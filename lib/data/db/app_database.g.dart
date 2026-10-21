// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalChatsTable extends LocalChats
    with TableInfo<$LocalChatsTable, LocalChat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalChatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _waChatIdMeta = const VerificationMeta(
    'waChatId',
  );
  @override
  late final GeneratedColumn<String> waChatId = GeneratedColumn<String>(
    'wa_chat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isGroupMeta = const VerificationMeta(
    'isGroup',
  );
  @override
  late final GeneratedColumn<bool> isGroup = GeneratedColumn<bool>(
    'is_group',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_group" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _profilePicPathMeta = const VerificationMeta(
    'profilePicPath',
  );
  @override
  late final GeneratedColumn<String> profilePicPath = GeneratedColumn<String>(
    'profile_pic_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageTextMeta = const VerificationMeta(
    'lastMessageText',
  );
  @override
  late final GeneratedColumn<String> lastMessageText = GeneratedColumn<String>(
    'last_message_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageAtMeta = const VerificationMeta(
    'lastMessageAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastMessageAt =
      GeneratedColumn<DateTime>(
        'last_message_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    waChatId,
    name,
    isGroup,
    profilePicPath,
    lastMessageText,
    lastMessageAt,
    unreadCount,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chats';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalChat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('wa_chat_id')) {
      context.handle(
        _waChatIdMeta,
        waChatId.isAcceptableOrUnknown(data['wa_chat_id']!, _waChatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_waChatIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_group')) {
      context.handle(
        _isGroupMeta,
        isGroup.isAcceptableOrUnknown(data['is_group']!, _isGroupMeta),
      );
    }
    if (data.containsKey('profile_pic_path')) {
      context.handle(
        _profilePicPathMeta,
        profilePicPath.isAcceptableOrUnknown(
          data['profile_pic_path']!,
          _profilePicPathMeta,
        ),
      );
    }
    if (data.containsKey('last_message_text')) {
      context.handle(
        _lastMessageTextMeta,
        lastMessageText.isAcceptableOrUnknown(
          data['last_message_text']!,
          _lastMessageTextMeta,
        ),
      );
    }
    if (data.containsKey('last_message_at')) {
      context.handle(
        _lastMessageAtMeta,
        lastMessageAt.isAcceptableOrUnknown(
          data['last_message_at']!,
          _lastMessageAtMeta,
        ),
      );
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalChat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalChat(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      waChatId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wa_chat_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_group'],
      )!,
      profilePicPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_pic_path'],
      ),
      lastMessageText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_text'],
      ),
      lastMessageAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_message_at'],
      ),
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalChatsTable createAlias(String alias) {
    return $LocalChatsTable(attachedDatabase, alias);
  }
}

class LocalChat extends DataClass implements Insertable<LocalChat> {
  final int id;
  final String waChatId;
  final String name;
  final bool isGroup;
  final String? profilePicPath;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime updatedAt;
  const LocalChat({
    required this.id,
    required this.waChatId,
    required this.name,
    required this.isGroup,
    this.profilePicPath,
    this.lastMessageText,
    this.lastMessageAt,
    required this.unreadCount,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['wa_chat_id'] = Variable<String>(waChatId);
    map['name'] = Variable<String>(name);
    map['is_group'] = Variable<bool>(isGroup);
    if (!nullToAbsent || profilePicPath != null) {
      map['profile_pic_path'] = Variable<String>(profilePicPath);
    }
    if (!nullToAbsent || lastMessageText != null) {
      map['last_message_text'] = Variable<String>(lastMessageText);
    }
    if (!nullToAbsent || lastMessageAt != null) {
      map['last_message_at'] = Variable<DateTime>(lastMessageAt);
    }
    map['unread_count'] = Variable<int>(unreadCount);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalChatsCompanion toCompanion(bool nullToAbsent) {
    return LocalChatsCompanion(
      id: Value(id),
      waChatId: Value(waChatId),
      name: Value(name),
      isGroup: Value(isGroup),
      profilePicPath: profilePicPath == null && nullToAbsent
          ? const Value.absent()
          : Value(profilePicPath),
      lastMessageText: lastMessageText == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageText),
      lastMessageAt: lastMessageAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageAt),
      unreadCount: Value(unreadCount),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalChat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalChat(
      id: serializer.fromJson<int>(json['id']),
      waChatId: serializer.fromJson<String>(json['waChatId']),
      name: serializer.fromJson<String>(json['name']),
      isGroup: serializer.fromJson<bool>(json['isGroup']),
      profilePicPath: serializer.fromJson<String?>(json['profilePicPath']),
      lastMessageText: serializer.fromJson<String?>(json['lastMessageText']),
      lastMessageAt: serializer.fromJson<DateTime?>(json['lastMessageAt']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'waChatId': serializer.toJson<String>(waChatId),
      'name': serializer.toJson<String>(name),
      'isGroup': serializer.toJson<bool>(isGroup),
      'profilePicPath': serializer.toJson<String?>(profilePicPath),
      'lastMessageText': serializer.toJson<String?>(lastMessageText),
      'lastMessageAt': serializer.toJson<DateTime?>(lastMessageAt),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalChat copyWith({
    int? id,
    String? waChatId,
    String? name,
    bool? isGroup,
    Value<String?> profilePicPath = const Value.absent(),
    Value<String?> lastMessageText = const Value.absent(),
    Value<DateTime?> lastMessageAt = const Value.absent(),
    int? unreadCount,
    DateTime? updatedAt,
  }) => LocalChat(
    id: id ?? this.id,
    waChatId: waChatId ?? this.waChatId,
    name: name ?? this.name,
    isGroup: isGroup ?? this.isGroup,
    profilePicPath: profilePicPath.present
        ? profilePicPath.value
        : this.profilePicPath,
    lastMessageText: lastMessageText.present
        ? lastMessageText.value
        : this.lastMessageText,
    lastMessageAt: lastMessageAt.present
        ? lastMessageAt.value
        : this.lastMessageAt,
    unreadCount: unreadCount ?? this.unreadCount,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalChat copyWithCompanion(LocalChatsCompanion data) {
    return LocalChat(
      id: data.id.present ? data.id.value : this.id,
      waChatId: data.waChatId.present ? data.waChatId.value : this.waChatId,
      name: data.name.present ? data.name.value : this.name,
      isGroup: data.isGroup.present ? data.isGroup.value : this.isGroup,
      profilePicPath: data.profilePicPath.present
          ? data.profilePicPath.value
          : this.profilePicPath,
      lastMessageText: data.lastMessageText.present
          ? data.lastMessageText.value
          : this.lastMessageText,
      lastMessageAt: data.lastMessageAt.present
          ? data.lastMessageAt.value
          : this.lastMessageAt,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalChat(')
          ..write('id: $id, ')
          ..write('waChatId: $waChatId, ')
          ..write('name: $name, ')
          ..write('isGroup: $isGroup, ')
          ..write('profilePicPath: $profilePicPath, ')
          ..write('lastMessageText: $lastMessageText, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    waChatId,
    name,
    isGroup,
    profilePicPath,
    lastMessageText,
    lastMessageAt,
    unreadCount,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalChat &&
          other.id == this.id &&
          other.waChatId == this.waChatId &&
          other.name == this.name &&
          other.isGroup == this.isGroup &&
          other.profilePicPath == this.profilePicPath &&
          other.lastMessageText == this.lastMessageText &&
          other.lastMessageAt == this.lastMessageAt &&
          other.unreadCount == this.unreadCount &&
          other.updatedAt == this.updatedAt);
}

class LocalChatsCompanion extends UpdateCompanion<LocalChat> {
  final Value<int> id;
  final Value<String> waChatId;
  final Value<String> name;
  final Value<bool> isGroup;
  final Value<String?> profilePicPath;
  final Value<String?> lastMessageText;
  final Value<DateTime?> lastMessageAt;
  final Value<int> unreadCount;
  final Value<DateTime> updatedAt;
  const LocalChatsCompanion({
    this.id = const Value.absent(),
    this.waChatId = const Value.absent(),
    this.name = const Value.absent(),
    this.isGroup = const Value.absent(),
    this.profilePicPath = const Value.absent(),
    this.lastMessageText = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalChatsCompanion.insert({
    this.id = const Value.absent(),
    required String waChatId,
    required String name,
    this.isGroup = const Value.absent(),
    this.profilePicPath = const Value.absent(),
    this.lastMessageText = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.unreadCount = const Value.absent(),
    required DateTime updatedAt,
  }) : waChatId = Value(waChatId),
       name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<LocalChat> custom({
    Expression<int>? id,
    Expression<String>? waChatId,
    Expression<String>? name,
    Expression<bool>? isGroup,
    Expression<String>? profilePicPath,
    Expression<String>? lastMessageText,
    Expression<DateTime>? lastMessageAt,
    Expression<int>? unreadCount,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (waChatId != null) 'wa_chat_id': waChatId,
      if (name != null) 'name': name,
      if (isGroup != null) 'is_group': isGroup,
      if (profilePicPath != null) 'profile_pic_path': profilePicPath,
      if (lastMessageText != null) 'last_message_text': lastMessageText,
      if (lastMessageAt != null) 'last_message_at': lastMessageAt,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalChatsCompanion copyWith({
    Value<int>? id,
    Value<String>? waChatId,
    Value<String>? name,
    Value<bool>? isGroup,
    Value<String?>? profilePicPath,
    Value<String?>? lastMessageText,
    Value<DateTime?>? lastMessageAt,
    Value<int>? unreadCount,
    Value<DateTime>? updatedAt,
  }) {
    return LocalChatsCompanion(
      id: id ?? this.id,
      waChatId: waChatId ?? this.waChatId,
      name: name ?? this.name,
      isGroup: isGroup ?? this.isGroup,
      profilePicPath: profilePicPath ?? this.profilePicPath,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (waChatId.present) {
      map['wa_chat_id'] = Variable<String>(waChatId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isGroup.present) {
      map['is_group'] = Variable<bool>(isGroup.value);
    }
    if (profilePicPath.present) {
      map['profile_pic_path'] = Variable<String>(profilePicPath.value);
    }
    if (lastMessageText.present) {
      map['last_message_text'] = Variable<String>(lastMessageText.value);
    }
    if (lastMessageAt.present) {
      map['last_message_at'] = Variable<DateTime>(lastMessageAt.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalChatsCompanion(')
          ..write('id: $id, ')
          ..write('waChatId: $waChatId, ')
          ..write('name: $name, ')
          ..write('isGroup: $isGroup, ')
          ..write('profilePicPath: $profilePicPath, ')
          ..write('lastMessageText: $lastMessageText, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalMessagesTable extends LocalMessages
    with TableInfo<$LocalMessagesTable, LocalMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _waMessageIdMeta = const VerificationMeta(
    'waMessageId',
  );
  @override
  late final GeneratedColumn<String> waMessageId = GeneratedColumn<String>(
    'wa_message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<int> chatId = GeneratedColumn<int>(
    'chat_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
    'sender_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _senderNameMeta = const VerificationMeta(
    'senderName',
  );
  @override
  late final GeneratedColumn<String> senderName = GeneratedColumn<String>(
    'sender_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fromMeMeta = const VerificationMeta('fromMe');
  @override
  late final GeneratedColumn<bool> fromMe = GeneratedColumn<bool>(
    'from_me',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("from_me" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('chat'),
  );
  static const VerificationMeta _hasMediaMeta = const VerificationMeta(
    'hasMedia',
  );
  @override
  late final GeneratedColumn<bool> hasMedia = GeneratedColumn<bool>(
    'has_media',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_media" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _mediaLocalPathMeta = const VerificationMeta(
    'mediaLocalPath',
  );
  @override
  late final GeneratedColumn<String> mediaLocalPath = GeneratedColumn<String>(
    'media_local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deliveryStatusMeta = const VerificationMeta(
    'deliveryStatus',
  );
  @override
  late final GeneratedColumn<String> deliveryStatus = GeneratedColumn<String>(
    'delivery_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sent'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    waMessageId,
    chatId,
    senderId,
    senderName,
    fromMe,
    body,
    timestamp,
    type,
    hasMedia,
    mediaLocalPath,
    deliveryStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('wa_message_id')) {
      context.handle(
        _waMessageIdMeta,
        waMessageId.isAcceptableOrUnknown(
          data['wa_message_id']!,
          _waMessageIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_waMessageIdMeta);
    }
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    }
    if (data.containsKey('sender_name')) {
      context.handle(
        _senderNameMeta,
        senderName.isAcceptableOrUnknown(data['sender_name']!, _senderNameMeta),
      );
    }
    if (data.containsKey('from_me')) {
      context.handle(
        _fromMeMeta,
        fromMe.isAcceptableOrUnknown(data['from_me']!, _fromMeMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('has_media')) {
      context.handle(
        _hasMediaMeta,
        hasMedia.isAcceptableOrUnknown(data['has_media']!, _hasMediaMeta),
      );
    }
    if (data.containsKey('media_local_path')) {
      context.handle(
        _mediaLocalPathMeta,
        mediaLocalPath.isAcceptableOrUnknown(
          data['media_local_path']!,
          _mediaLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('delivery_status')) {
      context.handle(
        _deliveryStatusMeta,
        deliveryStatus.isAcceptableOrUnknown(
          data['delivery_status']!,
          _deliveryStatusMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      waMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wa_message_id'],
      )!,
      chatId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chat_id'],
      )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_id'],
      ),
      senderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_name'],
      ),
      fromMe: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}from_me'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      hasMedia: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_media'],
      )!,
      mediaLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_local_path'],
      ),
      deliveryStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_status'],
      )!,
    );
  }

  @override
  $LocalMessagesTable createAlias(String alias) {
    return $LocalMessagesTable(attachedDatabase, alias);
  }
}

class LocalMessage extends DataClass implements Insertable<LocalMessage> {
  final int id;
  final String waMessageId;
  final int chatId;
  final String? senderId;
  final String? senderName;
  final bool fromMe;
  final String body;
  final DateTime timestamp;
  final String type;
  final bool hasMedia;
  final String? mediaLocalPath;
  final String deliveryStatus;
  const LocalMessage({
    required this.id,
    required this.waMessageId,
    required this.chatId,
    this.senderId,
    this.senderName,
    required this.fromMe,
    required this.body,
    required this.timestamp,
    required this.type,
    required this.hasMedia,
    this.mediaLocalPath,
    required this.deliveryStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['wa_message_id'] = Variable<String>(waMessageId);
    map['chat_id'] = Variable<int>(chatId);
    if (!nullToAbsent || senderId != null) {
      map['sender_id'] = Variable<String>(senderId);
    }
    if (!nullToAbsent || senderName != null) {
      map['sender_name'] = Variable<String>(senderName);
    }
    map['from_me'] = Variable<bool>(fromMe);
    map['body'] = Variable<String>(body);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['type'] = Variable<String>(type);
    map['has_media'] = Variable<bool>(hasMedia);
    if (!nullToAbsent || mediaLocalPath != null) {
      map['media_local_path'] = Variable<String>(mediaLocalPath);
    }
    map['delivery_status'] = Variable<String>(deliveryStatus);
    return map;
  }

  LocalMessagesCompanion toCompanion(bool nullToAbsent) {
    return LocalMessagesCompanion(
      id: Value(id),
      waMessageId: Value(waMessageId),
      chatId: Value(chatId),
      senderId: senderId == null && nullToAbsent
          ? const Value.absent()
          : Value(senderId),
      senderName: senderName == null && nullToAbsent
          ? const Value.absent()
          : Value(senderName),
      fromMe: Value(fromMe),
      body: Value(body),
      timestamp: Value(timestamp),
      type: Value(type),
      hasMedia: Value(hasMedia),
      mediaLocalPath: mediaLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaLocalPath),
      deliveryStatus: Value(deliveryStatus),
    );
  }

  factory LocalMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMessage(
      id: serializer.fromJson<int>(json['id']),
      waMessageId: serializer.fromJson<String>(json['waMessageId']),
      chatId: serializer.fromJson<int>(json['chatId']),
      senderId: serializer.fromJson<String?>(json['senderId']),
      senderName: serializer.fromJson<String?>(json['senderName']),
      fromMe: serializer.fromJson<bool>(json['fromMe']),
      body: serializer.fromJson<String>(json['body']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      type: serializer.fromJson<String>(json['type']),
      hasMedia: serializer.fromJson<bool>(json['hasMedia']),
      mediaLocalPath: serializer.fromJson<String?>(json['mediaLocalPath']),
      deliveryStatus: serializer.fromJson<String>(json['deliveryStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'waMessageId': serializer.toJson<String>(waMessageId),
      'chatId': serializer.toJson<int>(chatId),
      'senderId': serializer.toJson<String?>(senderId),
      'senderName': serializer.toJson<String?>(senderName),
      'fromMe': serializer.toJson<bool>(fromMe),
      'body': serializer.toJson<String>(body),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'type': serializer.toJson<String>(type),
      'hasMedia': serializer.toJson<bool>(hasMedia),
      'mediaLocalPath': serializer.toJson<String?>(mediaLocalPath),
      'deliveryStatus': serializer.toJson<String>(deliveryStatus),
    };
  }

  LocalMessage copyWith({
    int? id,
    String? waMessageId,
    int? chatId,
    Value<String?> senderId = const Value.absent(),
    Value<String?> senderName = const Value.absent(),
    bool? fromMe,
    String? body,
    DateTime? timestamp,
    String? type,
    bool? hasMedia,
    Value<String?> mediaLocalPath = const Value.absent(),
    String? deliveryStatus,
  }) => LocalMessage(
    id: id ?? this.id,
    waMessageId: waMessageId ?? this.waMessageId,
    chatId: chatId ?? this.chatId,
    senderId: senderId.present ? senderId.value : this.senderId,
    senderName: senderName.present ? senderName.value : this.senderName,
    fromMe: fromMe ?? this.fromMe,
    body: body ?? this.body,
    timestamp: timestamp ?? this.timestamp,
    type: type ?? this.type,
    hasMedia: hasMedia ?? this.hasMedia,
    mediaLocalPath: mediaLocalPath.present
        ? mediaLocalPath.value
        : this.mediaLocalPath,
    deliveryStatus: deliveryStatus ?? this.deliveryStatus,
  );
  LocalMessage copyWithCompanion(LocalMessagesCompanion data) {
    return LocalMessage(
      id: data.id.present ? data.id.value : this.id,
      waMessageId: data.waMessageId.present
          ? data.waMessageId.value
          : this.waMessageId,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      senderName: data.senderName.present
          ? data.senderName.value
          : this.senderName,
      fromMe: data.fromMe.present ? data.fromMe.value : this.fromMe,
      body: data.body.present ? data.body.value : this.body,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      type: data.type.present ? data.type.value : this.type,
      hasMedia: data.hasMedia.present ? data.hasMedia.value : this.hasMedia,
      mediaLocalPath: data.mediaLocalPath.present
          ? data.mediaLocalPath.value
          : this.mediaLocalPath,
      deliveryStatus: data.deliveryStatus.present
          ? data.deliveryStatus.value
          : this.deliveryStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessage(')
          ..write('id: $id, ')
          ..write('waMessageId: $waMessageId, ')
          ..write('chatId: $chatId, ')
          ..write('senderId: $senderId, ')
          ..write('senderName: $senderName, ')
          ..write('fromMe: $fromMe, ')
          ..write('body: $body, ')
          ..write('timestamp: $timestamp, ')
          ..write('type: $type, ')
          ..write('hasMedia: $hasMedia, ')
          ..write('mediaLocalPath: $mediaLocalPath, ')
          ..write('deliveryStatus: $deliveryStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    waMessageId,
    chatId,
    senderId,
    senderName,
    fromMe,
    body,
    timestamp,
    type,
    hasMedia,
    mediaLocalPath,
    deliveryStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMessage &&
          other.id == this.id &&
          other.waMessageId == this.waMessageId &&
          other.chatId == this.chatId &&
          other.senderId == this.senderId &&
          other.senderName == this.senderName &&
          other.fromMe == this.fromMe &&
          other.body == this.body &&
          other.timestamp == this.timestamp &&
          other.type == this.type &&
          other.hasMedia == this.hasMedia &&
          other.mediaLocalPath == this.mediaLocalPath &&
          other.deliveryStatus == this.deliveryStatus);
}

class LocalMessagesCompanion extends UpdateCompanion<LocalMessage> {
  final Value<int> id;
  final Value<String> waMessageId;
  final Value<int> chatId;
  final Value<String?> senderId;
  final Value<String?> senderName;
  final Value<bool> fromMe;
  final Value<String> body;
  final Value<DateTime> timestamp;
  final Value<String> type;
  final Value<bool> hasMedia;
  final Value<String?> mediaLocalPath;
  final Value<String> deliveryStatus;
  const LocalMessagesCompanion({
    this.id = const Value.absent(),
    this.waMessageId = const Value.absent(),
    this.chatId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.senderName = const Value.absent(),
    this.fromMe = const Value.absent(),
    this.body = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.type = const Value.absent(),
    this.hasMedia = const Value.absent(),
    this.mediaLocalPath = const Value.absent(),
    this.deliveryStatus = const Value.absent(),
  });
  LocalMessagesCompanion.insert({
    this.id = const Value.absent(),
    required String waMessageId,
    required int chatId,
    this.senderId = const Value.absent(),
    this.senderName = const Value.absent(),
    this.fromMe = const Value.absent(),
    this.body = const Value.absent(),
    required DateTime timestamp,
    this.type = const Value.absent(),
    this.hasMedia = const Value.absent(),
    this.mediaLocalPath = const Value.absent(),
    this.deliveryStatus = const Value.absent(),
  }) : waMessageId = Value(waMessageId),
       chatId = Value(chatId),
       timestamp = Value(timestamp);
  static Insertable<LocalMessage> custom({
    Expression<int>? id,
    Expression<String>? waMessageId,
    Expression<int>? chatId,
    Expression<String>? senderId,
    Expression<String>? senderName,
    Expression<bool>? fromMe,
    Expression<String>? body,
    Expression<DateTime>? timestamp,
    Expression<String>? type,
    Expression<bool>? hasMedia,
    Expression<String>? mediaLocalPath,
    Expression<String>? deliveryStatus,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (waMessageId != null) 'wa_message_id': waMessageId,
      if (chatId != null) 'chat_id': chatId,
      if (senderId != null) 'sender_id': senderId,
      if (senderName != null) 'sender_name': senderName,
      if (fromMe != null) 'from_me': fromMe,
      if (body != null) 'body': body,
      if (timestamp != null) 'timestamp': timestamp,
      if (type != null) 'type': type,
      if (hasMedia != null) 'has_media': hasMedia,
      if (mediaLocalPath != null) 'media_local_path': mediaLocalPath,
      if (deliveryStatus != null) 'delivery_status': deliveryStatus,
    });
  }

  LocalMessagesCompanion copyWith({
    Value<int>? id,
    Value<String>? waMessageId,
    Value<int>? chatId,
    Value<String?>? senderId,
    Value<String?>? senderName,
    Value<bool>? fromMe,
    Value<String>? body,
    Value<DateTime>? timestamp,
    Value<String>? type,
    Value<bool>? hasMedia,
    Value<String?>? mediaLocalPath,
    Value<String>? deliveryStatus,
  }) {
    return LocalMessagesCompanion(
      id: id ?? this.id,
      waMessageId: waMessageId ?? this.waMessageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      fromMe: fromMe ?? this.fromMe,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      hasMedia: hasMedia ?? this.hasMedia,
      mediaLocalPath: mediaLocalPath ?? this.mediaLocalPath,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (waMessageId.present) {
      map['wa_message_id'] = Variable<String>(waMessageId.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<int>(chatId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (senderName.present) {
      map['sender_name'] = Variable<String>(senderName.value);
    }
    if (fromMe.present) {
      map['from_me'] = Variable<bool>(fromMe.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (hasMedia.present) {
      map['has_media'] = Variable<bool>(hasMedia.value);
    }
    if (mediaLocalPath.present) {
      map['media_local_path'] = Variable<String>(mediaLocalPath.value);
    }
    if (deliveryStatus.present) {
      map['delivery_status'] = Variable<String>(deliveryStatus.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessagesCompanion(')
          ..write('id: $id, ')
          ..write('waMessageId: $waMessageId, ')
          ..write('chatId: $chatId, ')
          ..write('senderId: $senderId, ')
          ..write('senderName: $senderName, ')
          ..write('fromMe: $fromMe, ')
          ..write('body: $body, ')
          ..write('timestamp: $timestamp, ')
          ..write('type: $type, ')
          ..write('hasMedia: $hasMedia, ')
          ..write('mediaLocalPath: $mediaLocalPath, ')
          ..write('deliveryStatus: $deliveryStatus')
          ..write(')'))
        .toString();
  }
}

class $LocalContactsTable extends LocalContacts
    with TableInfo<$LocalContactsTable, LocalContact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _waIdMeta = const VerificationMeta('waId');
  @override
  late final GeneratedColumn<String> waId = GeneratedColumn<String>(
    'wa_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profilePicPathMeta = const VerificationMeta(
    'profilePicPath',
  );
  @override
  late final GeneratedColumn<String> profilePicPath = GeneratedColumn<String>(
    'profile_pic_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, waId, phone, name, profilePicPath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalContact> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('wa_id')) {
      context.handle(
        _waIdMeta,
        waId.isAcceptableOrUnknown(data['wa_id']!, _waIdMeta),
      );
    } else if (isInserting) {
      context.missing(_waIdMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('profile_pic_path')) {
      context.handle(
        _profilePicPathMeta,
        profilePicPath.isAcceptableOrUnknown(
          data['profile_pic_path']!,
          _profilePicPathMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalContact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalContact(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      waId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wa_id'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      profilePicPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_pic_path'],
      ),
    );
  }

  @override
  $LocalContactsTable createAlias(String alias) {
    return $LocalContactsTable(attachedDatabase, alias);
  }
}

class LocalContact extends DataClass implements Insertable<LocalContact> {
  final int id;
  final String waId;
  final String? phone;
  final String name;
  final String? profilePicPath;
  const LocalContact({
    required this.id,
    required this.waId,
    this.phone,
    required this.name,
    this.profilePicPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['wa_id'] = Variable<String>(waId);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || profilePicPath != null) {
      map['profile_pic_path'] = Variable<String>(profilePicPath);
    }
    return map;
  }

  LocalContactsCompanion toCompanion(bool nullToAbsent) {
    return LocalContactsCompanion(
      id: Value(id),
      waId: Value(waId),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      name: Value(name),
      profilePicPath: profilePicPath == null && nullToAbsent
          ? const Value.absent()
          : Value(profilePicPath),
    );
  }

  factory LocalContact.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalContact(
      id: serializer.fromJson<int>(json['id']),
      waId: serializer.fromJson<String>(json['waId']),
      phone: serializer.fromJson<String?>(json['phone']),
      name: serializer.fromJson<String>(json['name']),
      profilePicPath: serializer.fromJson<String?>(json['profilePicPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'waId': serializer.toJson<String>(waId),
      'phone': serializer.toJson<String?>(phone),
      'name': serializer.toJson<String>(name),
      'profilePicPath': serializer.toJson<String?>(profilePicPath),
    };
  }

  LocalContact copyWith({
    int? id,
    String? waId,
    Value<String?> phone = const Value.absent(),
    String? name,
    Value<String?> profilePicPath = const Value.absent(),
  }) => LocalContact(
    id: id ?? this.id,
    waId: waId ?? this.waId,
    phone: phone.present ? phone.value : this.phone,
    name: name ?? this.name,
    profilePicPath: profilePicPath.present
        ? profilePicPath.value
        : this.profilePicPath,
  );
  LocalContact copyWithCompanion(LocalContactsCompanion data) {
    return LocalContact(
      id: data.id.present ? data.id.value : this.id,
      waId: data.waId.present ? data.waId.value : this.waId,
      phone: data.phone.present ? data.phone.value : this.phone,
      name: data.name.present ? data.name.value : this.name,
      profilePicPath: data.profilePicPath.present
          ? data.profilePicPath.value
          : this.profilePicPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalContact(')
          ..write('id: $id, ')
          ..write('waId: $waId, ')
          ..write('phone: $phone, ')
          ..write('name: $name, ')
          ..write('profilePicPath: $profilePicPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, waId, phone, name, profilePicPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalContact &&
          other.id == this.id &&
          other.waId == this.waId &&
          other.phone == this.phone &&
          other.name == this.name &&
          other.profilePicPath == this.profilePicPath);
}

class LocalContactsCompanion extends UpdateCompanion<LocalContact> {
  final Value<int> id;
  final Value<String> waId;
  final Value<String?> phone;
  final Value<String> name;
  final Value<String?> profilePicPath;
  const LocalContactsCompanion({
    this.id = const Value.absent(),
    this.waId = const Value.absent(),
    this.phone = const Value.absent(),
    this.name = const Value.absent(),
    this.profilePicPath = const Value.absent(),
  });
  LocalContactsCompanion.insert({
    this.id = const Value.absent(),
    required String waId,
    this.phone = const Value.absent(),
    required String name,
    this.profilePicPath = const Value.absent(),
  }) : waId = Value(waId),
       name = Value(name);
  static Insertable<LocalContact> custom({
    Expression<int>? id,
    Expression<String>? waId,
    Expression<String>? phone,
    Expression<String>? name,
    Expression<String>? profilePicPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (waId != null) 'wa_id': waId,
      if (phone != null) 'phone': phone,
      if (name != null) 'name': name,
      if (profilePicPath != null) 'profile_pic_path': profilePicPath,
    });
  }

  LocalContactsCompanion copyWith({
    Value<int>? id,
    Value<String>? waId,
    Value<String?>? phone,
    Value<String>? name,
    Value<String?>? profilePicPath,
  }) {
    return LocalContactsCompanion(
      id: id ?? this.id,
      waId: waId ?? this.waId,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      profilePicPath: profilePicPath ?? this.profilePicPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (waId.present) {
      map['wa_id'] = Variable<String>(waId.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (profilePicPath.present) {
      map['profile_pic_path'] = Variable<String>(profilePicPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalContactsCompanion(')
          ..write('id: $id, ')
          ..write('waId: $waId, ')
          ..write('phone: $phone, ')
          ..write('name: $name, ')
          ..write('profilePicPath: $profilePicPath')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutgoingQueueItemsTable extends OutgoingQueueItems
    with TableInfo<$OutgoingQueueItemsTable, OutgoingQueueItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutgoingQueueItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<int> chatId = GeneratedColumn<int>(
    'chat_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _waChatIdMeta = const VerificationMeta(
    'waChatId',
  );
  @override
  late final GeneratedColumn<String> waChatId = GeneratedColumn<String>(
    'wa_chat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('text'),
  );
  static const VerificationMeta _mediaPathMeta = const VerificationMeta(
    'mediaPath',
  );
  @override
  late final GeneratedColumn<String> mediaPath = GeneratedColumn<String>(
    'media_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending_local'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localMessageKeyMeta = const VerificationMeta(
    'localMessageKey',
  );
  @override
  late final GeneratedColumn<String> localMessageKey = GeneratedColumn<String>(
    'local_message_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    chatId,
    waChatId,
    body,
    type,
    mediaPath,
    status,
    createdAt,
    retryCount,
    localMessageKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outgoing_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutgoingQueueItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('wa_chat_id')) {
      context.handle(
        _waChatIdMeta,
        waChatId.isAcceptableOrUnknown(data['wa_chat_id']!, _waChatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_waChatIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('media_path')) {
      context.handle(
        _mediaPathMeta,
        mediaPath.isAcceptableOrUnknown(data['media_path']!, _mediaPathMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('local_message_key')) {
      context.handle(
        _localMessageKeyMeta,
        localMessageKey.isAcceptableOrUnknown(
          data['local_message_key']!,
          _localMessageKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localMessageKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutgoingQueueItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutgoingQueueItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      chatId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chat_id'],
      )!,
      waChatId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wa_chat_id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      mediaPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_path'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      localMessageKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_message_key'],
      )!,
    );
  }

  @override
  $OutgoingQueueItemsTable createAlias(String alias) {
    return $OutgoingQueueItemsTable(attachedDatabase, alias);
  }
}

class OutgoingQueueItem extends DataClass
    implements Insertable<OutgoingQueueItem> {
  final int id;
  final int chatId;
  final String waChatId;
  final String body;
  final String type;
  final String? mediaPath;
  final String status;
  final DateTime createdAt;
  final int retryCount;
  final String localMessageKey;
  const OutgoingQueueItem({
    required this.id,
    required this.chatId,
    required this.waChatId,
    required this.body,
    required this.type,
    this.mediaPath,
    required this.status,
    required this.createdAt,
    required this.retryCount,
    required this.localMessageKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['chat_id'] = Variable<int>(chatId);
    map['wa_chat_id'] = Variable<String>(waChatId);
    map['body'] = Variable<String>(body);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || mediaPath != null) {
      map['media_path'] = Variable<String>(mediaPath);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    map['local_message_key'] = Variable<String>(localMessageKey);
    return map;
  }

  OutgoingQueueItemsCompanion toCompanion(bool nullToAbsent) {
    return OutgoingQueueItemsCompanion(
      id: Value(id),
      chatId: Value(chatId),
      waChatId: Value(waChatId),
      body: Value(body),
      type: Value(type),
      mediaPath: mediaPath == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaPath),
      status: Value(status),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      localMessageKey: Value(localMessageKey),
    );
  }

  factory OutgoingQueueItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutgoingQueueItem(
      id: serializer.fromJson<int>(json['id']),
      chatId: serializer.fromJson<int>(json['chatId']),
      waChatId: serializer.fromJson<String>(json['waChatId']),
      body: serializer.fromJson<String>(json['body']),
      type: serializer.fromJson<String>(json['type']),
      mediaPath: serializer.fromJson<String?>(json['mediaPath']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      localMessageKey: serializer.fromJson<String>(json['localMessageKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'chatId': serializer.toJson<int>(chatId),
      'waChatId': serializer.toJson<String>(waChatId),
      'body': serializer.toJson<String>(body),
      'type': serializer.toJson<String>(type),
      'mediaPath': serializer.toJson<String?>(mediaPath),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'localMessageKey': serializer.toJson<String>(localMessageKey),
    };
  }

  OutgoingQueueItem copyWith({
    int? id,
    int? chatId,
    String? waChatId,
    String? body,
    String? type,
    Value<String?> mediaPath = const Value.absent(),
    String? status,
    DateTime? createdAt,
    int? retryCount,
    String? localMessageKey,
  }) => OutgoingQueueItem(
    id: id ?? this.id,
    chatId: chatId ?? this.chatId,
    waChatId: waChatId ?? this.waChatId,
    body: body ?? this.body,
    type: type ?? this.type,
    mediaPath: mediaPath.present ? mediaPath.value : this.mediaPath,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    localMessageKey: localMessageKey ?? this.localMessageKey,
  );
  OutgoingQueueItem copyWithCompanion(OutgoingQueueItemsCompanion data) {
    return OutgoingQueueItem(
      id: data.id.present ? data.id.value : this.id,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      waChatId: data.waChatId.present ? data.waChatId.value : this.waChatId,
      body: data.body.present ? data.body.value : this.body,
      type: data.type.present ? data.type.value : this.type,
      mediaPath: data.mediaPath.present ? data.mediaPath.value : this.mediaPath,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      localMessageKey: data.localMessageKey.present
          ? data.localMessageKey.value
          : this.localMessageKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutgoingQueueItem(')
          ..write('id: $id, ')
          ..write('chatId: $chatId, ')
          ..write('waChatId: $waChatId, ')
          ..write('body: $body, ')
          ..write('type: $type, ')
          ..write('mediaPath: $mediaPath, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('localMessageKey: $localMessageKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    chatId,
    waChatId,
    body,
    type,
    mediaPath,
    status,
    createdAt,
    retryCount,
    localMessageKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutgoingQueueItem &&
          other.id == this.id &&
          other.chatId == this.chatId &&
          other.waChatId == this.waChatId &&
          other.body == this.body &&
          other.type == this.type &&
          other.mediaPath == this.mediaPath &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.localMessageKey == this.localMessageKey);
}

class OutgoingQueueItemsCompanion extends UpdateCompanion<OutgoingQueueItem> {
  final Value<int> id;
  final Value<int> chatId;
  final Value<String> waChatId;
  final Value<String> body;
  final Value<String> type;
  final Value<String?> mediaPath;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<String> localMessageKey;
  const OutgoingQueueItemsCompanion({
    this.id = const Value.absent(),
    this.chatId = const Value.absent(),
    this.waChatId = const Value.absent(),
    this.body = const Value.absent(),
    this.type = const Value.absent(),
    this.mediaPath = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.localMessageKey = const Value.absent(),
  });
  OutgoingQueueItemsCompanion.insert({
    this.id = const Value.absent(),
    required int chatId,
    required String waChatId,
    required String body,
    this.type = const Value.absent(),
    this.mediaPath = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    this.retryCount = const Value.absent(),
    required String localMessageKey,
  }) : chatId = Value(chatId),
       waChatId = Value(waChatId),
       body = Value(body),
       createdAt = Value(createdAt),
       localMessageKey = Value(localMessageKey);
  static Insertable<OutgoingQueueItem> custom({
    Expression<int>? id,
    Expression<int>? chatId,
    Expression<String>? waChatId,
    Expression<String>? body,
    Expression<String>? type,
    Expression<String>? mediaPath,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? localMessageKey,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chatId != null) 'chat_id': chatId,
      if (waChatId != null) 'wa_chat_id': waChatId,
      if (body != null) 'body': body,
      if (type != null) 'type': type,
      if (mediaPath != null) 'media_path': mediaPath,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (localMessageKey != null) 'local_message_key': localMessageKey,
    });
  }

  OutgoingQueueItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? chatId,
    Value<String>? waChatId,
    Value<String>? body,
    Value<String>? type,
    Value<String?>? mediaPath,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<int>? retryCount,
    Value<String>? localMessageKey,
  }) {
    return OutgoingQueueItemsCompanion(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      waChatId: waChatId ?? this.waChatId,
      body: body ?? this.body,
      type: type ?? this.type,
      mediaPath: mediaPath ?? this.mediaPath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      localMessageKey: localMessageKey ?? this.localMessageKey,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<int>(chatId.value);
    }
    if (waChatId.present) {
      map['wa_chat_id'] = Variable<String>(waChatId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (mediaPath.present) {
      map['media_path'] = Variable<String>(mediaPath.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (localMessageKey.present) {
      map['local_message_key'] = Variable<String>(localMessageKey.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutgoingQueueItemsCompanion(')
          ..write('id: $id, ')
          ..write('chatId: $chatId, ')
          ..write('waChatId: $waChatId, ')
          ..write('body: $body, ')
          ..write('type: $type, ')
          ..write('mediaPath: $mediaPath, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('localMessageKey: $localMessageKey')
          ..write(')'))
        .toString();
  }
}

class $LocalGroupsTable extends LocalGroups
    with TableInfo<$LocalGroupsTable, LocalGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _waGroupIdMeta = const VerificationMeta(
    'waGroupId',
  );
  @override
  late final GeneratedColumn<String> waGroupId = GeneratedColumn<String>(
    'wa_group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    waGroupId,
    name,
    ownerId,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('wa_group_id')) {
      context.handle(
        _waGroupIdMeta,
        waGroupId.isAcceptableOrUnknown(data['wa_group_id']!, _waGroupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_waGroupIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      waGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wa_group_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalGroupsTable createAlias(String alias) {
    return $LocalGroupsTable(attachedDatabase, alias);
  }
}

class LocalGroup extends DataClass implements Insertable<LocalGroup> {
  final int id;
  final String waGroupId;
  final String name;
  final String? ownerId;
  final DateTime updatedAt;
  const LocalGroup({
    required this.id,
    required this.waGroupId,
    required this.name,
    this.ownerId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['wa_group_id'] = Variable<String>(waGroupId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalGroupsCompanion toCompanion(bool nullToAbsent) {
    return LocalGroupsCompanion(
      id: Value(id),
      waGroupId: Value(waGroupId),
      name: Value(name),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalGroup(
      id: serializer.fromJson<int>(json['id']),
      waGroupId: serializer.fromJson<String>(json['waGroupId']),
      name: serializer.fromJson<String>(json['name']),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'waGroupId': serializer.toJson<String>(waGroupId),
      'name': serializer.toJson<String>(name),
      'ownerId': serializer.toJson<String?>(ownerId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalGroup copyWith({
    int? id,
    String? waGroupId,
    String? name,
    Value<String?> ownerId = const Value.absent(),
    DateTime? updatedAt,
  }) => LocalGroup(
    id: id ?? this.id,
    waGroupId: waGroupId ?? this.waGroupId,
    name: name ?? this.name,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalGroup copyWithCompanion(LocalGroupsCompanion data) {
    return LocalGroup(
      id: data.id.present ? data.id.value : this.id,
      waGroupId: data.waGroupId.present ? data.waGroupId.value : this.waGroupId,
      name: data.name.present ? data.name.value : this.name,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalGroup(')
          ..write('id: $id, ')
          ..write('waGroupId: $waGroupId, ')
          ..write('name: $name, ')
          ..write('ownerId: $ownerId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, waGroupId, name, ownerId, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalGroup &&
          other.id == this.id &&
          other.waGroupId == this.waGroupId &&
          other.name == this.name &&
          other.ownerId == this.ownerId &&
          other.updatedAt == this.updatedAt);
}

class LocalGroupsCompanion extends UpdateCompanion<LocalGroup> {
  final Value<int> id;
  final Value<String> waGroupId;
  final Value<String> name;
  final Value<String?> ownerId;
  final Value<DateTime> updatedAt;
  const LocalGroupsCompanion({
    this.id = const Value.absent(),
    this.waGroupId = const Value.absent(),
    this.name = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalGroupsCompanion.insert({
    this.id = const Value.absent(),
    required String waGroupId,
    required String name,
    this.ownerId = const Value.absent(),
    required DateTime updatedAt,
  }) : waGroupId = Value(waGroupId),
       name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<LocalGroup> custom({
    Expression<int>? id,
    Expression<String>? waGroupId,
    Expression<String>? name,
    Expression<String>? ownerId,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (waGroupId != null) 'wa_group_id': waGroupId,
      if (name != null) 'name': name,
      if (ownerId != null) 'owner_id': ownerId,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalGroupsCompanion copyWith({
    Value<int>? id,
    Value<String>? waGroupId,
    Value<String>? name,
    Value<String?>? ownerId,
    Value<DateTime>? updatedAt,
  }) {
    return LocalGroupsCompanion(
      id: id ?? this.id,
      waGroupId: waGroupId ?? this.waGroupId,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (waGroupId.present) {
      map['wa_group_id'] = Variable<String>(waGroupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalGroupsCompanion(')
          ..write('id: $id, ')
          ..write('waGroupId: $waGroupId, ')
          ..write('name: $name, ')
          ..write('ownerId: $ownerId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $GroupMembersTable extends GroupMembers
    with TableInfo<$GroupMembersTable, GroupMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _waGroupIdMeta = const VerificationMeta(
    'waGroupId',
  );
  @override
  late final GeneratedColumn<String> waGroupId = GeneratedColumn<String>(
    'wa_group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _waIdMeta = const VerificationMeta('waId');
  @override
  late final GeneratedColumn<String> waId = GeneratedColumn<String>(
    'wa_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAdminMeta = const VerificationMeta(
    'isAdmin',
  );
  @override
  late final GeneratedColumn<bool> isAdmin = GeneratedColumn<bool>(
    'is_admin',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_admin" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, waGroupId, waId, name, isAdmin];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_participants';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('wa_group_id')) {
      context.handle(
        _waGroupIdMeta,
        waGroupId.isAcceptableOrUnknown(data['wa_group_id']!, _waGroupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_waGroupIdMeta);
    }
    if (data.containsKey('wa_id')) {
      context.handle(
        _waIdMeta,
        waId.isAcceptableOrUnknown(data['wa_id']!, _waIdMeta),
      );
    } else if (isInserting) {
      context.missing(_waIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('is_admin')) {
      context.handle(
        _isAdminMeta,
        isAdmin.isAcceptableOrUnknown(data['is_admin']!, _isAdminMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {waGroupId, waId},
  ];
  @override
  GroupMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupMember(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      waGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wa_group_id'],
      )!,
      waId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wa_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      isAdmin: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_admin'],
      )!,
    );
  }

  @override
  $GroupMembersTable createAlias(String alias) {
    return $GroupMembersTable(attachedDatabase, alias);
  }
}

class GroupMember extends DataClass implements Insertable<GroupMember> {
  final int id;
  final String waGroupId;
  final String waId;
  final String? name;
  final bool isAdmin;
  const GroupMember({
    required this.id,
    required this.waGroupId,
    required this.waId,
    this.name,
    required this.isAdmin,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['wa_group_id'] = Variable<String>(waGroupId);
    map['wa_id'] = Variable<String>(waId);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['is_admin'] = Variable<bool>(isAdmin);
    return map;
  }

  GroupMembersCompanion toCompanion(bool nullToAbsent) {
    return GroupMembersCompanion(
      id: Value(id),
      waGroupId: Value(waGroupId),
      waId: Value(waId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      isAdmin: Value(isAdmin),
    );
  }

  factory GroupMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupMember(
      id: serializer.fromJson<int>(json['id']),
      waGroupId: serializer.fromJson<String>(json['waGroupId']),
      waId: serializer.fromJson<String>(json['waId']),
      name: serializer.fromJson<String?>(json['name']),
      isAdmin: serializer.fromJson<bool>(json['isAdmin']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'waGroupId': serializer.toJson<String>(waGroupId),
      'waId': serializer.toJson<String>(waId),
      'name': serializer.toJson<String?>(name),
      'isAdmin': serializer.toJson<bool>(isAdmin),
    };
  }

  GroupMember copyWith({
    int? id,
    String? waGroupId,
    String? waId,
    Value<String?> name = const Value.absent(),
    bool? isAdmin,
  }) => GroupMember(
    id: id ?? this.id,
    waGroupId: waGroupId ?? this.waGroupId,
    waId: waId ?? this.waId,
    name: name.present ? name.value : this.name,
    isAdmin: isAdmin ?? this.isAdmin,
  );
  GroupMember copyWithCompanion(GroupMembersCompanion data) {
    return GroupMember(
      id: data.id.present ? data.id.value : this.id,
      waGroupId: data.waGroupId.present ? data.waGroupId.value : this.waGroupId,
      waId: data.waId.present ? data.waId.value : this.waId,
      name: data.name.present ? data.name.value : this.name,
      isAdmin: data.isAdmin.present ? data.isAdmin.value : this.isAdmin,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupMember(')
          ..write('id: $id, ')
          ..write('waGroupId: $waGroupId, ')
          ..write('waId: $waId, ')
          ..write('name: $name, ')
          ..write('isAdmin: $isAdmin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, waGroupId, waId, name, isAdmin);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupMember &&
          other.id == this.id &&
          other.waGroupId == this.waGroupId &&
          other.waId == this.waId &&
          other.name == this.name &&
          other.isAdmin == this.isAdmin);
}

class GroupMembersCompanion extends UpdateCompanion<GroupMember> {
  final Value<int> id;
  final Value<String> waGroupId;
  final Value<String> waId;
  final Value<String?> name;
  final Value<bool> isAdmin;
  const GroupMembersCompanion({
    this.id = const Value.absent(),
    this.waGroupId = const Value.absent(),
    this.waId = const Value.absent(),
    this.name = const Value.absent(),
    this.isAdmin = const Value.absent(),
  });
  GroupMembersCompanion.insert({
    this.id = const Value.absent(),
    required String waGroupId,
    required String waId,
    this.name = const Value.absent(),
    this.isAdmin = const Value.absent(),
  }) : waGroupId = Value(waGroupId),
       waId = Value(waId);
  static Insertable<GroupMember> custom({
    Expression<int>? id,
    Expression<String>? waGroupId,
    Expression<String>? waId,
    Expression<String>? name,
    Expression<bool>? isAdmin,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (waGroupId != null) 'wa_group_id': waGroupId,
      if (waId != null) 'wa_id': waId,
      if (name != null) 'name': name,
      if (isAdmin != null) 'is_admin': isAdmin,
    });
  }

  GroupMembersCompanion copyWith({
    Value<int>? id,
    Value<String>? waGroupId,
    Value<String>? waId,
    Value<String?>? name,
    Value<bool>? isAdmin,
  }) {
    return GroupMembersCompanion(
      id: id ?? this.id,
      waGroupId: waGroupId ?? this.waGroupId,
      waId: waId ?? this.waId,
      name: name ?? this.name,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (waGroupId.present) {
      map['wa_group_id'] = Variable<String>(waGroupId.value);
    }
    if (waId.present) {
      map['wa_id'] = Variable<String>(waId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isAdmin.present) {
      map['is_admin'] = Variable<bool>(isAdmin.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupMembersCompanion(')
          ..write('id: $id, ')
          ..write('waGroupId: $waGroupId, ')
          ..write('waId: $waId, ')
          ..write('name: $name, ')
          ..write('isAdmin: $isAdmin')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalChatsTable localChats = $LocalChatsTable(this);
  late final $LocalMessagesTable localMessages = $LocalMessagesTable(this);
  late final $LocalContactsTable localContacts = $LocalContactsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $OutgoingQueueItemsTable outgoingQueueItems =
      $OutgoingQueueItemsTable(this);
  late final $LocalGroupsTable localGroups = $LocalGroupsTable(this);
  late final $GroupMembersTable groupMembers = $GroupMembersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localChats,
    localMessages,
    localContacts,
    appSettings,
    outgoingQueueItems,
    localGroups,
    groupMembers,
  ];
}

typedef $$LocalChatsTableCreateCompanionBuilder =
    LocalChatsCompanion Function({
      Value<int> id,
      required String waChatId,
      required String name,
      Value<bool> isGroup,
      Value<String?> profilePicPath,
      Value<String?> lastMessageText,
      Value<DateTime?> lastMessageAt,
      Value<int> unreadCount,
      required DateTime updatedAt,
    });
typedef $$LocalChatsTableUpdateCompanionBuilder =
    LocalChatsCompanion Function({
      Value<int> id,
      Value<String> waChatId,
      Value<String> name,
      Value<bool> isGroup,
      Value<String?> profilePicPath,
      Value<String?> lastMessageText,
      Value<DateTime?> lastMessageAt,
      Value<int> unreadCount,
      Value<DateTime> updatedAt,
    });

class $$LocalChatsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalChatsTable> {
  $$LocalChatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get waChatId => $composableBuilder(
    column: $table.waChatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isGroup => $composableBuilder(
    column: $table.isGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profilePicPath => $composableBuilder(
    column: $table.profilePicPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageText => $composableBuilder(
    column: $table.lastMessageText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalChatsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalChatsTable> {
  $$LocalChatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waChatId => $composableBuilder(
    column: $table.waChatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isGroup => $composableBuilder(
    column: $table.isGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profilePicPath => $composableBuilder(
    column: $table.profilePicPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageText => $composableBuilder(
    column: $table.lastMessageText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalChatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalChatsTable> {
  $$LocalChatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get waChatId =>
      $composableBuilder(column: $table.waChatId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isGroup =>
      $composableBuilder(column: $table.isGroup, builder: (column) => column);

  GeneratedColumn<String> get profilePicPath => $composableBuilder(
    column: $table.profilePicPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageText => $composableBuilder(
    column: $table.lastMessageText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalChatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalChatsTable,
          LocalChat,
          $$LocalChatsTableFilterComposer,
          $$LocalChatsTableOrderingComposer,
          $$LocalChatsTableAnnotationComposer,
          $$LocalChatsTableCreateCompanionBuilder,
          $$LocalChatsTableUpdateCompanionBuilder,
          (
            LocalChat,
            BaseReferences<_$AppDatabase, $LocalChatsTable, LocalChat>,
          ),
          LocalChat,
          PrefetchHooks Function()
        > {
  $$LocalChatsTableTableManager(_$AppDatabase db, $LocalChatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalChatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalChatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalChatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> waChatId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isGroup = const Value.absent(),
                Value<String?> profilePicPath = const Value.absent(),
                Value<String?> lastMessageText = const Value.absent(),
                Value<DateTime?> lastMessageAt = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalChatsCompanion(
                id: id,
                waChatId: waChatId,
                name: name,
                isGroup: isGroup,
                profilePicPath: profilePicPath,
                lastMessageText: lastMessageText,
                lastMessageAt: lastMessageAt,
                unreadCount: unreadCount,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String waChatId,
                required String name,
                Value<bool> isGroup = const Value.absent(),
                Value<String?> profilePicPath = const Value.absent(),
                Value<String?> lastMessageText = const Value.absent(),
                Value<DateTime?> lastMessageAt = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                required DateTime updatedAt,
              }) => LocalChatsCompanion.insert(
                id: id,
                waChatId: waChatId,
                name: name,
                isGroup: isGroup,
                profilePicPath: profilePicPath,
                lastMessageText: lastMessageText,
                lastMessageAt: lastMessageAt,
                unreadCount: unreadCount,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalChatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalChatsTable,
      LocalChat,
      $$LocalChatsTableFilterComposer,
      $$LocalChatsTableOrderingComposer,
      $$LocalChatsTableAnnotationComposer,
      $$LocalChatsTableCreateCompanionBuilder,
      $$LocalChatsTableUpdateCompanionBuilder,
      (LocalChat, BaseReferences<_$AppDatabase, $LocalChatsTable, LocalChat>),
      LocalChat,
      PrefetchHooks Function()
    >;
typedef $$LocalMessagesTableCreateCompanionBuilder =
    LocalMessagesCompanion Function({
      Value<int> id,
      required String waMessageId,
      required int chatId,
      Value<String?> senderId,
      Value<String?> senderName,
      Value<bool> fromMe,
      Value<String> body,
      required DateTime timestamp,
      Value<String> type,
      Value<bool> hasMedia,
      Value<String?> mediaLocalPath,
      Value<String> deliveryStatus,
    });
typedef $$LocalMessagesTableUpdateCompanionBuilder =
    LocalMessagesCompanion Function({
      Value<int> id,
      Value<String> waMessageId,
      Value<int> chatId,
      Value<String?> senderId,
      Value<String?> senderName,
      Value<bool> fromMe,
      Value<String> body,
      Value<DateTime> timestamp,
      Value<String> type,
      Value<bool> hasMedia,
      Value<String?> mediaLocalPath,
      Value<String> deliveryStatus,
    });

class $$LocalMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get waMessageId => $composableBuilder(
    column: $table.waMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fromMe => $composableBuilder(
    column: $table.fromMe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasMedia => $composableBuilder(
    column: $table.hasMedia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaLocalPath => $composableBuilder(
    column: $table.mediaLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryStatus => $composableBuilder(
    column: $table.deliveryStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waMessageId => $composableBuilder(
    column: $table.waMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fromMe => $composableBuilder(
    column: $table.fromMe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasMedia => $composableBuilder(
    column: $table.hasMedia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaLocalPath => $composableBuilder(
    column: $table.mediaLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryStatus => $composableBuilder(
    column: $table.deliveryStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get waMessageId => $composableBuilder(
    column: $table.waMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get fromMe =>
      $composableBuilder(column: $table.fromMe, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get hasMedia =>
      $composableBuilder(column: $table.hasMedia, builder: (column) => column);

  GeneratedColumn<String> get mediaLocalPath => $composableBuilder(
    column: $table.mediaLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryStatus => $composableBuilder(
    column: $table.deliveryStatus,
    builder: (column) => column,
  );
}

class $$LocalMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMessagesTable,
          LocalMessage,
          $$LocalMessagesTableFilterComposer,
          $$LocalMessagesTableOrderingComposer,
          $$LocalMessagesTableAnnotationComposer,
          $$LocalMessagesTableCreateCompanionBuilder,
          $$LocalMessagesTableUpdateCompanionBuilder,
          (
            LocalMessage,
            BaseReferences<_$AppDatabase, $LocalMessagesTable, LocalMessage>,
          ),
          LocalMessage,
          PrefetchHooks Function()
        > {
  $$LocalMessagesTableTableManager(_$AppDatabase db, $LocalMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> waMessageId = const Value.absent(),
                Value<int> chatId = const Value.absent(),
                Value<String?> senderId = const Value.absent(),
                Value<String?> senderName = const Value.absent(),
                Value<bool> fromMe = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<bool> hasMedia = const Value.absent(),
                Value<String?> mediaLocalPath = const Value.absent(),
                Value<String> deliveryStatus = const Value.absent(),
              }) => LocalMessagesCompanion(
                id: id,
                waMessageId: waMessageId,
                chatId: chatId,
                senderId: senderId,
                senderName: senderName,
                fromMe: fromMe,
                body: body,
                timestamp: timestamp,
                type: type,
                hasMedia: hasMedia,
                mediaLocalPath: mediaLocalPath,
                deliveryStatus: deliveryStatus,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String waMessageId,
                required int chatId,
                Value<String?> senderId = const Value.absent(),
                Value<String?> senderName = const Value.absent(),
                Value<bool> fromMe = const Value.absent(),
                Value<String> body = const Value.absent(),
                required DateTime timestamp,
                Value<String> type = const Value.absent(),
                Value<bool> hasMedia = const Value.absent(),
                Value<String?> mediaLocalPath = const Value.absent(),
                Value<String> deliveryStatus = const Value.absent(),
              }) => LocalMessagesCompanion.insert(
                id: id,
                waMessageId: waMessageId,
                chatId: chatId,
                senderId: senderId,
                senderName: senderName,
                fromMe: fromMe,
                body: body,
                timestamp: timestamp,
                type: type,
                hasMedia: hasMedia,
                mediaLocalPath: mediaLocalPath,
                deliveryStatus: deliveryStatus,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMessagesTable,
      LocalMessage,
      $$LocalMessagesTableFilterComposer,
      $$LocalMessagesTableOrderingComposer,
      $$LocalMessagesTableAnnotationComposer,
      $$LocalMessagesTableCreateCompanionBuilder,
      $$LocalMessagesTableUpdateCompanionBuilder,
      (
        LocalMessage,
        BaseReferences<_$AppDatabase, $LocalMessagesTable, LocalMessage>,
      ),
      LocalMessage,
      PrefetchHooks Function()
    >;
typedef $$LocalContactsTableCreateCompanionBuilder =
    LocalContactsCompanion Function({
      Value<int> id,
      required String waId,
      Value<String?> phone,
      required String name,
      Value<String?> profilePicPath,
    });
typedef $$LocalContactsTableUpdateCompanionBuilder =
    LocalContactsCompanion Function({
      Value<int> id,
      Value<String> waId,
      Value<String?> phone,
      Value<String> name,
      Value<String?> profilePicPath,
    });

class $$LocalContactsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalContactsTable> {
  $$LocalContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get waId => $composableBuilder(
    column: $table.waId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profilePicPath => $composableBuilder(
    column: $table.profilePicPath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalContactsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalContactsTable> {
  $$LocalContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waId => $composableBuilder(
    column: $table.waId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profilePicPath => $composableBuilder(
    column: $table.profilePicPath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalContactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalContactsTable> {
  $$LocalContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get waId =>
      $composableBuilder(column: $table.waId, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get profilePicPath => $composableBuilder(
    column: $table.profilePicPath,
    builder: (column) => column,
  );
}

class $$LocalContactsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalContactsTable,
          LocalContact,
          $$LocalContactsTableFilterComposer,
          $$LocalContactsTableOrderingComposer,
          $$LocalContactsTableAnnotationComposer,
          $$LocalContactsTableCreateCompanionBuilder,
          $$LocalContactsTableUpdateCompanionBuilder,
          (
            LocalContact,
            BaseReferences<_$AppDatabase, $LocalContactsTable, LocalContact>,
          ),
          LocalContact,
          PrefetchHooks Function()
        > {
  $$LocalContactsTableTableManager(_$AppDatabase db, $LocalContactsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> waId = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> profilePicPath = const Value.absent(),
              }) => LocalContactsCompanion(
                id: id,
                waId: waId,
                phone: phone,
                name: name,
                profilePicPath: profilePicPath,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String waId,
                Value<String?> phone = const Value.absent(),
                required String name,
                Value<String?> profilePicPath = const Value.absent(),
              }) => LocalContactsCompanion.insert(
                id: id,
                waId: waId,
                phone: phone,
                name: name,
                profilePicPath: profilePicPath,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalContactsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalContactsTable,
      LocalContact,
      $$LocalContactsTableFilterComposer,
      $$LocalContactsTableOrderingComposer,
      $$LocalContactsTableAnnotationComposer,
      $$LocalContactsTableCreateCompanionBuilder,
      $$LocalContactsTableUpdateCompanionBuilder,
      (
        LocalContact,
        BaseReferences<_$AppDatabase, $LocalContactsTable, LocalContact>,
      ),
      LocalContact,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$OutgoingQueueItemsTableCreateCompanionBuilder =
    OutgoingQueueItemsCompanion Function({
      Value<int> id,
      required int chatId,
      required String waChatId,
      required String body,
      Value<String> type,
      Value<String?> mediaPath,
      Value<String> status,
      required DateTime createdAt,
      Value<int> retryCount,
      required String localMessageKey,
    });
typedef $$OutgoingQueueItemsTableUpdateCompanionBuilder =
    OutgoingQueueItemsCompanion Function({
      Value<int> id,
      Value<int> chatId,
      Value<String> waChatId,
      Value<String> body,
      Value<String> type,
      Value<String?> mediaPath,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<int> retryCount,
      Value<String> localMessageKey,
    });

class $$OutgoingQueueItemsTableFilterComposer
    extends Composer<_$AppDatabase, $OutgoingQueueItemsTable> {
  $$OutgoingQueueItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get waChatId => $composableBuilder(
    column: $table.waChatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaPath => $composableBuilder(
    column: $table.mediaPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localMessageKey => $composableBuilder(
    column: $table.localMessageKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutgoingQueueItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutgoingQueueItemsTable> {
  $$OutgoingQueueItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waChatId => $composableBuilder(
    column: $table.waChatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaPath => $composableBuilder(
    column: $table.mediaPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localMessageKey => $composableBuilder(
    column: $table.localMessageKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutgoingQueueItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutgoingQueueItemsTable> {
  $$OutgoingQueueItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<String> get waChatId =>
      $composableBuilder(column: $table.waChatId, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get mediaPath =>
      $composableBuilder(column: $table.mediaPath, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localMessageKey => $composableBuilder(
    column: $table.localMessageKey,
    builder: (column) => column,
  );
}

class $$OutgoingQueueItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutgoingQueueItemsTable,
          OutgoingQueueItem,
          $$OutgoingQueueItemsTableFilterComposer,
          $$OutgoingQueueItemsTableOrderingComposer,
          $$OutgoingQueueItemsTableAnnotationComposer,
          $$OutgoingQueueItemsTableCreateCompanionBuilder,
          $$OutgoingQueueItemsTableUpdateCompanionBuilder,
          (
            OutgoingQueueItem,
            BaseReferences<
              _$AppDatabase,
              $OutgoingQueueItemsTable,
              OutgoingQueueItem
            >,
          ),
          OutgoingQueueItem,
          PrefetchHooks Function()
        > {
  $$OutgoingQueueItemsTableTableManager(
    _$AppDatabase db,
    $OutgoingQueueItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutgoingQueueItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutgoingQueueItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutgoingQueueItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> chatId = const Value.absent(),
                Value<String> waChatId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> mediaPath = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String> localMessageKey = const Value.absent(),
              }) => OutgoingQueueItemsCompanion(
                id: id,
                chatId: chatId,
                waChatId: waChatId,
                body: body,
                type: type,
                mediaPath: mediaPath,
                status: status,
                createdAt: createdAt,
                retryCount: retryCount,
                localMessageKey: localMessageKey,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int chatId,
                required String waChatId,
                required String body,
                Value<String> type = const Value.absent(),
                Value<String?> mediaPath = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                Value<int> retryCount = const Value.absent(),
                required String localMessageKey,
              }) => OutgoingQueueItemsCompanion.insert(
                id: id,
                chatId: chatId,
                waChatId: waChatId,
                body: body,
                type: type,
                mediaPath: mediaPath,
                status: status,
                createdAt: createdAt,
                retryCount: retryCount,
                localMessageKey: localMessageKey,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutgoingQueueItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutgoingQueueItemsTable,
      OutgoingQueueItem,
      $$OutgoingQueueItemsTableFilterComposer,
      $$OutgoingQueueItemsTableOrderingComposer,
      $$OutgoingQueueItemsTableAnnotationComposer,
      $$OutgoingQueueItemsTableCreateCompanionBuilder,
      $$OutgoingQueueItemsTableUpdateCompanionBuilder,
      (
        OutgoingQueueItem,
        BaseReferences<
          _$AppDatabase,
          $OutgoingQueueItemsTable,
          OutgoingQueueItem
        >,
      ),
      OutgoingQueueItem,
      PrefetchHooks Function()
    >;
typedef $$LocalGroupsTableCreateCompanionBuilder =
    LocalGroupsCompanion Function({
      Value<int> id,
      required String waGroupId,
      required String name,
      Value<String?> ownerId,
      required DateTime updatedAt,
    });
typedef $$LocalGroupsTableUpdateCompanionBuilder =
    LocalGroupsCompanion Function({
      Value<int> id,
      Value<String> waGroupId,
      Value<String> name,
      Value<String?> ownerId,
      Value<DateTime> updatedAt,
    });

class $$LocalGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalGroupsTable> {
  $$LocalGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get waGroupId => $composableBuilder(
    column: $table.waGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalGroupsTable> {
  $$LocalGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waGroupId => $composableBuilder(
    column: $table.waGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalGroupsTable> {
  $$LocalGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get waGroupId =>
      $composableBuilder(column: $table.waGroupId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalGroupsTable,
          LocalGroup,
          $$LocalGroupsTableFilterComposer,
          $$LocalGroupsTableOrderingComposer,
          $$LocalGroupsTableAnnotationComposer,
          $$LocalGroupsTableCreateCompanionBuilder,
          $$LocalGroupsTableUpdateCompanionBuilder,
          (
            LocalGroup,
            BaseReferences<_$AppDatabase, $LocalGroupsTable, LocalGroup>,
          ),
          LocalGroup,
          PrefetchHooks Function()
        > {
  $$LocalGroupsTableTableManager(_$AppDatabase db, $LocalGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> waGroupId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalGroupsCompanion(
                id: id,
                waGroupId: waGroupId,
                name: name,
                ownerId: ownerId,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String waGroupId,
                required String name,
                Value<String?> ownerId = const Value.absent(),
                required DateTime updatedAt,
              }) => LocalGroupsCompanion.insert(
                id: id,
                waGroupId: waGroupId,
                name: name,
                ownerId: ownerId,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalGroupsTable,
      LocalGroup,
      $$LocalGroupsTableFilterComposer,
      $$LocalGroupsTableOrderingComposer,
      $$LocalGroupsTableAnnotationComposer,
      $$LocalGroupsTableCreateCompanionBuilder,
      $$LocalGroupsTableUpdateCompanionBuilder,
      (
        LocalGroup,
        BaseReferences<_$AppDatabase, $LocalGroupsTable, LocalGroup>,
      ),
      LocalGroup,
      PrefetchHooks Function()
    >;
typedef $$GroupMembersTableCreateCompanionBuilder =
    GroupMembersCompanion Function({
      Value<int> id,
      required String waGroupId,
      required String waId,
      Value<String?> name,
      Value<bool> isAdmin,
    });
typedef $$GroupMembersTableUpdateCompanionBuilder =
    GroupMembersCompanion Function({
      Value<int> id,
      Value<String> waGroupId,
      Value<String> waId,
      Value<String?> name,
      Value<bool> isAdmin,
    });

class $$GroupMembersTableFilterComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get waGroupId => $composableBuilder(
    column: $table.waGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get waId => $composableBuilder(
    column: $table.waId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAdmin => $composableBuilder(
    column: $table.isAdmin,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GroupMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waGroupId => $composableBuilder(
    column: $table.waGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waId => $composableBuilder(
    column: $table.waId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAdmin => $composableBuilder(
    column: $table.isAdmin,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get waGroupId =>
      $composableBuilder(column: $table.waGroupId, builder: (column) => column);

  GeneratedColumn<String> get waId =>
      $composableBuilder(column: $table.waId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isAdmin =>
      $composableBuilder(column: $table.isAdmin, builder: (column) => column);
}

class $$GroupMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupMembersTable,
          GroupMember,
          $$GroupMembersTableFilterComposer,
          $$GroupMembersTableOrderingComposer,
          $$GroupMembersTableAnnotationComposer,
          $$GroupMembersTableCreateCompanionBuilder,
          $$GroupMembersTableUpdateCompanionBuilder,
          (
            GroupMember,
            BaseReferences<_$AppDatabase, $GroupMembersTable, GroupMember>,
          ),
          GroupMember,
          PrefetchHooks Function()
        > {
  $$GroupMembersTableTableManager(_$AppDatabase db, $GroupMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> waGroupId = const Value.absent(),
                Value<String> waId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<bool> isAdmin = const Value.absent(),
              }) => GroupMembersCompanion(
                id: id,
                waGroupId: waGroupId,
                waId: waId,
                name: name,
                isAdmin: isAdmin,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String waGroupId,
                required String waId,
                Value<String?> name = const Value.absent(),
                Value<bool> isAdmin = const Value.absent(),
              }) => GroupMembersCompanion.insert(
                id: id,
                waGroupId: waGroupId,
                waId: waId,
                name: name,
                isAdmin: isAdmin,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GroupMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupMembersTable,
      GroupMember,
      $$GroupMembersTableFilterComposer,
      $$GroupMembersTableOrderingComposer,
      $$GroupMembersTableAnnotationComposer,
      $$GroupMembersTableCreateCompanionBuilder,
      $$GroupMembersTableUpdateCompanionBuilder,
      (
        GroupMember,
        BaseReferences<_$AppDatabase, $GroupMembersTable, GroupMember>,
      ),
      GroupMember,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalChatsTableTableManager get localChats =>
      $$LocalChatsTableTableManager(_db, _db.localChats);
  $$LocalMessagesTableTableManager get localMessages =>
      $$LocalMessagesTableTableManager(_db, _db.localMessages);
  $$LocalContactsTableTableManager get localContacts =>
      $$LocalContactsTableTableManager(_db, _db.localContacts);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$OutgoingQueueItemsTableTableManager get outgoingQueueItems =>
      $$OutgoingQueueItemsTableTableManager(_db, _db.outgoingQueueItems);
  $$LocalGroupsTableTableManager get localGroups =>
      $$LocalGroupsTableTableManager(_db, _db.localGroups);
  $$GroupMembersTableTableManager get groupMembers =>
      $$GroupMembersTableTableManager(_db, _db.groupMembers);
}
