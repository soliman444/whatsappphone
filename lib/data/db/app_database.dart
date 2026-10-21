import 'package:drift/drift.dart';

import '../models/models.dart';
import 'open_connection.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    LocalChats,
    LocalMessages,
    LocalContacts,
    AppSettings,
    OutgoingQueueItems,
    LocalGroups,
    GroupMembers,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  factory AppDatabase.memory() {
    return AppDatabase.forTesting(openMemoryConnection());
  }

  static QueryExecutor _openConnection() => openConnection();

  @override
  int get schemaVersion => 1;

  Stream<List<LocalChat>> watchChats({bool channels = false}) {
    return (select(localChats)..orderBy([
          (t) => OrderingTerm(
            expression: t.lastMessageAt,
            mode: OrderingMode.desc,
            nulls: NullsOrder.last,
          ),
          (t) => OrderingTerm.desc(t.updatedAt),
        ]))
        .watch()
        .map((rows) {
          return rows.where((chat) {
            if (ChatKinds.isSystemId(chat.waChatId)) return false;
            final channel = ChatKinds.isChannelId(chat.waChatId);
            return channels ? channel : !channel;
          }).toList();
        });
  }

  Stream<List<LocalChat>> watchChannels() => watchChats(channels: true);

  Future<List<LocalMessage>> messagesForChat(int chatId) {
    return (select(localMessages)
          ..where((t) => t.chatId.equals(chatId))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();
  }

  Stream<List<LocalMessage>> watchMessages(int chatId) {
    return (select(localMessages)
          ..where((t) => t.chatId.equals(chatId))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .watch();
  }

  Future<List<LocalChat>> getAllChats() => select(localChats).get();

  Future<LocalChat?> chatByWaId(String waChatId) {
    return (select(localChats)
          ..where((t) => t.waChatId.equals(waChatId)))
        .getSingleOrNull();
  }

  Future<void> mergeChat(String fromWaId, String intoWaId) async {
    if (fromWaId.isEmpty || intoWaId.isEmpty || fromWaId == intoWaId) return;
    await transaction(() async {
      final from = await chatByWaId(fromWaId);
      if (from == null) return;
      final into = await chatByWaId(intoWaId);
      if (into == null) {
        await (update(localChats)..where((t) => t.id.equals(from.id))).write(
          LocalChatsCompanion(waChatId: Value(intoWaId)),
        );
        await (update(outgoingQueueItems)
              ..where((t) => t.chatId.equals(from.id)))
            .write(OutgoingQueueItemsCompanion(waChatId: Value(intoWaId)));
        return;
      }
      if (from.id == into.id) return;

      final messages = await (select(localMessages)
            ..where((t) => t.chatId.equals(from.id)))
          .get();
      for (final message in messages) {
        final existing = await messageByWaId(message.waMessageId);
        if (existing != null && existing.id != message.id) {
          await (delete(localMessages)..where((t) => t.id.equals(message.id)))
              .go();
          continue;
        }
        await (update(localMessages)..where((t) => t.id.equals(message.id)))
            .write(LocalMessagesCompanion(chatId: Value(into.id)));
      }

      await (update(outgoingQueueItems)
            ..where((t) => t.chatId.equals(from.id)))
          .write(
        OutgoingQueueItemsCompanion(
          chatId: Value(into.id),
          waChatId: Value(intoWaId),
        ),
      );

      if (DisplayNames.isWeak(into.name) && !DisplayNames.isWeak(from.name)) {
        await (update(localChats)..where((t) => t.id.equals(into.id))).write(
          LocalChatsCompanion(name: Value(from.name)),
        );
      }

      await (delete(localChats)..where((t) => t.id.equals(from.id))).go();
    });
  }

  Future<LocalChat?> chatById(int id) {
    return (select(localChats)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<LocalChat?> watchChat(int id) {
    return (select(localChats)..where((t) => t.id.equals(id)))
        .watch()
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  Future<LocalContact?> contactByWaId(String waId) {
    return (select(localContacts)
          ..where((t) => t.waId.equals(waId)))
        .getSingleOrNull();
  }

  Future<LocalContact?> contactByIdentity(String waId) async {
    if (waId.isEmpty) return null;
    final exact = await contactByWaId(waId);
    if (exact != null) return exact;
    final contacts = await select(localContacts).get();
    for (final contact in contacts) {
      if (DisplayNames.samePerson(contact.waId, waId)) return contact;
      if (contact.phone != null && DisplayNames.samePerson(contact.phone!, waId)) {
        return contact;
      }
    }
    return null;
  }

  Future<void> incrementUnread(int chatId) async {
    final chat = await chatById(chatId);
    if (chat == null) return;
    await (update(localChats)..where((t) => t.id.equals(chatId))).write(
      LocalChatsCompanion(unreadCount: Value(chat.unreadCount + 1)),
    );
  }

  Future<LocalMessage?> messageByWaId(String waMessageId) {
    return (select(localMessages)
          ..where((t) => t.waMessageId.equals(waMessageId)))
        .getSingleOrNull();
  }

  Future<String?> groupMemberName(String waGroupId, String waId) async {
    final member = await (select(groupMembers)..where(
          (t) => t.waGroupId.equals(waGroupId) & t.waId.equals(waId),
        ))
        .getSingleOrNull();
    return member?.name;
  }

  Future<void> applyContactNamesToChats([Map<String, String>? extra]) async {
    final contacts = await select(localContacts).get();
    final chats = await select(localChats).get();
    final lookup = <String, String>{};
    void remember(String? key, String name) {
      if (key == null || key.isEmpty || DisplayNames.isWeak(name)) return;
      lookup[key] = name;
      lookup[key.split('@').first] = name;
      final digits = DisplayNames.digits(key);
      if (digits.length >= 8) lookup[digits] = name;
    }

    extra?.forEach(remember);
    for (final contact in contacts) {
      remember(contact.waId, contact.name);
      remember(contact.phone, contact.name);
    }

    for (final chat in chats) {
      if (chat.isGroup || ChatKinds.isChannelId(chat.waChatId)) continue;
      final user = chat.waChatId.split('@').first;
      final digits = DisplayNames.digits(chat.waChatId);
      final name = DisplayNames.best(
        [
          lookup[chat.waChatId],
          lookup[user],
          lookup[digits],
          lookup['$user@c.us'],
          lookup['$user@lid'],
        ],
        fallback: '',
      );
      if (name.isEmpty || name == chat.name) continue;
      await (update(localChats)..where((t) => t.id.equals(chat.id))).write(
        LocalChatsCompanion(name: Value(name)),
      );
    }
  }

  Future<void> unstickDuplicateChatNames() async {
    final chats = await select(localChats).get();
    final oneToOne = chats
        .where(
          (chat) =>
              !chat.isGroup &&
              !ChatKinds.isChannelId(chat.waChatId) &&
              !ChatKinds.isSystemId(chat.waChatId),
        )
        .toList();
    final counts = <String, int>{};
    for (final chat in oneToOne) {
      final name = chat.name.trim();
      if (name.isEmpty || DisplayNames.isWeak(name)) continue;
      counts[name] = (counts[name] ?? 0) + 1;
    }
    for (final chat in oneToOne) {
      final name = chat.name.trim();
      if ((counts[name] ?? 0) < 2) continue;
      final contact = await contactByIdentity(chat.waChatId);
      final book = contact != null && !DisplayNames.isWeak(contact.name)
          ? contact.name.trim()
          : '';
      if (book.isNotEmpty && book == name) continue;
      final next = book.isNotEmpty ? book : DisplayNames.fromId(chat.waChatId);
      if (next == name) continue;
      await (update(localChats)..where((t) => t.id.equals(chat.id))).write(
        LocalChatsCompanion(name: Value(next)),
      );
    }
  }

  Future<LocalGroup?> groupByWaId(String waGroupId) {
    return (select(localGroups)..where((t) => t.waGroupId.equals(waGroupId)))
        .getSingleOrNull();
  }

  Future<void> applyGroupNamesToChats() async {
    final groups = await select(localGroups).get();
    for (final group in groups) {
      if (DisplayNames.isWeak(group.name)) continue;
      final chat = await chatByWaId(group.waGroupId);
      if (chat == null) continue;
      if (!chat.isGroup && !ChatKinds.isGroupId(chat.waChatId)) continue;
      if (chat.name == group.name) continue;
      await (update(localChats)..where((t) => t.id.equals(chat.id))).write(
        LocalChatsCompanion(
          name: Value(group.name),
          isGroup: const Value(true),
        ),
      );
    }
  }

  Future<void> unstickGroupContactTitles() async {
    final contactNames = (await select(localContacts).get())
        .map((contact) => contact.name.trim())
        .where((name) => name.isNotEmpty && !DisplayNames.isWeak(name))
        .toSet();
    final chats = await select(localChats).get();
    for (final chat in chats) {
      if (!chat.isGroup && !ChatKinds.isGroupId(chat.waChatId)) continue;
      final group = await groupByWaId(chat.waChatId);
      if (group != null && !DisplayNames.isWeak(group.name)) {
        if (chat.name != group.name) {
          await (update(localChats)..where((t) => t.id.equals(chat.id))).write(
            LocalChatsCompanion(name: Value(group.name)),
          );
        }
        continue;
      }
      if (!contactNames.contains(chat.name.trim())) continue;
      await (update(localChats)..where((t) => t.id.equals(chat.id))).write(
        const LocalChatsCompanion(name: Value('مجموعة')),
      );
    }
  }

  Future<LocalMessage?> oldestRemoteMessage(int chatId) {
    return (select(localMessages)
          ..where(
            (t) =>
                t.chatId.equals(chatId) & t.waMessageId.like('local_%').not(),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.timestamp),
            (t) => OrderingTerm.asc(t.id),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> messageCountForChat(int chatId) async {
    final count = countAll();
    final query = selectOnly(localMessages)
      ..addColumns([count])
      ..where(localMessages.chatId.equals(chatId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<OutgoingQueueItem?> queueById(int id) {
    return (select(outgoingQueueItems)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<OutgoingQueueItem>> pendingOutgoing() {
    return (select(outgoingQueueItems)
          ..where(
            (t) =>
                t.status.equals('pending_local') | t.status.equals('failed'),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<String?> setting(String key) async {
    final row = await (select(
      appSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> putSetting(String key, String value) {
    return into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(key: Value(key), value: Value(value)),
    );
  }

  Future<bool> get hasSession async =>
      (await setting('has_session')) == 'true';

  Future<void> markSession(bool value) =>
      putSetting('has_session', value ? 'true' : 'false');

  Future<LocalChat> upsertChat({
    required String waChatId,
    required String name,
    required bool isGroup,
    String? profilePicPath,
    String? lastMessageText,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) async {
    return transaction(() async {
    final now = DateTime.now();
    var existing = await chatByWaId(waChatId);
    if (existing == null) {
      try {
        final id = await into(localChats).insert(
          LocalChatsCompanion.insert(
            waChatId: waChatId,
            name: SafeText.display(name),
            isGroup: Value(isGroup),
            profilePicPath: Value(profilePicPath),
            lastMessageText: Value(
              lastMessageText == null
                  ? null
                  : SafeText.display(lastMessageText),
            ),
            lastMessageAt: Value(lastMessageAt),
            unreadCount: Value(unreadCount ?? 0),
            updatedAt: now,
          ),
        );
        return (await chatById(id))!;
      } catch (_) {
        existing = await chatByWaId(waChatId);
        if (existing == null) rethrow;
      }
    }

    final current = existing;
    await (update(localChats)..where((t) => t.id.equals(current.id))).write(
      LocalChatsCompanion(
        name: isGroup
            ? (!DisplayNames.isWeak(name)
                  ? Value(SafeText.display(name))
                  : const Value.absent())
            : Value(
                !DisplayNames.isWeak(current.name)
                    ? SafeText.display(current.name)
                    : SafeText.display(name.isEmpty ? current.name : name),
              ),
        isGroup: Value(isGroup),
        profilePicPath: profilePicPath == null
            ? const Value.absent()
            : Value(profilePicPath),
        lastMessageText: lastMessageText == null ||
                (current.lastMessageAt != null &&
                    lastMessageAt != null &&
                    lastMessageAt.isBefore(current.lastMessageAt!))
            ? const Value.absent()
            : Value(SafeText.display(lastMessageText)),
        lastMessageAt: lastMessageAt == null ||
                (current.lastMessageAt != null &&
                    lastMessageAt.isBefore(current.lastMessageAt!))
            ? const Value.absent()
            : Value(lastMessageAt),
        unreadCount: unreadCount == null
            ? const Value.absent()
            : Value(unreadCount),
        updatedAt: Value(now),
      ),
    );
    return (await chatById(current.id))!;
    });
  }

  Future<LocalMessage?> claimOptimisticOutgoing({
    required int chatId,
    required String waMessageId,
    required String body,
    required String type,
    required DateTime timestamp,
  }) async {
    final already = await messageByWaId(waMessageId);
    final locals = await (select(localMessages)
          ..where(
            (t) => t.fromMe.equals(true) & t.waMessageId.like('local_%'),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .get();
    LocalMessage? match;
    for (final row in locals) {
      final delta = row.timestamp.difference(timestamp).abs();
      if (delta > const Duration(minutes: 3)) continue;
      if (!_sameOutgoingBody(row.body, row.type, body, type)) continue;
      if (row.chatId == chatId) {
        match = row;
        break;
      }
      match ??= row;
    }
    final found = match;
    if (found == null) return already;
    if (already != null && already.id != found.id) {
      await (delete(localMessages)..where((t) => t.id.equals(found.id))).go();
      return already;
    }
    if (found.waMessageId != waMessageId) {
      await (update(localMessages)..where((t) => t.id.equals(found.id))).write(
        LocalMessagesCompanion(waMessageId: Value(waMessageId)),
      );
    }
    return (await messageByWaId(waMessageId)) ?? found;
  }

  bool _sameOutgoingBody(
    String storedBody,
    String storedType,
    String incomingBody,
    String incomingType,
  ) {
    final left = MediaText.readable(storedBody, type: storedType).trim();
    final right = MediaText.readable(incomingBody, type: incomingType).trim();
    if (storedType != 'chat' &&
        incomingType != 'chat' &&
        storedType == incomingType) {
      return left == right || left.isEmpty || right.isEmpty;
    }
    return left.isNotEmpty && left == right;
  }

  Future<void> upsertMessage({
    required String waMessageId,
    required int chatId,
    String? senderId,
    String? senderName,
    required bool fromMe,
    required String body,
    required DateTime timestamp,
    String type = 'chat',
    bool hasMedia = false,
    String? mediaLocalPath,
    String deliveryStatus = 'sent',
  }) async {
    final existing = await (select(
      localMessages,
    )..where((t) => t.waMessageId.equals(waMessageId))).getSingleOrNull();

    if (existing == null) {
      await into(localMessages).insert(
        LocalMessagesCompanion.insert(
          waMessageId: waMessageId,
          chatId: chatId,
          senderId: Value(senderId),
          senderName: Value(senderName),
          fromMe: Value(fromMe),
          body: Value(MediaText.readable(body, type: type)),
          timestamp: timestamp,
          type: Value(type),
          hasMedia: Value(hasMedia),
          mediaLocalPath: Value(mediaLocalPath),
          deliveryStatus: Value(deliveryStatus),
        ),
      );
    } else {
      await (update(
        localMessages,
      )..where((t) => t.id.equals(existing.id))).write(
        LocalMessagesCompanion(
          senderId: Value(senderId ?? existing.senderId),
          senderName: Value(
            DisplayNames.isWeak(senderName) &&
                    !DisplayNames.isWeak(existing.senderName)
                ? existing.senderName
                : senderName ?? existing.senderName,
          ),
          fromMe: Value(fromMe),
          body: Value(
            MediaText.preferFuller(existing.body, body, type: type),
          ),
          timestamp: Value(timestamp),
          type: Value(type),
          hasMedia: Value(hasMedia || existing.hasMedia),
          mediaLocalPath: mediaLocalPath == null
              ? const Value.absent()
              : Value(mediaLocalPath),
          deliveryStatus: Value(
            Receipt.merge(existing.deliveryStatus, deliveryStatus),
          ),
        ),
      );
    }

    final chat = await chatById(chatId);
    final newerPreview = chat?.lastMessageAt == null ||
        !timestamp.isBefore(chat!.lastMessageAt!);
    if (newerPreview) {
      await (update(localChats)..where((t) => t.id.equals(chatId))).write(
        LocalChatsCompanion(
          lastMessageText: Value(MediaText.preview(body, type: type)),
          lastMessageAt: Value(timestamp),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> updateMessageStatus(String waMessageId, String status) async {
    final existing = await messageByAckId(waMessageId);
    if (existing == null) return;
    final merged = Receipt.merge(existing.deliveryStatus, status);
    if (merged == existing.deliveryStatus) return;
    await (update(localMessages)..where((t) => t.id.equals(existing.id)))
        .write(LocalMessagesCompanion(deliveryStatus: Value(merged)));
  }

  Future<LocalMessage?> messageByAckId(String waMessageId) async {
    final exact = await messageByWaId(waMessageId);
    if (exact != null) return exact;
    final suffix = waMessageId.split('_').last;
    if (suffix.length < 8) return null;
    final rows = await (select(localMessages)
          ..where((t) => t.waMessageId.like('%$suffix')))
        .get();
    if (rows.length == 1) return rows.first;
    for (final row in rows) {
      if (row.waMessageId == waMessageId || row.waMessageId.endsWith(suffix)) {
        return row;
      }
    }
    return null;
  }

  Stream<LocalMessage?> watchLatestMessage(int chatId) {
    return (select(localMessages)
          ..where((t) => t.chatId.equals(chatId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.timestamp),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(1))
        .watch()
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  Future<void> setUnread(int chatId, int count) {
    return (update(localChats)..where((t) => t.id.equals(chatId))).write(
      LocalChatsCompanion(unreadCount: Value(count < 0 ? 0 : count)),
    );
  }

  Future<void> updateMessageMedia(String waMessageId, String path) async {
    final existing = await messageByWaId(waMessageId);
    await (update(localMessages)
          ..where((t) => t.waMessageId.equals(waMessageId)))
        .write(
      LocalMessagesCompanion(
        mediaLocalPath: Value(path),
        hasMedia: const Value(true),
        body: existing != null && MediaText.looksLikeBinary(existing.body)
            ? Value(WaMessage.mediaLabel(existing.type))
            : const Value.absent(),
      ),
    );
    if (existing != null && MediaText.looksLikeBinary(existing.body)) {
      final chat = await chatById(existing.chatId);
      if (chat?.lastMessageText == existing.body) {
        await (update(localChats)..where((t) => t.id.equals(existing.chatId)))
            .write(
          LocalChatsCompanion(
            lastMessageText: Value(WaMessage.mediaLabel(existing.type)),
          ),
        );
      }
    }
  }

  Future<void> clearUnread(int chatId) {
    return (update(localChats)..where((t) => t.id.equals(chatId))).write(
      const LocalChatsCompanion(unreadCount: Value(0)),
    );
  }

  Future<void> upsertContact({
    required String waId,
    String? phone,
    required String name,
    String? profilePicPath,
  }) async {
    final existing = await contactByWaId(waId);
    final resolved = DisplayNames.best(
      [name, existing?.name],
      fallback: name.isEmpty ? DisplayNames.fromId(waId) : name,
    );
    if (existing == null) {
      await into(localContacts).insert(
        LocalContactsCompanion.insert(
          waId: waId,
          phone: Value(phone),
          name: resolved,
          profilePicPath: Value(profilePicPath),
        ),
      );
      return;
    }
    await (update(localContacts)..where((t) => t.id.equals(existing.id))).write(
      LocalContactsCompanion(
        phone: Value(phone ?? existing.phone),
        name: Value(resolved),
        profilePicPath: profilePicPath == null
            ? const Value.absent()
            : Value(profilePicPath),
      ),
    );
  }

  Future<void> upsertGroup({
    required String waGroupId,
    required String name,
    String? ownerId,
  }) async {
    final existing = await (select(localGroups)
          ..where((t) => t.waGroupId.equals(waGroupId)))
        .getSingleOrNull();
    final resolved = DisplayNames.best(
      [name, existing?.name],
      fallback: name.isEmpty ? 'مجموعة' : name,
    );
    if (existing == null) {
      await into(localGroups).insert(
        LocalGroupsCompanion.insert(
          waGroupId: waGroupId,
          name: resolved,
          ownerId: Value(ownerId),
          updatedAt: DateTime.now(),
        ),
      );
      return;
    }
    await (update(localGroups)..where((t) => t.id.equals(existing.id))).write(
      LocalGroupsCompanion(
        name: Value(resolved),
        ownerId: ownerId == null ? const Value.absent() : Value(ownerId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> replaceGroupMembers(
    String waGroupId,
    List<GroupMembersCompanion> members,
  ) async {
    await (delete(
      groupMembers,
    )..where((t) => t.waGroupId.equals(waGroupId))).go();
    for (final member in members) {
      await into(groupMembers).insert(member);
    }
  }

  Future<int> enqueueOutgoing(OutgoingQueueItemsCompanion item) {
    return into(outgoingQueueItems).insert(item);
  }

  Future<void> updateQueueStatus(int id, String status, {int? retryCount}) {
    return (update(outgoingQueueItems)..where((t) => t.id.equals(id))).write(
      OutgoingQueueItemsCompanion(
        status: Value(status),
        retryCount: retryCount == null
            ? const Value.absent()
            : Value(retryCount),
      ),
    );
  }

  Future<void> deleteQueueItem(int id) {
    return (delete(outgoingQueueItems)..where((t) => t.id.equals(id))).go();
  }
}
