import 'package:drift/drift.dart';

class LocalChats extends Table {
  @override
  String get tableName => 'chats';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get waChatId => text().unique()();
  TextColumn get name => text()();
  BoolColumn get isGroup => boolean().withDefault(const Constant(false))();
  TextColumn get profilePicPath => text().nullable()();
  TextColumn get lastMessageText => text().nullable()();
  DateTimeColumn get lastMessageAt => dateTime().nullable()();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
}

class LocalMessages extends Table {
  @override
  String get tableName => 'messages';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get waMessageId => text().unique()();
  IntColumn get chatId => integer().references(LocalChats, #id)();
  TextColumn get senderId => text().nullable()();
  TextColumn get senderName => text().nullable()();
  BoolColumn get fromMe => boolean().withDefault(const Constant(false))();
  TextColumn get body => text().withDefault(const Constant(''))();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get type => text().withDefault(const Constant('chat'))();
  BoolColumn get hasMedia => boolean().withDefault(const Constant(false))();
  TextColumn get mediaLocalPath => text().nullable()();
  TextColumn get deliveryStatus =>
      text().withDefault(const Constant('sent'))();
}

class LocalContacts extends Table {
  @override
  String get tableName => 'contacts';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get waId => text().unique()();
  TextColumn get phone => text().nullable()();
  TextColumn get name => text()();
  TextColumn get profilePicPath => text().nullable()();
}

class AppSettings extends Table {
  @override
  String get tableName => 'app_state';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class OutgoingQueueItems extends Table {
  @override
  String get tableName => 'outgoing_queue';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get chatId => integer().references(LocalChats, #id)();
  TextColumn get waChatId => text()();
  TextColumn get body => text()();
  TextColumn get type => text().withDefault(const Constant('text'))();
  TextColumn get mediaPath => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending_local'))();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get localMessageKey => text()();
}

class LocalGroups extends Table {
  @override
  String get tableName => 'groups';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get waGroupId => text().unique()();
  TextColumn get name => text()();
  TextColumn get ownerId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
}

class GroupMembers extends Table {
  @override
  String get tableName => 'group_participants';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get waGroupId => text()();
  TextColumn get waId => text()();
  TextColumn get name => text().nullable()();
  BoolColumn get isAdmin => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {waGroupId, waId},
      ];
}
