import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'data/db/app_database.dart';
import 'services/connectivity_service.dart';
import 'services/notification_service.dart';
import 'services/sync_controller.dart';
import 'services/create_engine.dart';
import 'services/whatsapp_engine.dart';
import 'ui/chat/chat_screen.dart';
import 'ui/home/home_screen.dart';
import 'ui/theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  final engine = createEngine();
  late final SyncController controller;
  final notifications = NotificationService(
    onOpenChat: (chatId) async {
      final chat = await db.chatById(chatId);
      if (chat == null) return;
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
      );
    },
  );
  controller = SyncController(
    db: db,
    engine: engine,
    connectivity: ConnectivityService(),
    notifications: notifications,
  );
  runApp(WhatsAppApp(db: db, controller: controller, engine: engine));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(controller.start());
  });
}

class WhatsAppApp extends StatefulWidget {
  const WhatsAppApp({
    super.key,
    required this.db,
    required this.controller,
    required this.engine,
  });

  final AppDatabase db;
  final SyncController controller;
  final WhatsAppEngine engine;

  @override
  State<WhatsAppApp> createState() => _WhatsAppAppState();
}

class _WhatsAppAppState extends State<WhatsAppApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.controller.onAppResumed());
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      unawaited(widget.controller.onAppBackgrounded());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      db: widget.db,
      controller: widget.controller,
      engine: widget.engine,
      child: MaterialApp(
        title: 'راسل',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildAppTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}
