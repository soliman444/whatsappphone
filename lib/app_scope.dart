import 'package:flutter/material.dart';

import 'data/db/app_database.dart';
import 'services/sync_controller.dart';
import 'services/whatsapp_engine.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.db,
    required this.controller,
    required this.engine,
    required super.child,
  });

  final AppDatabase db;
  final SyncController controller;
  final WhatsAppEngine engine;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return db != oldWidget.db ||
        controller != oldWidget.controller ||
        engine != oldWidget.engine;
  }
}
