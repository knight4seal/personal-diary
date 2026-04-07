// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DiaryEntriesTable extends DiaryEntries
    with TableInfo<$DiaryEntriesTable, DiaryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiaryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entryDateMeta =
      VerificationMeta('entryDate');
  @override
  late final GeneratedColumn<DateTime> entryDate = GeneratedColumn<DateTime>(
      'entry_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contentMeta = VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isVoiceTranscribedMeta =
      VerificationMeta('isVoiceTranscribed');
  @override
  late final GeneratedColumn<bool> isVoiceTranscribed = GeneratedColumn<bool>(
      'is_voice_transcribed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_voice_transcribed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _audioFilePathMeta =
      VerificationMeta('audioFilePath');
  @override
  late final GeneratedColumn<String> audioFilePath = GeneratedColumn<String>(
      'audio_file_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _audioCreatedAtMeta =
      VerificationMeta('audioCreatedAt');
  @override
  late final GeneratedColumn<DateTime> audioCreatedAt =
      GeneratedColumn<DateTime>('audio_created_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastEditedAtMeta =
      VerificationMeta('lastEditedAt');
  @override
  late final GeneratedColumn<DateTime> lastEditedAt =
      GeneratedColumn<DateTime>('last_edited_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        entryDate,
        title,
        content,
        isVoiceTranscribed,
        audioFilePath,
        audioCreatedAt,
        lastEditedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diary_entries';
  @override
  VerificationContext validateIntegrity(Insertable<DiaryEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entry_date')) {
      context.handle(_entryDateMeta,
          entryDate.isAcceptableOrUnknown(data['entry_date']!, _entryDateMeta));
    } else if (isInserting) {
      context.missing(_entryDateMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('is_voice_transcribed')) {
      context.handle(
          _isVoiceTranscribedMeta,
          isVoiceTranscribed.isAcceptableOrUnknown(
              data['is_voice_transcribed']!, _isVoiceTranscribedMeta));
    }
    if (data.containsKey('audio_file_path')) {
      context.handle(
          _audioFilePathMeta,
          audioFilePath.isAcceptableOrUnknown(
              data['audio_file_path']!, _audioFilePathMeta));
    }
    if (data.containsKey('audio_created_at')) {
      context.handle(
          _audioCreatedAtMeta,
          audioCreatedAt.isAcceptableOrUnknown(
              data['audio_created_at']!, _audioCreatedAtMeta));
    }
    if (data.containsKey('last_edited_at')) {
      context.handle(
          _lastEditedAtMeta,
          lastEditedAt.isAcceptableOrUnknown(
              data['last_edited_at']!, _lastEditedAtMeta));
    } else if (isInserting) {
      context.missing(_lastEditedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiaryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiaryEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}entry_date'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      isVoiceTranscribed: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_voice_transcribed'])!,
      audioFilePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}audio_file_path']),
      audioCreatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}audio_created_at']),
      lastEditedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_edited_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DiaryEntriesTable createAlias(String alias) {
    return $DiaryEntriesTable(attachedDatabase, alias);
  }
}

class DiaryEntry extends DataClass implements Insertable<DiaryEntry> {
  final int id;
  final DateTime entryDate;
  final String? title;
  final String content;
  final bool isVoiceTranscribed;
  final String? audioFilePath;
  final DateTime? audioCreatedAt;
  final DateTime lastEditedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DiaryEntry({
    required this.id,
    required this.entryDate,
    this.title,
    required this.content,
    required this.isVoiceTranscribed,
    this.audioFilePath,
    this.audioCreatedAt,
    required this.lastEditedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entry_date'] = Variable<DateTime>(entryDate);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['content'] = Variable<String>(content);
    map['is_voice_transcribed'] = Variable<bool>(isVoiceTranscribed);
    if (!nullToAbsent || audioFilePath != null) {
      map['audio_file_path'] = Variable<String>(audioFilePath);
    }
    if (!nullToAbsent || audioCreatedAt != null) {
      map['audio_created_at'] = Variable<DateTime>(audioCreatedAt);
    }
    map['last_edited_at'] = Variable<DateTime>(lastEditedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DiaryEntriesCompanion toCompanion(bool nullToAbsent) {
    return DiaryEntriesCompanion(
      id: Value(id),
      entryDate: Value(entryDate),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      content: Value(content),
      isVoiceTranscribed: Value(isVoiceTranscribed),
      audioFilePath: audioFilePath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioFilePath),
      audioCreatedAt: audioCreatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(audioCreatedAt),
      lastEditedAt: Value(lastEditedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiaryEntry(
      id: serializer.fromJson<int>(json['id']),
      entryDate: serializer.fromJson<DateTime>(json['entryDate']),
      title: serializer.fromJson<String?>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      isVoiceTranscribed:
          serializer.fromJson<bool>(json['isVoiceTranscribed']),
      audioFilePath: serializer.fromJson<String?>(json['audioFilePath']),
      audioCreatedAt: serializer.fromJson<DateTime?>(json['audioCreatedAt']),
      lastEditedAt: serializer.fromJson<DateTime>(json['lastEditedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entryDate': serializer.toJson<DateTime>(entryDate),
      'title': serializer.toJson<String?>(title),
      'content': serializer.toJson<String>(content),
      'isVoiceTranscribed': serializer.toJson<bool>(isVoiceTranscribed),
      'audioFilePath': serializer.toJson<String?>(audioFilePath),
      'audioCreatedAt': serializer.toJson<DateTime?>(audioCreatedAt),
      'lastEditedAt': serializer.toJson<DateTime>(lastEditedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DiaryEntry copyWith({
    int? id,
    DateTime? entryDate,
    Value<String?> title = const Value.absent(),
    String? content,
    bool? isVoiceTranscribed,
    Value<String?> audioFilePath = const Value.absent(),
    Value<DateTime?> audioCreatedAt = const Value.absent(),
    DateTime? lastEditedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      DiaryEntry(
        id: id ?? this.id,
        entryDate: entryDate ?? this.entryDate,
        title: title.present ? title.value : this.title,
        content: content ?? this.content,
        isVoiceTranscribed: isVoiceTranscribed ?? this.isVoiceTranscribed,
        audioFilePath:
            audioFilePath.present ? audioFilePath.value : this.audioFilePath,
        audioCreatedAt:
            audioCreatedAt.present ? audioCreatedAt.value : this.audioCreatedAt,
        lastEditedAt: lastEditedAt ?? this.lastEditedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  @override
  String toString() {
    return (StringBuffer('DiaryEntry(')
          ..write('id: $id, ')
          ..write('entryDate: $entryDate, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('isVoiceTranscribed: $isVoiceTranscribed, ')
          ..write('audioFilePath: $audioFilePath, ')
          ..write('audioCreatedAt: $audioCreatedAt, ')
          ..write('lastEditedAt: $lastEditedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entryDate, title, content,
      isVoiceTranscribed, audioFilePath, audioCreatedAt, lastEditedAt, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiaryEntry &&
          other.id == this.id &&
          other.entryDate == this.entryDate &&
          other.title == this.title &&
          other.content == this.content &&
          other.isVoiceTranscribed == this.isVoiceTranscribed &&
          other.audioFilePath == this.audioFilePath &&
          other.audioCreatedAt == this.audioCreatedAt &&
          other.lastEditedAt == this.lastEditedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DiaryEntriesCompanion extends UpdateCompanion<DiaryEntry> {
  final Value<int> id;
  final Value<DateTime> entryDate;
  final Value<String?> title;
  final Value<String> content;
  final Value<bool> isVoiceTranscribed;
  final Value<String?> audioFilePath;
  final Value<DateTime?> audioCreatedAt;
  final Value<DateTime> lastEditedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DiaryEntriesCompanion({
    this.id = const Value.absent(),
    this.entryDate = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.isVoiceTranscribed = const Value.absent(),
    this.audioFilePath = const Value.absent(),
    this.audioCreatedAt = const Value.absent(),
    this.lastEditedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DiaryEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime entryDate,
    this.title = const Value.absent(),
    required String content,
    this.isVoiceTranscribed = const Value.absent(),
    this.audioFilePath = const Value.absent(),
    this.audioCreatedAt = const Value.absent(),
    required DateTime lastEditedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : entryDate = Value(entryDate),
        content = Value(content),
        lastEditedAt = Value(lastEditedAt),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<DiaryEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? entryDate,
    Expression<String>? title,
    Expression<String>? content,
    Expression<bool>? isVoiceTranscribed,
    Expression<String>? audioFilePath,
    Expression<DateTime>? audioCreatedAt,
    Expression<DateTime>? lastEditedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryDate != null) 'entry_date': entryDate,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (isVoiceTranscribed != null)
        'is_voice_transcribed': isVoiceTranscribed,
      if (audioFilePath != null) 'audio_file_path': audioFilePath,
      if (audioCreatedAt != null) 'audio_created_at': audioCreatedAt,
      if (lastEditedAt != null) 'last_edited_at': lastEditedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DiaryEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? entryDate,
    Value<String?>? title,
    Value<String>? content,
    Value<bool>? isVoiceTranscribed,
    Value<String?>? audioFilePath,
    Value<DateTime?>? audioCreatedAt,
    Value<DateTime>? lastEditedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return DiaryEntriesCompanion(
      id: id ?? this.id,
      entryDate: entryDate ?? this.entryDate,
      title: title ?? this.title,
      content: content ?? this.content,
      isVoiceTranscribed: isVoiceTranscribed ?? this.isVoiceTranscribed,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      audioCreatedAt: audioCreatedAt ?? this.audioCreatedAt,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entryDate.present) {
      map['entry_date'] = Variable<DateTime>(entryDate.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (isVoiceTranscribed.present) {
      map['is_voice_transcribed'] = Variable<bool>(isVoiceTranscribed.value);
    }
    if (audioFilePath.present) {
      map['audio_file_path'] = Variable<String>(audioFilePath.value);
    }
    if (audioCreatedAt.present) {
      map['audio_created_at'] = Variable<DateTime>(audioCreatedAt.value);
    }
    if (lastEditedAt.present) {
      map['last_edited_at'] = Variable<DateTime>(lastEditedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiaryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('entryDate: $entryDate, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('isVoiceTranscribed: $isVoiceTranscribed, ')
          ..write('audioFilePath: $audioFilePath, ')
          ..write('audioCreatedAt: $audioCreatedAt, ')
          ..write('lastEditedAt: $lastEditedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $DiaryEntriesTable diaryEntries = $DiaryEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [diaryEntries];
}
