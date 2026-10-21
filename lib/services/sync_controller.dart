import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/db/app_database.dart';
import '../data/models/models.dart';
import '../platform/local_fs.dart';
import 'connectivity_service.dart';
import 'keep_alive.dart';
import 'notification_service.dart';
import 'whatsapp_engine.dart';

class SyncController {
  SyncController({
    required this.db,
    required this.engine,
    required this.connectivity,
    this.notifications,
  });

  final AppDatabase db;
  final WhatsAppEngine engine;
  final ConnectivityService connectivity;
  final NotificationService? notifications;

  final ValueNotifier<String> status = ValueNotifier(
    AppConnectionStatus.offline,
  );
  final ValueNotifier<Uint8List?> qrBytes = ValueNotifier(null);
  final ValueNotifier<String?> qrData = ValueNotifier(null);
  final ValueNotifier<String> statusText = ValueNotifier(
    'غير متصل — عرض الرسائل المحفوظة',
  );
  final ValueNotifier<String?> errorText = ValueNotifier(null);
  final ValueNotifier<StatusFeed> statusFeed = ValueNotifier(const StatusFeed());
  final ValueNotifier<bool> statusesLoading = ValueNotifier(false);
  final ValueNotifier<WaProfile> myProfile = ValueNotifier(
    const WaProfile(waId: '', name: 'حسابي'),
  );
  final ValueNotifier<bool> shellReady = ValueNotifier(false);
  final ValueNotifier<String> shellPhase = ValueNotifier(AppShellPhase.starting);
  final ValueNotifier<double> bootstrapProgress = ValueNotifier(0);
  final ValueNotifier<String> bootstrapLabel = ValueNotifier(
    'جاري التحضير...',
  );

  StreamSubscription<bool>? _netSub;
  Timer? _qrTimeout;
  Timer? _liveTimer;
  Timer? _healthTimer;
  bool _connecting = false;
  bool _syncing = false;
  bool _liveBusy = false;
  bool _firstInboxReady = false;
  bool _refreshingDirectory = false;
  bool _catchingUp = false;
  DateTime? _lastCatchUp;
  bool _appInBackground = false;
  int _backgroundTicks = 0;
  int? viewingChatId;
  final Map<String, WaChatIdentity> _identities = {};

  static const initialMessagesPerChat = 20;
  static const pageSize = 50;

  Future<void> start() async {
    KeepAlive.bind();
    KeepAlive.onTick = () => unawaited(onBackgroundTick());
    unawaited(_initPush());
    await _loadCachedProfile();

    _netSub ??= connectivity.watch().listen((online) async {
      if (online &&
          await db.hasSession &&
          !engine.isConnected &&
          !_connecting) {
        unawaited(connect());
      } else if (!online) {
        _stopLiveLoop();
        _setStatus(
          AppConnectionStatus.offline,
          'بدون إنترنت — الرسائل المحفوظة ظاهرة، والمزامنة تتم تلقائيًا عند عودة الشبكة',
        );
      }
    });
    _healthTimer ??= Timer.periodic(const Duration(seconds: 40), (_) async {
      if (_connecting || _syncing || _liveBusy) return;
      if (engine.isConnected) return;
      if (await db.hasSession && await connectivity.isOnline) {
        unawaited(connect());
      }
    });

    if (await db.hasSession) {
      unawaited(KeepAlive.start());
      _enterReady();
      _setStatus(
        AppConnectionStatus.offline,
        'عرض المحادثات المحفوظة — جاري الربط',
      );
      unawaited(db.applyContactNamesToChats());
      unawaited(db.applyGroupNamesToChats());
      unawaited(db.unstickGroupContactTitles());
      unawaited(db.unstickDuplicateChatNames());
      if (await connectivity.isOnline) {
        unawaited(connect());
      }
    } else {
      _setStatus(
        AppConnectionStatus.authRequired,
        'امسح رمز QR لربط الحساب',
      );
      _enterNeedQr();
      unawaited(connect());
    }
  }

  Future<void> onAppBackgrounded() async {
    _appInBackground = true;
    if (!await db.hasSession) return;
    await KeepAlive.start();
    if (engine.isConnected) {
      try {
        await engine.listenMessages(_onIncomingMessage);
        await engine.listenAck(_onAck);
        await engine.keepAlivePulse();
      } catch (_) {}
      return;
    }
    if (await connectivity.isOnline && !_connecting) {
      unawaited(connect());
    }
  }

  Future<void> onBackgroundTick() async {
    if (!await db.hasSession) return;
    if (!await connectivity.isOnline) return;
    if (engine.isConnected) {
      try {
        await engine.listenMessages(_onIncomingMessage);
        await engine.listenAck(_onAck);
        await engine.keepAlivePulse();
        unawaited(flushOutgoingQueue());
        _backgroundTicks += 1;
        if (_appInBackground && _backgroundTicks % 4 == 0) {
          unawaited(_catchUpInbox());
        }
      } catch (_) {}
      return;
    }
    if (!_connecting) {
      unawaited(connect());
    }
  }

  Future<void> onAppResumed() async {
    _appInBackground = false;
    _backgroundTicks = 0;
    if (!await db.hasSession) return;
    if (!await connectivity.isOnline) {
      _setStatus(
        AppConnectionStatus.offline,
        'بدون إنترنت — الرسائل المحفوظة ظاهرة، والمزامنة تتم تلقائيًا عند عودة الشبكة',
      );
      return;
    }
    if (engine.isConnected) {
      await engine.listenMessages(_onIncomingMessage);
      await engine.listenAck(_onAck);
      _startLiveLoop();
      unawaited(_catchUpInbox(force: true));
      return;
    }
    if (!_connecting) {
      unawaited(connect());
    }
  }

  Future<void> connect() async {
    if (_connecting) return;
    if (engine.isConnected) {
      await engine.listenMessages(_onIncomingMessage);
      await engine.listenAck(_onAck);
      _startLiveLoop();
      _setStatus(AppConnectionStatus.online, 'متصل — التحديث تلقائي');
      unawaited(_refreshDirectory());
      unawaited(_catchUpInbox(force: true));
      return;
    }

    if (!await connectivity.isOnline) {
      if (await db.hasSession) {
        _enterReady();
        _setStatus(
          AppConnectionStatus.offline,
          'غير متصل — عرض المحادثات المحفوظة',
        );
      } else {
        _enterNeedQr();
      }
      return;
    }

    _connecting = true;
    errorText.value = null;
    if (!await db.hasSession && !await _hasLocalInbox()) {
      _enterNeedQr();
      _setBootstrap(0.15, 'جاري تجهيز رمز QR...');
    }
    qrBytes.value = null;
    qrData.value = null;
    if (_firstInboxReady) {
      _setStatus(AppConnectionStatus.syncing, 'جاري الربط في الخلفية...');
    } else {
      _setStatus(AppConnectionStatus.syncing, 'جاري تجهيز رمز QR...');
    }
    _qrTimeout?.cancel();
    _qrTimeout = Timer(const Duration(seconds: 90), () async {
      if (engine.isConnected) return;
      if (qrBytes.value != null || (qrData.value?.isNotEmpty ?? false)) {
        return;
      }
      if (await db.hasSession) return;
      errorText.value =
          'محرّك واتساب ويب توقف داخل المحاكي/الجهاز، لذلك لا يظهر الرمز. امسح بيانات التطبيق ثم أعد المحاولة على هاتف حقيقي.';
      _setStatus(
        AppConnectionStatus.authRequired,
        'تعذر إظهار رمز QR',
      );
      _enterNeedQr();
    });
    try {
      await engine.connect(
        persistSession: await db.hasSession,
        onQr: (qr, bytes) {
          _qrTimeout?.cancel();
          errorText.value = null;
          if (qr != null && qr.isNotEmpty) qrData.value = qr;
          if (bytes != null) qrBytes.value = bytes;
          if (_firstInboxReady) return;
          _enterNeedQr();
          _setStatus(
            AppConnectionStatus.authRequired,
            'امسح رمز QR من واتساب في هاتفك',
          );
        },
        onEvent: (event) {
          if (_firstInboxReady) {
            if (event == AppConnectionStatus.online) {
              _setStatus(event, 'متصل — التحديث تلقائي');
            } else if (event == AppConnectionStatus.offline) {
              _stopLiveLoop();
              _setStatus(event, 'انقطع الاتصال — الرسائل المحفوظة ظاهرة');
            }
            return;
          }
          if (event == AppConnectionStatus.authRequired) {
            _enterNeedQr();
            _setStatus(event, 'امسح رمز QR من واتساب في هاتفك');
          } else if (event == AppConnectionStatus.offline) {
            _stopLiveLoop();
            _setStatus(event, 'انقطع الاتصال — سيعاد الربط تلقائيًا');
          } else if (event == AppConnectionStatus.online) {
            if (shellPhase.value != AppShellPhase.ready) {
              _enterLinking('تم المسح — جاري المزامنة...');
            }
            _setStatus(event, 'جاري مزامنة المحادثات...');
          } else if (qrBytes.value == null &&
              (qrData.value == null || qrData.value!.isEmpty)) {
            if (shellPhase.value != AppShellPhase.needQr) {
              _enterLinking('جاري تجهيز رمز QR...');
            }
            _setStatus(AppConnectionStatus.syncing, 'جاري تجهيز رمز QR...');
          }
        },
      );

      if (!engine.isConnected) {
        final hasSession = await db.hasSession;
        _setStatus(
          hasSession
              ? AppConnectionStatus.offline
              : AppConnectionStatus.authRequired,
          hasSession
              ? 'تعذر الاتصال — عرض المحادثات المحفوظة'
              : 'يلزم مسح رمز QR',
        );
        if (hasSession) {
          _enterReady();
        } else {
          _enterNeedQr();
        }
        return;
      }

      _qrTimeout?.cancel();
      errorText.value = null;
      qrBytes.value = null;
      qrData.value = null;
      await db.markSession(true);
      await KeepAlive.start();
      unawaited(_requestBackgroundRun());
      if (!await _hasLocalInbox()) {
        _enterLinking('جاري جلب قائمة المحادثات لأول مرة...');
        await _bootstrapInbox();
      }
      await engine.listenMessages(_onIncomingMessage);
      await engine.listenAck(_onAck);
      _enterReady();
      _startLiveLoop();
      _setStatus(AppConnectionStatus.online, 'متصل — التحديث تلقائي');
      unawaited(flushOutgoingQueue());
      unawaited(_catchUpInbox(force: true));
      _scheduleDirectoryRefresh();
    } catch (error) {
      _qrTimeout?.cancel();
      final hasSession = await db.hasSession;
      if (qrBytes.value == null && (qrData.value == null || qrData.value!.isEmpty)) {
        errorText.value =
            'فشل الاتصال بواتساب ويب. هذا شائع في المحاكي. أعد المحاولة على هاتف حقيقي.';
      }
      _setStatus(
        hasSession
            ? AppConnectionStatus.offline
            : AppConnectionStatus.authRequired,
        hasSession
            ? 'غير متصل — عرض المحادثات المحفوظة'
            : 'تعذر إظهار رمز QR',
      );
      if (hasSession) {
        _enterReady();
      } else {
        _enterNeedQr();
      }
    } finally {
      _connecting = false;
    }
  }

  Future<void> disconnect({bool logout = false}) async {
    _stopLiveLoop();
    await KeepAlive.stop();
    await engine.disconnect(logout: logout);
    if (logout) {
      await db.markSession(false);
      qrBytes.value = null;
      qrData.value = null;
      _firstInboxReady = false;
      _setStatus(AppConnectionStatus.authRequired, 'يلزم مسح رمز QR');
      _enterNeedQr();
    } else {
      _setStatus(
        AppConnectionStatus.offline,
        'غير متصل — عرض المحادثات المحفوظة',
      );
    }
  }

  Future<void> syncChanges() async {
    if (await _hasLocalInbox()) {
      await _catchUpInbox(force: true);
      return;
    }
    await _bootstrapInbox();
  }

  Future<bool> _hasLocalInbox() async {
    final chats = await db.getAllChats();
    return chats.any((chat) => !ChatKinds.isSystemId(chat.waChatId));
  }

  Future<void> _bootstrapInbox() async {
    if (await _hasLocalInbox()) {
      _firstInboxReady = true;
      return;
    }
    if (!engine.isConnected || _syncing || !await engine.isReady()) {
      if (await db.hasSession) {
        _enterReady();
      } else {
        _enterNeedQr();
      }
      return;
    }
    _syncing = true;
    _setBootstrap(0.2, 'جاري جلب قائمة المحادثات...');
    if (status.value != AppConnectionStatus.online) {
      _setStatus(AppConnectionStatus.syncing, 'جاري مزامنة الدردشات...');
    }
    try {
      final chats = await engine.getChats();
      _setBootstrap(0.55, 'جاري حفظ المحادثات والأسماء...');
      var index = 0;
      for (final chat in chats) {
        index += 1;
        if (ChatKinds.isSystemId(chat.id)) continue;
        if (!chat.isGroup &&
            !chat.isChannel &&
            !ChatKinds.isChannelId(chat.id) &&
            !DisplayNames.isWeak(chat.name)) {
          await db.upsertContact(waId: chat.id, name: chat.name);
        }
        final local = await db.upsertChat(
          waChatId: chat.id,
          name: chat.name,
          isGroup: chat.isGroup && !chat.isChannel,
          lastMessageText: chat.lastMessageText,
          lastMessageAt: chat.lastMessageAt,
          unreadCount: chat.unreadCount,
        );
        if (viewingChatId == local.id) {
          await db.clearUnread(local.id);
        }
        if (index % 8 == 0) {
          await Future<void>.delayed(Duration.zero);
          _setBootstrap(
            0.55 + (0.35 * (index / chats.length)),
            'حفظ المحادثات... $index من ${chats.length}',
          );
        }
      }
      await db.applyContactNamesToChats();
      await db.applyGroupNamesToChats();
      _setBootstrap(0.95, 'اكتملت المزامنة الأولى');
      _firstInboxReady = true;
      _scheduleDirectoryRefresh();
    } finally {
      _syncing = false;
      if (engine.isConnected) {
        _setStatus(AppConnectionStatus.online, 'متصل — التحديث تلقائي');
      }
    }
  }

  void _setBootstrap(double progress, String label) {
    bootstrapProgress.value = progress.clamp(0, 1);
    bootstrapLabel.value = label;
  }

  void _enterNeedQr() {
    shellPhase.value = AppShellPhase.needQr;
    shellReady.value = false;
  }

  void _enterLinking(String label) {
    _setBootstrap(
      bootstrapProgress.value < 0.15 ? 0.2 : bootstrapProgress.value,
      label,
    );
    shellPhase.value = AppShellPhase.linking;
    shellReady.value = false;
  }

  void _enterReady() {
    _setBootstrap(1, 'جاهز');
    _firstInboxReady = true;
    shellPhase.value = AppShellPhase.ready;
    shellReady.value = true;
  }

  Future<void> refreshStatuses({bool silent = false}) async {
    if (!engine.isConnected || !await engine.isReady()) return;
    if (!silent) statusesLoading.value = true;
    try {
      statusFeed.value = await engine.getStatusFeed();
    } catch (_) {
    } finally {
      if (!silent) statusesLoading.value = false;
    }
  }

  Future<void> sendTextStatus(
    String text, {
    String backgroundColor = '#075E54',
  }) async {
    await _ensureStatusReady();
    await engine.sendTextStatus(text, backgroundColor: backgroundColor);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    await refreshStatuses();
  }

  Future<void> sendImageStatus(List<int> bytes) async {
    await _ensureStatusReady();
    await engine.sendImageStatus(bytes);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    await refreshStatuses();
  }

  Future<void> sendVideoStatus(List<int> bytes) async {
    await _ensureStatusReady();
    await engine.sendVideoStatus(bytes);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    await refreshStatuses();
  }

  Future<void> _ensureStatusReady() async {
    if (!engine.isConnected) {
      throw StateError('غير متصل');
    }
    for (var attempt = 0; attempt < 15; attempt++) {
      if (await engine.isMainReady()) return;
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    if (!await engine.isMainReady()) {
      throw StateError('واتساب غير جاهز لنشر الحالة بعد');
    }
  }

  Future<void> markStatusItemRead(WaStatusItem item) async {
    if (item.fromMe || item.id.isEmpty) return;
    try {
      await engine.markStatusRead(item.authorId, item.id);
    } catch (_) {}
  }

  Future<void> markStatusRead(WaStatusThread thread) async {
    if (thread.fromMe || thread.items.isEmpty) return;
    for (final item in thread.items) {
      await markStatusItemRead(item);
    }
    await refreshStatuses(silent: true);
  }

  Future<WaStatusViews> getStatusViewers(WaStatusItem item) async {
    var views = WaStatusViews(
      count: item.shownViewCount,
      viewers: item.viewers,
    );
    try {
      final remote = await engine.getStatusViewers(item.id);
      if (remote.viewers.isNotEmpty || remote.count > 0) {
        views = remote;
      }
    } catch (_) {}
    final merged = <String, WaStatusViewer>{};
    void add(WaStatusViewer viewer) {
      if (viewer.waId.isEmpty) return;
      final key = viewer.waId.split('@').first;
      final prev = merged[key];
      if (prev == null) {
        merged[key] = viewer;
        return;
      }
      merged[key] = WaStatusViewer(
        waId: prev.waId.contains('@c.us') ? prev.waId : viewer.waId,
        name: DisplayNames.isWeak(prev.name) ? viewer.name : prev.name,
        timestamp: viewer.timestamp ?? prev.timestamp,
        hiddenReceipt: prev.hiddenReceipt && viewer.hiddenReceipt,
      );
    }
    for (final viewer in await _cachedStatusViewers(item.id)) {
      add(viewer);
    }
    for (final viewer in views.viewers) {
      add(viewer);
    }
    final people = <WaStatusViewer>[];
    for (final viewer in merged.values) {
      var name = viewer.name;
      if (DisplayNames.isWeak(name)) {
        final contact = await db.contactByIdentity(viewer.waId);
        if (contact != null && !DisplayNames.isWeak(contact.name)) {
          name = contact.name;
        }
      }
      people.add(
        WaStatusViewer(
          waId: viewer.waId,
          name: name,
          timestamp: viewer.timestamp,
          hiddenReceipt: viewer.hiddenReceipt,
        ),
      );
    }
    await _saveStatusViewers(item.id, people);
    final hidden = views.hiddenCount;
    return WaStatusViews(
      count: people.length,
      viewers: people,
      hiddenCount: hidden != null && hidden > 0 ? hidden : null,
    );
  }

  Future<List<WaStatusViewer>> _cachedStatusViewers(String statusId) async {
    final raw = await db.setting('status_viewers_v1');
    if (raw == null || raw.isEmpty) return const [];
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return const [];
      final rows = map[statusId];
      if (rows is! List) return const [];
      return rows.map(WaParsers.statusViewer).where((v) => v.waId.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _saveStatusViewers(String statusId, List<WaStatusViewer> viewers) async {
    if (viewers.isEmpty) return;
    Map<String, dynamic> map = {};
    final raw = await db.setting('status_viewers_v1');
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          map = decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {}
    }
    map[statusId] = viewers
        .take(40)
        .map(
          (viewer) => {
            'waId': viewer.waId,
            'name': viewer.name,
            'timestamp': viewer.timestamp?.millisecondsSinceEpoch,
            'hiddenReceipt': viewer.hiddenReceipt,
          },
        )
        .toList();
    if (map.length > 30) {
      final keys = map.keys.toList();
      for (final key in keys.take(map.length - 30)) {
        map.remove(key);
      }
    }
    await db.putSetting('status_viewers_v1', jsonEncode(map));
  }

  Future<void> removeStatus(String statusId) async {
    if (!engine.isConnected || !await engine.isReady()) {
      throw StateError('غير متصل');
    }
    await engine.removeStatus(statusId);
    await refreshStatuses();
  }

  Future<bool> loadOlderMessages(int chatId) async {
    if (!engine.isConnected || !await engine.isReady()) {
      throw StateError('غير متصل');
    }
    final chat = await db.chatById(chatId);
    if (chat == null) return false;
    final oldest = await db.oldestRemoteMessage(chatId);
    final beforeCount = await db.messageCountForChat(chatId);
    var incoming = await engine.getMessages(
      chat.waChatId,
      count: pageSize,
      beforeId: oldest?.waMessageId,
    );
    await _storeMessages(incoming);
    var afterCount = await db.messageCountForChat(chatId);
    if (afterCount <= beforeCount) {
      incoming = await engine.getMessages(
        chat.waChatId,
        count: beforeCount + pageSize,
      );
      await _storeMessages(incoming);
      afterCount = await db.messageCountForChat(chatId);
    }
    return afterCount > beforeCount;
  }

  Future<void> sendText({
    required int chatId,
    required String waChatId,
    required String body,
  }) async {
    final key = 'local_${chatId}_${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();
    await db.upsertMessage(
      waMessageId: key,
      chatId: chatId,
      fromMe: true,
      body: body,
      timestamp: now,
      deliveryStatus: 'pending_local',
    );
    final queueId = await db.enqueueOutgoing(
      OutgoingQueueItemsCompanion.insert(
        chatId: chatId,
        waChatId: waChatId,
        body: body,
        createdAt: now,
        localMessageKey: key,
      ),
    );
    await _sendQueued(queueId);
  }

  Future<void> sendImage({
    required int chatId,
    required String waChatId,
    required List<int> bytes,
    String? caption,
  }) {
    return sendFile(
      chatId: chatId,
      waChatId: waChatId,
      bytes: bytes,
      type: 'image',
      caption: caption,
      fileName: 'image.jpg',
    );
  }

  Future<void> sendFile({
    required int chatId,
    required String waChatId,
    required List<int> bytes,
    required String type,
    String? caption,
    String? fileName,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final pickedExt = p.extension(fileName ?? '').replaceFirst('.', '');
    final ext = switch (type) {
      'video' => pickedExt.isEmpty ? 'mp4' : pickedExt,
      'audio' || 'ptt' => pickedExt.isEmpty
          ? (type == 'ptt' ? 'ogg' : 'm4a')
          : pickedExt,
      'document' => pickedExt.isEmpty ? 'bin' : pickedExt,
      _ => pickedExt.isEmpty ? 'jpg' : pickedExt,
    };
    final path = p.join(
      dir.path,
      'outgoing_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    await writeLocalFile(path, bytes);
    final key = 'local_${chatId}_${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();
    await db.upsertMessage(
      waMessageId: key,
      chatId: chatId,
      fromMe: true,
      body: caption ?? WaMessage.mediaLabel(type),
      timestamp: now,
      type: type,
      hasMedia: true,
      mediaLocalPath: path,
      deliveryStatus: 'pending_local',
    );
    final queueId = await db.enqueueOutgoing(
      OutgoingQueueItemsCompanion.insert(
        chatId: chatId,
        waChatId: waChatId,
        body: caption ?? '',
        type: Value(type),
        mediaPath: Value(path),
        createdAt: now,
        localMessageKey: key,
      ),
    );
    await _sendQueued(queueId);
  }

  Future<void> forwardToChat({
    required LocalMessage message,
    required LocalChat target,
  }) async {
    if (target.id == message.chatId) return;
    final remoteId = message.waMessageId;
    final canForwardRemote = engine.isConnected &&
        !remoteId.startsWith('local_') &&
        !remoteId.startsWith('unknown_');
    if (canForwardRemote && await engine.isReady()) {
      try {
        await engine.forwardMessage(
          toChatId: target.waChatId,
          messageId: remoteId,
        );
        return;
      } catch (_) {}
    }
    final caption =
        MediaText.isReadable(message.body) &&
            message.body != WaMessage.mediaLabel(message.type)
        ? message.body
        : null;
    if (localFileExists(message.mediaLocalPath)) {
      final bytes = await readLocalFile(message.mediaLocalPath!);
      await sendFile(
        chatId: target.id,
        waChatId: target.waChatId,
        bytes: bytes,
        type: ChatKinds.isMediaType(message.type) ? message.type : 'document',
        fileName: p.basename(message.mediaLocalPath!),
        caption: caption,
      );
      return;
    }
    if (caption != null && caption.trim().isNotEmpty) {
      await sendText(
        chatId: target.id,
        waChatId: target.waChatId,
        body: caption,
      );
      return;
    }
    throw StateError('تعذر تحويل هذه الرسالة');
  }

  Future<void> flushOutgoingQueue() async {
    if (!engine.isConnected) return;
    for (final item in await db.pendingOutgoing()) {
      await _sendQueued(item.id);
    }
  }

  Future<LocalChat> openOrCreateChat(String phone) async {
    var waChatId = phone.trim().replaceAll(RegExp(r'[^\d+]'), '');
    waChatId = waChatId.replaceAll('+', '');
    if (!waChatId.contains('@')) {
      waChatId = '$waChatId@c.us';
    }
    final contact = await db.contactByWaId(waChatId);
    return db.upsertChat(
      waChatId: waChatId,
      name: DisplayNames.best(
        [contact?.name, phone],
        fallback: DisplayNames.fromId(waChatId),
      ),
      isGroup: false,
    );
  }

  Future<void> _loadCachedProfile() async {
    myProfile.value = WaProfile(
      waId: await db.setting('me_wa_id') ?? '',
      name: await db.setting('me_name') ?? 'حسابي',
      about: await db.setting('me_about') ?? '',
      phone: await db.setting('me_phone'),
      photoPath: await db.setting('me_photo_path'),
    );
  }

  Future<void> _saveCachedProfile(WaProfile profile) async {
    await db.putSetting('me_wa_id', profile.waId);
    await db.putSetting('me_name', profile.name);
    await db.putSetting('me_about', profile.about);
    await db.putSetting('me_phone', profile.phone ?? '');
    if (profile.photoPath != null) {
      await db.putSetting('me_photo_path', profile.photoPath!);
    }
    myProfile.value = profile;
  }

  Future<void> refreshMyProfile() async {
    await _loadCachedProfile();
    if (!engine.isConnected || !await engine.isReady()) return;
    try {
      final remote = await engine.getMyProfile();
      final photoPath = remote.photoUrl == null
          ? myProfile.value.photoPath
          : await _cacheAvatar(remote.waId.isEmpty ? 'me' : remote.waId, remote.photoUrl!);
      await _saveCachedProfile(
        WaProfile(
          waId: remote.waId.isEmpty ? myProfile.value.waId : remote.waId,
          name: DisplayNames.isWeak(remote.name)
              ? myProfile.value.name
              : remote.name,
          about: remote.about.isEmpty ? myProfile.value.about : remote.about,
          phone: remote.phone ?? myProfile.value.phone,
          photoPath: photoPath ?? myProfile.value.photoPath,
          photoUrl: remote.photoUrl,
        ),
      );
    } catch (_) {}
  }

  Future<void> updateMyName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (engine.isConnected) {
      await engine.setMyProfileName(trimmed);
    }
    await _saveCachedProfile(
      WaProfile(
        waId: myProfile.value.waId,
        name: trimmed,
        about: myProfile.value.about,
        phone: myProfile.value.phone,
        photoPath: myProfile.value.photoPath,
        photoUrl: myProfile.value.photoUrl,
      ),
    );
  }

  Future<void> updateMyAbout(String about) async {
    if (engine.isConnected) {
      await engine.setMyAbout(about.trim());
    }
    await _saveCachedProfile(
      WaProfile(
        waId: myProfile.value.waId,
        name: myProfile.value.name,
        about: about.trim(),
        phone: myProfile.value.phone,
        photoPath: myProfile.value.photoPath,
        photoUrl: myProfile.value.photoUrl,
      ),
    );
  }

  Future<void> updateMyPhoto(List<int> bytes) async {
    if (engine.isConnected) {
      await engine.setMyProfilePicture(bytes);
    }
    final path = await _writeAvatarBytes(myProfile.value.waId.isEmpty ? 'me' : myProfile.value.waId, bytes);
    await _saveCachedProfile(
      WaProfile(
        waId: myProfile.value.waId,
        name: myProfile.value.name,
        about: myProfile.value.about,
        phone: myProfile.value.phone,
        photoPath: path,
        photoUrl: myProfile.value.photoUrl,
      ),
    );
  }

  Future<void> _initPush() async {
    try {
      await notifications?.init();
      await notifications?.requestPermission();
    } catch (_) {}
  }

  Future<void> _requestBackgroundRun() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (_) {}
  }

  void _scheduleDirectoryRefresh() {
    unawaited(_refreshDirectory());
    unawaited(
      Future<void>.delayed(const Duration(seconds: 12), () {
        if (engine.isConnected) unawaited(_refreshDirectory());
      }),
    );
  }

  Future<void> _refreshDirectory() async {
    if (_refreshingDirectory) return;
    if (!engine.isConnected || !await engine.isReady()) return;
    _refreshingDirectory = true;
    try {
      var names = <String, String>{};
      try {
        names = await engine.getContactNameMap();
        if (names.isEmpty) {
          await Future<void>.delayed(const Duration(seconds: 8));
          if (!engine.isConnected) return;
          names = await engine.getContactNameMap();
        }
      } catch (_) {}
      if (names.isNotEmpty) {
        for (final chat in await db.getAllChats()) {
          if (chat.isGroup || ChatKinds.isChannelId(chat.waChatId)) continue;
          final name = _nameFromMap(names, chat.waChatId);
          if (name == null) continue;
          await db.upsertContact(waId: chat.waChatId, name: name);
        }
        await db.applyContactNamesToChats(names);
      }
      try {
        final groups = await engine.getGroupNameMap();
        for (final entry in groups.entries) {
          await db.upsertGroup(waGroupId: entry.key, name: entry.value);
        }
        await db.applyGroupNamesToChats();
        await db.unstickGroupContactTitles();
      } catch (_) {}
      await db.unstickDuplicateChatNames();
      await syncProfilePictures(limit: 40);
    } catch (_) {
    } finally {
      _refreshingDirectory = false;
    }
  }

  Future<void> syncProfilePictures({int limit = 20}) async {
    if (!engine.isConnected || !await engine.isReady()) return;
    final chats = List<LocalChat>.from(await db.getAllChats());
    chats.sort((a, b) {
      final at = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    var count = 0;
    for (final chat in chats) {
      if (count >= limit) break;
      if (ChatKinds.isSystemId(chat.waChatId)) continue;
      if (localFileExists(chat.profilePicPath)) {
        continue;
      }
      final path = await refreshChatPhoto(chat);
      if (path != null) count += 1;
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!engine.isConnected) break;
    }
  }

  Future<String?> refreshChatPhoto(LocalChat chat) async {
    if (!engine.isConnected) return chat.profilePicPath;
    try {
      final url = await engine.getProfilePicture(chat.waChatId);
      if (url == null || url.isEmpty) return chat.profilePicPath;
      final path = await _cacheAvatar(chat.waChatId, url);
      if (path == null) return chat.profilePicPath;
      await db.upsertChat(
        waChatId: chat.waChatId,
        name: chat.name,
        isGroup: chat.isGroup,
        profilePicPath: path,
      );
      if (!chat.isGroup) {
        await db.upsertContact(
          waId: chat.waChatId,
          name: chat.name,
          profilePicPath: path,
        );
      }
      return path;
    } catch (_) {
      return chat.profilePicPath;
    }
  }

  Future<WaProfile> loadContactProfile(LocalChat chat) async {
    var photo = chat.profilePicPath;
    var about = '';
    if (engine.isConnected) {
      try {
        photo = await refreshChatPhoto(chat) ?? photo;
      } catch (_) {}
      try {
        about = await engine.getContactAbout(chat.waChatId) ?? '';
      } catch (_) {}
    }
    String? phone = DisplayNames.phoneFromId(chat.waChatId);
    if (engine.isConnected) {
      try {
        final identity = await _identityFor(chat.waChatId);
        phone = identity.phone ??
            DisplayNames.phoneFromId(identity.id) ??
            phone;
      } catch (_) {}
    }
    return WaProfile(
      waId: chat.waChatId,
      name: chat.name,
      about: about,
      phone: phone,
      photoPath: photo,
    );
  }

  Future<String?> _cacheAvatar(String id, String url) async {
    try {
      if (url.startsWith('data:')) {
        final bytes = MediaText.decode(url);
        if (bytes == null) return null;
        return _writeAvatarBytes(id, bytes);
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;
      final bytes = response.bodyBytes;
      if (bytes.isEmpty) return null;
      return _writeAvatarBytes(id, bytes);
    } catch (_) {
      return null;
    }
  }

  Future<String> _writeAvatarBytes(String id, List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final safe = id.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = p.join(dir.path, 'avatar_$safe.jpg');
    await writeLocalFile(path, bytes);
    return path;
  }

  Future<void> markChatSeen(LocalChat chat) async {
    await db.clearUnread(chat.id);
    if (engine.isConnected) {
      try {
        await engine.markSeen(chat.waChatId);
      } catch (_) {}
    }
  }

  Future<void> downloadMissingMediaInChat(int chatId) async {
    final messages = await db.messagesForChat(chatId);
    for (final message in messages.reversed.take(40)) {
      final path = message.mediaLocalPath;
      final missing = path == null ||
          !localFileExists(path) ||
          _isLikelyThumbnail(path, message.type);
      if (!missing) continue;
      if (MediaText.looksLikeBinary(message.body)) {
        await recoverEmbeddedMedia(message);
      }
      if (message.hasMedia || ChatKinds.isMediaType(message.type)) {
        try {
          await downloadMessageMedia(message);
        } catch (_) {}
      }
    }
  }

  Future<void> downloadMissingAudioInChat(int chatId) async {
    final messages = await db.messagesForChat(chatId);
    for (final message in messages.reversed.take(30)) {
      if (message.type != 'audio' && message.type != 'ptt') continue;
      if (localFileExists(message.mediaLocalPath) &&
          localFileLength(message.mediaLocalPath!) > 400) {
        continue;
      }
      try {
        await downloadMessageMedia(message);
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
  }

  Future<void> downloadMessageMedia(LocalMessage message) async {
    if (!engine.isConnected) return;
    if (!message.hasMedia && !ChatKinds.isMediaType(message.type)) return;
    final raw = await engine.downloadMedia(message.waMessageId);
    if (raw == null) return;
    final encoded = raw['data'] ?? raw['base64'] ?? raw['base64Data'];
    if (encoded is! String || encoded.isEmpty) return;
    final path = await _writeMediaFile(
      message.waMessageId,
      message.type,
      encoded,
      mime: (raw['mimetype'] ?? raw['mimeType'] ?? '').toString(),
    );
    if (path != null) {
      final previous = message.mediaLocalPath;
      if (previous != null &&
          localFileExists(previous) &&
          localFileExists(path) &&
          localFileLength(path) + 2048 < localFileLength(previous)) {
        return;
      }
      if (previous != null && previous != path && localFileExists(previous)) {
        try {
          deleteLocalFile(previous);
        } catch (_) {}
      }
      await db.updateMessageMedia(message.waMessageId, path);
    }
  }

  bool _isLikelyThumbnail(String? path, String type) {
    if (path == null) return true;
    if (type != 'image' && type != 'sticker' && type != 'chat') return false;
    if (!localFileExists(path)) return true;
    return localFileLength(path) < 48 * 1024;
  }

  Future<void> recoverEmbeddedMedia(LocalMessage message) async {
    if (localFileExists(message.mediaLocalPath)) {
      if (MediaText.looksLikeBinary(message.body)) {
        await db.updateMessageMedia(
          message.waMessageId,
          message.mediaLocalPath!,
        );
      }
      return;
    }
    final encoded = MediaText.extractBase64(message.body);
    if (encoded == null) return;
    final path = await _writeMediaFile(
      message.waMessageId,
      message.type == 'chat' ? 'image' : message.type,
      encoded,
    );
    if (path != null) {
      await db.updateMessageMedia(message.waMessageId, path);
    }
  }

  Future<void> recoverEmbeddedMediaInChat(int chatId) async {
    final messages = await db.messagesForChat(chatId);
    for (final message in messages) {
      if (MediaText.looksLikeBinary(message.body)) {
        await recoverEmbeddedMedia(message);
      }
    }
  }

  Future<String?> _writeMediaFile(
    String messageId,
    String type,
    String encoded, {
    String mime = '',
  }) async {
    try {
      final bytes = base64Decode(encoded.split(',').last);
      if (bytes.isEmpty) return null;
      final ext = mime.contains('mp4')
          ? 'mp4'
          : mime.contains('ogg') || mime.contains('opus')
          ? 'ogg'
          : mime.contains('mpeg') || mime.contains('mp3')
          ? 'mp3'
          : mime.contains('audio')
          ? 'm4a'
          : mime.contains('png')
          ? 'png'
          : mime.contains('webp')
          ? 'webp'
          : mime.contains('pdf')
          ? 'pdf'
          : mime.contains('jpeg') || mime.contains('jpg')
          ? 'jpg'
          : type == 'sticker'
          ? 'webp'
          : type == 'document'
          ? 'bin'
          : type == 'video'
          ? 'mp4'
          : type == 'audio' || type == 'ptt'
          ? 'ogg'
          : 'jpg';
      final dir = await getApplicationDocumentsDirectory();
      final safeId = messageId.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final path = p.join(dir.path, 'media_${safeId}_${bytes.length}.$ext');
      await writeLocalFile(path, bytes);
      return path;
    } catch (_) {
      return null;
    }
  }

  Future<void> retryOutgoing(String localMessageKey) async {
    final pending = await db.pendingOutgoing();
    for (final item in pending) {
      if (item.localMessageKey == localMessageKey) {
        await db.updateQueueStatus(item.id, 'pending_local');
        await db.updateMessageStatus(localMessageKey, 'pending_local');
        await _sendQueued(item.id);
        return;
      }
    }
  }

  Future<void> _sendQueued(int queueId) async {
    final item = await db.queueById(queueId);
    if (item == null) return;

    if (!engine.isConnected) {
      if (!_connecting) unawaited(connect());
      await db.updateQueueStatus(item.id, 'pending_local');
      await db.updateMessageStatus(item.localMessageKey, 'pending_local');
      return;
    }

    if (!await engine.isReady()) {
      for (var attempt = 0; attempt < 20; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (await engine.isReady()) break;
      }
      if (!await engine.isReady() && !engine.isConnected) {
        await db.updateQueueStatus(item.id, 'pending_local');
        await db.updateMessageStatus(item.localMessageKey, 'pending_local');
        return;
      }
    }

    await db.updateQueueStatus(item.id, 'sending');
    await db.updateMessageStatus(item.localMessageKey, 'sending');
    try {
      if (item.mediaPath != null && item.type != 'text') {
        final bytes = await readLocalFile(item.mediaPath!);
        await engine.sendMedia(
          chatId: item.waChatId,
          bytes: bytes,
          type: item.type,
          caption: item.body.isEmpty ? null : item.body,
          fileName: p.basename(item.mediaPath!),
        );
      } else {
        await engine.sendText(item.waChatId, item.body);
      }
      await db.updateMessageStatus(item.localMessageKey, 'sent');
      await db.deleteQueueItem(item.id);
    } catch (error) {
      final text = error.toString();
      final temporary = text.contains('WPP is not defined') ||
          text.contains('غير جاهز') ||
          text.contains('not connected');
      await db.updateQueueStatus(
        item.id,
        temporary ? 'pending_local' : 'failed',
        retryCount: item.retryCount + 1,
      );
      await db.updateMessageStatus(
        item.localMessageKey,
        temporary ? 'pending_local' : 'failed',
      );
    }
  }

  void _startLiveLoop() {
    _liveTimer?.cancel();
    var ticks = 0;
    _liveTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(flushOutgoingQueue());
      ticks += 1;
      if (ticks == 1 || ticks % 5 == 0) {
        unawaited(_catchUpInbox());
      }
    });
  }

  void _stopLiveLoop() {
    _liveTimer?.cancel();
    _liveTimer = null;
  }

  Future<void> syncLiveInbox() async {
    await _catchUpInbox();
  }

  Future<LocalChat?> _existingChatFor(String waId) async {
    final exact = await db.chatByWaId(waId);
    if (exact != null) return exact;
    if (ChatKinds.isGroupId(waId) || ChatKinds.isChannelId(waId)) {
      return null;
    }
    for (final chat in await db.getAllChats()) {
      if (chat.isGroup || ChatKinds.isChannelId(chat.waChatId)) continue;
      if (DisplayNames.samePerson(chat.waChatId, waId)) return chat;
    }
    return null;
  }

  Future<bool> _needsMessageCatchUp(WaChat remote, LocalChat? local) async {
    if (local == null) return true;
    if (await db.messageCountForChat(local.id) == 0) return true;
    if (local.lastMessageAt == null) return true;
    final remoteAt = remote.lastMessageAt;
    if (remoteAt != null &&
        remoteAt.isAfter(local.lastMessageAt!.add(const Duration(seconds: 2)))) {
      return true;
    }
    if (remote.unreadCount > local.unreadCount) return true;
    final remoteText = (remote.lastMessageText ?? '').trim();
    final localText = (local.lastMessageText ?? '').trim();
    if (remoteText.isNotEmpty &&
        remoteText != localText &&
        (remoteAt == null || !remoteAt.isBefore(local.lastMessageAt!))) {
      return true;
    }
    return false;
  }

  Future<void> _catchUpInbox({bool force = false}) async {
    if (_catchingUp || _syncing) return;
    if (!engine.isConnected) return;
    if (!force &&
        _lastCatchUp != null &&
        DateTime.now().difference(_lastCatchUp!) < const Duration(seconds: 25)) {
      return;
    }
    _catchingUp = true;
    _lastCatchUp = DateTime.now();
    try {
      for (var attempt = 0; attempt < 20; attempt++) {
        if (await engine.isMainReady()) break;
        if (!engine.isConnected) return;
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
      if (!await engine.isReady()) return;
      _setStatus(AppConnectionStatus.syncing, 'جاري مزامنة الرسائل الجديدة...');
      final remotes = await engine.getChats();
      final openId = viewingChatId;
      final fetchFirst = <WaChat>[];
      final fetchRest = <WaChat>[];
      final seenOnly = <WaChat>[];
      for (final chat in remotes) {
        if (ChatKinds.isSystemId(chat.id)) continue;
        final local = await _existingChatFor(chat.id);
        if (openId != null && local?.id == openId) {
          fetchFirst.add(chat);
        } else if (await _needsMessageCatchUp(chat, local)) {
          fetchRest.add(chat);
        } else {
          seenOnly.add(chat);
        }
      }
      var fetched = 0;
      for (final chat in [...fetchFirst, ...fetchRest, ...seenOnly]) {
        if (!engine.isConnected) break;
        final existing = await _existingChatFor(chat.id);
        final shouldFetch =
            fetched < 20 && await _needsMessageCatchUp(chat, existing);
        final local = await db.upsertChat(
          waChatId: existing?.waChatId ?? chat.id,
          name: DisplayNames.best(
            [existing?.name, chat.name],
            fallback: chat.name,
          ),
          isGroup: chat.isGroup && !chat.isChannel,
          lastMessageText: chat.lastMessageText,
          lastMessageAt: chat.lastMessageAt,
          unreadCount: existing != null && viewingChatId == existing.id
              ? 0
              : chat.unreadCount,
        );
        if (!shouldFetch) continue;
        try {
          final incoming = await engine.getMessages(
            chat.id,
            count: existing == null ? 20 : 30,
          );
          final mapped = existing != null && existing.waChatId != chat.id
              ? incoming
                  .map((message) => message.copyWith(chatId: existing.waChatId))
                  .toList()
              : incoming;
          await _storeMessages(mapped, bumpUnread: false);
          if (viewingChatId == local.id) {
            await db.clearUnread(local.id);
          }
          fetched += 1;
        } catch (_) {}
        await Future<void>.delayed(const Duration(milliseconds: 140));
      }
    } catch (_) {
    } finally {
      _catchingUp = false;
      if (engine.isConnected) {
        _setStatus(AppConnectionStatus.online, 'متصل — التحديث تلقائي');
      }
    }
  }

  Future<void> refreshOpenChat(int chatId) async {
    if (!engine.isConnected || !await engine.isReady()) return;
    final chat = await db.chatById(chatId);
    if (chat == null) return;
    try {
      await _storeMessages(
        await engine.getMessages(chat.waChatId, count: 30),
        bumpUnread: false,
      );
      await db.clearUnread(chatId);
    } catch (_) {}
  }

  final List<WaMessage> _incomingQueue = [];
  bool _drainingInbox = false;

  void _onIncomingMessage(WaMessage message) {
    if (message.id.isNotEmpty &&
        _incomingQueue.any((item) => item.id == message.id)) {
      return;
    }
    _incomingQueue.add(message);
    if (_incomingQueue.length > 60) {
      _incomingQueue.removeRange(0, _incomingQueue.length - 60);
    }
    unawaited(_drainIncoming());
  }

  Future<void> _drainIncoming() async {
    if (_drainingInbox) return;
    _drainingInbox = true;
    try {
      while (_incomingQueue.isNotEmpty) {
        final message = _incomingQueue.removeAt(0);
        await _storeMessages([message], bumpUnread: true);
        if (status.value != AppConnectionStatus.online) {
          _setStatus(AppConnectionStatus.online, 'متصل — التحديث تلقائي');
        }
        final open = viewingChatId;
        if (open != null && !message.fromMe) {
          final chat = await db.chatByWaId(message.chatId);
          if (chat != null && chat.id == open) {
            await db.clearUnread(chat.id);
          }
        }
        await Future<void>.delayed(const Duration(milliseconds: 160));
      }
    } finally {
      _drainingInbox = false;
    }
  }

  Future<void> _completeIncomingMedia(WaMessage message) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!engine.isConnected) return;
    final stored = await db.messageByWaId(message.id);
    if (stored == null) return;
    final path = stored.mediaLocalPath;
    if (path != null &&
        localFileExists(path) &&
        !_isLikelyThumbnail(path, stored.type)) {
      return;
    }
    try {
      await downloadMessageMedia(stored);
    } catch (_) {}
  }

  Future<void> _onAck(String messageId, int ack) {
    return db.updateMessageStatus(messageId, WaParsers.ackStatus(ack));
  }

  Future<WaChatIdentity> _identityFor(
    String id, {
    bool remote = false,
  }) async {
    final cached = _identities[id];
    if (cached != null) return cached;
    if (ChatKinds.isSystemId(id)) {
      return _identities[id] = WaChatIdentity(id: id, hidden: true);
    }
    if (ChatKinds.isGroupId(id) || ChatKinds.isChannelId(id)) {
      return _identities[id] = WaChatIdentity(id: id);
    }
    if (!remote || !engine.isConnected || _firstInboxReady) {
      return _identities[id] = WaChatIdentity(id: id);
    }
    try {
      final resolved = await engine.resolveChatIdentity(id);
      _identities[id] = resolved;
      if (resolved.id != id) {
        _identities[resolved.id] = resolved;
      }
      return resolved;
    } catch (_) {
      return _identities[id] = WaChatIdentity(id: id);
    }
  }

  Future<void> _cleanupGhostChats() async {
    for (final chat in await db.getAllChats()) {
      if (chat.isGroup || ChatKinds.isChannelId(chat.waChatId)) continue;
      if (ChatKinds.isSystemId(chat.waChatId)) continue;
      if (!ChatKinds.isLidId(chat.waChatId)) continue;
      final identity = await _identityFor(chat.waChatId);
      if (identity.usable && identity.id != chat.waChatId) {
        await db.mergeChat(chat.waChatId, identity.id);
        if (!DisplayNames.isWeak(identity.name ?? chat.name)) {
          await db.upsertChat(
            waChatId: identity.id,
            name: identity.name ?? chat.name,
            isGroup: false,
          );
        }
      }
    }
  }

  String? _nameFromMap(Map<String, String> names, String id) {
    final user = id.split('@').first;
    final digits = DisplayNames.digits(id);
    final name = DisplayNames.best(
      [
        names[id],
        names[user],
        names[digits],
        names['$user@c.us'],
        names['$user@lid'],
      ],
      fallback: '',
    );
    return name.isEmpty ? null : name;
  }

  Future<WaChat> _hydrateChat(WaChat chat) async {
    try {
      final detailed = await engine.getChat(chat.id);
      if (detailed != null && !DisplayNames.isWeak(detailed.name)) {
        return detailed;
      }
    } catch (_) {}
    if (!chat.isGroup &&
        !chat.isChannel &&
        !ChatKinds.isChannelId(chat.id)) {
      try {
        final contact = await engine.getContact(chat.id);
        if (contact != null && !DisplayNames.isWeak(contact.name)) {
          return WaChat(
            id: chat.id,
            name: contact.name,
            isGroup: false,
            lastMessageText: chat.lastMessageText,
            lastMessageAt: chat.lastMessageAt,
            unreadCount: chat.unreadCount,
            profilePicUrl: contact.profilePicUrl ?? chat.profilePicUrl,
          );
        }
      } catch (_) {}
    }
    final local = await db.contactByIdentity(chat.id);
    if (local != null && !DisplayNames.isWeak(local.name)) {
      return WaChat(
        id: chat.id,
        name: local.name,
        isGroup: chat.isGroup,
        lastMessageText: chat.lastMessageText,
        lastMessageAt: chat.lastMessageAt,
        unreadCount: chat.unreadCount,
        profilePicUrl: chat.profilePicUrl,
      );
    }
    return chat;
  }

  Future<void> _storeGroup(WaChat group) async {
    await db.upsertGroup(
      waGroupId: group.id,
      name: group.name,
      ownerId: group.ownerId,
    );
    var members = group.participants;
    if (members.isEmpty) {
      try {
        members = await engine.getParticipants(group.id);
      } catch (_) {}
    }
    if (members.isEmpty) return;
    await db.replaceGroupMembers(
      group.id,
      members
          .map(
            (member) => GroupMembersCompanion.insert(
              waGroupId: group.id,
              waId: member.waId,
              name: Value(
                DisplayNames.isWeak(member.name) ? null : member.name,
              ),
              isAdmin: Value(member.isAdmin),
            ),
          )
          .toList(),
    );
    for (final member in members) {
      if (DisplayNames.isWeak(member.name)) continue;
      await db.upsertContact(waId: member.waId, name: member.name!);
    }
  }

  Future<void> _storeMessages(
    List<WaMessage> messages, {
    bool bumpUnread = false,
  }) async {
    var stored = 0;
    for (final incoming in messages) {
      stored += 1;
      if (stored % 3 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      if (incoming.chatId.isEmpty) continue;
      if (ChatKinds.isSystemId(incoming.chatId) ||
          ChatKinds.isNoiseType(incoming.type)) {
        continue;
      }
      var message = incoming;
      if (!ChatKinds.isGroupId(message.chatId) &&
          !ChatKinds.isChannelId(message.chatId)) {
        final identity = await _identityFor(message.chatId, remote: false);
        if (identity.hidden && ChatKinds.isSystemId(identity.id)) continue;
        if (identity.usable && identity.id != message.chatId) {
          message = message.copyWith(chatId: identity.id);
        }
      }
      final isChannel = ChatKinds.isChannelId(message.chatId);
      final isGroup = ChatKinds.isGroupId(message.chatId);
      final existing = await db.chatByWaId(message.chatId);
      final storedGroup = isGroup ? await db.groupByWaId(message.chatId) : null;
      final senderId = message.senderId ?? '';
      final contact = await db.contactByIdentity(
        isGroup || isChannel ? senderId : message.chatId,
      );
      final memberName = isGroup && senderId.isNotEmpty
          ? await db.groupMemberName(message.chatId, senderId)
          : null;
      final chatName = isChannel
          ? DisplayNames.best(
              [existing?.name],
              fallback: existing?.name ?? 'قناة',
            )
          : isGroup
          ? DisplayNames.best(
              [storedGroup?.name],
              fallback: storedGroup?.name ?? 'مجموعة',
            )
          : DisplayNames.best(
              [contact?.name, existing?.name],
              fallback: existing?.name ?? DisplayNames.fromId(message.chatId),
            );
      final senderName = DisplayNames.best(
        [message.senderName, memberName, contact?.name],
        fallback: DisplayNames.fromId(senderId.isEmpty ? message.chatId : senderId),
      );
      final chat = await db.upsertChat(
        waChatId: message.chatId,
        name: chatName,
        isGroup: isGroup,
        lastMessageText: message.displayBody,
        lastMessageAt: message.timestamp,
      );
      if (message.fromMe) {
        await db.claimOptimisticOutgoing(
          chatId: chat.id,
          waMessageId: message.id,
          body: message.displayBody,
          type: message.type,
          timestamp: message.timestamp,
        );
      }
      final existed = await db.messageByWaId(message.id);
      var mediaPath = existed?.mediaLocalPath;
      if ((mediaPath == null || !localFileExists(mediaPath)) &&
          message.mediaBase64 != null) {
        mediaPath = await _writeMediaFile(
          message.id,
          message.type,
          message.mediaBase64!,
        );
      }
      await db.upsertMessage(
        waMessageId: message.id,
        chatId: chat.id,
        senderId: message.senderId,
        senderName: senderName,
        fromMe: message.fromMe,
        body: message.displayBody,
        timestamp: message.timestamp,
        type: message.type,
        hasMedia: message.hasMedia || mediaPath != null,
        mediaLocalPath: mediaPath,
        deliveryStatus: message.fromMe
            ? WaParsers.ackStatus(message.ack)
            : 'received',
      );
      final viewingNow = viewingChatId == chat.id && !_appInBackground;
      if (bumpUnread && existed == null && !message.fromMe && !viewingNow) {
        await db.incrementUnread(chat.id);
        final recent = message.timestamp.isAfter(
          DateTime.now().subtract(const Duration(minutes: 15)),
        );
        if (recent && _firstInboxReady && shellPhase.value == AppShellPhase.ready) {
          await notifications?.showIncoming(
            chatId: chat.id,
            title: DisplayNames.best(
              [chatName, senderName],
              fallback: 'رسالة جديدة',
            ),
            body: message.displayBody,
          );
        }
      }
      if (viewingNow && !message.fromMe) {
        await db.clearUnread(chat.id);
      }
      final needsFile = existed?.mediaLocalPath == null ||
          !localFileExists(existed!.mediaLocalPath) ||
          _isLikelyThumbnail(existed.mediaLocalPath, message.type);
      final shouldDownload = needsFile &&
          (message.hasMedia || ChatKinds.isMediaType(message.type));
      if (shouldDownload &&
          engine.isConnected &&
          viewingChatId == chat.id) {
        final row = await db.messageByWaId(message.id);
        if (row != null) {
          unawaited(() async {
            try {
              await downloadMessageMedia(row);
            } catch (_) {}
          }());
        }
      }
    }
  }

  void _setStatus(String value, String text) {
    status.value = value;
    statusText.value = text;
  }

  Future<void> dispose() async {
    _qrTimeout?.cancel();
    _liveTimer?.cancel();
    _healthTimer?.cancel();
    await _netSub?.cancel();
    await KeepAlive.stop();
    status.dispose();
    qrBytes.dispose();
    qrData.dispose();
    statusText.dispose();
    errorText.dispose();
    statusFeed.dispose();
    statusesLoading.dispose();
    myProfile.dispose();
    shellReady.dispose();
    shellPhase.dispose();
    bootstrapProgress.dispose();
    bootstrapLabel.dispose();
  }
}
