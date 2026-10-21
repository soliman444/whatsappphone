import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app_scope.dart';
import '../../data/models/models.dart';
import '../theme.dart';
import 'web_wa_view.dart';

class QrPanel extends StatelessWidget {
  const QrPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    return ValueListenableBuilder<String>(
      valueListenable: controller.status,
      builder: (context, status, _) {
        if (status == AppConnectionStatus.online) {
          return const _Box(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'تم المسح — جاري تجهيز المحادثات',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        return ValueListenableBuilder<String?>(
          valueListenable: controller.errorText,
          builder: (context, error, _) {
            return ValueListenableBuilder<String?>(
          valueListenable: controller.qrData,
          builder: (context, qr, _) {
            return ValueListenableBuilder<Uint8List?>(
              valueListenable: controller.qrBytes,
              builder: (context, bytes, _) {
                final hasQrString = qr != null && qr.isNotEmpty;
                final hasImage = bytes != null && bytes.isNotEmpty;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      error ??
                          'اضغط ربط الحساب وانتظر ظهور الرمز. لا تغلق التطبيق.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: error == null ? null : Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Box(
                      child: hasImage
                          ? Image.memory(
                              bytes,
                              width: 240,
                              height: 240,
                              fit: BoxFit.contain,
                            )
                          : hasQrString
                          ? QrImageView(
                              data: qr,
                              size: 240,
                              backgroundColor: Colors.white,
                            )
                          : kIsWeb
                          ? const SizedBox(
                              width: 360,
                              height: 420,
                              child: WebWaView(),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                children: [
                                  if (error == null)
                                    const CircularProgressIndicator()
                                  else
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red.shade400,
                                    ),
                                  const SizedBox(height: 16),
                                  Text(
                                    error == null
                                        ? 'جاري تجهيز الرمز...'
                                        : 'لم يتم إنشاء الرمز',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: controller.connect,
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('ربط الحساب'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                      ),
                    ),
                  ],
                );
              },
            );
            },
            );
          },
        );
      },
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16)],
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
