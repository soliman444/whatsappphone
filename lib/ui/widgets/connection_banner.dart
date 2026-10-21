import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/models/models.dart';
import '../theme.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    return ValueListenableBuilder<String>(
      valueListenable: controller.status,
      builder: (context, status, _) {
        return ValueListenableBuilder<String>(
          valueListenable: controller.statusText,
          builder: (context, text, _) {
            final color = switch (status) {
              AppConnectionStatus.online => const Color(0xFFDCFCE7),
              AppConnectionStatus.syncing => const Color(0xFFFEF3C7),
              AppConnectionStatus.authRequired => const Color(0xFFFFE4E6),
              _ => const Color(0xFFE5E7EB),
            };
            final icon = switch (status) {
              AppConnectionStatus.online => Icons.cloud_done_outlined,
              AppConnectionStatus.syncing => Icons.sync,
              AppConnectionStatus.authRequired => Icons.qr_code_2,
              _ => Icons.cloud_off_outlined,
            };
            return Material(
              color: color,
              child: InkWell(
                onTap: status == AppConnectionStatus.online
                    ? null
                    : controller.connect,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: AppColors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (status == AppConnectionStatus.authRequired)
                        const Text(
                          'ربط',
                          style: TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
