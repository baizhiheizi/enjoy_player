// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VideosTable extends Videos with TableInfo<$VideosTable, VideoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VideosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vidMeta = const VerificationMeta('vid');
  @override
  late final GeneratedColumn<String> vid = GeneratedColumn<String>(
    'vid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('user'),
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
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
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localUriMeta = const VerificationMeta(
    'localUri',
  );
  @override
  late final GeneratedColumn<String> localUri = GeneratedColumn<String>(
    'local_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _md5Meta = const VerificationMeta('md5');
  @override
  late final GeneratedColumn<String> md5 = GeneratedColumn<String>(
    'md5',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaUrlMeta = const VerificationMeta(
    'mediaUrl',
  );
  @override
  late final GeneratedColumn<String> mediaUrl = GeneratedColumn<String>(
    'media_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
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
    vid,
    provider,
    title,
    description,
    thumbnailUrl,
    durationSeconds,
    language,
    source,
    localUri,
    md5,
    size,
    mediaUrl,
    syncStatus,
    serverUpdatedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'videos';
  @override
  VerificationContext validateIntegrity(
    Insertable<VideoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vid')) {
      context.handle(
        _vidMeta,
        vid.isAcceptableOrUnknown(data['vid']!, _vidMeta),
      );
    } else if (isInserting) {
      context.missing(_vidMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('local_uri')) {
      context.handle(
        _localUriMeta,
        localUri.isAcceptableOrUnknown(data['local_uri']!, _localUriMeta),
      );
    }
    if (data.containsKey('md5')) {
      context.handle(
        _md5Meta,
        md5.isAcceptableOrUnknown(data['md5']!, _md5Meta),
      );
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    }
    if (data.containsKey('media_url')) {
      context.handle(
        _mediaUrlMeta,
        mediaUrl.isAcceptableOrUnknown(data['media_url']!, _mediaUrlMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
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
  VideoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VideoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      vid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vid'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      localUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_uri'],
      ),
      md5: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}md5'],
      ),
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      ),
      mediaUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_url'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      ),
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_updated_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VideosTable createAlias(String alias) {
    return $VideosTable(attachedDatabase, alias);
  }
}

class VideoRow extends DataClass implements Insertable<VideoRow> {
  final String id;
  final String vid;
  final String provider;
  final String title;
  final String? description;
  final String? thumbnailUrl;

  /// Duration in whole seconds (weapp `Video.duration`).
  final int durationSeconds;
  final String language;
  final String? source;

  /// Local file URI (replaces web `fileHandle` / `blob`).
  final String? localUri;
  final String? md5;
  final int? size;
  final String? mediaUrl;
  final String? syncStatus;
  final DateTime? serverUpdatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const VideoRow({
    required this.id,
    required this.vid,
    required this.provider,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.durationSeconds,
    required this.language,
    this.source,
    this.localUri,
    this.md5,
    this.size,
    this.mediaUrl,
    this.syncStatus,
    this.serverUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vid'] = Variable<String>(vid);
    map['provider'] = Variable<String>(provider);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['language'] = Variable<String>(language);
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || localUri != null) {
      map['local_uri'] = Variable<String>(localUri);
    }
    if (!nullToAbsent || md5 != null) {
      map['md5'] = Variable<String>(md5);
    }
    if (!nullToAbsent || size != null) {
      map['size'] = Variable<int>(size);
    }
    if (!nullToAbsent || mediaUrl != null) {
      map['media_url'] = Variable<String>(mediaUrl);
    }
    if (!nullToAbsent || syncStatus != null) {
      map['sync_status'] = Variable<String>(syncStatus);
    }
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VideosCompanion toCompanion(bool nullToAbsent) {
    return VideosCompanion(
      id: Value(id),
      vid: Value(vid),
      provider: Value(provider),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      durationSeconds: Value(durationSeconds),
      language: Value(language),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      localUri: localUri == null && nullToAbsent
          ? const Value.absent()
          : Value(localUri),
      md5: md5 == null && nullToAbsent ? const Value.absent() : Value(md5),
      size: size == null && nullToAbsent ? const Value.absent() : Value(size),
      mediaUrl: mediaUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaUrl),
      syncStatus: syncStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(syncStatus),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory VideoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VideoRow(
      id: serializer.fromJson<String>(json['id']),
      vid: serializer.fromJson<String>(json['vid']),
      provider: serializer.fromJson<String>(json['provider']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      language: serializer.fromJson<String>(json['language']),
      source: serializer.fromJson<String?>(json['source']),
      localUri: serializer.fromJson<String?>(json['localUri']),
      md5: serializer.fromJson<String?>(json['md5']),
      size: serializer.fromJson<int?>(json['size']),
      mediaUrl: serializer.fromJson<String?>(json['mediaUrl']),
      syncStatus: serializer.fromJson<String?>(json['syncStatus']),
      serverUpdatedAt: serializer.fromJson<DateTime?>(json['serverUpdatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vid': serializer.toJson<String>(vid),
      'provider': serializer.toJson<String>(provider),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'language': serializer.toJson<String>(language),
      'source': serializer.toJson<String?>(source),
      'localUri': serializer.toJson<String?>(localUri),
      'md5': serializer.toJson<String?>(md5),
      'size': serializer.toJson<int?>(size),
      'mediaUrl': serializer.toJson<String?>(mediaUrl),
      'syncStatus': serializer.toJson<String?>(syncStatus),
      'serverUpdatedAt': serializer.toJson<DateTime?>(serverUpdatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VideoRow copyWith({
    String? id,
    String? vid,
    String? provider,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> thumbnailUrl = const Value.absent(),
    int? durationSeconds,
    String? language,
    Value<String?> source = const Value.absent(),
    Value<String?> localUri = const Value.absent(),
    Value<String?> md5 = const Value.absent(),
    Value<int?> size = const Value.absent(),
    Value<String?> mediaUrl = const Value.absent(),
    Value<String?> syncStatus = const Value.absent(),
    Value<DateTime?> serverUpdatedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => VideoRow(
    id: id ?? this.id,
    vid: vid ?? this.vid,
    provider: provider ?? this.provider,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    language: language ?? this.language,
    source: source.present ? source.value : this.source,
    localUri: localUri.present ? localUri.value : this.localUri,
    md5: md5.present ? md5.value : this.md5,
    size: size.present ? size.value : this.size,
    mediaUrl: mediaUrl.present ? mediaUrl.value : this.mediaUrl,
    syncStatus: syncStatus.present ? syncStatus.value : this.syncStatus,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VideoRow copyWithCompanion(VideosCompanion data) {
    return VideoRow(
      id: data.id.present ? data.id.value : this.id,
      vid: data.vid.present ? data.vid.value : this.vid,
      provider: data.provider.present ? data.provider.value : this.provider,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      language: data.language.present ? data.language.value : this.language,
      source: data.source.present ? data.source.value : this.source,
      localUri: data.localUri.present ? data.localUri.value : this.localUri,
      md5: data.md5.present ? data.md5.value : this.md5,
      size: data.size.present ? data.size.value : this.size,
      mediaUrl: data.mediaUrl.present ? data.mediaUrl.value : this.mediaUrl,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VideoRow(')
          ..write('id: $id, ')
          ..write('vid: $vid, ')
          ..write('provider: $provider, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('language: $language, ')
          ..write('source: $source, ')
          ..write('localUri: $localUri, ')
          ..write('md5: $md5, ')
          ..write('size: $size, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    vid,
    provider,
    title,
    description,
    thumbnailUrl,
    durationSeconds,
    language,
    source,
    localUri,
    md5,
    size,
    mediaUrl,
    syncStatus,
    serverUpdatedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VideoRow &&
          other.id == this.id &&
          other.vid == this.vid &&
          other.provider == this.provider &&
          other.title == this.title &&
          other.description == this.description &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.durationSeconds == this.durationSeconds &&
          other.language == this.language &&
          other.source == this.source &&
          other.localUri == this.localUri &&
          other.md5 == this.md5 &&
          other.size == this.size &&
          other.mediaUrl == this.mediaUrl &&
          other.syncStatus == this.syncStatus &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VideosCompanion extends UpdateCompanion<VideoRow> {
  final Value<String> id;
  final Value<String> vid;
  final Value<String> provider;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> thumbnailUrl;
  final Value<int> durationSeconds;
  final Value<String> language;
  final Value<String?> source;
  final Value<String?> localUri;
  final Value<String?> md5;
  final Value<int?> size;
  final Value<String?> mediaUrl;
  final Value<String?> syncStatus;
  final Value<DateTime?> serverUpdatedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VideosCompanion({
    this.id = const Value.absent(),
    this.vid = const Value.absent(),
    this.provider = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.language = const Value.absent(),
    this.source = const Value.absent(),
    this.localUri = const Value.absent(),
    this.md5 = const Value.absent(),
    this.size = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VideosCompanion.insert({
    required String id,
    required String vid,
    this.provider = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.language = const Value.absent(),
    this.source = const Value.absent(),
    this.localUri = const Value.absent(),
    this.md5 = const Value.absent(),
    this.size = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       vid = Value(vid),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<VideoRow> custom({
    Expression<String>? id,
    Expression<String>? vid,
    Expression<String>? provider,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? thumbnailUrl,
    Expression<int>? durationSeconds,
    Expression<String>? language,
    Expression<String>? source,
    Expression<String>? localUri,
    Expression<String>? md5,
    Expression<int>? size,
    Expression<String>? mediaUrl,
    Expression<String>? syncStatus,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vid != null) 'vid': vid,
      if (provider != null) 'provider': provider,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (language != null) 'language': language,
      if (source != null) 'source': source,
      if (localUri != null) 'local_uri': localUri,
      if (md5 != null) 'md5': md5,
      if (size != null) 'size': size,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VideosCompanion copyWith({
    Value<String>? id,
    Value<String>? vid,
    Value<String>? provider,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? thumbnailUrl,
    Value<int>? durationSeconds,
    Value<String>? language,
    Value<String?>? source,
    Value<String?>? localUri,
    Value<String?>? md5,
    Value<int?>? size,
    Value<String?>? mediaUrl,
    Value<String?>? syncStatus,
    Value<DateTime?>? serverUpdatedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return VideosCompanion(
      id: id ?? this.id,
      vid: vid ?? this.vid,
      provider: provider ?? this.provider,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      language: language ?? this.language,
      source: source ?? this.source,
      localUri: localUri ?? this.localUri,
      md5: md5 ?? this.md5,
      size: size ?? this.size,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      syncStatus: syncStatus ?? this.syncStatus,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
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
    if (vid.present) {
      map['vid'] = Variable<String>(vid.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (localUri.present) {
      map['local_uri'] = Variable<String>(localUri.value);
    }
    if (md5.present) {
      map['md5'] = Variable<String>(md5.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (mediaUrl.present) {
      map['media_url'] = Variable<String>(mediaUrl.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
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
    return (StringBuffer('VideosCompanion(')
          ..write('id: $id, ')
          ..write('vid: $vid, ')
          ..write('provider: $provider, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('language: $language, ')
          ..write('source: $source, ')
          ..write('localUri: $localUri, ')
          ..write('md5: $md5, ')
          ..write('size: $size, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AudiosTable extends Audios with TableInfo<$AudiosTable, AudioRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AudiosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aidMeta = const VerificationMeta('aid');
  @override
  late final GeneratedColumn<String> aid = GeneratedColumn<String>(
    'aid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('user'),
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
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
  static const VerificationMeta _translationKeyMeta = const VerificationMeta(
    'translationKey',
  );
  @override
  late final GeneratedColumn<String> translationKey = GeneratedColumn<String>(
    'translation_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceTextMeta = const VerificationMeta(
    'sourceText',
  );
  @override
  late final GeneratedColumn<String> sourceText = GeneratedColumn<String>(
    'source_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voiceMeta = const VerificationMeta('voice');
  @override
  late final GeneratedColumn<String> voice = GeneratedColumn<String>(
    'voice',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localUriMeta = const VerificationMeta(
    'localUri',
  );
  @override
  late final GeneratedColumn<String> localUri = GeneratedColumn<String>(
    'local_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _md5Meta = const VerificationMeta('md5');
  @override
  late final GeneratedColumn<String> md5 = GeneratedColumn<String>(
    'md5',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaUrlMeta = const VerificationMeta(
    'mediaUrl',
  );
  @override
  late final GeneratedColumn<String> mediaUrl = GeneratedColumn<String>(
    'media_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
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
    aid,
    provider,
    title,
    description,
    thumbnailUrl,
    durationSeconds,
    language,
    translationKey,
    sourceText,
    voice,
    source,
    localUri,
    md5,
    size,
    mediaUrl,
    syncStatus,
    serverUpdatedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audios';
  @override
  VerificationContext validateIntegrity(
    Insertable<AudioRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('aid')) {
      context.handle(
        _aidMeta,
        aid.isAcceptableOrUnknown(data['aid']!, _aidMeta),
      );
    } else if (isInserting) {
      context.missing(_aidMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('translation_key')) {
      context.handle(
        _translationKeyMeta,
        translationKey.isAcceptableOrUnknown(
          data['translation_key']!,
          _translationKeyMeta,
        ),
      );
    }
    if (data.containsKey('source_text')) {
      context.handle(
        _sourceTextMeta,
        sourceText.isAcceptableOrUnknown(data['source_text']!, _sourceTextMeta),
      );
    }
    if (data.containsKey('voice')) {
      context.handle(
        _voiceMeta,
        voice.isAcceptableOrUnknown(data['voice']!, _voiceMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('local_uri')) {
      context.handle(
        _localUriMeta,
        localUri.isAcceptableOrUnknown(data['local_uri']!, _localUriMeta),
      );
    }
    if (data.containsKey('md5')) {
      context.handle(
        _md5Meta,
        md5.isAcceptableOrUnknown(data['md5']!, _md5Meta),
      );
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    }
    if (data.containsKey('media_url')) {
      context.handle(
        _mediaUrlMeta,
        mediaUrl.isAcceptableOrUnknown(data['media_url']!, _mediaUrlMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
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
  AudioRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      aid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aid'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      translationKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation_key'],
      ),
      sourceText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_text'],
      ),
      voice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      localUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_uri'],
      ),
      md5: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}md5'],
      ),
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      ),
      mediaUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_url'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      ),
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_updated_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AudiosTable createAlias(String alias) {
    return $AudiosTable(attachedDatabase, alias);
  }
}

class AudioRow extends DataClass implements Insertable<AudioRow> {
  final String id;
  final String aid;
  final String provider;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final int durationSeconds;
  final String language;
  final String? translationKey;
  final String? sourceText;
  final String? voice;
  final String? source;
  final String? localUri;
  final String? md5;
  final int? size;
  final String? mediaUrl;
  final String? syncStatus;
  final DateTime? serverUpdatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AudioRow({
    required this.id,
    required this.aid,
    required this.provider,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.durationSeconds,
    required this.language,
    this.translationKey,
    this.sourceText,
    this.voice,
    this.source,
    this.localUri,
    this.md5,
    this.size,
    this.mediaUrl,
    this.syncStatus,
    this.serverUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['aid'] = Variable<String>(aid);
    map['provider'] = Variable<String>(provider);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['language'] = Variable<String>(language);
    if (!nullToAbsent || translationKey != null) {
      map['translation_key'] = Variable<String>(translationKey);
    }
    if (!nullToAbsent || sourceText != null) {
      map['source_text'] = Variable<String>(sourceText);
    }
    if (!nullToAbsent || voice != null) {
      map['voice'] = Variable<String>(voice);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || localUri != null) {
      map['local_uri'] = Variable<String>(localUri);
    }
    if (!nullToAbsent || md5 != null) {
      map['md5'] = Variable<String>(md5);
    }
    if (!nullToAbsent || size != null) {
      map['size'] = Variable<int>(size);
    }
    if (!nullToAbsent || mediaUrl != null) {
      map['media_url'] = Variable<String>(mediaUrl);
    }
    if (!nullToAbsent || syncStatus != null) {
      map['sync_status'] = Variable<String>(syncStatus);
    }
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AudiosCompanion toCompanion(bool nullToAbsent) {
    return AudiosCompanion(
      id: Value(id),
      aid: Value(aid),
      provider: Value(provider),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      durationSeconds: Value(durationSeconds),
      language: Value(language),
      translationKey: translationKey == null && nullToAbsent
          ? const Value.absent()
          : Value(translationKey),
      sourceText: sourceText == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceText),
      voice: voice == null && nullToAbsent
          ? const Value.absent()
          : Value(voice),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      localUri: localUri == null && nullToAbsent
          ? const Value.absent()
          : Value(localUri),
      md5: md5 == null && nullToAbsent ? const Value.absent() : Value(md5),
      size: size == null && nullToAbsent ? const Value.absent() : Value(size),
      mediaUrl: mediaUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaUrl),
      syncStatus: syncStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(syncStatus),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AudioRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioRow(
      id: serializer.fromJson<String>(json['id']),
      aid: serializer.fromJson<String>(json['aid']),
      provider: serializer.fromJson<String>(json['provider']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      language: serializer.fromJson<String>(json['language']),
      translationKey: serializer.fromJson<String?>(json['translationKey']),
      sourceText: serializer.fromJson<String?>(json['sourceText']),
      voice: serializer.fromJson<String?>(json['voice']),
      source: serializer.fromJson<String?>(json['source']),
      localUri: serializer.fromJson<String?>(json['localUri']),
      md5: serializer.fromJson<String?>(json['md5']),
      size: serializer.fromJson<int?>(json['size']),
      mediaUrl: serializer.fromJson<String?>(json['mediaUrl']),
      syncStatus: serializer.fromJson<String?>(json['syncStatus']),
      serverUpdatedAt: serializer.fromJson<DateTime?>(json['serverUpdatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'aid': serializer.toJson<String>(aid),
      'provider': serializer.toJson<String>(provider),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'language': serializer.toJson<String>(language),
      'translationKey': serializer.toJson<String?>(translationKey),
      'sourceText': serializer.toJson<String?>(sourceText),
      'voice': serializer.toJson<String?>(voice),
      'source': serializer.toJson<String?>(source),
      'localUri': serializer.toJson<String?>(localUri),
      'md5': serializer.toJson<String?>(md5),
      'size': serializer.toJson<int?>(size),
      'mediaUrl': serializer.toJson<String?>(mediaUrl),
      'syncStatus': serializer.toJson<String?>(syncStatus),
      'serverUpdatedAt': serializer.toJson<DateTime?>(serverUpdatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AudioRow copyWith({
    String? id,
    String? aid,
    String? provider,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> thumbnailUrl = const Value.absent(),
    int? durationSeconds,
    String? language,
    Value<String?> translationKey = const Value.absent(),
    Value<String?> sourceText = const Value.absent(),
    Value<String?> voice = const Value.absent(),
    Value<String?> source = const Value.absent(),
    Value<String?> localUri = const Value.absent(),
    Value<String?> md5 = const Value.absent(),
    Value<int?> size = const Value.absent(),
    Value<String?> mediaUrl = const Value.absent(),
    Value<String?> syncStatus = const Value.absent(),
    Value<DateTime?> serverUpdatedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AudioRow(
    id: id ?? this.id,
    aid: aid ?? this.aid,
    provider: provider ?? this.provider,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    language: language ?? this.language,
    translationKey: translationKey.present
        ? translationKey.value
        : this.translationKey,
    sourceText: sourceText.present ? sourceText.value : this.sourceText,
    voice: voice.present ? voice.value : this.voice,
    source: source.present ? source.value : this.source,
    localUri: localUri.present ? localUri.value : this.localUri,
    md5: md5.present ? md5.value : this.md5,
    size: size.present ? size.value : this.size,
    mediaUrl: mediaUrl.present ? mediaUrl.value : this.mediaUrl,
    syncStatus: syncStatus.present ? syncStatus.value : this.syncStatus,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AudioRow copyWithCompanion(AudiosCompanion data) {
    return AudioRow(
      id: data.id.present ? data.id.value : this.id,
      aid: data.aid.present ? data.aid.value : this.aid,
      provider: data.provider.present ? data.provider.value : this.provider,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      language: data.language.present ? data.language.value : this.language,
      translationKey: data.translationKey.present
          ? data.translationKey.value
          : this.translationKey,
      sourceText: data.sourceText.present
          ? data.sourceText.value
          : this.sourceText,
      voice: data.voice.present ? data.voice.value : this.voice,
      source: data.source.present ? data.source.value : this.source,
      localUri: data.localUri.present ? data.localUri.value : this.localUri,
      md5: data.md5.present ? data.md5.value : this.md5,
      size: data.size.present ? data.size.value : this.size,
      mediaUrl: data.mediaUrl.present ? data.mediaUrl.value : this.mediaUrl,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioRow(')
          ..write('id: $id, ')
          ..write('aid: $aid, ')
          ..write('provider: $provider, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('language: $language, ')
          ..write('translationKey: $translationKey, ')
          ..write('sourceText: $sourceText, ')
          ..write('voice: $voice, ')
          ..write('source: $source, ')
          ..write('localUri: $localUri, ')
          ..write('md5: $md5, ')
          ..write('size: $size, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    aid,
    provider,
    title,
    description,
    thumbnailUrl,
    durationSeconds,
    language,
    translationKey,
    sourceText,
    voice,
    source,
    localUri,
    md5,
    size,
    mediaUrl,
    syncStatus,
    serverUpdatedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioRow &&
          other.id == this.id &&
          other.aid == this.aid &&
          other.provider == this.provider &&
          other.title == this.title &&
          other.description == this.description &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.durationSeconds == this.durationSeconds &&
          other.language == this.language &&
          other.translationKey == this.translationKey &&
          other.sourceText == this.sourceText &&
          other.voice == this.voice &&
          other.source == this.source &&
          other.localUri == this.localUri &&
          other.md5 == this.md5 &&
          other.size == this.size &&
          other.mediaUrl == this.mediaUrl &&
          other.syncStatus == this.syncStatus &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AudiosCompanion extends UpdateCompanion<AudioRow> {
  final Value<String> id;
  final Value<String> aid;
  final Value<String> provider;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> thumbnailUrl;
  final Value<int> durationSeconds;
  final Value<String> language;
  final Value<String?> translationKey;
  final Value<String?> sourceText;
  final Value<String?> voice;
  final Value<String?> source;
  final Value<String?> localUri;
  final Value<String?> md5;
  final Value<int?> size;
  final Value<String?> mediaUrl;
  final Value<String?> syncStatus;
  final Value<DateTime?> serverUpdatedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AudiosCompanion({
    this.id = const Value.absent(),
    this.aid = const Value.absent(),
    this.provider = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.language = const Value.absent(),
    this.translationKey = const Value.absent(),
    this.sourceText = const Value.absent(),
    this.voice = const Value.absent(),
    this.source = const Value.absent(),
    this.localUri = const Value.absent(),
    this.md5 = const Value.absent(),
    this.size = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AudiosCompanion.insert({
    required String id,
    required String aid,
    this.provider = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.language = const Value.absent(),
    this.translationKey = const Value.absent(),
    this.sourceText = const Value.absent(),
    this.voice = const Value.absent(),
    this.source = const Value.absent(),
    this.localUri = const Value.absent(),
    this.md5 = const Value.absent(),
    this.size = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       aid = Value(aid),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AudioRow> custom({
    Expression<String>? id,
    Expression<String>? aid,
    Expression<String>? provider,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? thumbnailUrl,
    Expression<int>? durationSeconds,
    Expression<String>? language,
    Expression<String>? translationKey,
    Expression<String>? sourceText,
    Expression<String>? voice,
    Expression<String>? source,
    Expression<String>? localUri,
    Expression<String>? md5,
    Expression<int>? size,
    Expression<String>? mediaUrl,
    Expression<String>? syncStatus,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (aid != null) 'aid': aid,
      if (provider != null) 'provider': provider,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (language != null) 'language': language,
      if (translationKey != null) 'translation_key': translationKey,
      if (sourceText != null) 'source_text': sourceText,
      if (voice != null) 'voice': voice,
      if (source != null) 'source': source,
      if (localUri != null) 'local_uri': localUri,
      if (md5 != null) 'md5': md5,
      if (size != null) 'size': size,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AudiosCompanion copyWith({
    Value<String>? id,
    Value<String>? aid,
    Value<String>? provider,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? thumbnailUrl,
    Value<int>? durationSeconds,
    Value<String>? language,
    Value<String?>? translationKey,
    Value<String?>? sourceText,
    Value<String?>? voice,
    Value<String?>? source,
    Value<String?>? localUri,
    Value<String?>? md5,
    Value<int?>? size,
    Value<String?>? mediaUrl,
    Value<String?>? syncStatus,
    Value<DateTime?>? serverUpdatedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AudiosCompanion(
      id: id ?? this.id,
      aid: aid ?? this.aid,
      provider: provider ?? this.provider,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      language: language ?? this.language,
      translationKey: translationKey ?? this.translationKey,
      sourceText: sourceText ?? this.sourceText,
      voice: voice ?? this.voice,
      source: source ?? this.source,
      localUri: localUri ?? this.localUri,
      md5: md5 ?? this.md5,
      size: size ?? this.size,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      syncStatus: syncStatus ?? this.syncStatus,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
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
    if (aid.present) {
      map['aid'] = Variable<String>(aid.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (translationKey.present) {
      map['translation_key'] = Variable<String>(translationKey.value);
    }
    if (sourceText.present) {
      map['source_text'] = Variable<String>(sourceText.value);
    }
    if (voice.present) {
      map['voice'] = Variable<String>(voice.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (localUri.present) {
      map['local_uri'] = Variable<String>(localUri.value);
    }
    if (md5.present) {
      map['md5'] = Variable<String>(md5.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (mediaUrl.present) {
      map['media_url'] = Variable<String>(mediaUrl.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
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
    return (StringBuffer('AudiosCompanion(')
          ..write('id: $id, ')
          ..write('aid: $aid, ')
          ..write('provider: $provider, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('language: $language, ')
          ..write('translationKey: $translationKey, ')
          ..write('sourceText: $sourceText, ')
          ..write('voice: $voice, ')
          ..write('source: $source, ')
          ..write('localUri: $localUri, ')
          ..write('md5: $md5, ')
          ..write('size: $size, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
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
  static const VerificationMeta _targetTypeMeta = const VerificationMeta(
    'targetType',
  );
  @override
  late final GeneratedColumn<String> targetType = GeneratedColumn<String>(
    'target_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _timelineJsonMeta = const VerificationMeta(
    'timelineJson',
  );
  @override
  late final GeneratedColumn<String> timelineJson = GeneratedColumn<String>(
    'timeline_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceIdMeta = const VerificationMeta(
    'referenceId',
  );
  @override
  late final GeneratedColumn<String> referenceId = GeneratedColumn<String>(
    'reference_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
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
    targetType,
    targetId,
    language,
    source,
    timelineJson,
    referenceId,
    label,
    trackIndex,
    syncStatus,
    serverUpdatedAt,
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
    if (data.containsKey('target_type')) {
      context.handle(
        _targetTypeMeta,
        targetType.isAcceptableOrUnknown(data['target_type']!, _targetTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_targetTypeMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
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
    if (data.containsKey('timeline_json')) {
      context.handle(
        _timelineJsonMeta,
        timelineJson.isAcceptableOrUnknown(
          data['timeline_json']!,
          _timelineJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timelineJsonMeta);
    }
    if (data.containsKey('reference_id')) {
      context.handle(
        _referenceIdMeta,
        referenceId.isAcceptableOrUnknown(
          data['reference_id']!,
          _referenceIdMeta,
        ),
      );
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
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
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
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      targetType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_type'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      timelineJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timeline_json'],
      )!,
      referenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_id'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      trackIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_index'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      ),
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_updated_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
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

  /// Weapp `TargetType`: `Video` | `Audio` | `Example` | `Ebook`.
  final String targetType;
  final String targetId;
  final String language;

  /// Weapp `TranscriptSource`: `official` | `auto` | `ai` | `user`.
  final String source;

  /// JSON array of `TranscriptLine` (ms-based), same shape as weapp `timeline`.
  final String timelineJson;
  final String? referenceId;
  final String label;
  final int? trackIndex;
  final String? syncStatus;
  final DateTime? serverUpdatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TranscriptRow({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.language,
    required this.source,
    required this.timelineJson,
    this.referenceId,
    required this.label,
    this.trackIndex,
    this.syncStatus,
    this.serverUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['target_type'] = Variable<String>(targetType);
    map['target_id'] = Variable<String>(targetId);
    map['language'] = Variable<String>(language);
    map['source'] = Variable<String>(source);
    map['timeline_json'] = Variable<String>(timelineJson);
    if (!nullToAbsent || referenceId != null) {
      map['reference_id'] = Variable<String>(referenceId);
    }
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || trackIndex != null) {
      map['track_index'] = Variable<int>(trackIndex);
    }
    if (!nullToAbsent || syncStatus != null) {
      map['sync_status'] = Variable<String>(syncStatus);
    }
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TranscriptsCompanion toCompanion(bool nullToAbsent) {
    return TranscriptsCompanion(
      id: Value(id),
      targetType: Value(targetType),
      targetId: Value(targetId),
      language: Value(language),
      source: Value(source),
      timelineJson: Value(timelineJson),
      referenceId: referenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceId),
      label: Value(label),
      trackIndex: trackIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(trackIndex),
      syncStatus: syncStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(syncStatus),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
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
      targetType: serializer.fromJson<String>(json['targetType']),
      targetId: serializer.fromJson<String>(json['targetId']),
      language: serializer.fromJson<String>(json['language']),
      source: serializer.fromJson<String>(json['source']),
      timelineJson: serializer.fromJson<String>(json['timelineJson']),
      referenceId: serializer.fromJson<String?>(json['referenceId']),
      label: serializer.fromJson<String>(json['label']),
      trackIndex: serializer.fromJson<int?>(json['trackIndex']),
      syncStatus: serializer.fromJson<String?>(json['syncStatus']),
      serverUpdatedAt: serializer.fromJson<DateTime?>(json['serverUpdatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'targetType': serializer.toJson<String>(targetType),
      'targetId': serializer.toJson<String>(targetId),
      'language': serializer.toJson<String>(language),
      'source': serializer.toJson<String>(source),
      'timelineJson': serializer.toJson<String>(timelineJson),
      'referenceId': serializer.toJson<String?>(referenceId),
      'label': serializer.toJson<String>(label),
      'trackIndex': serializer.toJson<int?>(trackIndex),
      'syncStatus': serializer.toJson<String?>(syncStatus),
      'serverUpdatedAt': serializer.toJson<DateTime?>(serverUpdatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TranscriptRow copyWith({
    String? id,
    String? targetType,
    String? targetId,
    String? language,
    String? source,
    String? timelineJson,
    Value<String?> referenceId = const Value.absent(),
    String? label,
    Value<int?> trackIndex = const Value.absent(),
    Value<String?> syncStatus = const Value.absent(),
    Value<DateTime?> serverUpdatedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TranscriptRow(
    id: id ?? this.id,
    targetType: targetType ?? this.targetType,
    targetId: targetId ?? this.targetId,
    language: language ?? this.language,
    source: source ?? this.source,
    timelineJson: timelineJson ?? this.timelineJson,
    referenceId: referenceId.present ? referenceId.value : this.referenceId,
    label: label ?? this.label,
    trackIndex: trackIndex.present ? trackIndex.value : this.trackIndex,
    syncStatus: syncStatus.present ? syncStatus.value : this.syncStatus,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TranscriptRow copyWithCompanion(TranscriptsCompanion data) {
    return TranscriptRow(
      id: data.id.present ? data.id.value : this.id,
      targetType: data.targetType.present
          ? data.targetType.value
          : this.targetType,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      language: data.language.present ? data.language.value : this.language,
      source: data.source.present ? data.source.value : this.source,
      timelineJson: data.timelineJson.present
          ? data.timelineJson.value
          : this.timelineJson,
      referenceId: data.referenceId.present
          ? data.referenceId.value
          : this.referenceId,
      label: data.label.present ? data.label.value : this.label,
      trackIndex: data.trackIndex.present
          ? data.trackIndex.value
          : this.trackIndex,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TranscriptRow(')
          ..write('id: $id, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('language: $language, ')
          ..write('source: $source, ')
          ..write('timelineJson: $timelineJson, ')
          ..write('referenceId: $referenceId, ')
          ..write('label: $label, ')
          ..write('trackIndex: $trackIndex, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    targetType,
    targetId,
    language,
    source,
    timelineJson,
    referenceId,
    label,
    trackIndex,
    syncStatus,
    serverUpdatedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TranscriptRow &&
          other.id == this.id &&
          other.targetType == this.targetType &&
          other.targetId == this.targetId &&
          other.language == this.language &&
          other.source == this.source &&
          other.timelineJson == this.timelineJson &&
          other.referenceId == this.referenceId &&
          other.label == this.label &&
          other.trackIndex == this.trackIndex &&
          other.syncStatus == this.syncStatus &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TranscriptsCompanion extends UpdateCompanion<TranscriptRow> {
  final Value<String> id;
  final Value<String> targetType;
  final Value<String> targetId;
  final Value<String> language;
  final Value<String> source;
  final Value<String> timelineJson;
  final Value<String?> referenceId;
  final Value<String> label;
  final Value<int?> trackIndex;
  final Value<String?> syncStatus;
  final Value<DateTime?> serverUpdatedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TranscriptsCompanion({
    this.id = const Value.absent(),
    this.targetType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.language = const Value.absent(),
    this.source = const Value.absent(),
    this.timelineJson = const Value.absent(),
    this.referenceId = const Value.absent(),
    this.label = const Value.absent(),
    this.trackIndex = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TranscriptsCompanion.insert({
    required String id,
    required String targetType,
    required String targetId,
    required String language,
    required String source,
    required String timelineJson,
    this.referenceId = const Value.absent(),
    this.label = const Value.absent(),
    this.trackIndex = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       targetType = Value(targetType),
       targetId = Value(targetId),
       language = Value(language),
       source = Value(source),
       timelineJson = Value(timelineJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TranscriptRow> custom({
    Expression<String>? id,
    Expression<String>? targetType,
    Expression<String>? targetId,
    Expression<String>? language,
    Expression<String>? source,
    Expression<String>? timelineJson,
    Expression<String>? referenceId,
    Expression<String>? label,
    Expression<int>? trackIndex,
    Expression<String>? syncStatus,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
      if (language != null) 'language': language,
      if (source != null) 'source': source,
      if (timelineJson != null) 'timeline_json': timelineJson,
      if (referenceId != null) 'reference_id': referenceId,
      if (label != null) 'label': label,
      if (trackIndex != null) 'track_index': trackIndex,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TranscriptsCompanion copyWith({
    Value<String>? id,
    Value<String>? targetType,
    Value<String>? targetId,
    Value<String>? language,
    Value<String>? source,
    Value<String>? timelineJson,
    Value<String?>? referenceId,
    Value<String>? label,
    Value<int?>? trackIndex,
    Value<String?>? syncStatus,
    Value<DateTime?>? serverUpdatedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TranscriptsCompanion(
      id: id ?? this.id,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      language: language ?? this.language,
      source: source ?? this.source,
      timelineJson: timelineJson ?? this.timelineJson,
      referenceId: referenceId ?? this.referenceId,
      label: label ?? this.label,
      trackIndex: trackIndex ?? this.trackIndex,
      syncStatus: syncStatus ?? this.syncStatus,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
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
    if (targetType.present) {
      map['target_type'] = Variable<String>(targetType.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (timelineJson.present) {
      map['timeline_json'] = Variable<String>(timelineJson.value);
    }
    if (referenceId.present) {
      map['reference_id'] = Variable<String>(referenceId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (trackIndex.present) {
      map['track_index'] = Variable<int>(trackIndex.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
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
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('language: $language, ')
          ..write('source: $source, ')
          ..write('timelineJson: $timelineJson, ')
          ..write('referenceId: $referenceId, ')
          ..write('label: $label, ')
          ..write('trackIndex: $trackIndex, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TranscriptFetchStatesTable extends TranscriptFetchStates
    with TableInfo<$TranscriptFetchStatesTable, TranscriptFetchStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranscriptFetchStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _targetTypeMeta = const VerificationMeta(
    'targetType',
  );
  @override
  late final GeneratedColumn<String> targetType = GeneratedColumn<String>(
    'target_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastFetchedAtMeta = const VerificationMeta(
    'lastFetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastFetchedAt =
      GeneratedColumn<DateTime>(
        'last_fetched_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastStatusMeta = const VerificationMeta(
    'lastStatus',
  );
  @override
  late final GeneratedColumn<String> lastStatus = GeneratedColumn<String>(
    'last_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    targetType,
    targetId,
    lastFetchedAt,
    lastStatus,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transcript_fetch_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<TranscriptFetchStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('target_type')) {
      context.handle(
        _targetTypeMeta,
        targetType.isAcceptableOrUnknown(data['target_type']!, _targetTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_targetTypeMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('last_fetched_at')) {
      context.handle(
        _lastFetchedAtMeta,
        lastFetchedAt.isAcceptableOrUnknown(
          data['last_fetched_at']!,
          _lastFetchedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastFetchedAtMeta);
    }
    if (data.containsKey('last_status')) {
      context.handle(
        _lastStatusMeta,
        lastStatus.isAcceptableOrUnknown(data['last_status']!, _lastStatusMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {targetType, targetId};
  @override
  TranscriptFetchStateRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TranscriptFetchStateRow(
      targetType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_type'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      lastFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_fetched_at'],
      )!,
      lastStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_status'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $TranscriptFetchStatesTable createAlias(String alias) {
    return $TranscriptFetchStatesTable(attachedDatabase, alias);
  }
}

class TranscriptFetchStateRow extends DataClass
    implements Insertable<TranscriptFetchStateRow> {
  /// Dexie `TargetType`: `Video` | `Audio`.
  final String targetType;
  final String targetId;
  final DateTime lastFetchedAt;

  /// Terminal outcome: `success`, `empty`, or `error`.
  final String? lastStatus;

  /// User-facing or log-friendly error when [lastStatus] is `error`.
  final String? lastError;
  const TranscriptFetchStateRow({
    required this.targetType,
    required this.targetId,
    required this.lastFetchedAt,
    this.lastStatus,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['target_type'] = Variable<String>(targetType);
    map['target_id'] = Variable<String>(targetId);
    map['last_fetched_at'] = Variable<DateTime>(lastFetchedAt);
    if (!nullToAbsent || lastStatus != null) {
      map['last_status'] = Variable<String>(lastStatus);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  TranscriptFetchStatesCompanion toCompanion(bool nullToAbsent) {
    return TranscriptFetchStatesCompanion(
      targetType: Value(targetType),
      targetId: Value(targetId),
      lastFetchedAt: Value(lastFetchedAt),
      lastStatus: lastStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(lastStatus),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory TranscriptFetchStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TranscriptFetchStateRow(
      targetType: serializer.fromJson<String>(json['targetType']),
      targetId: serializer.fromJson<String>(json['targetId']),
      lastFetchedAt: serializer.fromJson<DateTime>(json['lastFetchedAt']),
      lastStatus: serializer.fromJson<String?>(json['lastStatus']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'targetType': serializer.toJson<String>(targetType),
      'targetId': serializer.toJson<String>(targetId),
      'lastFetchedAt': serializer.toJson<DateTime>(lastFetchedAt),
      'lastStatus': serializer.toJson<String?>(lastStatus),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  TranscriptFetchStateRow copyWith({
    String? targetType,
    String? targetId,
    DateTime? lastFetchedAt,
    Value<String?> lastStatus = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => TranscriptFetchStateRow(
    targetType: targetType ?? this.targetType,
    targetId: targetId ?? this.targetId,
    lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
    lastStatus: lastStatus.present ? lastStatus.value : this.lastStatus,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  TranscriptFetchStateRow copyWithCompanion(
    TranscriptFetchStatesCompanion data,
  ) {
    return TranscriptFetchStateRow(
      targetType: data.targetType.present
          ? data.targetType.value
          : this.targetType,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      lastFetchedAt: data.lastFetchedAt.present
          ? data.lastFetchedAt.value
          : this.lastFetchedAt,
      lastStatus: data.lastStatus.present
          ? data.lastStatus.value
          : this.lastStatus,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TranscriptFetchStateRow(')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('lastFetchedAt: $lastFetchedAt, ')
          ..write('lastStatus: $lastStatus, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(targetType, targetId, lastFetchedAt, lastStatus, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TranscriptFetchStateRow &&
          other.targetType == this.targetType &&
          other.targetId == this.targetId &&
          other.lastFetchedAt == this.lastFetchedAt &&
          other.lastStatus == this.lastStatus &&
          other.lastError == this.lastError);
}

class TranscriptFetchStatesCompanion
    extends UpdateCompanion<TranscriptFetchStateRow> {
  final Value<String> targetType;
  final Value<String> targetId;
  final Value<DateTime> lastFetchedAt;
  final Value<String?> lastStatus;
  final Value<String?> lastError;
  final Value<int> rowid;
  const TranscriptFetchStatesCompanion({
    this.targetType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.lastFetchedAt = const Value.absent(),
    this.lastStatus = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TranscriptFetchStatesCompanion.insert({
    required String targetType,
    required String targetId,
    required DateTime lastFetchedAt,
    this.lastStatus = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : targetType = Value(targetType),
       targetId = Value(targetId),
       lastFetchedAt = Value(lastFetchedAt);
  static Insertable<TranscriptFetchStateRow> custom({
    Expression<String>? targetType,
    Expression<String>? targetId,
    Expression<DateTime>? lastFetchedAt,
    Expression<String>? lastStatus,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
      if (lastFetchedAt != null) 'last_fetched_at': lastFetchedAt,
      if (lastStatus != null) 'last_status': lastStatus,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TranscriptFetchStatesCompanion copyWith({
    Value<String>? targetType,
    Value<String>? targetId,
    Value<DateTime>? lastFetchedAt,
    Value<String?>? lastStatus,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return TranscriptFetchStatesCompanion(
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      lastStatus: lastStatus ?? this.lastStatus,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (targetType.present) {
      map['target_type'] = Variable<String>(targetType.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (lastFetchedAt.present) {
      map['last_fetched_at'] = Variable<DateTime>(lastFetchedAt.value);
    }
    if (lastStatus.present) {
      map['last_status'] = Variable<String>(lastStatus.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranscriptFetchStatesCompanion(')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('lastFetchedAt: $lastFetchedAt, ')
          ..write('lastStatus: $lastStatus, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EchoSessionsTable extends EchoSessions
    with TableInfo<$EchoSessionsTable, EchoSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EchoSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetTypeMeta = const VerificationMeta(
    'targetType',
  );
  @override
  late final GeneratedColumn<String> targetType = GeneratedColumn<String>(
    'target_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _currentTimeMsMeta = const VerificationMeta(
    'currentTimeMs',
  );
  @override
  late final GeneratedColumn<int> currentTimeMs = GeneratedColumn<int>(
    'current_time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _playbackRateMeta = const VerificationMeta(
    'playbackRate',
  );
  @override
  late final GeneratedColumn<double> playbackRate = GeneratedColumn<double>(
    'playback_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _volumeMeta = const VerificationMeta('volume');
  @override
  late final GeneratedColumn<double> volume = GeneratedColumn<double>(
    'volume',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _echoStartMsMeta = const VerificationMeta(
    'echoStartMs',
  );
  @override
  late final GeneratedColumn<int> echoStartMs = GeneratedColumn<int>(
    'echo_start_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _echoEndMsMeta = const VerificationMeta(
    'echoEndMs',
  );
  @override
  late final GeneratedColumn<int> echoEndMs = GeneratedColumn<int>(
    'echo_end_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transcriptIdMeta = const VerificationMeta(
    'transcriptId',
  );
  @override
  late final GeneratedColumn<String> transcriptId = GeneratedColumn<String>(
    'transcript_id',
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
  static const VerificationMeta _recordingsCountMeta = const VerificationMeta(
    'recordingsCount',
  );
  @override
  late final GeneratedColumn<int> recordingsCount = GeneratedColumn<int>(
    'recordings_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _recordingsDurationMsMeta =
      const VerificationMeta('recordingsDurationMs');
  @override
  late final GeneratedColumn<int> recordingsDurationMs = GeneratedColumn<int>(
    'recordings_duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastRecordingAtMeta = const VerificationMeta(
    'lastRecordingAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastRecordingAt =
      GeneratedColumn<DateTime>(
        'last_recording_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
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
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
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
    targetType,
    targetId,
    language,
    currentTimeMs,
    playbackRate,
    volume,
    echoStartMs,
    echoEndMs,
    transcriptId,
    secondaryTranscriptId,
    recordingsCount,
    recordingsDurationMs,
    lastRecordingAt,
    currentSegmentIndex,
    echoActive,
    echoStartLine,
    echoEndLine,
    startedAt,
    lastActiveAt,
    completedAt,
    syncStatus,
    serverUpdatedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'echo_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<EchoSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('target_type')) {
      context.handle(
        _targetTypeMeta,
        targetType.isAcceptableOrUnknown(data['target_type']!, _targetTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_targetTypeMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('current_time_ms')) {
      context.handle(
        _currentTimeMsMeta,
        currentTimeMs.isAcceptableOrUnknown(
          data['current_time_ms']!,
          _currentTimeMsMeta,
        ),
      );
    }
    if (data.containsKey('playback_rate')) {
      context.handle(
        _playbackRateMeta,
        playbackRate.isAcceptableOrUnknown(
          data['playback_rate']!,
          _playbackRateMeta,
        ),
      );
    }
    if (data.containsKey('volume')) {
      context.handle(
        _volumeMeta,
        volume.isAcceptableOrUnknown(data['volume']!, _volumeMeta),
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
    if (data.containsKey('transcript_id')) {
      context.handle(
        _transcriptIdMeta,
        transcriptId.isAcceptableOrUnknown(
          data['transcript_id']!,
          _transcriptIdMeta,
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
    if (data.containsKey('recordings_count')) {
      context.handle(
        _recordingsCountMeta,
        recordingsCount.isAcceptableOrUnknown(
          data['recordings_count']!,
          _recordingsCountMeta,
        ),
      );
    }
    if (data.containsKey('recordings_duration_ms')) {
      context.handle(
        _recordingsDurationMsMeta,
        recordingsDurationMs.isAcceptableOrUnknown(
          data['recordings_duration_ms']!,
          _recordingsDurationMsMeta,
        ),
      );
    }
    if (data.containsKey('last_recording_at')) {
      context.handle(
        _lastRecordingAtMeta,
        lastRecordingAt.isAcceptableOrUnknown(
          data['last_recording_at']!,
          _lastRecordingAtMeta,
        ),
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
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
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
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
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
  EchoSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EchoSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      targetType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_type'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      currentTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_time_ms'],
      )!,
      playbackRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}playback_rate'],
      )!,
      volume: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}volume'],
      )!,
      echoStartMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}echo_start_ms'],
      ),
      echoEndMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}echo_end_ms'],
      ),
      transcriptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcript_id'],
      ),
      secondaryTranscriptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secondary_transcript_id'],
      ),
      recordingsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recordings_count'],
      )!,
      recordingsDurationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recordings_duration_ms'],
      )!,
      lastRecordingAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_recording_at'],
      ),
      currentSegmentIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_segment_index'],
      )!,
      echoActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}echo_active'],
      )!,
      echoStartLine: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}echo_start_line'],
      )!,
      echoEndLine: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}echo_end_line'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      lastActiveAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_active_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      ),
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_updated_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EchoSessionsTable createAlias(String alias) {
    return $EchoSessionsTable(attachedDatabase, alias);
  }
}

class EchoSessionRow extends DataClass implements Insertable<EchoSessionRow> {
  final String id;
  final String targetType;
  final String targetId;
  final String language;
  final int currentTimeMs;
  final double playbackRate;
  final double volume;
  final int? echoStartMs;
  final int? echoEndMs;

  /// Primary transcript (weapp `transcriptId`).
  final String? transcriptId;
  final String? secondaryTranscriptId;
  final int recordingsCount;
  final int recordingsDurationMs;
  final DateTime? lastRecordingAt;
  final int currentSegmentIndex;
  final bool echoActive;
  final int echoStartLine;
  final int echoEndLine;
  final DateTime startedAt;
  final DateTime lastActiveAt;
  final DateTime? completedAt;
  final String? syncStatus;
  final DateTime? serverUpdatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const EchoSessionRow({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.language,
    required this.currentTimeMs,
    required this.playbackRate,
    required this.volume,
    this.echoStartMs,
    this.echoEndMs,
    this.transcriptId,
    this.secondaryTranscriptId,
    required this.recordingsCount,
    required this.recordingsDurationMs,
    this.lastRecordingAt,
    required this.currentSegmentIndex,
    required this.echoActive,
    required this.echoStartLine,
    required this.echoEndLine,
    required this.startedAt,
    required this.lastActiveAt,
    this.completedAt,
    this.syncStatus,
    this.serverUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['target_type'] = Variable<String>(targetType);
    map['target_id'] = Variable<String>(targetId);
    map['language'] = Variable<String>(language);
    map['current_time_ms'] = Variable<int>(currentTimeMs);
    map['playback_rate'] = Variable<double>(playbackRate);
    map['volume'] = Variable<double>(volume);
    if (!nullToAbsent || echoStartMs != null) {
      map['echo_start_ms'] = Variable<int>(echoStartMs);
    }
    if (!nullToAbsent || echoEndMs != null) {
      map['echo_end_ms'] = Variable<int>(echoEndMs);
    }
    if (!nullToAbsent || transcriptId != null) {
      map['transcript_id'] = Variable<String>(transcriptId);
    }
    if (!nullToAbsent || secondaryTranscriptId != null) {
      map['secondary_transcript_id'] = Variable<String>(secondaryTranscriptId);
    }
    map['recordings_count'] = Variable<int>(recordingsCount);
    map['recordings_duration_ms'] = Variable<int>(recordingsDurationMs);
    if (!nullToAbsent || lastRecordingAt != null) {
      map['last_recording_at'] = Variable<DateTime>(lastRecordingAt);
    }
    map['current_segment_index'] = Variable<int>(currentSegmentIndex);
    map['echo_active'] = Variable<bool>(echoActive);
    map['echo_start_line'] = Variable<int>(echoStartLine);
    map['echo_end_line'] = Variable<int>(echoEndLine);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['last_active_at'] = Variable<DateTime>(lastActiveAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || syncStatus != null) {
      map['sync_status'] = Variable<String>(syncStatus);
    }
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EchoSessionsCompanion toCompanion(bool nullToAbsent) {
    return EchoSessionsCompanion(
      id: Value(id),
      targetType: Value(targetType),
      targetId: Value(targetId),
      language: Value(language),
      currentTimeMs: Value(currentTimeMs),
      playbackRate: Value(playbackRate),
      volume: Value(volume),
      echoStartMs: echoStartMs == null && nullToAbsent
          ? const Value.absent()
          : Value(echoStartMs),
      echoEndMs: echoEndMs == null && nullToAbsent
          ? const Value.absent()
          : Value(echoEndMs),
      transcriptId: transcriptId == null && nullToAbsent
          ? const Value.absent()
          : Value(transcriptId),
      secondaryTranscriptId: secondaryTranscriptId == null && nullToAbsent
          ? const Value.absent()
          : Value(secondaryTranscriptId),
      recordingsCount: Value(recordingsCount),
      recordingsDurationMs: Value(recordingsDurationMs),
      lastRecordingAt: lastRecordingAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRecordingAt),
      currentSegmentIndex: Value(currentSegmentIndex),
      echoActive: Value(echoActive),
      echoStartLine: Value(echoStartLine),
      echoEndLine: Value(echoEndLine),
      startedAt: Value(startedAt),
      lastActiveAt: Value(lastActiveAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      syncStatus: syncStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(syncStatus),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory EchoSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EchoSessionRow(
      id: serializer.fromJson<String>(json['id']),
      targetType: serializer.fromJson<String>(json['targetType']),
      targetId: serializer.fromJson<String>(json['targetId']),
      language: serializer.fromJson<String>(json['language']),
      currentTimeMs: serializer.fromJson<int>(json['currentTimeMs']),
      playbackRate: serializer.fromJson<double>(json['playbackRate']),
      volume: serializer.fromJson<double>(json['volume']),
      echoStartMs: serializer.fromJson<int?>(json['echoStartMs']),
      echoEndMs: serializer.fromJson<int?>(json['echoEndMs']),
      transcriptId: serializer.fromJson<String?>(json['transcriptId']),
      secondaryTranscriptId: serializer.fromJson<String?>(
        json['secondaryTranscriptId'],
      ),
      recordingsCount: serializer.fromJson<int>(json['recordingsCount']),
      recordingsDurationMs: serializer.fromJson<int>(
        json['recordingsDurationMs'],
      ),
      lastRecordingAt: serializer.fromJson<DateTime?>(json['lastRecordingAt']),
      currentSegmentIndex: serializer.fromJson<int>(
        json['currentSegmentIndex'],
      ),
      echoActive: serializer.fromJson<bool>(json['echoActive']),
      echoStartLine: serializer.fromJson<int>(json['echoStartLine']),
      echoEndLine: serializer.fromJson<int>(json['echoEndLine']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      lastActiveAt: serializer.fromJson<DateTime>(json['lastActiveAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      syncStatus: serializer.fromJson<String?>(json['syncStatus']),
      serverUpdatedAt: serializer.fromJson<DateTime?>(json['serverUpdatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'targetType': serializer.toJson<String>(targetType),
      'targetId': serializer.toJson<String>(targetId),
      'language': serializer.toJson<String>(language),
      'currentTimeMs': serializer.toJson<int>(currentTimeMs),
      'playbackRate': serializer.toJson<double>(playbackRate),
      'volume': serializer.toJson<double>(volume),
      'echoStartMs': serializer.toJson<int?>(echoStartMs),
      'echoEndMs': serializer.toJson<int?>(echoEndMs),
      'transcriptId': serializer.toJson<String?>(transcriptId),
      'secondaryTranscriptId': serializer.toJson<String?>(
        secondaryTranscriptId,
      ),
      'recordingsCount': serializer.toJson<int>(recordingsCount),
      'recordingsDurationMs': serializer.toJson<int>(recordingsDurationMs),
      'lastRecordingAt': serializer.toJson<DateTime?>(lastRecordingAt),
      'currentSegmentIndex': serializer.toJson<int>(currentSegmentIndex),
      'echoActive': serializer.toJson<bool>(echoActive),
      'echoStartLine': serializer.toJson<int>(echoStartLine),
      'echoEndLine': serializer.toJson<int>(echoEndLine),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'lastActiveAt': serializer.toJson<DateTime>(lastActiveAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'syncStatus': serializer.toJson<String?>(syncStatus),
      'serverUpdatedAt': serializer.toJson<DateTime?>(serverUpdatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EchoSessionRow copyWith({
    String? id,
    String? targetType,
    String? targetId,
    String? language,
    int? currentTimeMs,
    double? playbackRate,
    double? volume,
    Value<int?> echoStartMs = const Value.absent(),
    Value<int?> echoEndMs = const Value.absent(),
    Value<String?> transcriptId = const Value.absent(),
    Value<String?> secondaryTranscriptId = const Value.absent(),
    int? recordingsCount,
    int? recordingsDurationMs,
    Value<DateTime?> lastRecordingAt = const Value.absent(),
    int? currentSegmentIndex,
    bool? echoActive,
    int? echoStartLine,
    int? echoEndLine,
    DateTime? startedAt,
    DateTime? lastActiveAt,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> syncStatus = const Value.absent(),
    Value<DateTime?> serverUpdatedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => EchoSessionRow(
    id: id ?? this.id,
    targetType: targetType ?? this.targetType,
    targetId: targetId ?? this.targetId,
    language: language ?? this.language,
    currentTimeMs: currentTimeMs ?? this.currentTimeMs,
    playbackRate: playbackRate ?? this.playbackRate,
    volume: volume ?? this.volume,
    echoStartMs: echoStartMs.present ? echoStartMs.value : this.echoStartMs,
    echoEndMs: echoEndMs.present ? echoEndMs.value : this.echoEndMs,
    transcriptId: transcriptId.present ? transcriptId.value : this.transcriptId,
    secondaryTranscriptId: secondaryTranscriptId.present
        ? secondaryTranscriptId.value
        : this.secondaryTranscriptId,
    recordingsCount: recordingsCount ?? this.recordingsCount,
    recordingsDurationMs: recordingsDurationMs ?? this.recordingsDurationMs,
    lastRecordingAt: lastRecordingAt.present
        ? lastRecordingAt.value
        : this.lastRecordingAt,
    currentSegmentIndex: currentSegmentIndex ?? this.currentSegmentIndex,
    echoActive: echoActive ?? this.echoActive,
    echoStartLine: echoStartLine ?? this.echoStartLine,
    echoEndLine: echoEndLine ?? this.echoEndLine,
    startedAt: startedAt ?? this.startedAt,
    lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    syncStatus: syncStatus.present ? syncStatus.value : this.syncStatus,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EchoSessionRow copyWithCompanion(EchoSessionsCompanion data) {
    return EchoSessionRow(
      id: data.id.present ? data.id.value : this.id,
      targetType: data.targetType.present
          ? data.targetType.value
          : this.targetType,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      language: data.language.present ? data.language.value : this.language,
      currentTimeMs: data.currentTimeMs.present
          ? data.currentTimeMs.value
          : this.currentTimeMs,
      playbackRate: data.playbackRate.present
          ? data.playbackRate.value
          : this.playbackRate,
      volume: data.volume.present ? data.volume.value : this.volume,
      echoStartMs: data.echoStartMs.present
          ? data.echoStartMs.value
          : this.echoStartMs,
      echoEndMs: data.echoEndMs.present ? data.echoEndMs.value : this.echoEndMs,
      transcriptId: data.transcriptId.present
          ? data.transcriptId.value
          : this.transcriptId,
      secondaryTranscriptId: data.secondaryTranscriptId.present
          ? data.secondaryTranscriptId.value
          : this.secondaryTranscriptId,
      recordingsCount: data.recordingsCount.present
          ? data.recordingsCount.value
          : this.recordingsCount,
      recordingsDurationMs: data.recordingsDurationMs.present
          ? data.recordingsDurationMs.value
          : this.recordingsDurationMs,
      lastRecordingAt: data.lastRecordingAt.present
          ? data.lastRecordingAt.value
          : this.lastRecordingAt,
      currentSegmentIndex: data.currentSegmentIndex.present
          ? data.currentSegmentIndex.value
          : this.currentSegmentIndex,
      echoActive: data.echoActive.present
          ? data.echoActive.value
          : this.echoActive,
      echoStartLine: data.echoStartLine.present
          ? data.echoStartLine.value
          : this.echoStartLine,
      echoEndLine: data.echoEndLine.present
          ? data.echoEndLine.value
          : this.echoEndLine,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      lastActiveAt: data.lastActiveAt.present
          ? data.lastActiveAt.value
          : this.lastActiveAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EchoSessionRow(')
          ..write('id: $id, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('language: $language, ')
          ..write('currentTimeMs: $currentTimeMs, ')
          ..write('playbackRate: $playbackRate, ')
          ..write('volume: $volume, ')
          ..write('echoStartMs: $echoStartMs, ')
          ..write('echoEndMs: $echoEndMs, ')
          ..write('transcriptId: $transcriptId, ')
          ..write('secondaryTranscriptId: $secondaryTranscriptId, ')
          ..write('recordingsCount: $recordingsCount, ')
          ..write('recordingsDurationMs: $recordingsDurationMs, ')
          ..write('lastRecordingAt: $lastRecordingAt, ')
          ..write('currentSegmentIndex: $currentSegmentIndex, ')
          ..write('echoActive: $echoActive, ')
          ..write('echoStartLine: $echoStartLine, ')
          ..write('echoEndLine: $echoEndLine, ')
          ..write('startedAt: $startedAt, ')
          ..write('lastActiveAt: $lastActiveAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    targetType,
    targetId,
    language,
    currentTimeMs,
    playbackRate,
    volume,
    echoStartMs,
    echoEndMs,
    transcriptId,
    secondaryTranscriptId,
    recordingsCount,
    recordingsDurationMs,
    lastRecordingAt,
    currentSegmentIndex,
    echoActive,
    echoStartLine,
    echoEndLine,
    startedAt,
    lastActiveAt,
    completedAt,
    syncStatus,
    serverUpdatedAt,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EchoSessionRow &&
          other.id == this.id &&
          other.targetType == this.targetType &&
          other.targetId == this.targetId &&
          other.language == this.language &&
          other.currentTimeMs == this.currentTimeMs &&
          other.playbackRate == this.playbackRate &&
          other.volume == this.volume &&
          other.echoStartMs == this.echoStartMs &&
          other.echoEndMs == this.echoEndMs &&
          other.transcriptId == this.transcriptId &&
          other.secondaryTranscriptId == this.secondaryTranscriptId &&
          other.recordingsCount == this.recordingsCount &&
          other.recordingsDurationMs == this.recordingsDurationMs &&
          other.lastRecordingAt == this.lastRecordingAt &&
          other.currentSegmentIndex == this.currentSegmentIndex &&
          other.echoActive == this.echoActive &&
          other.echoStartLine == this.echoStartLine &&
          other.echoEndLine == this.echoEndLine &&
          other.startedAt == this.startedAt &&
          other.lastActiveAt == this.lastActiveAt &&
          other.completedAt == this.completedAt &&
          other.syncStatus == this.syncStatus &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EchoSessionsCompanion extends UpdateCompanion<EchoSessionRow> {
  final Value<String> id;
  final Value<String> targetType;
  final Value<String> targetId;
  final Value<String> language;
  final Value<int> currentTimeMs;
  final Value<double> playbackRate;
  final Value<double> volume;
  final Value<int?> echoStartMs;
  final Value<int?> echoEndMs;
  final Value<String?> transcriptId;
  final Value<String?> secondaryTranscriptId;
  final Value<int> recordingsCount;
  final Value<int> recordingsDurationMs;
  final Value<DateTime?> lastRecordingAt;
  final Value<int> currentSegmentIndex;
  final Value<bool> echoActive;
  final Value<int> echoStartLine;
  final Value<int> echoEndLine;
  final Value<DateTime> startedAt;
  final Value<DateTime> lastActiveAt;
  final Value<DateTime?> completedAt;
  final Value<String?> syncStatus;
  final Value<DateTime?> serverUpdatedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EchoSessionsCompanion({
    this.id = const Value.absent(),
    this.targetType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.language = const Value.absent(),
    this.currentTimeMs = const Value.absent(),
    this.playbackRate = const Value.absent(),
    this.volume = const Value.absent(),
    this.echoStartMs = const Value.absent(),
    this.echoEndMs = const Value.absent(),
    this.transcriptId = const Value.absent(),
    this.secondaryTranscriptId = const Value.absent(),
    this.recordingsCount = const Value.absent(),
    this.recordingsDurationMs = const Value.absent(),
    this.lastRecordingAt = const Value.absent(),
    this.currentSegmentIndex = const Value.absent(),
    this.echoActive = const Value.absent(),
    this.echoStartLine = const Value.absent(),
    this.echoEndLine = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.lastActiveAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EchoSessionsCompanion.insert({
    required String id,
    required String targetType,
    required String targetId,
    this.language = const Value.absent(),
    this.currentTimeMs = const Value.absent(),
    this.playbackRate = const Value.absent(),
    this.volume = const Value.absent(),
    this.echoStartMs = const Value.absent(),
    this.echoEndMs = const Value.absent(),
    this.transcriptId = const Value.absent(),
    this.secondaryTranscriptId = const Value.absent(),
    this.recordingsCount = const Value.absent(),
    this.recordingsDurationMs = const Value.absent(),
    this.lastRecordingAt = const Value.absent(),
    this.currentSegmentIndex = const Value.absent(),
    this.echoActive = const Value.absent(),
    this.echoStartLine = const Value.absent(),
    this.echoEndLine = const Value.absent(),
    required DateTime startedAt,
    required DateTime lastActiveAt,
    this.completedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       targetType = Value(targetType),
       targetId = Value(targetId),
       startedAt = Value(startedAt),
       lastActiveAt = Value(lastActiveAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<EchoSessionRow> custom({
    Expression<String>? id,
    Expression<String>? targetType,
    Expression<String>? targetId,
    Expression<String>? language,
    Expression<int>? currentTimeMs,
    Expression<double>? playbackRate,
    Expression<double>? volume,
    Expression<int>? echoStartMs,
    Expression<int>? echoEndMs,
    Expression<String>? transcriptId,
    Expression<String>? secondaryTranscriptId,
    Expression<int>? recordingsCount,
    Expression<int>? recordingsDurationMs,
    Expression<DateTime>? lastRecordingAt,
    Expression<int>? currentSegmentIndex,
    Expression<bool>? echoActive,
    Expression<int>? echoStartLine,
    Expression<int>? echoEndLine,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? lastActiveAt,
    Expression<DateTime>? completedAt,
    Expression<String>? syncStatus,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
      if (language != null) 'language': language,
      if (currentTimeMs != null) 'current_time_ms': currentTimeMs,
      if (playbackRate != null) 'playback_rate': playbackRate,
      if (volume != null) 'volume': volume,
      if (echoStartMs != null) 'echo_start_ms': echoStartMs,
      if (echoEndMs != null) 'echo_end_ms': echoEndMs,
      if (transcriptId != null) 'transcript_id': transcriptId,
      if (secondaryTranscriptId != null)
        'secondary_transcript_id': secondaryTranscriptId,
      if (recordingsCount != null) 'recordings_count': recordingsCount,
      if (recordingsDurationMs != null)
        'recordings_duration_ms': recordingsDurationMs,
      if (lastRecordingAt != null) 'last_recording_at': lastRecordingAt,
      if (currentSegmentIndex != null)
        'current_segment_index': currentSegmentIndex,
      if (echoActive != null) 'echo_active': echoActive,
      if (echoStartLine != null) 'echo_start_line': echoStartLine,
      if (echoEndLine != null) 'echo_end_line': echoEndLine,
      if (startedAt != null) 'started_at': startedAt,
      if (lastActiveAt != null) 'last_active_at': lastActiveAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EchoSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? targetType,
    Value<String>? targetId,
    Value<String>? language,
    Value<int>? currentTimeMs,
    Value<double>? playbackRate,
    Value<double>? volume,
    Value<int?>? echoStartMs,
    Value<int?>? echoEndMs,
    Value<String?>? transcriptId,
    Value<String?>? secondaryTranscriptId,
    Value<int>? recordingsCount,
    Value<int>? recordingsDurationMs,
    Value<DateTime?>? lastRecordingAt,
    Value<int>? currentSegmentIndex,
    Value<bool>? echoActive,
    Value<int>? echoStartLine,
    Value<int>? echoEndLine,
    Value<DateTime>? startedAt,
    Value<DateTime>? lastActiveAt,
    Value<DateTime?>? completedAt,
    Value<String?>? syncStatus,
    Value<DateTime?>? serverUpdatedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return EchoSessionsCompanion(
      id: id ?? this.id,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      language: language ?? this.language,
      currentTimeMs: currentTimeMs ?? this.currentTimeMs,
      playbackRate: playbackRate ?? this.playbackRate,
      volume: volume ?? this.volume,
      echoStartMs: echoStartMs ?? this.echoStartMs,
      echoEndMs: echoEndMs ?? this.echoEndMs,
      transcriptId: transcriptId ?? this.transcriptId,
      secondaryTranscriptId:
          secondaryTranscriptId ?? this.secondaryTranscriptId,
      recordingsCount: recordingsCount ?? this.recordingsCount,
      recordingsDurationMs: recordingsDurationMs ?? this.recordingsDurationMs,
      lastRecordingAt: lastRecordingAt ?? this.lastRecordingAt,
      currentSegmentIndex: currentSegmentIndex ?? this.currentSegmentIndex,
      echoActive: echoActive ?? this.echoActive,
      echoStartLine: echoStartLine ?? this.echoStartLine,
      echoEndLine: echoEndLine ?? this.echoEndLine,
      startedAt: startedAt ?? this.startedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      completedAt: completedAt ?? this.completedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
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
    if (targetType.present) {
      map['target_type'] = Variable<String>(targetType.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (currentTimeMs.present) {
      map['current_time_ms'] = Variable<int>(currentTimeMs.value);
    }
    if (playbackRate.present) {
      map['playback_rate'] = Variable<double>(playbackRate.value);
    }
    if (volume.present) {
      map['volume'] = Variable<double>(volume.value);
    }
    if (echoStartMs.present) {
      map['echo_start_ms'] = Variable<int>(echoStartMs.value);
    }
    if (echoEndMs.present) {
      map['echo_end_ms'] = Variable<int>(echoEndMs.value);
    }
    if (transcriptId.present) {
      map['transcript_id'] = Variable<String>(transcriptId.value);
    }
    if (secondaryTranscriptId.present) {
      map['secondary_transcript_id'] = Variable<String>(
        secondaryTranscriptId.value,
      );
    }
    if (recordingsCount.present) {
      map['recordings_count'] = Variable<int>(recordingsCount.value);
    }
    if (recordingsDurationMs.present) {
      map['recordings_duration_ms'] = Variable<int>(recordingsDurationMs.value);
    }
    if (lastRecordingAt.present) {
      map['last_recording_at'] = Variable<DateTime>(lastRecordingAt.value);
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
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (lastActiveAt.present) {
      map['last_active_at'] = Variable<DateTime>(lastActiveAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
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
    return (StringBuffer('EchoSessionsCompanion(')
          ..write('id: $id, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('language: $language, ')
          ..write('currentTimeMs: $currentTimeMs, ')
          ..write('playbackRate: $playbackRate, ')
          ..write('volume: $volume, ')
          ..write('echoStartMs: $echoStartMs, ')
          ..write('echoEndMs: $echoEndMs, ')
          ..write('transcriptId: $transcriptId, ')
          ..write('secondaryTranscriptId: $secondaryTranscriptId, ')
          ..write('recordingsCount: $recordingsCount, ')
          ..write('recordingsDurationMs: $recordingsDurationMs, ')
          ..write('lastRecordingAt: $lastRecordingAt, ')
          ..write('currentSegmentIndex: $currentSegmentIndex, ')
          ..write('echoActive: $echoActive, ')
          ..write('echoStartLine: $echoStartLine, ')
          ..write('echoEndLine: $echoEndLine, ')
          ..write('startedAt: $startedAt, ')
          ..write('lastActiveAt: $lastActiveAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecordingsTable extends Recordings
    with TableInfo<$RecordingsTable, RecordingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetTypeMeta = const VerificationMeta(
    'targetType',
  );
  @override
  late final GeneratedColumn<String> targetType = GeneratedColumn<String>(
    'target_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceStartMeta = const VerificationMeta(
    'referenceStart',
  );
  @override
  late final GeneratedColumn<int> referenceStart = GeneratedColumn<int>(
    'reference_start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceDurationMeta = const VerificationMeta(
    'referenceDuration',
  );
  @override
  late final GeneratedColumn<int> referenceDuration = GeneratedColumn<int>(
    'reference_duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceTextMeta = const VerificationMeta(
    'referenceText',
  );
  @override
  late final GeneratedColumn<String> referenceText = GeneratedColumn<String>(
    'reference_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _md5Meta = const VerificationMeta('md5');
  @override
  late final GeneratedColumn<String> md5 = GeneratedColumn<String>(
    'md5',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioUrlMeta = const VerificationMeta(
    'audioUrl',
  );
  @override
  late final GeneratedColumn<String> audioUrl = GeneratedColumn<String>(
    'audio_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pronunciationScoreMeta =
      const VerificationMeta('pronunciationScore');
  @override
  late final GeneratedColumn<int> pronunciationScore = GeneratedColumn<int>(
    'pronunciation_score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assessmentJsonMeta = const VerificationMeta(
    'assessmentJson',
  );
  @override
  late final GeneratedColumn<String> assessmentJson = GeneratedColumn<String>(
    'assessment_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
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
    targetType,
    targetId,
    referenceStart,
    referenceDuration,
    referenceText,
    language,
    duration,
    md5,
    audioUrl,
    pronunciationScore,
    assessmentJson,
    localPath,
    syncStatus,
    serverUpdatedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recordings';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('target_type')) {
      context.handle(
        _targetTypeMeta,
        targetType.isAcceptableOrUnknown(data['target_type']!, _targetTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_targetTypeMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('reference_start')) {
      context.handle(
        _referenceStartMeta,
        referenceStart.isAcceptableOrUnknown(
          data['reference_start']!,
          _referenceStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceStartMeta);
    }
    if (data.containsKey('reference_duration')) {
      context.handle(
        _referenceDurationMeta,
        referenceDuration.isAcceptableOrUnknown(
          data['reference_duration']!,
          _referenceDurationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceDurationMeta);
    }
    if (data.containsKey('reference_text')) {
      context.handle(
        _referenceTextMeta,
        referenceText.isAcceptableOrUnknown(
          data['reference_text']!,
          _referenceTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceTextMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('md5')) {
      context.handle(
        _md5Meta,
        md5.isAcceptableOrUnknown(data['md5']!, _md5Meta),
      );
    }
    if (data.containsKey('audio_url')) {
      context.handle(
        _audioUrlMeta,
        audioUrl.isAcceptableOrUnknown(data['audio_url']!, _audioUrlMeta),
      );
    }
    if (data.containsKey('pronunciation_score')) {
      context.handle(
        _pronunciationScoreMeta,
        pronunciationScore.isAcceptableOrUnknown(
          data['pronunciation_score']!,
          _pronunciationScoreMeta,
        ),
      );
    }
    if (data.containsKey('assessment_json')) {
      context.handle(
        _assessmentJsonMeta,
        assessmentJson.isAcceptableOrUnknown(
          data['assessment_json']!,
          _assessmentJsonMeta,
        ),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
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
  RecordingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      targetType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_type'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      referenceStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reference_start'],
      )!,
      referenceDuration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reference_duration'],
      )!,
      referenceText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_text'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      )!,
      md5: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}md5'],
      ),
      audioUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_url'],
      ),
      pronunciationScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pronunciation_score'],
      ),
      assessmentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assessment_json'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      ),
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_updated_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RecordingsTable createAlias(String alias) {
    return $RecordingsTable(attachedDatabase, alias);
  }
}

class RecordingRow extends DataClass implements Insertable<RecordingRow> {
  final String id;
  final String targetType;
  final String targetId;
  final int referenceStart;
  final int referenceDuration;
  final String referenceText;
  final String language;
  final int duration;
  final String? md5;
  final String? audioUrl;
  final int? pronunciationScore;
  final String? assessmentJson;
  final String? localPath;
  final String? syncStatus;
  final DateTime? serverUpdatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const RecordingRow({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.referenceStart,
    required this.referenceDuration,
    required this.referenceText,
    required this.language,
    required this.duration,
    this.md5,
    this.audioUrl,
    this.pronunciationScore,
    this.assessmentJson,
    this.localPath,
    this.syncStatus,
    this.serverUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['target_type'] = Variable<String>(targetType);
    map['target_id'] = Variable<String>(targetId);
    map['reference_start'] = Variable<int>(referenceStart);
    map['reference_duration'] = Variable<int>(referenceDuration);
    map['reference_text'] = Variable<String>(referenceText);
    map['language'] = Variable<String>(language);
    map['duration'] = Variable<int>(duration);
    if (!nullToAbsent || md5 != null) {
      map['md5'] = Variable<String>(md5);
    }
    if (!nullToAbsent || audioUrl != null) {
      map['audio_url'] = Variable<String>(audioUrl);
    }
    if (!nullToAbsent || pronunciationScore != null) {
      map['pronunciation_score'] = Variable<int>(pronunciationScore);
    }
    if (!nullToAbsent || assessmentJson != null) {
      map['assessment_json'] = Variable<String>(assessmentJson);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || syncStatus != null) {
      map['sync_status'] = Variable<String>(syncStatus);
    }
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RecordingsCompanion toCompanion(bool nullToAbsent) {
    return RecordingsCompanion(
      id: Value(id),
      targetType: Value(targetType),
      targetId: Value(targetId),
      referenceStart: Value(referenceStart),
      referenceDuration: Value(referenceDuration),
      referenceText: Value(referenceText),
      language: Value(language),
      duration: Value(duration),
      md5: md5 == null && nullToAbsent ? const Value.absent() : Value(md5),
      audioUrl: audioUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(audioUrl),
      pronunciationScore: pronunciationScore == null && nullToAbsent
          ? const Value.absent()
          : Value(pronunciationScore),
      assessmentJson: assessmentJson == null && nullToAbsent
          ? const Value.absent()
          : Value(assessmentJson),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      syncStatus: syncStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(syncStatus),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RecordingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordingRow(
      id: serializer.fromJson<String>(json['id']),
      targetType: serializer.fromJson<String>(json['targetType']),
      targetId: serializer.fromJson<String>(json['targetId']),
      referenceStart: serializer.fromJson<int>(json['referenceStart']),
      referenceDuration: serializer.fromJson<int>(json['referenceDuration']),
      referenceText: serializer.fromJson<String>(json['referenceText']),
      language: serializer.fromJson<String>(json['language']),
      duration: serializer.fromJson<int>(json['duration']),
      md5: serializer.fromJson<String?>(json['md5']),
      audioUrl: serializer.fromJson<String?>(json['audioUrl']),
      pronunciationScore: serializer.fromJson<int?>(json['pronunciationScore']),
      assessmentJson: serializer.fromJson<String?>(json['assessmentJson']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      syncStatus: serializer.fromJson<String?>(json['syncStatus']),
      serverUpdatedAt: serializer.fromJson<DateTime?>(json['serverUpdatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'targetType': serializer.toJson<String>(targetType),
      'targetId': serializer.toJson<String>(targetId),
      'referenceStart': serializer.toJson<int>(referenceStart),
      'referenceDuration': serializer.toJson<int>(referenceDuration),
      'referenceText': serializer.toJson<String>(referenceText),
      'language': serializer.toJson<String>(language),
      'duration': serializer.toJson<int>(duration),
      'md5': serializer.toJson<String?>(md5),
      'audioUrl': serializer.toJson<String?>(audioUrl),
      'pronunciationScore': serializer.toJson<int?>(pronunciationScore),
      'assessmentJson': serializer.toJson<String?>(assessmentJson),
      'localPath': serializer.toJson<String?>(localPath),
      'syncStatus': serializer.toJson<String?>(syncStatus),
      'serverUpdatedAt': serializer.toJson<DateTime?>(serverUpdatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RecordingRow copyWith({
    String? id,
    String? targetType,
    String? targetId,
    int? referenceStart,
    int? referenceDuration,
    String? referenceText,
    String? language,
    int? duration,
    Value<String?> md5 = const Value.absent(),
    Value<String?> audioUrl = const Value.absent(),
    Value<int?> pronunciationScore = const Value.absent(),
    Value<String?> assessmentJson = const Value.absent(),
    Value<String?> localPath = const Value.absent(),
    Value<String?> syncStatus = const Value.absent(),
    Value<DateTime?> serverUpdatedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => RecordingRow(
    id: id ?? this.id,
    targetType: targetType ?? this.targetType,
    targetId: targetId ?? this.targetId,
    referenceStart: referenceStart ?? this.referenceStart,
    referenceDuration: referenceDuration ?? this.referenceDuration,
    referenceText: referenceText ?? this.referenceText,
    language: language ?? this.language,
    duration: duration ?? this.duration,
    md5: md5.present ? md5.value : this.md5,
    audioUrl: audioUrl.present ? audioUrl.value : this.audioUrl,
    pronunciationScore: pronunciationScore.present
        ? pronunciationScore.value
        : this.pronunciationScore,
    assessmentJson: assessmentJson.present
        ? assessmentJson.value
        : this.assessmentJson,
    localPath: localPath.present ? localPath.value : this.localPath,
    syncStatus: syncStatus.present ? syncStatus.value : this.syncStatus,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RecordingRow copyWithCompanion(RecordingsCompanion data) {
    return RecordingRow(
      id: data.id.present ? data.id.value : this.id,
      targetType: data.targetType.present
          ? data.targetType.value
          : this.targetType,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      referenceStart: data.referenceStart.present
          ? data.referenceStart.value
          : this.referenceStart,
      referenceDuration: data.referenceDuration.present
          ? data.referenceDuration.value
          : this.referenceDuration,
      referenceText: data.referenceText.present
          ? data.referenceText.value
          : this.referenceText,
      language: data.language.present ? data.language.value : this.language,
      duration: data.duration.present ? data.duration.value : this.duration,
      md5: data.md5.present ? data.md5.value : this.md5,
      audioUrl: data.audioUrl.present ? data.audioUrl.value : this.audioUrl,
      pronunciationScore: data.pronunciationScore.present
          ? data.pronunciationScore.value
          : this.pronunciationScore,
      assessmentJson: data.assessmentJson.present
          ? data.assessmentJson.value
          : this.assessmentJson,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordingRow(')
          ..write('id: $id, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('referenceStart: $referenceStart, ')
          ..write('referenceDuration: $referenceDuration, ')
          ..write('referenceText: $referenceText, ')
          ..write('language: $language, ')
          ..write('duration: $duration, ')
          ..write('md5: $md5, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('pronunciationScore: $pronunciationScore, ')
          ..write('assessmentJson: $assessmentJson, ')
          ..write('localPath: $localPath, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    targetType,
    targetId,
    referenceStart,
    referenceDuration,
    referenceText,
    language,
    duration,
    md5,
    audioUrl,
    pronunciationScore,
    assessmentJson,
    localPath,
    syncStatus,
    serverUpdatedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordingRow &&
          other.id == this.id &&
          other.targetType == this.targetType &&
          other.targetId == this.targetId &&
          other.referenceStart == this.referenceStart &&
          other.referenceDuration == this.referenceDuration &&
          other.referenceText == this.referenceText &&
          other.language == this.language &&
          other.duration == this.duration &&
          other.md5 == this.md5 &&
          other.audioUrl == this.audioUrl &&
          other.pronunciationScore == this.pronunciationScore &&
          other.assessmentJson == this.assessmentJson &&
          other.localPath == this.localPath &&
          other.syncStatus == this.syncStatus &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RecordingsCompanion extends UpdateCompanion<RecordingRow> {
  final Value<String> id;
  final Value<String> targetType;
  final Value<String> targetId;
  final Value<int> referenceStart;
  final Value<int> referenceDuration;
  final Value<String> referenceText;
  final Value<String> language;
  final Value<int> duration;
  final Value<String?> md5;
  final Value<String?> audioUrl;
  final Value<int?> pronunciationScore;
  final Value<String?> assessmentJson;
  final Value<String?> localPath;
  final Value<String?> syncStatus;
  final Value<DateTime?> serverUpdatedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RecordingsCompanion({
    this.id = const Value.absent(),
    this.targetType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.referenceStart = const Value.absent(),
    this.referenceDuration = const Value.absent(),
    this.referenceText = const Value.absent(),
    this.language = const Value.absent(),
    this.duration = const Value.absent(),
    this.md5 = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.pronunciationScore = const Value.absent(),
    this.assessmentJson = const Value.absent(),
    this.localPath = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordingsCompanion.insert({
    required String id,
    required String targetType,
    required String targetId,
    required int referenceStart,
    required int referenceDuration,
    required String referenceText,
    required String language,
    required int duration,
    this.md5 = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.pronunciationScore = const Value.absent(),
    this.assessmentJson = const Value.absent(),
    this.localPath = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       targetType = Value(targetType),
       targetId = Value(targetId),
       referenceStart = Value(referenceStart),
       referenceDuration = Value(referenceDuration),
       referenceText = Value(referenceText),
       language = Value(language),
       duration = Value(duration),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<RecordingRow> custom({
    Expression<String>? id,
    Expression<String>? targetType,
    Expression<String>? targetId,
    Expression<int>? referenceStart,
    Expression<int>? referenceDuration,
    Expression<String>? referenceText,
    Expression<String>? language,
    Expression<int>? duration,
    Expression<String>? md5,
    Expression<String>? audioUrl,
    Expression<int>? pronunciationScore,
    Expression<String>? assessmentJson,
    Expression<String>? localPath,
    Expression<String>? syncStatus,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
      if (referenceStart != null) 'reference_start': referenceStart,
      if (referenceDuration != null) 'reference_duration': referenceDuration,
      if (referenceText != null) 'reference_text': referenceText,
      if (language != null) 'language': language,
      if (duration != null) 'duration': duration,
      if (md5 != null) 'md5': md5,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (pronunciationScore != null) 'pronunciation_score': pronunciationScore,
      if (assessmentJson != null) 'assessment_json': assessmentJson,
      if (localPath != null) 'local_path': localPath,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordingsCompanion copyWith({
    Value<String>? id,
    Value<String>? targetType,
    Value<String>? targetId,
    Value<int>? referenceStart,
    Value<int>? referenceDuration,
    Value<String>? referenceText,
    Value<String>? language,
    Value<int>? duration,
    Value<String?>? md5,
    Value<String?>? audioUrl,
    Value<int?>? pronunciationScore,
    Value<String?>? assessmentJson,
    Value<String?>? localPath,
    Value<String?>? syncStatus,
    Value<DateTime?>? serverUpdatedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RecordingsCompanion(
      id: id ?? this.id,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      referenceStart: referenceStart ?? this.referenceStart,
      referenceDuration: referenceDuration ?? this.referenceDuration,
      referenceText: referenceText ?? this.referenceText,
      language: language ?? this.language,
      duration: duration ?? this.duration,
      md5: md5 ?? this.md5,
      audioUrl: audioUrl ?? this.audioUrl,
      pronunciationScore: pronunciationScore ?? this.pronunciationScore,
      assessmentJson: assessmentJson ?? this.assessmentJson,
      localPath: localPath ?? this.localPath,
      syncStatus: syncStatus ?? this.syncStatus,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
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
    if (targetType.present) {
      map['target_type'] = Variable<String>(targetType.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (referenceStart.present) {
      map['reference_start'] = Variable<int>(referenceStart.value);
    }
    if (referenceDuration.present) {
      map['reference_duration'] = Variable<int>(referenceDuration.value);
    }
    if (referenceText.present) {
      map['reference_text'] = Variable<String>(referenceText.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (md5.present) {
      map['md5'] = Variable<String>(md5.value);
    }
    if (audioUrl.present) {
      map['audio_url'] = Variable<String>(audioUrl.value);
    }
    if (pronunciationScore.present) {
      map['pronunciation_score'] = Variable<int>(pronunciationScore.value);
    }
    if (assessmentJson.present) {
      map['assessment_json'] = Variable<String>(assessmentJson.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
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
    return (StringBuffer('RecordingsCompanion(')
          ..write('id: $id, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('referenceStart: $referenceStart, ')
          ..write('referenceDuration: $referenceDuration, ')
          ..write('referenceText: $referenceText, ')
          ..write('language: $language, ')
          ..write('duration: $duration, ')
          ..write('md5: $md5, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('pronunciationScore: $pronunciationScore, ')
          ..write('assessmentJson: $assessmentJson, ')
          ..write('localPath: $localPath, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DictationsTable extends Dictations
    with TableInfo<$DictationsTable, DictationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetTypeMeta = const VerificationMeta(
    'targetType',
  );
  @override
  late final GeneratedColumn<String> targetType = GeneratedColumn<String>(
    'target_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceStartMsMeta = const VerificationMeta(
    'referenceStartMs',
  );
  @override
  late final GeneratedColumn<int> referenceStartMs = GeneratedColumn<int>(
    'reference_start_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceDurationMsMeta =
      const VerificationMeta('referenceDurationMs');
  @override
  late final GeneratedColumn<int> referenceDurationMs = GeneratedColumn<int>(
    'reference_duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceTextMeta = const VerificationMeta(
    'referenceText',
  );
  @override
  late final GeneratedColumn<String> referenceText = GeneratedColumn<String>(
    'reference_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _userInputMeta = const VerificationMeta(
    'userInput',
  );
  @override
  late final GeneratedColumn<String> userInput = GeneratedColumn<String>(
    'user_input',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<int> accuracy = GeneratedColumn<int>(
    'accuracy',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctWordsMeta = const VerificationMeta(
    'correctWords',
  );
  @override
  late final GeneratedColumn<int> correctWords = GeneratedColumn<int>(
    'correct_words',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _missedWordsMeta = const VerificationMeta(
    'missedWords',
  );
  @override
  late final GeneratedColumn<int> missedWords = GeneratedColumn<int>(
    'missed_words',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extraWordsMeta = const VerificationMeta(
    'extraWords',
  );
  @override
  late final GeneratedColumn<int> extraWords = GeneratedColumn<int>(
    'extra_words',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
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
    targetType,
    targetId,
    referenceStartMs,
    referenceDurationMs,
    referenceText,
    language,
    userInput,
    accuracy,
    correctWords,
    missedWords,
    extraWords,
    syncStatus,
    serverUpdatedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictations';
  @override
  VerificationContext validateIntegrity(
    Insertable<DictationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('target_type')) {
      context.handle(
        _targetTypeMeta,
        targetType.isAcceptableOrUnknown(data['target_type']!, _targetTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_targetTypeMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('reference_start_ms')) {
      context.handle(
        _referenceStartMsMeta,
        referenceStartMs.isAcceptableOrUnknown(
          data['reference_start_ms']!,
          _referenceStartMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceStartMsMeta);
    }
    if (data.containsKey('reference_duration_ms')) {
      context.handle(
        _referenceDurationMsMeta,
        referenceDurationMs.isAcceptableOrUnknown(
          data['reference_duration_ms']!,
          _referenceDurationMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceDurationMsMeta);
    }
    if (data.containsKey('reference_text')) {
      context.handle(
        _referenceTextMeta,
        referenceText.isAcceptableOrUnknown(
          data['reference_text']!,
          _referenceTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceTextMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('user_input')) {
      context.handle(
        _userInputMeta,
        userInput.isAcceptableOrUnknown(data['user_input']!, _userInputMeta),
      );
    } else if (isInserting) {
      context.missing(_userInputMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    } else if (isInserting) {
      context.missing(_accuracyMeta);
    }
    if (data.containsKey('correct_words')) {
      context.handle(
        _correctWordsMeta,
        correctWords.isAcceptableOrUnknown(
          data['correct_words']!,
          _correctWordsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctWordsMeta);
    }
    if (data.containsKey('missed_words')) {
      context.handle(
        _missedWordsMeta,
        missedWords.isAcceptableOrUnknown(
          data['missed_words']!,
          _missedWordsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_missedWordsMeta);
    }
    if (data.containsKey('extra_words')) {
      context.handle(
        _extraWordsMeta,
        extraWords.isAcceptableOrUnknown(data['extra_words']!, _extraWordsMeta),
      );
    } else if (isInserting) {
      context.missing(_extraWordsMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
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
  DictationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DictationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      targetType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_type'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      referenceStartMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reference_start_ms'],
      )!,
      referenceDurationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reference_duration_ms'],
      )!,
      referenceText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_text'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      userInput: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_input'],
      )!,
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}accuracy'],
      )!,
      correctWords: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_words'],
      )!,
      missedWords: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}missed_words'],
      )!,
      extraWords: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}extra_words'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      ),
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_updated_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DictationsTable createAlias(String alias) {
    return $DictationsTable(attachedDatabase, alias);
  }
}

class DictationRow extends DataClass implements Insertable<DictationRow> {
  final String id;
  final String targetType;
  final String targetId;
  final int referenceStartMs;
  final int referenceDurationMs;
  final String referenceText;
  final String language;
  final String userInput;
  final int accuracy;
  final int correctWords;
  final int missedWords;
  final int extraWords;
  final String? syncStatus;
  final DateTime? serverUpdatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DictationRow({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.referenceStartMs,
    required this.referenceDurationMs,
    required this.referenceText,
    required this.language,
    required this.userInput,
    required this.accuracy,
    required this.correctWords,
    required this.missedWords,
    required this.extraWords,
    this.syncStatus,
    this.serverUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['target_type'] = Variable<String>(targetType);
    map['target_id'] = Variable<String>(targetId);
    map['reference_start_ms'] = Variable<int>(referenceStartMs);
    map['reference_duration_ms'] = Variable<int>(referenceDurationMs);
    map['reference_text'] = Variable<String>(referenceText);
    map['language'] = Variable<String>(language);
    map['user_input'] = Variable<String>(userInput);
    map['accuracy'] = Variable<int>(accuracy);
    map['correct_words'] = Variable<int>(correctWords);
    map['missed_words'] = Variable<int>(missedWords);
    map['extra_words'] = Variable<int>(extraWords);
    if (!nullToAbsent || syncStatus != null) {
      map['sync_status'] = Variable<String>(syncStatus);
    }
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DictationsCompanion toCompanion(bool nullToAbsent) {
    return DictationsCompanion(
      id: Value(id),
      targetType: Value(targetType),
      targetId: Value(targetId),
      referenceStartMs: Value(referenceStartMs),
      referenceDurationMs: Value(referenceDurationMs),
      referenceText: Value(referenceText),
      language: Value(language),
      userInput: Value(userInput),
      accuracy: Value(accuracy),
      correctWords: Value(correctWords),
      missedWords: Value(missedWords),
      extraWords: Value(extraWords),
      syncStatus: syncStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(syncStatus),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DictationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DictationRow(
      id: serializer.fromJson<String>(json['id']),
      targetType: serializer.fromJson<String>(json['targetType']),
      targetId: serializer.fromJson<String>(json['targetId']),
      referenceStartMs: serializer.fromJson<int>(json['referenceStartMs']),
      referenceDurationMs: serializer.fromJson<int>(
        json['referenceDurationMs'],
      ),
      referenceText: serializer.fromJson<String>(json['referenceText']),
      language: serializer.fromJson<String>(json['language']),
      userInput: serializer.fromJson<String>(json['userInput']),
      accuracy: serializer.fromJson<int>(json['accuracy']),
      correctWords: serializer.fromJson<int>(json['correctWords']),
      missedWords: serializer.fromJson<int>(json['missedWords']),
      extraWords: serializer.fromJson<int>(json['extraWords']),
      syncStatus: serializer.fromJson<String?>(json['syncStatus']),
      serverUpdatedAt: serializer.fromJson<DateTime?>(json['serverUpdatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'targetType': serializer.toJson<String>(targetType),
      'targetId': serializer.toJson<String>(targetId),
      'referenceStartMs': serializer.toJson<int>(referenceStartMs),
      'referenceDurationMs': serializer.toJson<int>(referenceDurationMs),
      'referenceText': serializer.toJson<String>(referenceText),
      'language': serializer.toJson<String>(language),
      'userInput': serializer.toJson<String>(userInput),
      'accuracy': serializer.toJson<int>(accuracy),
      'correctWords': serializer.toJson<int>(correctWords),
      'missedWords': serializer.toJson<int>(missedWords),
      'extraWords': serializer.toJson<int>(extraWords),
      'syncStatus': serializer.toJson<String?>(syncStatus),
      'serverUpdatedAt': serializer.toJson<DateTime?>(serverUpdatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DictationRow copyWith({
    String? id,
    String? targetType,
    String? targetId,
    int? referenceStartMs,
    int? referenceDurationMs,
    String? referenceText,
    String? language,
    String? userInput,
    int? accuracy,
    int? correctWords,
    int? missedWords,
    int? extraWords,
    Value<String?> syncStatus = const Value.absent(),
    Value<DateTime?> serverUpdatedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DictationRow(
    id: id ?? this.id,
    targetType: targetType ?? this.targetType,
    targetId: targetId ?? this.targetId,
    referenceStartMs: referenceStartMs ?? this.referenceStartMs,
    referenceDurationMs: referenceDurationMs ?? this.referenceDurationMs,
    referenceText: referenceText ?? this.referenceText,
    language: language ?? this.language,
    userInput: userInput ?? this.userInput,
    accuracy: accuracy ?? this.accuracy,
    correctWords: correctWords ?? this.correctWords,
    missedWords: missedWords ?? this.missedWords,
    extraWords: extraWords ?? this.extraWords,
    syncStatus: syncStatus.present ? syncStatus.value : this.syncStatus,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DictationRow copyWithCompanion(DictationsCompanion data) {
    return DictationRow(
      id: data.id.present ? data.id.value : this.id,
      targetType: data.targetType.present
          ? data.targetType.value
          : this.targetType,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      referenceStartMs: data.referenceStartMs.present
          ? data.referenceStartMs.value
          : this.referenceStartMs,
      referenceDurationMs: data.referenceDurationMs.present
          ? data.referenceDurationMs.value
          : this.referenceDurationMs,
      referenceText: data.referenceText.present
          ? data.referenceText.value
          : this.referenceText,
      language: data.language.present ? data.language.value : this.language,
      userInput: data.userInput.present ? data.userInput.value : this.userInput,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      correctWords: data.correctWords.present
          ? data.correctWords.value
          : this.correctWords,
      missedWords: data.missedWords.present
          ? data.missedWords.value
          : this.missedWords,
      extraWords: data.extraWords.present
          ? data.extraWords.value
          : this.extraWords,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DictationRow(')
          ..write('id: $id, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('referenceStartMs: $referenceStartMs, ')
          ..write('referenceDurationMs: $referenceDurationMs, ')
          ..write('referenceText: $referenceText, ')
          ..write('language: $language, ')
          ..write('userInput: $userInput, ')
          ..write('accuracy: $accuracy, ')
          ..write('correctWords: $correctWords, ')
          ..write('missedWords: $missedWords, ')
          ..write('extraWords: $extraWords, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    targetType,
    targetId,
    referenceStartMs,
    referenceDurationMs,
    referenceText,
    language,
    userInput,
    accuracy,
    correctWords,
    missedWords,
    extraWords,
    syncStatus,
    serverUpdatedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DictationRow &&
          other.id == this.id &&
          other.targetType == this.targetType &&
          other.targetId == this.targetId &&
          other.referenceStartMs == this.referenceStartMs &&
          other.referenceDurationMs == this.referenceDurationMs &&
          other.referenceText == this.referenceText &&
          other.language == this.language &&
          other.userInput == this.userInput &&
          other.accuracy == this.accuracy &&
          other.correctWords == this.correctWords &&
          other.missedWords == this.missedWords &&
          other.extraWords == this.extraWords &&
          other.syncStatus == this.syncStatus &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DictationsCompanion extends UpdateCompanion<DictationRow> {
  final Value<String> id;
  final Value<String> targetType;
  final Value<String> targetId;
  final Value<int> referenceStartMs;
  final Value<int> referenceDurationMs;
  final Value<String> referenceText;
  final Value<String> language;
  final Value<String> userInput;
  final Value<int> accuracy;
  final Value<int> correctWords;
  final Value<int> missedWords;
  final Value<int> extraWords;
  final Value<String?> syncStatus;
  final Value<DateTime?> serverUpdatedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DictationsCompanion({
    this.id = const Value.absent(),
    this.targetType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.referenceStartMs = const Value.absent(),
    this.referenceDurationMs = const Value.absent(),
    this.referenceText = const Value.absent(),
    this.language = const Value.absent(),
    this.userInput = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.correctWords = const Value.absent(),
    this.missedWords = const Value.absent(),
    this.extraWords = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DictationsCompanion.insert({
    required String id,
    required String targetType,
    required String targetId,
    required int referenceStartMs,
    required int referenceDurationMs,
    required String referenceText,
    required String language,
    required String userInput,
    required int accuracy,
    required int correctWords,
    required int missedWords,
    required int extraWords,
    this.syncStatus = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       targetType = Value(targetType),
       targetId = Value(targetId),
       referenceStartMs = Value(referenceStartMs),
       referenceDurationMs = Value(referenceDurationMs),
       referenceText = Value(referenceText),
       language = Value(language),
       userInput = Value(userInput),
       accuracy = Value(accuracy),
       correctWords = Value(correctWords),
       missedWords = Value(missedWords),
       extraWords = Value(extraWords),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DictationRow> custom({
    Expression<String>? id,
    Expression<String>? targetType,
    Expression<String>? targetId,
    Expression<int>? referenceStartMs,
    Expression<int>? referenceDurationMs,
    Expression<String>? referenceText,
    Expression<String>? language,
    Expression<String>? userInput,
    Expression<int>? accuracy,
    Expression<int>? correctWords,
    Expression<int>? missedWords,
    Expression<int>? extraWords,
    Expression<String>? syncStatus,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
      if (referenceStartMs != null) 'reference_start_ms': referenceStartMs,
      if (referenceDurationMs != null)
        'reference_duration_ms': referenceDurationMs,
      if (referenceText != null) 'reference_text': referenceText,
      if (language != null) 'language': language,
      if (userInput != null) 'user_input': userInput,
      if (accuracy != null) 'accuracy': accuracy,
      if (correctWords != null) 'correct_words': correctWords,
      if (missedWords != null) 'missed_words': missedWords,
      if (extraWords != null) 'extra_words': extraWords,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DictationsCompanion copyWith({
    Value<String>? id,
    Value<String>? targetType,
    Value<String>? targetId,
    Value<int>? referenceStartMs,
    Value<int>? referenceDurationMs,
    Value<String>? referenceText,
    Value<String>? language,
    Value<String>? userInput,
    Value<int>? accuracy,
    Value<int>? correctWords,
    Value<int>? missedWords,
    Value<int>? extraWords,
    Value<String?>? syncStatus,
    Value<DateTime?>? serverUpdatedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DictationsCompanion(
      id: id ?? this.id,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      referenceStartMs: referenceStartMs ?? this.referenceStartMs,
      referenceDurationMs: referenceDurationMs ?? this.referenceDurationMs,
      referenceText: referenceText ?? this.referenceText,
      language: language ?? this.language,
      userInput: userInput ?? this.userInput,
      accuracy: accuracy ?? this.accuracy,
      correctWords: correctWords ?? this.correctWords,
      missedWords: missedWords ?? this.missedWords,
      extraWords: extraWords ?? this.extraWords,
      syncStatus: syncStatus ?? this.syncStatus,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
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
    if (targetType.present) {
      map['target_type'] = Variable<String>(targetType.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (referenceStartMs.present) {
      map['reference_start_ms'] = Variable<int>(referenceStartMs.value);
    }
    if (referenceDurationMs.present) {
      map['reference_duration_ms'] = Variable<int>(referenceDurationMs.value);
    }
    if (referenceText.present) {
      map['reference_text'] = Variable<String>(referenceText.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (userInput.present) {
      map['user_input'] = Variable<String>(userInput.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<int>(accuracy.value);
    }
    if (correctWords.present) {
      map['correct_words'] = Variable<int>(correctWords.value);
    }
    if (missedWords.present) {
      map['missed_words'] = Variable<int>(missedWords.value);
    }
    if (extraWords.present) {
      map['extra_words'] = Variable<int>(extraWords.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
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
    return (StringBuffer('DictationsCompanion(')
          ..write('id: $id, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('referenceStartMs: $referenceStartMs, ')
          ..write('referenceDurationMs: $referenceDurationMs, ')
          ..write('referenceText: $referenceText, ')
          ..write('language: $language, ')
          ..write('userInput: $userInput, ')
          ..write('accuracy: $accuracy, ')
          ..write('correctWords: $correctWords, ')
          ..write('missedWords: $missedWords, ')
          ..write('extraWords: $extraWords, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _lastAttemptMeta = const VerificationMeta(
    'lastAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttempt = GeneratedColumn<DateTime>(
    'last_attempt',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    action,
    payloadJson,
    retryCount,
    lastAttempt,
    error,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_attempt')) {
      context.handle(
        _lastAttemptMeta,
        lastAttempt.isAcceptableOrUnknown(
          data['last_attempt']!,
          _lastAttemptMeta,
        ),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt'],
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueRow extends DataClass implements Insertable<SyncQueueRow> {
  final int id;
  final String entityType;
  final String entityId;
  final String action;
  final String? payloadJson;
  final int retryCount;
  final DateTime? lastAttempt;
  final String? error;
  final DateTime createdAt;
  const SyncQueueRow({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.payloadJson,
    required this.retryCount,
    this.lastAttempt,
    this.error,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || payloadJson != null) {
      map['payload_json'] = Variable<String>(payloadJson);
    }
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastAttempt != null) {
      map['last_attempt'] = Variable<DateTime>(lastAttempt);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      action: Value(action),
      payloadJson: payloadJson == null && nullToAbsent
          ? const Value.absent()
          : Value(payloadJson),
      retryCount: Value(retryCount),
      lastAttempt: lastAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttempt),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueRow(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      action: serializer.fromJson<String>(json['action']),
      payloadJson: serializer.fromJson<String?>(json['payloadJson']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastAttempt: serializer.fromJson<DateTime?>(json['lastAttempt']),
      error: serializer.fromJson<String?>(json['error']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'action': serializer.toJson<String>(action),
      'payloadJson': serializer.toJson<String?>(payloadJson),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastAttempt': serializer.toJson<DateTime?>(lastAttempt),
      'error': serializer.toJson<String?>(error),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncQueueRow copyWith({
    int? id,
    String? entityType,
    String? entityId,
    String? action,
    Value<String?> payloadJson = const Value.absent(),
    int? retryCount,
    Value<DateTime?> lastAttempt = const Value.absent(),
    Value<String?> error = const Value.absent(),
    DateTime? createdAt,
  }) => SyncQueueRow(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    action: action ?? this.action,
    payloadJson: payloadJson.present ? payloadJson.value : this.payloadJson,
    retryCount: retryCount ?? this.retryCount,
    lastAttempt: lastAttempt.present ? lastAttempt.value : this.lastAttempt,
    error: error.present ? error.value : this.error,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncQueueRow copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueRow(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      action: data.action.present ? data.action.value : this.action,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastAttempt: data.lastAttempt.present
          ? data.lastAttempt.value
          : this.lastAttempt,
      error: data.error.present ? data.error.value : this.error,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueRow(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastAttempt: $lastAttempt, ')
          ..write('error: $error, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    action,
    payloadJson,
    retryCount,
    lastAttempt,
    error,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueRow &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.action == this.action &&
          other.payloadJson == this.payloadJson &&
          other.retryCount == this.retryCount &&
          other.lastAttempt == this.lastAttempt &&
          other.error == this.error &&
          other.createdAt == this.createdAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueRow> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> action;
  final Value<String?> payloadJson;
  final Value<int> retryCount;
  final Value<DateTime?> lastAttempt;
  final Value<String?> error;
  final Value<DateTime> createdAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.action = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastAttempt = const Value.absent(),
    this.error = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String entityId,
    required String action,
    this.payloadJson = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastAttempt = const Value.absent(),
    this.error = const Value.absent(),
    required DateTime createdAt,
  }) : entityType = Value(entityType),
       entityId = Value(entityId),
       action = Value(action),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueRow> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? action,
    Expression<String>? payloadJson,
    Expression<int>? retryCount,
    Expression<DateTime>? lastAttempt,
    Expression<String>? error,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (action != null) 'action': action,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastAttempt != null) 'last_attempt': lastAttempt,
      if (error != null) 'error': error,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? action,
    Value<String?>? payloadJson,
    Value<int>? retryCount,
    Value<DateTime?>? lastAttempt,
    Value<String?>? error,
    Value<DateTime>? createdAt,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payloadJson: payloadJson ?? this.payloadJson,
      retryCount: retryCount ?? this.retryCount,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastAttempt.present) {
      map['last_attempt'] = Variable<DateTime>(lastAttempt.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastAttempt: $lastAttempt, ')
          ..write('error: $error, ')
          ..write('createdAt: $createdAt')
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

class $YoutubeChannelSubscriptionsTable extends YoutubeChannelSubscriptions
    with
        TableInfo<
          $YoutubeChannelSubscriptionsTable,
          YoutubeChannelSubscriptionRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $YoutubeChannelSubscriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<YoutubeSubscriptionSource, String>
  source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('user'),
      ).withConverter<YoutubeSubscriptionSource>(
        $YoutubeChannelSubscriptionsTable.$convertersource,
      );
  static const VerificationMeta _subscribedAtMeta = const VerificationMeta(
    'subscribedAt',
  );
  @override
  late final GeneratedColumn<DateTime> subscribedAt = GeneratedColumn<DateTime>(
    'subscribed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastFetchedAtMeta = const VerificationMeta(
    'lastFetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastFetchedAt =
      GeneratedColumn<DateTime>(
        'last_fetched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    channelId,
    displayName,
    thumbnailUrl,
    source,
    subscribedAt,
    lastFetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'youtube_channel_subscriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<YoutubeChannelSubscriptionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('subscribed_at')) {
      context.handle(
        _subscribedAtMeta,
        subscribedAt.isAcceptableOrUnknown(
          data['subscribed_at']!,
          _subscribedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subscribedAtMeta);
    }
    if (data.containsKey('last_fetched_at')) {
      context.handle(
        _lastFetchedAtMeta,
        lastFetchedAt.isAcceptableOrUnknown(
          data['last_fetched_at']!,
          _lastFetchedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {channelId};
  @override
  YoutubeChannelSubscriptionRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return YoutubeChannelSubscriptionRow(
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
      source: $YoutubeChannelSubscriptionsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      subscribedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}subscribed_at'],
      )!,
      lastFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_fetched_at'],
      ),
    );
  }

  @override
  $YoutubeChannelSubscriptionsTable createAlias(String alias) {
    return $YoutubeChannelSubscriptionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<YoutubeSubscriptionSource, String, String>
  $convertersource = const EnumNameConverter<YoutubeSubscriptionSource>(
    YoutubeSubscriptionSource.values,
  );
}

class YoutubeChannelSubscriptionRow extends DataClass
    implements Insertable<YoutubeChannelSubscriptionRow> {
  final String channelId;
  final String displayName;
  final String? thumbnailUrl;

  /// Bundled catalog vs user-initiated subscription.
  final YoutubeSubscriptionSource source;
  final DateTime subscribedAt;
  final DateTime? lastFetchedAt;
  const YoutubeChannelSubscriptionRow({
    required this.channelId,
    required this.displayName,
    this.thumbnailUrl,
    required this.source,
    required this.subscribedAt,
    this.lastFetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['channel_id'] = Variable<String>(channelId);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    {
      map['source'] = Variable<String>(
        $YoutubeChannelSubscriptionsTable.$convertersource.toSql(source),
      );
    }
    map['subscribed_at'] = Variable<DateTime>(subscribedAt);
    if (!nullToAbsent || lastFetchedAt != null) {
      map['last_fetched_at'] = Variable<DateTime>(lastFetchedAt);
    }
    return map;
  }

  YoutubeChannelSubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return YoutubeChannelSubscriptionsCompanion(
      channelId: Value(channelId),
      displayName: Value(displayName),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      source: Value(source),
      subscribedAt: Value(subscribedAt),
      lastFetchedAt: lastFetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFetchedAt),
    );
  }

  factory YoutubeChannelSubscriptionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return YoutubeChannelSubscriptionRow(
      channelId: serializer.fromJson<String>(json['channelId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      source: $YoutubeChannelSubscriptionsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      subscribedAt: serializer.fromJson<DateTime>(json['subscribedAt']),
      lastFetchedAt: serializer.fromJson<DateTime?>(json['lastFetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'channelId': serializer.toJson<String>(channelId),
      'displayName': serializer.toJson<String>(displayName),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'source': serializer.toJson<String>(
        $YoutubeChannelSubscriptionsTable.$convertersource.toJson(source),
      ),
      'subscribedAt': serializer.toJson<DateTime>(subscribedAt),
      'lastFetchedAt': serializer.toJson<DateTime?>(lastFetchedAt),
    };
  }

  YoutubeChannelSubscriptionRow copyWith({
    String? channelId,
    String? displayName,
    Value<String?> thumbnailUrl = const Value.absent(),
    YoutubeSubscriptionSource? source,
    DateTime? subscribedAt,
    Value<DateTime?> lastFetchedAt = const Value.absent(),
  }) => YoutubeChannelSubscriptionRow(
    channelId: channelId ?? this.channelId,
    displayName: displayName ?? this.displayName,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    source: source ?? this.source,
    subscribedAt: subscribedAt ?? this.subscribedAt,
    lastFetchedAt: lastFetchedAt.present
        ? lastFetchedAt.value
        : this.lastFetchedAt,
  );
  YoutubeChannelSubscriptionRow copyWithCompanion(
    YoutubeChannelSubscriptionsCompanion data,
  ) {
    return YoutubeChannelSubscriptionRow(
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      source: data.source.present ? data.source.value : this.source,
      subscribedAt: data.subscribedAt.present
          ? data.subscribedAt.value
          : this.subscribedAt,
      lastFetchedAt: data.lastFetchedAt.present
          ? data.lastFetchedAt.value
          : this.lastFetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('YoutubeChannelSubscriptionRow(')
          ..write('channelId: $channelId, ')
          ..write('displayName: $displayName, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('source: $source, ')
          ..write('subscribedAt: $subscribedAt, ')
          ..write('lastFetchedAt: $lastFetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    channelId,
    displayName,
    thumbnailUrl,
    source,
    subscribedAt,
    lastFetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is YoutubeChannelSubscriptionRow &&
          other.channelId == this.channelId &&
          other.displayName == this.displayName &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.source == this.source &&
          other.subscribedAt == this.subscribedAt &&
          other.lastFetchedAt == this.lastFetchedAt);
}

class YoutubeChannelSubscriptionsCompanion
    extends UpdateCompanion<YoutubeChannelSubscriptionRow> {
  final Value<String> channelId;
  final Value<String> displayName;
  final Value<String?> thumbnailUrl;
  final Value<YoutubeSubscriptionSource> source;
  final Value<DateTime> subscribedAt;
  final Value<DateTime?> lastFetchedAt;
  final Value<int> rowid;
  const YoutubeChannelSubscriptionsCompanion({
    this.channelId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.source = const Value.absent(),
    this.subscribedAt = const Value.absent(),
    this.lastFetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  YoutubeChannelSubscriptionsCompanion.insert({
    required String channelId,
    required String displayName,
    this.thumbnailUrl = const Value.absent(),
    this.source = const Value.absent(),
    required DateTime subscribedAt,
    this.lastFetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : channelId = Value(channelId),
       displayName = Value(displayName),
       subscribedAt = Value(subscribedAt);
  static Insertable<YoutubeChannelSubscriptionRow> custom({
    Expression<String>? channelId,
    Expression<String>? displayName,
    Expression<String>? thumbnailUrl,
    Expression<String>? source,
    Expression<DateTime>? subscribedAt,
    Expression<DateTime>? lastFetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (channelId != null) 'channel_id': channelId,
      if (displayName != null) 'display_name': displayName,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (source != null) 'source': source,
      if (subscribedAt != null) 'subscribed_at': subscribedAt,
      if (lastFetchedAt != null) 'last_fetched_at': lastFetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  YoutubeChannelSubscriptionsCompanion copyWith({
    Value<String>? channelId,
    Value<String>? displayName,
    Value<String?>? thumbnailUrl,
    Value<YoutubeSubscriptionSource>? source,
    Value<DateTime>? subscribedAt,
    Value<DateTime?>? lastFetchedAt,
    Value<int>? rowid,
  }) {
    return YoutubeChannelSubscriptionsCompanion(
      channelId: channelId ?? this.channelId,
      displayName: displayName ?? this.displayName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      source: source ?? this.source,
      subscribedAt: subscribedAt ?? this.subscribedAt,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $YoutubeChannelSubscriptionsTable.$convertersource.toSql(source.value),
      );
    }
    if (subscribedAt.present) {
      map['subscribed_at'] = Variable<DateTime>(subscribedAt.value);
    }
    if (lastFetchedAt.present) {
      map['last_fetched_at'] = Variable<DateTime>(lastFetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('YoutubeChannelSubscriptionsCompanion(')
          ..write('channelId: $channelId, ')
          ..write('displayName: $displayName, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('source: $source, ')
          ..write('subscribedAt: $subscribedAt, ')
          ..write('lastFetchedAt: $lastFetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $YoutubeFeedEntriesTable extends YoutubeFeedEntries
    with TableInfo<$YoutubeFeedEntriesTable, YoutubeFeedEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $YoutubeFeedEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
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
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> publishedAt = GeneratedColumn<DateTime>(
    'published_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    videoId,
    channelId,
    title,
    thumbnailUrl,
    durationSeconds,
    publishedAt,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'youtube_feed_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<YoutubeFeedEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publishedAtMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {videoId, channelId};
  @override
  YoutubeFeedEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return YoutubeFeedEntryRow(
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}published_at'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $YoutubeFeedEntriesTable createAlias(String alias) {
    return $YoutubeFeedEntriesTable(attachedDatabase, alias);
  }
}

class YoutubeFeedEntryRow extends DataClass
    implements Insertable<YoutubeFeedEntryRow> {
  final String videoId;
  final String channelId;
  final String title;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final DateTime publishedAt;
  final DateTime fetchedAt;
  const YoutubeFeedEntryRow({
    required this.videoId,
    required this.channelId,
    required this.title,
    this.thumbnailUrl,
    this.durationSeconds,
    required this.publishedAt,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['video_id'] = Variable<String>(videoId);
    map['channel_id'] = Variable<String>(channelId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['published_at'] = Variable<DateTime>(publishedAt);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  YoutubeFeedEntriesCompanion toCompanion(bool nullToAbsent) {
    return YoutubeFeedEntriesCompanion(
      videoId: Value(videoId),
      channelId: Value(channelId),
      title: Value(title),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      publishedAt: Value(publishedAt),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory YoutubeFeedEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return YoutubeFeedEntryRow(
      videoId: serializer.fromJson<String>(json['videoId']),
      channelId: serializer.fromJson<String>(json['channelId']),
      title: serializer.fromJson<String>(json['title']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      publishedAt: serializer.fromJson<DateTime>(json['publishedAt']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'videoId': serializer.toJson<String>(videoId),
      'channelId': serializer.toJson<String>(channelId),
      'title': serializer.toJson<String>(title),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'publishedAt': serializer.toJson<DateTime>(publishedAt),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  YoutubeFeedEntryRow copyWith({
    String? videoId,
    String? channelId,
    String? title,
    Value<String?> thumbnailUrl = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    DateTime? publishedAt,
    DateTime? fetchedAt,
  }) => YoutubeFeedEntryRow(
    videoId: videoId ?? this.videoId,
    channelId: channelId ?? this.channelId,
    title: title ?? this.title,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    publishedAt: publishedAt ?? this.publishedAt,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  YoutubeFeedEntryRow copyWithCompanion(YoutubeFeedEntriesCompanion data) {
    return YoutubeFeedEntryRow(
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      title: data.title.present ? data.title.value : this.title,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('YoutubeFeedEntryRow(')
          ..write('videoId: $videoId, ')
          ..write('channelId: $channelId, ')
          ..write('title: $title, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    videoId,
    channelId,
    title,
    thumbnailUrl,
    durationSeconds,
    publishedAt,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is YoutubeFeedEntryRow &&
          other.videoId == this.videoId &&
          other.channelId == this.channelId &&
          other.title == this.title &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.durationSeconds == this.durationSeconds &&
          other.publishedAt == this.publishedAt &&
          other.fetchedAt == this.fetchedAt);
}

class YoutubeFeedEntriesCompanion extends UpdateCompanion<YoutubeFeedEntryRow> {
  final Value<String> videoId;
  final Value<String> channelId;
  final Value<String> title;
  final Value<String?> thumbnailUrl;
  final Value<int?> durationSeconds;
  final Value<DateTime> publishedAt;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const YoutubeFeedEntriesCompanion({
    this.videoId = const Value.absent(),
    this.channelId = const Value.absent(),
    this.title = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  YoutubeFeedEntriesCompanion.insert({
    required String videoId,
    required String channelId,
    required String title,
    this.thumbnailUrl = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    required DateTime publishedAt,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : videoId = Value(videoId),
       channelId = Value(channelId),
       title = Value(title),
       publishedAt = Value(publishedAt),
       fetchedAt = Value(fetchedAt);
  static Insertable<YoutubeFeedEntryRow> custom({
    Expression<String>? videoId,
    Expression<String>? channelId,
    Expression<String>? title,
    Expression<String>? thumbnailUrl,
    Expression<int>? durationSeconds,
    Expression<DateTime>? publishedAt,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (videoId != null) 'video_id': videoId,
      if (channelId != null) 'channel_id': channelId,
      if (title != null) 'title': title,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (publishedAt != null) 'published_at': publishedAt,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  YoutubeFeedEntriesCompanion copyWith({
    Value<String>? videoId,
    Value<String>? channelId,
    Value<String>? title,
    Value<String?>? thumbnailUrl,
    Value<int?>? durationSeconds,
    Value<DateTime>? publishedAt,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return YoutubeFeedEntriesCompanion(
      videoId: videoId ?? this.videoId,
      channelId: channelId ?? this.channelId,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      publishedAt: publishedAt ?? this.publishedAt,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<DateTime>(publishedAt.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('YoutubeFeedEntriesCompanion(')
          ..write('videoId: $videoId, ')
          ..write('channelId: $channelId, ')
          ..write('title: $title, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VideosTable videos = $VideosTable(this);
  late final $AudiosTable audios = $AudiosTable(this);
  late final $TranscriptsTable transcripts = $TranscriptsTable(this);
  late final $TranscriptFetchStatesTable transcriptFetchStates =
      $TranscriptFetchStatesTable(this);
  late final $EchoSessionsTable echoSessions = $EchoSessionsTable(this);
  late final $RecordingsTable recordings = $RecordingsTable(this);
  late final $DictationsTable dictations = $DictationsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $SettingsKvTable settingsKv = $SettingsKvTable(this);
  late final $YoutubeChannelSubscriptionsTable youtubeChannelSubscriptions =
      $YoutubeChannelSubscriptionsTable(this);
  late final $YoutubeFeedEntriesTable youtubeFeedEntries =
      $YoutubeFeedEntriesTable(this);
  late final Index idxTranscriptFetchStatesTarget = Index(
    'idx_transcript_fetch_states_target',
    'CREATE INDEX idx_transcript_fetch_states_target ON transcript_fetch_states (target_type, target_id)',
  );
  late final VideoDao videoDao = VideoDao(this as AppDatabase);
  late final AudioDao audioDao = AudioDao(this as AppDatabase);
  late final TranscriptDao transcriptDao = TranscriptDao(this as AppDatabase);
  late final TranscriptFetchStateDao transcriptFetchStateDao =
      TranscriptFetchStateDao(this as AppDatabase);
  late final EchoSessionDao echoSessionDao = EchoSessionDao(
    this as AppDatabase,
  );
  late final RecordingDao recordingDao = RecordingDao(this as AppDatabase);
  late final DictationDao dictationDao = DictationDao(this as AppDatabase);
  late final SyncQueueDao syncQueueDao = SyncQueueDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final YoutubeChannelSubscriptionDao youtubeChannelSubscriptionDao =
      YoutubeChannelSubscriptionDao(this as AppDatabase);
  late final YoutubeFeedEntryDao youtubeFeedEntryDao = YoutubeFeedEntryDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    videos,
    audios,
    transcripts,
    transcriptFetchStates,
    echoSessions,
    recordings,
    dictations,
    syncQueue,
    settingsKv,
    youtubeChannelSubscriptions,
    youtubeFeedEntries,
    idxTranscriptFetchStatesTarget,
  ];
}

typedef $$VideosTableCreateCompanionBuilder =
    VideosCompanion Function({
      required String id,
      required String vid,
      Value<String> provider,
      required String title,
      Value<String?> description,
      Value<String?> thumbnailUrl,
      Value<int> durationSeconds,
      Value<String> language,
      Value<String?> source,
      Value<String?> localUri,
      Value<String?> md5,
      Value<int?> size,
      Value<String?> mediaUrl,
      Value<String?> syncStatus,
      Value<DateTime?> serverUpdatedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$VideosTableUpdateCompanionBuilder =
    VideosCompanion Function({
      Value<String> id,
      Value<String> vid,
      Value<String> provider,
      Value<String> title,
      Value<String?> description,
      Value<String?> thumbnailUrl,
      Value<int> durationSeconds,
      Value<String> language,
      Value<String?> source,
      Value<String?> localUri,
      Value<String?> md5,
      Value<int?> size,
      Value<String?> mediaUrl,
      Value<String?> syncStatus,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$VideosTableFilterComposer
    extends Composer<_$AppDatabase, $VideosTable> {
  $$VideosTableFilterComposer({
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

  ColumnFilters<String> get vid => $composableBuilder(
    column: $table.vid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
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

  ColumnFilters<String> get localUri => $composableBuilder(
    column: $table.localUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get md5 => $composableBuilder(
    column: $table.md5,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaUrl => $composableBuilder(
    column: $table.mediaUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
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
}

class $$VideosTableOrderingComposer
    extends Composer<_$AppDatabase, $VideosTable> {
  $$VideosTableOrderingComposer({
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

  ColumnOrderings<String> get vid => $composableBuilder(
    column: $table.vid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
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

  ColumnOrderings<String> get localUri => $composableBuilder(
    column: $table.localUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get md5 => $composableBuilder(
    column: $table.md5,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaUrl => $composableBuilder(
    column: $table.mediaUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
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

class $$VideosTableAnnotationComposer
    extends Composer<_$AppDatabase, $VideosTable> {
  $$VideosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vid =>
      $composableBuilder(column: $table.vid, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get localUri =>
      $composableBuilder(column: $table.localUri, builder: (column) => column);

  GeneratedColumn<String> get md5 =>
      $composableBuilder(column: $table.md5, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get mediaUrl =>
      $composableBuilder(column: $table.mediaUrl, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$VideosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VideosTable,
          VideoRow,
          $$VideosTableFilterComposer,
          $$VideosTableOrderingComposer,
          $$VideosTableAnnotationComposer,
          $$VideosTableCreateCompanionBuilder,
          $$VideosTableUpdateCompanionBuilder,
          (VideoRow, BaseReferences<_$AppDatabase, $VideosTable, VideoRow>),
          VideoRow,
          PrefetchHooks Function()
        > {
  $$VideosTableTableManager(_$AppDatabase db, $VideosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VideosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VideosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VideosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> vid = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> localUri = const Value.absent(),
                Value<String?> md5 = const Value.absent(),
                Value<int?> size = const Value.absent(),
                Value<String?> mediaUrl = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VideosCompanion(
                id: id,
                vid: vid,
                provider: provider,
                title: title,
                description: description,
                thumbnailUrl: thumbnailUrl,
                durationSeconds: durationSeconds,
                language: language,
                source: source,
                localUri: localUri,
                md5: md5,
                size: size,
                mediaUrl: mediaUrl,
                syncStatus: syncStatus,
                serverUpdatedAt: serverUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String vid,
                Value<String> provider = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> localUri = const Value.absent(),
                Value<String?> md5 = const Value.absent(),
                Value<int?> size = const Value.absent(),
                Value<String?> mediaUrl = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => VideosCompanion.insert(
                id: id,
                vid: vid,
                provider: provider,
                title: title,
                description: description,
                thumbnailUrl: thumbnailUrl,
                durationSeconds: durationSeconds,
                language: language,
                source: source,
                localUri: localUri,
                md5: md5,
                size: size,
                mediaUrl: mediaUrl,
                syncStatus: syncStatus,
                serverUpdatedAt: serverUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VideosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VideosTable,
      VideoRow,
      $$VideosTableFilterComposer,
      $$VideosTableOrderingComposer,
      $$VideosTableAnnotationComposer,
      $$VideosTableCreateCompanionBuilder,
      $$VideosTableUpdateCompanionBuilder,
      (VideoRow, BaseReferences<_$AppDatabase, $VideosTable, VideoRow>),
      VideoRow,
      PrefetchHooks Function()
    >;
typedef $$AudiosTableCreateCompanionBuilder =
    AudiosCompanion Function({
      required String id,
      required String aid,
      Value<String> provider,
      required String title,
      Value<String?> description,
      Value<String?> thumbnailUrl,
      Value<int> durationSeconds,
      Value<String> language,
      Value<String?> translationKey,
      Value<String?> sourceText,
      Value<String?> voice,
      Value<String?> source,
      Value<String?> localUri,
      Value<String?> md5,
      Value<int?> size,
      Value<String?> mediaUrl,
      Value<String?> syncStatus,
      Value<DateTime?> serverUpdatedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AudiosTableUpdateCompanionBuilder =
    AudiosCompanion Function({
      Value<String> id,
      Value<String> aid,
      Value<String> provider,
      Value<String> title,
      Value<String?> description,
      Value<String?> thumbnailUrl,
      Value<int> durationSeconds,
      Value<String> language,
      Value<String?> translationKey,
      Value<String?> sourceText,
      Value<String?> voice,
      Value<String?> source,
      Value<String?> localUri,
      Value<String?> md5,
      Value<int?> size,
      Value<String?> mediaUrl,
      Value<String?> syncStatus,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AudiosTableFilterComposer
    extends Composer<_$AppDatabase, $AudiosTable> {
  $$AudiosTableFilterComposer({
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

  ColumnFilters<String> get aid => $composableBuilder(
    column: $table.aid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translationKey => $composableBuilder(
    column: $table.translationKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voice => $composableBuilder(
    column: $table.voice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localUri => $composableBuilder(
    column: $table.localUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get md5 => $composableBuilder(
    column: $table.md5,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaUrl => $composableBuilder(
    column: $table.mediaUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
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
}

class $$AudiosTableOrderingComposer
    extends Composer<_$AppDatabase, $AudiosTable> {
  $$AudiosTableOrderingComposer({
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

  ColumnOrderings<String> get aid => $composableBuilder(
    column: $table.aid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translationKey => $composableBuilder(
    column: $table.translationKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voice => $composableBuilder(
    column: $table.voice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localUri => $composableBuilder(
    column: $table.localUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get md5 => $composableBuilder(
    column: $table.md5,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaUrl => $composableBuilder(
    column: $table.mediaUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
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

class $$AudiosTableAnnotationComposer
    extends Composer<_$AppDatabase, $AudiosTable> {
  $$AudiosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get aid =>
      $composableBuilder(column: $table.aid, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get translationKey => $composableBuilder(
    column: $table.translationKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voice =>
      $composableBuilder(column: $table.voice, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get localUri =>
      $composableBuilder(column: $table.localUri, builder: (column) => column);

  GeneratedColumn<String> get md5 =>
      $composableBuilder(column: $table.md5, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get mediaUrl =>
      $composableBuilder(column: $table.mediaUrl, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AudiosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AudiosTable,
          AudioRow,
          $$AudiosTableFilterComposer,
          $$AudiosTableOrderingComposer,
          $$AudiosTableAnnotationComposer,
          $$AudiosTableCreateCompanionBuilder,
          $$AudiosTableUpdateCompanionBuilder,
          (AudioRow, BaseReferences<_$AppDatabase, $AudiosTable, AudioRow>),
          AudioRow,
          PrefetchHooks Function()
        > {
  $$AudiosTableTableManager(_$AppDatabase db, $AudiosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AudiosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AudiosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AudiosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> aid = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String?> translationKey = const Value.absent(),
                Value<String?> sourceText = const Value.absent(),
                Value<String?> voice = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> localUri = const Value.absent(),
                Value<String?> md5 = const Value.absent(),
                Value<int?> size = const Value.absent(),
                Value<String?> mediaUrl = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AudiosCompanion(
                id: id,
                aid: aid,
                provider: provider,
                title: title,
                description: description,
                thumbnailUrl: thumbnailUrl,
                durationSeconds: durationSeconds,
                language: language,
                translationKey: translationKey,
                sourceText: sourceText,
                voice: voice,
                source: source,
                localUri: localUri,
                md5: md5,
                size: size,
                mediaUrl: mediaUrl,
                syncStatus: syncStatus,
                serverUpdatedAt: serverUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String aid,
                Value<String> provider = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String?> translationKey = const Value.absent(),
                Value<String?> sourceText = const Value.absent(),
                Value<String?> voice = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> localUri = const Value.absent(),
                Value<String?> md5 = const Value.absent(),
                Value<int?> size = const Value.absent(),
                Value<String?> mediaUrl = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AudiosCompanion.insert(
                id: id,
                aid: aid,
                provider: provider,
                title: title,
                description: description,
                thumbnailUrl: thumbnailUrl,
                durationSeconds: durationSeconds,
                language: language,
                translationKey: translationKey,
                sourceText: sourceText,
                voice: voice,
                source: source,
                localUri: localUri,
                md5: md5,
                size: size,
                mediaUrl: mediaUrl,
                syncStatus: syncStatus,
                serverUpdatedAt: serverUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AudiosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AudiosTable,
      AudioRow,
      $$AudiosTableFilterComposer,
      $$AudiosTableOrderingComposer,
      $$AudiosTableAnnotationComposer,
      $$AudiosTableCreateCompanionBuilder,
      $$AudiosTableUpdateCompanionBuilder,
      (AudioRow, BaseReferences<_$AppDatabase, $AudiosTable, AudioRow>),
      AudioRow,
      PrefetchHooks Function()
    >;
typedef $$TranscriptsTableCreateCompanionBuilder =
    TranscriptsCompanion Function({
      required String id,
      required String targetType,
      required String targetId,
      required String language,
      required String source,
      required String timelineJson,
      Value<String?> referenceId,
      Value<String> label,
      Value<int?> trackIndex,
      Value<String?> syncStatus,
      Value<DateTime?> serverUpdatedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$TranscriptsTableUpdateCompanionBuilder =
    TranscriptsCompanion Function({
      Value<String> id,
      Value<String> targetType,
      Value<String> targetId,
      Value<String> language,
      Value<String> source,
      Value<String> timelineJson,
      Value<String?> referenceId,
      Value<String> label,
      Value<int?> trackIndex,
      Value<String?> syncStatus,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

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

  ColumnFilters<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
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

  ColumnFilters<String> get timelineJson => $composableBuilder(
    column: $table.timelineJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
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

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
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

  ColumnOrderings<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
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

  ColumnOrderings<String> get timelineJson => $composableBuilder(
    column: $table.timelineJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
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

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
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

  GeneratedColumn<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get timelineJson => $composableBuilder(
    column: $table.timelineJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get trackIndex => $composableBuilder(
    column: $table.trackIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
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
          (
            TranscriptRow,
            BaseReferences<_$AppDatabase, $TranscriptsTable, TranscriptRow>,
          ),
          TranscriptRow,
          PrefetchHooks Function()
        > {
  $$TranscriptsTableTableManager(_$AppDatabase db, $TranscriptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TranscriptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TranscriptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TranscriptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> targetType = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> timelineJson = const Value.absent(),
                Value<String?> referenceId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int?> trackIndex = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TranscriptsCompanion(
                id: id,
                targetType: targetType,
                targetId: targetId,
                language: language,
                source: source,
                timelineJson: timelineJson,
                referenceId: referenceId,
                label: label,
                trackIndex: trackIndex,
                syncStatus: syncStatus,
                serverUpdatedAt: serverUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String targetType,
                required String targetId,
                required String language,
                required String source,
                required String timelineJson,
                Value<String?> referenceId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int?> trackIndex = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TranscriptsCompanion.insert(
                id: id,
                targetType: targetType,
                targetId: targetId,
                language: language,
                source: source,
                timelineJson: timelineJson,
                referenceId: referenceId,
                label: label,
                trackIndex: trackIndex,
                syncStatus: syncStatus,
                serverUpdatedAt: serverUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
      (
        TranscriptRow,
        BaseReferences<_$AppDatabase, $TranscriptsTable, TranscriptRow>,
      ),
      TranscriptRow,
      PrefetchHooks Function()
    >;
typedef $$TranscriptFetchStatesTableCreateCompanionBuilder =
    TranscriptFetchStatesCompanion Function({
      required String targetType,
      required String targetId,
      required DateTime lastFetchedAt,
      Value<String?> lastStatus,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$TranscriptFetchStatesTableUpdateCompanionBuilder =
    TranscriptFetchStatesCompanion Function({
      Value<String> targetType,
      Value<String> targetId,
      Value<DateTime> lastFetchedAt,
      Value<String?> lastStatus,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$TranscriptFetchStatesTableFilterComposer
    extends Composer<_$AppDatabase, $TranscriptFetchStatesTable> {
  $$TranscriptFetchStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastStatus => $composableBuilder(
    column: $table.lastStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TranscriptFetchStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $TranscriptFetchStatesTable> {
  $$TranscriptFetchStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastStatus => $composableBuilder(
    column: $table.lastStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TranscriptFetchStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TranscriptFetchStatesTable> {
  $$TranscriptFetchStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastStatus => $composableBuilder(
    column: $table.lastStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$TranscriptFetchStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TranscriptFetchStatesTable,
          TranscriptFetchStateRow,
          $$TranscriptFetchStatesTableFilterComposer,
          $$TranscriptFetchStatesTableOrderingComposer,
          $$TranscriptFetchStatesTableAnnotationComposer,
          $$TranscriptFetchStatesTableCreateCompanionBuilder,
          $$TranscriptFetchStatesTableUpdateCompanionBuilder,
          (
            TranscriptFetchStateRow,
            BaseReferences<
              _$AppDatabase,
              $TranscriptFetchStatesTable,
              TranscriptFetchStateRow
            >,
          ),
          TranscriptFetchStateRow,
          PrefetchHooks Function()
        > {
  $$TranscriptFetchStatesTableTableManager(
    _$AppDatabase db,
    $TranscriptFetchStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TranscriptFetchStatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TranscriptFetchStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TranscriptFetchStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> targetType = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<DateTime> lastFetchedAt = const Value.absent(),
                Value<String?> lastStatus = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TranscriptFetchStatesCompanion(
                targetType: targetType,
                targetId: targetId,
                lastFetchedAt: lastFetchedAt,
                lastStatus: lastStatus,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String targetType,
                required String targetId,
                required DateTime lastFetchedAt,
                Value<String?> lastStatus = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TranscriptFetchStatesCompanion.insert(
                targetType: targetType,
                targetId: targetId,
                lastFetchedAt: lastFetchedAt,
                lastStatus: lastStatus,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TranscriptFetchStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TranscriptFetchStatesTable,
      TranscriptFetchStateRow,
      $$TranscriptFetchStatesTableFilterComposer,
      $$TranscriptFetchStatesTableOrderingComposer,
      $$TranscriptFetchStatesTableAnnotationComposer,
      $$TranscriptFetchStatesTableCreateCompanionBuilder,
      $$TranscriptFetchStatesTableUpdateCompanionBuilder,
      (
        TranscriptFetchStateRow,
        BaseReferences<
          _$AppDatabase,
          $TranscriptFetchStatesTable,
          TranscriptFetchStateRow
        >,
      ),
      TranscriptFetchStateRow,
      PrefetchHooks Function()
    >;
typedef $$EchoSessionsTableCreateCompanionBuilder =
    EchoSessionsCompanion Function({
      required String id,
      required String targetType,
      required String targetId,
      Value<String> language,
      Value<int> currentTimeMs,
      Value<double> playbackRate,
      Value<double> volume,
      Value<int?> echoStartMs,
      Value<int?> echoEndMs,
      Value<String?> transcriptId,
      Value<String?> secondaryTranscriptId,
      Value<int> recordingsCount,
      Value<int> recordingsDurationMs,
      Value<DateTime?> lastRecordingAt,
      Value<int> currentSegmentIndex,
      Value<bool> echoActive,
      Value<int> echoStartLine,
      Value<int> echoEndLine,
      required DateTime startedAt,
      required DateTime lastActiveAt,
      Value<DateTime?> completedAt,
      Value<String?> syncStatus,
      Value<DateTime?> serverUpdatedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$EchoSessionsTableUpdateCompanionBuilder =
    EchoSessionsCompanion Function({
      Value<String> id,
      Value<String> targetType,
      Value<String> targetId,
      Value<String> language,
      Value<int> currentTimeMs,
      Value<double> playbackRate,
      Value<double> volume,
      Value<int?> echoStartMs,
      Value<int?> echoEndMs,
      Value<String?> transcriptId,
      Value<String?> secondaryTranscriptId,
      Value<int> recordingsCount,
      Value<int> recordingsDurationMs,
      Value<DateTime?> lastRecordingAt,
      Value<int> currentSegmentIndex,
      Value<bool> echoActive,
      Value<int> echoStartLine,
      Value<int> echoEndLine,
      Value<DateTime> startedAt,
      Value<DateTime> lastActiveAt,
      Value<DateTime?> completedAt,
      Value<String?> syncStatus,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$EchoSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $EchoSessionsTable> {
  $$EchoSessionsTableFilterComposer({
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

  ColumnFilters<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentTimeMs => $composableBuilder(
    column: $table.currentTimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get playbackRate => $composableBuilder(
    column: $table.playbackRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get volume => $composableBuilder(
    column: $table.volume,
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

  ColumnFilters<String> get transcriptId => $composableBuilder(
    column: $table.transcriptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secondaryTranscriptId => $composableBuilder(
    column: $table.secondaryTranscriptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordingsCount => $composableBuilder(
    column: $table.recordingsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordingsDurationMs => $composableBuilder(
    column: $table.recordingsDurationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastRecordingAt => $composableBuilder(
    column: $table.lastRecordingAt,
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

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastActiveAt => $composableBuilder(
    column: $table.lastActiveAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
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
}

class $$EchoSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $EchoSessionsTable> {
  $$EchoSessionsTableOrderingComposer({
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

  ColumnOrderings<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentTimeMs => $composableBuilder(
    column: $table.currentTimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get playbackRate => $composableBuilder(
    column: $table.playbackRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get volume => $composableBuilder(
    column: $table.volume,
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

  ColumnOrderings<String> get transcriptId => $composableBuilder(
    column: $table.transcriptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secondaryTranscriptId => $composableBuilder(
    column: $table.secondaryTranscriptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordingsCount => $composableBuilder(
    column: $table.recordingsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordingsDurationMs => $composableBuilder(
    column: $table.recordingsDurationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastRecordingAt => $composableBuilder(
    column: $table.lastRecordingAt,
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

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastActiveAt => $composableBuilder(
    column: $table.lastActiveAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
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

class $$EchoSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EchoSessionsTable> {
  $$EchoSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<int> get currentTimeMs => $composableBuilder(
    column: $table.currentTimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get playbackRate => $composableBuilder(
    column: $table.playbackRate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get volume =>
      $composableBuilder(column: $table.volume, builder: (column) => column);

  GeneratedColumn<int> get echoStartMs => $composableBuilder(
    column: $table.echoStartMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get echoEndMs =>
      $composableBuilder(column: $table.echoEndMs, builder: (column) => column);

  GeneratedColumn<String> get transcriptId => $composableBuilder(
    column: $table.transcriptId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get secondaryTranscriptId => $composableBuilder(
    column: $table.secondaryTranscriptId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recordingsCount => $composableBuilder(
    column: $table.recordingsCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recordingsDurationMs => $composableBuilder(
    column: $table.recordingsDurationMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastRecordingAt => $composableBuilder(
    column: $table.lastRecordingAt,
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

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastActiveAt => $composableBuilder(
    column: $table.lastActiveAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EchoSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EchoSessionsTable,
          EchoSessionRow,
          $$EchoSessionsTableFilterComposer,
          $$EchoSessionsTableOrderingComposer,
          $$EchoSessionsTableAnnotationComposer,
          $$EchoSessionsTableCreateCompanionBuilder,
          $$EchoSessionsTableUpdateCompanionBuilder,
          (
            EchoSessionRow,
            BaseReferences<_$AppDatabase, $EchoSessionsTable, EchoSessionRow>,
          ),
          EchoSessionRow,
          PrefetchHooks Function()
        > {
  $$EchoSessionsTableTableManager(_$AppDatabase db, $EchoSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EchoSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EchoSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EchoSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> targetType = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<int> currentTimeMs = const Value.absent(),
                Value<double> playbackRate = const Value.absent(),
                Value<double> volume = const Value.absent(),
                Value<int?> echoStartMs = const Value.absent(),
                Value<int?> echoEndMs = const Value.absent(),
                Value<String?> transcriptId = const Value.absent(),
                Value<String?> secondaryTranscriptId = const Value.absent(),
                Value<int> recordingsCount = const Value.absent(),
                Value<int> recordingsDurationMs = const Value.absent(),
                Value<DateTime?> lastRecordingAt = const Value.absent(),
                Value<int> currentSegmentIndex = const Value.absent(),
                Value<bool> echoActive = const Value.absent(),
                Value<int> echoStartLine = const Value.absent(),
                Value<int> echoEndLine = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> lastActiveAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EchoSessionsCompanion(
                id: id,
                targetType: targetType,
                targetId: targetId,
                language: language,
                currentTimeMs: currentTimeMs,
                playbackRate: playbackRate,
                volume: volume,
                echoStartMs: echoStartMs,
                echoEndMs: echoEndMs,
                transcriptId: transcriptId,
                secondaryTranscriptId: secondaryTranscriptId,
                recordingsCount: recordingsCount,
                recordingsDurationMs: recordingsDurationMs,
                lastRecordingAt: lastRecordingAt,
                currentSegmentIndex: currentSegmentIndex,
                echoActive: echoActive,
                echoStartLine: echoStartLine,
                echoEndLine: echoEndLine,
                startedAt: startedAt,
                lastActiveAt: lastActiveAt,
                completedAt: completedAt,
                syncStatus: syncStatus,
                serverUpdatedAt: serverUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String targetType,
                required String targetId,
                Value<String> language = const Value.absent(),
                Value<int> currentTimeMs = const Value.absent(),
                Value<double> playbackRate = const Value.absent(),
                Value<double> volume = const Value.absent(),
                Value<int?> echoStartMs = const Value.absent(),
                Value<int?> echoEndMs = const Value.absent(),
                Value<String?> transcriptId = const Value.absent(),
                Value<String?> secondaryTranscriptId = const Value.absent(),
                Value<int> recordingsCount = const Value.absent(),
                Value<int> recordingsDurationMs = const Value.absent(),
                Value<DateTime?> lastRecordingAt = const Value.absent(),
                Value<int> currentSegmentIndex = const Value.absent(),
                Value<bool> echoActive = const Value.absent(),
                Value<int> echoStartLine = const Value.absent(),
                Value<int> echoEndLine = const Value.absent(),
                required DateTime startedAt,
                required DateTime lastActiveAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => EchoSessionsCompanion.insert(
                id: id,
                targetType: targetType,
                targetId: targetId,
                language: language,
                currentTimeMs: currentTimeMs,
                playbackRate: playbackRate,
                volume: volume,
                echoStartMs: echoStartMs,
                echoEndMs: echoEndMs,
                transcriptId: transcriptId,
                secondaryTranscriptId: secondaryTranscriptId,
                recordingsCount: recordingsCount,
                recordingsDurationMs: recordingsDurationMs,
                lastRecordingAt: lastRecordingAt,
                currentSegmentIndex: currentSegmentIndex,
                echoActive: echoActive,
                echoStartLine: echoStartLine,
                echoEndLine: echoEndLine,
                startedAt: startedAt,
                lastActiveAt: lastActiveAt,
                completedAt: completedAt,
                syncStatus: syncStatus,
                serverUpdatedAt: serverUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EchoSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EchoSessionsTable,
      EchoSessionRow,
      $$EchoSessionsTableFilterComposer,
      $$EchoSessionsTableOrderingComposer,
      $$EchoSessionsTableAnnotationComposer,
      $$EchoSessionsTableCreateCompanionBuilder,
      $$EchoSessionsTableUpdateCompanionBuilder,
      (
        EchoSessionRow,
        BaseReferences<_$AppDatabase, $EchoSessionsTable, EchoSessionRow>,
      ),
      EchoSessionRow,
      PrefetchHooks Function()
    >;
typedef $$RecordingsTableCreateCompanionBuilder =
    RecordingsCompanion Function({
      required String id,
      required String targetType,
      required String targetId,
      required int referenceStart,
      required int referenceDuration,
      required String referenceText,
      required String language,
      required int duration,
      Value<String?> md5,
      Value<String?> audioUrl,
      Value<int?> pronunciationScore,
      Value<String?> assessmentJson,
      Value<String?> localPath,
      Value<String?> syncStatus,
      Value<DateTime?> serverUpdatedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$RecordingsTableUpdateCompanionBuilder =
    RecordingsCompanion Function({
      Value<String> id,
      Value<String> targetType,
      Value<String> targetId,
      Value<int> referenceStart,
      Value<int> referenceDuration,
      Value<String> referenceText,
      Value<String> language,
      Value<int> duration,
      Value<String?> md5,
      Value<String?> audioUrl,
      Value<int?> pronunciationScore,
      Value<String?> assessmentJson,
      Value<String?> localPath,
      Value<String?> syncStatus,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$RecordingsTableFilterComposer
    extends Composer<_$AppDatabase, $RecordingsTable> {
  $$RecordingsTableFilterComposer({
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

  ColumnFilters<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get referenceStart => $composableBuilder(
    column: $table.referenceStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get referenceDuration => $composableBuilder(
    column: $table.referenceDuration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceText => $composableBuilder(
    column: $table.referenceText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get md5 => $composableBuilder(
    column: $table.md5,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pronunciationScore => $composableBuilder(
    column: $table.pronunciationScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assessmentJson => $composableBuilder(
    column: $table.assessmentJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
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
}

class $$RecordingsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecordingsTable> {
  $$RecordingsTableOrderingComposer({
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

  ColumnOrderings<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get referenceStart => $composableBuilder(
    column: $table.referenceStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get referenceDuration => $composableBuilder(
    column: $table.referenceDuration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceText => $composableBuilder(
    column: $table.referenceText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get md5 => $composableBuilder(
    column: $table.md5,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pronunciationScore => $composableBuilder(
    column: $table.pronunciationScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assessmentJson => $composableBuilder(
    column: $table.assessmentJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
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

class $$RecordingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecordingsTable> {
  $$RecordingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<int> get referenceStart => $composableBuilder(
    column: $table.referenceStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get referenceDuration => $composableBuilder(
    column: $table.referenceDuration,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceText => $composableBuilder(
    column: $table.referenceText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get md5 =>
      $composableBuilder(column: $table.md5, builder: (column) => column);

  GeneratedColumn<String> get audioUrl =>
      $composableBuilder(column: $table.audioUrl, builder: (column) => column);

  GeneratedColumn<int> get pronunciationScore => $composableBuilder(
    column: $table.pronunciationScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assessmentJson => $composableBuilder(
    column: $table.assessmentJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RecordingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecordingsTable,
          RecordingRow,
          $$RecordingsTableFilterComposer,
          $$RecordingsTableOrderingComposer,
          $$RecordingsTableAnnotationComposer,
          $$RecordingsTableCreateCompanionBuilder,
          $$RecordingsTableUpdateCompanionBuilder,
          (
            RecordingRow,
            BaseReferences<_$AppDatabase, $RecordingsTable, RecordingRow>,
          ),
          RecordingRow,
          PrefetchHooks Function()
        > {
  $$RecordingsTableTableManager(_$AppDatabase db, $RecordingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> targetType = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<int> referenceStart = const Value.absent(),
                Value<int> referenceDuration = const Value.absent(),
                Value<String> referenceText = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<String?> md5 = const Value.absent(),
                Value<String?> audioUrl = const Value.absent(),
                Value<int?> pronunciationScore = const Value.absent(),
                Value<String?> assessmentJson = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecordingsCompanion(
                id: id,
                targetType: targetType,
                targetId: targetId,
                referenceStart: referenceStart,
                referenceDuration: referenceDuration,
                referenceText: referenceText,
                language: language,
                duration: duration,
                md5: md5,
                audioUrl: audioUrl,
                pronunciationScore: pronunciationScore,
                assessmentJson: assessmentJson,
                localPath: localPath,
                syncStatus: syncStatus,
                serverUpdatedAt: serverUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String targetType,
                required String targetId,
                required int referenceStart,
                required int referenceDuration,
                required String referenceText,
                required String language,
                required int duration,
                Value<String?> md5 = const Value.absent(),
                Value<String?> audioUrl = const Value.absent(),
                Value<int?> pronunciationScore = const Value.absent(),
                Value<String?> assessmentJson = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => RecordingsCompanion.insert(
                id: id,
                targetType: targetType,
                targetId: targetId,
                referenceStart: referenceStart,
                referenceDuration: referenceDuration,
                referenceText: referenceText,
                language: language,
                duration: duration,
                md5: md5,
                audioUrl: audioUrl,
                pronunciationScore: pronunciationScore,
                assessmentJson: assessmentJson,
                localPath: localPath,
                syncStatus: syncStatus,
                serverUpdatedAt: serverUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecordingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecordingsTable,
      RecordingRow,
      $$RecordingsTableFilterComposer,
      $$RecordingsTableOrderingComposer,
      $$RecordingsTableAnnotationComposer,
      $$RecordingsTableCreateCompanionBuilder,
      $$RecordingsTableUpdateCompanionBuilder,
      (
        RecordingRow,
        BaseReferences<_$AppDatabase, $RecordingsTable, RecordingRow>,
      ),
      RecordingRow,
      PrefetchHooks Function()
    >;
typedef $$DictationsTableCreateCompanionBuilder =
    DictationsCompanion Function({
      required String id,
      required String targetType,
      required String targetId,
      required int referenceStartMs,
      required int referenceDurationMs,
      required String referenceText,
      required String language,
      required String userInput,
      required int accuracy,
      required int correctWords,
      required int missedWords,
      required int extraWords,
      Value<String?> syncStatus,
      Value<DateTime?> serverUpdatedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DictationsTableUpdateCompanionBuilder =
    DictationsCompanion Function({
      Value<String> id,
      Value<String> targetType,
      Value<String> targetId,
      Value<int> referenceStartMs,
      Value<int> referenceDurationMs,
      Value<String> referenceText,
      Value<String> language,
      Value<String> userInput,
      Value<int> accuracy,
      Value<int> correctWords,
      Value<int> missedWords,
      Value<int> extraWords,
      Value<String?> syncStatus,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DictationsTableFilterComposer
    extends Composer<_$AppDatabase, $DictationsTable> {
  $$DictationsTableFilterComposer({
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

  ColumnFilters<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get referenceStartMs => $composableBuilder(
    column: $table.referenceStartMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get referenceDurationMs => $composableBuilder(
    column: $table.referenceDurationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceText => $composableBuilder(
    column: $table.referenceText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userInput => $composableBuilder(
    column: $table.userInput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctWords => $composableBuilder(
    column: $table.correctWords,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get missedWords => $composableBuilder(
    column: $table.missedWords,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get extraWords => $composableBuilder(
    column: $table.extraWords,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
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
}

class $$DictationsTableOrderingComposer
    extends Composer<_$AppDatabase, $DictationsTable> {
  $$DictationsTableOrderingComposer({
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

  ColumnOrderings<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get referenceStartMs => $composableBuilder(
    column: $table.referenceStartMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get referenceDurationMs => $composableBuilder(
    column: $table.referenceDurationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceText => $composableBuilder(
    column: $table.referenceText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userInput => $composableBuilder(
    column: $table.userInput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctWords => $composableBuilder(
    column: $table.correctWords,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get missedWords => $composableBuilder(
    column: $table.missedWords,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get extraWords => $composableBuilder(
    column: $table.extraWords,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
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

class $$DictationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictationsTable> {
  $$DictationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<int> get referenceStartMs => $composableBuilder(
    column: $table.referenceStartMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get referenceDurationMs => $composableBuilder(
    column: $table.referenceDurationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceText => $composableBuilder(
    column: $table.referenceText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get userInput =>
      $composableBuilder(column: $table.userInput, builder: (column) => column);

  GeneratedColumn<int> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<int> get correctWords => $composableBuilder(
    column: $table.correctWords,
    builder: (column) => column,
  );

  GeneratedColumn<int> get missedWords => $composableBuilder(
    column: $table.missedWords,
    builder: (column) => column,
  );

  GeneratedColumn<int> get extraWords => $composableBuilder(
    column: $table.extraWords,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DictationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictationsTable,
          DictationRow,
          $$DictationsTableFilterComposer,
          $$DictationsTableOrderingComposer,
          $$DictationsTableAnnotationComposer,
          $$DictationsTableCreateCompanionBuilder,
          $$DictationsTableUpdateCompanionBuilder,
          (
            DictationRow,
            BaseReferences<_$AppDatabase, $DictationsTable, DictationRow>,
          ),
          DictationRow,
          PrefetchHooks Function()
        > {
  $$DictationsTableTableManager(_$AppDatabase db, $DictationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DictationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DictationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> targetType = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<int> referenceStartMs = const Value.absent(),
                Value<int> referenceDurationMs = const Value.absent(),
                Value<String> referenceText = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> userInput = const Value.absent(),
                Value<int> accuracy = const Value.absent(),
                Value<int> correctWords = const Value.absent(),
                Value<int> missedWords = const Value.absent(),
                Value<int> extraWords = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DictationsCompanion(
                id: id,
                targetType: targetType,
                targetId: targetId,
                referenceStartMs: referenceStartMs,
                referenceDurationMs: referenceDurationMs,
                referenceText: referenceText,
                language: language,
                userInput: userInput,
                accuracy: accuracy,
                correctWords: correctWords,
                missedWords: missedWords,
                extraWords: extraWords,
                syncStatus: syncStatus,
                serverUpdatedAt: serverUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String targetType,
                required String targetId,
                required int referenceStartMs,
                required int referenceDurationMs,
                required String referenceText,
                required String language,
                required String userInput,
                required int accuracy,
                required int correctWords,
                required int missedWords,
                required int extraWords,
                Value<String?> syncStatus = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DictationsCompanion.insert(
                id: id,
                targetType: targetType,
                targetId: targetId,
                referenceStartMs: referenceStartMs,
                referenceDurationMs: referenceDurationMs,
                referenceText: referenceText,
                language: language,
                userInput: userInput,
                accuracy: accuracy,
                correctWords: correctWords,
                missedWords: missedWords,
                extraWords: extraWords,
                syncStatus: syncStatus,
                serverUpdatedAt: serverUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DictationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictationsTable,
      DictationRow,
      $$DictationsTableFilterComposer,
      $$DictationsTableOrderingComposer,
      $$DictationsTableAnnotationComposer,
      $$DictationsTableCreateCompanionBuilder,
      $$DictationsTableUpdateCompanionBuilder,
      (
        DictationRow,
        BaseReferences<_$AppDatabase, $DictationsTable, DictationRow>,
      ),
      DictationRow,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      required String entityType,
      required String entityId,
      required String action,
      Value<String?> payloadJson,
      Value<int> retryCount,
      Value<DateTime?> lastAttempt,
      Value<String?> error,
      required DateTime createdAt,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> action,
      Value<String?> payloadJson,
      Value<int> retryCount,
      Value<DateTime?> lastAttempt,
      Value<String?> error,
      Value<DateTime> createdAt,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
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

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttempt => $composableBuilder(
    column: $table.lastAttempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
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

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttempt => $composableBuilder(
    column: $table.lastAttempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAttempt => $composableBuilder(
    column: $table.lastAttempt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueRow,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueRow,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueRow>,
          ),
          SyncQueueRow,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String?> payloadJson = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> lastAttempt = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                action: action,
                payloadJson: payloadJson,
                retryCount: retryCount,
                lastAttempt: lastAttempt,
                error: error,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityType,
                required String entityId,
                required String action,
                Value<String?> payloadJson = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> lastAttempt = const Value.absent(),
                Value<String?> error = const Value.absent(),
                required DateTime createdAt,
              }) => SyncQueueCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                action: action,
                payloadJson: payloadJson,
                retryCount: retryCount,
                lastAttempt: lastAttempt,
                error: error,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueRow,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueRow,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueRow>,
      ),
      SyncQueueRow,
      PrefetchHooks Function()
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
          createFilteringComposer: () =>
              $$SettingsKvTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsKvTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsKvTableAnnotationComposer($db: db, $table: table),
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
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
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
typedef $$YoutubeChannelSubscriptionsTableCreateCompanionBuilder =
    YoutubeChannelSubscriptionsCompanion Function({
      required String channelId,
      required String displayName,
      Value<String?> thumbnailUrl,
      Value<YoutubeSubscriptionSource> source,
      required DateTime subscribedAt,
      Value<DateTime?> lastFetchedAt,
      Value<int> rowid,
    });
typedef $$YoutubeChannelSubscriptionsTableUpdateCompanionBuilder =
    YoutubeChannelSubscriptionsCompanion Function({
      Value<String> channelId,
      Value<String> displayName,
      Value<String?> thumbnailUrl,
      Value<YoutubeSubscriptionSource> source,
      Value<DateTime> subscribedAt,
      Value<DateTime?> lastFetchedAt,
      Value<int> rowid,
    });

class $$YoutubeChannelSubscriptionsTableFilterComposer
    extends Composer<_$AppDatabase, $YoutubeChannelSubscriptionsTable> {
  $$YoutubeChannelSubscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    YoutubeSubscriptionSource,
    YoutubeSubscriptionSource,
    String
  >
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get subscribedAt => $composableBuilder(
    column: $table.subscribedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$YoutubeChannelSubscriptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $YoutubeChannelSubscriptionsTable> {
  $$YoutubeChannelSubscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get subscribedAt => $composableBuilder(
    column: $table.subscribedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$YoutubeChannelSubscriptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $YoutubeChannelSubscriptionsTable> {
  $$YoutubeChannelSubscriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<YoutubeSubscriptionSource, String>
  get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get subscribedAt => $composableBuilder(
    column: $table.subscribedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => column,
  );
}

class $$YoutubeChannelSubscriptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $YoutubeChannelSubscriptionsTable,
          YoutubeChannelSubscriptionRow,
          $$YoutubeChannelSubscriptionsTableFilterComposer,
          $$YoutubeChannelSubscriptionsTableOrderingComposer,
          $$YoutubeChannelSubscriptionsTableAnnotationComposer,
          $$YoutubeChannelSubscriptionsTableCreateCompanionBuilder,
          $$YoutubeChannelSubscriptionsTableUpdateCompanionBuilder,
          (
            YoutubeChannelSubscriptionRow,
            BaseReferences<
              _$AppDatabase,
              $YoutubeChannelSubscriptionsTable,
              YoutubeChannelSubscriptionRow
            >,
          ),
          YoutubeChannelSubscriptionRow,
          PrefetchHooks Function()
        > {
  $$YoutubeChannelSubscriptionsTableTableManager(
    _$AppDatabase db,
    $YoutubeChannelSubscriptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$YoutubeChannelSubscriptionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$YoutubeChannelSubscriptionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$YoutubeChannelSubscriptionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> channelId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<YoutubeSubscriptionSource> source = const Value.absent(),
                Value<DateTime> subscribedAt = const Value.absent(),
                Value<DateTime?> lastFetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => YoutubeChannelSubscriptionsCompanion(
                channelId: channelId,
                displayName: displayName,
                thumbnailUrl: thumbnailUrl,
                source: source,
                subscribedAt: subscribedAt,
                lastFetchedAt: lastFetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String channelId,
                required String displayName,
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<YoutubeSubscriptionSource> source = const Value.absent(),
                required DateTime subscribedAt,
                Value<DateTime?> lastFetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => YoutubeChannelSubscriptionsCompanion.insert(
                channelId: channelId,
                displayName: displayName,
                thumbnailUrl: thumbnailUrl,
                source: source,
                subscribedAt: subscribedAt,
                lastFetchedAt: lastFetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$YoutubeChannelSubscriptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $YoutubeChannelSubscriptionsTable,
      YoutubeChannelSubscriptionRow,
      $$YoutubeChannelSubscriptionsTableFilterComposer,
      $$YoutubeChannelSubscriptionsTableOrderingComposer,
      $$YoutubeChannelSubscriptionsTableAnnotationComposer,
      $$YoutubeChannelSubscriptionsTableCreateCompanionBuilder,
      $$YoutubeChannelSubscriptionsTableUpdateCompanionBuilder,
      (
        YoutubeChannelSubscriptionRow,
        BaseReferences<
          _$AppDatabase,
          $YoutubeChannelSubscriptionsTable,
          YoutubeChannelSubscriptionRow
        >,
      ),
      YoutubeChannelSubscriptionRow,
      PrefetchHooks Function()
    >;
typedef $$YoutubeFeedEntriesTableCreateCompanionBuilder =
    YoutubeFeedEntriesCompanion Function({
      required String videoId,
      required String channelId,
      required String title,
      Value<String?> thumbnailUrl,
      Value<int?> durationSeconds,
      required DateTime publishedAt,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$YoutubeFeedEntriesTableUpdateCompanionBuilder =
    YoutubeFeedEntriesCompanion Function({
      Value<String> videoId,
      Value<String> channelId,
      Value<String> title,
      Value<String?> thumbnailUrl,
      Value<int?> durationSeconds,
      Value<DateTime> publishedAt,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$YoutubeFeedEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $YoutubeFeedEntriesTable> {
  $$YoutubeFeedEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$YoutubeFeedEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $YoutubeFeedEntriesTable> {
  $$YoutubeFeedEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$YoutubeFeedEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $YoutubeFeedEntriesTable> {
  $$YoutubeFeedEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$YoutubeFeedEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $YoutubeFeedEntriesTable,
          YoutubeFeedEntryRow,
          $$YoutubeFeedEntriesTableFilterComposer,
          $$YoutubeFeedEntriesTableOrderingComposer,
          $$YoutubeFeedEntriesTableAnnotationComposer,
          $$YoutubeFeedEntriesTableCreateCompanionBuilder,
          $$YoutubeFeedEntriesTableUpdateCompanionBuilder,
          (
            YoutubeFeedEntryRow,
            BaseReferences<
              _$AppDatabase,
              $YoutubeFeedEntriesTable,
              YoutubeFeedEntryRow
            >,
          ),
          YoutubeFeedEntryRow,
          PrefetchHooks Function()
        > {
  $$YoutubeFeedEntriesTableTableManager(
    _$AppDatabase db,
    $YoutubeFeedEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$YoutubeFeedEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$YoutubeFeedEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$YoutubeFeedEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> videoId = const Value.absent(),
                Value<String> channelId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<DateTime> publishedAt = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => YoutubeFeedEntriesCompanion(
                videoId: videoId,
                channelId: channelId,
                title: title,
                thumbnailUrl: thumbnailUrl,
                durationSeconds: durationSeconds,
                publishedAt: publishedAt,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String videoId,
                required String channelId,
                required String title,
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                required DateTime publishedAt,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => YoutubeFeedEntriesCompanion.insert(
                videoId: videoId,
                channelId: channelId,
                title: title,
                thumbnailUrl: thumbnailUrl,
                durationSeconds: durationSeconds,
                publishedAt: publishedAt,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$YoutubeFeedEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $YoutubeFeedEntriesTable,
      YoutubeFeedEntryRow,
      $$YoutubeFeedEntriesTableFilterComposer,
      $$YoutubeFeedEntriesTableOrderingComposer,
      $$YoutubeFeedEntriesTableAnnotationComposer,
      $$YoutubeFeedEntriesTableCreateCompanionBuilder,
      $$YoutubeFeedEntriesTableUpdateCompanionBuilder,
      (
        YoutubeFeedEntryRow,
        BaseReferences<
          _$AppDatabase,
          $YoutubeFeedEntriesTable,
          YoutubeFeedEntryRow
        >,
      ),
      YoutubeFeedEntryRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VideosTableTableManager get videos =>
      $$VideosTableTableManager(_db, _db.videos);
  $$AudiosTableTableManager get audios =>
      $$AudiosTableTableManager(_db, _db.audios);
  $$TranscriptsTableTableManager get transcripts =>
      $$TranscriptsTableTableManager(_db, _db.transcripts);
  $$TranscriptFetchStatesTableTableManager get transcriptFetchStates =>
      $$TranscriptFetchStatesTableTableManager(_db, _db.transcriptFetchStates);
  $$EchoSessionsTableTableManager get echoSessions =>
      $$EchoSessionsTableTableManager(_db, _db.echoSessions);
  $$RecordingsTableTableManager get recordings =>
      $$RecordingsTableTableManager(_db, _db.recordings);
  $$DictationsTableTableManager get dictations =>
      $$DictationsTableTableManager(_db, _db.dictations);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$SettingsKvTableTableManager get settingsKv =>
      $$SettingsKvTableTableManager(_db, _db.settingsKv);
  $$YoutubeChannelSubscriptionsTableTableManager
  get youtubeChannelSubscriptions =>
      $$YoutubeChannelSubscriptionsTableTableManager(
        _db,
        _db.youtubeChannelSubscriptions,
      );
  $$YoutubeFeedEntriesTableTableManager get youtubeFeedEntries =>
      $$YoutubeFeedEntriesTableTableManager(_db, _db.youtubeFeedEntries);
}

mixin _$VideoDaoMixin on DatabaseAccessor<AppDatabase> {
  $VideosTable get videos => attachedDatabase.videos;
  VideoDaoManager get managers => VideoDaoManager(this);
}

class VideoDaoManager {
  final _$VideoDaoMixin _db;
  VideoDaoManager(this._db);
  $$VideosTableTableManager get videos =>
      $$VideosTableTableManager(_db.attachedDatabase, _db.videos);
}

mixin _$AudioDaoMixin on DatabaseAccessor<AppDatabase> {
  $AudiosTable get audios => attachedDatabase.audios;
  AudioDaoManager get managers => AudioDaoManager(this);
}

class AudioDaoManager {
  final _$AudioDaoMixin _db;
  AudioDaoManager(this._db);
  $$AudiosTableTableManager get audios =>
      $$AudiosTableTableManager(_db.attachedDatabase, _db.audios);
}

mixin _$TranscriptDaoMixin on DatabaseAccessor<AppDatabase> {
  $TranscriptsTable get transcripts => attachedDatabase.transcripts;
  TranscriptDaoManager get managers => TranscriptDaoManager(this);
}

class TranscriptDaoManager {
  final _$TranscriptDaoMixin _db;
  TranscriptDaoManager(this._db);
  $$TranscriptsTableTableManager get transcripts =>
      $$TranscriptsTableTableManager(_db.attachedDatabase, _db.transcripts);
}

mixin _$TranscriptFetchStateDaoMixin on DatabaseAccessor<AppDatabase> {
  $TranscriptFetchStatesTable get transcriptFetchStates =>
      attachedDatabase.transcriptFetchStates;
  TranscriptFetchStateDaoManager get managers =>
      TranscriptFetchStateDaoManager(this);
}

class TranscriptFetchStateDaoManager {
  final _$TranscriptFetchStateDaoMixin _db;
  TranscriptFetchStateDaoManager(this._db);
  $$TranscriptFetchStatesTableTableManager get transcriptFetchStates =>
      $$TranscriptFetchStatesTableTableManager(
        _db.attachedDatabase,
        _db.transcriptFetchStates,
      );
}

mixin _$EchoSessionDaoMixin on DatabaseAccessor<AppDatabase> {
  $EchoSessionsTable get echoSessions => attachedDatabase.echoSessions;
  EchoSessionDaoManager get managers => EchoSessionDaoManager(this);
}

class EchoSessionDaoManager {
  final _$EchoSessionDaoMixin _db;
  EchoSessionDaoManager(this._db);
  $$EchoSessionsTableTableManager get echoSessions =>
      $$EchoSessionsTableTableManager(_db.attachedDatabase, _db.echoSessions);
}

mixin _$RecordingDaoMixin on DatabaseAccessor<AppDatabase> {
  $RecordingsTable get recordings => attachedDatabase.recordings;
  RecordingDaoManager get managers => RecordingDaoManager(this);
}

class RecordingDaoManager {
  final _$RecordingDaoMixin _db;
  RecordingDaoManager(this._db);
  $$RecordingsTableTableManager get recordings =>
      $$RecordingsTableTableManager(_db.attachedDatabase, _db.recordings);
}

mixin _$DictationDaoMixin on DatabaseAccessor<AppDatabase> {
  $DictationsTable get dictations => attachedDatabase.dictations;
  DictationDaoManager get managers => DictationDaoManager(this);
}

class DictationDaoManager {
  final _$DictationDaoMixin _db;
  DictationDaoManager(this._db);
  $$DictationsTableTableManager get dictations =>
      $$DictationsTableTableManager(_db.attachedDatabase, _db.dictations);
}

mixin _$SyncQueueDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncQueueTable get syncQueue => attachedDatabase.syncQueue;
  SyncQueueDaoManager get managers => SyncQueueDaoManager(this);
}

class SyncQueueDaoManager {
  final _$SyncQueueDaoMixin _db;
  SyncQueueDaoManager(this._db);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db.attachedDatabase, _db.syncQueue);
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

mixin _$YoutubeChannelSubscriptionDaoMixin on DatabaseAccessor<AppDatabase> {
  $YoutubeChannelSubscriptionsTable get youtubeChannelSubscriptions =>
      attachedDatabase.youtubeChannelSubscriptions;
  YoutubeChannelSubscriptionDaoManager get managers =>
      YoutubeChannelSubscriptionDaoManager(this);
}

class YoutubeChannelSubscriptionDaoManager {
  final _$YoutubeChannelSubscriptionDaoMixin _db;
  YoutubeChannelSubscriptionDaoManager(this._db);
  $$YoutubeChannelSubscriptionsTableTableManager
  get youtubeChannelSubscriptions =>
      $$YoutubeChannelSubscriptionsTableTableManager(
        _db.attachedDatabase,
        _db.youtubeChannelSubscriptions,
      );
}

mixin _$YoutubeFeedEntryDaoMixin on DatabaseAccessor<AppDatabase> {
  $YoutubeFeedEntriesTable get youtubeFeedEntries =>
      attachedDatabase.youtubeFeedEntries;
  YoutubeFeedEntryDaoManager get managers => YoutubeFeedEntryDaoManager(this);
}

class YoutubeFeedEntryDaoManager {
  final _$YoutubeFeedEntryDaoMixin _db;
  YoutubeFeedEntryDaoManager(this._db);
  $$YoutubeFeedEntriesTableTableManager get youtubeFeedEntries =>
      $$YoutubeFeedEntriesTableTableManager(
        _db.attachedDatabase,
        _db.youtubeFeedEntries,
      );
}
