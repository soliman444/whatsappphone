import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:whatsapp_bot_flutter_mobile/whatsapp_bot_flutter_mobile.dart';
import 'package:whatsapp_bot_platform_interface/whatsapp_bot_platform_interface.dart';

import '../data/models/models.dart';
import 'web_wa_host.dart';
import 'web_wp_client.dart';
import 'whatsapp_engine.dart';

class WhatsAppService implements WhatsAppEngine {
  WhatsappClient? _client;
  HeadlessInAppWebView? _headless;
  Future<void>? _openingDone;
  bool _listening = false;
  bool _ackListening = false;
  MessageCallback? _messageHandler;
  void Function(String messageId, int ack)? _ackHandler;
  Future<void>? _wppBusy;
  Timer? _inboxPump;

  @override
  bool get isConnected => _client?.isConnected == true;

  @override
  Future<void> connect({
    required QrCallback onQr,
    required ConnectionCallback onEvent,
    bool persistSession = true,
  }) async {
    if (isConnected) {
      onEvent(AppConnectionStatus.online);
      return;
    }
    if (_openingDone != null) {
      await _openingDone;
      if (isConnected) onEvent(AppConnectionStatus.online);
      return;
    }
    final gate = Completer<void>();
    _openingDone = gate.future;
    try {
      await _connectLocked(
        onQr: onQr,
        onEvent: onEvent,
        persistSession: persistSession,
      );
    } finally {
      if (!gate.isCompleted) gate.complete();
      _openingDone = null;
    }
  }

  Future<void> _connectLocked({
    required QrCallback onQr,
    required ConnectionCallback onEvent,
    required bool persistSession,
  }) async {
    if (isConnected) {
      onEvent(AppConnectionStatus.online);
      return;
    }

    if (kIsWeb) {
      final wpClient = WebWpClient(await WebWaHost.waitForController());
      try {
        await WppConnect.init(
          wpClient,
          waitTimeOut: const Duration(seconds: 45),
          wppLibraryUrl:
              'https://cdn.jsdelivr.net/gh/wppconnect-team/wa-js@master/dist/wppconnect-wa.js',
        );
      } catch (_) {}
      await waitForLogin(
        wpClient,
        onQrCode: (String qr, Uint8List? imageBytes) {
          onQr(qr, imageBytes);
          onEvent(AppConnectionStatus.authRequired);
        },
        waitDurationSeconds: 90,
        onConnectionEvent: (event) => onEvent(_mapEvent(event)),
      );
      _client = WhatsappClient(wpClient: wpClient);
      await _waitUntilReady();
      await _quietWhatsAppUi();
      return;
    }

    final client = await WhatsappBotFlutterMobile.connect(
      saveSession: persistSession,
      qrCodeWaitDurationSeconds: 90,
      wppInitTimeout: const Duration(seconds: 90),
      wppLibraryUrl:
          'https://github.com/wppconnect-team/wa-js/releases/latest/download/wppconnect-wa.js',
      onWebViewCreated: (headless) {
        _headless = headless;
      },
      onQrCode: (String qr, Uint8List? imageBytes) {
        onQr(qr, imageBytes);
        onEvent(AppConnectionStatus.authRequired);
      },
      onConnectionEvent: (ConnectionEvent event) {
        onEvent(_mapEvent(event));
      },
    );
    if (client == null) {
      throw StateError('تعذر الاتصال بواتساب ويب');
    }
    _client = client;
    await _repairJsBridge();
    await _waitUntilReady();
    await _quietWhatsAppUi();
  }

  @override
  Future<bool> isReady() async {
    final client = _client;
    if (client == null || !client.isConnected) return false;
    try {
      final ready = await client.wpClient.evaluateJs(
        r'''
        (function () {
          try { if (window.WPP && WPP.conn && WPP.conn.isMainReady && WPP.conn.isMainReady()) return true; } catch (e) {}
          try { if (window.WPP && WPP.conn && WPP.conn.isAuthenticated && WPP.conn.isAuthenticated()) return true; } catch (e) {}
          return false;
        })()
        ''',
        methodName: 'isMainReady',
        tryPromise: false,
      );
      if (ready == true) return true;
    } catch (_) {}
    try {
      return await client.isReadyToChat;
    } catch (error) {
      return !_isWppMissing(error);
    }
  }

  @override
  Future<bool> isMainReady() async {
    final client = _client;
    if (client == null || !client.isConnected) return false;
    try {
      final ready = await client.wpClient.evaluateJs(
        r'''
        (function () {
          try { return !!(window.WPP && WPP.conn && WPP.conn.isMainReady && WPP.conn.isMainReady()); } catch (e) {}
          return false;
        })()
        ''',
        methodName: 'isMainReadyOnly',
        tryPromise: false,
      );
      return ready == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> disconnect({bool logout = false}) async {
    final client = _client;
    _client = null;
    _listening = false;
    _ackListening = false;
    _inboxPump?.cancel();
    _inboxPump = null;
    _messageHandler = null;
    _ackHandler = null;
    try {
      if (client != null) {
        await client.disconnect(tryLogout: logout);
      }
    } catch (_) {
      try {
        await _headless?.dispose();
      } catch (_) {}
    }
    _headless = null;
  }

  @override
  Future<List<WaChat>> getChats() async {
    final raw = await _runWpp(
      () => _requireClient().wpClient.evaluateJs(
        '''
        (async function () {
          $_jsSlimFn
          const chats = await WPP.chat.list();
          const result = [];
          const list = (Array.isArray(chats) ? chats : []).slice().sort(function (a, b) {
            return (b.t || 0) - (a.t || 0);
          });
          for (const chat of list.slice(0, 150)) {
            const id = sid(chat.id);
            if (!id || id === 'status@broadcast' || id.indexOf('@broadcast') !== -1) {
              continue;
            }
            const c = chat.contact || {};
            const isNewsletter = !!chat.isNewsletter || id.indexOf('@newsletter') !== -1;
            const last = chat.lastMessage || {};
            const preview = slimText(last.caption || last.body || last.notifyName, 80);
            result.push({
              id: id,
              isGroup: !!chat.isGroup && !isNewsletter,
              isNewsletter: isNewsletter,
              isChannel: isNewsletter,
              name: (!!chat.isGroup && !isNewsletter)
                ? (chat.name || chat.formattedTitle ||
                  (chat.groupMetadata && chat.groupMetadata.subject) || '')
                : (c.name || c.verifiedName || c.verifiedBizName ||
                  chat.name || chat.formattedTitle || c.pushname || ''),
              lastMessage: preview ? { body: preview, t: last.t || chat.t, type: last.type || 'chat' } : null,
              unreadCount: chat.unreadCount || 0,
              t: chat.t
            });
          }
          return result;
        })()
        ''',
        methodName: 'getChatsHydrated',
        forceJsonParseResult: true,
      ),
    );
    if (raw == null) return const [];
    return ParsedDynamic.asList(raw).map(WaParsers.chat).where((chat) {
      return chat.id.isNotEmpty && !ChatKinds.isSystemId(chat.id);
    }).toList();
  }

  @override
  Future<List<WaChat>> getChatPreviews() async {
    final raw = await _runWpp(
      () => _requireClient().wpClient.evaluateJs(
        '''
        (async function () {
          $_jsSlimFn
          const chats = await WPP.chat.list();
          const result = [];
          const list = Array.isArray(chats) ? chats : [];
          for (const chat of list.slice(0, 15)) {
            const id = sid(chat.id);
            if (!id || id === 'status@broadcast' || id.indexOf('@broadcast') !== -1) {
              continue;
            }
            const c = chat.contact || {};
            result.push({
              id: id,
              isGroup: !!chat.isGroup,
              isNewsletter: !!chat.isNewsletter || id.indexOf('@newsletter') !== -1,
              name: chat.name || chat.formattedTitle ||
                (chat.groupMetadata && chat.groupMetadata.subject) ||
                c.name || c.verifiedName || c.pushname || '',
              contact: slimContact(c),
              unreadCount: chat.unreadCount || 0,
              lastMessage: slimLast(chat.lastMessage),
              t: chat.t
            });
          }
          return result;
        })()
        ''',
        methodName: 'getChatPreviews',
        forceJsonParseResult: true,
      ),
    );
    if (raw == null) return const [];
    return ParsedDynamic.asList(raw).map(WaParsers.chat).where((chat) {
      return chat.id.isNotEmpty && !ChatKinds.isSystemId(chat.id);
    }).toList();
  }

  @override
  Future<WaChatIdentity> resolveChatIdentity(String id) async {
    if (ChatKinds.isSystemId(id)) {
      return WaChatIdentity(id: id, hidden: true);
    }
    if (ChatKinds.isGroupId(id) || ChatKinds.isChannelId(id)) {
      return WaChatIdentity(id: id);
    }
    final raw = await _runWpp(
      () => _requireClient().wpClient.evaluateJs(
        '''
        (async function () {
          $_jsInspectChatFn
          return await inspectChat(${_jsString(id)}, null);
        })()
        ''',
        methodName: 'resolveChatIdentity',
        forceJsonParseResult: true,
      ),
    );
    final map = ParsedDynamic.asMap(raw);
    if (map == null) {
      return WaChatIdentity(id: id);
    }
    final resolved = ParsedDynamic.serializedId(map['id']).isEmpty
        ? id
        : ParsedDynamic.serializedId(map['id']);
    final hidden = ParsedDynamic.flag(map['hidden']) || ChatKinds.isSystemId(resolved);
    return WaChatIdentity(
      id: resolved,
      phone: DisplayNames.phoneFromId(
        ParsedDynamic.text(map['phone']) ?? resolved,
      ),
      name: ParsedDynamic.text(map['name']),
      hidden: hidden,
    );
  }

  @override
  Future<WaChat?> getChat(String id) async {
    final raw = await _runWpp(
      () => _requireClient().wpClient.evaluateJs(
        'WPP.chat.get(${_jsString(id)})',
        methodName: 'getChat',
        forceJsonParseResult: true,
      ),
    );
    if (raw == null) return null;
    final chat = WaParsers.chat(raw);
    return chat.id.isEmpty ? null : chat;
  }

  @override
  Future<WaContact?> getContact(String id) async {
    final raw = await _runWpp(
      () => _requireClient().wpClient.evaluateJs(
        'WPP.contact.get(${_jsString(id)})',
        methodName: 'getContact',
        forceJsonParseResult: true,
      ),
    );
    if (raw == null) return null;
    final contact = WaParsers.contact(raw);
    return contact.waId.isEmpty ? null : contact;
  }

  @override
  Future<List<WaMessage>> getMessages(
    String chatId, {
    int count = 50,
    String? beforeId,
  }) async {
    final id = _sendId(chatId);
    final raw = await _runWpp(
      () => _requireClient().wpClient.evaluateJs(
        '''
        (async function () {
          $_jsSlimFn
          const chatId = ${_jsString(id)};
          const count = ${count.clamp(1, 80)};
          const beforeId = ${_jsString(beforeId ?? '')};
          try { await WPP.chat.find(chatId); } catch (e) {}

          function key(value) {
            if (!value) return '';
            const parts = String(value).split('_');
            return parts.length >= 3 ? parts[parts.length - 1] : String(value);
          }

          async function fetch(opts) {
            return slimMsgList(await WPP.chat.getMessages(chatId, opts));
          }

          async function loadEarlier() {
            try {
              const chat = await WPP.chat.get(chatId);
              const msgs = chat?.msgs;
              if (msgs?.loadEarlierMsgs) {
                for (let i = 0; i < 2; i++) {
                  try { await msgs.loadEarlierMsgs(); } catch (e) { break; }
                }
              }
            } catch (e) {}
          }

          if (beforeId) {
            try {
              const older = await fetch({
                count: count,
                direction: 'before',
                id: beforeId
              });
              if (older.length) return older;
            } catch (e) {}
            try {
              const older = await fetch({
                count: count,
                direction: 'before',
                id: key(beforeId)
              });
              if (older.length) return older;
            } catch (e) {}
            await loadEarlier();
            try {
              const older = await fetch({
                count: count,
                direction: 'before',
                id: beforeId
              });
              if (older.length) return older;
            } catch (e) {}
          }

          return await fetch({ count: count });
        })()
        ''',
        methodName: 'getMessages',
        forceJsonParseResult: true,
      ),
    );
    if (raw == null) return const [];
    return ParsedDynamic.asList(raw).map(WaParsers.message).where((message) {
      return message.id.isNotEmpty;
    }).toList();
  }

  @override
  Future<void> sendText(String chatId, String message) async {
    final id = _sendId(chatId);
    await _runWpp(
      () => _requireClient().wpClient.evaluateJs(
        '''
        (async function () {
          const id = ${_jsString(id)};
          try { await WPP.chat.find(id); } catch (e) {}
          return await WPP.chat.sendTextMessage(id, ${_jsString(message)});
        })()
        ''',
        methodName: 'sendTextMessage',
      ),
      required: true,
    );
  }

  @override
  Future<void> sendMedia({
    required String chatId,
    required List<int> bytes,
    required String type,
    String? caption,
    String? fileName,
  }) async {
    final id = _sendId(chatId);
    final mime = _mimeType(type, fileName);
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
    final wppType = (type == 'ptt' || type == 'audio') ? 'audio' : type;
    final isPtt = type == 'ptt';
    await _runWpp(
      () => _requireClient().wpClient.evaluateJs(
        '''
        (async function () {
          const id = ${_jsString(id)};
          try { await WPP.chat.find(id); } catch (e) {}
          return await WPP.chat.sendFileMessage(id, ${_jsString(dataUrl)}, {
            type: ${_jsString(wppType)},
            isPtt: $isPtt,
            filename: ${_jsString(fileName ?? 'file')},
            caption: ${caption == null ? 'undefined' : _jsString(caption)},
            waitForAck: true
          });
        })()
        ''',
        methodName: 'sendFileMessage',
      ),
      required: true,
    );
  }

  @override
  Future<void> forwardMessage({
    required String toChatId,
    required String messageId,
  }) async {
    final to = _sendId(toChatId);
    await _runWpp(
      () => _requireClient().wpClient.evaluateJs(
        '''
        (async function () {
          const to = ${_jsString(to)};
          const id = ${_jsString(messageId)};
          try { await WPP.chat.find(to); } catch (e) {}
          if (WPP.chat.forwardMessage) {
            return await WPP.chat.forwardMessage(to, id);
          }
          throw new Error('forwardMessage unavailable');
        })()
        ''',
        methodName: 'forwardMessage',
      ),
      required: true,
    );
  }

  @override
  Future<void> markSeen(String chatId) async {
    final id = _sendId(chatId);
    await _runWpp(
      () => _requireClient().wpClient.evaluateJs(
        '''
        (async function () {
          const id = ${_jsString(id)};
          try { await WPP.chat.find(id); } catch (e) {}
          try { await WPP.chat.markIsRead(id); } catch (e) {}
          try { await WPP.chat.sendSeen(id); } catch (e) {}
        })()
        ''',
        methodName: 'markSeen',
      ),
    );
  }

  @override
  Future<List<WaContact>> getContacts() async {
    final raw = await _runWpp(
      () => _requireClient().wpClient.evaluateJs(
        '''
        (async function () {
          const list = await WPP.contact.list();
          return (Array.isArray(list) ? list : []).slice(0, 400).map((c) => ({
            id: (c.id && c.id._serialized) ? c.id._serialized : String(c.id || ''),
            lid: (c.lid && c.lid._serialized) ? c.lid._serialized : '',
            name: c.name || '',
            verifiedName: c.verifiedName || '',
            verifiedBizName: c.verifiedBizName || '',
            pushname: c.pushname || '',
            formattedName: c.formattedName || '',
            shortName: c.shortName || '',
            number: c.number || c.phoneNumber || (c.id && c.id.server === 'c.us' ? c.id.user : '')
          }));
        })()
        ''',
        methodName: 'getContactsHydrated',
        forceJsonParseResult: true,
      ),
    ) ??
        await _runWpp(() => _requireClient().contact.getContacts());
    if (raw == null) return const [];
    final contacts = <WaContact>[];
    for (final item in ParsedDynamic.asList(raw)) {
      final contact = WaParsers.contact(item);
      if (contact.waId.isEmpty || DisplayNames.isWeak(contact.name)) continue;
      contacts.add(contact);
      for (final alias in contact.aliases) {
        if (alias.contains('@') || alias.length > 6) {
          contacts.add(
            WaContact(waId: alias, name: contact.name, phone: contact.phone),
          );
        }
      }
    }
    return contacts;
  }

  @override
  Future<Map<String, String>> getContactNameMap() async {
    final raw = await _runWpp(
      () => _requireClient().wpClient.evaluateJs(
        '''
        (async function () {
          function clean(name) {
            if (name == null) return '';
            name = String(name).trim();
            if (!name || name === 'null' || name.indexOf('@') !== -1) return '';
            if (/^\\+?\\d[\\d\\s-]{5,}\$/.test(name)) return '';
            return name;
          }
          function add(map, key, name) {
            name = clean(name);
            if (!key || !name) return;
            map[String(key)] = name;
          }
          const map = {};
          let contacts = [];
          try { contacts = await WPP.contact.list(); } catch (e) {}
          for (const c of contacts) {
            const name = c.name || c.verifiedName || c.verifiedBizName;
            const sid = c.id?._serialized || '';
            const user = c.id?.user || '';
            const server = c.id?.server || '';
            add(map, sid, name);
            add(map, user, name);
            if (user && server) add(map, user + '@' + server, name);
            const phone = c.number || c.phoneNumber || (server === 'c.us' ? user : '');
            add(map, phone, name);
            add(map, String(phone).replace(/\\D/g, ''), name);
            if (phone) add(map, String(phone).replace(/\\D/g, '') + '@c.us', name);
            const lid = c.lid?._serialized || c.id?.lid?._serialized || '';
            add(map, lid, name);
          }
          return map;
        })()
        ''',
        methodName: 'getContactNameMap',
        forceJsonParseResult: true,
      ),
    );
    final parsed = ParsedDynamic.asMap(raw);
    if (parsed == null) return const {};
    return parsed.map((key, value) {
      return MapEntry(key, value?.toString() ?? '');
    })..removeWhere((key, value) => DisplayNames.isWeak(value));
  }

  @override
  Future<Map<String, String>> getGroupNameMap() async {
    final raw = await _runWpp(
      () => _requireClient().wpClient.evaluateJs(
        '''
        (async function () {
          function clean(name) {
            if (name == null) return '';
            name = String(name).trim();
            if (!name || name === 'null' || name.indexOf('@') !== -1) return '';
            return name;
          }
          const map = {};
          let chats = [];
          try { chats = await WPP.chat.list({ onlyGroups: true }); } catch (e) {
            try { chats = await WPP.chat.list(); } catch (e2) {}
          }
          const list = Array.isArray(chats) ? chats : [];
          for (const chat of list) {
            const id = (chat.id && chat.id._serialized) || '';
            if (!id || id.indexOf('@g.us') === -1) continue;
            const name = clean(
              chat.name || chat.formattedTitle ||
              (chat.groupMetadata && chat.groupMetadata.subject) || ''
            );
            if (name) map[id] = name;
          }
          return map;
        })()
        ''',
        methodName: 'getGroupNameMap',
        forceJsonParseResult: true,
      ),
    );
    final parsed = ParsedDynamic.asMap(raw);
    if (parsed == null) return const {};
    return parsed.map((key, value) {
      return MapEntry(key, value?.toString() ?? '');
    })..removeWhere((key, value) => DisplayNames.isWeak(value));
  }

  @override
  Future<List<WaChat>> getGroups() async {
    try {
      final raw = await _requireClient().group.getAllGroups();
      return ParsedDynamic.asList(raw).map(WaParsers.chat).where((chat) {
        return chat.id.isNotEmpty;
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<WaParticipant>> getParticipants(String groupId) async {
    try {
      final raw = await _requireClient().group.getParticipants(
        groupId: groupId,
      );
      return ParsedDynamic.asList(raw)
          .map(WaParsers.participant)
          .where((member) => member.waId.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<String?> getProfilePicture(String id) async {
    try {
      final raw = await _requireClient().wpClient.evaluateJs(
        '''
        (async function () {
          const id = ${_jsString(_sendId(id))};
          async function urlOf(target) {
            try {
              let url = await WPP.contact.getProfilePictureUrl(target);
              if (url && typeof url === 'object') {
                url = url.eurl || url.imgFull || url.img || url.url || '';
              }
              return url || '';
            } catch (e) { return ''; }
          }
          let url = await urlOf(id);
          if (!url) {
            try {
              const pn = await WPP.contact.getPN(id);
              const phone = pn && (pn._serialized || pn.user || String(pn));
              if (phone) url = await urlOf(phone);
            } catch (e) {}
          }
          return url || '';
        })()
        ''',
        methodName: 'getProfilePicture',
        forceJsonParseResult: true,
      );
      final text = ParsedDynamic.text(raw);
      return (text == null || text.isEmpty) ? null : text;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<WaProfile> getMyProfile() async {
    final raw = await _runWpp(
      () => _requireClient().wpClient.evaluateJs(
        '''
        (async function () {
          const me = WPP.conn.getMyUserId?.() || WPP.conn.wid;
          const waId = me?._serialized || String(me || '');
          let name = '';
          try { name = await WPP.profile.getMyProfileName(); } catch (e) {}
          if (!name) {
            try { name = WPP.whatsapp.UserPrefs?.getPushname?.() || ''; } catch (e) {}
          }
          if (!name) {
            try {
              const c = await WPP.contact.get(waId);
              name = c?.pushname || c?.name || '';
            } catch (e) {}
          }
          let about = '';
          try { about = await WPP.profile.getMyStatus(); } catch (e) {}
          if (about && typeof about === 'object') {
            about = about.status || about.body || '';
          }
          let photo = '';
          try { photo = await WPP.contact.getProfilePictureUrl(waId); } catch (e) {}
          if (photo && typeof photo === 'object') {
            photo = photo.eurl || photo.imgFull || photo.img || '';
          }
          return {
            waId: waId,
            name: name || '',
            about: about || '',
            photoUrl: photo || '',
            phone: me?.user || String(waId).split('@')[0]
          };
        })()
        ''',
        methodName: 'getMyProfile',
        forceJsonParseResult: true,
      ),
    );
    final map = ParsedDynamic.asMap(raw) ?? const {};
    return WaProfile(
      waId: ParsedDynamic.serializedId(map['waId'] ?? map['id']),
      name: DisplayNames.best(
        [ParsedDynamic.text(map['name'])],
        fallback: 'حسابي',
      ),
      about: SafeText.display(ParsedDynamic.text(map['about'])),
      phone: ParsedDynamic.text(map['phone']),
      photoUrl: ParsedDynamic.text(map['photoUrl']),
    );
  }

  @override
  Future<void> setMyProfileName(String name) async {
    await _runWpp(
      () => _requireClient().wpClient.evaluateJs(
        '''
        (async function () {
          const name = ${_jsString(name)};
          try { return await WPP.profile.setMyProfileName(name); } catch (e) {}
          try { return await WPP.whatsapp.functions.setPushname(name); } catch (e) {}
        })()
        ''',
        methodName: 'setMyProfileName',
      ),
      required: true,
    );
  }

  @override
  Future<void> setMyAbout(String about) async {
    await _runWpp(
      () => _requireClient().profile.setMyStatus(status: about),
      required: true,
    );
  }

  @override
  Future<void> setMyProfilePicture(List<int> bytes) async {
    await _runWpp(
      () => _requireClient().profile.setMyProfilePicture(imageBytes: bytes),
      required: true,
    );
  }

  @override
  Future<String?> getContactAbout(String id) async {
    final raw = await _runWpp(
      () => _requireClient().contact.getStatus(phone: id),
    );
    if (raw is String) return raw;
    final map = ParsedDynamic.asMap(raw);
    return ParsedDynamic.text(map?['status']) ??
        ParsedDynamic.text(map?['body']);
  }

  @override
  Future<Map<String, dynamic>?> downloadMedia(String messageId) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      final raw = await _runWpp(
        () => _requireClient().wpClient.evaluateJs(
          '''
          (async function () {
            const id = ${_jsString(messageId)};
            async function toBase64(data) {
              if (!data) return '';
              if (typeof data === 'string') {
                if (data.indexOf('base64,') !== -1) return data.split('base64,').pop();
                return data.length > 20 ? data : '';
              }
              if (data instanceof Blob) {
                data = await data.arrayBuffer();
              }
              if (data instanceof ArrayBuffer) data = new Uint8Array(data);
              if (ArrayBuffer.isView(data)) {
                const bytes = new Uint8Array(data.buffer, data.byteOffset, data.byteLength);
                let binary = '';
                const chunk = 0x8000;
                for (let i = 0; i < bytes.length; i += chunk) {
                  binary += String.fromCharCode.apply(null, bytes.subarray(i, i + chunk));
                }
                return btoa(binary);
              }
              return data.data || data.base64 || data.base64Data || data.body || '';
            }
            async function pack(data, mime) {
              if (!data) return null;
              const encoded = await toBase64(data);
              if (!encoded || String(encoded).length < 20) return null;
              return {
                data: encoded,
                mimetype: (data && (data.mimetype || data.mimeType)) || mime || '',
                filename: (data && (data.filename || data.fileName)) || ''
              };
            }
            let msg = null;
            try { msg = await WPP.chat.getMessageById(id); } catch (e) {}
            const mime = msg?.mimetype || '';
            try {
              if (msg && msg.downloadMedia) {
                const file = await msg.downloadMedia({
                  downloadEvenIfExpensive: true,
                  rmrReason: 1
                });
                const packed = await pack(file, mime);
                if (packed) return packed;
              }
            } catch (e) {}
            try {
              const file = await WPP.chat.downloadMedia(id);
              const packed = await pack(file, mime);
              if (packed) return packed;
            } catch (e) {}
            return null;
          })()
          ''',
          methodName: 'downloadMediaRetry',
          forceJsonParseResult: true,
        ),
      );
      final map = ParsedDynamic.asMap(raw);
      final data = map?['data'] ?? map?['base64'] ?? map?['base64Data'];
      if (data is String && data.length > 20) {
        final mime = (map?['mimetype'] ?? map?['mimeType'] ?? '').toString();
        final audio = mime.contains('audio') ||
            mime.contains('ogg') ||
            mime.contains('opus') ||
            mime.contains('mpeg');
        if (audio && data.length > 400) return map;
        if (data.length > 120000 || attempt >= 6) return map;
      }
      try {
        final fallback = await _requireClient().chat.downloadMedia(
          messageId: _parseMessageId(messageId),
        );
        final parsed = ParsedDynamic.asMap(fallback);
        final encoded = parsed?['data'] ?? parsed?['base64'] ?? parsed?['base64Data'];
        if (encoded is String && encoded.length > 20) return parsed;
      } catch (_) {}
      await Future<void>.delayed(Duration(milliseconds: 350 + attempt * 250));
    }
    return null;
  }

  @override
  Future<StatusFeed> getStatusFeed() async {
    final raw = await _runWpp(
      () => _requireClient().wpClient.evaluateJs(
        '''
        (async function () {
          function contactName(c) {
            if (!c) return '';
            return c.name || c.verifiedName || c.verifiedBizName || c.pushname || c.formattedName || c.notifyName || '';
          }
          $_jsStatusViewersFn
          async function loadViewers(msg) {
            const packed = await fetchStatusViewers(msg.id?._serialized || msg.id, msg);
            return packed;
          }
          async function serializeMsg(msg, fromMe) {
            const packed = { viewers: [], viewCount: msg.viewCount || 0 };
            const rawBody = typeof msg.body === 'string' ? msg.body : '';
            const body = rawBody.indexOf('data:') === 0 || rawBody.length > 240
              ? ''
              : rawBody;
            return {
              id: msg.id?._serialized || msg.id?.id || String(msg.id || ''),
              type: msg.type || 'chat',
              body: body,
              caption: (msg.caption || '').toString().slice(0, 180),
              t: msg.t,
              backgroundColor: msg.backgroundColor || msg.bgColor,
              viewed: !!(msg.ack >= 1 || msg.isViewed || msg.viewed),
              viewCount: packed.viewCount || msg.viewCount || packed.viewers.length || 0,
              viewers: packed.viewers || []
            };
          }
          async function msgsFrom(model) {
            try {
              if (model?.msgs?.loadEarlierMsgs) {
                try { await model.msgs.loadEarlierMsgs(); } catch (e) {}
              }
            } catch (e) {}
            return model?.msgs?.getModelsArray?.() || model?.msgs?.toArray?.() || model?.msgs || model?.messages || [];
          }
          const result = { mine: null, others: [] };
          try {
            const mine = await WPP.status.getMyStatus();
            const list = await msgsFrom(mine);
            const items = [];
            for (const m of (Array.isArray(list) ? list : []).filter(Boolean)) {
              items.push(await serializeMsg(m, true));
            }
            result.mine = {
              authorId: 'me',
              authorName: 'حالتي',
              fromMe: true,
              unreadCount: 0,
              items
            };
          } catch (e) {}
          try {
            const Store = WPP.whatsapp.StatusV3Store || WPP.whatsapp.StatusStore;
            if (Store?.sync) { try { await Store.sync(); } catch (e) {} }
            const models = Store?.getModelsArray?.() || [];
            for (const model of models) {
              const id = model.id?._serialized || String(model.id || '');
              if (!id || id.indexOf('status@broadcast') !== -1) continue;
              const contact = model.contact || {};
              let fromMe = !!(model.id?.fromMe || contact.isMe);
              try {
                const me = WPP.conn.getMyUserId?.() || WPP.conn.wid;
                const meId = me?._serialized || String(me || '');
                if (meId && id === meId) fromMe = true;
              } catch (e) {}
              let msgs = await msgsFrom(model);
              if (!msgs || !msgs.length) {
                try {
                  const loaded = await WPP.status.get(id);
                  msgs = await msgsFrom(loaded);
                } catch (e) {}
              }
              const items = [];
              for (const m of (Array.isArray(msgs) ? msgs : []).filter(Boolean)) {
                items.push(await serializeMsg(m, fromMe));
              }
              const unread = model.unreadCount || items.filter((i) => !i.viewed).length;
              const thread = {
                authorId: id,
                authorName: contactName(contact),
                fromMe: fromMe,
                unreadCount: fromMe ? 0 : unread,
                items
              };
              if (fromMe) {
                if (!result.mine || !result.mine.items || !result.mine.items.length) {
                  result.mine = Object.assign({}, thread, { authorName: 'حالتي' });
                }
              } else if (items.length || unread) {
                result.others.push(thread);
              }
            }
          } catch (e) {}
          return result;
        })()
        ''',
        methodName: 'getStatusFeed',
        forceJsonParseResult: true,
      ),
    );
    final map = ParsedDynamic.asMap(raw) ?? const {};
    WaStatusThread? mine;
    final mineRaw = map['mine'];
    if (mineRaw != null) {
      mine = WaParsers.statusThread(mineRaw, fromMe: true);
    }
    final others = ParsedDynamic.asList(map['others'])
        .map((item) => WaParsers.statusThread(item))
        .where((thread) => thread.authorId.isNotEmpty)
        .toList();
    return StatusFeed(mine: mine, others: others);
  }

  @override
  Future<void> sendTextStatus(
    String text, {
    String backgroundColor = '#075E54',
  }) async {
    final raw = await _runWpp(
      () => _requireClient().wpClient.evaluateJs(
        '''
        (async function () {
          $_jsEnableStatusPosting
          if (!WPP.conn.isMainReady || !WPP.conn.isMainReady()) {
            throw new Error('WPP not ready');
          }
          const text = ${_jsString(text)};
          const bg = ${_jsString(backgroundColor)};
          enableCompanionStatusPosting();
          let res = null;
          try {
            res = await WPP.status.sendTextStatus(text, {
              backgroundColor: bg,
              font: 2,
              waitForAck: true
            });
          } catch (e) {}
          if (!res) {
            try {
              res = await WPP.chat.sendTextMessage('status@broadcast', text, {
                backgroundColor: bg,
                font: 2,
                waitForAck: true
              });
            } catch (e) {}
          }
          return await confirmStatusSend(res, text);
        })()
        ''',
        methodName: 'sendTextStatus',
        forceJsonParseResult: true,
      ),
      required: true,
    );
    _assertStatusPublished(raw);
  }

  @override
  Future<void> sendImageStatus(List<int> bytes) async {
    await _sendMediaStatus(bytes, type: 'image');
  }

  @override
  Future<void> markStatusRead(String authorId, String statusId) async {
    await _runWpp(
      () => _requireClient().status.sendReadStatus(
        phone: authorId,
        statusId: statusId,
      ),
    );
  }

  @override
  Future<void> sendVideoStatus(List<int> bytes) async {
    await _sendMediaStatus(bytes, type: 'video');
  }

  Future<void> _sendMediaStatus(
    List<int> bytes, {
    required String type,
  }) async {
    final mime = type == 'video' ? 'video/mp4' : 'image/jpeg';
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
    final raw = await _runWpp(
      () => _requireClient().wpClient.evaluateJs(
        '''
        (async function () {
          $_jsEnableStatusPosting
          if (!WPP.conn.isMainReady || !WPP.conn.isMainReady()) {
            throw new Error('WPP not ready');
          }
          const file = ${_jsString(dataUrl)};
          const kind = ${_jsString(type)};
          enableCompanionStatusPosting();
          let res = null;
          try {
            res = kind === 'video'
              ? await WPP.status.sendVideoStatus(file, { waitForAck: true })
              : await WPP.status.sendImageStatus(file, { waitForAck: true });
          } catch (e) {}
          if (!res) {
            try {
              res = await WPP.chat.sendFileMessage('status@broadcast', file, {
                type: kind,
                waitForAck: true
              });
            } catch (e) {}
          }
          return await confirmStatusSend(res, '');
        })()
        ''',
        methodName: 'sendMediaStatus',
        forceJsonParseResult: true,
      ),
      required: true,
    );
    _assertStatusPublished(raw);
  }

  void _assertStatusPublished(dynamic raw) {
    final map = ParsedDynamic.asMap(raw);
    if (map != null && ParsedDynamic.flag(map['ok'])) return;
    throw StateError('تعذر رفع الحالة إلى واتساب');
  }

  @override
  Future<void> removeStatus(String statusId) async {
    await _runWpp(
      () => _requireClient().status.remove(statusId: statusId),
      required: true,
    );
  }

  @override
  Future<WaStatusViews> getStatusViewers(String statusId) async {
    final raw = await _runWpp(
      () => _requireClient().wpClient.evaluateJs(
        '''
        (async function () {
          $_jsStatusViewersFn
          return await fetchStatusViewers(${_jsString(statusId)}, null);
        })()
        ''',
        methodName: 'getStatusViewers',
        forceJsonParseResult: true,
      ),
    );
    final map = ParsedDynamic.asMap(raw);
    final viewers = ParsedDynamic.asList(map?['viewers'] ?? raw)
        .map(WaParsers.statusViewer)
        .where((viewer) => viewer.waId.isNotEmpty)
        .toList();
    final hiddenRaw = map?['hiddenCount'];
    int? hiddenCount;
    if (hiddenRaw is num) {
      final value = hiddenRaw.toInt();
      if (value > 0) hiddenCount = value;
    }
    return WaStatusViews(
      count: viewers.length,
      viewers: viewers,
      hiddenCount: hiddenCount,
    );
  }

  MessageId _parseMessageId(String serialized) {
    final parts = serialized.split('_');
    if (parts.length >= 3) {
      return MessageId(
        fromMe: parts.first.toLowerCase() == 'true',
        remote: parts.sublist(1, parts.length - 1).join('_'),
        id: parts.last,
        serialized: serialized,
      );
    }
    return MessageId(
      fromMe: serialized.startsWith('true'),
      remote: serialized,
      id: serialized,
      serialized: serialized,
    );
  }

  @override
  Future<void> listenMessages(MessageCallback onMessage) async {
    final client = _client;
    if (client == null) return;
    _messageHandler = onMessage;
    await _repairJsBridge();
    await _installMailbox();
    await _installStatusViewerHook();
    _startInboxPump();
    if (!_listening) {
      _listening = true;
      await client.on(WhatsappEvent.chatNewMessage, (data) {
        final handler = _messageHandler;
        if (handler == null) return;
        dynamic raw = data;
        if (raw is List && raw.isNotEmpty) raw = raw.first;
        if (raw is Map) {
          handler(WaParsers.message(raw));
          return;
        }
        for (final item in _parseEventMessages(raw)) {
          handler(item);
        }
      });
    }
    try {
      await client.wpClient.evaluateJs(
        r'''
        (function () {
          WPP.removeAllListeners('chat.new_message');
          WPP.on('chat.new_message', (msg) => {
            try {
              if (msg && msg.isNewMsg === false) return;
              const slim = function (v, max) {
                if (v == null) return '';
                const text = String(v);
                if (text.indexOf('data:') === 0) return '';
                return text.length > max ? text.slice(0, max) : text;
              };
              const payload = {
                id: {
                  _serialized: (msg.id && msg.id._serialized) || '',
                  fromMe: !!(msg.id && msg.id.fromMe),
                  remote: (msg.id && msg.id.remote && msg.id.remote._serialized) || (msg.id && msg.id.remote) || '',
                  id: (msg.id && msg.id.id) || ''
                },
                from: (msg.from && msg.from._serialized) || msg.from,
                to: (msg.to && msg.to._serialized) || msg.to,
                body: slim(msg.body || msg.caption, 20000),
                caption: slim(msg.caption, 4000),
                type: msg.type || 'chat',
                t: msg.t,
                notifyName: slim(msg.notifyName || msg.notify, 40),
                ack: msg.ack,
                hasMedia: !!(msg.isMedia || msg.deprecatedMms3Url)
              };
              window.__raselInbox = window.__raselInbox || [];
              window.__raselInbox.push(payload);
              if (window.__raselInbox.length > 120) {
                window.__raselInbox.splice(0, window.__raselInbox.length - 120);
              }
              try {
                if (window.callback_chat_new_message) {
                  window.callback_chat_new_message(payload);
                }
              } catch (e) {}
            } catch (e) {}
          });
        })()
        ''',
        methodName: 'listenSerializedMessages',
        tryPromise: false,
      );
    } catch (_) {}
  }

  @override
  Future<void> listenAck(void Function(String messageId, int ack) onAck) async {
    final client = _client;
    if (client == null) return;
    _ackHandler = onAck;

    void emit(dynamic payload) {
      final map = ParsedDynamic.asMap(
            payload is List && payload.isNotEmpty ? payload.first : payload,
          ) ??
          const {};
      final ack = ParsedDynamic.number(map['ack'] ?? map['ackValue']);
      final ids = <String>[];
      final rawIds = map['ids'] ?? map['id'] ?? map['messageId'] ?? map['msgId'];
      if (rawIds is List) {
        for (final item in rawIds) {
          final id = ParsedDynamic.serializedId(item);
          if (id.isNotEmpty) ids.add(id);
        }
      } else {
        final id = ParsedDynamic.serializedId(rawIds);
        if (id.isNotEmpty) ids.add(id);
      }
      for (final id in ids) {
        _ackHandler?.call(id, ack);
      }
    }

    if (!_ackListening) {
      _ackListening = true;
      await client.on(WhatsappEvent.chatMsgAckChange, emit);
    }
    try {
      await client.wpClient.evaluateJs(
        r'''
        (function () {
          WPP.on('chat.msg_ack_change', (data) => {
            try {
              if (window.__raselCaptureStatusAck) window.__raselCaptureStatusAck(data);
              const ids = [];
              const raw = (data && (data.ids || data.id)) || [];
              const list = Array.isArray(raw) ? raw : [raw];
              for (const item of list) {
                const id = (item && (item._serialized || item.id)) || String(item || '');
                if (id) ids.push(id);
              }
              if (window.callback_chat_msg_ack_change) {
                window.callback_chat_msg_ack_change({
                  ack: (data && (data.ack != null ? data.ack : data.ackValue)) || 0,
                  ids: ids
                });
              }
            } catch (e) {}
          });
        })()
        ''',
        methodName: 'listenSerializedAcks',
        tryPromise: false,
      );
    } catch (_) {}
    await _installStatusViewerHook();
  }

  List<WaMessage> _parseEventMessages(dynamic data) {
    try {
      return Message.parse(data).map((message) {
        return WaParsers.message({
          'id': {
            '_serialized': message.id?.serialized ??
                '${message.id?.remote}_${message.id?.id}',
            'fromMe': message.id?.fromMe,
            'remote': message.id?.remote,
          },
          'from': message.from,
          'to': message.to,
          'body': message.body,
          'caption': message.caption,
          'type': message.type,
          't': message.t,
          'notifyName': message.notifyName,
          'hasMedia': const {
            'image',
            'video',
            'audio',
            'ptt',
            'document',
            'sticker',
          }.contains(message.type),
        });
      }).toList();
    } catch (_) {
      return ParsedDynamic.asList(data).map(WaParsers.message).toList();
    }
  }

  WhatsappClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('WhatsApp is not connected');
    }
    return client;
  }

  Future<T?> _runWpp<T>(
    Future<T> Function() action, {
    bool required = false,
  }) async {
    while (_wppBusy != null) {
      try {
        await _wppBusy;
      } catch (_) {}
    }
    final gate = Completer<void>();
    _wppBusy = gate.future;
    try {
      return await action();
    } catch (error) {
      if (_isWppMissing(error)) {
        if (required) {
          throw StateError('واتساب ويب غير جاهز بعد، أعد المحاولة بعد الاتصال');
        }
        return null;
      }
      if (required) rethrow;
      return null;
    } finally {
      if (!gate.isCompleted) gate.complete();
      if (identical(_wppBusy, gate.future)) _wppBusy = null;
    }
  }

  Future<void> _repairJsBridge() async {
    final client = _client;
    if (client == null) return;
    try {
      await client.wpClient.evaluateJs(
        r'''
        (function () {
          var native = window.flutter_inappwebview;
          if (!native) return;
          if (typeof native.callHandler === 'function') return;
          native.callHandler = function () {
            var id = setTimeout(function () {});
            native._callHandler(arguments[0], id, JSON.stringify(Array.prototype.slice.call(arguments, 1)));
            return new Promise(function (resolve, reject) {
              native[id] = { resolve: resolve, reject: reject };
            });
          };
        })()
        ''',
        methodName: 'repairJsBridge',
        tryPromise: false,
      );
    } catch (_) {}
  }

  Future<void> _installStatusViewerHook() async {
    final client = _client;
    if (client == null) return;
    try {
      await client.wpClient.evaluateJs(
        r'''
        (function () {
          window.__raselStatusViews = window.__raselStatusViews || {};
          function sid(v) {
            if (!v) return '';
            if (typeof v === 'string') return v;
            if (v._serialized) return v._serialized;
            if (v.user && v.server) return v.user + '@' + v.server;
            if (v.id && v.id._serialized) return v.id._serialized;
            return '';
          }
          function remember(statusId, viewer, kind, t) {
            if (!statusId || !viewer) return;
            if (viewer.indexOf('status@') !== -1) return;
            const list = window.__raselStatusViews[statusId] = window.__raselStatusViews[statusId] || [];
            if (list.some((x) => x.waId === viewer || (x.waId && x.waId.split('@')[0] === viewer.split('@')[0]))) {
              return;
            }
            list.push({
              waId: viewer,
              name: '',
              timestamp: t || null,
              hiddenReceipt: kind !== 'read'
            });
          }
          function bumpReceipt(id, hasParticipant, ack) {
            if (!id) return;
            window.__raselStatusReceipts = window.__raselStatusReceipts || {};
            const bag = window.__raselStatusReceipts[id] = window.__raselStatusReceipts[id] || { named: 0, anon: 0 };
            if (hasParticipant) bag.named += 1;
            else if (ack >= 3) bag.anon += 1;
          }
          function captureAck(ackData) {
            if (!ackData) return;
            const from = sid(ackData.from || ackData.chat);
            const viewer = sid(ackData.participant || ackData.sender);
            const isStatus = from.indexOf('status@') !== -1 || String(ackData.ackString || '').indexOf('status') !== -1;
            if (!isStatus) return;
            const ack = ackData.ack || 0;
            const hasParticipant = !!(viewer && viewer.indexOf('status@') === -1);
            const ids = ackData.externalIds || ackData.ids || [];
            const list = Array.isArray(ids) ? ids : [ids];
            if (!list.length) bumpReceipt('status@broadcast', hasParticipant, ack);
            for (const item of list) {
              const id = sid(item) || String(item || '');
              if (!id) continue;
              bumpReceipt(id, hasParticipant, ack);
              const short = id.indexOf('_') !== -1 ? id.split('_').pop() : id;
              if (short && short !== id) bumpReceipt(short, hasParticipant, ack);
              if (hasParticipant) {
                const kind = (ack >= 4 || ackData.ackString === 'played') ? 'played' : 'read';
                remember(id, viewer, kind, ackData.t);
                if (short && short !== id) remember(short, viewer, kind, ackData.t);
              }
            }
          }
          window.__raselCaptureStatusAck = captureAck;
          function wrapReceipt(name) {
            try {
              const fns = WPP.whatsapp.functions;
              const orig = fns && fns[name];
              if (typeof orig !== 'function' || orig.__raselWrapped) return;
              const wrapped = function (ackData) {
                try { captureAck(ackData); } catch (e) {}
                return orig.apply(this, arguments);
              };
              wrapped.__raselWrapped = true;
              fns[name] = wrapped;
            } catch (e) {}
          }
          wrapReceipt('handleStatusSimpleReceipt');
          wrapReceipt('handleChatSimpleReceipt');
          wrapReceipt('handleGroupSimpleReceipt');
          try {
            if (WPP.webpack && WPP.webpack.search && !window.__raselWebpackReceipt) {
              const mod = WPP.webpack.search(function (m) {
                return m && typeof m.handleStatusSimpleReceipt === 'function';
              });
              if (mod && !mod.handleStatusSimpleReceipt.__raselWrapped) {
                const orig = mod.handleStatusSimpleReceipt;
                const wrapped = function (ackData) {
                  try { captureAck(ackData); } catch (e) {}
                  return orig.apply(this, arguments);
                };
                wrapped.__raselWrapped = true;
                mod.handleStatusSimpleReceipt = wrapped;
              }
              window.__raselWebpackReceipt = true;
            }
          } catch (e) {}
          try {
            WPP.on('chat.msg_ack_change', function (data) {
              try { captureAck(data); } catch (e) {}
            });
          } catch (e) {}
          function fromInfo(info) {
            try {
              const id = (info && info.id && (info.id._serialized || String(info.id))) || '';
              if (!id || id.indexOf('status@') === -1) return;
              const groups = [info.played, info.read, info.viewed, info.viewedBy, info.playedBy];
              for (let i = 0; i < groups.length; i++) {
                const rows = groups[i] && groups[i].getModelsArray
                  ? groups[i].getModelsArray()
                  : (Array.isArray(groups[i]) ? groups[i] : []);
                for (const row of rows) {
                  const wid = (row && row.id && row.id._serialized) || (row && row._serialized) || '';
                  if (wid) remember(id, wid, i === 1 ? 'read' : 'played', row && row.t);
                }
              }
            } catch (e) {}
          }
          try {
            const store = WPP.whatsapp.MsgInfoStore;
            if (store && store.on && !window.__raselStatusHook) {
              store.on('change', fromInfo);
              store.on('add', fromInfo);
            }
          } catch (e) {}
          window.__raselStatusHook = true;
        })()
        ''',
        methodName: 'statusViewerHook',
        tryPromise: false,
      );
    } catch (_) {}
  }

  Future<void> _installMailbox() async {
    final client = _client;
    if (client == null) return;
    try {
      await client.wpClient.evaluateJs(
        r'''
        (function () {
          window.__raselInbox = window.__raselInbox || [];
        })()
        ''',
        methodName: 'installMailbox',
        tryPromise: false,
      );
    } catch (_) {}
  }

  @override
  Future<void> keepAlivePulse() async {
    if (_client == null) return;
    try {
      await _requireClient().wpClient.evaluateJs(
        r'''
        (function () {
          try {
            if (window.WPP && WPP.conn && typeof WPP.conn.keepAlive === 'function') {
              WPP.conn.keepAlive();
            }
          } catch (e) {}
          return true;
        })()
        ''',
        methodName: 'keepAlivePulse',
        tryPromise: false,
      );
    } catch (_) {}
    await _repairJsBridge();
    _startInboxPump();
    await _drainJsInbox();
  }

  void _startInboxPump() {
    _inboxPump?.cancel();
    _inboxPump = Timer.periodic(const Duration(seconds: 4), (_) {
      unawaited(_drainJsInbox());
    });
    unawaited(_drainJsInbox());
  }

  Future<void> _drainJsInbox() async {
    final handler = _messageHandler;
    final client = _client;
    if (handler == null || client == null) return;
    try {
      final raw = await client.wpClient.evaluateJs(
        r'''
        (async function () {
          var q = window.__raselInbox || [];
          window.__raselInbox = [];
          return q;
        })()
        ''',
        methodName: 'drainMailbox',
        forceJsonParseResult: true,
      );
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) handler(WaParsers.message(item));
        }
      } else {
        for (final item in _parseEventMessages(raw)) {
          handler(item);
        }
      }
    } catch (_) {}
  }

  Future<void> _quietWhatsAppUi() async {
    await _runWpp(
      () => _requireClient().wpClient.evaluateJs(
        r'''
        (function () {
          try {
            document.querySelectorAll('video, audio').forEach((el) => {
              try { el.pause(); el.muted = true; } catch (e) {}
            });
          } catch (e) {}
        })()
        ''',
        methodName: 'quietWhatsAppUi',
        tryPromise: false,
      ),
    );
  }

  Future<void> _waitUntilReady() async {
    for (var attempt = 0; attempt < 24; attempt++) {
      if (await isMainReady()) return;
      if (attempt >= 8 && await isReady()) return;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  String _jsString(String value) => jsonEncode(value);

  static const _jsStatusViewersFn = r'''
          function viewerId(v) {
            if (!v) return '';
            if (typeof v === 'string') {
              if (v.indexOf('@') !== -1) return v;
              if (/^\d{15,}$/.test(v)) return v + '@lid';
              if (/^\d{8,14}$/.test(v)) return v + '@c.us';
              return '';
            }
            if (v._serialized) return v._serialized;
            if (v.user && v.server) return v.user + '@' + v.server;
            const nested = [v.id, v.wid, v.participant, v.author, v.contact, v.phoneNumber, v.lid, v._lid];
            for (const item of nested) {
              if (!item || item === v) continue;
              const inner = viewerId(item);
              if (inner) return inner;
            }
            try {
              const text = String(v.toString ? v.toString() : v);
              return text.indexOf('@') !== -1 ? text : '';
            } catch (e) { return ''; }
          }
          function viewerTime(v) {
            if (!v || typeof v !== 'object') return null;
            return v.t || v.timestamp || v.readT || v.playedT || null;
          }
          function localName(id) {
            try {
              const c = WPP.whatsapp.ContactStore.get(id);
              return (c && (c.name || c.verifiedName || c.verifiedBizName || c.pushname || c.formattedName)) || '';
            } catch (e) {}
            return '';
          }
          function asRows(list) {
            if (!list) return [];
            if (Array.isArray(list)) return list;
            if (list.getModelsArray) return list.getModelsArray();
            if (list.toArray) return list.toArray();
            if (list.models) return list.models;
            if (list._models) return list._models;
            if (typeof list === 'object') return Object.values(list);
            return [];
          }
          function isMe(id) {
            if (!id) return false;
            try {
              const me = WPP.conn.getMyUserId && WPP.conn.getMyUserId();
              if (me && (me._serialized === id || String(me) === id)) return true;
              if (me && me.user && id.indexOf(me.user + '@') === 0) return true;
            } catch (e) {}
            try {
              const lid = WPP.conn.getMyUserLid && WPP.conn.getMyUserLid();
              if (lid && (lid._serialized === id || String(lid) === id)) return true;
            } catch (e) {}
            return false;
          }
          function addViewers(out, seen, list, kind) {
            if (!list) return;
            for (const v of asRows(list)) {
              const id = viewerId(v);
              if (!id || id === '[object Object]' || isMe(id)) continue;
              if (id.indexOf('status@') !== -1 || id.indexOf('@broadcast') !== -1) continue;
              const user = id.split('@')[0];
              if (seen[id] || (user && seen[user])) continue;
              seen[id] = kind || 'read';
              if (user) seen[user] = kind || 'read';
              out.push({
                waId: id,
                name: (v && (v.name || v.pushname || v.notifyName)) || localName(id),
                timestamp: viewerTime(v),
                hiddenReceipt: kind === 'hidden' || kind === 'played'
              });
            }
          }
          function addIfViewed(out, seen, list) {
            for (const v of asRows(list)) {
              if (!v || typeof v !== 'object') continue;
              const viewed = v.playedT || v.readT || v.viewedT || v.played || v.isViewed || v.viewed || (v.ack && v.ack >= 3);
              if (!viewed) continue;
              addViewers(out, seen, [v], 'played');
            }
          }
          function collectInfo(out, seen, info) {
            if (!info) return;
            addViewers(out, seen, info.read, 'read');
            addViewers(out, seen, info.viewed, 'read');
            addViewers(out, seen, info.viewers, 'read');
            addViewers(out, seen, info.views, 'read');
            addViewers(out, seen, info.played, 'played');
            addViewers(out, seen, info.playedBy, 'played');
            addViewers(out, seen, info.seenBy, 'played');
            addViewers(out, seen, info.viewedBy, 'played');
            addViewers(out, seen, info.hidden, 'hidden');
            addViewers(out, seen, info.hiddenRead, 'hidden');
            addViewers(out, seen, info.privacyRead, 'hidden');
            addIfViewed(out, seen, info.delivery);
            addIfViewed(out, seen, info.remaining);
            if (Array.isArray(info)) addViewers(out, seen, info, 'read');
          }
          function rememberLocal(statusId, list) {
            window.__raselStatusViews = window.__raselStatusViews || {};
            const bucket = window.__raselStatusViews[statusId] = window.__raselStatusViews[statusId] || [];
            for (const row of list || []) {
              if (!row || !row.waId) continue;
              if (bucket.some((x) => x.waId === row.waId)) continue;
              bucket.push(row);
            }
          }
          async function preferPhone(id) {
            if (!id || id.indexOf('@lid') === -1) return id;
            try {
              if (WPP.contact && WPP.contact.getPN) {
                const pn = await WPP.contact.getPN(id);
                if (pn && pn._serialized) return pn._serialized;
                if (pn && pn.user) return pn.user + '@c.us';
                if (typeof pn === 'string' && pn) {
                  return pn.indexOf('@') === -1 ? (pn + '@c.us') : pn;
                }
              }
            } catch (e) {}
            try {
              const c = WPP.whatsapp.ContactStore.get(id);
              const p = c && c.phoneNumber && (c.phoneNumber._serialized || viewerId(c.phoneNumber));
              if (p) return p;
            } catch (e) {}
            return id;
          }
          async function requireQuery(msg) {
            const names = [
              'WAWebApiMessageInfoStore',
              'WAWebFrontendMsgInfoBridge',
              'WAWebStatusUtils',
              'WAWebStatusMsgInfoCollection',
              'WAWebApiStatus',
              'WAWebStatusMsgAction'
            ];
            const req = window.require || (WPP.webpack && WPP.webpack.require);
            if (typeof req !== 'function') return;
            for (const name of names) {
              try {
                const mod = req(name);
                if (!mod) continue;
                if (typeof mod.queryMsgInfo === 'function') await mod.queryMsgInfo(msg.id);
                if (typeof mod.find === 'function') await mod.find(msg.id);
                if (typeof mod.updateStatusViewers === 'function') await mod.updateStatusViewers(msg);
                if (typeof mod.queryStatusViewers === 'function') await mod.queryStatusViewers(msg);
                if (typeof mod.queryAndUpdateStatusViewers === 'function') await mod.queryAndUpdateStatusViewers(msg);
              } catch (e) {}
            }
          }
          async function fetchStatusViewers(statusId, knownMsg) {
            const out = [];
            const seen = {};
            let msg = knownMsg || null;
            try { if (!msg) msg = await WPP.chat.getMessageById(statusId); } catch (e) {}
            if (!msg) {
              try {
                const mine = await WPP.status.getMyStatus();
                const msgs = mine?.msgs?.getModelsArray?.() || mine?.msgs?.toArray?.() || [];
                msg = msgs.find((m) => {
                  const full = m.id?._serialized || '';
                  const short = m.id?.id || '';
                  return full === statusId || short === statusId || full.endsWith(statusId) || (short && statusId.indexOf(short) !== -1);
                }) || null;
              } catch (e) {}
            }
            const key = (msg && msg.id && msg.id._serialized) || statusId;
            const short = (msg && msg.id && msg.id.id) || (String(statusId).split('_').pop()) || '';
            try {
              const bag = window.__raselStatusViews || {};
              addViewers(out, seen, bag[key], 'played');
              addViewers(out, seen, bag[statusId], 'played');
              if (short) addViewers(out, seen, bag[short], 'played');
              addViewers(out, seen, bag['status@broadcast'], 'played');
            } catch (e) {}
            if (!msg) {
              rememberLocal(statusId, out);
              return { viewers: out, viewCount: out.length };
            }
            try {
              const local = WPP.whatsapp.MsgInfoStore.get(msg.id) || (WPP.whatsapp.MsgInfo && WPP.whatsapp.MsgInfo.get && WPP.whatsapp.MsgInfo.get(msg.id));
              collectInfo(out, seen, local);
            } catch (e) {}
            try { addViewers(out, seen, msg.views, 'read'); } catch (e) {}
            try { addViewers(out, seen, msg.viewedBy, 'played'); } catch (e) {}
            try { addViewers(out, seen, msg.viewers, 'read'); } catch (e) {}
            try { addViewers(out, seen, msg.playedBy, 'played'); } catch (e) {}
            try { await WPP.whatsapp.MsgInfoStore.find(msg.id); } catch (e) {}
            try { if (WPP.whatsapp.MsgInfo && WPP.whatsapp.MsgInfo.find) await WPP.whatsapp.MsgInfo.find(msg.id); } catch (e) {}
            try {
              if (WPP.whatsapp.functions && WPP.whatsapp.functions.queryMsgInfo) {
                collectInfo(out, seen, await WPP.whatsapp.functions.queryMsgInfo(msg.id));
              }
            } catch (e) {}
            try { await requireQuery(msg); } catch (e) {}
            try {
              if (WPP.chat.getMessageInfo) {
                collectInfo(out, seen, await WPP.chat.getMessageInfo(msg.id?._serialized || statusId));
              }
            } catch (e) {}
            try {
              if (WPP.status.getStatusViewers) addViewers(out, seen, await WPP.status.getStatusViewers(statusId), 'read');
            } catch (e) {}
            try {
              if (WPP.status.getViewers) addViewers(out, seen, await WPP.status.getViewers(statusId), 'read');
            } catch (e) {}
            try {
              const su = WPP.whatsapp.StatusUtils;
              if (su) {
                if (su.updateStatusViewers) await su.updateStatusViewers(msg);
                if (su.getStatusViewers) addViewers(out, seen, su.getStatusViewers(msg), 'played');
              }
            } catch (e) {}
            try {
              const later = WPP.whatsapp.MsgInfoStore.get(msg.id) || (WPP.whatsapp.MsgInfo && WPP.whatsapp.MsgInfo.get && WPP.whatsapp.MsgInfo.get(msg.id));
              collectInfo(out, seen, later);
            } catch (e) {}
            for (let i = 0; i < out.length && i < 25; i++) {
              out[i].waId = await preferPhone(out[i].waId);
              if (!out[i].name) out[i].name = localName(out[i].waId);
            }
            rememberLocal(key, out);
            let laterInfo = null;
            try {
              laterInfo = WPP.whatsapp.MsgInfoStore.get(msg.id) || (WPP.whatsapp.MsgInfo && WPP.whatsapp.MsgInfo.get && WPP.whatsapp.MsgInfo.get(msg.id));
            } catch (e) {}
            const recBag = (window.__raselStatusReceipts || {});
            const rec = recBag[key] || recBag[short] || recBag[statusId] || {};
            const visible = out.length;
            const aggregate = Math.max(msg.viewCount || 0, msg.viewsCount || 0);
            const anon = rec.anon || 0;
            let hiddenCount = null;
            if (aggregate > visible) hiddenCount = aggregate - visible;
            else if (anon > 0) hiddenCount = anon;
            return {
              viewers: out,
              viewCount: visible,
              hiddenCount: hiddenCount,
              counts: {
                read: laterInfo ? asRows(laterInfo.read).length : 0,
                played: laterInfo ? asRows(laterInfo.played).length : 0,
                viewed: laterInfo ? asRows(laterInfo.viewed || laterInfo.viewers).length : 0,
                delivery: laterInfo ? asRows(laterInfo.delivery).length : 0,
                viewCount: msg.viewCount || 0,
                viewsCount: msg.viewsCount || 0,
                anonReceipts: anon
              }
            };
          }
  ''';

  static const _jsEnableStatusPosting = r'''
          function enableCompanionStatusPosting() {
            function wrapAB(fn) {
              if (!fn || fn.__raselStatusPatched) return fn;
              const orig = fn;
              const wrapped = function (key) {
                if (key === 'web_status_posting_enabled' || key === 'post_status_in_companion') return 1;
                return orig.apply(this, arguments);
              };
              wrapped.__raselStatusPatched = true;
              return wrapped;
            }
            function wrapFeature(fn) {
              if (!fn || fn.__raselStatusPatched) return fn;
              const orig = fn;
              const wrapped = function (key) {
                if (key === 'post_status_in_companion' || key === 'text_status_creation_support') return true;
                return orig.apply(this, arguments);
              };
              wrapped.__raselStatusPatched = true;
              return wrapped;
            }
            try {
              if (WPP.whatsapp.getABPropConfigValue) {
                WPP.whatsapp.getABPropConfigValue = wrapAB(WPP.whatsapp.getABPropConfigValue);
              }
              if (WPP.whatsapp.primaryFeatureEnabled) {
                WPP.whatsapp.primaryFeatureEnabled = wrapFeature(WPP.whatsapp.primaryFeatureEnabled);
              }
            } catch (e) {}
            try {
              WPP.webpack.search(function (mod) {
                if (!mod) return false;
                if (typeof mod.getABPropConfigValue === 'function') {
                  mod.getABPropConfigValue = wrapAB(mod.getABPropConfigValue);
                }
                if (typeof mod.primaryFeatureEnabled === 'function') {
                  mod.primaryFeatureEnabled = wrapFeature(mod.primaryFeatureEnabled);
                }
                return false;
              });
            } catch (e) {}
          }
          async function confirmStatusSend(res, text) {
            if (!res) return { ok: false };
            const id = (res.id && (res.id._serialized || res.id.id)) ||
              (res.message && res.message.id && (res.message.id._serialized || res.message.id.id)) || '';
            let ack = res.ack;
            if (typeof ack !== 'number') ack = (res.message && res.message.ack);
            if (typeof ack !== 'number') ack = -1;
            for (let i = 0; i < 8 && ack < 1; i++) {
              await new Promise(function (resolve) { setTimeout(resolve, 400); });
              try {
                if (id) {
                  const msg = await WPP.chat.getMessageById(id);
                  if (msg && typeof msg.ack === 'number') ack = msg.ack;
                }
              } catch (e) {}
              try {
                const mine = await WPP.status.getMyStatus();
                const list = (mine && mine.msgs && mine.msgs.getModelsArray && mine.msgs.getModelsArray()) || [];
                for (const item of (Array.isArray(list) ? list : [])) {
                  const mid = item.id && item.id._serialized || '';
                  if (id && mid && mid.indexOf(id) !== -1 && typeof item.ack === 'number') {
                    ack = Math.max(ack, item.ack);
                  }
                  if (text && item.body === text && typeof item.ack === 'number') {
                    ack = Math.max(ack, item.ack);
                  }
                }
              } catch (e) {}
            }
            return { ok: ack >= 1, id: String(id || ''), ack: ack };
          }
  ''';

  static const _jsSlimFn = r'''
          function sid(v) {
            if (!v) return '';
            if (typeof v === 'string') return v;
            return v._serialized || '';
          }
          function slimText(value, max) {
            if (value == null) return '';
            const text = String(value);
            if (text.indexOf('data:') === 0) return '';
            return text.length > max ? text.slice(0, max) : text;
          }
          function slimLast(msg) {
            if (!msg) return null;
            return {
              body: slimText(msg.caption || msg.body, 180),
              caption: slimText(msg.caption, 120),
              type: msg.type || 'chat',
              t: msg.t
            };
          }
          function slimContact(c) {
            if (!c) return null;
            return {
              name: c.name || '',
              verifiedName: c.verifiedName || '',
              verifiedBizName: c.verifiedBizName || '',
              pushname: c.pushname || '',
              formattedName: c.formattedName || '',
              shortName: c.shortName || ''
            };
          }
          function slimMsg(msg) {
            if (!msg) return null;
            const type = msg.type || 'chat';
            const media = !!(msg.isMedia || msg.deprecatedMms3Url ||
              type === 'image' || type === 'video' || type === 'audio' ||
              type === 'ptt' || type === 'document' || type === 'sticker');
            return {
              id: {
                _serialized: sid(msg.id),
                fromMe: !!(msg.id && msg.id.fromMe),
                remote: sid(msg.id && msg.id.remote) || sid(msg.from) || sid(msg.to),
                id: (msg.id && msg.id.id) || ''
              },
              from: sid(msg.from),
              to: sid(msg.to),
              body: slimText(msg.body, 65536),
              caption: slimText(msg.caption, 8000),
              type: type,
              t: msg.t,
              notifyName: msg.notifyName || msg.notify || '',
              ack: msg.ack,
              mimetype: msg.mimetype || '',
              filename: msg.filename || msg.fileName || '',
              hasMedia: media
            };
          }
          function slimMsgList(list) {
            if (!Array.isArray(list)) return [];
            const out = [];
            for (const item of list) {
              const packed = slimMsg(item);
              if (packed) out.push(packed);
            }
            return out;
          }
  ''';

  static const _jsInspectChatFn = r'''
          async function inspectChat(rawId, chatObj) {
            const id = (rawId && rawId._serialized) ? rawId._serialized : String(rawId || '');
            if (!id || id === 'status@broadcast' || id.indexOf('@broadcast') !== -1 || id === '0@c.us') {
              return { id: id, hidden: true };
            }
            const chat = chatObj || await (async () => {
              try { return await WPP.chat.get(id); } catch (e) { return null; }
            })();
            if (chat && (chat.isHidden || chat.notSpam === false || chat.isPSA)) {
              return { id: id, hidden: true };
            }
            let canonical = id;
            let phone = null;
            const user = String(id).split('@')[0] || '';
            const isLid = id.indexOf('@lid') !== -1 || /^\d{15,}$/.test(user);
            if (isLid && WPP.contact && WPP.contact.getPN) {
              try {
                const lid = id.indexOf('@') === -1 ? (id + '@lid') : id;
                const pn = await WPP.contact.getPN(lid);
                let pnId = '';
                if (pn && pn._serialized) pnId = pn._serialized;
                else if (pn && pn.user) pnId = pn.user + '@c.us';
                else if (typeof pn === 'string' && pn) {
                  pnId = pn.indexOf('@') === -1 ? (pn + '@c.us') : pn;
                }
                if (pnId) {
                  phone = pnId;
                  canonical = pnId;
                }
              } catch (e) {}
              if (!phone && canonical.indexOf('@lid') !== -1) {
                canonical = id;
              }
            }
            let name = '';
            try {
              const c = await WPP.contact.get(canonical);
              name = c?.name || c?.verifiedName || c?.verifiedBizName || c?.pushname || '';
            } catch (e) {}
            return { id: canonical, phone: phone, name: name, hidden: false };
          }
  ''';

  String _sendId(String id) {
    final value = id.trim();
    if (value.contains('@')) return value;
    if (RegExp(r'^\d{15,}$').hasMatch(value)) return '$value@lid';
    return '$value@c.us';
  }

  String _mimeType(String type, String? fileName) {
    switch (type) {
      case 'video':
        return 'video/mp4';
      case 'audio':
      case 'ptt':
        final name = (fileName ?? '').toLowerCase();
        if (name.endsWith('.m4a') ||
            name.endsWith('.aac') ||
            name.endsWith('.mp4')) {
          return 'audio/mp4';
        }
        if (name.endsWith('.mp3')) return 'audio/mpeg';
        if (name.endsWith('.ogg') ||
            name.endsWith('.opus') ||
            type == 'ptt') {
          return 'audio/ogg; codecs=opus';
        }
        return 'audio/mp4';
      case 'document':
        if (fileName != null && fileName.toLowerCase().endsWith('.pdf')) {
          return 'application/pdf';
        }
        return 'application/octet-stream';
      default:
        return 'image/jpeg';
    }
  }

  bool _isWppMissing(Object error) {
    final text = error.toString();
    return text.contains('WPP is not defined') ||
        text.contains('ReferenceError');
  }

  String _mapEvent(ConnectionEvent event) {
    switch (event) {
      case ConnectionEvent.waitingForQrScan:
      case ConnectionEvent.requireAuth:
      case ConnectionEvent.waitingForLogin:
      case ConnectionEvent.waitingForPhoneLink:
        return AppConnectionStatus.authRequired;
      case ConnectionEvent.authenticated:
      case ConnectionEvent.connected:
      case ConnectionEvent.connectingWhatsapp:
        return AppConnectionStatus.syncing;
      case ConnectionEvent.logout:
      case ConnectionEvent.disconnected:
        return AppConnectionStatus.offline;
      default:
        return AppConnectionStatus.syncing;
    }
  }
}
