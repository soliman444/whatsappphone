import 'dart:typed_data';

import '../data/models/models.dart';

typedef QrCallback = void Function(String? qr, Uint8List? imageBytes);
typedef ConnectionCallback = void Function(String event);
typedef MessageCallback = void Function(WaMessage message);

abstract class WhatsAppEngine {
  bool get isConnected;

  Future<bool> isReady() async => isConnected;

  Future<bool> isMainReady() async => isReady();

  Future<void> connect({
    required QrCallback onQr,
    required ConnectionCallback onEvent,
    bool persistSession = true,
  });

  Future<void> disconnect({bool logout = false});

  Future<List<WaChat>> getChats();

  Future<List<WaChat>> getChatPreviews() async => const [];

  Future<WaChat?> getChat(String id) async => null;

  Future<WaChatIdentity> resolveChatIdentity(String id) async {
    return WaChatIdentity(
      id: id,
      hidden: ChatKinds.isSystemId(id),
    );
  }

  Future<WaContact?> getContact(String id) async => null;

  Future<List<WaMessage>> getMessages(
    String chatId, {
    int count = 50,
    String? beforeId,
  });

  Future<void> sendText(String chatId, String message);

  Future<void> sendMedia({
    required String chatId,
    required List<int> bytes,
    required String type,
    String? caption,
    String? fileName,
  });

  Future<void> forwardMessage({
    required String toChatId,
    required String messageId,
  }) async {}

  Future<void> markSeen(String chatId);

  Future<List<WaContact>> getContacts();

  Future<Map<String, String>> getContactNameMap() async => const {};

  Future<Map<String, String>> getGroupNameMap() async => const {};

  Future<List<WaChat>> getGroups() async => const [];

  Future<List<WaParticipant>> getParticipants(String groupId) async =>
      const [];

  Future<String?> getProfilePicture(String id) async => null;

  Future<WaProfile> getMyProfile() async =>
      const WaProfile(waId: '', name: '');

  Future<void> setMyProfileName(String name) async {}

  Future<void> setMyAbout(String about) async {}

  Future<void> setMyProfilePicture(List<int> bytes) async {}

  Future<String?> getContactAbout(String id) async => null;

  Future<Map<String, dynamic>?> downloadMedia(String messageId);

  Future<StatusFeed> getStatusFeed() async => const StatusFeed();

  Future<void> sendTextStatus(String text, {String backgroundColor = '#075E54'}) async {}

  Future<void> sendImageStatus(List<int> bytes) async {}

  Future<void> sendVideoStatus(List<int> bytes) async {}

  Future<void> markStatusRead(String authorId, String statusId) async {}

  Future<void> removeStatus(String statusId) async {}

  Future<WaStatusViews> getStatusViewers(String statusId) async =>
      const WaStatusViews();

  Future<void> listenMessages(MessageCallback onMessage) async {}

  Future<void> listenAck(void Function(String messageId, int ack) onAck) async {}

  Future<void> keepAlivePulse() async {}
}
