import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:whatsapp_bot_platform_interface/whatsapp_bot_platform_interface.dart';

import '../../services/web_wa_host.dart';

class WebWaView extends StatelessWidget {
  const WebWaView({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: Colors.white,
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri(WhatsAppMetadata.whatsAppURL),
          ),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            cacheEnabled: true,
            preferredContentMode: UserPreferredContentMode.DESKTOP,
            userAgent: WhatsAppMetadata.userAgent,
            iframeAllow: 'camera; microphone; clipboard-read; clipboard-write',
            iframeAllowFullscreen: true,
          ),
          onWebViewCreated: WebWaHost.attach,
          onLoadStop: (controller, _) => WebWaHost.attach(controller),
        ),
      ),
    );
  }
}
