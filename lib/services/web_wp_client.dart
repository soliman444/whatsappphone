import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:whatsapp_bot_platform_interface/whatsapp_bot_platform_interface.dart';

class WebWpClient implements WpClientInterface {
  WebWpClient(this.controller);

  final InAppWebViewController controller;

  @override
  Future injectJs(String content) async {
    await evaluateJs(content, tryPromise: false);
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  @override
  Future<void> dispose() async {}

  @override
  Future evaluateJs(
    String source, {
    String? methodName,
    bool tryPromise = true,
    bool forceJsonParseResult = false,
  }) async {
    if (!tryPromise) {
      return controller.evaluateJavascript(source: source);
    }
    final result = await controller.callAsyncJavaScript(
      functionBody: '''
        var result = new Promise(async function (resolve, reject) {
          try {
            var data = await $source;
            resolve(data);
          } catch (e) {
            reject(e);
          }
        });
        return await result;
      ''',
    );
    if (result?.error != null) {
      throw result!.error!;
    }
    return result?.value;
  }

  @override
  Future<QrCodeImage?> getQrCode() async {
    try {
      final result = await evaluateJs(
        '''
          (function getQr() {
            try {
              const selectorImg = document.querySelector('canvas');
              const selectorUrl = selectorImg && selectorImg.closest('[data-ref]');
              if (selectorImg != null && selectorUrl != null) {
                return {
                  base64Image: selectorImg.toDataURL(),
                  urlCode: selectorUrl.getAttribute('data-ref'),
                };
              }
            } catch (e) {}
            return null;
          })()
        ''',
        tryPromise: false,
      );
      if (result is! Map) return null;
      return QrCodeImage(
        base64Image: result['base64Image']?.toString(),
        urlCode: result['urlCode']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> on(WhatsappEvent event, Function(dynamic) callback) async {
    final callbackName = 'callback_${event.value.replaceAll('.', '_')}';
    await evaluateJs(
      "window.$callbackName = (data) => window.flutter_inappwebview.callHandler('$callbackName',data);",
      tryPromise: false,
    );
    controller.addJavaScriptHandler(
      handlerName: callbackName,
      callback: callback,
    );
    await controller.evaluateJavascript(
      source: "WPP.on('${event.value}', (data) => { window.$callbackName(data); });",
    );
  }

  @override
  Future<void> off(WhatsappEvent event) async {
    final callbackName = 'callback_${event.value.replaceAll('.', '_')}';
    controller.removeJavaScriptHandler(handlerName: callbackName);
    await controller.evaluateJavascript(
      source: "WPP.removeAllListeners('${event.value}');",
    );
  }

  @override
  Future initializeEventListener(
    OnNewEventFromListener onNewEventFromListener,
  ) async {
    await evaluateJs(
      "window.onCustomEvent = (eventName,data) => window.flutter_inappwebview.callHandler('onCustomEvent',{type:eventName,data:data});",
      tryPromise: false,
    );
    controller.addJavaScriptHandler(
      handlerName: 'onCustomEvent',
      callback: (arguments) {
        if (arguments.isEmpty) return;
        final payload = arguments.first;
        if (payload is Map) {
          onNewEventFromListener(
            payload['type'].toString(),
            payload['data'],
          );
        }
      },
    );
    await controller.evaluateJavascript(
      source: '''
        function initEvents() {
          WPP.on('conn.authenticated', () => window.onCustomEvent('connectionEvent','authenticated'));
          WPP.on('conn.logout', () => window.onCustomEvent('connectionEvent','logout'));
          WPP.on('conn.auth_code_change', () => window.onCustomEvent('connectionEvent','auth_code_change'));
          WPP.on('conn.main_loaded', () => window.onCustomEvent('connectionEvent','main_loaded'));
          WPP.on('conn.main_ready', () => window.onCustomEvent('connectionEvent','main_ready'));
          WPP.on('conn.require_auth', () => window.onCustomEvent('connectionEvent','require_auth'));
        }
        initEvents();
      ''',
    );
  }

  @override
  bool isConnected() => true;
}
