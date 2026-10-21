import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp/data/db/app_database.dart';
import 'package:whatsapp/data/models/models.dart';
import 'package:whatsapp/main.dart';
import 'package:whatsapp/services/connectivity_service.dart';
import 'package:whatsapp/services/fake_whatsapp_engine.dart';
import 'package:whatsapp/services/sync_controller.dart';

void main() {
  testWidgets('shows saved chats from the local database', (tester) async {
    final db = AppDatabase.memory();
    final controller = SyncController(
      db: db,
      engine: FakeWhatsAppEngine(),
      connectivity: ConnectivityService(
        overrideOnline: false,
        changes: const Stream.empty(),
      ),
    );
    await db.upsertChat(
      waChatId: '966500000000@c.us',
      name: 'أيا',
      isGroup: false,
      lastMessageText: 'مرحبا',
      lastMessageAt: DateTime(2026, 1, 1, 10),
    );

    await tester.pumpWidget(
      WhatsAppApp(
        db: db,
        controller: controller,
        engine: FakeWhatsAppEngine(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('الدردشات'), findsWidgets);
    expect(find.text('أيا'), findsOneWidget);
    expect(find.text('مرحبا'), findsOneWidget);
    expect(find.text('القنوات'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await controller.dispose();
    await db.close();
  });

  test('parses WhatsApp chat and message payloads', () {
    final chat = WaParsers.chat({
      'id': {'_serialized': '966511111111@c.us'},
      'name': 'سعد',
      'isGroup': false,
      'unreadCount': 2,
      'lastMessage': {'body': 'أهلا', 't': 1700000000},
    });

    expect(chat.id, '966511111111@c.us');
    expect(chat.name, 'سعد');
    expect(chat.unreadCount, 2);
    expect(chat.lastMessageText, 'أهلا');

    final message = WaParsers.message({
      'id': {
        '_serialized': 'true_966511111111@c.us_ABCDEF',
        'fromMe': true,
        'remote': '966511111111@c.us',
      },
      'body': 'تم',
      'type': 'chat',
      't': 1700000000,
    });

    expect(message.fromMe, isTrue);
    expect(message.body, 'تم');
    expect(message.chatId, '966511111111@c.us');

    final group = WaParsers.chat({
      'id': {'_serialized': '120363@g.us'},
      'isGroup': true,
      'formattedTitle': '120363@g.us',
      'groupMetadata': {'subject': 'فريق العمل'},
    });
    expect(group.isGroup, isTrue);
    expect(group.name, 'فريق العمل');

    final channel = WaParsers.chat({
      'id': {'_serialized': '120363@newsletter'},
      'isNewsletter': true,
      'formattedTitle': 'قناة الأخبار',
      'newsletterMetadata': {'name': 'قناة الأخبار'},
    });
    expect(channel.isChannel, isTrue);
    expect(channel.isGroup, isFalse);
    expect(channel.name, 'قناة الأخبار');
    expect(ChatKinds.isChannelId(channel.id), isTrue);
  });

  test('stores outgoing messages locally before WhatsApp send', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final controller = SyncController(
      db: db,
      engine: FakeWhatsAppEngine(),
      connectivity: ConnectivityService(
        overrideOnline: false,
        changes: const Stream.empty(),
      ),
    );
    addTearDown(controller.dispose);

    final chat = await db.upsertChat(
      waChatId: '966522222222@c.us',
      name: 'نورة',
      isGroup: false,
    );

    await controller.sendText(
      chatId: chat.id,
      waChatId: chat.waChatId,
      body: 'رسالة محلية',
    );

    final messages = await db.messagesForChat(chat.id);
    expect(messages.single.body, 'رسالة محلية');
    expect(messages.single.fromMe, isTrue);
    expect(messages.single.deliveryStatus, 'pending_local');
  });
}
