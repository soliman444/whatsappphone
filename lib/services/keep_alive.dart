import 'package:flutter/services.dart';

class KeepAlive {
  static const _channel = MethodChannel('com.example.whatsapp/keepalive');
  static void Function()? onTick;
  static bool _bound = false;

  static void bind() {
    if (_bound) return;
    _bound = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'tick') {
        onTick?.call();
      }
    });
  }

  static Future<void> start() async {
    bind();
    try {
      await _channel.invokeMethod('start');
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {}
  }
}
