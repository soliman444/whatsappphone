import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/models/models.dart';
import '../widgets/qr_panel.dart';

class QrLoginPage extends StatelessWidget {
  const QrLoginPage({super.key});

  static Future<void> open(BuildContext context) {
    AppScope.of(context).controller.connect();
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const QrLoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    return Scaffold(
      appBar: AppBar(title: const Text('ربط الحساب')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ValueListenableBuilder<String>(
          valueListenable: controller.status,
          builder: (context, status, _) {
            if (status == AppConnectionStatus.online) {
              return const QrPanel();
            }
            return const SingleChildScrollView(
              child: Center(child: QrPanel()),
            );
          },
        ),
      ),
    );
  }
}
