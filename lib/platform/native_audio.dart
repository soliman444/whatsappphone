import 'package:flutter/services.dart';

class NativeAudio {
  static const _channel = MethodChannel('com.example.whatsapp/audio');
  static void Function()? onComplete;
  static bool _bound = false;

  static void bind() {
    if (_bound) return;
    _bound = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'complete') {
        onComplete?.call();
      }
    });
  }

  static Future<bool> play(String path) async {
    bind();
    try {
      final ok = await _channel.invokeMethod<bool>('play', {'path': path});
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {}
  }
}
