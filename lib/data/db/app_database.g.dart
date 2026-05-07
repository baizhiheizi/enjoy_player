// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MediasTable extends Medias with TableInfo<$MediasTable, MediaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceUriMeta = const VerificationMeta(
    'sourceUri',
  );
  @override
  late final GeneratedColumn<String> sourceUri = GeneratedColumn<String>(
    'source_uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('und'),
  );
  static const VerificationMeta _fileHashMeta = const VerificationMeta(
    'fileHash',
  );
  @override
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
    'file_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    kind,
    title,
    sourceUri,
    thumbnailPath,
    durationMs,
    language,
    fileHash,
    fileSize,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('source_uri')) {
      context.handle(
        _sourceUriMeta,
        sourceUri.isAcceptableOrUnknown(data['source_uri']!, _sourceUriMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceUriMeta);
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('file_hash')) {
      context.handle(
        _fileHashMeta,
        fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta),
      );
    } else if (isInserting) {
      context.missing(_fileHashMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
  MediaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      kind:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}kind'],
          )!,
      title:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}title'],
          )!,
      sourceUri:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}source_uri'],
          )!,
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      durationMs:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}duration_ms'],
          )!,
      language:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}language'],
          )!,
      fileHash:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}file_hash'],
          )!,
      fileSize:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}file_size'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $MediasTable createAlias(String alias) {
    return $MediasTable(attachedDatabase, alias);
  }
}

class MediaRow extends DataClass implements Insertable<MediaRow> {
  final String id;
  final String kind;
  final String title;
  final String sourceUri;
  final String? thumbnailPath;
  final int durationMs;
  final String language;
  final String fileHash;
  final int fileSize;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MediaRow({
    required this.id,
    required this.kind,
    required this.title,
    required this.sourceUri,
    this.thumbnailPath,
    required this.durationMs,
    required this.language,
    required this.fileHash,
    required this.fileSize,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['title'] = Variable<String>(title);
    map['source_uri'] = Variable<String>(sourceUri);
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    map['language'] = Variable<String>(language);
    map['file_hash'] = Variable<String>(fileHash);
    map['file_size'] = Variable<int>(fileSize);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MediasCompanion toCompanion(bool nullToAbsent) {
    return MediasCompanion(
      id: Value(id),
      kind: Value(kind),
      title: Value(title),
      sourceUri: Value(sourceUri),
      thumbnailPath:
          thumbnailPath == null && nullToAbsent
              ? const Value.absent()
              : Value(thumbnailPath),
      durationMs: Value(durationMs),
      language: Value(language),
      fileHash: Value(fileHash),
      fileSize: Value(fileSize),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MediaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaRow(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      title: serializer.fromJson<String>(json['title']),
      sourceUri: serializer.fromJson<String>(json['sourceUri']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      language: serializer.fromJson<String>(json['language']),
      fileHash: serializer.fromJson<String>(json['fileHash']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'title': serializer.toJson<String>(title),
      'sourceUri': serializer.toJson<String>(sourceUri),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'durationMs': serializer.toJson<int>(durationMs),
      'language': serializer.toJson<String>(language),
      'fileHash': serializer.toJson<String>(fileHash),
      'fileSize': serializer.toJson<int>(fileSize),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MediaRow copyWith({
    String? id,
    String? kind,
    String? title,
    String? sourceUri,
    Value<String?> thumbnailPath = const Value.absent(),
    int? durationMs,
    String? language,
    String? fileHash,
    int? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MediaRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    sourceUri: sourceUri ?? this.sourceUri,
    thumbnailPath:
        thumbnailPath.present ? thumbnailPath.value : this.thumbnailPath,
    durationMs: durationMs ?? this.durationMs,
    language: language ?? this.language,
    fileHash: fileHash ?? this.fileHash,
    fileSize: fileSize ?? this.fileSize,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MediaRow copyWithCompanion(MediasCompanion data) {
    return MediaRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      sourceUri: data.sourceUri.present ? data.sourceUri.value : this.sourceUri,
      thumbnailPath:
          data.thumbnailPath.present
              ? data.thumbnailPath.value
              : this.thumbnailPath,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      language: data.language.present ? data.language.value : this.language,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('durationMs: $durationMs, ')
          ..write('language: $language, ')
          ..write('fileHash: $fileHash, ')
          ..write('fileSize: $fileSize, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    title,
    sourceUri,
    thumbnailPath,
    durationMs,
    language,
    fileHash,
    fileSize,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.sourceUri == this.sourceUri &&
          other.thumbnailPath == this.thumbnailPath &&
          other.durationMs == this.durationMs &&
          other.language == this.language &&
          other.fileHash == this.fileHash &&
          other.fileSize == this.fileSize &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MediasCompanion extends UpdateCompanion<MediaRow> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> title;
  final Value<String> sourceUri;
  final Value<String?> thumbnailPath;
  final Value<int> durationMs;
  final Value<String> language;
  final Value<String> fileHash;
  final Value<int> fileSize;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MediasCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.sourceUri = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.language = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediasCompanion.insert({
    required String id,
    required String kind,
    required String title,
    required String sourceUri,
    this.thumbnailPath = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.language = const Value.absent(),
    required String fileHash,
    required int fileSize,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       title = Value(title),
       sourceUri = Value(sourceUri),
       fileHash = Value(fileHash),
       fileSize = Value(fileSize),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MediaRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<String>? sourceUri,
    Expression<String>? thumbnailPath,
    Expression<int>? durationMs,
    Expression<String>? language,
    Expression<String>? fileHash,
    Expression<int>? fileSize,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (sourceUri != null) 'source_uri': sourceUri,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (durationMs != null) 'duration_ms': durationMs,
      if (language != null) 'language': language,
      if (fileHash != null) 'file_hash': fileHash,
      if (fileSize != null) 'file_size': fileSize,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediasCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? title,
    Value<String>? sourceUri,
    Value<String?>? thumbnailPath,
    Value<int>? durationMs,
    Value<String>? language,
    Value<String>? fileHash,
    Value<int>? fileSize,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MediasCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      sourceUri: sourceUri ?? this.sourceUri,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      durationMs: durationMs ?? this.durationMs,
      language: language ?? this.language,
      fileHash: fileHash ?? this.fileHash,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sourceUri.present) {
      map['source_uri'] = Variable<String>(sourceUri.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediasCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('durationMs: $durationMs, ')
          ..write('language: $language, ')
          ..write('fileHash: $fileHash, ')
          ..write('fileSize: $fileSize, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TranscriptsTable extends Transcripts
    with TableInfo<$TranscriptsTable, TranscriptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranscriptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _linesJsonMeta = const VerificationMeta(
    'linesJson',
  );
  @override
  late final GeneratedColumn<String> linesJson = GeneratedColumn<String>(
    'lines_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _trackIndexMeta = const VerificationMeta(
    'trackIndex',
  );
  @override
  late final GeneratedColumn<int> trackIndex = GeneratedColumn<int>(
    'track_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEmbeddedMeta = const VerificationMeta(
    'isEmbedded',
  );
  @override
  late final GeneratedColumn<bool> isEmbedded = GeneratedColumn<bool>(
    'is_embedded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_embedded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    mediaId,
    language,
    source,
    linesJson,
    label,
    trackIndex,
    isEmbedded,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transcripts';
  @override
  VerificationContext validateIntegrity(
    Insertable<TranscriptRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('lines_json')) {
      context.handle(
        _linesJsonMeta,
        linesJson.isAcceptableOrUnknown(data['lines_json']!, _linesJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_linesJsonMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('track_index')) {
      context.handle(
        _trackIndexMeta,
        trackIndex.isAcceptableOrUnknown(data['track_index']!, _trackIndexMeta),
      );
    }
    if (data.containsKey('is_embedded')) {
      context.handle(
        _isEmbeddedMeta,
        isEmbedded.isAcceptableOrUnknown(data['is_embedded']!, _isEmbeddedMeta),
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
  TranscriptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TranscriptRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      mediaId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}media_id'],
          )!,
      language:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}language'],
          )!,
      source:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}source'],
          )!,
      linesJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}lines_json'],
          )!,
      label:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}label'],
          )!,
      trackIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_index'],
      ),
      isEmbedded:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_embedded'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $TranscriptsTable createAlias(String alias) {
    return $TranscriptsTable(attachedDatabase, alias);
  }
}

class TranscriptRow extends DataClass implements Insertable<TranscriptRow> {
  final String id;
  final String mediaId;
  final String language;
  final String source;
  final String linesJson;

  /// Human-readable label shown in the track picker (filename, stream title, etc.).
  final String label;

  /// For embedded tracks: the 0-based index in the container's subtitle stream list.
  final int? trackIndex;

  /// 1 if extracted from the media file itself, 0 if user-imported an external file.
  final bool isEmbedded;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TranscriptRow({
    required this.id,
    required this.mediaId,
    required this.language,
    required this.source,
    required this.linesJson,
    required this.label,
    this.trackIndex,
    required this.isEmbedded,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['media_id'] = Variable<String>(mediaId);
    map['language'] = Variable<String>(language);
    map['source'] = Variable<String>(source);
    map['lines_json'] = Variable<String>(linesJson);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || trackIndex != null) {
      map['track_index'] = Variable<int>(trackIndex);
    }
    map['is_embedded'] = Variable<bool>(isEmbedded);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TranscriptsCompanion toCompanion(bool nullToAbsent) {
    return TranscriptsCompanion(
      id: Value(id),
      mediaId: Value(mediaId),
      language: Value(language),
      source: Value(source),
      linesJson: Value(linesJson),
      label: Value(label),
      trackIndex:
          trackIndex == null && nullToAbsent
              ? const Value.absent()
              : Value(trackIndex),
      isEmbedded: Value(isEmbedded),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TranscriptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TranscriptRow(
      id: serializer.fromJson<String>(json['id']),
      mediaId: serializer.fromJson<String>(json['mediaId']),
      language: serializer.fromJson<String>(json['language']),
      source: serializer.fromJson<String>(json['source']),
      linesJson: serializer.fromJson<String>(json['linesJson']),
      label: serializer.fromJson<String>(json['label']),
      trackIndex: serializer.fromJson<int?>(json['trackIndex']),
      isEmbedded: serializer.fromJson<bool>(json['isEmbedded']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mediaId': serializer.toJson<String>(mediaId),
      'language': serializer.toJson<String>(language),
      'source': serializer.toJson<String>(source),
      'linesJson': serializer.toJson<String>(linesJson),
      'label': serializer.toJson<String>(label),
      'trackIndex': serializer.toJson<int?>(trackIndex),
      'isEmbedded': serializer.toJson<bool>(isEmbedded),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TranscriptRow copyWith({
    String? id,
    String? mediaId,
    String? language,
    String? source,
    String? linesJson,
    String? label,
    Value<int?> trackIndex = const Value.absent(),
    bool? isEmbedded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TranscriptRow(
    id: id ?? this.id,
    mediaId: mediaId ?? this.mediaId,
    language: language ?? this.language,
    source: source ?? this.source,
    linesJson: linesJson ?? this.linesJson,
    label: label ?? this.label,
    trackIndex: trackIndex.present ? trackIndex.value : this.trackIndex,
    isEmbedded: isEmbedded ?? this.isEmbedded,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TranscriptRow copyWithCompanion(TranscriptsCompanion data) {
    return TranscriptRow(
      id: data.id.present ? data.id.value : this.id,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      language: data.language.present ? data.language.value : this.language,
      source: data.source.present ? data.source.value : this.source,
      linesJson: data.linesJson.present ? data.linesJson.value : this.linesJson,
      label: data.label.present ? data.label.value : this.label,
      trackIndex:
          data.trackIndex.present ? data.trackIndex.value : this.trackIndex,
      isEmbedded:
          data.isEmbedded.present ? data.isEmbedded.value : this.isEmbedded,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TranscriptRow(')
          ..write('id: $id, ')
          ..write('mediaId: $mediaId, ')
          ..write('language: $language, ')
          ..write('source: $source, ')
          ..write('linesJson: $linesJson, ')
          ..write('label: $label, ')
          ..write('trackIndex: $trackIndex, ')
          ..write('isEmbedded: $isEmbedded, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mediaId,
    language,
    source,
    linesJson,
    label,
    trackIndex,
    isEmbedded,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TranscriptRow &&
          other.id == this.id &&
          other.mediaId == this.mediaId &&
          other.language == this.language &&
          other.source == this.source &&
          other.linesJson == this.linesJson &&
          other.label == this.label &&
          other.trackIndex == this.trackIndex &&
          other.isEmbedded == this.isEmbedded &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TranscriptsCompanion extends UpdateCompanion<TranscriptRow> {
  final Value<String> id;
  final Value<String> mediaId;
  final Value<String> language;
  final Value<String> source;
  final Value<String> linesJson;
  final Value<String> label;
  final Value<int?> trackIndex;
  final Value<bool> isEmbedded;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TranscriptsCompanion({
    this.id = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.language = const Value.absent(),
    this.source = const Value.absent(),
    this.linesJson = const Value.absent(),
    this.label = const Value.absent(),
    this.trackIndex = const Value.absent(),
    this.isEmbedded = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TranscriptsCompanion.insert({
    required String id,
    required String mediaId,
    required String language,
    required String source,
    required String linesJson,
    this.label = const Value.absent(),
    this.trackIndex = const Value.absent(),
    this.isEmbedded = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mediaId = Value(mediaId),
       language = Value(language),
       source = Value(source),
       linesJson = Value(linesJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TranscriptRow> custom({
    Expression<String>? id,
    Expression<String>? mediaId,
    Expression<String>? language,
    Expression<String>? source,
    Expression<String>? linesJson,
    Expression<String>? label,
    Expression<int>? trackIndex,
    Expression<bool>? isEmbedded,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mediaId != null) 'media_id': mediaId,
      if (language != null) 'language': language,
      if (source != null) 'source': source,
      if (linesJson != null) 'lines_json': linesJson,
      if (label != null) 'label': label,
      if (trackIndex != null) 'track_index': trackIndex,
      if (isEmbedded != null) 'is_embedded': isEmbedded,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TranscriptsCompanion copyWith({
    Value<String>? id,
    Value<String>? mediaId,
    Value<String>? language,
    Value<String>? source,
    Value<String>? linesJson,
    Value<String>? label,
    Value<int?>? trackIndex,
    Value<bool>? isEmbedded,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TranscriptsCompanion(
      id: id ?? this.id,
      mediaId: mediaId ?? this.mediaId,
      language: language ?? this.language,
      source: source ?? this.source,
      linesJson: linesJson ?? this.linesJson,
      label: label ?? this.label,
      trackIndex: trackIndex ?? this.trackIndex,
      isEmbedded: isEmbedded ?? this.isEmbedded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (linesJson.present) {
      map['lines_json'] = Variable<String>(linesJson.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (trackIndex.present) {
      map['track_index'] = Variable<int>(trackIndex.value);
    }
    if (isEmbedded.present) {
      map['is_embedded'] = Variable<bool>(isEmbedded.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranscriptsCompanion(')
          ..write('id: $id, ')
          ..write('mediaId: $mediaId, ')
          ..write('language: $language, ')
          ..write('source: $source, ')
          ..write('linesJson: $linesJson, ')
          ..write('label: $label, ')
          ..write('trackIndex: $trackIndex, ')
          ..write('isEmbedded: $isEmbedded, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaybackSessionsTable extends PlaybackSessions
    with TableInfo<$PlaybackSessionsTable, PlaybackSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentSegmentIndexMeta =
      const VerificationMeta('currentSegmentIndex');
  @override
  late final GeneratedColumn<int> currentSegmentIndex = GeneratedColumn<int>(
    'current_segment_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  static const VerificationMeta _echoActiveMeta = const VerificationMeta(
    'echoActive',
  );
  @override
  late final GeneratedColumn<bool> echoActive = GeneratedColumn<bool>(
    'echo_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("echo_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _echoStartLineMeta = const VerificationMeta(
    'echoStartLine',
  );
  @override
  late final GeneratedColumn<int> echoStartLine = GeneratedColumn<int>(
    'echo_start_line',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  static const VerificationMeta _echoEndLineMeta = const VerificationMeta(
    'echoEndLine',
  );
  @override
  late final GeneratedColumn<int> echoEndLine = GeneratedColumn<int>(
    'echo_end_line',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  static const VerificationMeta _echoStartMsMeta = const VerificationMeta(
    'echoStartMs',
  );
  @override
  late final GeneratedColumn<int> echoStartMs = GeneratedColumn<int>(
    'echo_start_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  static const VerificationMeta _echoEndMsMeta = const VerificationMeta(
    'echoEndMs',
  );
  @override
  late final GeneratedColumn<int> echoEndMs = GeneratedColumn<int>(
    'echo_end_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  static const VerificationMeta _primaryTranscriptIdMeta =
      const VerificationMeta('primaryTranscriptId');
  @override
  late final GeneratedColumn<String> primaryTranscriptId =
      GeneratedColumn<String>(
        'primary_transcript_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _secondaryTranscriptIdMeta =
      const VerificationMeta('secondaryTranscriptId');
  @override
  late final GeneratedColumn<String> secondaryTranscriptId =
      GeneratedColumn<String>(
        'secondary_transcript_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastActiveAtMeta = const VerificationMeta(
    'lastActiveAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastActiveAt = GeneratedColumn<DateTime>(
    'last_active_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    mediaId,
    positionMs,
    currentSegmentIndex,
    echoActive,
    echoStartLine,
    echoEndLine,
    echoStartMs,
    echoEndMs,
    primaryTranscriptId,
    secondaryTranscriptId,
    lastActiveAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaybackSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    }
    if (data.containsKey('current_segment_index')) {
      context.handle(
        _currentSegmentIndexMeta,
        currentSegmentIndex.isAcceptableOrUnknown(
          data['current_segment_index']!,
          _currentSegmentIndexMeta,
        ),
      );
    }
    if (data.containsKey('echo_active')) {
      context.handle(
        _echoActiveMeta,
        echoActive.isAcceptableOrUnknown(data['echo_active']!, _echoActiveMeta),
      );
    }
    if (data.containsKey('echo_start_line')) {
      context.handle(
        _echoStartLineMeta,
        echoStartLine.isAcceptableOrUnknown(
          data['echo_start_line']!,
          _echoStartLineMeta,
        ),
      );
    }
    if (data.containsKey('echo_end_line')) {
      context.handle(
        _echoEndLineMeta,
        echoEndLine.isAcceptableOrUnknown(
          data['echo_end_line']!,
          _echoEndLineMeta,
        ),
      );
    }
    if (data.containsKey('echo_start_ms')) {
      context.handle(
        _echoStartMsMeta,
        echoStartMs.isAcceptableOrUnknown(
          data['echo_start_ms']!,
          _echoStartMsMeta,
        ),
      );
    }
    if (data.containsKey('echo_end_ms')) {
      context.handle(
        _echoEndMsMeta,
        echoEndMs.isAcceptableOrUnknown(data['echo_end_ms']!, _echoEndMsMeta),
      );
    }
    if (data.containsKey('primary_transcript_id')) {
      context.handle(
        _primaryTranscriptIdMeta,
        primaryTranscriptId.isAcceptableOrUnknown(
          data['primary_transcript_id']!,
          _primaryTranscriptIdMeta,
        ),
      );
    }
    if (data.containsKey('secondary_transcript_id')) {
      context.handle(
        _secondaryTranscriptIdMeta,
        secondaryTranscriptId.isAcceptableOrUnknown(
          data['secondary_transcript_id']!,
          _secondaryTranscriptIdMeta,
        ),
      );
    }
    if (data.containsKey('last_active_at')) {
      context.handle(
        _lastActiveAtMeta,
        lastActiveAt.isAcceptableOrUnknown(
          data['last_active_at']!,
          _lastActiveAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastActiveAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mediaId};
  @override
  PlaybackSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackSessionRow(
      mediaId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}media_id'],
          )!,
      positionMs:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}position_ms'],
          )!,
      currentSegmentIndex:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}current_segment_index'],
          )!,
      echoActive:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}echo_active'],
          )!,
      echoStartLine:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}echo_start_line'],
          )!,
      echoEndLine:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}echo_end_line'],
          )!,
      echoStartMs:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}echo_start_ms'],
          )!,
      echoEndMs:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}echo_end_ms'],
          )!,
      primaryTranscriptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_transcript_id'],
      ),
      secondaryTranscriptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secondary_transcript_id'],
      ),
      lastActiveAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}last_active_at'],
          )!,
    );
  }

  @override
  $PlaybackSessionsTable createAlias(String alias) {
    return $PlaybackSessionsTable(attachedDatabase, alias);
  }
}

class PlaybackSessionRow extends DataClass
    implements Insertable<PlaybackSessionRow> {
  final String mediaId;
  final int positionMs;
  final int currentSegmentIndex;
  final bool echoActive;
  final int echoStartLine;
  final int echoEndLine;
  final int echoStartMs;
  final int echoEndMs;

  /// The transcript row id currently selected as primary (shadow-reading) track.
  final String? primaryTranscriptId;

  /// The transcript row id currently selected as secondary (translation) track.
  final String? secondaryTranscriptId;
  final DateTime lastActiveAt;
  const PlaybackSessionRow({
    required this.mediaId,
    required this.positionMs,
    required this.currentSegmentIndex,
    required this.echoActive,
    required this.echoStartLine,
    required this.echoEndLine,
    required this.echoStartMs,
    required this.echoEndMs,
    this.primaryTranscriptId,
    this.secondaryTranscriptId,
    required this.lastActiveAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['media_id'] = Variable<String>(mediaId);
    map['position_ms'] = Variable<int>(positionMs);
    map['current_segment_index'] = Variable<int>(currentSegmentIndex);
    map['echo_active'] = Variable<bool>(echoActive);
    map['echo_start_line'] = Variable<int>(echoStartLine);
    map['echo_end_line'] = Variable<int>(echoEndLine);
    map['echo_start_ms'] = Variable<int>(echoStartMs);
    map['echo_end_ms'] = Variable<int>(echoEndMs);
    if (!nullToAbsent || primaryTranscriptId != null) {
      map['primary_transcript_id'] = Variable<String>(primaryTranscriptId);
    }
    if (!nullToAbsent || secondaryTranscriptId != null) {
      map['secondary_transcript_id'] = Variable<String>(secondaryTranscriptId);
    }
    map['last_active_at'] = Variable<DateTime>(lastActiveAt);
    return map;
  }

  PlaybackSessionsCompanion toCompanion(bool nullToAbsent) {
    return PlaybackSessionsCompanion(
      mediaId: Value(mediaId),
      positionMs: Value(positionMs),
      currentSegmentIndex: Value(currentSegmentIndex),
      echoActive: Value(echoActive),
      echoStartLine: Value(echoStartLine),
      echoEndLine: Value(echoEndLine),
      echoStartMs: Value(echoStartMs),
      echoEndMs: Value(echoEndMs),
      primaryTranscriptId:
          primaryTranscriptId == null && nullToAbsent
              ? const Value.absent()
              : Value(primaryTranscriptId),
      secondaryTranscriptId:
          secondaryTranscriptId == null && nullToAbsent
              ? const Value.absent()
              : Value(secondaryTranscriptId),
      lastActiveAt: Value(lastActiveAt),
    );
  }

  factory PlaybackSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackSessionRow(
      mediaId: serializer.fromJson<String>(json['mediaId']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      currentSegmentIndex: serializer.fromJson<int>(
        json['currentSegmentIndex'],
      ),
      echoActive: serializer.fromJson<bool>(json['echoActive']),
      echoStartLine: serializer.fromJson<int>(json['echoStartLine']),
      echoEndLine: serializer.fromJson<int>(json['echoEndLine']),
      echoStartMs: serializer.fromJson<int>(json['echoStartMs']),
      echoEndMs: serializer.fromJson<int>(json['echoEndMs']),
      primaryTranscriptId: serializer.fromJson<String?>(
        json['primaryTranscriptId'],
      ),
      secondaryTranscriptId: serializer.fromJson<String?>(
        json['secondaryTranscriptId'],
      ),
      lastActiveAt: serializer.fromJson<DateTime>(json['lastActiveAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaId': serializer.toJson<String>(mediaId),
      'positionMs': serializer.toJson<int>(positionMs),
      'currentSegmentIndex': serializer.toJson<int>(currentSegmentIndex),
      'echoActive': serializer.toJson<bool>(echoActive),
      'echoStartLine': serializer.toJson<int>(echoStartLine),
      'echoEndLine': serializer.toJson<int>(echoEndLine),
      'echoStartMs': serializer.toJson<int>(echoStartMs),
      'echoEndMs': serializer.toJson<int>(echoEndMs),
      'primaryTranscriptId': serializer.toJson<String?>(primaryTranscriptId),
      'secondaryTranscriptId': serializer.toJson<String?>(
        secondaryTranscriptId,
      ),
      'lastActiveAt': serializer.toJson<DateTime>(lastActiveAt),
    };
  }

  PlaybackSessionRow copyWith({
    String? mediaId,
    int? positionMs,
    int? currentSegmentIndex,
    bool? echoActive,
    int? echoStartLine,
    int? echoEndLine,
    int? echoStartMs,
    int? echoEndMs,
    Value<String?> primaryTranscriptId = const Value.absent(),
    Value<String?> secondaryTranscriptId = const Value.absent(),
    DateTime? lastActiveAt,
  }) => PlaybackSessionRow(
    mediaId: mediaId ?? this.mediaId,
    positionMs: positionMs ?? this.positionMs,
    currentSegmentIndex: currentSegmentIndex ?? this.currentSegmentIndex,
    echoActive: echoActive ?? this.echoActive,
    echoStartLine: echoStartLine ?? this.echoStartLine,
    echoEndLine: echoEndLine ?? this.echoEndLine,
    echoStartMs: echoStartMs ?? this.echoStartMs,
    echoEndMs: echoEndMs ?? this.echoEndMs,
    primaryTranscriptId:
        primaryTranscriptId.present
            ? primaryTranscriptId.value
            : this.primaryTranscriptId,
    secondaryTranscriptId:
        secondaryTranscriptId.present
            ? secondaryTranscriptId.value
            : this.secondaryTranscriptId,
    lastActiveAt: lastActiveAt ?? this.lastActiveAt,
  );
  PlaybackSessionRow copyWithCompanion(PlaybackSessionsCompanion data) {
    return PlaybackSessionRow(
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      positionMs:
          data.positionMs.present ? data.positionMs.value : this.positionMs,
      currentSegmentIndex:
          data.currentSegmentIndex.present
              ? data.currentSegmentIndex.value
              : this.currentSegmentIndex,
      echoActive:
          data.echoActive.present ? data.echoActive.value : this.echoActive,
      echoStartLine:
          data.echoStartLine.present
              ? data.echoStartLine.value
              : this.echoStartLine,
      echoEndLine:
          data.echoEndLine.present ? data.echoEndLine.value : this.echoEndLine,
      echoStartMs:
          data.echoStartMs.present ? data.echoStartMs.value : this.echoStartMs,
      echoEndMs: data.echoEndMs.present ? data.echoEndMs.value : this.echoEndMs,
      primaryTranscriptId:
          data.primaryTranscriptId.present
              ? data.primaryTranscriptId.value
              : this.primaryTranscriptId,
      secondaryTranscriptId:
          data.secondaryTranscriptId.present
              ? data.secondaryTranscriptId.value
              : this.secondaryTranscriptId,
      lastActiveAt:
          data.lastActiveAt.present
              ? data.lastActiveAt.value
              : this.lastActiveAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackSessionRow(')
          ..write('mediaId: $mediaId, ')
          ..write('positionMs: $positionMs, ')
          ..write('currentSegmentIndex: $currentSegmentIndex, ')
          ..write('echoActive: $echoActive, ')
          ..write('echoStartLine: $echoStartLine, ')
          ..write('echoEndLine: $echoEndLine, ')
          ..write('echoStartMs: $echoStartMs, ')
          ..write('echoEndMs: $echoEndMs, ')
          ..write('primaryTranscriptId: $primaryTranscriptId, ')
          ..write('secondaryTranscriptId: $secondaryTranscriptId, ')
          ..write('lastActiveAt: $lastActiveAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    mediaId,
    positionMs,
    currentSegmentIndex,
    echoActive,
    echoStartLine,
    echoEndLine,
    echoStartMs,
    echoEndMs,
    primaryTranscriptId,
    secondaryTranscriptId,
    lastActiveAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackSessionRow &&
          other.mediaId == this.mediaId &&
          other.positionMs == this.positionMs &&
          other.currentSegmentIndex == this.currentSegmentIndex &&
          other.echoActive == this.echoActive &&
          other.echoStartLine == this.echoStartLine &&
          other.echoEndLine == this.echoEndLine &&
          other.echoStartMs == this.echoStartMs &&
          other.echoEndMs == this.echoEndMs &&
          other.primaryTranscriptId == this.primaryTranscriptId &&
          other.secondaryTranscriptId == this.secondaryTranscriptId &&
          other.lastActiveAt == this.lastActiveAt);
}

class PlaybackSessionsCompanion extends UpdateCompanion<PlaybackSessionRow> {
  final Value<String> mediaId;
  final Value<int> positionMs;
  final Value<int> currentSegmentIndex;
  final Value<bool> echoActive;
  final Value<int> echoStartLine;
  final Value<int> echoEndLine;
  final Value<int> echoStartMs;
  final Value<int> echoEndMs;
  final Value<String?> primaryTranscriptId;
  final Value<String?> secondaryTranscriptId;
  final Value<DateTime> lastActiveAt;
  final Value<int> rowid;
  const PlaybackSessionsCompanion({
    this.mediaId = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.currentSegmentIndex = const Value.absent(),
    this.echoActive = const Value.absent(),
    this.echoStartLine = const Value.absent(),
    this.echoEndLine = const Value.absent(),
    this.echoStartMs = const Value.absent(),
    this.echoEndMs = const Value.absent(),
    this.primaryTranscriptId = const Value.absent(),
    this.secondaryTranscriptId = const Value.absent(),
    this.lastActiveAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaybackSessionsCompanion.insert({
    required String mediaId,
    this.positionMs = const Value.absent(),
    this.currentSegmentIndex = const Value.absent(),
    this.echoActive = const Value.absent(),
    this.echoStartLine = const Value.absent(),
    this.echoEndLine = const Value.absent(),
    this.echoStartMs = const Value.absent(),
    this.echoEndMs = const Value.absent(),
    this.primaryTranscriptId = const Value.absent(),
    this.secondaryTranscriptId = const Value.absent(),
    required DateTime lastActiveAt,
    this.rowid = const Value.absent(),
  }) : mediaId = Value(mediaId),
       lastActiveAt = Value(lastActiveAt);
  static Insertable<PlaybackSessionRow> custom({
    Expression<String>? mediaId,
    Expression<int>? positionMs,
    Expression<int>? currentSegmentIndex,
    Expression<bool>? echoActive,
    Expression<int>? echoStartLine,
    Expression<int>? echoEndLine,
    Expression<int>? echoStartMs,
    Expression<int>? echoEndMs,
    Expression<String>? primaryTranscriptId,
    Expression<String>? secondaryTranscriptId,
    Expression<DateTime>? lastActiveAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mediaId != null) 'media_id': mediaId,
      if (positionMs != null) 'position_ms': positionMs,
      if (currentSegmentIndex != null)
        'current_segment_index': currentSegmentIndex,
      if (echoActive != null) 'echo_active': echoActive,
      if (echoStartLine != null) 'echo_start_line': echoStartLine,
      if (echoEndLine != null) 'echo_end_line': echoEndLine,
      if (echoStartMs != null) 'echo_start_ms': echoStartMs,
      if (echoEndMs != null) 'echo_end_ms': echoEndMs,
      if (primaryTranscriptId != null)
        'primary_transcript_id': primaryTranscriptId,
      if (secondaryTranscriptId != null)
        'secondary_transcript_id': secondaryTranscriptId,
      if (lastActiveAt != null) 'last_active_at': lastActiveAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaybackSessionsCompanion copyWith({
    Value<String>? mediaId,
    Value<int>? positionMs,
    Value<int>? currentSegmentIndex,
    Value<bool>? echoActive,
    Value<int>? echoStartLine,
    Value<int>? echoEndLine,
    Value<int>? echoStartMs,
    Value<int>? echoEndMs,
    Value<String?>? primaryTranscriptId,
    Value<String?>? secondaryTranscriptId,
    Value<DateTime>? lastActiveAt,
    Value<int>? rowid,
  }) {
    return PlaybackSessionsCompanion(
      mediaId: mediaId ?? this.mediaId,
      positionMs: positionMs ?? this.positionMs,
      currentSegmentIndex: currentSegmentIndex ?? this.currentSegmentIndex,
      echoActive: echoActive ?? this.echoActive,
      echoStartLine: echoStartLine ?? this.echoStartLine,
      echoEndLine: echoEndLine ?? this.echoEndLine,
      echoStartMs: echoStartMs ?? this.echoStartMs,
      echoEndMs: echoEndMs ?? this.echoEndMs,
      primaryTranscriptId: primaryTranscriptId ?? this.primaryTranscriptId,
      secondaryTranscriptId:
          secondaryTranscriptId ?? this.secondaryTranscriptId,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (currentSegmentIndex.present) {
      map['current_segment_index'] = Variable<int>(currentSegmentIndex.value);
    }
    if (echoActive.present) {
      map['echo_active'] = Variable<bool>(echoActive.value);
    }
    if (echoStartLine.present) {
      map['echo_start_line'] = Variable<int>(echoStartLine.value);
    }
    if (echoEndLine.present) {
      map['echo_end_line'] = Variable<int>(echoEndLine.value);
    }
    if (echoStartMs.present) {
      map['echo_start_ms'] = Variable<int>(echoStartMs.value);
    }
    if (echoEndMs.present) {
      map['echo_end_ms'] = Variable<int>(echoEndMs.value);
    }
    if (primaryTranscriptId.present) {
      map['primary_transcript_id'] = Variable<String>(
        primaryTranscriptId.value,
      );
    }
    if (secondaryTranscriptId.present) {
      map['secondary_transcript_id'] = Variable<String>(
        secondaryTranscriptId.value,
      );
    }
    if (lastActiveAt.present) {
      map['last_active_at'] = Variable<DateTime>(lastActiveAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackSessionsCompanion(')
          ..write('mediaId: $mediaId, ')
          ..write('positionMs: $positionMs, ')
          ..write('currentSegmentIndex: $currentSegmentIndex, ')
          ..write('echoActive: $echoActive, ')
          ..write('echoStartLine: $echoStartLine, ')
          ..write('echoEndLine: $echoEndLine, ')
          ..write('echoStartMs: $echoStartMs, ')
          ..write('echoEndMs: $echoEndMs, ')
          ..write('primaryTranscriptId: $primaryTranscriptId, ')
          ..write('secondaryTranscriptId: $secondaryTranscriptId, ')
          ..write('lastActiveAt: $lastActiveAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsKvTable extends SettingsKv
    with TableInfo<$SettingsKvTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsKvTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
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
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}key'],
          )!,
      value:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}value'],
          )!,
    );
  }

  @override
  $SettingsKvTable createAlias(String alias) {
    return $SettingsKvTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsKvCompanion toCompanion(bool nullToAbsent) {
    return SettingsKvCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
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

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsKvCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
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
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsKvCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsKvCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsKvCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
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

  SettingsKvCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsKvCompanion(
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
    return (StringBuffer('SettingsKvCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MediasTable medias = $MediasTable(this);
  late final $TranscriptsTable transcripts = $TranscriptsTable(this);
  late final $PlaybackSessionsTable playbackSessions = $PlaybackSessionsTable(
    this,
  );
  late final $SettingsKvTable settingsKv = $SettingsKvTable(this);
  late final MediaDao mediaDao = MediaDao(this as AppDatabase);
  late final TranscriptDao transcriptDao = TranscriptDao(this as AppDatabase);
  late final SessionDao sessionDao = SessionDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    medias,
    transcripts,
    playbackSessions,
    settingsKv,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'media',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transcripts', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'media',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playback_sessions', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$MediasTableCreateCompanionBuilder =
    MediasCompanion Function({
      required String id,
      required String kind,
      required String title,
      required String sourceUri,
      Value<String?> thumbnailPath,
      Value<int> durationMs,
      Value<String> language,
      required String fileHash,
      required int fileSize,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MediasTableUpdateCompanionBuilder =
    MediasCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String> title,
      Value<String> sourceUri,
      Value<String?> thumbnailPath,
      Value<int> durationMs,
      Value<String> language,
      Value<String> fileHash,
      Value<int> fileSize,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$MediasTableReferences
    extends BaseReferences<_$AppDatabase, $MediasTable, MediaRow> {
  $$MediasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TranscriptsTable, List<TranscriptRow>>
  _transcriptsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transcripts,
    aliasName: $_aliasNameGenerator(db.medias.id, db.transcripts.mediaId),
  );

  $$TranscriptsTableProcessedTableManager get transcriptsRefs {
    final manager = $$TranscriptsTableTableManager(
      $_db,
      $_db.transcripts,
    ).filter((f) => f.mediaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transcriptsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlaybackSessionsTable, List<PlaybackSessionRow>>
  _playbackSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.playbackSessions,
    aliasName: $_aliasNameGenerator(db.medias.id, db.playbackSessions.mediaId),
  );

  $$PlaybackSessionsTableProcessedTableManager get playbackSessionsRefs {
    final manager = $$PlaybackSessionsTableTableManager(
      $_db,
      $_db.playbackSessions,
    ).filter((f) => f.mediaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playbackSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MediasTableFilterComposer
    extends Composer<_$AppDatabase, $MediasTable> {
  $$MediasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUri => $composableBuilder(
    column: $table.sourceUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transcriptsRefs(
    Expression<bool> Function($$TranscriptsTableFilterComposer f) f,
  ) {
    final $$TranscriptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transcripts,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TranscriptsTableFilterComposer(
            $db: $db,
            $table: $db.transcripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playbackSessionsRefs(
    Expression<bool> Function($$PlaybackSessionsTableFilterComposer f) f,
  ) {
    final $$PlaybackSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackSessions,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaybackSessionsTableFilterComposer(
            $db: $db,
            $table: $db.playbackSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MediasTableOrderingComposer
    extends Composer<_$AppDatabase, $MediasTable> {
  $$MediasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUri => $composableBuilder(
    column: $table.sourceUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediasTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediasTable> {
  $$MediasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get sourceUri =>
      $composableBuilder(column: $table.sourceUri, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get fileHash =>
      $composableBuilder(column: $table.fileHash, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> transcriptsRefs<T extends Object>(
    Expression<T> Function($$TranscriptsTableAnnotationComposer a) f,
  ) {
    final $$TranscriptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transcripts,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TranscriptsTableAnnotationComposer(
            $db: $db,
            $table: $db.transcripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playbackSessionsRefs<T extends Object>(
    Expression<T> Function($$PlaybackSessionsTableAnnotationComposer a) f,
  ) {
    final $$PlaybackSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackSessions,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaybackSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.playbackSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MediasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediasTable,
          MediaRow,
          $$MediasTableFilterComposer,
          $$MediasTableOrderingComposer,
          $$MediasTableAnnotationComposer,
          $$MediasTableCreateCompanionBuilder,
          $$MediasTableUpdateCompanionBuilder,
          (MediaRow, $$MediasTableReferences),
          MediaRow,
          PrefetchHooks Function({
            bool transcriptsRefs,
            bool playbackSessionsRefs,
          })
        > {
  $$MediasTableTableManager(_$AppDatabase db, $MediasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$MediasTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$MediasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$MediasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> sourceUri = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> fileHash = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediasCompanion(
                id: id,
                kind: kind,
                title: title,
                sourceUri: sourceUri,
                thumbnailPath: thumbnailPath,
                durationMs: durationMs,
                language: language,
                fileHash: fileHash,
                fileSize: fileSize,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String title,
                required String sourceUri,
                Value<String?> thumbnailPath = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String> language = const Value.absent(),
                required String fileHash,
                required int fileSize,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MediasCompanion.insert(
                id: id,
                kind: kind,
                title: title,
                sourceUri: sourceUri,
                thumbnailPath: thumbnailPath,
                durationMs: durationMs,
                language: language,
                fileHash: fileHash,
                fileSize: fileSize,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$MediasTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({
            transcriptsRefs = false,
            playbackSessionsRefs = false,
          }) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (transcriptsRefs) db.transcripts,
                if (playbackSessionsRefs) db.playbackSessions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transcriptsRefs)
                    await $_getPrefetchedData<
                      MediaRow,
                      $MediasTable,
                      TranscriptRow
                    >(
                      currentTable: table,
                      referencedTable: $$MediasTableReferences
                          ._transcriptsRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$MediasTableReferences(
                                db,
                                table,
                                p0,
                              ).transcriptsRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.mediaId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (playbackSessionsRefs)
                    await $_getPrefetchedData<
                      MediaRow,
                      $MediasTable,
                      PlaybackSessionRow
                    >(
                      currentTable: table,
                      referencedTable: $$MediasTableReferences
                          ._playbackSessionsRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$MediasTableReferences(
                                db,
                                table,
                                p0,
                              ).playbackSessionsRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.mediaId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MediasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediasTable,
      MediaRow,
      $$MediasTableFilterComposer,
      $$MediasTableOrderingComposer,
      $$MediasTableAnnotationComposer,
      $$MediasTableCreateCompanionBuilder,
      $$MediasTableUpdateCompanionBuilder,
      (MediaRow, $$MediasTableReferences),
      MediaRow,
      PrefetchHooks Function({bool transcriptsRefs, bool playbackSessionsRefs})
    >;
typedef $$TranscriptsTableCreateCompanionBuilder =
    TranscriptsCompanion Function({
      required String id,
      required String mediaId,
      required String language,
      required String source,
      required String linesJson,
      Value<String> label,
      Value<int?> trackIndex,
      Value<bool> isEmbedded,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$TranscriptsTableUpdateCompanionBuilder =
    TranscriptsCompanion Function({
      Value<String> id,
      Value<String> mediaId,
      Value<String> language,
      Value<String> source,
      Value<String> linesJson,
      Value<String> label,
      Value<int?> trackIndex,
      Value<bool> isEmbedded,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$TranscriptsTableReferences
    extends BaseReferences<_$AppDatabase, $TranscriptsTable, TranscriptRow> {
  $$TranscriptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MediasTable _mediaIdTable(_$AppDatabase db) => db.medias.createAlias(
    $_aliasNameGenerator(db.transcripts.mediaId, db.medias.id),
  );

  $$MediasTableProcessedTableManager get mediaId {
    final $_column = $_itemColumn<String>('media_id')!;

    final manager = $$MediasTableTableManager(
      $_db,
      $_db.medias,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TranscriptsTableFilterComposer
    extends Composer<_$AppDatabase, $TranscriptsTable> {
  $$TranscriptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linesJson => $composableBuilder(
    column: $table.linesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackIndex => $composableBuilder(
    column: $table.trackIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEmbedded => $composableBuilder(
    column: $table.isEmbedded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MediasTableFilterComposer get mediaId {
    final $$MediasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.medias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediasTableFilterComposer(
            $db: $db,
            $table: $db.medias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TranscriptsTableOrderingComposer
    extends Composer<_$AppDatabase, $TranscriptsTable> {
  $$TranscriptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linesJson => $composableBuilder(
    column: $table.linesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackIndex => $composableBuilder(
    column: $table.trackIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEmbedded => $composableBuilder(
    column: $table.isEmbedded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MediasTableOrderingComposer get mediaId {
    final $$MediasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.medias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediasTableOrderingComposer(
            $db: $db,
            $table: $db.medias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TranscriptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TranscriptsTable> {
  $$TranscriptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get linesJson =>
      $composableBuilder(column: $table.linesJson, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get trackIndex => $composableBuilder(
    column: $table.trackIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEmbedded => $composableBuilder(
    column: $table.isEmbedded,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$MediasTableAnnotationComposer get mediaId {
    final $$MediasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.medias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediasTableAnnotationComposer(
            $db: $db,
            $table: $db.medias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TranscriptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TranscriptsTable,
          TranscriptRow,
          $$TranscriptsTableFilterComposer,
          $$TranscriptsTableOrderingComposer,
          $$TranscriptsTableAnnotationComposer,
          $$TranscriptsTableCreateCompanionBuilder,
          $$TranscriptsTableUpdateCompanionBuilder,
          (TranscriptRow, $$TranscriptsTableReferences),
          TranscriptRow,
          PrefetchHooks Function({bool mediaId})
        > {
  $$TranscriptsTableTableManager(_$AppDatabase db, $TranscriptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$TranscriptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$TranscriptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$TranscriptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> mediaId = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> linesJson = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int?> trackIndex = const Value.absent(),
                Value<bool> isEmbedded = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TranscriptsCompanion(
                id: id,
                mediaId: mediaId,
                language: language,
                source: source,
                linesJson: linesJson,
                label: label,
                trackIndex: trackIndex,
                isEmbedded: isEmbedded,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String mediaId,
                required String language,
                required String source,
                required String linesJson,
                Value<String> label = const Value.absent(),
                Value<int?> trackIndex = const Value.absent(),
                Value<bool> isEmbedded = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TranscriptsCompanion.insert(
                id: id,
                mediaId: mediaId,
                language: language,
                source: source,
                linesJson: linesJson,
                label: label,
                trackIndex: trackIndex,
                isEmbedded: isEmbedded,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$TranscriptsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({mediaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (mediaId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.mediaId,
                            referencedTable: $$TranscriptsTableReferences
                                ._mediaIdTable(db),
                            referencedColumn:
                                $$TranscriptsTableReferences
                                    ._mediaIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TranscriptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TranscriptsTable,
      TranscriptRow,
      $$TranscriptsTableFilterComposer,
      $$TranscriptsTableOrderingComposer,
      $$TranscriptsTableAnnotationComposer,
      $$TranscriptsTableCreateCompanionBuilder,
      $$TranscriptsTableUpdateCompanionBuilder,
      (TranscriptRow, $$TranscriptsTableReferences),
      TranscriptRow,
      PrefetchHooks Function({bool mediaId})
    >;
typedef $$PlaybackSessionsTableCreateCompanionBuilder =
    PlaybackSessionsCompanion Function({
      required String mediaId,
      Value<int> positionMs,
      Value<int> currentSegmentIndex,
      Value<bool> echoActive,
      Value<int> echoStartLine,
      Value<int> echoEndLine,
      Value<int> echoStartMs,
      Value<int> echoEndMs,
      Value<String?> primaryTranscriptId,
      Value<String?> secondaryTranscriptId,
      required DateTime lastActiveAt,
      Value<int> rowid,
    });
typedef $$PlaybackSessionsTableUpdateCompanionBuilder =
    PlaybackSessionsCompanion Function({
      Value<String> mediaId,
      Value<int> positionMs,
      Value<int> currentSegmentIndex,
      Value<bool> echoActive,
      Value<int> echoStartLine,
      Value<int> echoEndLine,
      Value<int> echoStartMs,
      Value<int> echoEndMs,
      Value<String?> primaryTranscriptId,
      Value<String?> secondaryTranscriptId,
      Value<DateTime> lastActiveAt,
      Value<int> rowid,
    });

final class $$PlaybackSessionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PlaybackSessionsTable,
          PlaybackSessionRow
        > {
  $$PlaybackSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MediasTable _mediaIdTable(_$AppDatabase db) => db.medias.createAlias(
    $_aliasNameGenerator(db.playbackSessions.mediaId, db.medias.id),
  );

  $$MediasTableProcessedTableManager get mediaId {
    final $_column = $_itemColumn<String>('media_id')!;

    final manager = $$MediasTableTableManager(
      $_db,
      $_db.medias,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaybackSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaybackSessionsTable> {
  $$PlaybackSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentSegmentIndex => $composableBuilder(
    column: $table.currentSegmentIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get echoActive => $composableBuilder(
    column: $table.echoActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get echoStartLine => $composableBuilder(
    column: $table.echoStartLine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get echoEndLine => $composableBuilder(
    column: $table.echoEndLine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get echoStartMs => $composableBuilder(
    column: $table.echoStartMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get echoEndMs => $composableBuilder(
    column: $table.echoEndMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryTranscriptId => $composableBuilder(
    column: $table.primaryTranscriptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secondaryTranscriptId => $composableBuilder(
    column: $table.secondaryTranscriptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastActiveAt => $composableBuilder(
    column: $table.lastActiveAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MediasTableFilterComposer get mediaId {
    final $$MediasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.medias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediasTableFilterComposer(
            $db: $db,
            $table: $db.medias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaybackSessionsTable> {
  $$PlaybackSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentSegmentIndex => $composableBuilder(
    column: $table.currentSegmentIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get echoActive => $composableBuilder(
    column: $table.echoActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get echoStartLine => $composableBuilder(
    column: $table.echoStartLine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get echoEndLine => $composableBuilder(
    column: $table.echoEndLine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get echoStartMs => $composableBuilder(
    column: $table.echoStartMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get echoEndMs => $composableBuilder(
    column: $table.echoEndMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryTranscriptId => $composableBuilder(
    column: $table.primaryTranscriptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secondaryTranscriptId => $composableBuilder(
    column: $table.secondaryTranscriptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastActiveAt => $composableBuilder(
    column: $table.lastActiveAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MediasTableOrderingComposer get mediaId {
    final $$MediasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.medias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediasTableOrderingComposer(
            $db: $db,
            $table: $db.medias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaybackSessionsTable> {
  $$PlaybackSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentSegmentIndex => $composableBuilder(
    column: $table.currentSegmentIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get echoActive => $composableBuilder(
    column: $table.echoActive,
    builder: (column) => column,
  );

  GeneratedColumn<int> get echoStartLine => $composableBuilder(
    column: $table.echoStartLine,
    builder: (column) => column,
  );

  GeneratedColumn<int> get echoEndLine => $composableBuilder(
    column: $table.echoEndLine,
    builder: (column) => column,
  );

  GeneratedColumn<int> get echoStartMs => $composableBuilder(
    column: $table.echoStartMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get echoEndMs =>
      $composableBuilder(column: $table.echoEndMs, builder: (column) => column);

  GeneratedColumn<String> get primaryTranscriptId => $composableBuilder(
    column: $table.primaryTranscriptId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get secondaryTranscriptId => $composableBuilder(
    column: $table.secondaryTranscriptId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastActiveAt => $composableBuilder(
    column: $table.lastActiveAt,
    builder: (column) => column,
  );

  $$MediasTableAnnotationComposer get mediaId {
    final $$MediasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.medias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediasTableAnnotationComposer(
            $db: $db,
            $table: $db.medias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaybackSessionsTable,
          PlaybackSessionRow,
          $$PlaybackSessionsTableFilterComposer,
          $$PlaybackSessionsTableOrderingComposer,
          $$PlaybackSessionsTableAnnotationComposer,
          $$PlaybackSessionsTableCreateCompanionBuilder,
          $$PlaybackSessionsTableUpdateCompanionBuilder,
          (PlaybackSessionRow, $$PlaybackSessionsTableReferences),
          PlaybackSessionRow,
          PrefetchHooks Function({bool mediaId})
        > {
  $$PlaybackSessionsTableTableManager(
    _$AppDatabase db,
    $PlaybackSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$PlaybackSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$PlaybackSessionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$PlaybackSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> mediaId = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<int> currentSegmentIndex = const Value.absent(),
                Value<bool> echoActive = const Value.absent(),
                Value<int> echoStartLine = const Value.absent(),
                Value<int> echoEndLine = const Value.absent(),
                Value<int> echoStartMs = const Value.absent(),
                Value<int> echoEndMs = const Value.absent(),
                Value<String?> primaryTranscriptId = const Value.absent(),
                Value<String?> secondaryTranscriptId = const Value.absent(),
                Value<DateTime> lastActiveAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaybackSessionsCompanion(
                mediaId: mediaId,
                positionMs: positionMs,
                currentSegmentIndex: currentSegmentIndex,
                echoActive: echoActive,
                echoStartLine: echoStartLine,
                echoEndLine: echoEndLine,
                echoStartMs: echoStartMs,
                echoEndMs: echoEndMs,
                primaryTranscriptId: primaryTranscriptId,
                secondaryTranscriptId: secondaryTranscriptId,
                lastActiveAt: lastActiveAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String mediaId,
                Value<int> positionMs = const Value.absent(),
                Value<int> currentSegmentIndex = const Value.absent(),
                Value<bool> echoActive = const Value.absent(),
                Value<int> echoStartLine = const Value.absent(),
                Value<int> echoEndLine = const Value.absent(),
                Value<int> echoStartMs = const Value.absent(),
                Value<int> echoEndMs = const Value.absent(),
                Value<String?> primaryTranscriptId = const Value.absent(),
                Value<String?> secondaryTranscriptId = const Value.absent(),
                required DateTime lastActiveAt,
                Value<int> rowid = const Value.absent(),
              }) => PlaybackSessionsCompanion.insert(
                mediaId: mediaId,
                positionMs: positionMs,
                currentSegmentIndex: currentSegmentIndex,
                echoActive: echoActive,
                echoStartLine: echoStartLine,
                echoEndLine: echoEndLine,
                echoStartMs: echoStartMs,
                echoEndMs: echoEndMs,
                primaryTranscriptId: primaryTranscriptId,
                secondaryTranscriptId: secondaryTranscriptId,
                lastActiveAt: lastActiveAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$PlaybackSessionsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({mediaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (mediaId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.mediaId,
                            referencedTable: $$PlaybackSessionsTableReferences
                                ._mediaIdTable(db),
                            referencedColumn:
                                $$PlaybackSessionsTableReferences
                                    ._mediaIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaybackSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaybackSessionsTable,
      PlaybackSessionRow,
      $$PlaybackSessionsTableFilterComposer,
      $$PlaybackSessionsTableOrderingComposer,
      $$PlaybackSessionsTableAnnotationComposer,
      $$PlaybackSessionsTableCreateCompanionBuilder,
      $$PlaybackSessionsTableUpdateCompanionBuilder,
      (PlaybackSessionRow, $$PlaybackSessionsTableReferences),
      PlaybackSessionRow,
      PrefetchHooks Function({bool mediaId})
    >;
typedef $$SettingsKvTableCreateCompanionBuilder =
    SettingsKvCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsKvTableUpdateCompanionBuilder =
    SettingsKvCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsKvTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsKvTable> {
  $$SettingsKvTableFilterComposer({
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

class $$SettingsKvTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsKvTable> {
  $$SettingsKvTableOrderingComposer({
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

class $$SettingsKvTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsKvTable> {
  $$SettingsKvTableAnnotationComposer({
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

class $$SettingsKvTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsKvTable,
          SettingRow,
          $$SettingsKvTableFilterComposer,
          $$SettingsKvTableOrderingComposer,
          $$SettingsKvTableAnnotationComposer,
          $$SettingsKvTableCreateCompanionBuilder,
          $$SettingsKvTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsKvTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsKvTableTableManager(_$AppDatabase db, $SettingsKvTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SettingsKvTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$SettingsKvTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$SettingsKvTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsKvCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsKvCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsKvTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsKvTable,
      SettingRow,
      $$SettingsKvTableFilterComposer,
      $$SettingsKvTableOrderingComposer,
      $$SettingsKvTableAnnotationComposer,
      $$SettingsKvTableCreateCompanionBuilder,
      $$SettingsKvTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsKvTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MediasTableTableManager get medias =>
      $$MediasTableTableManager(_db, _db.medias);
  $$TranscriptsTableTableManager get transcripts =>
      $$TranscriptsTableTableManager(_db, _db.transcripts);
  $$PlaybackSessionsTableTableManager get playbackSessions =>
      $$PlaybackSessionsTableTableManager(_db, _db.playbackSessions);
  $$SettingsKvTableTableManager get settingsKv =>
      $$SettingsKvTableTableManager(_db, _db.settingsKv);
}

mixin _$MediaDaoMixin on DatabaseAccessor<AppDatabase> {
  $MediasTable get medias => attachedDatabase.medias;
  MediaDaoManager get managers => MediaDaoManager(this);
}

class MediaDaoManager {
  final _$MediaDaoMixin _db;
  MediaDaoManager(this._db);
  $$MediasTableTableManager get medias =>
      $$MediasTableTableManager(_db.attachedDatabase, _db.medias);
}

mixin _$TranscriptDaoMixin on DatabaseAccessor<AppDatabase> {
  $MediasTable get medias => attachedDatabase.medias;
  $TranscriptsTable get transcripts => attachedDatabase.transcripts;
  TranscriptDaoManager get managers => TranscriptDaoManager(this);
}

class TranscriptDaoManager {
  final _$TranscriptDaoMixin _db;
  TranscriptDaoManager(this._db);
  $$MediasTableTableManager get medias =>
      $$MediasTableTableManager(_db.attachedDatabase, _db.medias);
  $$TranscriptsTableTableManager get transcripts =>
      $$TranscriptsTableTableManager(_db.attachedDatabase, _db.transcripts);
}

mixin _$SessionDaoMixin on DatabaseAccessor<AppDatabase> {
  $MediasTable get medias => attachedDatabase.medias;
  $PlaybackSessionsTable get playbackSessions =>
      attachedDatabase.playbackSessions;
  SessionDaoManager get managers => SessionDaoManager(this);
}

class SessionDaoManager {
  final _$SessionDaoMixin _db;
  SessionDaoManager(this._db);
  $$MediasTableTableManager get medias =>
      $$MediasTableTableManager(_db.attachedDatabase, _db.medias);
  $$PlaybackSessionsTableTableManager get playbackSessions =>
      $$PlaybackSessionsTableTableManager(
        _db.attachedDatabase,
        _db.playbackSessions,
      );
}

mixin _$SettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SettingsKvTable get settingsKv => attachedDatabase.settingsKv;
  SettingsDaoManager get managers => SettingsDaoManager(this);
}

class SettingsDaoManager {
  final _$SettingsDaoMixin _db;
  SettingsDaoManager(this._db);
  $$SettingsKvTableTableManager get settingsKv =>
      $$SettingsKvTableTableManager(_db.attachedDatabase, _db.settingsKv);
}
