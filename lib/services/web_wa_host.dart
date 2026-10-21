import 'dart:async';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebWaHost {
  static InAppWebViewController? controller;
  static Completer<InAppWebViewController>? _ready;

  static Future<InAppWebViewController> waitForController() {
    final existing = controller;
    if (existing != null) return Future.value(existing);
    final pending = _ready ??= Completer<InAppWebViewController>();
    return pending.future.timeout(
      const Duration(seconds: 25),
      onTimeout: () => throw StateError('تعذر تجهيز صفحة الربط'),
    );
  }

  static void attach(InAppWebViewController next) {
    controller = next;
    final pending = _ready;
    if (pending != null && !pending.isCompleted) {
      pending.complete(next);
    }
  }
}
