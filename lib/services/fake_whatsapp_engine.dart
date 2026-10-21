import '../data/models/models.dart';
import 'whatsapp_engine.dart';

class FakeWhatsAppEngine implements WhatsAppEngine {
  bool connected = false;
  final List<WaChat> chats;
  final List<WaMessage> messages;
  final List<String> sent = [];

  FakeWhatsAppEngine({
    this.chats = const [],
    this.messages = const [],
  });

  @override
  bool get isConnected => connected;

  @override
  Future<void> connect({
    required QrCallback onQr,
    required ConnectionCallback onEvent,
    bool persistSession = true,
  }) async {
    connected = true;
    onQr(null, null);
    onEvent(AppConnectionStatus.online);
  }

  @override
  Future<void> disconnect({bool logout = false}) async {
    connected = false;
  }

  @override
  Future<List<WaChat>> getChats() async => chats;

  @override
  Future<List<WaMessage>> getMessages(
    String chatId, {
    int count = 50,
    String? beforeId,
  }) async {
    var items = messages.where((message) => message.chatId == chatId).toList();
    if (beforeId != null) {
      final index = items.indexWhere((message) => message.id == beforeId);
      if (index > 0) {
        items = items.sublist(0, index);
      } else if (index == 0) {
        items = const [];
      }
    }
    if (items.length > count) {
      items = items.sublist(items.length - count);
    }
    return items;
  }

  @override
  Future<void> sendText(String chatId, String message) async {
    sent.add('$chatId:$message');
  }

  @override
  Future<void> sendMedia({
    required String chatId,
    required List<int> bytes,
    required String type,
    String? caption,
    String? fileName,
  }) async {
    sent.add('$chatId:$type');
  }

  @override
  Future<void> markSeen(String chatId) async {}

  @override
  Future<List<WaContact>> getContacts() async => const [];

  @override
  Future<List<WaChat>> getGroups() async => const [];

  @override
  Future<List<WaParticipant>> getParticipants(String groupId) async =>
      const [];

  @override
  Future<String?> getProfilePicture(String id) async => null;

  @override
  Future<Map<String, dynamic>?> downloadMedia(String messageId) async => null;

  @override
  Future<void> listenMessages(MessageCallback onMessage) async {}

  @override
  Future<void> listenAck(void Function(String messageId, int ack) onAck) async {}
}
