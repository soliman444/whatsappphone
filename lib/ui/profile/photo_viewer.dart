import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../platform/local_fs.dart';

class PhotoViewer extends StatefulWidget {
  const PhotoViewer({
    super.key,
    this.path,
    this.bytes,
    required this.title,
    this.refreshHd,
  });

  final String? path;
  final Uint8List? bytes;
  final String title;
  final Future<String?> Function()? refreshHd;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  final _transform = TransformationController();
  String? _path;
  Uint8List? _bytes;
  bool _loadingHd = false;
  Offset _tap = Offset.zero;

  @override
  void initState() {
    super.initState();
    _path = widget.path;
    _bytes = widget.bytes;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _upgrade();
    });
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  Future<void> _upgrade() async {
    final refresh = widget.refreshHd;
    if (refresh == null) return;
    setState(() => _loadingHd = true);
    try {
      final next = await refresh();
      if (!mounted) return;
      if (next != null && next.isNotEmpty && localFileExists(next)) {
        await evictLocalFileImage(next);
        setState(() {
          _path = next;
          _bytes = null;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingHd = false);
    }
  }

  void _onDoubleTap() {
    if (_transform.value != Matrix4.identity()) {
      _transform.value = Matrix4.identity();
      return;
    }
    final zoom = 3.0;
    _transform.value = Matrix4.identity()
      ..translate(-_tap.dx * (zoom - 1), -_tap.dy * (zoom - 1))
      ..scale(zoom);
  }

  Widget _image(BoxConstraints constraints) {
    final hasFile = localFileExists(_path);
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    if (hasFile) {
      return localImageFile(
        _path!,
        width: width,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      );
    }
    return Image.memory(
      _bytes!,
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        localFileExists(_path) || _bytes != null;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        actions: [
          if (_loadingHd)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: hasImage
          ? LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onDoubleTapDown: (details) => _tap = details.localPosition,
                  onDoubleTap: _onDoubleTap,
                  child: InteractiveViewer(
                    transformationController: _transform,
                    minScale: 1,
                    maxScale: 8,
                    panEnabled: true,
                    scaleEnabled: true,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: _image(constraints),
                    ),
                  ),
                );
              },
            )
          : const Center(
              child: Text(
                'تعذر عرض الصورة',
                style: TextStyle(color: Colors.white70),
              ),
            ),
    );
  }
}
