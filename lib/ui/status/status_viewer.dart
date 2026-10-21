import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/models/models.dart';
import '../theme.dart';
import '../widgets/initials_avatar.dart';

class StatusViewer extends StatefulWidget {
  const StatusViewer({super.key, required this.thread});

  final WaStatusThread thread;

  @override
  State<StatusViewer> createState() => _StatusViewerState();
}

class _StatusViewerState extends State<StatusViewer> {
  late final PageController _pages;
  Timer? _timer;
  late int _index;
  double _progress = 0;
  List<WaStatusViewer> _viewers = const [];
  int _viewCount = 0;
  int? _hiddenCount;
  bool _loadingViewers = false;

  List<WaStatusItem> get _items => widget.thread.items;
  WaStatusItem get _item => _items[_index];

  @override
  void initState() {
    super.initState();
    final firstUnread = _items.indexWhere((item) => !item.viewed);
    _index = widget.thread.fromMe
        ? 0
        : (firstUnread >= 0 ? firstUnread : 0);
    _pages = PageController(initialPage: _index);
    _viewers = _item.viewers;
    _viewCount = _item.shownViewCount;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onItemShown();
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _progress = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        _progress += 0.05 / 5;
      });
      if (_progress >= 1) {
        _go(_index + 1);
      }
    });
  }

  Future<void> _onItemShown() async {
    final item = _item;
    if (!widget.thread.fromMe) {
      await AppScope.of(context).controller.markStatusItemRead(item);
      return;
    }
    setState(() {
      _loadingViewers = true;
      _viewers = item.viewers;
      _viewCount = item.shownViewCount;
    });
    var views = await AppScope.of(context).controller.getStatusViewers(item);
    if (!mounted || _item.id != item.id) return;
    if (views.viewers.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (!mounted || _item.id != item.id) return;
      views = await AppScope.of(context).controller.getStatusViewers(item);
      if (!mounted || _item.id != item.id) return;
    }
    setState(() {
      _viewers = views.viewers;
      _viewCount = views.viewers.length;
      _hiddenCount = views.hiddenCount;
      _loadingViewers = false;
    });
  }

  void _go(int index) {
    if (index < 0 || index >= _items.length) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _index = index;
      _progress = 0;
      _viewers = _items[index].viewers;
      _viewCount = _items[index].shownViewCount;
    });
    _pages.jumpToPage(index);
    _startTimer();
    unawaited(_onItemShown());
  }

  Future<void> _deleteCurrent() async {
    final item = _item;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحالة'),
        content: const Text('هل تريد حذف هذه الحالة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await AppScope.of(context).controller.removeStatus(item.id);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حذف الحالة')),
      );
    }
  }

  Future<void> _showViewers() async {
    _timer?.cancel();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _ViewersSheet(
          count: _viewers.length,
          viewers: _viewers,
          hiddenCount: _hiddenCount,
          loading: _loadingViewers,
        );
      },
    );
    if (mounted) _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final mine = widget.thread.fromMe;
    return Scaffold(
      backgroundColor: hexColor(item.backgroundColor, fallback: Colors.black),
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.sizeOf(context).width;
          if (details.localPosition.dx < width / 3) {
            _go(_index - 1);
          } else {
            _go(_index + 1);
          }
        },
        onLongPressStart: (_) => _timer?.cancel(),
        onLongPressEnd: (_) => _startTimer(),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pages,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return _StatusPage(item: _items[index]);
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < _items.length; i++) ...[
                          if (i > 0) const SizedBox(width: 4),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: i < _index
                                  ? 1
                                  : i == _index
                                  ? _progress.clamp(0, 1)
                                  : 0,
                              minHeight: 3,
                              backgroundColor: Colors.white24,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.only(right: 4),
                      leading: CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Text(
                          initialsFor(widget.thread.authorName),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        SafeText.display(
                          widget.thread.authorName,
                          fallback: 'حالة',
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        formatChatTime(item.timestamp),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (mine)
                            IconButton(
                              tooltip: 'حذف',
                              onPressed: _deleteCurrent,
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                              ),
                            ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (mine)
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextButton.icon(
                      onPressed: _showViewers,
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      icon: const Icon(Icons.visibility_outlined),
                      label: Text(
                        _loadingViewers
                            ? 'جاري تحميل المشاهدات...'
                            : _viewCount > 0
                            ? 'شوهدت بواسطة $_viewCount'
                            : 'لا مشاهدات بعد',
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ViewersSheet extends StatelessWidget {
  const _ViewersSheet({
    required this.count,
    required this.viewers,
    required this.loading,
    this.hiddenCount,
  });

  final int count;
  final List<WaStatusViewer> viewers;
  final bool loading;
  final int? hiddenCount;

  @override
  Widget build(BuildContext context) {
    final known = viewers.length;
    final hidden = hiddenCount != null && hiddenCount! > 0 ? hiddenCount! : null;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        height: 420,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CountLine(label: 'المعروفون', value: '$known'),
                  const SizedBox(height: 6),
                  _CountLine(
                    label: 'المخفيون',
                    value: hidden != null ? '$hidden' : 'غير معروف',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: loading && viewers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : viewers.isEmpty && hidden == null
                  ? const Center(child: Text('لا مشاهدين معروفين'))
                  : ListView.builder(
                    itemCount: viewers.length + (hidden != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= viewers.length) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade300,
                            child: Icon(
                              Icons.visibility_off_outlined,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          title: Text('$hidden مشاهد أخفوا ظهورهم'),
                          subtitle: const Text(
                            'واتساب لا يرسل أسماءهم لصاحب الحالة',
                            style: TextStyle(fontSize: 12),
                          ),
                        );
                      }
                      final viewer = viewers[index];
                      return ListTile(
                        leading: InitialsAvatar(name: viewer.name),
                        title: Text(
                          SafeText.display(
                            viewer.name,
                            fallback: 'جهة اتصال',
                          ),
                        ),
                        subtitle: viewer.hiddenReceipt
                            ? const Text(
                                'أخفى إيصال القراءة',
                                style: TextStyle(fontSize: 12),
                              )
                            : null,
                        trailing: Text(
                          formatChatTime(viewer.timestamp),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountLine extends StatelessWidget {
  const _CountLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _StatusPage extends StatelessWidget {
  const _StatusPage({required this.item});

  final WaStatusItem item;

  @override
  Widget build(BuildContext context) {
    final media = item.type != 'chat' && item.type != 'extendedText';
    final image =
        MediaText.decode(item.mediaBase64) ?? MediaText.decode(item.body);
    return ColoredBox(
      color: hexColor(item.backgroundColor, fallback: Colors.black),
      child: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 96),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (image != null)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(image, fit: BoxFit.contain),
                  ),
                )
              else if (media)
                Icon(
                  item.type == 'video'
                      ? Icons.videocam
                      : item.type == 'audio' || item.type == 'ptt'
                      ? Icons.mic
                      : Icons.image,
                  size: 64,
                  color: Colors.white70,
                ),
              if (MediaText.isReadable(item.body)) ...[
                const SizedBox(height: 16),
                Text(
                  SafeText.display(item.body),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ] else if (image == null)
                Text(
                  SafeText.display(
                    MediaText.preview(item.body, type: item.type),
                    fallback: media ? WaMessage.mediaLabel(item.type) : '',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
