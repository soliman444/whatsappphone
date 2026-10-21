import 'dart:convert';
import 'dart:typed_data';

class AppConnectionStatus {
  static const online = 'ONLINE';
  static const syncing = 'SYNCING';
  static const offline = 'OFFLINE';
  static const authRequired = 'AUTH_REQUIRED';
}

class AppShellPhase {
  static const starting = 'starting';
  static const needQr = 'needQr';
  static const linking = 'linking';
  static const ready = 'ready';
}

class WaChat {
  const WaChat({
    required this.id,
    required this.name,
    required this.isGroup,
    this.isChannel = false,
    this.lastMessageText,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.profilePicUrl,
    this.participants = const [],
    this.ownerId,
  });

  final String id;
  final String name;
  final bool isGroup;
  final bool isChannel;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String? profilePicUrl;
  final List<WaParticipant> participants;
  final String? ownerId;
}

class WaParticipant {
  const WaParticipant({
    required this.waId,
    this.name,
    this.isAdmin = false,
  });

  final String waId;
  final String? name;
  final bool isAdmin;
}

class WaMessage {
  const WaMessage({
    required this.id,
    required this.chatId,
    required this.fromMe,
    required this.body,
    required this.timestamp,
    this.senderId,
    this.senderName,
    this.type = 'chat',
    this.hasMedia = false,
    this.caption,
    this.ack,
    this.mediaBase64,
  });

  final String id;
  final String chatId;
  final bool fromMe;
  final String body;
  final DateTime timestamp;
  final String? senderId;
  final String? senderName;
  final String type;
  final bool hasMedia;
  final String? caption;
  final int? ack;
  final String? mediaBase64;

  String get displayBody =>
      MediaText.readable(body, caption: caption, type: type);

  WaMessage copyWith({
    String? id,
    String? chatId,
    bool? fromMe,
    String? body,
    DateTime? timestamp,
    String? senderId,
    String? senderName,
    String? type,
    bool? hasMedia,
    String? caption,
    int? ack,
    String? mediaBase64,
  }) {
    return WaMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      fromMe: fromMe ?? this.fromMe,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      type: type ?? this.type,
      hasMedia: hasMedia ?? this.hasMedia,
      caption: caption ?? this.caption,
      ack: ack ?? this.ack,
      mediaBase64: mediaBase64 ?? this.mediaBase64,
    );
  }

  static String mediaLabel(String type) {
    switch (type) {
      case 'image':
        return 'صورة';
      case 'video':
        return 'فيديو';
      case 'audio':
      case 'ptt':
        return 'رسالة صوتية';
      case 'document':
        return 'ملف';
      case 'sticker':
        return 'ملصق';
      case 'location':
        return 'موقع';
      case 'list':
        return 'قائمة خيارات من حساب أعمال';
      case 'list_response':
        return 'اختيار من قائمة';
      case 'notification_template':
        return 'قالب إشعار من حساب أعمال — واتساب ويب لا يعطي نص القالب';
      case 'biz_content_placeholder':
        return 'إعلان أو كتالوج أعمال — النص محجوب على واتساب ويب';
      case 'interactive':
      case 'buttons_response':
      case 'template':
        return 'رسالة أعمال تفاعلية';
      default:
        return 'رسالة';
    }
  }
}

class MediaText {
  static bool looksLikeBinary(String? value) {
    if (value == null) return false;
    final text = value.trim();
    if (text.isEmpty) return false;
    if (text.startsWith('data:image') ||
        text.startsWith('data:video') ||
        text.startsWith('data:audio') ||
        text.startsWith('data:application')) {
      return true;
    }
    if (text.length < 80) return false;
    if (text.contains(' ') || text.contains('\n')) return false;
    final sample = text.substring(0, text.length > 240 ? 240 : text.length);
    return RegExp(r'^[A-Za-z0-9+/=\r\n]+$').hasMatch(sample);
  }

  static bool isReadable(String? value) {
    final text = value?.trim() ?? '';
    return text.isNotEmpty && !looksLikeBinary(text);
  }

  static String readable(
    String? body, {
    String? caption,
    String type = 'chat',
  }) {
    if (isReadable(caption)) return caption!.trim();
    if (isReadable(body)) return body!.trim();
    return WaMessage.mediaLabel(type);
  }

  static String preferFuller(String current, String incoming, {String type = 'chat'}) {
    final left = readable(current, type: type);
    final right = readable(incoming, type: type);
    if (right.isEmpty || right == WaMessage.mediaLabel(type)) return left;
    if (left.isEmpty || left == WaMessage.mediaLabel(type)) return right;
    if (left.startsWith(right) && left.length > right.length) return left;
    if (right.startsWith(left) && right.length > left.length) return right;
    if (right.length >= left.length) return right;
    return left;
  }

  static String preview(String? value, {String type = 'chat'}) {
    if (value == null || value.trim().isEmpty) return '';
    if (looksLikeBinary(value)) return WaMessage.mediaLabel(type);
    return value.trim();
  }

  static String? extractBase64(String? value) {
    if (!looksLikeBinary(value)) return null;
    final text = value!.trim();
    final comma = text.indexOf(',');
    if (text.startsWith('data:') && comma != -1) {
      return text.substring(comma + 1);
    }
    return text;
  }

  static Uint8List? decode(String? value) {
    final encoded = extractBase64(value);
    if (encoded == null) return null;
    try {
      final bytes = base64Decode(encoded);
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }
}

class WaProfile {
  const WaProfile({
    required this.waId,
    required this.name,
    this.about = '',
    this.phone,
    this.photoPath,
    this.photoUrl,
  });

  final String waId;
  final String name;
  final String about;
  final String? phone;
  final String? photoPath;
  final String? photoUrl;
}

class WaContact {
  const WaContact({
    required this.waId,
    required this.name,
    this.phone,
    this.profilePicUrl,
    this.aliases = const [],
  });

  final String waId;
  final String name;
  final String? phone;
  final String? profilePicUrl;
  final List<String> aliases;
}

class WaStatusViewer {
  const WaStatusViewer({
    required this.waId,
    required this.name,
    this.timestamp,
    this.hiddenReceipt = false,
  });

  final String waId;
  final String name;
  final DateTime? timestamp;
  final bool hiddenReceipt;
}

class WaStatusViews {
  const WaStatusViews({
    this.count = 0,
    this.viewers = const [],
    this.hiddenCount,
  });

  final int count;
  final List<WaStatusViewer> viewers;

  /// Independent hidden total from WhatsApp. Null means unknown, not zero.
  final int? hiddenCount;

  int get shown => viewers.length;
}

class WaStatusItem {
  const WaStatusItem({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.timestamp,
    this.type = 'chat',
    this.body = '',
    this.fromMe = false,
    this.backgroundColor = '#075E54',
    this.viewed = false,
    this.mediaBase64,
    this.viewCount = 0,
    this.viewers = const [],
  });

  final String id;
  final String authorId;
  final String authorName;
  final DateTime timestamp;
  final String type;
  final String body;
  final bool fromMe;
  final String backgroundColor;
  final bool viewed;
  final String? mediaBase64;
  final int viewCount;
  final List<WaStatusViewer> viewers;

  int get shownViewCount => viewCount > 0 ? viewCount : viewers.length;
}

class WaStatusThread {
  const WaStatusThread({
    required this.authorId,
    required this.authorName,
    this.items = const [],
    this.fromMe = false,
    this.unreadCount = 0,
  });

  final String authorId;
  final String authorName;
  final List<WaStatusItem> items;
  final bool fromMe;
  final int unreadCount;

  bool get hasItems => items.isNotEmpty;

  int get viewCount => items.fold<int>(
    0,
    (sum, item) => sum + item.shownViewCount,
  );
}

class StatusFeed {
  const StatusFeed({this.mine, this.others = const []});

  final WaStatusThread? mine;
  final List<WaStatusThread> others;

  List<WaStatusThread> get recent => others.where((thread) {
    return thread.unreadCount > 0 || thread.items.any((item) => !item.viewed);
  }).toList();

  List<WaStatusThread> get viewed => others.where((thread) {
    return thread.unreadCount <= 0 &&
        (thread.items.isEmpty || thread.items.every((item) => item.viewed));
  }).toList();
}

class ChatKinds {
  static bool isChannelId(String id) {
    return id.endsWith('@newsletter') || id.contains('@newsletter');
  }

  static bool isGroupId(String id) {
    return id.endsWith('@g.us') && !isChannelId(id);
  }

  static bool isLidId(String id) {
    if (id.contains('@lid')) return true;
    final user = id.split('@').first;
    return RegExp(r'^\d{15,}$').hasMatch(user);
  }

  static bool isSystemId(String id) {
    if (id.isEmpty) return true;
    final lower = id.toLowerCase();
    return lower == 'status@broadcast' ||
        lower.endsWith('@broadcast') ||
        lower.contains('status@') ||
        lower.contains('@psa') ||
        lower == '0@c.us';
  }

  static bool isNoiseType(String type) {
    return const {
      'protocol',
      'gp2',
      'e2e_notification',
      'ciphertext',
      'call_log',
      'call',
    }.contains(type);
  }

  static bool isMediaType(String type) {
    return const {
      'image',
      'video',
      'audio',
      'ptt',
      'document',
      'sticker',
    }.contains(type);
  }
}

class WaChatIdentity {
  const WaChatIdentity({
    required this.id,
    this.phone,
    this.name,
    this.hidden = false,
  });

  final String id;
  final String? phone;
  final String? name;
  final bool hidden;

  bool get usable => !hidden && id.isNotEmpty && !ChatKinds.isSystemId(id);
}

class SafeText {
  static String display(String? value, {String fallback = ''}) {
    if (value == null || value.isEmpty) return fallback;
    final units = value.codeUnits;
    final out = <int>[];
    for (var i = 0; i < units.length; i++) {
      final unit = units[i];
      if (unit >= 0xD800 && unit <= 0xDBFF) {
        if (i + 1 < units.length) {
          final next = units[i + 1];
          if (next >= 0xDC00 && next <= 0xDFFF) {
            out.add(unit);
            out.add(next);
            i++;
            continue;
          }
        }
        continue;
      }
      if (unit >= 0xDC00 && unit <= 0xDFFF) continue;
      if (unit == 0xFFFE || unit == 0xFFFF) continue;
      out.add(unit);
    }
    if (out.isEmpty) return fallback;
    return String.fromCharCodes(out);
  }
}

class DisplayNames {
  static bool isWeak(String? name) {
    if (name == null) return true;
    final value = name.trim();
    if (value.isEmpty) return true;
    if (value == 'محادثة' ||
        value == 'مجموعة' ||
        value == 'قناة' ||
        value == 'جهة اتصال' ||
        value == 'Unknown') {
      return true;
    }
    if (value.contains('@')) return true;
    return RegExp(r'^\+?\d[\d\s-]{6,}$').hasMatch(value);
  }

  static String best(List<String?> candidates, {required String fallback}) {
    for (final candidate in candidates) {
      final cleaned = SafeText.display(candidate);
      if (!isWeak(cleaned)) return cleaned.trim();
    }
    return SafeText.display(fallback);
  }

  static String fromId(
    String id, {
    bool isGroup = false,
    bool isChannel = false,
  }) {
    if (isChannel || ChatKinds.isChannelId(id)) return 'قناة';
    if (ChatKinds.isLidId(id) || ChatKinds.isSystemId(id)) {
      return isGroup ? 'مجموعة' : 'جهة اتصال';
    }
    final user = id.split('@').first;
    if (user.isEmpty) return isGroup ? 'مجموعة' : 'محادثة';
    return isGroup ? 'مجموعة' : '+$user';
  }

  static String digits(String? value) {
    return (value ?? '').replaceAll(RegExp(r'\D'), '');
  }

  static String? phoneFromId(String? id) {
    if (id == null || id.isEmpty) return null;
    if (ChatKinds.isLidId(id) ||
        ChatKinds.isGroupId(id) ||
        ChatKinds.isChannelId(id) ||
        ChatKinds.isSystemId(id)) {
      return null;
    }
    final value = digits(id);
    if (value.length < 8 || value.length > 15) return null;
    return value;
  }

  static bool samePerson(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    final userA = a.split('@').first;
    final userB = b.split('@').first;
    if (userA.isNotEmpty && userA == userB) return true;
    final digitsA = digits(a);
    final digitsB = digits(b);
    if (digitsA.length < 8 || digitsB.length < 8) return false;
    return digitsA == digitsB ||
        digitsA.endsWith(digitsB) ||
        digitsB.endsWith(digitsA);
  }
}

class ParsedDynamic {
  static dynamic decode(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          return jsonDecode(trimmed);
        } catch (_) {}
      }
    }
    return value;
  }

  static Map<String, dynamic>? asMap(dynamic value) {
    value = decode(value);
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    try {
      final json = value.toJson();
      if (json is Map<String, dynamic>) return json;
      if (json is Map) {
        return json.map((key, item) => MapEntry(key.toString(), item));
      }
    } catch (_) {}
    return null;
  }

  static List<dynamic> asList(dynamic value) {
    value = decode(value);
    if (value is List) return value;
    if (value is Map && value['data'] is List) return value['data'] as List;
    if (value is Map && value['result'] is List) {
      return value['result'] as List;
    }
    return value == null ? const [] : [value];
  }

  static String? text(dynamic value) {
    if (value == null) return null;
    final text = SafeText.display(value.toString()).trim();
    return text.isEmpty || text == 'null' ? null : text;
  }

  static String serializedId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    final map = asMap(value);
    if (map == null) return value.toString();
    return text(map['_serialized']) ??
        text(map['serialized']) ??
        text(map['id']) ??
        value.toString();
  }

  static DateTime? date(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      if (value > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is num) return date(value.toInt());
    return DateTime.tryParse(value.toString());
  }

  static bool flag(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return value == 'true' || value == '1';
    }
    return fallback;
  }

  static int number(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class WaParsers {
  static WaChat chat(dynamic raw) {
    final map = ParsedDynamic.asMap(raw) ?? const {};
    final contact = ParsedDynamic.asMap(map['contact']) ?? const {};
    final last = ParsedDynamic.asMap(map['lastMessage']) ??
        ParsedDynamic.asMap(map['last_message']) ??
        const {};
    final id = ParsedDynamic.serializedId(map['id'] ?? map['chatId']);
    final newsletterMeta = ParsedDynamic.asMap(map['newsletterMetadata']) ??
        ParsedDynamic.asMap(map['newsletter_metadata']);
    final isChannel = ChatKinds.isChannelId(id) ||
        ParsedDynamic.flag(
          map['isNewsletter'] ??
              map['isChannel'] ??
              map['newsletter'],
        );
    final isGroup = !isChannel &&
        ParsedDynamic.flag(
          map['isGroup'] ?? map['isGroupMsg'] ?? ChatKinds.isGroupId(id),
          fallback: ChatKinds.isGroupId(id),
        );
    final groupMeta = ParsedDynamic.asMap(map['groupMetadata']) ??
        ParsedDynamic.asMap(map['group_metadata']);
    final name = DisplayNames.best(
      [
        if (isChannel) ParsedDynamic.text(newsletterMeta?['name']),
        if (isChannel) ParsedDynamic.text(newsletterMeta?['description']),
        if (isGroup) ParsedDynamic.text(groupMeta?['subject']),
        if (isGroup) ParsedDynamic.text(map['subject']),
        ParsedDynamic.text(contact['name']),
        ParsedDynamic.text(contact['verifiedName']),
        ParsedDynamic.text(contact['verifiedBizName']),
        ParsedDynamic.text(map['name']),
        ParsedDynamic.text(map['pushname']),
        ParsedDynamic.text(map['notifyName']),
        ParsedDynamic.text(contact['pushname']),
        ParsedDynamic.text(map['formattedTitle']),
        ParsedDynamic.text(contact['formattedName']),
        ParsedDynamic.text(contact['shortName']),
      ],
      fallback: DisplayNames.fromId(
        id,
        isGroup: isGroup,
        isChannel: isChannel,
      ),
    );
    final lastType = ParsedDynamic.text(last['type']) ?? 'chat';
    final lastBody = last.isEmpty &&
            !MediaText.isReadable(ParsedDynamic.text(map['lastMessageText']))
        ? null
        : MediaText.readable(
            ParsedDynamic.text(last['body']),
            caption: ParsedDynamic.text(last['caption']) ??
                ParsedDynamic.text(map['lastMessageText']),
            type: lastType,
          );
    final lastAt = ParsedDynamic.date(last['t'] ?? last['timestamp']) ??
        ParsedDynamic.date(map['t'] ?? map['timestamp']);
    final participants = ParsedDynamic.asList(
      groupMeta?['participants'] ?? map['participants'],
    ).map(participant).where((member) => member.waId.isNotEmpty).toList();

    return WaChat(
      id: id,
      name: name,
      isGroup: isGroup,
      isChannel: isChannel,
      lastMessageText: lastBody,
      lastMessageAt: lastAt,
      unreadCount: ParsedDynamic.number(map['unreadCount']),
      profilePicUrl: ParsedDynamic.text(map['profilePicUrl']) ??
          ParsedDynamic.text(contact['profilePicUrl']),
      participants: participants,
      ownerId: ParsedDynamic.serializedId(
        groupMeta?['owner'] ?? map['owner'],
      ),
    );
  }

  static WaMessage message(dynamic raw) {
    final map = ParsedDynamic.asMap(raw) ?? const {};
    final idMap = ParsedDynamic.asMap(map['id']);
    final id = ParsedDynamic.serializedId(map['id']);
    final fromMe = ParsedDynamic.flag(
      idMap?['fromMe'] ?? map['fromMe'] ?? map['id']?['fromMe'],
    );
    final chatId = ParsedDynamic.serializedId(
      idMap?['remote'] ??
          map['chatId'] ??
          map['from'] ??
          (fromMe ? map['to'] : map['from']),
    );
    final rawType = ParsedDynamic.text(map['type']) ?? 'chat';
    final rawBody = ParsedDynamic.text(map['body']);
    final caption = ParsedDynamic.text(map['caption']) ??
        businessMessageText(map);
    final mediaBase64 = MediaText.extractBase64(rawBody);
    final mediaTypes = {
      'image',
      'video',
      'audio',
      'ptt',
      'document',
      'sticker',
    };
    final type = rawType == 'chat' && mediaBase64 != null ? 'image' : rawType;
    return WaMessage(
      id: id.isEmpty
          ? 'unknown_${map['t'] ?? DateTime.now().millisecondsSinceEpoch}'
          : id,
      chatId: chatId,
      fromMe: fromMe,
      body: MediaText.readable(rawBody, caption: caption, type: type),
      timestamp:
          ParsedDynamic.date(map['t'] ?? map['timestamp']) ?? DateTime.now(),
      senderId: ParsedDynamic.serializedId(
        map['author'] ?? map['from'] ?? idMap?['participant'],
      ),
      senderName: DisplayNames.best(
        [
          ParsedDynamic.text(map['notifyName']),
          ParsedDynamic.text(map['notify']),
          ParsedDynamic.text(map['senderName']),
          ParsedDynamic.text(map['pushName']),
        ],
        fallback: '',
      ),
      type: type,
      hasMedia: mediaTypes.contains(type) ||
          mediaBase64 != null ||
          ParsedDynamic.flag(map['hasMedia']) ||
          map['deprecatedMms3Url'] != null,
      caption: caption,
      ack: map['ack'] is int
          ? map['ack'] as int
          : ParsedDynamic.number(map['ack'], fallback: -1).clamp(-1, 4),
      mediaBase64: mediaBase64,
    );
  }

  static String? businessMessageText(Map<String, dynamic> map) {
    final list = ParsedDynamic.asMap(map['list']);
    final response = ParsedDynamic.asMap(map['listResponse']) ??
        ParsedDynamic.asMap(map['quotedMsg']);
    final interactive = ParsedDynamic.asMap(map['interactivePayload']) ??
        ParsedDynamic.asMap(map['interactive']);
    final params = ParsedDynamic.asList(
      map['templateParams'] ?? map['hsmParams'],
    )
        .map((item) => ParsedDynamic.text(item))
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .join(' · ');
    final candidates = <String?>[
      ParsedDynamic.text(map['title']),
      ParsedDynamic.text(map['hydratedTitle']),
      ParsedDynamic.text(map['description']),
      ParsedDynamic.text(map['footer']),
      ParsedDynamic.text(map['nativeFlowName']),
      ParsedDynamic.text(map['subtype']),
      if (list != null) ParsedDynamic.text(list['title']),
      if (list != null) ParsedDynamic.text(list['description']),
      if (list != null) ParsedDynamic.text(list['buttonText']),
      if (response != null) ParsedDynamic.text(response['title']),
      if (response != null) ParsedDynamic.text(response['description']),
      if (interactive != null) ParsedDynamic.text(interactive['title']),
      if (interactive != null) ParsedDynamic.text(interactive['body']),
      if (params.isNotEmpty) params,
    ];
    for (final candidate in candidates) {
      if (MediaText.isReadable(candidate)) return candidate!.trim();
    }
    return null;
  }

  static WaParticipant participant(dynamic raw) {
    final map = ParsedDynamic.asMap(raw) ?? const {};
    final contactMap = ParsedDynamic.asMap(map['contact']) ?? const {};
    final waId = ParsedDynamic.serializedId(
      map['id'] ?? map['userWid'] ?? map['phone'] ?? contactMap['id'],
    );
    return WaParticipant(
      waId: waId,
      name: DisplayNames.best(
        [
          ParsedDynamic.text(map['name']),
          ParsedDynamic.text(map['pushname']),
          ParsedDynamic.text(contactMap['name']),
          ParsedDynamic.text(contactMap['verifiedName']),
          ParsedDynamic.text(contactMap['pushname']),
          ParsedDynamic.text(contactMap['formattedName']),
        ],
        fallback: '',
      ),
      isAdmin: ParsedDynamic.flag(map['isAdmin'] ?? map['isSuperAdmin']),
    );
  }

  static WaContact contact(dynamic raw) {
    final map = ParsedDynamic.asMap(raw) ?? const {};
    final waId = ParsedDynamic.serializedId(map['id'] ?? map['wid']);
    final lid = ParsedDynamic.serializedId(map['lid'] ?? map['lidWid']);
    final phone = ParsedDynamic.text(map['number']) ??
        ParsedDynamic.text(map['phone']) ??
        ParsedDynamic.text(map['phoneNumber']) ??
        (waId.contains('@c.us') ? waId.split('@').first : null);
    final aliases = <String>{
      if (lid.isNotEmpty) lid,
      if (phone != null && phone.isNotEmpty) phone,
      if (phone != null && phone.isNotEmpty && !phone.contains('@'))
        '$phone@c.us',
      if (waId.contains('@')) waId.split('@').first,
    }..removeWhere((item) => item.isEmpty || item == waId);
    return WaContact(
      waId: waId,
      name: DisplayNames.best(
        [
          ParsedDynamic.text(map['name']),
          ParsedDynamic.text(map['verifiedName']),
          ParsedDynamic.text(map['verifiedBizName']),
          ParsedDynamic.text(map['pushname']),
          ParsedDynamic.text(map['formattedName']),
          ParsedDynamic.text(map['shortName']),
        ],
        fallback: DisplayNames.fromId(waId),
      ),
      phone: phone,
      profilePicUrl: ParsedDynamic.text(map['profilePicUrl']),
      aliases: aliases.toList(),
    );
  }

  static String ackStatus(int? ack) {
    switch (ack) {
      case 0:
        return 'pending';
      case 1:
        return 'sent';
      case 2:
        return 'delivered';
      case 3:
        return 'read';
      case 4:
        return 'played';
      default:
        return 'sent';
    }
  }

  static WaStatusItem statusItem(
    dynamic raw, {
    required String authorId,
    required String authorName,
    bool fromMe = false,
  }) {
    final map = ParsedDynamic.asMap(raw) ?? const {};
    final rawType = ParsedDynamic.text(map['type']) ?? 'chat';
    final rawBody = ParsedDynamic.text(map['body']);
    final caption = ParsedDynamic.text(map['caption']);
    final mediaBase64 = MediaText.extractBase64(rawBody);
    final type = rawType == 'chat' && mediaBase64 != null ? 'image' : rawType;
    return WaStatusItem(
      id: ParsedDynamic.serializedId(map['id']),
      authorId: authorId,
      authorName: DisplayNames.best([authorName], fallback: 'حالة'),
      timestamp:
          ParsedDynamic.date(map['t'] ?? map['timestamp']) ?? DateTime.now(),
      type: type,
      body: MediaText.readable(rawBody, caption: caption, type: type),
      fromMe: fromMe,
      backgroundColor: ParsedDynamic.text(map['backgroundColor']) ??
          ParsedDynamic.text(map['bgColor']) ??
          '#075E54',
      viewed: ParsedDynamic.flag(map['viewed'] ?? map['ack']),
      mediaBase64: mediaBase64,
      viewCount: ParsedDynamic.number(map['viewCount']),
      viewers: ParsedDynamic.asList(map['viewers'])
          .map(statusViewer)
          .where((viewer) => viewer.waId.isNotEmpty)
          .toList(),
    );
  }

  static WaStatusViewer statusViewer(dynamic raw) {
    final map = ParsedDynamic.asMap(raw) ?? const {};
    final waId = ParsedDynamic.serializedId(
      map['waId'] ?? map['id'] ?? map['wid'],
    );
    return WaStatusViewer(
      waId: waId,
      name: DisplayNames.best(
        [ParsedDynamic.text(map['name'])],
        fallback: DisplayNames.fromId(waId),
      ),
      timestamp: ParsedDynamic.date(map['timestamp'] ?? map['t']),
      hiddenReceipt: ParsedDynamic.flag(
        map['hiddenReceipt'] ?? map['hidden'] ?? map['noReceipt'],
      ),
    );
  }

  static WaStatusThread statusThread(dynamic raw, {bool fromMe = false}) {
    final map = ParsedDynamic.asMap(raw) ?? const {};
    final authorId = ParsedDynamic.serializedId(
      map['authorId'] ?? map['id'] ?? map['wid'],
    );
    final contact = ParsedDynamic.asMap(map['contact']) ?? const {};
    final authorName = DisplayNames.best(
      [
        ParsedDynamic.text(map['authorName']),
        ParsedDynamic.text(contact['name']),
        ParsedDynamic.text(contact['pushname']),
        ParsedDynamic.text(contact['verifiedName']),
      ],
      fallback: fromMe ? 'حالتي' : DisplayNames.fromId(authorId),
    );
    final items = ParsedDynamic.asList(map['items'] ?? map['msgs'] ?? map['messages'])
        .map(
          (item) => statusItem(
            item,
            authorId: authorId,
            authorName: authorName,
            fromMe: fromMe,
          ),
        )
        .where((item) => item.id.isNotEmpty || item.body.isNotEmpty)
        .toList();
    return WaStatusThread(
      authorId: authorId,
      authorName: authorName,
      items: items,
      fromMe: fromMe,
      unreadCount: ParsedDynamic.number(map['unreadCount']),
    );
  }
}

class Receipt {
  static int rank(String status) {
    switch (status) {
      case 'failed':
        return -1;
      case 'pending':
      case 'pending_local':
      case 'sending':
        return 0;
      case 'sent':
        return 1;
      case 'delivered':
        return 2;
      case 'read':
      case 'played':
        return 3;
      default:
        return 1;
    }
  }

  static String merge(String current, String incoming) {
    if (incoming == 'failed' && rank(current) <= 0) return incoming;
    if (current == 'failed' && rank(incoming) <= 0) return current;
    return rank(incoming) >= rank(current) ? incoming : current;
  }

  static bool isRead(String status) =>
      status == 'read' || status == 'played';
}
