import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../app_scope.dart';
import '../../data/db/app_database.dart';
import '../../data/models/models.dart';
import '../../platform/local_fs.dart';
import '../../platform/native_audio.dart';
import '../../services/sync_controller.dart';
import '../profile/contact_profile_screen.dart';
import '../profile/photo_viewer.dart';
import '../theme.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/receipt_ticks.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chat});

  final LocalChat chat;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _recorder = AudioRecorder();
  SyncController? _controller;
  bool _loadingOlder = false;
  bool _hasMore = true;
  bool _recording = false;
  String? _recordingPath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = AppScope.of(context).controller;
    _controller!.viewingChatId = widget.chat.id;
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller?.markChatSeen(widget.chat);
      _controller?.refreshOpenChat(widget.chat.id);
      unawaited(_controller?.downloadMissingAudioInChat(widget.chat.id));
    });
  }

  @override
  void dispose() {
    _controller?.viewingChatId = null;
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _input.dispose();
    unawaited(_recorder.dispose());
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients || _loadingOlder || !_hasMore) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 140) {
      _loadOlder();
    }
  }

  Future<void> _loadOlder() async {
    if (_loadingOlder || !_hasMore || !mounted) return;
    setState(() => _loadingOlder = true);
    try {
      final more = await AppScope.of(context).controller.loadOlderMessages(
        widget.chat.id,
      );
      if (!mounted) return;
      setState(() {
        _loadingOlder = false;
        if (!more) _hasMore = false;
      });
      if (more) _maybeLoadIfShort();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingOlder = false);
    }
  }

  void _maybeLoadIfShort() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients || _loadingOlder || !_hasMore) {
        return;
      }
      if (_scroll.position.maxScrollExtent <= 140) {
        _loadOlder();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return StreamBuilder<LocalChat?>(
      stream: scope.db.watchChat(widget.chat.id),
      builder: (context, snapshot) {
        final chat = snapshot.data ?? widget.chat;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ContactProfileScreen(chat: chat),
                  ),
                );
              },
              child: Row(
                children: [
                  InitialsAvatar(
                    name: chat.name,
                    path: chat.profilePicPath,
                    isGroup: chat.isGroup,
                    isChannel: ChatKinds.isChannelId(chat.waChatId),
                    size: 36,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      SafeText.display(chat.name, fallback: 'محادثة'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: AppColors.chatBg),
                  child: StreamBuilder<List<LocalMessage>>(
                    stream: scope.db.watchMessages(chat.id),
                    builder: (context, snapshot) {
                      final messages = snapshot.data ?? const <LocalMessage>[];
                      if (messages.isEmpty && !_loadingOlder && !_hasMore) {
                        return const Center(
                          child: Text('لا توجد رسائل محفوظة في هذه المحادثة'),
                        );
                      }
                      return ListView.builder(
                        controller: _scroll,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        itemCount: messages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return _HistoryHeader(
                              loading: _loadingOlder,
                              hasMore: _hasMore,
                              empty: messages.isEmpty,
                              onLoad: _loadOlder,
                            );
                          }
                          final message = messages[messages.length - 1 - index];
                          return _MessageBubble(
                            message: message,
                            showSender: chat.isGroup && !message.fromMe,
                            isGroup: chat.isGroup,
                            onDownload: () =>
                                scope.controller.downloadMessageMedia(message),
                            onRetry: message.deliveryStatus == 'failed'
                                ? () => scope.controller
                                    .retryOutgoing(message.waMessageId)
                                : null,
                            onLongPress: () => _showMessageActions(chat, message),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              if (ChatKinds.isChannelId(chat.waChatId))
                const SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Text(
                      'هذه قناة للعرض فقط. الإرسال من تبويب الدردشات.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                _Composer(
                  controller: _input,
                  recording: _recording,
                  onSend: () => _sendText(chat),
                  onAttach: _showAttachSheet,
                  onVoice: () => _toggleVoice(chat),
                ),
            ],
          ),
        );
      },
    );
  }

  String? _copyableText(LocalMessage message) {
    if (MediaText.isReadable(message.body) &&
        message.body != WaMessage.mediaLabel(message.type)) {
      return message.body;
    }
    return null;
  }

  Future<void> _showMessageActions(
    LocalChat chat,
    LocalMessage message,
  ) async {
    final text = _copyableText(message);
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.copy_outlined),
                  title: const Text('نسخ'),
                  enabled: text != null,
                  onTap: text == null
                      ? null
                      : () => Navigator.pop(context, 'copy'),
                ),
                ListTile(
                  leading: const Icon(Icons.forward_outlined),
                  title: const Text('تحويل'),
                  onTap: () => Navigator.pop(context, 'forward'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || action == null) return;
    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: text!));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ الرسالة')),
      );
      return;
    }
    if (action == 'forward') {
      await _forwardMessage(chat, message);
    }
  }

  Future<void> _forwardMessage(
    LocalChat from,
    LocalMessage message,
  ) async {
    final target = await showModalBottomSheet<LocalChat>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            builder: (context, scroll) {
              return StreamBuilder<List<LocalChat>>(
                stream: AppScope.of(context).db.watchChats(),
                builder: (context, snapshot) {
                  final chats = (snapshot.data ?? const <LocalChat>[])
                      .where(
                        (chat) =>
                            chat.id != from.id &&
                            !ChatKinds.isChannelId(chat.waChatId) &&
                            !ChatKinds.isSystemId(chat.waChatId),
                      )
                      .toList();
                  if (chats.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('لا توجد محادثات للتحويل إليها'),
                    );
                  }
                  return Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'تحويل إلى',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scroll,
                          itemCount: chats.length,
                          itemBuilder: (context, index) {
                            final chat = chats[index];
                            return ListTile(
                              leading: InitialsAvatar(
                                name: chat.name,
                                path: chat.profilePicPath,
                                isGroup: chat.isGroup,
                                size: 36,
                              ),
                              title: Text(
                                SafeText.display(
                                  chat.name,
                                  fallback: chat.isGroup ? 'مجموعة' : 'محادثة',
                                ),
                              ),
                              onTap: () => Navigator.pop(context, chat),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
    if (!mounted || target == null) return;
    try {
      await AppScope.of(context).controller.forwardToChat(
        message: message,
        target: target,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم التحويل إلى ${SafeText.display(target.name, fallback: 'محادثة')}',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحويل الرسالة')),
      );
    }
  }

  Future<void> _sendText(LocalChat chat) async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    try {
      await AppScope.of(context).controller.sendText(
        chatId: chat.id,
        waChatId: chat.waChatId,
        body: text,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر إرسال الرسالة، أعد المحاولة بعد الاتصال')),
      );
    }
  }

  Future<void> _showAttachSheet() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_outlined),
                title: const Text('صورة من المعرض'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('صورة من الكاميرا'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('فيديو'),
                onTap: () => Navigator.pop(context, 'video'),
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: const Text('ملف'),
                onTap: () => Navigator.pop(context, 'document'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'gallery':
        await _sendPickedImage(ImageSource.gallery);
      case 'camera':
        await _sendPickedImage(ImageSource.camera);
      case 'video':
        await _sendPickedVideo();
      case 'document':
        await _sendPickedFile();
    }
  }

  Future<void> _sendPickedImage(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 96,
      maxWidth: 2560,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await _sendBytes(bytes, type: 'image', fileName: file.name);
  }

  Future<void> _sendPickedVideo() async {
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await _sendBytes(bytes, type: 'video', fileName: file.name);
  }

  Future<void> _sendPickedFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    final file = result?.files.single;
    final bytes = file?.bytes ??
        (file?.path == null ? null : await readLocalFile(file!.path!));
    if (file == null || bytes == null || !mounted) return;
    await _sendBytes(
      bytes,
      type: 'document',
      fileName: file.name,
      caption: file.name,
    );
  }

  Future<void> _sendBytes(
    List<int> bytes, {
    required String type,
    String? fileName,
    String? caption,
  }) async {
    final chat = await AppScope.of(context).db.chatById(widget.chat.id) ??
        widget.chat;
    if (!mounted) return;
    try {
      await AppScope.of(context).controller.sendFile(
        chatId: chat.id,
        waChatId: chat.waChatId,
        bytes: bytes,
        type: type,
        fileName: fileName,
        caption: caption,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر إرسال الملف، أعد المحاولة بعد الاتصال')),
      );
    }
  }

  Future<void> _toggleVoice(LocalChat chat) async {
    if (_recording) {
      final path = await _recorder.stop() ?? _recordingPath;
      setState(() => _recording = false);
      if (path == null || !mounted) return;
      final bytes = await readLocalFile(path);
      if (!mounted || bytes.isEmpty) return;
      await _sendBytes(
        bytes,
        type: 'ptt',
        fileName: p.basename(path),
      );
      return;
    }

    final granted = await Permission.microphone.request();
    if (!granted.isGranted || !mounted) return;
    final dir = await getTemporaryDirectory();
    String path;
    try {
      path = p.join(
        dir.path,
        'voice_${DateTime.now().millisecondsSinceEpoch}.ogg',
      );
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.opus,
          numChannels: 1,
          sampleRate: 16000,
          bitRate: 24000,
        ),
        path: path,
      );
    } catch (_) {
      path = p.join(
        dir.path,
        'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          numChannels: 1,
          sampleRate: 16000,
          bitRate: 32000,
        ),
        path: path,
      );
    }
    if (!mounted) return;
    setState(() {
      _recording = true;
      _recordingPath = path;
    });
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.recording,
    required this.onSend,
    required this.onAttach,
    required this.onVoice,
  });

  final TextEditingController controller;
  final bool recording;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final hasText = value.text.trim().isNotEmpty;
            return Row(
              children: [
                IconButton(
                  onPressed: onAttach,
                  icon: const Icon(Icons.attach_file, color: AppColors.green),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !recording,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: recording ? 'جارٍ التسجيل...' : 'اكتب رسالة...',
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: recording ? Colors.red : AppColors.ink,
                  borderRadius: BorderRadius.circular(12),
                  child: IconButton(
                    onPressed: hasText && !recording ? onSend : onVoice,
                    icon: Icon(
                      recording
                          ? Icons.stop
                          : hasText
                          ? Icons.send
                          : Icons.mic,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({
    required this.loading,
    required this.hasMore,
    required this.empty,
    required this.onLoad,
  });

  final bool loading;
  final bool hasMore;
  final bool empty;
  final VoidCallback onLoad;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          empty ? 'لا توجد رسائل محفوظة في هذه المحادثة' : 'هذه أقدم الرسائل',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: TextButton.icon(
          onPressed: onLoad,
          icon: const Icon(Icons.history, size: 18),
          label: const Text('تحميل 50 رسالة أقدم'),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.showSender,
    required this.isGroup,
    required this.onDownload,
    this.onRetry,
    this.onLongPress,
  });

  final LocalMessage message;
  final bool showSender;
  final bool isGroup;
  final VoidCallback onDownload;
  final VoidCallback? onRetry;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromMe;
    final showBody = MediaText.isReadable(message.body) &&
        message.body != WaMessage.mediaLabel(message.type);
    final imagePath = message.mediaLocalPath;
    final imageExists = localFileExists(imagePath);
    final embedded = MediaText.decode(message.body);
    final canOpenImage = (message.type == 'image' ||
            message.type == 'sticker' ||
            embedded != null) &&
        (imageExists || embedded != null);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canOpenImage
          ? () => _openChatImage(
                context,
                message,
                path: imageExists ? imagePath : null,
                bytes: imageExists ? null : embedded,
              )
          : null,
      onLongPress: onLongPress,
      child: Align(
        alignment: mine ? Alignment.centerLeft : Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: canOpenImage
                ? MediaQuery.of(context).size.width * 0.68
                : 0,
            maxWidth: MediaQuery.of(context).size.width * 0.86,
          ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: EdgeInsets.symmetric(
            horizontal: canOpenImage ? 4 : 10,
            vertical: canOpenImage ? 4 : 8,
          ),
          decoration: BoxDecoration(
            color: mine ? AppColors.outgoing : AppColors.incoming,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 4 : 18),
              bottomRight: Radius.circular(mine ? 18 : 4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showSender && (message.senderName?.isNotEmpty ?? false))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    SafeText.display(message.senderName),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (message.hasMedia ||
                  ChatKinds.isMediaType(message.type) ||
                  MediaText.looksLikeBinary(message.body))
                _MediaBlock(
                  message: message,
                  onDownload: onDownload,
                  onOpenImage: (path, bytes) =>
                      _openChatImage(context, message, path: path, bytes: bytes),
                ),
              if (showBody)
                Text(
                  SafeText.display(message.body),
                  style: TextStyle(
                    fontSize: 15,
                    color: mine ? Colors.white : const Color(0xFF1C2433),
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatChatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: mine
                          ? const Color(0xFFD5DCE8)
                          : Colors.grey.shade600,
                    ),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onRetry,
                      child: ReceiptTicks(
                        status: message.deliveryStatus,
                        isGroup: isGroup,
                        size: 15,
                        onDark: true,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

void _openChatImage(
  BuildContext context,
  LocalMessage message, {
  String? path,
  Uint8List? bytes,
}) {
  final scope = AppScope.of(context);
  final controller = scope.controller;
  final db = scope.db;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PhotoViewer(
        path: path,
        bytes: bytes,
        title: WaMessage.mediaLabel(message.type),
        refreshHd: () async {
          await controller.downloadMessageMedia(message);
          final latest = await db.messageByWaId(message.waMessageId);
          return latest?.mediaLocalPath;
        },
      ),
    ),
  );
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    this.path,
    this.bytes,
    required this.title,
    required this.onOpen,
  });

  final String? path;
  final Uint8List? bytes;
  final String title;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.78;
    final image = localFileExists(path)
        ? localImageFile(
            path!,
            width: width,
            height: 340,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          )
        : Image.memory(
            bytes!,
            width: width,
            height: 340,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: const Color(0x11000000),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: width,
              height: 340,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  image,
                  const Positioned(
                    left: 8,
                    bottom: 8,
                    child: Icon(
                      Icons.zoom_out_map,
                      color: Colors.white,
                      size: 24,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaBlock extends StatelessWidget {
  const _MediaBlock({
    required this.message,
    required this.onDownload,
    required this.onOpenImage,
  });

  final LocalMessage message;
  final VoidCallback onDownload;
  final void Function(String? path, Uint8List? bytes) onOpenImage;

  @override
  Widget build(BuildContext context) {
    final path = message.mediaLocalPath;
    final exists = localFileExists(path);

    final embedded = MediaText.decode(message.body);
    final pathLooksImage = (path ?? '').toLowerCase().contains(
          RegExp(r'\.(jpe?g|png|webp|gif)$'),
        );
    final canShowImage = message.type == 'image' ||
        message.type == 'sticker' ||
        pathLooksImage ||
        embedded != null;

    if (exists && canShowImage) {
      return _ImagePreview(
        path: path,
        title: WaMessage.mediaLabel(message.type),
        onOpen: () => onOpenImage(path, null),
      );
    }

    if (embedded != null && canShowImage) {
      return _ImagePreview(
        bytes: embedded,
        title: WaMessage.mediaLabel(message.type),
        onOpen: () => onOpenImage(null, embedded),
      );
    }

    if (message.type == 'audio' || message.type == 'ptt') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: _AudioPlayerTile(
          message: message,
          onDownload: onDownload,
        ),
      );
    }

    final label = WaMessage.mediaLabel(message.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () async {
          if (exists && path != null) {
            await OpenFilex.open(path);
            return;
          }
          onDownload();
        },
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(_iconFor(message.type), color: AppColors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(exists ? label : 'تحميل $label'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'video':
        return Icons.videocam_outlined;
      case 'document':
        return Icons.insert_drive_file_outlined;
      case 'audio':
      case 'ptt':
        return Icons.mic_none;
      default:
        return Icons.image_outlined;
    }
  }
}

class _AudioPlayerTile extends StatefulWidget {
  const _AudioPlayerTile({
    required this.message,
    required this.onDownload,
  });

  final LocalMessage message;
  final VoidCallback onDownload;

  @override
  State<_AudioPlayerTile> createState() => _AudioPlayerTileState();
}

class _AudioPlayerTileState extends State<_AudioPlayerTile> {
  final _player = AudioPlayer();
  bool _playing = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    NativeAudio.bind();
    unawaited(_player.setPlayerMode(PlayerMode.mediaPlayer));
    unawaited(_player.setVolume(1));
    unawaited(
      _player.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      ),
    );
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    if (NativeAudio.onComplete == _onNativeComplete) {
      NativeAudio.onComplete = null;
      unawaited(NativeAudio.stop());
    }
    unawaited(_player.dispose());
    super.dispose();
  }

  void _onNativeComplete() {
    if (mounted) setState(() => _playing = false);
  }

  Future<String?> _ensureFile() async {
    var path = widget.message.mediaLocalPath;
    if (localFileExists(path) && localFileLength(path!) > 400) return path;
    widget.onDownload();
    await AppScope.of(context).controller.downloadMessageMedia(widget.message);
    if (!mounted) return null;
    final latest = await AppScope.of(
      context,
    ).db.messageByWaId(widget.message.waMessageId);
    path = latest?.mediaLocalPath ?? path;
    if (localFileExists(path) && localFileLength(path!) > 400) return path;
    return localFileExists(path) ? path : null;
  }

  Future<void> _toggle() async {
    if (_busy) return;
    if (_playing) {
      NativeAudio.onComplete = null;
      await NativeAudio.stop();
      await _player.stop();
      setState(() => _playing = false);
      return;
    }
    setState(() => _busy = true);
    try {
      final path = await _ensureFile();
      if (!mounted) return;
      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحميل الرسالة الصوتية')),
        );
        return;
      }
      NativeAudio.onComplete = _onNativeComplete;
      final native = await NativeAudio.play(path);
      if (native) {
        if (mounted) setState(() => _playing = true);
        return;
      }
      try {
        await _player.stop();
        await _player.setVolume(1);
        final bytes = await readLocalFile(path);
        final lower = path.toLowerCase();
        final mime = lower.endsWith('.ogg') || lower.endsWith('.opus')
            ? 'audio/ogg'
            : lower.endsWith('.mp3')
            ? 'audio/mpeg'
            : 'audio/mp4';
        await _player.play(BytesSource(bytes, mimeType: mime));
        if (mounted) setState(() => _playing = true);
      } catch (_) {
        final opened = await OpenFilex.open(path);
        if (!mounted) return;
        if (opened.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر تشغيل الملف الصوتي')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = localFileExists(widget.message.mediaLocalPath);
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _busy ? null : _toggle,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_playing ? Icons.stop : Icons.play_arrow),
            color: AppColors.green,
          ),
          Expanded(
            child: Text(ready ? 'رسالة صوتية' : 'تحميل وتشغيل'),
          ),
        ],
      ),
    );
  }
}
