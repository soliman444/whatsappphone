import 'dart:typed_data';

import 'package:flutter/widgets.dart';

final Map<String, Uint8List> _memoryFiles = {};

bool localFileExists(String? path) {
  return path != null && path.isNotEmpty && _memoryFiles.containsKey(path);
}

int localFileLength(String path) => _memoryFiles[path]?.length ?? 0;

Future<void> writeLocalFile(
  String path,
  List<int> bytes, {
  bool flush = true,
}) async {
  _memoryFiles[path] = Uint8List.fromList(bytes);
}

Future<Uint8List> readLocalFile(String path) async {
  return _memoryFiles[path] ?? Uint8List(0);
}

void deleteLocalFile(String path) {
  _memoryFiles.remove(path);
}

Widget localImageFile(
  String path, {
  Key? key,
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  FilterQuality filterQuality = FilterQuality.low,
  bool gaplessPlayback = false,
}) {
  final bytes = _memoryFiles[path];
  if (bytes == null) return SizedBox(width: width, height: height);
  return Image.memory(
    bytes,
    key: key ?? ValueKey('$path-${bytes.length}'),
    fit: fit,
    width: width,
    height: height,
    filterQuality: filterQuality,
    gaplessPlayback: gaplessPlayback,
  );
}

Future<void> evictLocalFileImage(String path) async {}
