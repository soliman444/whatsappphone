import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

bool localFileExists(String? path) {
  return path != null && path.isNotEmpty && File(path).existsSync();
}

int localFileLength(String path) => File(path).lengthSync();

Future<void> writeLocalFile(
  String path,
  List<int> bytes, {
  bool flush = true,
}) {
  return File(path).writeAsBytes(bytes, flush: flush);
}

Future<Uint8List> readLocalFile(String path) => File(path).readAsBytes();

void deleteLocalFile(String path) {
  final file = File(path);
  if (file.existsSync()) file.deleteSync();
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
  final file = File(path);
  return Image.file(
    file,
    key: key ?? ValueKey('${file.path}-${file.lengthSync()}'),
    fit: fit,
    width: width,
    height: height,
    filterQuality: filterQuality,
    gaplessPlayback: gaplessPlayback,
  );
}

Future<void> evictLocalFileImage(String path) {
  return FileImage(File(path)).evict();
}
