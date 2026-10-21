import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_scope.dart';
import '../../data/models/models.dart';
import '../theme.dart';
import '../widgets/initials_avatar.dart';
import 'status_viewer.dart';

class StatusTab extends StatefulWidget {
  const StatusTab({
    super.key,
    required this.query,
    this.active = false,
  });

  final String query;
  final bool active;

  @override
  State<StatusTab> createState() => StatusTabState();
}

class StatusTabState extends State<StatusTab> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(StatusTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      AppScope.of(context).controller.refreshStatuses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    return ValueListenableBuilder<bool>(
      valueListenable: controller.statusesLoading,
      builder: (context, loading, _) {
        return ValueListenableBuilder<StatusFeed>(
          valueListenable: controller.statusFeed,
          builder: (context, feed, _) {
            final query = widget.query.trim();
            final recent = feed.recent.where((thread) {
              return query.isEmpty || thread.authorName.contains(query);
            }).toList();
            final viewed = feed.viewed.where((thread) {
              return query.isEmpty || thread.authorName.contains(query);
            }).toList();

            return RefreshIndicator(
              onRefresh: controller.refreshStatuses,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _MyStatusTile(
                    thread: feed.mine,
                    loading: loading,
                    onAdd: () => addStatus(context),
                    onOpen: () {
                      final mine = feed.mine;
                      if (mine == null || !mine.hasItems) {
                        addStatus(context);
                        return;
                      }
                      _open(context, mine, markRead: false);
                    },
                  ),
                  if (loading && !feed.others.any((t) => t.hasItems))
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (recent.isNotEmpty) ...[
                    const _SectionLabel('حديثة'),
                    ...recent.map(
                      (thread) => _StatusTile(
                        thread: thread,
                        seen: false,
                        onTap: () => _open(context, thread),
                      ),
                    ),
                  ],
                  if (viewed.isNotEmpty) ...[
                    const _SectionLabel('مشاهدة'),
                    ...viewed.map(
                      (thread) => _StatusTile(
                        thread: thread,
                        seen: true,
                        onTap: () => _open(context, thread),
                      ),
                    ),
                  ],
                  if (query.isNotEmpty && recent.isEmpty && viewed.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'لا توجد نتائج في الحالات',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (query.isEmpty &&
                      recent.isEmpty &&
                      viewed.isEmpty &&
                      !loading)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        controller.status.value == AppConnectionStatus.online
                            ? 'لا توجد حالات من جهات الاتصال بعد.'
                            : 'اربط الحساب ثم اسحب للتحديث لعرض الحالات.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  const SizedBox(height: 88),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> addStatus(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('حالة نصية'),
              onTap: () => Navigator.pop(context, 'text'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('صورة من المعرض'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('التقاط صورة'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('فيديو من المعرض'),
              onTap: () => Navigator.pop(context, 'video'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice == 'text') {
      await _composeText(context);
      return;
    }
    if (choice == 'video') {
      final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (file == null || !context.mounted) return;
      final bytes = await file.readAsBytes();
      if (!context.mounted) return;
      await _runSend(context, () {
        return AppScope.of(context).controller.sendVideoStatus(bytes);
      });
      return;
    }
    final file = await ImagePicker().pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null || !context.mounted) return;
    await _sendImage(context, await file.readAsBytes());
  }

  Future<void> _composeText(BuildContext context) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => const _TextStatusDialog(),
    );
    if (result == null || !context.mounted) return;
    await _runSend(context, () {
      return AppScope.of(context).controller.sendTextStatus(
        result.$1,
        backgroundColor: result.$2,
      );
    });
  }

  Future<void> _sendImage(BuildContext context, List<int> bytes) {
    return _runSend(context, () {
      return AppScope.of(context).controller.sendImageStatus(bytes);
    });
  }

  Future<void> _runSend(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نشر الحالة')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر نشر الحالة. تأكد من الاتصال.')),
      );
    }
  }

  Future<void> _open(
    BuildContext context,
    WaStatusThread thread, {
    bool markRead = true,
  }) async {
    if (!thread.hasItems) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StatusViewer(thread: thread),
      ),
    );
    if (!markRead || !context.mounted) return;
    await AppScope.of(context).controller.markStatusRead(thread);
  }
}

class _MyStatusTile extends StatelessWidget {
  const _MyStatusTile({
    required this.thread,
    required this.loading,
    required this.onAdd,
    required this.onOpen,
  });

  final WaStatusThread? thread;
  final bool loading;
  final VoidCallback onAdd;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final hasItems = thread?.hasItems == true;
    final last = hasItems ? thread!.items.last : null;
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      leading: Stack(
        children: [
          _StatusAvatar(
            name: 'قصتي',
            seen: !hasItems,
            segments: thread?.items.length ?? 0,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              radius: 10,
              backgroundColor: AppColors.teal,
              child: const Icon(Icons.add, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
      title: const Text(
        'قصتي',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        last == null
            ? 'أضف قصة جديدة'
            : (thread?.viewCount ?? last.shownViewCount) > 0
            ? 'شوهدت بواسطة ${thread?.viewCount ?? last.shownViewCount} · ${formatChatTime(last.timestamp)}'
            : formatChatTime(last.timestamp),
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              tooltip: 'إضافة حالة',
              onPressed: onAdd,
              icon: const Icon(Icons.camera_alt_outlined),
            ),
      onTap: onOpen,
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.thread,
    required this.seen,
    required this.onTap,
  });

  final WaStatusThread thread;
  final bool seen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final last = thread.items.isEmpty ? null : thread.items.last;
    return ListTile(
      leading: _StatusAvatar(
        name: thread.authorName,
        seen: seen,
        segments: thread.items.length,
      ),
      title: Text(
        SafeText.display(thread.authorName, fallback: 'جهة اتصال'),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        last == null
            ? '${thread.unreadCount} حالة'
            : formatChatTime(last.timestamp),
        style: TextStyle(color: Colors.grey.shade600),
      ),
      onTap: onTap,
    );
  }
}

class _StatusAvatar extends StatelessWidget {
  const _StatusAvatar({
    required this.name,
    required this.seen,
    required this.segments,
  });

  final String name;
  final bool seen;
  final int segments;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: seen ? Colors.grey.shade400 : AppColors.lightGreen,
          width: segments > 1 ? 2.8 : 2.4,
        ),
      ),
      child: InitialsAvatar(name: name, size: 46),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.accentSoft.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TextStatusDialog extends StatefulWidget {
  const _TextStatusDialog();

  @override
  State<_TextStatusDialog> createState() => _TextStatusDialogState();
}

class _TextStatusDialogState extends State<_TextStatusDialog> {
  final _text = TextEditingController();
  String _color = '#075E54';

  static const _colors = [
    '#075E54',
    '#128C7E',
    '#25D366',
    '#34B7F1',
    '#FF9800',
    '#E91E63',
    '#9C27B0',
    '#455A64',
  ];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 220,
              width: double.infinity,
              color: hexColor(_color),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _text,
                maxLines: 5,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  filled: false,
                  hintText: 'اكتب حالتك',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final color in _colors)
                    GestureDetector(
                      onTap: () => setState(() => _color = color),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: hexColor(color),
                        child: _color == color
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
            ButtonBar(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () {
                    final text = _text.text.trim();
                    if (text.isEmpty) return;
                    Navigator.pop(context, (text, _color));
                  },
                  child: const Text('نشر'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
