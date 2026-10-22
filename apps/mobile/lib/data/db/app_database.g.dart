// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocationTableTable extends LocationTable
    with TableInfo<$LocationTableTable, LocationTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocationTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocationSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocationSource>($LocationTableTable.$convertersource);
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cityIdMeta = const VerificationMeta('cityId');
  @override
  late final GeneratedColumn<int> cityId = GeneratedColumn<int>(
    'city_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _timeZoneIdMeta = const VerificationMeta(
    'timeZoneId',
  );
  @override
  late final GeneratedColumn<String> timeZoneId = GeneratedColumn<String>(
    'time_zone_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countryCodeMeta = const VerificationMeta(
    'countryCode',
  );
  @override
  late final GeneratedColumn<String> countryCode = GeneratedColumn<String>(
    'country_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    source,
    latitude,
    longitude,
    cityId,
    displayName,
    timeZoneId,
    countryCode,
    updatedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'location';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocationTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('city_id')) {
      context.handle(
        _cityIdMeta,
        cityId.isAcceptableOrUnknown(data['city_id']!, _cityIdMeta),
      );
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
    if (data.containsKey('time_zone_id')) {
      context.handle(
        _timeZoneIdMeta,
        timeZoneId.isAcceptableOrUnknown(
          data['time_zone_id']!,
          _timeZoneIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeZoneIdMeta);
    }
    if (data.containsKey('country_code')) {
      context.handle(
        _countryCodeMeta,
        countryCode.isAcceptableOrUnknown(
          data['country_code']!,
          _countryCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_countryCodeMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocationTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocationTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      source: $LocationTableTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      cityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}city_id'],
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      timeZoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone_id'],
      )!,
      countryCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country_code'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
    );
  }

  @override
  $LocationTableTable createAlias(String alias) {
    return $LocationTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LocationSource, String, String> $convertersource =
      const EnumNameConverter<LocationSource>(LocationSource.values);
}

class LocationTableData extends DataClass
    implements Insertable<LocationTableData> {
  final int id;
  final LocationSource source;
  final double latitude;
  final double longitude;
  final int? cityId;
  final String displayName;
  final String timeZoneId;
  final String countryCode;
  final int updatedAtMs;
  const LocationTableData({
    required this.id,
    required this.source,
    required this.latitude,
    required this.longitude,
    this.cityId,
    required this.displayName,
    required this.timeZoneId,
    required this.countryCode,
    required this.updatedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['source'] = Variable<String>(
        $LocationTableTable.$convertersource.toSql(source),
      );
    }
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || cityId != null) {
      map['city_id'] = Variable<int>(cityId);
    }
    map['display_name'] = Variable<String>(displayName);
    map['time_zone_id'] = Variable<String>(timeZoneId);
    map['country_code'] = Variable<String>(countryCode);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    return map;
  }

  LocationTableCompanion toCompanion(bool nullToAbsent) {
    return LocationTableCompanion(
      id: Value(id),
      source: Value(source),
      latitude: Value(latitude),
      longitude: Value(longitude),
      cityId: cityId == null && nullToAbsent
          ? const Value.absent()
          : Value(cityId),
      displayName: Value(displayName),
      timeZoneId: Value(timeZoneId),
      countryCode: Value(countryCode),
      updatedAtMs: Value(updatedAtMs),
    );
  }

  factory LocationTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocationTableData(
      id: serializer.fromJson<int>(json['id']),
      source: $LocationTableTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      cityId: serializer.fromJson<int?>(json['cityId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      timeZoneId: serializer.fromJson<String>(json['timeZoneId']),
      countryCode: serializer.fromJson<String>(json['countryCode']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'source': serializer.toJson<String>(
        $LocationTableTable.$convertersource.toJson(source),
      ),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'cityId': serializer.toJson<int?>(cityId),
      'displayName': serializer.toJson<String>(displayName),
      'timeZoneId': serializer.toJson<String>(timeZoneId),
      'countryCode': serializer.toJson<String>(countryCode),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
    };
  }

  LocationTableData copyWith({
    int? id,
    LocationSource? source,
    double? latitude,
    double? longitude,
    Value<int?> cityId = const Value.absent(),
    String? displayName,
    String? timeZoneId,
    String? countryCode,
    int? updatedAtMs,
  }) => LocationTableData(
    id: id ?? this.id,
    source: source ?? this.source,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    cityId: cityId.present ? cityId.value : this.cityId,
    displayName: displayName ?? this.displayName,
    timeZoneId: timeZoneId ?? this.timeZoneId,
    countryCode: countryCode ?? this.countryCode,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
  );
  LocationTableData copyWithCompanion(LocationTableCompanion data) {
    return LocationTableData(
      id: data.id.present ? data.id.value : this.id,
      source: data.source.present ? data.source.value : this.source,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      cityId: data.cityId.present ? data.cityId.value : this.cityId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      timeZoneId: data.timeZoneId.present
          ? data.timeZoneId.value
          : this.timeZoneId,
      countryCode: data.countryCode.present
          ? data.countryCode.value
          : this.countryCode,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocationTableData(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('cityId: $cityId, ')
          ..write('displayName: $displayName, ')
          ..write('timeZoneId: $timeZoneId, ')
          ..write('countryCode: $countryCode, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    source,
    latitude,
    longitude,
    cityId,
    displayName,
    timeZoneId,
    countryCode,
    updatedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocationTableData &&
          other.id == this.id &&
          other.source == this.source &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.cityId == this.cityId &&
          other.displayName == this.displayName &&
          other.timeZoneId == this.timeZoneId &&
          other.countryCode == this.countryCode &&
          other.updatedAtMs == this.updatedAtMs);
}

class LocationTableCompanion extends UpdateCompanion<LocationTableData> {
  final Value<int> id;
  final Value<LocationSource> source;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<int?> cityId;
  final Value<String> displayName;
  final Value<String> timeZoneId;
  final Value<String> countryCode;
  final Value<int> updatedAtMs;
  const LocationTableCompanion({
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.cityId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.timeZoneId = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
  });
  LocationTableCompanion.insert({
    this.id = const Value.absent(),
    required LocationSource source,
    required double latitude,
    required double longitude,
    this.cityId = const Value.absent(),
    required String displayName,
    required String timeZoneId,
    required String countryCode,
    required int updatedAtMs,
  }) : source = Value(source),
       latitude = Value(latitude),
       longitude = Value(longitude),
       displayName = Value(displayName),
       timeZoneId = Value(timeZoneId),
       countryCode = Value(countryCode),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<LocationTableData> custom({
    Expression<int>? id,
    Expression<String>? source,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? cityId,
    Expression<String>? displayName,
    Expression<String>? timeZoneId,
    Expression<String>? countryCode,
    Expression<int>? updatedAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (source != null) 'source': source,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (cityId != null) 'city_id': cityId,
      if (displayName != null) 'display_name': displayName,
      if (timeZoneId != null) 'time_zone_id': timeZoneId,
      if (countryCode != null) 'country_code': countryCode,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
    });
  }

  LocationTableCompanion copyWith({
    Value<int>? id,
    Value<LocationSource>? source,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<int?>? cityId,
    Value<String>? displayName,
    Value<String>? timeZoneId,
    Value<String>? countryCode,
    Value<int>? updatedAtMs,
  }) {
    return LocationTableCompanion(
      id: id ?? this.id,
      source: source ?? this.source,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cityId: cityId ?? this.cityId,
      displayName: displayName ?? this.displayName,
      timeZoneId: timeZoneId ?? this.timeZoneId,
      countryCode: countryCode ?? this.countryCode,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $LocationTableTable.$convertersource.toSql(source.value),
      );
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (cityId.present) {
      map['city_id'] = Variable<int>(cityId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (timeZoneId.present) {
      map['time_zone_id'] = Variable<String>(timeZoneId.value);
    }
    if (countryCode.present) {
      map['country_code'] = Variable<String>(countryCode.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocationTableCompanion(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('cityId: $cityId, ')
          ..write('displayName: $displayName, ')
          ..write('timeZoneId: $timeZoneId, ')
          ..write('countryCode: $countryCode, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }
}

class $PrayerSettingsTableTable extends PrayerSettingsTable
    with TableInfo<$PrayerSettingsTableTable, PrayerSettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrayerSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<engine.CalculationMethod, String>
  method =
      GeneratedColumn<String>(
        'method',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<engine.CalculationMethod>(
        $PrayerSettingsTableTable.$convertermethod,
      );
  @override
  late final GeneratedColumnWithTypeConverter<engine.AsrMethod, String>
  asrMethod =
      GeneratedColumn<String>(
        'asr_method',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<engine.AsrMethod>(
        $PrayerSettingsTableTable.$converterasrMethod,
      );
  @override
  late final GeneratedColumnWithTypeConverter<engine.HighLatitudeRule, String>
  highLatitudeRule =
      GeneratedColumn<String>(
        'high_latitude_rule',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<engine.HighLatitudeRule>(
        $PrayerSettingsTableTable.$converterhighLatitudeRule,
      );
  static const VerificationMeta _offsetFajrMeta = const VerificationMeta(
    'offsetFajr',
  );
  @override
  late final GeneratedColumn<int> offsetFajr = GeneratedColumn<int>(
    'offset_fajr',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _offsetSunriseMeta = const VerificationMeta(
    'offsetSunrise',
  );
  @override
  late final GeneratedColumn<int> offsetSunrise = GeneratedColumn<int>(
    'offset_sunrise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _offsetDhuhrMeta = const VerificationMeta(
    'offsetDhuhr',
  );
  @override
  late final GeneratedColumn<int> offsetDhuhr = GeneratedColumn<int>(
    'offset_dhuhr',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _offsetAsrMeta = const VerificationMeta(
    'offsetAsr',
  );
  @override
  late final GeneratedColumn<int> offsetAsr = GeneratedColumn<int>(
    'offset_asr',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _offsetMaghribMeta = const VerificationMeta(
    'offsetMaghrib',
  );
  @override
  late final GeneratedColumn<int> offsetMaghrib = GeneratedColumn<int>(
    'offset_maghrib',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _offsetIshaMeta = const VerificationMeta(
    'offsetIsha',
  );
  @override
  late final GeneratedColumn<int> offsetIsha = GeneratedColumn<int>(
    'offset_isha',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _imsakMinutesMeta = const VerificationMeta(
    'imsakMinutes',
  );
  @override
  late final GeneratedColumn<int> imsakMinutes = GeneratedColumn<int>(
    'imsak_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  static const VerificationMeta _hijriAdjustmentMeta = const VerificationMeta(
    'hijriAdjustment',
  );
  @override
  late final GeneratedColumn<int> hijriAdjustment = GeneratedColumn<int>(
    'hijri_adjustment',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _suggestionDismissedRegionsMeta =
      const VerificationMeta('suggestionDismissedRegions');
  @override
  late final GeneratedColumn<String> suggestionDismissedRegions =
      GeneratedColumn<String>(
        'suggestion_dismissed_regions',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  @override
  late final GeneratedColumnWithTypeConverter<AppLanguage, String> language =
      GeneratedColumn<String>(
        'language',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AppLanguage>(
        $PrayerSettingsTableTable.$converterlanguage,
      );
  @override
  late final GeneratedColumnWithTypeConverter<ThemePreference, String> theme =
      GeneratedColumn<String>(
        'theme',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('system'),
      ).withConverter<ThemePreference>(
        $PrayerSettingsTableTable.$convertertheme,
      );
  static const VerificationMeta _textScaleMeta = const VerificationMeta(
    'textScale',
  );
  @override
  late final GeneratedColumn<double> textScale = GeneratedColumn<double>(
    'text_scale',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _highContrastMeta = const VerificationMeta(
    'highContrast',
  );
  @override
  late final GeneratedColumn<bool> highContrast = GeneratedColumn<bool>(
    'high_contrast',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("high_contrast" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    method,
    asrMethod,
    highLatitudeRule,
    offsetFajr,
    offsetSunrise,
    offsetDhuhr,
    offsetAsr,
    offsetMaghrib,
    offsetIsha,
    imsakMinutes,
    hijriAdjustment,
    suggestionDismissedRegions,
    language,
    theme,
    textScale,
    highContrast,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prayer_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrayerSettingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('offset_fajr')) {
      context.handle(
        _offsetFajrMeta,
        offsetFajr.isAcceptableOrUnknown(data['offset_fajr']!, _offsetFajrMeta),
      );
    }
    if (data.containsKey('offset_sunrise')) {
      context.handle(
        _offsetSunriseMeta,
        offsetSunrise.isAcceptableOrUnknown(
          data['offset_sunrise']!,
          _offsetSunriseMeta,
        ),
      );
    }
    if (data.containsKey('offset_dhuhr')) {
      context.handle(
        _offsetDhuhrMeta,
        offsetDhuhr.isAcceptableOrUnknown(
          data['offset_dhuhr']!,
          _offsetDhuhrMeta,
        ),
      );
    }
    if (data.containsKey('offset_asr')) {
      context.handle(
        _offsetAsrMeta,
        offsetAsr.isAcceptableOrUnknown(data['offset_asr']!, _offsetAsrMeta),
      );
    }
    if (data.containsKey('offset_maghrib')) {
      context.handle(
        _offsetMaghribMeta,
        offsetMaghrib.isAcceptableOrUnknown(
          data['offset_maghrib']!,
          _offsetMaghribMeta,
        ),
      );
    }
    if (data.containsKey('offset_isha')) {
      context.handle(
        _offsetIshaMeta,
        offsetIsha.isAcceptableOrUnknown(data['offset_isha']!, _offsetIshaMeta),
      );
    }
    if (data.containsKey('imsak_minutes')) {
      context.handle(
        _imsakMinutesMeta,
        imsakMinutes.isAcceptableOrUnknown(
          data['imsak_minutes']!,
          _imsakMinutesMeta,
        ),
      );
    }
    if (data.containsKey('hijri_adjustment')) {
      context.handle(
        _hijriAdjustmentMeta,
        hijriAdjustment.isAcceptableOrUnknown(
          data['hijri_adjustment']!,
          _hijriAdjustmentMeta,
        ),
      );
    }
    if (data.containsKey('suggestion_dismissed_regions')) {
      context.handle(
        _suggestionDismissedRegionsMeta,
        suggestionDismissedRegions.isAcceptableOrUnknown(
          data['suggestion_dismissed_regions']!,
          _suggestionDismissedRegionsMeta,
        ),
      );
    }
    if (data.containsKey('text_scale')) {
      context.handle(
        _textScaleMeta,
        textScale.isAcceptableOrUnknown(data['text_scale']!, _textScaleMeta),
      );
    }
    if (data.containsKey('high_contrast')) {
      context.handle(
        _highContrastMeta,
        highContrast.isAcceptableOrUnknown(
          data['high_contrast']!,
          _highContrastMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrayerSettingsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrayerSettingsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      method: $PrayerSettingsTableTable.$convertermethod.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}method'],
        )!,
      ),
      asrMethod: $PrayerSettingsTableTable.$converterasrMethod.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}asr_method'],
        )!,
      ),
      highLatitudeRule: $PrayerSettingsTableTable.$converterhighLatitudeRule
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}high_latitude_rule'],
            )!,
          ),
      offsetFajr: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_fajr'],
      )!,
      offsetSunrise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_sunrise'],
      )!,
      offsetDhuhr: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_dhuhr'],
      )!,
      offsetAsr: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_asr'],
      )!,
      offsetMaghrib: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_maghrib'],
      )!,
      offsetIsha: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_isha'],
      )!,
      imsakMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}imsak_minutes'],
      )!,
      hijriAdjustment: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hijri_adjustment'],
      )!,
      suggestionDismissedRegions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}suggestion_dismissed_regions'],
      )!,
      language: $PrayerSettingsTableTable.$converterlanguage.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}language'],
        )!,
      ),
      theme: $PrayerSettingsTableTable.$convertertheme.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}theme'],
        )!,
      ),
      textScale: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}text_scale'],
      )!,
      highContrast: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}high_contrast'],
      )!,
    );
  }

  @override
  $PrayerSettingsTableTable createAlias(String alias) {
    return $PrayerSettingsTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<engine.CalculationMethod, String, String>
  $convertermethod = const EnumNameConverter<engine.CalculationMethod>(
    engine.CalculationMethod.values,
  );
  static JsonTypeConverter2<engine.AsrMethod, String, String>
  $converterasrMethod = const EnumNameConverter<engine.AsrMethod>(
    engine.AsrMethod.values,
  );
  static JsonTypeConverter2<engine.HighLatitudeRule, String, String>
  $converterhighLatitudeRule = const EnumNameConverter<engine.HighLatitudeRule>(
    engine.HighLatitudeRule.values,
  );
  static JsonTypeConverter2<AppLanguage, String, String> $converterlanguage =
      const EnumNameConverter<AppLanguage>(AppLanguage.values);
  static JsonTypeConverter2<ThemePreference, String, String> $convertertheme =
      const EnumNameConverter<ThemePreference>(ThemePreference.values);
}

class PrayerSettingsTableData extends DataClass
    implements Insertable<PrayerSettingsTableData> {
  final int id;
  final engine.CalculationMethod method;
  final engine.AsrMethod asrMethod;
  final engine.HighLatitudeRule highLatitudeRule;
  final int offsetFajr;
  final int offsetSunrise;
  final int offsetDhuhr;
  final int offsetAsr;
  final int offsetMaghrib;
  final int offsetIsha;
  final int imsakMinutes;
  final int hijriAdjustment;

  /// Comma-separated region names whose method suggestion was dismissed.
  final String suggestionDismissedRegions;
  final AppLanguage language;
  final ThemePreference theme;
  final double textScale;
  final bool highContrast;
  const PrayerSettingsTableData({
    required this.id,
    required this.method,
    required this.asrMethod,
    required this.highLatitudeRule,
    required this.offsetFajr,
    required this.offsetSunrise,
    required this.offsetDhuhr,
    required this.offsetAsr,
    required this.offsetMaghrib,
    required this.offsetIsha,
    required this.imsakMinutes,
    required this.hijriAdjustment,
    required this.suggestionDismissedRegions,
    required this.language,
    required this.theme,
    required this.textScale,
    required this.highContrast,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['method'] = Variable<String>(
        $PrayerSettingsTableTable.$convertermethod.toSql(method),
      );
    }
    {
      map['asr_method'] = Variable<String>(
        $PrayerSettingsTableTable.$converterasrMethod.toSql(asrMethod),
      );
    }
    {
      map['high_latitude_rule'] = Variable<String>(
        $PrayerSettingsTableTable.$converterhighLatitudeRule.toSql(
          highLatitudeRule,
        ),
      );
    }
    map['offset_fajr'] = Variable<int>(offsetFajr);
    map['offset_sunrise'] = Variable<int>(offsetSunrise);
    map['offset_dhuhr'] = Variable<int>(offsetDhuhr);
    map['offset_asr'] = Variable<int>(offsetAsr);
    map['offset_maghrib'] = Variable<int>(offsetMaghrib);
    map['offset_isha'] = Variable<int>(offsetIsha);
    map['imsak_minutes'] = Variable<int>(imsakMinutes);
    map['hijri_adjustment'] = Variable<int>(hijriAdjustment);
    map['suggestion_dismissed_regions'] = Variable<String>(
      suggestionDismissedRegions,
    );
    {
      map['language'] = Variable<String>(
        $PrayerSettingsTableTable.$converterlanguage.toSql(language),
      );
    }
    {
      map['theme'] = Variable<String>(
        $PrayerSettingsTableTable.$convertertheme.toSql(theme),
      );
    }
    map['text_scale'] = Variable<double>(textScale);
    map['high_contrast'] = Variable<bool>(highContrast);
    return map;
  }

  PrayerSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return PrayerSettingsTableCompanion(
      id: Value(id),
      method: Value(method),
      asrMethod: Value(asrMethod),
      highLatitudeRule: Value(highLatitudeRule),
      offsetFajr: Value(offsetFajr),
      offsetSunrise: Value(offsetSunrise),
      offsetDhuhr: Value(offsetDhuhr),
      offsetAsr: Value(offsetAsr),
      offsetMaghrib: Value(offsetMaghrib),
      offsetIsha: Value(offsetIsha),
      imsakMinutes: Value(imsakMinutes),
      hijriAdjustment: Value(hijriAdjustment),
      suggestionDismissedRegions: Value(suggestionDismissedRegions),
      language: Value(language),
      theme: Value(theme),
      textScale: Value(textScale),
      highContrast: Value(highContrast),
    );
  }

  factory PrayerSettingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrayerSettingsTableData(
      id: serializer.fromJson<int>(json['id']),
      method: $PrayerSettingsTableTable.$convertermethod.fromJson(
        serializer.fromJson<String>(json['method']),
      ),
      asrMethod: $PrayerSettingsTableTable.$converterasrMethod.fromJson(
        serializer.fromJson<String>(json['asrMethod']),
      ),
      highLatitudeRule: $PrayerSettingsTableTable.$converterhighLatitudeRule
          .fromJson(serializer.fromJson<String>(json['highLatitudeRule'])),
      offsetFajr: serializer.fromJson<int>(json['offsetFajr']),
      offsetSunrise: serializer.fromJson<int>(json['offsetSunrise']),
      offsetDhuhr: serializer.fromJson<int>(json['offsetDhuhr']),
      offsetAsr: serializer.fromJson<int>(json['offsetAsr']),
      offsetMaghrib: serializer.fromJson<int>(json['offsetMaghrib']),
      offsetIsha: serializer.fromJson<int>(json['offsetIsha']),
      imsakMinutes: serializer.fromJson<int>(json['imsakMinutes']),
      hijriAdjustment: serializer.fromJson<int>(json['hijriAdjustment']),
      suggestionDismissedRegions: serializer.fromJson<String>(
        json['suggestionDismissedRegions'],
      ),
      language: $PrayerSettingsTableTable.$converterlanguage.fromJson(
        serializer.fromJson<String>(json['language']),
      ),
      theme: $PrayerSettingsTableTable.$convertertheme.fromJson(
        serializer.fromJson<String>(json['theme']),
      ),
      textScale: serializer.fromJson<double>(json['textScale']),
      highContrast: serializer.fromJson<bool>(json['highContrast']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'method': serializer.toJson<String>(
        $PrayerSettingsTableTable.$convertermethod.toJson(method),
      ),
      'asrMethod': serializer.toJson<String>(
        $PrayerSettingsTableTable.$converterasrMethod.toJson(asrMethod),
      ),
      'highLatitudeRule': serializer.toJson<String>(
        $PrayerSettingsTableTable.$converterhighLatitudeRule.toJson(
          highLatitudeRule,
        ),
      ),
      'offsetFajr': serializer.toJson<int>(offsetFajr),
      'offsetSunrise': serializer.toJson<int>(offsetSunrise),
      'offsetDhuhr': serializer.toJson<int>(offsetDhuhr),
      'offsetAsr': serializer.toJson<int>(offsetAsr),
      'offsetMaghrib': serializer.toJson<int>(offsetMaghrib),
      'offsetIsha': serializer.toJson<int>(offsetIsha),
      'imsakMinutes': serializer.toJson<int>(imsakMinutes),
      'hijriAdjustment': serializer.toJson<int>(hijriAdjustment),
      'suggestionDismissedRegions': serializer.toJson<String>(
        suggestionDismissedRegions,
      ),
      'language': serializer.toJson<String>(
        $PrayerSettingsTableTable.$converterlanguage.toJson(language),
      ),
      'theme': serializer.toJson<String>(
        $PrayerSettingsTableTable.$convertertheme.toJson(theme),
      ),
      'textScale': serializer.toJson<double>(textScale),
      'highContrast': serializer.toJson<bool>(highContrast),
    };
  }

  PrayerSettingsTableData copyWith({
    int? id,
    engine.CalculationMethod? method,
    engine.AsrMethod? asrMethod,
    engine.HighLatitudeRule? highLatitudeRule,
    int? offsetFajr,
    int? offsetSunrise,
    int? offsetDhuhr,
    int? offsetAsr,
    int? offsetMaghrib,
    int? offsetIsha,
    int? imsakMinutes,
    int? hijriAdjustment,
    String? suggestionDismissedRegions,
    AppLanguage? language,
    ThemePreference? theme,
    double? textScale,
    bool? highContrast,
  }) => PrayerSettingsTableData(
    id: id ?? this.id,
    method: method ?? this.method,
    asrMethod: asrMethod ?? this.asrMethod,
    highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
    offsetFajr: offsetFajr ?? this.offsetFajr,
    offsetSunrise: offsetSunrise ?? this.offsetSunrise,
    offsetDhuhr: offsetDhuhr ?? this.offsetDhuhr,
    offsetAsr: offsetAsr ?? this.offsetAsr,
    offsetMaghrib: offsetMaghrib ?? this.offsetMaghrib,
    offsetIsha: offsetIsha ?? this.offsetIsha,
    imsakMinutes: imsakMinutes ?? this.imsakMinutes,
    hijriAdjustment: hijriAdjustment ?? this.hijriAdjustment,
    suggestionDismissedRegions:
        suggestionDismissedRegions ?? this.suggestionDismissedRegions,
    language: language ?? this.language,
    theme: theme ?? this.theme,
    textScale: textScale ?? this.textScale,
    highContrast: highContrast ?? this.highContrast,
  );
  PrayerSettingsTableData copyWithCompanion(PrayerSettingsTableCompanion data) {
    return PrayerSettingsTableData(
      id: data.id.present ? data.id.value : this.id,
      method: data.method.present ? data.method.value : this.method,
      asrMethod: data.asrMethod.present ? data.asrMethod.value : this.asrMethod,
      highLatitudeRule: data.highLatitudeRule.present
          ? data.highLatitudeRule.value
          : this.highLatitudeRule,
      offsetFajr: data.offsetFajr.present
          ? data.offsetFajr.value
          : this.offsetFajr,
      offsetSunrise: data.offsetSunrise.present
          ? data.offsetSunrise.value
          : this.offsetSunrise,
      offsetDhuhr: data.offsetDhuhr.present
          ? data.offsetDhuhr.value
          : this.offsetDhuhr,
      offsetAsr: data.offsetAsr.present ? data.offsetAsr.value : this.offsetAsr,
      offsetMaghrib: data.offsetMaghrib.present
          ? data.offsetMaghrib.value
          : this.offsetMaghrib,
      offsetIsha: data.offsetIsha.present
          ? data.offsetIsha.value
          : this.offsetIsha,
      imsakMinutes: data.imsakMinutes.present
          ? data.imsakMinutes.value
          : this.imsakMinutes,
      hijriAdjustment: data.hijriAdjustment.present
          ? data.hijriAdjustment.value
          : this.hijriAdjustment,
      suggestionDismissedRegions: data.suggestionDismissedRegions.present
          ? data.suggestionDismissedRegions.value
          : this.suggestionDismissedRegions,
      language: data.language.present ? data.language.value : this.language,
      theme: data.theme.present ? data.theme.value : this.theme,
      textScale: data.textScale.present ? data.textScale.value : this.textScale,
      highContrast: data.highContrast.present
          ? data.highContrast.value
          : this.highContrast,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrayerSettingsTableData(')
          ..write('id: $id, ')
          ..write('method: $method, ')
          ..write('asrMethod: $asrMethod, ')
          ..write('highLatitudeRule: $highLatitudeRule, ')
          ..write('offsetFajr: $offsetFajr, ')
          ..write('offsetSunrise: $offsetSunrise, ')
          ..write('offsetDhuhr: $offsetDhuhr, ')
          ..write('offsetAsr: $offsetAsr, ')
          ..write('offsetMaghrib: $offsetMaghrib, ')
          ..write('offsetIsha: $offsetIsha, ')
          ..write('imsakMinutes: $imsakMinutes, ')
          ..write('hijriAdjustment: $hijriAdjustment, ')
          ..write('suggestionDismissedRegions: $suggestionDismissedRegions, ')
          ..write('language: $language, ')
          ..write('theme: $theme, ')
          ..write('textScale: $textScale, ')
          ..write('highContrast: $highContrast')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    method,
    asrMethod,
    highLatitudeRule,
    offsetFajr,
    offsetSunrise,
    offsetDhuhr,
    offsetAsr,
    offsetMaghrib,
    offsetIsha,
    imsakMinutes,
    hijriAdjustment,
    suggestionDismissedRegions,
    language,
    theme,
    textScale,
    highContrast,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrayerSettingsTableData &&
          other.id == this.id &&
          other.method == this.method &&
          other.asrMethod == this.asrMethod &&
          other.highLatitudeRule == this.highLatitudeRule &&
          other.offsetFajr == this.offsetFajr &&
          other.offsetSunrise == this.offsetSunrise &&
          other.offsetDhuhr == this.offsetDhuhr &&
          other.offsetAsr == this.offsetAsr &&
          other.offsetMaghrib == this.offsetMaghrib &&
          other.offsetIsha == this.offsetIsha &&
          other.imsakMinutes == this.imsakMinutes &&
          other.hijriAdjustment == this.hijriAdjustment &&
          other.suggestionDismissedRegions == this.suggestionDismissedRegions &&
          other.language == this.language &&
          other.theme == this.theme &&
          other.textScale == this.textScale &&
          other.highContrast == this.highContrast);
}

class PrayerSettingsTableCompanion
    extends UpdateCompanion<PrayerSettingsTableData> {
  final Value<int> id;
  final Value<engine.CalculationMethod> method;
  final Value<engine.AsrMethod> asrMethod;
  final Value<engine.HighLatitudeRule> highLatitudeRule;
  final Value<int> offsetFajr;
  final Value<int> offsetSunrise;
  final Value<int> offsetDhuhr;
  final Value<int> offsetAsr;
  final Value<int> offsetMaghrib;
  final Value<int> offsetIsha;
  final Value<int> imsakMinutes;
  final Value<int> hijriAdjustment;
  final Value<String> suggestionDismissedRegions;
  final Value<AppLanguage> language;
  final Value<ThemePreference> theme;
  final Value<double> textScale;
  final Value<bool> highContrast;
  const PrayerSettingsTableCompanion({
    this.id = const Value.absent(),
    this.method = const Value.absent(),
    this.asrMethod = const Value.absent(),
    this.highLatitudeRule = const Value.absent(),
    this.offsetFajr = const Value.absent(),
    this.offsetSunrise = const Value.absent(),
    this.offsetDhuhr = const Value.absent(),
    this.offsetAsr = const Value.absent(),
    this.offsetMaghrib = const Value.absent(),
    this.offsetIsha = const Value.absent(),
    this.imsakMinutes = const Value.absent(),
    this.hijriAdjustment = const Value.absent(),
    this.suggestionDismissedRegions = const Value.absent(),
    this.language = const Value.absent(),
    this.theme = const Value.absent(),
    this.textScale = const Value.absent(),
    this.highContrast = const Value.absent(),
  });
  PrayerSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    required engine.CalculationMethod method,
    required engine.AsrMethod asrMethod,
    required engine.HighLatitudeRule highLatitudeRule,
    this.offsetFajr = const Value.absent(),
    this.offsetSunrise = const Value.absent(),
    this.offsetDhuhr = const Value.absent(),
    this.offsetAsr = const Value.absent(),
    this.offsetMaghrib = const Value.absent(),
    this.offsetIsha = const Value.absent(),
    this.imsakMinutes = const Value.absent(),
    this.hijriAdjustment = const Value.absent(),
    this.suggestionDismissedRegions = const Value.absent(),
    required AppLanguage language,
    this.theme = const Value.absent(),
    this.textScale = const Value.absent(),
    this.highContrast = const Value.absent(),
  }) : method = Value(method),
       asrMethod = Value(asrMethod),
       highLatitudeRule = Value(highLatitudeRule),
       language = Value(language);
  static Insertable<PrayerSettingsTableData> custom({
    Expression<int>? id,
    Expression<String>? method,
    Expression<String>? asrMethod,
    Expression<String>? highLatitudeRule,
    Expression<int>? offsetFajr,
    Expression<int>? offsetSunrise,
    Expression<int>? offsetDhuhr,
    Expression<int>? offsetAsr,
    Expression<int>? offsetMaghrib,
    Expression<int>? offsetIsha,
    Expression<int>? imsakMinutes,
    Expression<int>? hijriAdjustment,
    Expression<String>? suggestionDismissedRegions,
    Expression<String>? language,
    Expression<String>? theme,
    Expression<double>? textScale,
    Expression<bool>? highContrast,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (method != null) 'method': method,
      if (asrMethod != null) 'asr_method': asrMethod,
      if (highLatitudeRule != null) 'high_latitude_rule': highLatitudeRule,
      if (offsetFajr != null) 'offset_fajr': offsetFajr,
      if (offsetSunrise != null) 'offset_sunrise': offsetSunrise,
      if (offsetDhuhr != null) 'offset_dhuhr': offsetDhuhr,
      if (offsetAsr != null) 'offset_asr': offsetAsr,
      if (offsetMaghrib != null) 'offset_maghrib': offsetMaghrib,
      if (offsetIsha != null) 'offset_isha': offsetIsha,
      if (imsakMinutes != null) 'imsak_minutes': imsakMinutes,
      if (hijriAdjustment != null) 'hijri_adjustment': hijriAdjustment,
      if (suggestionDismissedRegions != null)
        'suggestion_dismissed_regions': suggestionDismissedRegions,
      if (language != null) 'language': language,
      if (theme != null) 'theme': theme,
      if (textScale != null) 'text_scale': textScale,
      if (highContrast != null) 'high_contrast': highContrast,
    });
  }

  PrayerSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<engine.CalculationMethod>? method,
    Value<engine.AsrMethod>? asrMethod,
    Value<engine.HighLatitudeRule>? highLatitudeRule,
    Value<int>? offsetFajr,
    Value<int>? offsetSunrise,
    Value<int>? offsetDhuhr,
    Value<int>? offsetAsr,
    Value<int>? offsetMaghrib,
    Value<int>? offsetIsha,
    Value<int>? imsakMinutes,
    Value<int>? hijriAdjustment,
    Value<String>? suggestionDismissedRegions,
    Value<AppLanguage>? language,
    Value<ThemePreference>? theme,
    Value<double>? textScale,
    Value<bool>? highContrast,
  }) {
    return PrayerSettingsTableCompanion(
      id: id ?? this.id,
      method: method ?? this.method,
      asrMethod: asrMethod ?? this.asrMethod,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      offsetFajr: offsetFajr ?? this.offsetFajr,
      offsetSunrise: offsetSunrise ?? this.offsetSunrise,
      offsetDhuhr: offsetDhuhr ?? this.offsetDhuhr,
      offsetAsr: offsetAsr ?? this.offsetAsr,
      offsetMaghrib: offsetMaghrib ?? this.offsetMaghrib,
      offsetIsha: offsetIsha ?? this.offsetIsha,
      imsakMinutes: imsakMinutes ?? this.imsakMinutes,
      hijriAdjustment: hijriAdjustment ?? this.hijriAdjustment,
      suggestionDismissedRegions:
          suggestionDismissedRegions ?? this.suggestionDismissedRegions,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      textScale: textScale ?? this.textScale,
      highContrast: highContrast ?? this.highContrast,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(
        $PrayerSettingsTableTable.$convertermethod.toSql(method.value),
      );
    }
    if (asrMethod.present) {
      map['asr_method'] = Variable<String>(
        $PrayerSettingsTableTable.$converterasrMethod.toSql(asrMethod.value),
      );
    }
    if (highLatitudeRule.present) {
      map['high_latitude_rule'] = Variable<String>(
        $PrayerSettingsTableTable.$converterhighLatitudeRule.toSql(
          highLatitudeRule.value,
        ),
      );
    }
    if (offsetFajr.present) {
      map['offset_fajr'] = Variable<int>(offsetFajr.value);
    }
    if (offsetSunrise.present) {
      map['offset_sunrise'] = Variable<int>(offsetSunrise.value);
    }
    if (offsetDhuhr.present) {
      map['offset_dhuhr'] = Variable<int>(offsetDhuhr.value);
    }
    if (offsetAsr.present) {
      map['offset_asr'] = Variable<int>(offsetAsr.value);
    }
    if (offsetMaghrib.present) {
      map['offset_maghrib'] = Variable<int>(offsetMaghrib.value);
    }
    if (offsetIsha.present) {
      map['offset_isha'] = Variable<int>(offsetIsha.value);
    }
    if (imsakMinutes.present) {
      map['imsak_minutes'] = Variable<int>(imsakMinutes.value);
    }
    if (hijriAdjustment.present) {
      map['hijri_adjustment'] = Variable<int>(hijriAdjustment.value);
    }
    if (suggestionDismissedRegions.present) {
      map['suggestion_dismissed_regions'] = Variable<String>(
        suggestionDismissedRegions.value,
      );
    }
    if (language.present) {
      map['language'] = Variable<String>(
        $PrayerSettingsTableTable.$converterlanguage.toSql(language.value),
      );
    }
    if (theme.present) {
      map['theme'] = Variable<String>(
        $PrayerSettingsTableTable.$convertertheme.toSql(theme.value),
      );
    }
    if (textScale.present) {
      map['text_scale'] = Variable<double>(textScale.value);
    }
    if (highContrast.present) {
      map['high_contrast'] = Variable<bool>(highContrast.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrayerSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('method: $method, ')
          ..write('asrMethod: $asrMethod, ')
          ..write('highLatitudeRule: $highLatitudeRule, ')
          ..write('offsetFajr: $offsetFajr, ')
          ..write('offsetSunrise: $offsetSunrise, ')
          ..write('offsetDhuhr: $offsetDhuhr, ')
          ..write('offsetAsr: $offsetAsr, ')
          ..write('offsetMaghrib: $offsetMaghrib, ')
          ..write('offsetIsha: $offsetIsha, ')
          ..write('imsakMinutes: $imsakMinutes, ')
          ..write('hijriAdjustment: $hijriAdjustment, ')
          ..write('suggestionDismissedRegions: $suggestionDismissedRegions, ')
          ..write('language: $language, ')
          ..write('theme: $theme, ')
          ..write('textScale: $textScale, ')
          ..write('highContrast: $highContrast')
          ..write(')'))
        .toString();
  }
}

class $AlertPreferenceTableTable extends AlertPreferenceTable
    with TableInfo<$AlertPreferenceTableTable, AlertPreferenceTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlertPreferenceTableTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<AlertPrayer, String> prayer =
      GeneratedColumn<String>(
        'prayer',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AlertPrayer>($AlertPreferenceTableTable.$converterprayer);
  @override
  late final GeneratedColumnWithTypeConverter<AlertType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('shortTone'),
      ).withConverter<AlertType>($AlertPreferenceTableTable.$convertertype);
  static const VerificationMeta _voiceIdMeta = const VerificationMeta(
    'voiceId',
  );
  @override
  late final GeneratedColumn<String> voiceId = GeneratedColumn<String>(
    'voice_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('voice-1'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AzaanVariant, String> variant =
      GeneratedColumn<String>(
        'variant',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('standard'),
      ).withConverter<AzaanVariant>(
        $AlertPreferenceTableTable.$convertervariant,
      );
  static const VerificationMeta _loudModeMeta = const VerificationMeta(
    'loudMode',
  );
  @override
  late final GeneratedColumn<bool> loudMode = GeneratedColumn<bool>(
    'loud_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("loud_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<VolumeChoice, String>
  volumeChoice =
      GeneratedColumn<String>(
        'volume_choice',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('keepCurrent'),
      ).withConverter<VolumeChoice>(
        $AlertPreferenceTableTable.$convertervolumeChoice,
      );
  static const VerificationMeta _preReminderMinutesMeta =
      const VerificationMeta('preReminderMinutes');
  @override
  late final GeneratedColumn<int> preReminderMinutes = GeneratedColumn<int>(
    'pre_reminder_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ignoreQuietHoursMeta = const VerificationMeta(
    'ignoreQuietHours',
  );
  @override
  late final GeneratedColumn<bool> ignoreQuietHours = GeneratedColumn<bool>(
    'ignore_quiet_hours',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ignore_quiet_hours" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    prayer,
    type,
    voiceId,
    variant,
    loudMode,
    volumeChoice,
    preReminderMinutes,
    ignoreQuietHours,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alert_preference';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlertPreferenceTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('voice_id')) {
      context.handle(
        _voiceIdMeta,
        voiceId.isAcceptableOrUnknown(data['voice_id']!, _voiceIdMeta),
      );
    }
    if (data.containsKey('loud_mode')) {
      context.handle(
        _loudModeMeta,
        loudMode.isAcceptableOrUnknown(data['loud_mode']!, _loudModeMeta),
      );
    }
    if (data.containsKey('pre_reminder_minutes')) {
      context.handle(
        _preReminderMinutesMeta,
        preReminderMinutes.isAcceptableOrUnknown(
          data['pre_reminder_minutes']!,
          _preReminderMinutesMeta,
        ),
      );
    }
    if (data.containsKey('ignore_quiet_hours')) {
      context.handle(
        _ignoreQuietHoursMeta,
        ignoreQuietHours.isAcceptableOrUnknown(
          data['ignore_quiet_hours']!,
          _ignoreQuietHoursMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {prayer};
  @override
  AlertPreferenceTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlertPreferenceTableData(
      prayer: $AlertPreferenceTableTable.$converterprayer.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}prayer'],
        )!,
      ),
      type: $AlertPreferenceTableTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      voiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice_id'],
      )!,
      variant: $AlertPreferenceTableTable.$convertervariant.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}variant'],
        )!,
      ),
      loudMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}loud_mode'],
      )!,
      volumeChoice: $AlertPreferenceTableTable.$convertervolumeChoice.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}volume_choice'],
        )!,
      ),
      preReminderMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pre_reminder_minutes'],
      ),
      ignoreQuietHours: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ignore_quiet_hours'],
      )!,
    );
  }

  @override
  $AlertPreferenceTableTable createAlias(String alias) {
    return $AlertPreferenceTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AlertPrayer, String, String> $converterprayer =
      const EnumNameConverter<AlertPrayer>(AlertPrayer.values);
  static JsonTypeConverter2<AlertType, String, String> $convertertype =
      const EnumNameConverter<AlertType>(AlertType.values);
  static JsonTypeConverter2<AzaanVariant, String, String> $convertervariant =
      const EnumNameConverter<AzaanVariant>(AzaanVariant.values);
  static JsonTypeConverter2<VolumeChoice, String, String>
  $convertervolumeChoice = const EnumNameConverter<VolumeChoice>(
    VolumeChoice.values,
  );
}

class AlertPreferenceTableData extends DataClass
    implements Insertable<AlertPreferenceTableData> {
  final AlertPrayer prayer;
  final AlertType type;
  final String voiceId;
  final AzaanVariant variant;
  final bool loudMode;
  final VolumeChoice volumeChoice;
  final int? preReminderMinutes;
  final bool ignoreQuietHours;
  const AlertPreferenceTableData({
    required this.prayer,
    required this.type,
    required this.voiceId,
    required this.variant,
    required this.loudMode,
    required this.volumeChoice,
    this.preReminderMinutes,
    required this.ignoreQuietHours,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['prayer'] = Variable<String>(
        $AlertPreferenceTableTable.$converterprayer.toSql(prayer),
      );
    }
    {
      map['type'] = Variable<String>(
        $AlertPreferenceTableTable.$convertertype.toSql(type),
      );
    }
    map['voice_id'] = Variable<String>(voiceId);
    {
      map['variant'] = Variable<String>(
        $AlertPreferenceTableTable.$convertervariant.toSql(variant),
      );
    }
    map['loud_mode'] = Variable<bool>(loudMode);
    {
      map['volume_choice'] = Variable<String>(
        $AlertPreferenceTableTable.$convertervolumeChoice.toSql(volumeChoice),
      );
    }
    if (!nullToAbsent || preReminderMinutes != null) {
      map['pre_reminder_minutes'] = Variable<int>(preReminderMinutes);
    }
    map['ignore_quiet_hours'] = Variable<bool>(ignoreQuietHours);
    return map;
  }

  AlertPreferenceTableCompanion toCompanion(bool nullToAbsent) {
    return AlertPreferenceTableCompanion(
      prayer: Value(prayer),
      type: Value(type),
      voiceId: Value(voiceId),
      variant: Value(variant),
      loudMode: Value(loudMode),
      volumeChoice: Value(volumeChoice),
      preReminderMinutes: preReminderMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(preReminderMinutes),
      ignoreQuietHours: Value(ignoreQuietHours),
    );
  }

  factory AlertPreferenceTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlertPreferenceTableData(
      prayer: $AlertPreferenceTableTable.$converterprayer.fromJson(
        serializer.fromJson<String>(json['prayer']),
      ),
      type: $AlertPreferenceTableTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      voiceId: serializer.fromJson<String>(json['voiceId']),
      variant: $AlertPreferenceTableTable.$convertervariant.fromJson(
        serializer.fromJson<String>(json['variant']),
      ),
      loudMode: serializer.fromJson<bool>(json['loudMode']),
      volumeChoice: $AlertPreferenceTableTable.$convertervolumeChoice.fromJson(
        serializer.fromJson<String>(json['volumeChoice']),
      ),
      preReminderMinutes: serializer.fromJson<int?>(json['preReminderMinutes']),
      ignoreQuietHours: serializer.fromJson<bool>(json['ignoreQuietHours']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'prayer': serializer.toJson<String>(
        $AlertPreferenceTableTable.$converterprayer.toJson(prayer),
      ),
      'type': serializer.toJson<String>(
        $AlertPreferenceTableTable.$convertertype.toJson(type),
      ),
      'voiceId': serializer.toJson<String>(voiceId),
      'variant': serializer.toJson<String>(
        $AlertPreferenceTableTable.$convertervariant.toJson(variant),
      ),
      'loudMode': serializer.toJson<bool>(loudMode),
      'volumeChoice': serializer.toJson<String>(
        $AlertPreferenceTableTable.$convertervolumeChoice.toJson(volumeChoice),
      ),
      'preReminderMinutes': serializer.toJson<int?>(preReminderMinutes),
      'ignoreQuietHours': serializer.toJson<bool>(ignoreQuietHours),
    };
  }

  AlertPreferenceTableData copyWith({
    AlertPrayer? prayer,
    AlertType? type,
    String? voiceId,
    AzaanVariant? variant,
    bool? loudMode,
    VolumeChoice? volumeChoice,
    Value<int?> preReminderMinutes = const Value.absent(),
    bool? ignoreQuietHours,
  }) => AlertPreferenceTableData(
    prayer: prayer ?? this.prayer,
    type: type ?? this.type,
    voiceId: voiceId ?? this.voiceId,
    variant: variant ?? this.variant,
    loudMode: loudMode ?? this.loudMode,
    volumeChoice: volumeChoice ?? this.volumeChoice,
    preReminderMinutes: preReminderMinutes.present
        ? preReminderMinutes.value
        : this.preReminderMinutes,
    ignoreQuietHours: ignoreQuietHours ?? this.ignoreQuietHours,
  );
  AlertPreferenceTableData copyWithCompanion(
    AlertPreferenceTableCompanion data,
  ) {
    return AlertPreferenceTableData(
      prayer: data.prayer.present ? data.prayer.value : this.prayer,
      type: data.type.present ? data.type.value : this.type,
      voiceId: data.voiceId.present ? data.voiceId.value : this.voiceId,
      variant: data.variant.present ? data.variant.value : this.variant,
      loudMode: data.loudMode.present ? data.loudMode.value : this.loudMode,
      volumeChoice: data.volumeChoice.present
          ? data.volumeChoice.value
          : this.volumeChoice,
      preReminderMinutes: data.preReminderMinutes.present
          ? data.preReminderMinutes.value
          : this.preReminderMinutes,
      ignoreQuietHours: data.ignoreQuietHours.present
          ? data.ignoreQuietHours.value
          : this.ignoreQuietHours,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlertPreferenceTableData(')
          ..write('prayer: $prayer, ')
          ..write('type: $type, ')
          ..write('voiceId: $voiceId, ')
          ..write('variant: $variant, ')
          ..write('loudMode: $loudMode, ')
          ..write('volumeChoice: $volumeChoice, ')
          ..write('preReminderMinutes: $preReminderMinutes, ')
          ..write('ignoreQuietHours: $ignoreQuietHours')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    prayer,
    type,
    voiceId,
    variant,
    loudMode,
    volumeChoice,
    preReminderMinutes,
    ignoreQuietHours,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlertPreferenceTableData &&
          other.prayer == this.prayer &&
          other.type == this.type &&
          other.voiceId == this.voiceId &&
          other.variant == this.variant &&
          other.loudMode == this.loudMode &&
          other.volumeChoice == this.volumeChoice &&
          other.preReminderMinutes == this.preReminderMinutes &&
          other.ignoreQuietHours == this.ignoreQuietHours);
}

class AlertPreferenceTableCompanion
    extends UpdateCompanion<AlertPreferenceTableData> {
  final Value<AlertPrayer> prayer;
  final Value<AlertType> type;
  final Value<String> voiceId;
  final Value<AzaanVariant> variant;
  final Value<bool> loudMode;
  final Value<VolumeChoice> volumeChoice;
  final Value<int?> preReminderMinutes;
  final Value<bool> ignoreQuietHours;
  final Value<int> rowid;
  const AlertPreferenceTableCompanion({
    this.prayer = const Value.absent(),
    this.type = const Value.absent(),
    this.voiceId = const Value.absent(),
    this.variant = const Value.absent(),
    this.loudMode = const Value.absent(),
    this.volumeChoice = const Value.absent(),
    this.preReminderMinutes = const Value.absent(),
    this.ignoreQuietHours = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlertPreferenceTableCompanion.insert({
    required AlertPrayer prayer,
    this.type = const Value.absent(),
    this.voiceId = const Value.absent(),
    this.variant = const Value.absent(),
    this.loudMode = const Value.absent(),
    this.volumeChoice = const Value.absent(),
    this.preReminderMinutes = const Value.absent(),
    this.ignoreQuietHours = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : prayer = Value(prayer);
  static Insertable<AlertPreferenceTableData> custom({
    Expression<String>? prayer,
    Expression<String>? type,
    Expression<String>? voiceId,
    Expression<String>? variant,
    Expression<bool>? loudMode,
    Expression<String>? volumeChoice,
    Expression<int>? preReminderMinutes,
    Expression<bool>? ignoreQuietHours,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (prayer != null) 'prayer': prayer,
      if (type != null) 'type': type,
      if (voiceId != null) 'voice_id': voiceId,
      if (variant != null) 'variant': variant,
      if (loudMode != null) 'loud_mode': loudMode,
      if (volumeChoice != null) 'volume_choice': volumeChoice,
      if (preReminderMinutes != null)
        'pre_reminder_minutes': preReminderMinutes,
      if (ignoreQuietHours != null) 'ignore_quiet_hours': ignoreQuietHours,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlertPreferenceTableCompanion copyWith({
    Value<AlertPrayer>? prayer,
    Value<AlertType>? type,
    Value<String>? voiceId,
    Value<AzaanVariant>? variant,
    Value<bool>? loudMode,
    Value<VolumeChoice>? volumeChoice,
    Value<int?>? preReminderMinutes,
    Value<bool>? ignoreQuietHours,
    Value<int>? rowid,
  }) {
    return AlertPreferenceTableCompanion(
      prayer: prayer ?? this.prayer,
      type: type ?? this.type,
      voiceId: voiceId ?? this.voiceId,
      variant: variant ?? this.variant,
      loudMode: loudMode ?? this.loudMode,
      volumeChoice: volumeChoice ?? this.volumeChoice,
      preReminderMinutes: preReminderMinutes ?? this.preReminderMinutes,
      ignoreQuietHours: ignoreQuietHours ?? this.ignoreQuietHours,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (prayer.present) {
      map['prayer'] = Variable<String>(
        $AlertPreferenceTableTable.$converterprayer.toSql(prayer.value),
      );
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $AlertPreferenceTableTable.$convertertype.toSql(type.value),
      );
    }
    if (voiceId.present) {
      map['voice_id'] = Variable<String>(voiceId.value);
    }
    if (variant.present) {
      map['variant'] = Variable<String>(
        $AlertPreferenceTableTable.$convertervariant.toSql(variant.value),
      );
    }
    if (loudMode.present) {
      map['loud_mode'] = Variable<bool>(loudMode.value);
    }
    if (volumeChoice.present) {
      map['volume_choice'] = Variable<String>(
        $AlertPreferenceTableTable.$convertervolumeChoice.toSql(
          volumeChoice.value,
        ),
      );
    }
    if (preReminderMinutes.present) {
      map['pre_reminder_minutes'] = Variable<int>(preReminderMinutes.value);
    }
    if (ignoreQuietHours.present) {
      map['ignore_quiet_hours'] = Variable<bool>(ignoreQuietHours.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertPreferenceTableCompanion(')
          ..write('prayer: $prayer, ')
          ..write('type: $type, ')
          ..write('voiceId: $voiceId, ')
          ..write('variant: $variant, ')
          ..write('loudMode: $loudMode, ')
          ..write('volumeChoice: $volumeChoice, ')
          ..write('preReminderMinutes: $preReminderMinutes, ')
          ..write('ignoreQuietHours: $ignoreQuietHours, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GlobalSettingsTableTable extends GlobalSettingsTable
    with TableInfo<$GlobalSettingsTableTable, GlobalSettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GlobalSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AudioOutput, String> audioOutput =
      GeneratedColumn<String>(
        'audio_output',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('speaker'),
      ).withConverter<AudioOutput>(
        $GlobalSettingsTableTable.$converteraudioOutput,
      );
  static const VerificationMeta _quietHoursStartMinutesMeta =
      const VerificationMeta('quietHoursStartMinutes');
  @override
  late final GeneratedColumn<int> quietHoursStartMinutes = GeneratedColumn<int>(
    'quiet_hours_start_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quietHoursEndMinutesMeta =
      const VerificationMeta('quietHoursEndMinutes');
  @override
  late final GeneratedColumn<int> quietHoursEndMinutes = GeneratedColumn<int>(
    'quiet_hours_end_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _suhoorReminderEnabledMeta =
      const VerificationMeta('suhoorReminderEnabled');
  @override
  late final GeneratedColumn<bool> suhoorReminderEnabled =
      GeneratedColumn<bool>(
        'suhoor_reminder_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("suhoor_reminder_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _suhoorReminderMinutesMeta =
      const VerificationMeta('suhoorReminderMinutes');
  @override
  late final GeneratedColumn<int> suhoorReminderMinutes = GeneratedColumn<int>(
    'suhoor_reminder_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  @override
  late final GeneratedColumnWithTypeConverter<PermissionState, String>
  exactAlarmState =
      GeneratedColumn<String>(
        'exact_alarm_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('unknown'),
      ).withConverter<PermissionState>(
        $GlobalSettingsTableTable.$converterexactAlarmState,
      );
  @override
  late final GeneratedColumnWithTypeConverter<PermissionState, String>
  notificationPermissionState =
      GeneratedColumn<String>(
        'notification_permission_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('unknown'),
      ).withConverter<PermissionState>(
        $GlobalSettingsTableTable.$converternotificationPermissionState,
      );
  static const VerificationMeta _silentSwitchExplainedMeta =
      const VerificationMeta('silentSwitchExplained');
  @override
  late final GeneratedColumn<bool> silentSwitchExplained =
      GeneratedColumn<bool>(
        'silent_switch_explained',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("silent_switch_explained" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _setupCompletedMeta = const VerificationMeta(
    'setupCompleted',
  );
  @override
  late final GeneratedColumn<bool> setupCompleted = GeneratedColumn<bool>(
    'setup_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("setup_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _clockWallMsMeta = const VerificationMeta(
    'clockWallMs',
  );
  @override
  late final GeneratedColumn<int> clockWallMs = GeneratedColumn<int>(
    'clock_wall_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clockMonotonicMsMeta = const VerificationMeta(
    'clockMonotonicMs',
  );
  @override
  late final GeneratedColumn<int> clockMonotonicMs = GeneratedColumn<int>(
    'clock_monotonic_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clockBootIdMeta = const VerificationMeta(
    'clockBootId',
  );
  @override
  late final GeneratedColumn<String> clockBootId = GeneratedColumn<String>(
    'clock_boot_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduleRunsUntilMsMeta =
      const VerificationMeta('scheduleRunsUntilMs');
  @override
  late final GeneratedColumn<int> scheduleRunsUntilMs = GeneratedColumn<int>(
    'schedule_runs_until_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    audioOutput,
    quietHoursStartMinutes,
    quietHoursEndMinutes,
    suhoorReminderEnabled,
    suhoorReminderMinutes,
    exactAlarmState,
    notificationPermissionState,
    silentSwitchExplained,
    setupCompleted,
    clockWallMs,
    clockMonotonicMs,
    clockBootId,
    scheduleRunsUntilMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'global_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<GlobalSettingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('quiet_hours_start_minutes')) {
      context.handle(
        _quietHoursStartMinutesMeta,
        quietHoursStartMinutes.isAcceptableOrUnknown(
          data['quiet_hours_start_minutes']!,
          _quietHoursStartMinutesMeta,
        ),
      );
    }
    if (data.containsKey('quiet_hours_end_minutes')) {
      context.handle(
        _quietHoursEndMinutesMeta,
        quietHoursEndMinutes.isAcceptableOrUnknown(
          data['quiet_hours_end_minutes']!,
          _quietHoursEndMinutesMeta,
        ),
      );
    }
    if (data.containsKey('suhoor_reminder_enabled')) {
      context.handle(
        _suhoorReminderEnabledMeta,
        suhoorReminderEnabled.isAcceptableOrUnknown(
          data['suhoor_reminder_enabled']!,
          _suhoorReminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('suhoor_reminder_minutes')) {
      context.handle(
        _suhoorReminderMinutesMeta,
        suhoorReminderMinutes.isAcceptableOrUnknown(
          data['suhoor_reminder_minutes']!,
          _suhoorReminderMinutesMeta,
        ),
      );
    }
    if (data.containsKey('silent_switch_explained')) {
      context.handle(
        _silentSwitchExplainedMeta,
        silentSwitchExplained.isAcceptableOrUnknown(
          data['silent_switch_explained']!,
          _silentSwitchExplainedMeta,
        ),
      );
    }
    if (data.containsKey('setup_completed')) {
      context.handle(
        _setupCompletedMeta,
        setupCompleted.isAcceptableOrUnknown(
          data['setup_completed']!,
          _setupCompletedMeta,
        ),
      );
    }
    if (data.containsKey('clock_wall_ms')) {
      context.handle(
        _clockWallMsMeta,
        clockWallMs.isAcceptableOrUnknown(
          data['clock_wall_ms']!,
          _clockWallMsMeta,
        ),
      );
    }
    if (data.containsKey('clock_monotonic_ms')) {
      context.handle(
        _clockMonotonicMsMeta,
        clockMonotonicMs.isAcceptableOrUnknown(
          data['clock_monotonic_ms']!,
          _clockMonotonicMsMeta,
        ),
      );
    }
    if (data.containsKey('clock_boot_id')) {
      context.handle(
        _clockBootIdMeta,
        clockBootId.isAcceptableOrUnknown(
          data['clock_boot_id']!,
          _clockBootIdMeta,
        ),
      );
    }
    if (data.containsKey('schedule_runs_until_ms')) {
      context.handle(
        _scheduleRunsUntilMsMeta,
        scheduleRunsUntilMs.isAcceptableOrUnknown(
          data['schedule_runs_until_ms']!,
          _scheduleRunsUntilMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GlobalSettingsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GlobalSettingsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      audioOutput: $GlobalSettingsTableTable.$converteraudioOutput.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}audio_output'],
        )!,
      ),
      quietHoursStartMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quiet_hours_start_minutes'],
      ),
      quietHoursEndMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quiet_hours_end_minutes'],
      ),
      suhoorReminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}suhoor_reminder_enabled'],
      )!,
      suhoorReminderMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}suhoor_reminder_minutes'],
      )!,
      exactAlarmState: $GlobalSettingsTableTable.$converterexactAlarmState
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}exact_alarm_state'],
            )!,
          ),
      notificationPermissionState: $GlobalSettingsTableTable
          .$converternotificationPermissionState
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}notification_permission_state'],
            )!,
          ),
      silentSwitchExplained: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}silent_switch_explained'],
      )!,
      setupCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}setup_completed'],
      )!,
      clockWallMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}clock_wall_ms'],
      ),
      clockMonotonicMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}clock_monotonic_ms'],
      ),
      clockBootId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clock_boot_id'],
      ),
      scheduleRunsUntilMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schedule_runs_until_ms'],
      ),
    );
  }

  @override
  $GlobalSettingsTableTable createAlias(String alias) {
    return $GlobalSettingsTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AudioOutput, String, String> $converteraudioOutput =
      const EnumNameConverter<AudioOutput>(AudioOutput.values);
  static JsonTypeConverter2<PermissionState, String, String>
  $converterexactAlarmState = const EnumNameConverter<PermissionState>(
    PermissionState.values,
  );
  static JsonTypeConverter2<PermissionState, String, String>
  $converternotificationPermissionState =
      const EnumNameConverter<PermissionState>(PermissionState.values);
}

class GlobalSettingsTableData extends DataClass
    implements Insertable<GlobalSettingsTableData> {
  final int id;
  final AudioOutput audioOutput;

  /// Local times as minutes after midnight; both null means no quiet hours.
  final int? quietHoursStartMinutes;
  final int? quietHoursEndMinutes;
  final bool suhoorReminderEnabled;
  final int suhoorReminderMinutes;
  final PermissionState exactAlarmState;
  final PermissionState notificationPermissionState;
  final bool silentSwitchExplained;
  final bool setupCompleted;

  /// Last clock sample used by the clock-sanity check.
  final int? clockWallMs;
  final int? clockMonotonicMs;
  final String? clockBootId;

  /// End of the last scheduled alert (epoch ms), shown in the Reliability check.
  final int? scheduleRunsUntilMs;
  const GlobalSettingsTableData({
    required this.id,
    required this.audioOutput,
    this.quietHoursStartMinutes,
    this.quietHoursEndMinutes,
    required this.suhoorReminderEnabled,
    required this.suhoorReminderMinutes,
    required this.exactAlarmState,
    required this.notificationPermissionState,
    required this.silentSwitchExplained,
    required this.setupCompleted,
    this.clockWallMs,
    this.clockMonotonicMs,
    this.clockBootId,
    this.scheduleRunsUntilMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['audio_output'] = Variable<String>(
        $GlobalSettingsTableTable.$converteraudioOutput.toSql(audioOutput),
      );
    }
    if (!nullToAbsent || quietHoursStartMinutes != null) {
      map['quiet_hours_start_minutes'] = Variable<int>(quietHoursStartMinutes);
    }
    if (!nullToAbsent || quietHoursEndMinutes != null) {
      map['quiet_hours_end_minutes'] = Variable<int>(quietHoursEndMinutes);
    }
    map['suhoor_reminder_enabled'] = Variable<bool>(suhoorReminderEnabled);
    map['suhoor_reminder_minutes'] = Variable<int>(suhoorReminderMinutes);
    {
      map['exact_alarm_state'] = Variable<String>(
        $GlobalSettingsTableTable.$converterexactAlarmState.toSql(
          exactAlarmState,
        ),
      );
    }
    {
      map['notification_permission_state'] = Variable<String>(
        $GlobalSettingsTableTable.$converternotificationPermissionState.toSql(
          notificationPermissionState,
        ),
      );
    }
    map['silent_switch_explained'] = Variable<bool>(silentSwitchExplained);
    map['setup_completed'] = Variable<bool>(setupCompleted);
    if (!nullToAbsent || clockWallMs != null) {
      map['clock_wall_ms'] = Variable<int>(clockWallMs);
    }
    if (!nullToAbsent || clockMonotonicMs != null) {
      map['clock_monotonic_ms'] = Variable<int>(clockMonotonicMs);
    }
    if (!nullToAbsent || clockBootId != null) {
      map['clock_boot_id'] = Variable<String>(clockBootId);
    }
    if (!nullToAbsent || scheduleRunsUntilMs != null) {
      map['schedule_runs_until_ms'] = Variable<int>(scheduleRunsUntilMs);
    }
    return map;
  }

  GlobalSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return GlobalSettingsTableCompanion(
      id: Value(id),
      audioOutput: Value(audioOutput),
      quietHoursStartMinutes: quietHoursStartMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(quietHoursStartMinutes),
      quietHoursEndMinutes: quietHoursEndMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(quietHoursEndMinutes),
      suhoorReminderEnabled: Value(suhoorReminderEnabled),
      suhoorReminderMinutes: Value(suhoorReminderMinutes),
      exactAlarmState: Value(exactAlarmState),
      notificationPermissionState: Value(notificationPermissionState),
      silentSwitchExplained: Value(silentSwitchExplained),
      setupCompleted: Value(setupCompleted),
      clockWallMs: clockWallMs == null && nullToAbsent
          ? const Value.absent()
          : Value(clockWallMs),
      clockMonotonicMs: clockMonotonicMs == null && nullToAbsent
          ? const Value.absent()
          : Value(clockMonotonicMs),
      clockBootId: clockBootId == null && nullToAbsent
          ? const Value.absent()
          : Value(clockBootId),
      scheduleRunsUntilMs: scheduleRunsUntilMs == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduleRunsUntilMs),
    );
  }

  factory GlobalSettingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GlobalSettingsTableData(
      id: serializer.fromJson<int>(json['id']),
      audioOutput: $GlobalSettingsTableTable.$converteraudioOutput.fromJson(
        serializer.fromJson<String>(json['audioOutput']),
      ),
      quietHoursStartMinutes: serializer.fromJson<int?>(
        json['quietHoursStartMinutes'],
      ),
      quietHoursEndMinutes: serializer.fromJson<int?>(
        json['quietHoursEndMinutes'],
      ),
      suhoorReminderEnabled: serializer.fromJson<bool>(
        json['suhoorReminderEnabled'],
      ),
      suhoorReminderMinutes: serializer.fromJson<int>(
        json['suhoorReminderMinutes'],
      ),
      exactAlarmState: $GlobalSettingsTableTable.$converterexactAlarmState
          .fromJson(serializer.fromJson<String>(json['exactAlarmState'])),
      notificationPermissionState: $GlobalSettingsTableTable
          .$converternotificationPermissionState
          .fromJson(
            serializer.fromJson<String>(json['notificationPermissionState']),
          ),
      silentSwitchExplained: serializer.fromJson<bool>(
        json['silentSwitchExplained'],
      ),
      setupCompleted: serializer.fromJson<bool>(json['setupCompleted']),
      clockWallMs: serializer.fromJson<int?>(json['clockWallMs']),
      clockMonotonicMs: serializer.fromJson<int?>(json['clockMonotonicMs']),
      clockBootId: serializer.fromJson<String?>(json['clockBootId']),
      scheduleRunsUntilMs: serializer.fromJson<int?>(
        json['scheduleRunsUntilMs'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'audioOutput': serializer.toJson<String>(
        $GlobalSettingsTableTable.$converteraudioOutput.toJson(audioOutput),
      ),
      'quietHoursStartMinutes': serializer.toJson<int?>(quietHoursStartMinutes),
      'quietHoursEndMinutes': serializer.toJson<int?>(quietHoursEndMinutes),
      'suhoorReminderEnabled': serializer.toJson<bool>(suhoorReminderEnabled),
      'suhoorReminderMinutes': serializer.toJson<int>(suhoorReminderMinutes),
      'exactAlarmState': serializer.toJson<String>(
        $GlobalSettingsTableTable.$converterexactAlarmState.toJson(
          exactAlarmState,
        ),
      ),
      'notificationPermissionState': serializer.toJson<String>(
        $GlobalSettingsTableTable.$converternotificationPermissionState.toJson(
          notificationPermissionState,
        ),
      ),
      'silentSwitchExplained': serializer.toJson<bool>(silentSwitchExplained),
      'setupCompleted': serializer.toJson<bool>(setupCompleted),
      'clockWallMs': serializer.toJson<int?>(clockWallMs),
      'clockMonotonicMs': serializer.toJson<int?>(clockMonotonicMs),
      'clockBootId': serializer.toJson<String?>(clockBootId),
      'scheduleRunsUntilMs': serializer.toJson<int?>(scheduleRunsUntilMs),
    };
  }

  GlobalSettingsTableData copyWith({
    int? id,
    AudioOutput? audioOutput,
    Value<int?> quietHoursStartMinutes = const Value.absent(),
    Value<int?> quietHoursEndMinutes = const Value.absent(),
    bool? suhoorReminderEnabled,
    int? suhoorReminderMinutes,
    PermissionState? exactAlarmState,
    PermissionState? notificationPermissionState,
    bool? silentSwitchExplained,
    bool? setupCompleted,
    Value<int?> clockWallMs = const Value.absent(),
    Value<int?> clockMonotonicMs = const Value.absent(),
    Value<String?> clockBootId = const Value.absent(),
    Value<int?> scheduleRunsUntilMs = const Value.absent(),
  }) => GlobalSettingsTableData(
    id: id ?? this.id,
    audioOutput: audioOutput ?? this.audioOutput,
    quietHoursStartMinutes: quietHoursStartMinutes.present
        ? quietHoursStartMinutes.value
        : this.quietHoursStartMinutes,
    quietHoursEndMinutes: quietHoursEndMinutes.present
        ? quietHoursEndMinutes.value
        : this.quietHoursEndMinutes,
    suhoorReminderEnabled: suhoorReminderEnabled ?? this.suhoorReminderEnabled,
    suhoorReminderMinutes: suhoorReminderMinutes ?? this.suhoorReminderMinutes,
    exactAlarmState: exactAlarmState ?? this.exactAlarmState,
    notificationPermissionState:
        notificationPermissionState ?? this.notificationPermissionState,
    silentSwitchExplained: silentSwitchExplained ?? this.silentSwitchExplained,
    setupCompleted: setupCompleted ?? this.setupCompleted,
    clockWallMs: clockWallMs.present ? clockWallMs.value : this.clockWallMs,
    clockMonotonicMs: clockMonotonicMs.present
        ? clockMonotonicMs.value
        : this.clockMonotonicMs,
    clockBootId: clockBootId.present ? clockBootId.value : this.clockBootId,
    scheduleRunsUntilMs: scheduleRunsUntilMs.present
        ? scheduleRunsUntilMs.value
        : this.scheduleRunsUntilMs,
  );
  GlobalSettingsTableData copyWithCompanion(GlobalSettingsTableCompanion data) {
    return GlobalSettingsTableData(
      id: data.id.present ? data.id.value : this.id,
      audioOutput: data.audioOutput.present
          ? data.audioOutput.value
          : this.audioOutput,
      quietHoursStartMinutes: data.quietHoursStartMinutes.present
          ? data.quietHoursStartMinutes.value
          : this.quietHoursStartMinutes,
      quietHoursEndMinutes: data.quietHoursEndMinutes.present
          ? data.quietHoursEndMinutes.value
          : this.quietHoursEndMinutes,
      suhoorReminderEnabled: data.suhoorReminderEnabled.present
          ? data.suhoorReminderEnabled.value
          : this.suhoorReminderEnabled,
      suhoorReminderMinutes: data.suhoorReminderMinutes.present
          ? data.suhoorReminderMinutes.value
          : this.suhoorReminderMinutes,
      exactAlarmState: data.exactAlarmState.present
          ? data.exactAlarmState.value
          : this.exactAlarmState,
      notificationPermissionState: data.notificationPermissionState.present
          ? data.notificationPermissionState.value
          : this.notificationPermissionState,
      silentSwitchExplained: data.silentSwitchExplained.present
          ? data.silentSwitchExplained.value
          : this.silentSwitchExplained,
      setupCompleted: data.setupCompleted.present
          ? data.setupCompleted.value
          : this.setupCompleted,
      clockWallMs: data.clockWallMs.present
          ? data.clockWallMs.value
          : this.clockWallMs,
      clockMonotonicMs: data.clockMonotonicMs.present
          ? data.clockMonotonicMs.value
          : this.clockMonotonicMs,
      clockBootId: data.clockBootId.present
          ? data.clockBootId.value
          : this.clockBootId,
      scheduleRunsUntilMs: data.scheduleRunsUntilMs.present
          ? data.scheduleRunsUntilMs.value
          : this.scheduleRunsUntilMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GlobalSettingsTableData(')
          ..write('id: $id, ')
          ..write('audioOutput: $audioOutput, ')
          ..write('quietHoursStartMinutes: $quietHoursStartMinutes, ')
          ..write('quietHoursEndMinutes: $quietHoursEndMinutes, ')
          ..write('suhoorReminderEnabled: $suhoorReminderEnabled, ')
          ..write('suhoorReminderMinutes: $suhoorReminderMinutes, ')
          ..write('exactAlarmState: $exactAlarmState, ')
          ..write('notificationPermissionState: $notificationPermissionState, ')
          ..write('silentSwitchExplained: $silentSwitchExplained, ')
          ..write('setupCompleted: $setupCompleted, ')
          ..write('clockWallMs: $clockWallMs, ')
          ..write('clockMonotonicMs: $clockMonotonicMs, ')
          ..write('clockBootId: $clockBootId, ')
          ..write('scheduleRunsUntilMs: $scheduleRunsUntilMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    audioOutput,
    quietHoursStartMinutes,
    quietHoursEndMinutes,
    suhoorReminderEnabled,
    suhoorReminderMinutes,
    exactAlarmState,
    notificationPermissionState,
    silentSwitchExplained,
    setupCompleted,
    clockWallMs,
    clockMonotonicMs,
    clockBootId,
    scheduleRunsUntilMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GlobalSettingsTableData &&
          other.id == this.id &&
          other.audioOutput == this.audioOutput &&
          other.quietHoursStartMinutes == this.quietHoursStartMinutes &&
          other.quietHoursEndMinutes == this.quietHoursEndMinutes &&
          other.suhoorReminderEnabled == this.suhoorReminderEnabled &&
          other.suhoorReminderMinutes == this.suhoorReminderMinutes &&
          other.exactAlarmState == this.exactAlarmState &&
          other.notificationPermissionState ==
              this.notificationPermissionState &&
          other.silentSwitchExplained == this.silentSwitchExplained &&
          other.setupCompleted == this.setupCompleted &&
          other.clockWallMs == this.clockWallMs &&
          other.clockMonotonicMs == this.clockMonotonicMs &&
          other.clockBootId == this.clockBootId &&
          other.scheduleRunsUntilMs == this.scheduleRunsUntilMs);
}

class GlobalSettingsTableCompanion
    extends UpdateCompanion<GlobalSettingsTableData> {
  final Value<int> id;
  final Value<AudioOutput> audioOutput;
  final Value<int?> quietHoursStartMinutes;
  final Value<int?> quietHoursEndMinutes;
  final Value<bool> suhoorReminderEnabled;
  final Value<int> suhoorReminderMinutes;
  final Value<PermissionState> exactAlarmState;
  final Value<PermissionState> notificationPermissionState;
  final Value<bool> silentSwitchExplained;
  final Value<bool> setupCompleted;
  final Value<int?> clockWallMs;
  final Value<int?> clockMonotonicMs;
  final Value<String?> clockBootId;
  final Value<int?> scheduleRunsUntilMs;
  const GlobalSettingsTableCompanion({
    this.id = const Value.absent(),
    this.audioOutput = const Value.absent(),
    this.quietHoursStartMinutes = const Value.absent(),
    this.quietHoursEndMinutes = const Value.absent(),
    this.suhoorReminderEnabled = const Value.absent(),
    this.suhoorReminderMinutes = const Value.absent(),
    this.exactAlarmState = const Value.absent(),
    this.notificationPermissionState = const Value.absent(),
    this.silentSwitchExplained = const Value.absent(),
    this.setupCompleted = const Value.absent(),
    this.clockWallMs = const Value.absent(),
    this.clockMonotonicMs = const Value.absent(),
    this.clockBootId = const Value.absent(),
    this.scheduleRunsUntilMs = const Value.absent(),
  });
  GlobalSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    this.audioOutput = const Value.absent(),
    this.quietHoursStartMinutes = const Value.absent(),
    this.quietHoursEndMinutes = const Value.absent(),
    this.suhoorReminderEnabled = const Value.absent(),
    this.suhoorReminderMinutes = const Value.absent(),
    this.exactAlarmState = const Value.absent(),
    this.notificationPermissionState = const Value.absent(),
    this.silentSwitchExplained = const Value.absent(),
    this.setupCompleted = const Value.absent(),
    this.clockWallMs = const Value.absent(),
    this.clockMonotonicMs = const Value.absent(),
    this.clockBootId = const Value.absent(),
    this.scheduleRunsUntilMs = const Value.absent(),
  });
  static Insertable<GlobalSettingsTableData> custom({
    Expression<int>? id,
    Expression<String>? audioOutput,
    Expression<int>? quietHoursStartMinutes,
    Expression<int>? quietHoursEndMinutes,
    Expression<bool>? suhoorReminderEnabled,
    Expression<int>? suhoorReminderMinutes,
    Expression<String>? exactAlarmState,
    Expression<String>? notificationPermissionState,
    Expression<bool>? silentSwitchExplained,
    Expression<bool>? setupCompleted,
    Expression<int>? clockWallMs,
    Expression<int>? clockMonotonicMs,
    Expression<String>? clockBootId,
    Expression<int>? scheduleRunsUntilMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (audioOutput != null) 'audio_output': audioOutput,
      if (quietHoursStartMinutes != null)
        'quiet_hours_start_minutes': quietHoursStartMinutes,
      if (quietHoursEndMinutes != null)
        'quiet_hours_end_minutes': quietHoursEndMinutes,
      if (suhoorReminderEnabled != null)
        'suhoor_reminder_enabled': suhoorReminderEnabled,
      if (suhoorReminderMinutes != null)
        'suhoor_reminder_minutes': suhoorReminderMinutes,
      if (exactAlarmState != null) 'exact_alarm_state': exactAlarmState,
      if (notificationPermissionState != null)
        'notification_permission_state': notificationPermissionState,
      if (silentSwitchExplained != null)
        'silent_switch_explained': silentSwitchExplained,
      if (setupCompleted != null) 'setup_completed': setupCompleted,
      if (clockWallMs != null) 'clock_wall_ms': clockWallMs,
      if (clockMonotonicMs != null) 'clock_monotonic_ms': clockMonotonicMs,
      if (clockBootId != null) 'clock_boot_id': clockBootId,
      if (scheduleRunsUntilMs != null)
        'schedule_runs_until_ms': scheduleRunsUntilMs,
    });
  }

  GlobalSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<AudioOutput>? audioOutput,
    Value<int?>? quietHoursStartMinutes,
    Value<int?>? quietHoursEndMinutes,
    Value<bool>? suhoorReminderEnabled,
    Value<int>? suhoorReminderMinutes,
    Value<PermissionState>? exactAlarmState,
    Value<PermissionState>? notificationPermissionState,
    Value<bool>? silentSwitchExplained,
    Value<bool>? setupCompleted,
    Value<int?>? clockWallMs,
    Value<int?>? clockMonotonicMs,
    Value<String?>? clockBootId,
    Value<int?>? scheduleRunsUntilMs,
  }) {
    return GlobalSettingsTableCompanion(
      id: id ?? this.id,
      audioOutput: audioOutput ?? this.audioOutput,
      quietHoursStartMinutes:
          quietHoursStartMinutes ?? this.quietHoursStartMinutes,
      quietHoursEndMinutes: quietHoursEndMinutes ?? this.quietHoursEndMinutes,
      suhoorReminderEnabled:
          suhoorReminderEnabled ?? this.suhoorReminderEnabled,
      suhoorReminderMinutes:
          suhoorReminderMinutes ?? this.suhoorReminderMinutes,
      exactAlarmState: exactAlarmState ?? this.exactAlarmState,
      notificationPermissionState:
          notificationPermissionState ?? this.notificationPermissionState,
      silentSwitchExplained:
          silentSwitchExplained ?? this.silentSwitchExplained,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      clockWallMs: clockWallMs ?? this.clockWallMs,
      clockMonotonicMs: clockMonotonicMs ?? this.clockMonotonicMs,
      clockBootId: clockBootId ?? this.clockBootId,
      scheduleRunsUntilMs: scheduleRunsUntilMs ?? this.scheduleRunsUntilMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (audioOutput.present) {
      map['audio_output'] = Variable<String>(
        $GlobalSettingsTableTable.$converteraudioOutput.toSql(
          audioOutput.value,
        ),
      );
    }
    if (quietHoursStartMinutes.present) {
      map['quiet_hours_start_minutes'] = Variable<int>(
        quietHoursStartMinutes.value,
      );
    }
    if (quietHoursEndMinutes.present) {
      map['quiet_hours_end_minutes'] = Variable<int>(
        quietHoursEndMinutes.value,
      );
    }
    if (suhoorReminderEnabled.present) {
      map['suhoor_reminder_enabled'] = Variable<bool>(
        suhoorReminderEnabled.value,
      );
    }
    if (suhoorReminderMinutes.present) {
      map['suhoor_reminder_minutes'] = Variable<int>(
        suhoorReminderMinutes.value,
      );
    }
    if (exactAlarmState.present) {
      map['exact_alarm_state'] = Variable<String>(
        $GlobalSettingsTableTable.$converterexactAlarmState.toSql(
          exactAlarmState.value,
        ),
      );
    }
    if (notificationPermissionState.present) {
      map['notification_permission_state'] = Variable<String>(
        $GlobalSettingsTableTable.$converternotificationPermissionState.toSql(
          notificationPermissionState.value,
        ),
      );
    }
    if (silentSwitchExplained.present) {
      map['silent_switch_explained'] = Variable<bool>(
        silentSwitchExplained.value,
      );
    }
    if (setupCompleted.present) {
      map['setup_completed'] = Variable<bool>(setupCompleted.value);
    }
    if (clockWallMs.present) {
      map['clock_wall_ms'] = Variable<int>(clockWallMs.value);
    }
    if (clockMonotonicMs.present) {
      map['clock_monotonic_ms'] = Variable<int>(clockMonotonicMs.value);
    }
    if (clockBootId.present) {
      map['clock_boot_id'] = Variable<String>(clockBootId.value);
    }
    if (scheduleRunsUntilMs.present) {
      map['schedule_runs_until_ms'] = Variable<int>(scheduleRunsUntilMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GlobalSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('audioOutput: $audioOutput, ')
          ..write('quietHoursStartMinutes: $quietHoursStartMinutes, ')
          ..write('quietHoursEndMinutes: $quietHoursEndMinutes, ')
          ..write('suhoorReminderEnabled: $suhoorReminderEnabled, ')
          ..write('suhoorReminderMinutes: $suhoorReminderMinutes, ')
          ..write('exactAlarmState: $exactAlarmState, ')
          ..write('notificationPermissionState: $notificationPermissionState, ')
          ..write('silentSwitchExplained: $silentSwitchExplained, ')
          ..write('setupCompleted: $setupCompleted, ')
          ..write('clockWallMs: $clockWallMs, ')
          ..write('clockMonotonicMs: $clockMonotonicMs, ')
          ..write('clockBootId: $clockBootId, ')
          ..write('scheduleRunsUntilMs: $scheduleRunsUntilMs')
          ..write(')'))
        .toString();
  }
}

class $AlertLogTableTable extends AlertLogTable
    with TableInfo<$AlertLogTableTable, AlertLogTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlertLogTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _alertIdMeta = const VerificationMeta(
    'alertId',
  );
  @override
  late final GeneratedColumn<String> alertId = GeneratedColumn<String>(
    'alert_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptMeta = const VerificationMeta(
    'attempt',
  );
  @override
  late final GeneratedColumn<int> attempt = GeneratedColumn<int>(
    'attempt',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _plannedFireAtMsMeta = const VerificationMeta(
    'plannedFireAtMs',
  );
  @override
  late final GeneratedColumn<int> plannedFireAtMs = GeneratedColumn<int>(
    'planned_fire_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AlertLogState, String> state =
      GeneratedColumn<String>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AlertLogState>($AlertLogTableTable.$converterstate);
  static const VerificationMeta _firedAtMsMeta = const VerificationMeta(
    'firedAtMs',
  );
  @override
  late final GeneratedColumn<int> firedAtMs = GeneratedColumn<int>(
    'fired_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviationMsMeta = const VerificationMeta(
    'deviationMs',
  );
  @override
  late final GeneratedColumn<int> deviationMs = GeneratedColumn<int>(
    'deviation_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _causeMeta = const VerificationMeta('cause');
  @override
  late final GeneratedColumn<String> cause = GeneratedColumn<String>(
    'cause',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AlertLogSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AlertLogSource>($AlertLogTableTable.$convertersource);
  @override
  List<GeneratedColumn> get $columns => [
    alertId,
    attempt,
    plannedFireAtMs,
    state,
    firedAtMs,
    deviationMs,
    cause,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alert_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlertLogTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('alert_id')) {
      context.handle(
        _alertIdMeta,
        alertId.isAcceptableOrUnknown(data['alert_id']!, _alertIdMeta),
      );
    } else if (isInserting) {
      context.missing(_alertIdMeta);
    }
    if (data.containsKey('attempt')) {
      context.handle(
        _attemptMeta,
        attempt.isAcceptableOrUnknown(data['attempt']!, _attemptMeta),
      );
    }
    if (data.containsKey('planned_fire_at_ms')) {
      context.handle(
        _plannedFireAtMsMeta,
        plannedFireAtMs.isAcceptableOrUnknown(
          data['planned_fire_at_ms']!,
          _plannedFireAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedFireAtMsMeta);
    }
    if (data.containsKey('fired_at_ms')) {
      context.handle(
        _firedAtMsMeta,
        firedAtMs.isAcceptableOrUnknown(data['fired_at_ms']!, _firedAtMsMeta),
      );
    }
    if (data.containsKey('deviation_ms')) {
      context.handle(
        _deviationMsMeta,
        deviationMs.isAcceptableOrUnknown(
          data['deviation_ms']!,
          _deviationMsMeta,
        ),
      );
    }
    if (data.containsKey('cause')) {
      context.handle(
        _causeMeta,
        cause.isAcceptableOrUnknown(data['cause']!, _causeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {alertId, attempt};
  @override
  AlertLogTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlertLogTableData(
      alertId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alert_id'],
      )!,
      attempt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt'],
      )!,
      plannedFireAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_fire_at_ms'],
      )!,
      state: $AlertLogTableTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}state'],
        )!,
      ),
      firedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fired_at_ms'],
      ),
      deviationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deviation_ms'],
      ),
      cause: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cause'],
      ),
      source: $AlertLogTableTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
    );
  }

  @override
  $AlertLogTableTable createAlias(String alias) {
    return $AlertLogTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AlertLogState, String, String> $converterstate =
      const EnumNameConverter<AlertLogState>(AlertLogState.values);
  static JsonTypeConverter2<AlertLogSource, String, String> $convertersource =
      const EnumNameConverter<AlertLogSource>(AlertLogSource.values);
}

class AlertLogTableData extends DataClass
    implements Insertable<AlertLogTableData> {
  /// Stable id from the planner, for example `fajr:2026-10-22`.
  final String alertId;

  /// Retry counter so a rebuilt alert never overwrites its history.
  final int attempt;
  final int plannedFireAtMs;
  final AlertLogState state;
  final int? firedAtMs;

  /// Milliseconds between planned and actual time (feeds SC-002).
  final int? deviationMs;

  /// One of the causes in data-model.md.
  final String? cause;
  final AlertLogSource source;
  const AlertLogTableData({
    required this.alertId,
    required this.attempt,
    required this.plannedFireAtMs,
    required this.state,
    this.firedAtMs,
    this.deviationMs,
    this.cause,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['alert_id'] = Variable<String>(alertId);
    map['attempt'] = Variable<int>(attempt);
    map['planned_fire_at_ms'] = Variable<int>(plannedFireAtMs);
    {
      map['state'] = Variable<String>(
        $AlertLogTableTable.$converterstate.toSql(state),
      );
    }
    if (!nullToAbsent || firedAtMs != null) {
      map['fired_at_ms'] = Variable<int>(firedAtMs);
    }
    if (!nullToAbsent || deviationMs != null) {
      map['deviation_ms'] = Variable<int>(deviationMs);
    }
    if (!nullToAbsent || cause != null) {
      map['cause'] = Variable<String>(cause);
    }
    {
      map['source'] = Variable<String>(
        $AlertLogTableTable.$convertersource.toSql(source),
      );
    }
    return map;
  }

  AlertLogTableCompanion toCompanion(bool nullToAbsent) {
    return AlertLogTableCompanion(
      alertId: Value(alertId),
      attempt: Value(attempt),
      plannedFireAtMs: Value(plannedFireAtMs),
      state: Value(state),
      firedAtMs: firedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(firedAtMs),
      deviationMs: deviationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(deviationMs),
      cause: cause == null && nullToAbsent
          ? const Value.absent()
          : Value(cause),
      source: Value(source),
    );
  }

  factory AlertLogTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlertLogTableData(
      alertId: serializer.fromJson<String>(json['alertId']),
      attempt: serializer.fromJson<int>(json['attempt']),
      plannedFireAtMs: serializer.fromJson<int>(json['plannedFireAtMs']),
      state: $AlertLogTableTable.$converterstate.fromJson(
        serializer.fromJson<String>(json['state']),
      ),
      firedAtMs: serializer.fromJson<int?>(json['firedAtMs']),
      deviationMs: serializer.fromJson<int?>(json['deviationMs']),
      cause: serializer.fromJson<String?>(json['cause']),
      source: $AlertLogTableTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'alertId': serializer.toJson<String>(alertId),
      'attempt': serializer.toJson<int>(attempt),
      'plannedFireAtMs': serializer.toJson<int>(plannedFireAtMs),
      'state': serializer.toJson<String>(
        $AlertLogTableTable.$converterstate.toJson(state),
      ),
      'firedAtMs': serializer.toJson<int?>(firedAtMs),
      'deviationMs': serializer.toJson<int?>(deviationMs),
      'cause': serializer.toJson<String?>(cause),
      'source': serializer.toJson<String>(
        $AlertLogTableTable.$convertersource.toJson(source),
      ),
    };
  }

  AlertLogTableData copyWith({
    String? alertId,
    int? attempt,
    int? plannedFireAtMs,
    AlertLogState? state,
    Value<int?> firedAtMs = const Value.absent(),
    Value<int?> deviationMs = const Value.absent(),
    Value<String?> cause = const Value.absent(),
    AlertLogSource? source,
  }) => AlertLogTableData(
    alertId: alertId ?? this.alertId,
    attempt: attempt ?? this.attempt,
    plannedFireAtMs: plannedFireAtMs ?? this.plannedFireAtMs,
    state: state ?? this.state,
    firedAtMs: firedAtMs.present ? firedAtMs.value : this.firedAtMs,
    deviationMs: deviationMs.present ? deviationMs.value : this.deviationMs,
    cause: cause.present ? cause.value : this.cause,
    source: source ?? this.source,
  );
  AlertLogTableData copyWithCompanion(AlertLogTableCompanion data) {
    return AlertLogTableData(
      alertId: data.alertId.present ? data.alertId.value : this.alertId,
      attempt: data.attempt.present ? data.attempt.value : this.attempt,
      plannedFireAtMs: data.plannedFireAtMs.present
          ? data.plannedFireAtMs.value
          : this.plannedFireAtMs,
      state: data.state.present ? data.state.value : this.state,
      firedAtMs: data.firedAtMs.present ? data.firedAtMs.value : this.firedAtMs,
      deviationMs: data.deviationMs.present
          ? data.deviationMs.value
          : this.deviationMs,
      cause: data.cause.present ? data.cause.value : this.cause,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlertLogTableData(')
          ..write('alertId: $alertId, ')
          ..write('attempt: $attempt, ')
          ..write('plannedFireAtMs: $plannedFireAtMs, ')
          ..write('state: $state, ')
          ..write('firedAtMs: $firedAtMs, ')
          ..write('deviationMs: $deviationMs, ')
          ..write('cause: $cause, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    alertId,
    attempt,
    plannedFireAtMs,
    state,
    firedAtMs,
    deviationMs,
    cause,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlertLogTableData &&
          other.alertId == this.alertId &&
          other.attempt == this.attempt &&
          other.plannedFireAtMs == this.plannedFireAtMs &&
          other.state == this.state &&
          other.firedAtMs == this.firedAtMs &&
          other.deviationMs == this.deviationMs &&
          other.cause == this.cause &&
          other.source == this.source);
}

class AlertLogTableCompanion extends UpdateCompanion<AlertLogTableData> {
  final Value<String> alertId;
  final Value<int> attempt;
  final Value<int> plannedFireAtMs;
  final Value<AlertLogState> state;
  final Value<int?> firedAtMs;
  final Value<int?> deviationMs;
  final Value<String?> cause;
  final Value<AlertLogSource> source;
  final Value<int> rowid;
  const AlertLogTableCompanion({
    this.alertId = const Value.absent(),
    this.attempt = const Value.absent(),
    this.plannedFireAtMs = const Value.absent(),
    this.state = const Value.absent(),
    this.firedAtMs = const Value.absent(),
    this.deviationMs = const Value.absent(),
    this.cause = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlertLogTableCompanion.insert({
    required String alertId,
    this.attempt = const Value.absent(),
    required int plannedFireAtMs,
    required AlertLogState state,
    this.firedAtMs = const Value.absent(),
    this.deviationMs = const Value.absent(),
    this.cause = const Value.absent(),
    required AlertLogSource source,
    this.rowid = const Value.absent(),
  }) : alertId = Value(alertId),
       plannedFireAtMs = Value(plannedFireAtMs),
       state = Value(state),
       source = Value(source);
  static Insertable<AlertLogTableData> custom({
    Expression<String>? alertId,
    Expression<int>? attempt,
    Expression<int>? plannedFireAtMs,
    Expression<String>? state,
    Expression<int>? firedAtMs,
    Expression<int>? deviationMs,
    Expression<String>? cause,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (alertId != null) 'alert_id': alertId,
      if (attempt != null) 'attempt': attempt,
      if (plannedFireAtMs != null) 'planned_fire_at_ms': plannedFireAtMs,
      if (state != null) 'state': state,
      if (firedAtMs != null) 'fired_at_ms': firedAtMs,
      if (deviationMs != null) 'deviation_ms': deviationMs,
      if (cause != null) 'cause': cause,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlertLogTableCompanion copyWith({
    Value<String>? alertId,
    Value<int>? attempt,
    Value<int>? plannedFireAtMs,
    Value<AlertLogState>? state,
    Value<int?>? firedAtMs,
    Value<int?>? deviationMs,
    Value<String?>? cause,
    Value<AlertLogSource>? source,
    Value<int>? rowid,
  }) {
    return AlertLogTableCompanion(
      alertId: alertId ?? this.alertId,
      attempt: attempt ?? this.attempt,
      plannedFireAtMs: plannedFireAtMs ?? this.plannedFireAtMs,
      state: state ?? this.state,
      firedAtMs: firedAtMs ?? this.firedAtMs,
      deviationMs: deviationMs ?? this.deviationMs,
      cause: cause ?? this.cause,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (alertId.present) {
      map['alert_id'] = Variable<String>(alertId.value);
    }
    if (attempt.present) {
      map['attempt'] = Variable<int>(attempt.value);
    }
    if (plannedFireAtMs.present) {
      map['planned_fire_at_ms'] = Variable<int>(plannedFireAtMs.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(
        $AlertLogTableTable.$converterstate.toSql(state.value),
      );
    }
    if (firedAtMs.present) {
      map['fired_at_ms'] = Variable<int>(firedAtMs.value);
    }
    if (deviationMs.present) {
      map['deviation_ms'] = Variable<int>(deviationMs.value);
    }
    if (cause.present) {
      map['cause'] = Variable<String>(cause.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $AlertLogTableTable.$convertersource.toSql(source.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertLogTableCompanion(')
          ..write('alertId: $alertId, ')
          ..write('attempt: $attempt, ')
          ..write('plannedFireAtMs: $plannedFireAtMs, ')
          ..write('state: $state, ')
          ..write('firedAtMs: $firedAtMs, ')
          ..write('deviationMs: $deviationMs, ')
          ..write('cause: $cause, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasbihStateTableTable extends TasbihStateTable
    with TableInfo<$TasbihStateTableTable, TasbihStateTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasbihStateTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<int> target = GeneratedColumn<int>(
    'target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(33),
  );
  static const VerificationMeta _keepAwakeMeta = const VerificationMeta(
    'keepAwake',
  );
  @override
  late final GeneratedColumn<bool> keepAwake = GeneratedColumn<bool>(
    'keep_awake',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("keep_awake" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _volumeKeysMeta = const VerificationMeta(
    'volumeKeys',
  );
  @override
  late final GeneratedColumn<bool> volumeKeys = GeneratedColumn<bool>(
    'volume_keys',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("volume_keys" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lockMeta = const VerificationMeta('lock');
  @override
  late final GeneratedColumn<bool> lock = GeneratedColumn<bool>(
    'lock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("lock" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hapticsMeta = const VerificationMeta(
    'haptics',
  );
  @override
  late final GeneratedColumn<bool> haptics = GeneratedColumn<bool>(
    'haptics',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("haptics" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _soundMeta = const VerificationMeta('sound');
  @override
  late final GeneratedColumn<bool> sound = GeneratedColumn<bool>(
    'sound',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sound" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    count,
    target,
    keepAwake,
    volumeKeys,
    lock,
    haptics,
    sound,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasbih_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<TasbihStateTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    if (data.containsKey('target')) {
      context.handle(
        _targetMeta,
        target.isAcceptableOrUnknown(data['target']!, _targetMeta),
      );
    }
    if (data.containsKey('keep_awake')) {
      context.handle(
        _keepAwakeMeta,
        keepAwake.isAcceptableOrUnknown(data['keep_awake']!, _keepAwakeMeta),
      );
    }
    if (data.containsKey('volume_keys')) {
      context.handle(
        _volumeKeysMeta,
        volumeKeys.isAcceptableOrUnknown(data['volume_keys']!, _volumeKeysMeta),
      );
    }
    if (data.containsKey('lock')) {
      context.handle(
        _lockMeta,
        lock.isAcceptableOrUnknown(data['lock']!, _lockMeta),
      );
    }
    if (data.containsKey('haptics')) {
      context.handle(
        _hapticsMeta,
        haptics.isAcceptableOrUnknown(data['haptics']!, _hapticsMeta),
      );
    }
    if (data.containsKey('sound')) {
      context.handle(
        _soundMeta,
        sound.isAcceptableOrUnknown(data['sound']!, _soundMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TasbihStateTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TasbihStateTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      target: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target'],
      )!,
      keepAwake: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}keep_awake'],
      )!,
      volumeKeys: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}volume_keys'],
      )!,
      lock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}lock'],
      )!,
      haptics: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}haptics'],
      )!,
      sound: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sound'],
      )!,
    );
  }

  @override
  $TasbihStateTableTable createAlias(String alias) {
    return $TasbihStateTableTable(attachedDatabase, alias);
  }
}

class TasbihStateTableData extends DataClass
    implements Insertable<TasbihStateTableData> {
  final int id;
  final int count;
  final int target;
  final bool keepAwake;
  final bool volumeKeys;
  final bool lock;
  final bool haptics;
  final bool sound;
  const TasbihStateTableData({
    required this.id,
    required this.count,
    required this.target,
    required this.keepAwake,
    required this.volumeKeys,
    required this.lock,
    required this.haptics,
    required this.sound,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['count'] = Variable<int>(count);
    map['target'] = Variable<int>(target);
    map['keep_awake'] = Variable<bool>(keepAwake);
    map['volume_keys'] = Variable<bool>(volumeKeys);
    map['lock'] = Variable<bool>(lock);
    map['haptics'] = Variable<bool>(haptics);
    map['sound'] = Variable<bool>(sound);
    return map;
  }

  TasbihStateTableCompanion toCompanion(bool nullToAbsent) {
    return TasbihStateTableCompanion(
      id: Value(id),
      count: Value(count),
      target: Value(target),
      keepAwake: Value(keepAwake),
      volumeKeys: Value(volumeKeys),
      lock: Value(lock),
      haptics: Value(haptics),
      sound: Value(sound),
    );
  }

  factory TasbihStateTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TasbihStateTableData(
      id: serializer.fromJson<int>(json['id']),
      count: serializer.fromJson<int>(json['count']),
      target: serializer.fromJson<int>(json['target']),
      keepAwake: serializer.fromJson<bool>(json['keepAwake']),
      volumeKeys: serializer.fromJson<bool>(json['volumeKeys']),
      lock: serializer.fromJson<bool>(json['lock']),
      haptics: serializer.fromJson<bool>(json['haptics']),
      sound: serializer.fromJson<bool>(json['sound']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'count': serializer.toJson<int>(count),
      'target': serializer.toJson<int>(target),
      'keepAwake': serializer.toJson<bool>(keepAwake),
      'volumeKeys': serializer.toJson<bool>(volumeKeys),
      'lock': serializer.toJson<bool>(lock),
      'haptics': serializer.toJson<bool>(haptics),
      'sound': serializer.toJson<bool>(sound),
    };
  }

  TasbihStateTableData copyWith({
    int? id,
    int? count,
    int? target,
    bool? keepAwake,
    bool? volumeKeys,
    bool? lock,
    bool? haptics,
    bool? sound,
  }) => TasbihStateTableData(
    id: id ?? this.id,
    count: count ?? this.count,
    target: target ?? this.target,
    keepAwake: keepAwake ?? this.keepAwake,
    volumeKeys: volumeKeys ?? this.volumeKeys,
    lock: lock ?? this.lock,
    haptics: haptics ?? this.haptics,
    sound: sound ?? this.sound,
  );
  TasbihStateTableData copyWithCompanion(TasbihStateTableCompanion data) {
    return TasbihStateTableData(
      id: data.id.present ? data.id.value : this.id,
      count: data.count.present ? data.count.value : this.count,
      target: data.target.present ? data.target.value : this.target,
      keepAwake: data.keepAwake.present ? data.keepAwake.value : this.keepAwake,
      volumeKeys: data.volumeKeys.present
          ? data.volumeKeys.value
          : this.volumeKeys,
      lock: data.lock.present ? data.lock.value : this.lock,
      haptics: data.haptics.present ? data.haptics.value : this.haptics,
      sound: data.sound.present ? data.sound.value : this.sound,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TasbihStateTableData(')
          ..write('id: $id, ')
          ..write('count: $count, ')
          ..write('target: $target, ')
          ..write('keepAwake: $keepAwake, ')
          ..write('volumeKeys: $volumeKeys, ')
          ..write('lock: $lock, ')
          ..write('haptics: $haptics, ')
          ..write('sound: $sound')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    count,
    target,
    keepAwake,
    volumeKeys,
    lock,
    haptics,
    sound,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TasbihStateTableData &&
          other.id == this.id &&
          other.count == this.count &&
          other.target == this.target &&
          other.keepAwake == this.keepAwake &&
          other.volumeKeys == this.volumeKeys &&
          other.lock == this.lock &&
          other.haptics == this.haptics &&
          other.sound == this.sound);
}

class TasbihStateTableCompanion extends UpdateCompanion<TasbihStateTableData> {
  final Value<int> id;
  final Value<int> count;
  final Value<int> target;
  final Value<bool> keepAwake;
  final Value<bool> volumeKeys;
  final Value<bool> lock;
  final Value<bool> haptics;
  final Value<bool> sound;
  const TasbihStateTableCompanion({
    this.id = const Value.absent(),
    this.count = const Value.absent(),
    this.target = const Value.absent(),
    this.keepAwake = const Value.absent(),
    this.volumeKeys = const Value.absent(),
    this.lock = const Value.absent(),
    this.haptics = const Value.absent(),
    this.sound = const Value.absent(),
  });
  TasbihStateTableCompanion.insert({
    this.id = const Value.absent(),
    this.count = const Value.absent(),
    this.target = const Value.absent(),
    this.keepAwake = const Value.absent(),
    this.volumeKeys = const Value.absent(),
    this.lock = const Value.absent(),
    this.haptics = const Value.absent(),
    this.sound = const Value.absent(),
  });
  static Insertable<TasbihStateTableData> custom({
    Expression<int>? id,
    Expression<int>? count,
    Expression<int>? target,
    Expression<bool>? keepAwake,
    Expression<bool>? volumeKeys,
    Expression<bool>? lock,
    Expression<bool>? haptics,
    Expression<bool>? sound,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (count != null) 'count': count,
      if (target != null) 'target': target,
      if (keepAwake != null) 'keep_awake': keepAwake,
      if (volumeKeys != null) 'volume_keys': volumeKeys,
      if (lock != null) 'lock': lock,
      if (haptics != null) 'haptics': haptics,
      if (sound != null) 'sound': sound,
    });
  }

  TasbihStateTableCompanion copyWith({
    Value<int>? id,
    Value<int>? count,
    Value<int>? target,
    Value<bool>? keepAwake,
    Value<bool>? volumeKeys,
    Value<bool>? lock,
    Value<bool>? haptics,
    Value<bool>? sound,
  }) {
    return TasbihStateTableCompanion(
      id: id ?? this.id,
      count: count ?? this.count,
      target: target ?? this.target,
      keepAwake: keepAwake ?? this.keepAwake,
      volumeKeys: volumeKeys ?? this.volumeKeys,
      lock: lock ?? this.lock,
      haptics: haptics ?? this.haptics,
      sound: sound ?? this.sound,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (target.present) {
      map['target'] = Variable<int>(target.value);
    }
    if (keepAwake.present) {
      map['keep_awake'] = Variable<bool>(keepAwake.value);
    }
    if (volumeKeys.present) {
      map['volume_keys'] = Variable<bool>(volumeKeys.value);
    }
    if (lock.present) {
      map['lock'] = Variable<bool>(lock.value);
    }
    if (haptics.present) {
      map['haptics'] = Variable<bool>(haptics.value);
    }
    if (sound.present) {
      map['sound'] = Variable<bool>(sound.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasbihStateTableCompanion(')
          ..write('id: $id, ')
          ..write('count: $count, ')
          ..write('target: $target, ')
          ..write('keepAwake: $keepAwake, ')
          ..write('volumeKeys: $volumeKeys, ')
          ..write('lock: $lock, ')
          ..write('haptics: $haptics, ')
          ..write('sound: $sound')
          ..write(')'))
        .toString();
  }
}

class $TasbihDaysTableTable extends TasbihDaysTable
    with TableInfo<$TasbihDaysTableTable, TasbihDaysTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasbihDaysTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [date, total];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasbih_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<TasbihDaysTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  TasbihDaysTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TasbihDaysTableData(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      )!,
    );
  }

  @override
  $TasbihDaysTableTable createAlias(String alias) {
    return $TasbihDaysTableTable(attachedDatabase, alias);
  }
}

class TasbihDaysTableData extends DataClass
    implements Insertable<TasbihDaysTableData> {
  /// Local date `YYYY-MM-DD`.
  final String date;
  final int total;
  const TasbihDaysTableData({required this.date, required this.total});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['total'] = Variable<int>(total);
    return map;
  }

  TasbihDaysTableCompanion toCompanion(bool nullToAbsent) {
    return TasbihDaysTableCompanion(date: Value(date), total: Value(total));
  }

  factory TasbihDaysTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TasbihDaysTableData(
      date: serializer.fromJson<String>(json['date']),
      total: serializer.fromJson<int>(json['total']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'total': serializer.toJson<int>(total),
    };
  }

  TasbihDaysTableData copyWith({String? date, int? total}) =>
      TasbihDaysTableData(date: date ?? this.date, total: total ?? this.total);
  TasbihDaysTableData copyWithCompanion(TasbihDaysTableCompanion data) {
    return TasbihDaysTableData(
      date: data.date.present ? data.date.value : this.date,
      total: data.total.present ? data.total.value : this.total,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TasbihDaysTableData(')
          ..write('date: $date, ')
          ..write('total: $total')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, total);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TasbihDaysTableData &&
          other.date == this.date &&
          other.total == this.total);
}

class TasbihDaysTableCompanion extends UpdateCompanion<TasbihDaysTableData> {
  final Value<String> date;
  final Value<int> total;
  final Value<int> rowid;
  const TasbihDaysTableCompanion({
    this.date = const Value.absent(),
    this.total = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasbihDaysTableCompanion.insert({
    required String date,
    this.total = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date);
  static Insertable<TasbihDaysTableData> custom({
    Expression<String>? date,
    Expression<int>? total,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (total != null) 'total': total,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasbihDaysTableCompanion copyWith({
    Value<String>? date,
    Value<int>? total,
    Value<int>? rowid,
  }) {
    return TasbihDaysTableCompanion(
      date: date ?? this.date,
      total: total ?? this.total,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasbihDaysTableCompanion(')
          ..write('date: $date, ')
          ..write('total: $total, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdhkarProgressTableTable extends AdhkarProgressTable
    with TableInfo<$AdhkarProgressTableTable, AdhkarProgressTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdhkarProgressTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
    'collection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedCountMeta = const VerificationMeta(
    'completedCount',
  );
  @override
  late final GeneratedColumn<int> completedCount = GeneratedColumn<int>(
    'completed_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startedAtMsMeta = const VerificationMeta(
    'startedAtMs',
  );
  @override
  late final GeneratedColumn<int> startedAtMs = GeneratedColumn<int>(
    'started_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMsMeta = const VerificationMeta(
    'finishedAtMs',
  );
  @override
  late final GeneratedColumn<int> finishedAtMs = GeneratedColumn<int>(
    'finished_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    collectionId,
    entryId,
    completedCount,
    startedAtMs,
    finishedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'adhkar_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdhkarProgressTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('completed_count')) {
      context.handle(
        _completedCountMeta,
        completedCount.isAcceptableOrUnknown(
          data['completed_count']!,
          _completedCountMeta,
        ),
      );
    }
    if (data.containsKey('started_at_ms')) {
      context.handle(
        _startedAtMsMeta,
        startedAtMs.isAcceptableOrUnknown(
          data['started_at_ms']!,
          _startedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedAtMsMeta);
    }
    if (data.containsKey('finished_at_ms')) {
      context.handle(
        _finishedAtMsMeta,
        finishedAtMs.isAcceptableOrUnknown(
          data['finished_at_ms']!,
          _finishedAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, entryId};
  @override
  AdhkarProgressTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdhkarProgressTableData(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      completedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_count'],
      )!,
      startedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at_ms'],
      )!,
      finishedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}finished_at_ms'],
      ),
    );
  }

  @override
  $AdhkarProgressTableTable createAlias(String alias) {
    return $AdhkarProgressTableTable(attachedDatabase, alias);
  }
}

class AdhkarProgressTableData extends DataClass
    implements Insertable<AdhkarProgressTableData> {
  final String sessionId;
  final String collectionId;
  final String entryId;
  final int completedCount;
  final int startedAtMs;
  final int? finishedAtMs;
  const AdhkarProgressTableData({
    required this.sessionId,
    required this.collectionId,
    required this.entryId,
    required this.completedCount,
    required this.startedAtMs,
    this.finishedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['collection_id'] = Variable<String>(collectionId);
    map['entry_id'] = Variable<String>(entryId);
    map['completed_count'] = Variable<int>(completedCount);
    map['started_at_ms'] = Variable<int>(startedAtMs);
    if (!nullToAbsent || finishedAtMs != null) {
      map['finished_at_ms'] = Variable<int>(finishedAtMs);
    }
    return map;
  }

  AdhkarProgressTableCompanion toCompanion(bool nullToAbsent) {
    return AdhkarProgressTableCompanion(
      sessionId: Value(sessionId),
      collectionId: Value(collectionId),
      entryId: Value(entryId),
      completedCount: Value(completedCount),
      startedAtMs: Value(startedAtMs),
      finishedAtMs: finishedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAtMs),
    );
  }

  factory AdhkarProgressTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdhkarProgressTableData(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      collectionId: serializer.fromJson<String>(json['collectionId']),
      entryId: serializer.fromJson<String>(json['entryId']),
      completedCount: serializer.fromJson<int>(json['completedCount']),
      startedAtMs: serializer.fromJson<int>(json['startedAtMs']),
      finishedAtMs: serializer.fromJson<int?>(json['finishedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'collectionId': serializer.toJson<String>(collectionId),
      'entryId': serializer.toJson<String>(entryId),
      'completedCount': serializer.toJson<int>(completedCount),
      'startedAtMs': serializer.toJson<int>(startedAtMs),
      'finishedAtMs': serializer.toJson<int?>(finishedAtMs),
    };
  }

  AdhkarProgressTableData copyWith({
    String? sessionId,
    String? collectionId,
    String? entryId,
    int? completedCount,
    int? startedAtMs,
    Value<int?> finishedAtMs = const Value.absent(),
  }) => AdhkarProgressTableData(
    sessionId: sessionId ?? this.sessionId,
    collectionId: collectionId ?? this.collectionId,
    entryId: entryId ?? this.entryId,
    completedCount: completedCount ?? this.completedCount,
    startedAtMs: startedAtMs ?? this.startedAtMs,
    finishedAtMs: finishedAtMs.present ? finishedAtMs.value : this.finishedAtMs,
  );
  AdhkarProgressTableData copyWithCompanion(AdhkarProgressTableCompanion data) {
    return AdhkarProgressTableData(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      completedCount: data.completedCount.present
          ? data.completedCount.value
          : this.completedCount,
      startedAtMs: data.startedAtMs.present
          ? data.startedAtMs.value
          : this.startedAtMs,
      finishedAtMs: data.finishedAtMs.present
          ? data.finishedAtMs.value
          : this.finishedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdhkarProgressTableData(')
          ..write('sessionId: $sessionId, ')
          ..write('collectionId: $collectionId, ')
          ..write('entryId: $entryId, ')
          ..write('completedCount: $completedCount, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('finishedAtMs: $finishedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    collectionId,
    entryId,
    completedCount,
    startedAtMs,
    finishedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdhkarProgressTableData &&
          other.sessionId == this.sessionId &&
          other.collectionId == this.collectionId &&
          other.entryId == this.entryId &&
          other.completedCount == this.completedCount &&
          other.startedAtMs == this.startedAtMs &&
          other.finishedAtMs == this.finishedAtMs);
}

class AdhkarProgressTableCompanion
    extends UpdateCompanion<AdhkarProgressTableData> {
  final Value<String> sessionId;
  final Value<String> collectionId;
  final Value<String> entryId;
  final Value<int> completedCount;
  final Value<int> startedAtMs;
  final Value<int?> finishedAtMs;
  final Value<int> rowid;
  const AdhkarProgressTableCompanion({
    this.sessionId = const Value.absent(),
    this.collectionId = const Value.absent(),
    this.entryId = const Value.absent(),
    this.completedCount = const Value.absent(),
    this.startedAtMs = const Value.absent(),
    this.finishedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdhkarProgressTableCompanion.insert({
    required String sessionId,
    required String collectionId,
    required String entryId,
    this.completedCount = const Value.absent(),
    required int startedAtMs,
    this.finishedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       collectionId = Value(collectionId),
       entryId = Value(entryId),
       startedAtMs = Value(startedAtMs);
  static Insertable<AdhkarProgressTableData> custom({
    Expression<String>? sessionId,
    Expression<String>? collectionId,
    Expression<String>? entryId,
    Expression<int>? completedCount,
    Expression<int>? startedAtMs,
    Expression<int>? finishedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (collectionId != null) 'collection_id': collectionId,
      if (entryId != null) 'entry_id': entryId,
      if (completedCount != null) 'completed_count': completedCount,
      if (startedAtMs != null) 'started_at_ms': startedAtMs,
      if (finishedAtMs != null) 'finished_at_ms': finishedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdhkarProgressTableCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? collectionId,
    Value<String>? entryId,
    Value<int>? completedCount,
    Value<int>? startedAtMs,
    Value<int?>? finishedAtMs,
    Value<int>? rowid,
  }) {
    return AdhkarProgressTableCompanion(
      sessionId: sessionId ?? this.sessionId,
      collectionId: collectionId ?? this.collectionId,
      entryId: entryId ?? this.entryId,
      completedCount: completedCount ?? this.completedCount,
      startedAtMs: startedAtMs ?? this.startedAtMs,
      finishedAtMs: finishedAtMs ?? this.finishedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (completedCount.present) {
      map['completed_count'] = Variable<int>(completedCount.value);
    }
    if (startedAtMs.present) {
      map['started_at_ms'] = Variable<int>(startedAtMs.value);
    }
    if (finishedAtMs.present) {
      map['finished_at_ms'] = Variable<int>(finishedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdhkarProgressTableCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('collectionId: $collectionId, ')
          ..write('entryId: $entryId, ')
          ..write('completedCount: $completedCount, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('finishedAtMs: $finishedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdhkarBookmarkTableTable extends AdhkarBookmarkTable
    with TableInfo<$AdhkarBookmarkTableTable, AdhkarBookmarkTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdhkarBookmarkTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [entryId, createdAtMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'adhkar_bookmark';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdhkarBookmarkTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId};
  @override
  AdhkarBookmarkTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdhkarBookmarkTableData(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
    );
  }

  @override
  $AdhkarBookmarkTableTable createAlias(String alias) {
    return $AdhkarBookmarkTableTable(attachedDatabase, alias);
  }
}

class AdhkarBookmarkTableData extends DataClass
    implements Insertable<AdhkarBookmarkTableData> {
  final String entryId;
  final int createdAtMs;
  const AdhkarBookmarkTableData({
    required this.entryId,
    required this.createdAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    return map;
  }

  AdhkarBookmarkTableCompanion toCompanion(bool nullToAbsent) {
    return AdhkarBookmarkTableCompanion(
      entryId: Value(entryId),
      createdAtMs: Value(createdAtMs),
    );
  }

  factory AdhkarBookmarkTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdhkarBookmarkTableData(
      entryId: serializer.fromJson<String>(json['entryId']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryId': serializer.toJson<String>(entryId),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
    };
  }

  AdhkarBookmarkTableData copyWith({String? entryId, int? createdAtMs}) =>
      AdhkarBookmarkTableData(
        entryId: entryId ?? this.entryId,
        createdAtMs: createdAtMs ?? this.createdAtMs,
      );
  AdhkarBookmarkTableData copyWithCompanion(AdhkarBookmarkTableCompanion data) {
    return AdhkarBookmarkTableData(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdhkarBookmarkTableData(')
          ..write('entryId: $entryId, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entryId, createdAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdhkarBookmarkTableData &&
          other.entryId == this.entryId &&
          other.createdAtMs == this.createdAtMs);
}

class AdhkarBookmarkTableCompanion
    extends UpdateCompanion<AdhkarBookmarkTableData> {
  final Value<String> entryId;
  final Value<int> createdAtMs;
  final Value<int> rowid;
  const AdhkarBookmarkTableCompanion({
    this.entryId = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdhkarBookmarkTableCompanion.insert({
    required String entryId,
    required int createdAtMs,
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       createdAtMs = Value(createdAtMs);
  static Insertable<AdhkarBookmarkTableData> custom({
    Expression<String>? entryId,
    Expression<int>? createdAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdhkarBookmarkTableCompanion copyWith({
    Value<String>? entryId,
    Value<int>? createdAtMs,
    Value<int>? rowid,
  }) {
    return AdhkarBookmarkTableCompanion(
      entryId: entryId ?? this.entryId,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdhkarBookmarkTableCompanion(')
          ..write('entryId: $entryId, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdhkarReminderTableTable extends AdhkarReminderTable
    with TableInfo<$AdhkarReminderTableTable, AdhkarReminderTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdhkarReminderTableTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<AdhkarReminderKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AdhkarReminderKind>(
        $AdhkarReminderTableTable.$converterkind,
      );
  @override
  late final GeneratedColumnWithTypeConverter<ReminderAnchor, String> anchor =
      GeneratedColumn<String>(
        'anchor',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ReminderAnchor>(
        $AdhkarReminderTableTable.$converteranchor,
      );
  static const VerificationMeta _offsetMinutesMeta = const VerificationMeta(
    'offsetMinutes',
  );
  @override
  late final GeneratedColumn<int> offsetMinutes = GeneratedColumn<int>(
    'offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [kind, anchor, offsetMinutes, enabled];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'adhkar_reminder';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdhkarReminderTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('offset_minutes')) {
      context.handle(
        _offsetMinutesMeta,
        offsetMinutes.isAcceptableOrUnknown(
          data['offset_minutes']!,
          _offsetMinutesMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind};
  @override
  AdhkarReminderTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdhkarReminderTableData(
      kind: $AdhkarReminderTableTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      anchor: $AdhkarReminderTableTable.$converteranchor.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}anchor'],
        )!,
      ),
      offsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_minutes'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $AdhkarReminderTableTable createAlias(String alias) {
    return $AdhkarReminderTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AdhkarReminderKind, String, String> $converterkind =
      const EnumNameConverter<AdhkarReminderKind>(AdhkarReminderKind.values);
  static JsonTypeConverter2<ReminderAnchor, String, String> $converteranchor =
      const EnumNameConverter<ReminderAnchor>(ReminderAnchor.values);
}

class AdhkarReminderTableData extends DataClass
    implements Insertable<AdhkarReminderTableData> {
  final AdhkarReminderKind kind;
  final ReminderAnchor anchor;

  /// Minutes after the anchor prayer (may be negative for "before").
  final int offsetMinutes;
  final bool enabled;
  const AdhkarReminderTableData({
    required this.kind,
    required this.anchor,
    required this.offsetMinutes,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['kind'] = Variable<String>(
        $AdhkarReminderTableTable.$converterkind.toSql(kind),
      );
    }
    {
      map['anchor'] = Variable<String>(
        $AdhkarReminderTableTable.$converteranchor.toSql(anchor),
      );
    }
    map['offset_minutes'] = Variable<int>(offsetMinutes);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  AdhkarReminderTableCompanion toCompanion(bool nullToAbsent) {
    return AdhkarReminderTableCompanion(
      kind: Value(kind),
      anchor: Value(anchor),
      offsetMinutes: Value(offsetMinutes),
      enabled: Value(enabled),
    );
  }

  factory AdhkarReminderTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdhkarReminderTableData(
      kind: $AdhkarReminderTableTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      anchor: $AdhkarReminderTableTable.$converteranchor.fromJson(
        serializer.fromJson<String>(json['anchor']),
      ),
      offsetMinutes: serializer.fromJson<int>(json['offsetMinutes']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(
        $AdhkarReminderTableTable.$converterkind.toJson(kind),
      ),
      'anchor': serializer.toJson<String>(
        $AdhkarReminderTableTable.$converteranchor.toJson(anchor),
      ),
      'offsetMinutes': serializer.toJson<int>(offsetMinutes),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  AdhkarReminderTableData copyWith({
    AdhkarReminderKind? kind,
    ReminderAnchor? anchor,
    int? offsetMinutes,
    bool? enabled,
  }) => AdhkarReminderTableData(
    kind: kind ?? this.kind,
    anchor: anchor ?? this.anchor,
    offsetMinutes: offsetMinutes ?? this.offsetMinutes,
    enabled: enabled ?? this.enabled,
  );
  AdhkarReminderTableData copyWithCompanion(AdhkarReminderTableCompanion data) {
    return AdhkarReminderTableData(
      kind: data.kind.present ? data.kind.value : this.kind,
      anchor: data.anchor.present ? data.anchor.value : this.anchor,
      offsetMinutes: data.offsetMinutes.present
          ? data.offsetMinutes.value
          : this.offsetMinutes,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdhkarReminderTableData(')
          ..write('kind: $kind, ')
          ..write('anchor: $anchor, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, anchor, offsetMinutes, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdhkarReminderTableData &&
          other.kind == this.kind &&
          other.anchor == this.anchor &&
          other.offsetMinutes == this.offsetMinutes &&
          other.enabled == this.enabled);
}

class AdhkarReminderTableCompanion
    extends UpdateCompanion<AdhkarReminderTableData> {
  final Value<AdhkarReminderKind> kind;
  final Value<ReminderAnchor> anchor;
  final Value<int> offsetMinutes;
  final Value<bool> enabled;
  final Value<int> rowid;
  const AdhkarReminderTableCompanion({
    this.kind = const Value.absent(),
    this.anchor = const Value.absent(),
    this.offsetMinutes = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdhkarReminderTableCompanion.insert({
    required AdhkarReminderKind kind,
    required ReminderAnchor anchor,
    this.offsetMinutes = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       anchor = Value(anchor);
  static Insertable<AdhkarReminderTableData> custom({
    Expression<String>? kind,
    Expression<String>? anchor,
    Expression<int>? offsetMinutes,
    Expression<bool>? enabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (anchor != null) 'anchor': anchor,
      if (offsetMinutes != null) 'offset_minutes': offsetMinutes,
      if (enabled != null) 'enabled': enabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdhkarReminderTableCompanion copyWith({
    Value<AdhkarReminderKind>? kind,
    Value<ReminderAnchor>? anchor,
    Value<int>? offsetMinutes,
    Value<bool>? enabled,
    Value<int>? rowid,
  }) {
    return AdhkarReminderTableCompanion(
      kind: kind ?? this.kind,
      anchor: anchor ?? this.anchor,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      enabled: enabled ?? this.enabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(
        $AdhkarReminderTableTable.$converterkind.toSql(kind.value),
      );
    }
    if (anchor.present) {
      map['anchor'] = Variable<String>(
        $AdhkarReminderTableTable.$converteranchor.toSql(anchor.value),
      );
    }
    if (offsetMinutes.present) {
      map['offset_minutes'] = Variable<int>(offsetMinutes.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdhkarReminderTableCompanion(')
          ..write('kind: $kind, ')
          ..write('anchor: $anchor, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('enabled: $enabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocationTableTable locationTable = $LocationTableTable(this);
  late final $PrayerSettingsTableTable prayerSettingsTable =
      $PrayerSettingsTableTable(this);
  late final $AlertPreferenceTableTable alertPreferenceTable =
      $AlertPreferenceTableTable(this);
  late final $GlobalSettingsTableTable globalSettingsTable =
      $GlobalSettingsTableTable(this);
  late final $AlertLogTableTable alertLogTable = $AlertLogTableTable(this);
  late final $TasbihStateTableTable tasbihStateTable = $TasbihStateTableTable(
    this,
  );
  late final $TasbihDaysTableTable tasbihDaysTable = $TasbihDaysTableTable(
    this,
  );
  late final $AdhkarProgressTableTable adhkarProgressTable =
      $AdhkarProgressTableTable(this);
  late final $AdhkarBookmarkTableTable adhkarBookmarkTable =
      $AdhkarBookmarkTableTable(this);
  late final $AdhkarReminderTableTable adhkarReminderTable =
      $AdhkarReminderTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    locationTable,
    prayerSettingsTable,
    alertPreferenceTable,
    globalSettingsTable,
    alertLogTable,
    tasbihStateTable,
    tasbihDaysTable,
    adhkarProgressTable,
    adhkarBookmarkTable,
    adhkarReminderTable,
  ];
}

typedef $$LocationTableTableCreateCompanionBuilder =
    LocationTableCompanion Function({
      Value<int> id,
      required LocationSource source,
      required double latitude,
      required double longitude,
      Value<int?> cityId,
      required String displayName,
      required String timeZoneId,
      required String countryCode,
      required int updatedAtMs,
    });
typedef $$LocationTableTableUpdateCompanionBuilder =
    LocationTableCompanion Function({
      Value<int> id,
      Value<LocationSource> source,
      Value<double> latitude,
      Value<double> longitude,
      Value<int?> cityId,
      Value<String> displayName,
      Value<String> timeZoneId,
      Value<String> countryCode,
      Value<int> updatedAtMs,
    });

class $$LocationTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocationTableTable> {
  $$LocationTableTableFilterComposer({
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

  ColumnWithTypeConverterFilters<LocationSource, LocationSource, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cityId => $composableBuilder(
    column: $table.cityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocationTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocationTableTable> {
  $$LocationTableTableOrderingComposer({
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

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cityId => $composableBuilder(
    column: $table.cityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocationTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocationTableTable> {
  $$LocationTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocationSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<int> get cityId =>
      $composableBuilder(column: $table.cityId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );
}

class $$LocationTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocationTableTable,
          LocationTableData,
          $$LocationTableTableFilterComposer,
          $$LocationTableTableOrderingComposer,
          $$LocationTableTableAnnotationComposer,
          $$LocationTableTableCreateCompanionBuilder,
          $$LocationTableTableUpdateCompanionBuilder,
          (
            LocationTableData,
            BaseReferences<
              _$AppDatabase,
              $LocationTableTable,
              LocationTableData
            >,
          ),
          LocationTableData,
          PrefetchHooks Function()
        > {
  $$LocationTableTableTableManager(_$AppDatabase db, $LocationTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocationTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocationTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocationTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<LocationSource> source = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<int?> cityId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> timeZoneId = const Value.absent(),
                Value<String> countryCode = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
              }) => LocationTableCompanion(
                id: id,
                source: source,
                latitude: latitude,
                longitude: longitude,
                cityId: cityId,
                displayName: displayName,
                timeZoneId: timeZoneId,
                countryCode: countryCode,
                updatedAtMs: updatedAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required LocationSource source,
                required double latitude,
                required double longitude,
                Value<int?> cityId = const Value.absent(),
                required String displayName,
                required String timeZoneId,
                required String countryCode,
                required int updatedAtMs,
              }) => LocationTableCompanion.insert(
                id: id,
                source: source,
                latitude: latitude,
                longitude: longitude,
                cityId: cityId,
                displayName: displayName,
                timeZoneId: timeZoneId,
                countryCode: countryCode,
                updatedAtMs: updatedAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocationTableTable, LocationTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocationTableTable,
                    LocationTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocationTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocationTableTable,
      LocationTableData,
      $$LocationTableTableFilterComposer,
      $$LocationTableTableOrderingComposer,
      $$LocationTableTableAnnotationComposer,
      $$LocationTableTableCreateCompanionBuilder,
      $$LocationTableTableUpdateCompanionBuilder,
      (
        LocationTableData,
        BaseReferences<_$AppDatabase, $LocationTableTable, LocationTableData>,
      ),
      LocationTableData,
      PrefetchHooks Function()
    >;
typedef $$PrayerSettingsTableTableCreateCompanionBuilder =
    PrayerSettingsTableCompanion Function({
      Value<int> id,
      required engine.CalculationMethod method,
      required engine.AsrMethod asrMethod,
      required engine.HighLatitudeRule highLatitudeRule,
      Value<int> offsetFajr,
      Value<int> offsetSunrise,
      Value<int> offsetDhuhr,
      Value<int> offsetAsr,
      Value<int> offsetMaghrib,
      Value<int> offsetIsha,
      Value<int> imsakMinutes,
      Value<int> hijriAdjustment,
      Value<String> suggestionDismissedRegions,
      required AppLanguage language,
      Value<ThemePreference> theme,
      Value<double> textScale,
      Value<bool> highContrast,
    });
typedef $$PrayerSettingsTableTableUpdateCompanionBuilder =
    PrayerSettingsTableCompanion Function({
      Value<int> id,
      Value<engine.CalculationMethod> method,
      Value<engine.AsrMethod> asrMethod,
      Value<engine.HighLatitudeRule> highLatitudeRule,
      Value<int> offsetFajr,
      Value<int> offsetSunrise,
      Value<int> offsetDhuhr,
      Value<int> offsetAsr,
      Value<int> offsetMaghrib,
      Value<int> offsetIsha,
      Value<int> imsakMinutes,
      Value<int> hijriAdjustment,
      Value<String> suggestionDismissedRegions,
      Value<AppLanguage> language,
      Value<ThemePreference> theme,
      Value<double> textScale,
      Value<bool> highContrast,
    });

class $$PrayerSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PrayerSettingsTableTable> {
  $$PrayerSettingsTableTableFilterComposer({
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

  ColumnWithTypeConverterFilters<
    engine.CalculationMethod,
    engine.CalculationMethod,
    String
  >
  get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<engine.AsrMethod, engine.AsrMethod, String>
  get asrMethod => $composableBuilder(
    column: $table.asrMethod,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    engine.HighLatitudeRule,
    engine.HighLatitudeRule,
    String
  >
  get highLatitudeRule => $composableBuilder(
    column: $table.highLatitudeRule,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get offsetFajr => $composableBuilder(
    column: $table.offsetFajr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetSunrise => $composableBuilder(
    column: $table.offsetSunrise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetDhuhr => $composableBuilder(
    column: $table.offsetDhuhr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetAsr => $composableBuilder(
    column: $table.offsetAsr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetMaghrib => $composableBuilder(
    column: $table.offsetMaghrib,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetIsha => $composableBuilder(
    column: $table.offsetIsha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get imsakMinutes => $composableBuilder(
    column: $table.imsakMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hijriAdjustment => $composableBuilder(
    column: $table.hijriAdjustment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get suggestionDismissedRegions => $composableBuilder(
    column: $table.suggestionDismissedRegions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AppLanguage, AppLanguage, String>
  get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<ThemePreference, ThemePreference, String>
  get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get textScale => $composableBuilder(
    column: $table.textScale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get highContrast => $composableBuilder(
    column: $table.highContrast,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrayerSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PrayerSettingsTableTable> {
  $$PrayerSettingsTableTableOrderingComposer({
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

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get asrMethod => $composableBuilder(
    column: $table.asrMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get highLatitudeRule => $composableBuilder(
    column: $table.highLatitudeRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetFajr => $composableBuilder(
    column: $table.offsetFajr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetSunrise => $composableBuilder(
    column: $table.offsetSunrise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetDhuhr => $composableBuilder(
    column: $table.offsetDhuhr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetAsr => $composableBuilder(
    column: $table.offsetAsr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetMaghrib => $composableBuilder(
    column: $table.offsetMaghrib,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetIsha => $composableBuilder(
    column: $table.offsetIsha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get imsakMinutes => $composableBuilder(
    column: $table.imsakMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hijriAdjustment => $composableBuilder(
    column: $table.hijriAdjustment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get suggestionDismissedRegions => $composableBuilder(
    column: $table.suggestionDismissedRegions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get textScale => $composableBuilder(
    column: $table.textScale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get highContrast => $composableBuilder(
    column: $table.highContrast,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrayerSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrayerSettingsTableTable> {
  $$PrayerSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<engine.CalculationMethod, String>
  get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumnWithTypeConverter<engine.AsrMethod, String> get asrMethod =>
      $composableBuilder(column: $table.asrMethod, builder: (column) => column);

  GeneratedColumnWithTypeConverter<engine.HighLatitudeRule, String>
  get highLatitudeRule => $composableBuilder(
    column: $table.highLatitudeRule,
    builder: (column) => column,
  );

  GeneratedColumn<int> get offsetFajr => $composableBuilder(
    column: $table.offsetFajr,
    builder: (column) => column,
  );

  GeneratedColumn<int> get offsetSunrise => $composableBuilder(
    column: $table.offsetSunrise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get offsetDhuhr => $composableBuilder(
    column: $table.offsetDhuhr,
    builder: (column) => column,
  );

  GeneratedColumn<int> get offsetAsr =>
      $composableBuilder(column: $table.offsetAsr, builder: (column) => column);

  GeneratedColumn<int> get offsetMaghrib => $composableBuilder(
    column: $table.offsetMaghrib,
    builder: (column) => column,
  );

  GeneratedColumn<int> get offsetIsha => $composableBuilder(
    column: $table.offsetIsha,
    builder: (column) => column,
  );

  GeneratedColumn<int> get imsakMinutes => $composableBuilder(
    column: $table.imsakMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hijriAdjustment => $composableBuilder(
    column: $table.hijriAdjustment,
    builder: (column) => column,
  );

  GeneratedColumn<String> get suggestionDismissedRegions => $composableBuilder(
    column: $table.suggestionDismissedRegions,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<AppLanguage, String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ThemePreference, String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<double> get textScale =>
      $composableBuilder(column: $table.textScale, builder: (column) => column);

  GeneratedColumn<bool> get highContrast => $composableBuilder(
    column: $table.highContrast,
    builder: (column) => column,
  );
}

class $$PrayerSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrayerSettingsTableTable,
          PrayerSettingsTableData,
          $$PrayerSettingsTableTableFilterComposer,
          $$PrayerSettingsTableTableOrderingComposer,
          $$PrayerSettingsTableTableAnnotationComposer,
          $$PrayerSettingsTableTableCreateCompanionBuilder,
          $$PrayerSettingsTableTableUpdateCompanionBuilder,
          (
            PrayerSettingsTableData,
            BaseReferences<
              _$AppDatabase,
              $PrayerSettingsTableTable,
              PrayerSettingsTableData
            >,
          ),
          PrayerSettingsTableData,
          PrefetchHooks Function()
        > {
  $$PrayerSettingsTableTableTableManager(
    _$AppDatabase db,
    $PrayerSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrayerSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrayerSettingsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PrayerSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<engine.CalculationMethod> method = const Value.absent(),
                Value<engine.AsrMethod> asrMethod = const Value.absent(),
                Value<engine.HighLatitudeRule> highLatitudeRule =
                    const Value.absent(),
                Value<int> offsetFajr = const Value.absent(),
                Value<int> offsetSunrise = const Value.absent(),
                Value<int> offsetDhuhr = const Value.absent(),
                Value<int> offsetAsr = const Value.absent(),
                Value<int> offsetMaghrib = const Value.absent(),
                Value<int> offsetIsha = const Value.absent(),
                Value<int> imsakMinutes = const Value.absent(),
                Value<int> hijriAdjustment = const Value.absent(),
                Value<String> suggestionDismissedRegions = const Value.absent(),
                Value<AppLanguage> language = const Value.absent(),
                Value<ThemePreference> theme = const Value.absent(),
                Value<double> textScale = const Value.absent(),
                Value<bool> highContrast = const Value.absent(),
              }) => PrayerSettingsTableCompanion(
                id: id,
                method: method,
                asrMethod: asrMethod,
                highLatitudeRule: highLatitudeRule,
                offsetFajr: offsetFajr,
                offsetSunrise: offsetSunrise,
                offsetDhuhr: offsetDhuhr,
                offsetAsr: offsetAsr,
                offsetMaghrib: offsetMaghrib,
                offsetIsha: offsetIsha,
                imsakMinutes: imsakMinutes,
                hijriAdjustment: hijriAdjustment,
                suggestionDismissedRegions: suggestionDismissedRegions,
                language: language,
                theme: theme,
                textScale: textScale,
                highContrast: highContrast,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required engine.CalculationMethod method,
                required engine.AsrMethod asrMethod,
                required engine.HighLatitudeRule highLatitudeRule,
                Value<int> offsetFajr = const Value.absent(),
                Value<int> offsetSunrise = const Value.absent(),
                Value<int> offsetDhuhr = const Value.absent(),
                Value<int> offsetAsr = const Value.absent(),
                Value<int> offsetMaghrib = const Value.absent(),
                Value<int> offsetIsha = const Value.absent(),
                Value<int> imsakMinutes = const Value.absent(),
                Value<int> hijriAdjustment = const Value.absent(),
                Value<String> suggestionDismissedRegions = const Value.absent(),
                required AppLanguage language,
                Value<ThemePreference> theme = const Value.absent(),
                Value<double> textScale = const Value.absent(),
                Value<bool> highContrast = const Value.absent(),
              }) => PrayerSettingsTableCompanion.insert(
                id: id,
                method: method,
                asrMethod: asrMethod,
                highLatitudeRule: highLatitudeRule,
                offsetFajr: offsetFajr,
                offsetSunrise: offsetSunrise,
                offsetDhuhr: offsetDhuhr,
                offsetAsr: offsetAsr,
                offsetMaghrib: offsetMaghrib,
                offsetIsha: offsetIsha,
                imsakMinutes: imsakMinutes,
                hijriAdjustment: hijriAdjustment,
                suggestionDismissedRegions: suggestionDismissedRegions,
                language: language,
                theme: theme,
                textScale: textScale,
                highContrast: highContrast,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $PrayerSettingsTableTable,
                    PrayerSettingsTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PrayerSettingsTableTable,
                    PrayerSettingsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrayerSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrayerSettingsTableTable,
      PrayerSettingsTableData,
      $$PrayerSettingsTableTableFilterComposer,
      $$PrayerSettingsTableTableOrderingComposer,
      $$PrayerSettingsTableTableAnnotationComposer,
      $$PrayerSettingsTableTableCreateCompanionBuilder,
      $$PrayerSettingsTableTableUpdateCompanionBuilder,
      (
        PrayerSettingsTableData,
        BaseReferences<
          _$AppDatabase,
          $PrayerSettingsTableTable,
          PrayerSettingsTableData
        >,
      ),
      PrayerSettingsTableData,
      PrefetchHooks Function()
    >;
typedef $$AlertPreferenceTableTableCreateCompanionBuilder =
    AlertPreferenceTableCompanion Function({
      required AlertPrayer prayer,
      Value<AlertType> type,
      Value<String> voiceId,
      Value<AzaanVariant> variant,
      Value<bool> loudMode,
      Value<VolumeChoice> volumeChoice,
      Value<int?> preReminderMinutes,
      Value<bool> ignoreQuietHours,
      Value<int> rowid,
    });
typedef $$AlertPreferenceTableTableUpdateCompanionBuilder =
    AlertPreferenceTableCompanion Function({
      Value<AlertPrayer> prayer,
      Value<AlertType> type,
      Value<String> voiceId,
      Value<AzaanVariant> variant,
      Value<bool> loudMode,
      Value<VolumeChoice> volumeChoice,
      Value<int?> preReminderMinutes,
      Value<bool> ignoreQuietHours,
      Value<int> rowid,
    });

class $$AlertPreferenceTableTableFilterComposer
    extends Composer<_$AppDatabase, $AlertPreferenceTableTable> {
  $$AlertPreferenceTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<AlertPrayer, AlertPrayer, String> get prayer =>
      $composableBuilder(
        column: $table.prayer,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<AlertType, AlertType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get voiceId => $composableBuilder(
    column: $table.voiceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AzaanVariant, AzaanVariant, String>
  get variant => $composableBuilder(
    column: $table.variant,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get loudMode => $composableBuilder(
    column: $table.loudMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<VolumeChoice, VolumeChoice, String>
  get volumeChoice => $composableBuilder(
    column: $table.volumeChoice,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get preReminderMinutes => $composableBuilder(
    column: $table.preReminderMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ignoreQuietHours => $composableBuilder(
    column: $table.ignoreQuietHours,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlertPreferenceTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AlertPreferenceTableTable> {
  $$AlertPreferenceTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get prayer => $composableBuilder(
    column: $table.prayer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voiceId => $composableBuilder(
    column: $table.voiceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variant => $composableBuilder(
    column: $table.variant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get loudMode => $composableBuilder(
    column: $table.loudMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get volumeChoice => $composableBuilder(
    column: $table.volumeChoice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get preReminderMinutes => $composableBuilder(
    column: $table.preReminderMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ignoreQuietHours => $composableBuilder(
    column: $table.ignoreQuietHours,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlertPreferenceTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlertPreferenceTableTable> {
  $$AlertPreferenceTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<AlertPrayer, String> get prayer =>
      $composableBuilder(column: $table.prayer, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AlertType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get voiceId =>
      $composableBuilder(column: $table.voiceId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AzaanVariant, String> get variant =>
      $composableBuilder(column: $table.variant, builder: (column) => column);

  GeneratedColumn<bool> get loudMode =>
      $composableBuilder(column: $table.loudMode, builder: (column) => column);

  GeneratedColumnWithTypeConverter<VolumeChoice, String> get volumeChoice =>
      $composableBuilder(
        column: $table.volumeChoice,
        builder: (column) => column,
      );

  GeneratedColumn<int> get preReminderMinutes => $composableBuilder(
    column: $table.preReminderMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get ignoreQuietHours => $composableBuilder(
    column: $table.ignoreQuietHours,
    builder: (column) => column,
  );
}

class $$AlertPreferenceTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlertPreferenceTableTable,
          AlertPreferenceTableData,
          $$AlertPreferenceTableTableFilterComposer,
          $$AlertPreferenceTableTableOrderingComposer,
          $$AlertPreferenceTableTableAnnotationComposer,
          $$AlertPreferenceTableTableCreateCompanionBuilder,
          $$AlertPreferenceTableTableUpdateCompanionBuilder,
          (
            AlertPreferenceTableData,
            BaseReferences<
              _$AppDatabase,
              $AlertPreferenceTableTable,
              AlertPreferenceTableData
            >,
          ),
          AlertPreferenceTableData,
          PrefetchHooks Function()
        > {
  $$AlertPreferenceTableTableTableManager(
    _$AppDatabase db,
    $AlertPreferenceTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlertPreferenceTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlertPreferenceTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AlertPreferenceTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<AlertPrayer> prayer = const Value.absent(),
                Value<AlertType> type = const Value.absent(),
                Value<String> voiceId = const Value.absent(),
                Value<AzaanVariant> variant = const Value.absent(),
                Value<bool> loudMode = const Value.absent(),
                Value<VolumeChoice> volumeChoice = const Value.absent(),
                Value<int?> preReminderMinutes = const Value.absent(),
                Value<bool> ignoreQuietHours = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertPreferenceTableCompanion(
                prayer: prayer,
                type: type,
                voiceId: voiceId,
                variant: variant,
                loudMode: loudMode,
                volumeChoice: volumeChoice,
                preReminderMinutes: preReminderMinutes,
                ignoreQuietHours: ignoreQuietHours,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required AlertPrayer prayer,
                Value<AlertType> type = const Value.absent(),
                Value<String> voiceId = const Value.absent(),
                Value<AzaanVariant> variant = const Value.absent(),
                Value<bool> loudMode = const Value.absent(),
                Value<VolumeChoice> volumeChoice = const Value.absent(),
                Value<int?> preReminderMinutes = const Value.absent(),
                Value<bool> ignoreQuietHours = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertPreferenceTableCompanion.insert(
                prayer: prayer,
                type: type,
                voiceId: voiceId,
                variant: variant,
                loudMode: loudMode,
                volumeChoice: volumeChoice,
                preReminderMinutes: preReminderMinutes,
                ignoreQuietHours: ignoreQuietHours,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $AlertPreferenceTableTable,
                    AlertPreferenceTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AlertPreferenceTableTable,
                    AlertPreferenceTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlertPreferenceTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlertPreferenceTableTable,
      AlertPreferenceTableData,
      $$AlertPreferenceTableTableFilterComposer,
      $$AlertPreferenceTableTableOrderingComposer,
      $$AlertPreferenceTableTableAnnotationComposer,
      $$AlertPreferenceTableTableCreateCompanionBuilder,
      $$AlertPreferenceTableTableUpdateCompanionBuilder,
      (
        AlertPreferenceTableData,
        BaseReferences<
          _$AppDatabase,
          $AlertPreferenceTableTable,
          AlertPreferenceTableData
        >,
      ),
      AlertPreferenceTableData,
      PrefetchHooks Function()
    >;
typedef $$GlobalSettingsTableTableCreateCompanionBuilder =
    GlobalSettingsTableCompanion Function({
      Value<int> id,
      Value<AudioOutput> audioOutput,
      Value<int?> quietHoursStartMinutes,
      Value<int?> quietHoursEndMinutes,
      Value<bool> suhoorReminderEnabled,
      Value<int> suhoorReminderMinutes,
      Value<PermissionState> exactAlarmState,
      Value<PermissionState> notificationPermissionState,
      Value<bool> silentSwitchExplained,
      Value<bool> setupCompleted,
      Value<int?> clockWallMs,
      Value<int?> clockMonotonicMs,
      Value<String?> clockBootId,
      Value<int?> scheduleRunsUntilMs,
    });
typedef $$GlobalSettingsTableTableUpdateCompanionBuilder =
    GlobalSettingsTableCompanion Function({
      Value<int> id,
      Value<AudioOutput> audioOutput,
      Value<int?> quietHoursStartMinutes,
      Value<int?> quietHoursEndMinutes,
      Value<bool> suhoorReminderEnabled,
      Value<int> suhoorReminderMinutes,
      Value<PermissionState> exactAlarmState,
      Value<PermissionState> notificationPermissionState,
      Value<bool> silentSwitchExplained,
      Value<bool> setupCompleted,
      Value<int?> clockWallMs,
      Value<int?> clockMonotonicMs,
      Value<String?> clockBootId,
      Value<int?> scheduleRunsUntilMs,
    });

class $$GlobalSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $GlobalSettingsTableTable> {
  $$GlobalSettingsTableTableFilterComposer({
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

  ColumnWithTypeConverterFilters<AudioOutput, AudioOutput, String>
  get audioOutput => $composableBuilder(
    column: $table.audioOutput,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get quietHoursStartMinutes => $composableBuilder(
    column: $table.quietHoursStartMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quietHoursEndMinutes => $composableBuilder(
    column: $table.quietHoursEndMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get suhoorReminderEnabled => $composableBuilder(
    column: $table.suhoorReminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get suhoorReminderMinutes => $composableBuilder(
    column: $table.suhoorReminderMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PermissionState, PermissionState, String>
  get exactAlarmState => $composableBuilder(
    column: $table.exactAlarmState,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<PermissionState, PermissionState, String>
  get notificationPermissionState => $composableBuilder(
    column: $table.notificationPermissionState,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get silentSwitchExplained => $composableBuilder(
    column: $table.silentSwitchExplained,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get setupCompleted => $composableBuilder(
    column: $table.setupCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clockWallMs => $composableBuilder(
    column: $table.clockWallMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clockMonotonicMs => $composableBuilder(
    column: $table.clockMonotonicMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clockBootId => $composableBuilder(
    column: $table.clockBootId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scheduleRunsUntilMs => $composableBuilder(
    column: $table.scheduleRunsUntilMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GlobalSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GlobalSettingsTableTable> {
  $$GlobalSettingsTableTableOrderingComposer({
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

  ColumnOrderings<String> get audioOutput => $composableBuilder(
    column: $table.audioOutput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quietHoursStartMinutes => $composableBuilder(
    column: $table.quietHoursStartMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quietHoursEndMinutes => $composableBuilder(
    column: $table.quietHoursEndMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get suhoorReminderEnabled => $composableBuilder(
    column: $table.suhoorReminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get suhoorReminderMinutes => $composableBuilder(
    column: $table.suhoorReminderMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exactAlarmState => $composableBuilder(
    column: $table.exactAlarmState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notificationPermissionState => $composableBuilder(
    column: $table.notificationPermissionState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get silentSwitchExplained => $composableBuilder(
    column: $table.silentSwitchExplained,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get setupCompleted => $composableBuilder(
    column: $table.setupCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clockWallMs => $composableBuilder(
    column: $table.clockWallMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clockMonotonicMs => $composableBuilder(
    column: $table.clockMonotonicMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clockBootId => $composableBuilder(
    column: $table.clockBootId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scheduleRunsUntilMs => $composableBuilder(
    column: $table.scheduleRunsUntilMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GlobalSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GlobalSettingsTableTable> {
  $$GlobalSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AudioOutput, String> get audioOutput =>
      $composableBuilder(
        column: $table.audioOutput,
        builder: (column) => column,
      );

  GeneratedColumn<int> get quietHoursStartMinutes => $composableBuilder(
    column: $table.quietHoursStartMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quietHoursEndMinutes => $composableBuilder(
    column: $table.quietHoursEndMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get suhoorReminderEnabled => $composableBuilder(
    column: $table.suhoorReminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get suhoorReminderMinutes => $composableBuilder(
    column: $table.suhoorReminderMinutes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PermissionState, String>
  get exactAlarmState => $composableBuilder(
    column: $table.exactAlarmState,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PermissionState, String>
  get notificationPermissionState => $composableBuilder(
    column: $table.notificationPermissionState,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get silentSwitchExplained => $composableBuilder(
    column: $table.silentSwitchExplained,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get setupCompleted => $composableBuilder(
    column: $table.setupCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get clockWallMs => $composableBuilder(
    column: $table.clockWallMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get clockMonotonicMs => $composableBuilder(
    column: $table.clockMonotonicMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clockBootId => $composableBuilder(
    column: $table.clockBootId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scheduleRunsUntilMs => $composableBuilder(
    column: $table.scheduleRunsUntilMs,
    builder: (column) => column,
  );
}

class $$GlobalSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GlobalSettingsTableTable,
          GlobalSettingsTableData,
          $$GlobalSettingsTableTableFilterComposer,
          $$GlobalSettingsTableTableOrderingComposer,
          $$GlobalSettingsTableTableAnnotationComposer,
          $$GlobalSettingsTableTableCreateCompanionBuilder,
          $$GlobalSettingsTableTableUpdateCompanionBuilder,
          (
            GlobalSettingsTableData,
            BaseReferences<
              _$AppDatabase,
              $GlobalSettingsTableTable,
              GlobalSettingsTableData
            >,
          ),
          GlobalSettingsTableData,
          PrefetchHooks Function()
        > {
  $$GlobalSettingsTableTableTableManager(
    _$AppDatabase db,
    $GlobalSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GlobalSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GlobalSettingsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$GlobalSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<AudioOutput> audioOutput = const Value.absent(),
                Value<int?> quietHoursStartMinutes = const Value.absent(),
                Value<int?> quietHoursEndMinutes = const Value.absent(),
                Value<bool> suhoorReminderEnabled = const Value.absent(),
                Value<int> suhoorReminderMinutes = const Value.absent(),
                Value<PermissionState> exactAlarmState = const Value.absent(),
                Value<PermissionState> notificationPermissionState =
                    const Value.absent(),
                Value<bool> silentSwitchExplained = const Value.absent(),
                Value<bool> setupCompleted = const Value.absent(),
                Value<int?> clockWallMs = const Value.absent(),
                Value<int?> clockMonotonicMs = const Value.absent(),
                Value<String?> clockBootId = const Value.absent(),
                Value<int?> scheduleRunsUntilMs = const Value.absent(),
              }) => GlobalSettingsTableCompanion(
                id: id,
                audioOutput: audioOutput,
                quietHoursStartMinutes: quietHoursStartMinutes,
                quietHoursEndMinutes: quietHoursEndMinutes,
                suhoorReminderEnabled: suhoorReminderEnabled,
                suhoorReminderMinutes: suhoorReminderMinutes,
                exactAlarmState: exactAlarmState,
                notificationPermissionState: notificationPermissionState,
                silentSwitchExplained: silentSwitchExplained,
                setupCompleted: setupCompleted,
                clockWallMs: clockWallMs,
                clockMonotonicMs: clockMonotonicMs,
                clockBootId: clockBootId,
                scheduleRunsUntilMs: scheduleRunsUntilMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<AudioOutput> audioOutput = const Value.absent(),
                Value<int?> quietHoursStartMinutes = const Value.absent(),
                Value<int?> quietHoursEndMinutes = const Value.absent(),
                Value<bool> suhoorReminderEnabled = const Value.absent(),
                Value<int> suhoorReminderMinutes = const Value.absent(),
                Value<PermissionState> exactAlarmState = const Value.absent(),
                Value<PermissionState> notificationPermissionState =
                    const Value.absent(),
                Value<bool> silentSwitchExplained = const Value.absent(),
                Value<bool> setupCompleted = const Value.absent(),
                Value<int?> clockWallMs = const Value.absent(),
                Value<int?> clockMonotonicMs = const Value.absent(),
                Value<String?> clockBootId = const Value.absent(),
                Value<int?> scheduleRunsUntilMs = const Value.absent(),
              }) => GlobalSettingsTableCompanion.insert(
                id: id,
                audioOutput: audioOutput,
                quietHoursStartMinutes: quietHoursStartMinutes,
                quietHoursEndMinutes: quietHoursEndMinutes,
                suhoorReminderEnabled: suhoorReminderEnabled,
                suhoorReminderMinutes: suhoorReminderMinutes,
                exactAlarmState: exactAlarmState,
                notificationPermissionState: notificationPermissionState,
                silentSwitchExplained: silentSwitchExplained,
                setupCompleted: setupCompleted,
                clockWallMs: clockWallMs,
                clockMonotonicMs: clockMonotonicMs,
                clockBootId: clockBootId,
                scheduleRunsUntilMs: scheduleRunsUntilMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $GlobalSettingsTableTable,
                    GlobalSettingsTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $GlobalSettingsTableTable,
                    GlobalSettingsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GlobalSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GlobalSettingsTableTable,
      GlobalSettingsTableData,
      $$GlobalSettingsTableTableFilterComposer,
      $$GlobalSettingsTableTableOrderingComposer,
      $$GlobalSettingsTableTableAnnotationComposer,
      $$GlobalSettingsTableTableCreateCompanionBuilder,
      $$GlobalSettingsTableTableUpdateCompanionBuilder,
      (
        GlobalSettingsTableData,
        BaseReferences<
          _$AppDatabase,
          $GlobalSettingsTableTable,
          GlobalSettingsTableData
        >,
      ),
      GlobalSettingsTableData,
      PrefetchHooks Function()
    >;
typedef $$AlertLogTableTableCreateCompanionBuilder =
    AlertLogTableCompanion Function({
      required String alertId,
      Value<int> attempt,
      required int plannedFireAtMs,
      required AlertLogState state,
      Value<int?> firedAtMs,
      Value<int?> deviationMs,
      Value<String?> cause,
      required AlertLogSource source,
      Value<int> rowid,
    });
typedef $$AlertLogTableTableUpdateCompanionBuilder =
    AlertLogTableCompanion Function({
      Value<String> alertId,
      Value<int> attempt,
      Value<int> plannedFireAtMs,
      Value<AlertLogState> state,
      Value<int?> firedAtMs,
      Value<int?> deviationMs,
      Value<String?> cause,
      Value<AlertLogSource> source,
      Value<int> rowid,
    });

class $$AlertLogTableTableFilterComposer
    extends Composer<_$AppDatabase, $AlertLogTableTable> {
  $$AlertLogTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get alertId => $composableBuilder(
    column: $table.alertId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempt => $composableBuilder(
    column: $table.attempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedFireAtMs => $composableBuilder(
    column: $table.plannedFireAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AlertLogState, AlertLogState, String>
  get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get firedAtMs => $composableBuilder(
    column: $table.firedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deviationMs => $composableBuilder(
    column: $table.deviationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cause => $composableBuilder(
    column: $table.cause,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AlertLogSource, AlertLogSource, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$AlertLogTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AlertLogTableTable> {
  $$AlertLogTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get alertId => $composableBuilder(
    column: $table.alertId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempt => $composableBuilder(
    column: $table.attempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedFireAtMs => $composableBuilder(
    column: $table.plannedFireAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firedAtMs => $composableBuilder(
    column: $table.firedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deviationMs => $composableBuilder(
    column: $table.deviationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cause => $composableBuilder(
    column: $table.cause,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlertLogTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlertLogTableTable> {
  $$AlertLogTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get alertId =>
      $composableBuilder(column: $table.alertId, builder: (column) => column);

  GeneratedColumn<int> get attempt =>
      $composableBuilder(column: $table.attempt, builder: (column) => column);

  GeneratedColumn<int> get plannedFireAtMs => $composableBuilder(
    column: $table.plannedFireAtMs,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<AlertLogState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get firedAtMs =>
      $composableBuilder(column: $table.firedAtMs, builder: (column) => column);

  GeneratedColumn<int> get deviationMs => $composableBuilder(
    column: $table.deviationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cause =>
      $composableBuilder(column: $table.cause, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AlertLogSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$AlertLogTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlertLogTableTable,
          AlertLogTableData,
          $$AlertLogTableTableFilterComposer,
          $$AlertLogTableTableOrderingComposer,
          $$AlertLogTableTableAnnotationComposer,
          $$AlertLogTableTableCreateCompanionBuilder,
          $$AlertLogTableTableUpdateCompanionBuilder,
          (
            AlertLogTableData,
            BaseReferences<
              _$AppDatabase,
              $AlertLogTableTable,
              AlertLogTableData
            >,
          ),
          AlertLogTableData,
          PrefetchHooks Function()
        > {
  $$AlertLogTableTableTableManager(_$AppDatabase db, $AlertLogTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlertLogTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlertLogTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlertLogTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> alertId = const Value.absent(),
                Value<int> attempt = const Value.absent(),
                Value<int> plannedFireAtMs = const Value.absent(),
                Value<AlertLogState> state = const Value.absent(),
                Value<int?> firedAtMs = const Value.absent(),
                Value<int?> deviationMs = const Value.absent(),
                Value<String?> cause = const Value.absent(),
                Value<AlertLogSource> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertLogTableCompanion(
                alertId: alertId,
                attempt: attempt,
                plannedFireAtMs: plannedFireAtMs,
                state: state,
                firedAtMs: firedAtMs,
                deviationMs: deviationMs,
                cause: cause,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String alertId,
                Value<int> attempt = const Value.absent(),
                required int plannedFireAtMs,
                required AlertLogState state,
                Value<int?> firedAtMs = const Value.absent(),
                Value<int?> deviationMs = const Value.absent(),
                Value<String?> cause = const Value.absent(),
                required AlertLogSource source,
                Value<int> rowid = const Value.absent(),
              }) => AlertLogTableCompanion.insert(
                alertId: alertId,
                attempt: attempt,
                plannedFireAtMs: plannedFireAtMs,
                state: state,
                firedAtMs: firedAtMs,
                deviationMs: deviationMs,
                cause: cause,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AlertLogTableTable, AlertLogTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AlertLogTableTable,
                    AlertLogTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlertLogTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlertLogTableTable,
      AlertLogTableData,
      $$AlertLogTableTableFilterComposer,
      $$AlertLogTableTableOrderingComposer,
      $$AlertLogTableTableAnnotationComposer,
      $$AlertLogTableTableCreateCompanionBuilder,
      $$AlertLogTableTableUpdateCompanionBuilder,
      (
        AlertLogTableData,
        BaseReferences<_$AppDatabase, $AlertLogTableTable, AlertLogTableData>,
      ),
      AlertLogTableData,
      PrefetchHooks Function()
    >;
typedef $$TasbihStateTableTableCreateCompanionBuilder =
    TasbihStateTableCompanion Function({
      Value<int> id,
      Value<int> count,
      Value<int> target,
      Value<bool> keepAwake,
      Value<bool> volumeKeys,
      Value<bool> lock,
      Value<bool> haptics,
      Value<bool> sound,
    });
typedef $$TasbihStateTableTableUpdateCompanionBuilder =
    TasbihStateTableCompanion Function({
      Value<int> id,
      Value<int> count,
      Value<int> target,
      Value<bool> keepAwake,
      Value<bool> volumeKeys,
      Value<bool> lock,
      Value<bool> haptics,
      Value<bool> sound,
    });

class $$TasbihStateTableTableFilterComposer
    extends Composer<_$AppDatabase, $TasbihStateTableTable> {
  $$TasbihStateTableTableFilterComposer({
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

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get keepAwake => $composableBuilder(
    column: $table.keepAwake,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get volumeKeys => $composableBuilder(
    column: $table.volumeKeys,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lock => $composableBuilder(
    column: $table.lock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get haptics => $composableBuilder(
    column: $table.haptics,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sound => $composableBuilder(
    column: $table.sound,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasbihStateTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TasbihStateTableTable> {
  $$TasbihStateTableTableOrderingComposer({
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

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get keepAwake => $composableBuilder(
    column: $table.keepAwake,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get volumeKeys => $composableBuilder(
    column: $table.volumeKeys,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lock => $composableBuilder(
    column: $table.lock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get haptics => $composableBuilder(
    column: $table.haptics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sound => $composableBuilder(
    column: $table.sound,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasbihStateTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasbihStateTableTable> {
  $$TasbihStateTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<int> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<bool> get keepAwake =>
      $composableBuilder(column: $table.keepAwake, builder: (column) => column);

  GeneratedColumn<bool> get volumeKeys => $composableBuilder(
    column: $table.volumeKeys,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get lock =>
      $composableBuilder(column: $table.lock, builder: (column) => column);

  GeneratedColumn<bool> get haptics =>
      $composableBuilder(column: $table.haptics, builder: (column) => column);

  GeneratedColumn<bool> get sound =>
      $composableBuilder(column: $table.sound, builder: (column) => column);
}

class $$TasbihStateTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasbihStateTableTable,
          TasbihStateTableData,
          $$TasbihStateTableTableFilterComposer,
          $$TasbihStateTableTableOrderingComposer,
          $$TasbihStateTableTableAnnotationComposer,
          $$TasbihStateTableTableCreateCompanionBuilder,
          $$TasbihStateTableTableUpdateCompanionBuilder,
          (
            TasbihStateTableData,
            BaseReferences<
              _$AppDatabase,
              $TasbihStateTableTable,
              TasbihStateTableData
            >,
          ),
          TasbihStateTableData,
          PrefetchHooks Function()
        > {
  $$TasbihStateTableTableTableManager(
    _$AppDatabase db,
    $TasbihStateTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasbihStateTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasbihStateTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasbihStateTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<int> target = const Value.absent(),
                Value<bool> keepAwake = const Value.absent(),
                Value<bool> volumeKeys = const Value.absent(),
                Value<bool> lock = const Value.absent(),
                Value<bool> haptics = const Value.absent(),
                Value<bool> sound = const Value.absent(),
              }) => TasbihStateTableCompanion(
                id: id,
                count: count,
                target: target,
                keepAwake: keepAwake,
                volumeKeys: volumeKeys,
                lock: lock,
                haptics: haptics,
                sound: sound,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<int> target = const Value.absent(),
                Value<bool> keepAwake = const Value.absent(),
                Value<bool> volumeKeys = const Value.absent(),
                Value<bool> lock = const Value.absent(),
                Value<bool> haptics = const Value.absent(),
                Value<bool> sound = const Value.absent(),
              }) => TasbihStateTableCompanion.insert(
                id: id,
                count: count,
                target: target,
                keepAwake: keepAwake,
                volumeKeys: volumeKeys,
                lock: lock,
                haptics: haptics,
                sound: sound,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasbihStateTableTable, TasbihStateTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $TasbihStateTableTable,
                    TasbihStateTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasbihStateTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasbihStateTableTable,
      TasbihStateTableData,
      $$TasbihStateTableTableFilterComposer,
      $$TasbihStateTableTableOrderingComposer,
      $$TasbihStateTableTableAnnotationComposer,
      $$TasbihStateTableTableCreateCompanionBuilder,
      $$TasbihStateTableTableUpdateCompanionBuilder,
      (
        TasbihStateTableData,
        BaseReferences<
          _$AppDatabase,
          $TasbihStateTableTable,
          TasbihStateTableData
        >,
      ),
      TasbihStateTableData,
      PrefetchHooks Function()
    >;
typedef $$TasbihDaysTableTableCreateCompanionBuilder =
    TasbihDaysTableCompanion Function({
      required String date,
      Value<int> total,
      Value<int> rowid,
    });
typedef $$TasbihDaysTableTableUpdateCompanionBuilder =
    TasbihDaysTableCompanion Function({
      Value<String> date,
      Value<int> total,
      Value<int> rowid,
    });

class $$TasbihDaysTableTableFilterComposer
    extends Composer<_$AppDatabase, $TasbihDaysTableTable> {
  $$TasbihDaysTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasbihDaysTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TasbihDaysTableTable> {
  $$TasbihDaysTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasbihDaysTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasbihDaysTableTable> {
  $$TasbihDaysTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);
}

class $$TasbihDaysTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasbihDaysTableTable,
          TasbihDaysTableData,
          $$TasbihDaysTableTableFilterComposer,
          $$TasbihDaysTableTableOrderingComposer,
          $$TasbihDaysTableTableAnnotationComposer,
          $$TasbihDaysTableTableCreateCompanionBuilder,
          $$TasbihDaysTableTableUpdateCompanionBuilder,
          (
            TasbihDaysTableData,
            BaseReferences<
              _$AppDatabase,
              $TasbihDaysTableTable,
              TasbihDaysTableData
            >,
          ),
          TasbihDaysTableData,
          PrefetchHooks Function()
        > {
  $$TasbihDaysTableTableTableManager(
    _$AppDatabase db,
    $TasbihDaysTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasbihDaysTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasbihDaysTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasbihDaysTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasbihDaysTableCompanion(
                date: date,
                total: total,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                Value<int> total = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasbihDaysTableCompanion.insert(
                date: date,
                total: total,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasbihDaysTableTable, TasbihDaysTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $TasbihDaysTableTable,
                    TasbihDaysTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasbihDaysTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasbihDaysTableTable,
      TasbihDaysTableData,
      $$TasbihDaysTableTableFilterComposer,
      $$TasbihDaysTableTableOrderingComposer,
      $$TasbihDaysTableTableAnnotationComposer,
      $$TasbihDaysTableTableCreateCompanionBuilder,
      $$TasbihDaysTableTableUpdateCompanionBuilder,
      (
        TasbihDaysTableData,
        BaseReferences<
          _$AppDatabase,
          $TasbihDaysTableTable,
          TasbihDaysTableData
        >,
      ),
      TasbihDaysTableData,
      PrefetchHooks Function()
    >;
typedef $$AdhkarProgressTableTableCreateCompanionBuilder =
    AdhkarProgressTableCompanion Function({
      required String sessionId,
      required String collectionId,
      required String entryId,
      Value<int> completedCount,
      required int startedAtMs,
      Value<int?> finishedAtMs,
      Value<int> rowid,
    });
typedef $$AdhkarProgressTableTableUpdateCompanionBuilder =
    AdhkarProgressTableCompanion Function({
      Value<String> sessionId,
      Value<String> collectionId,
      Value<String> entryId,
      Value<int> completedCount,
      Value<int> startedAtMs,
      Value<int?> finishedAtMs,
      Value<int> rowid,
    });

class $$AdhkarProgressTableTableFilterComposer
    extends Composer<_$AppDatabase, $AdhkarProgressTableTable> {
  $$AdhkarProgressTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedCount => $composableBuilder(
    column: $table.completedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finishedAtMs => $composableBuilder(
    column: $table.finishedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AdhkarProgressTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AdhkarProgressTableTable> {
  $$AdhkarProgressTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedCount => $composableBuilder(
    column: $table.completedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finishedAtMs => $composableBuilder(
    column: $table.finishedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdhkarProgressTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AdhkarProgressTableTable> {
  $$AdhkarProgressTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<int> get completedCount => $composableBuilder(
    column: $table.completedCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get finishedAtMs => $composableBuilder(
    column: $table.finishedAtMs,
    builder: (column) => column,
  );
}

class $$AdhkarProgressTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AdhkarProgressTableTable,
          AdhkarProgressTableData,
          $$AdhkarProgressTableTableFilterComposer,
          $$AdhkarProgressTableTableOrderingComposer,
          $$AdhkarProgressTableTableAnnotationComposer,
          $$AdhkarProgressTableTableCreateCompanionBuilder,
          $$AdhkarProgressTableTableUpdateCompanionBuilder,
          (
            AdhkarProgressTableData,
            BaseReferences<
              _$AppDatabase,
              $AdhkarProgressTableTable,
              AdhkarProgressTableData
            >,
          ),
          AdhkarProgressTableData,
          PrefetchHooks Function()
        > {
  $$AdhkarProgressTableTableTableManager(
    _$AppDatabase db,
    $AdhkarProgressTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdhkarProgressTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdhkarProgressTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AdhkarProgressTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> collectionId = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<int> completedCount = const Value.absent(),
                Value<int> startedAtMs = const Value.absent(),
                Value<int?> finishedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdhkarProgressTableCompanion(
                sessionId: sessionId,
                collectionId: collectionId,
                entryId: entryId,
                completedCount: completedCount,
                startedAtMs: startedAtMs,
                finishedAtMs: finishedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String collectionId,
                required String entryId,
                Value<int> completedCount = const Value.absent(),
                required int startedAtMs,
                Value<int?> finishedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdhkarProgressTableCompanion.insert(
                sessionId: sessionId,
                collectionId: collectionId,
                entryId: entryId,
                completedCount: completedCount,
                startedAtMs: startedAtMs,
                finishedAtMs: finishedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $AdhkarProgressTableTable,
                    AdhkarProgressTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AdhkarProgressTableTable,
                    AdhkarProgressTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AdhkarProgressTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AdhkarProgressTableTable,
      AdhkarProgressTableData,
      $$AdhkarProgressTableTableFilterComposer,
      $$AdhkarProgressTableTableOrderingComposer,
      $$AdhkarProgressTableTableAnnotationComposer,
      $$AdhkarProgressTableTableCreateCompanionBuilder,
      $$AdhkarProgressTableTableUpdateCompanionBuilder,
      (
        AdhkarProgressTableData,
        BaseReferences<
          _$AppDatabase,
          $AdhkarProgressTableTable,
          AdhkarProgressTableData
        >,
      ),
      AdhkarProgressTableData,
      PrefetchHooks Function()
    >;
typedef $$AdhkarBookmarkTableTableCreateCompanionBuilder =
    AdhkarBookmarkTableCompanion Function({
      required String entryId,
      required int createdAtMs,
      Value<int> rowid,
    });
typedef $$AdhkarBookmarkTableTableUpdateCompanionBuilder =
    AdhkarBookmarkTableCompanion Function({
      Value<String> entryId,
      Value<int> createdAtMs,
      Value<int> rowid,
    });

class $$AdhkarBookmarkTableTableFilterComposer
    extends Composer<_$AppDatabase, $AdhkarBookmarkTableTable> {
  $$AdhkarBookmarkTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AdhkarBookmarkTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AdhkarBookmarkTableTable> {
  $$AdhkarBookmarkTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdhkarBookmarkTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AdhkarBookmarkTableTable> {
  $$AdhkarBookmarkTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );
}

class $$AdhkarBookmarkTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AdhkarBookmarkTableTable,
          AdhkarBookmarkTableData,
          $$AdhkarBookmarkTableTableFilterComposer,
          $$AdhkarBookmarkTableTableOrderingComposer,
          $$AdhkarBookmarkTableTableAnnotationComposer,
          $$AdhkarBookmarkTableTableCreateCompanionBuilder,
          $$AdhkarBookmarkTableTableUpdateCompanionBuilder,
          (
            AdhkarBookmarkTableData,
            BaseReferences<
              _$AppDatabase,
              $AdhkarBookmarkTableTable,
              AdhkarBookmarkTableData
            >,
          ),
          AdhkarBookmarkTableData,
          PrefetchHooks Function()
        > {
  $$AdhkarBookmarkTableTableTableManager(
    _$AppDatabase db,
    $AdhkarBookmarkTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdhkarBookmarkTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdhkarBookmarkTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AdhkarBookmarkTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdhkarBookmarkTableCompanion(
                entryId: entryId,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required int createdAtMs,
                Value<int> rowid = const Value.absent(),
              }) => AdhkarBookmarkTableCompanion.insert(
                entryId: entryId,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $AdhkarBookmarkTableTable,
                    AdhkarBookmarkTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AdhkarBookmarkTableTable,
                    AdhkarBookmarkTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AdhkarBookmarkTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AdhkarBookmarkTableTable,
      AdhkarBookmarkTableData,
      $$AdhkarBookmarkTableTableFilterComposer,
      $$AdhkarBookmarkTableTableOrderingComposer,
      $$AdhkarBookmarkTableTableAnnotationComposer,
      $$AdhkarBookmarkTableTableCreateCompanionBuilder,
      $$AdhkarBookmarkTableTableUpdateCompanionBuilder,
      (
        AdhkarBookmarkTableData,
        BaseReferences<
          _$AppDatabase,
          $AdhkarBookmarkTableTable,
          AdhkarBookmarkTableData
        >,
      ),
      AdhkarBookmarkTableData,
      PrefetchHooks Function()
    >;
typedef $$AdhkarReminderTableTableCreateCompanionBuilder =
    AdhkarReminderTableCompanion Function({
      required AdhkarReminderKind kind,
      required ReminderAnchor anchor,
      Value<int> offsetMinutes,
      Value<bool> enabled,
      Value<int> rowid,
    });
typedef $$AdhkarReminderTableTableUpdateCompanionBuilder =
    AdhkarReminderTableCompanion Function({
      Value<AdhkarReminderKind> kind,
      Value<ReminderAnchor> anchor,
      Value<int> offsetMinutes,
      Value<bool> enabled,
      Value<int> rowid,
    });

class $$AdhkarReminderTableTableFilterComposer
    extends Composer<_$AppDatabase, $AdhkarReminderTableTable> {
  $$AdhkarReminderTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<AdhkarReminderKind, AdhkarReminderKind, String>
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<ReminderAnchor, ReminderAnchor, String>
  get anchor => $composableBuilder(
    column: $table.anchor,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AdhkarReminderTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AdhkarReminderTableTable> {
  $$AdhkarReminderTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchor => $composableBuilder(
    column: $table.anchor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdhkarReminderTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AdhkarReminderTableTable> {
  $$AdhkarReminderTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<AdhkarReminderKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReminderAnchor, String> get anchor =>
      $composableBuilder(column: $table.anchor, builder: (column) => column);

  GeneratedColumn<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);
}

class $$AdhkarReminderTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AdhkarReminderTableTable,
          AdhkarReminderTableData,
          $$AdhkarReminderTableTableFilterComposer,
          $$AdhkarReminderTableTableOrderingComposer,
          $$AdhkarReminderTableTableAnnotationComposer,
          $$AdhkarReminderTableTableCreateCompanionBuilder,
          $$AdhkarReminderTableTableUpdateCompanionBuilder,
          (
            AdhkarReminderTableData,
            BaseReferences<
              _$AppDatabase,
              $AdhkarReminderTableTable,
              AdhkarReminderTableData
            >,
          ),
          AdhkarReminderTableData,
          PrefetchHooks Function()
        > {
  $$AdhkarReminderTableTableTableManager(
    _$AppDatabase db,
    $AdhkarReminderTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdhkarReminderTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdhkarReminderTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AdhkarReminderTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<AdhkarReminderKind> kind = const Value.absent(),
                Value<ReminderAnchor> anchor = const Value.absent(),
                Value<int> offsetMinutes = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdhkarReminderTableCompanion(
                kind: kind,
                anchor: anchor,
                offsetMinutes: offsetMinutes,
                enabled: enabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required AdhkarReminderKind kind,
                required ReminderAnchor anchor,
                Value<int> offsetMinutes = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdhkarReminderTableCompanion.insert(
                kind: kind,
                anchor: anchor,
                offsetMinutes: offsetMinutes,
                enabled: enabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $AdhkarReminderTableTable,
                    AdhkarReminderTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AdhkarReminderTableTable,
                    AdhkarReminderTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AdhkarReminderTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AdhkarReminderTableTable,
      AdhkarReminderTableData,
      $$AdhkarReminderTableTableFilterComposer,
      $$AdhkarReminderTableTableOrderingComposer,
      $$AdhkarReminderTableTableAnnotationComposer,
      $$AdhkarReminderTableTableCreateCompanionBuilder,
      $$AdhkarReminderTableTableUpdateCompanionBuilder,
      (
        AdhkarReminderTableData,
        BaseReferences<
          _$AppDatabase,
          $AdhkarReminderTableTable,
          AdhkarReminderTableData
        >,
      ),
      AdhkarReminderTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocationTableTableTableManager get locationTable =>
      $$LocationTableTableTableManager(_db, _db.locationTable);
  $$PrayerSettingsTableTableTableManager get prayerSettingsTable =>
      $$PrayerSettingsTableTableTableManager(_db, _db.prayerSettingsTable);
  $$AlertPreferenceTableTableTableManager get alertPreferenceTable =>
      $$AlertPreferenceTableTableTableManager(_db, _db.alertPreferenceTable);
  $$GlobalSettingsTableTableTableManager get globalSettingsTable =>
      $$GlobalSettingsTableTableTableManager(_db, _db.globalSettingsTable);
  $$AlertLogTableTableTableManager get alertLogTable =>
      $$AlertLogTableTableTableManager(_db, _db.alertLogTable);
  $$TasbihStateTableTableTableManager get tasbihStateTable =>
      $$TasbihStateTableTableTableManager(_db, _db.tasbihStateTable);
  $$TasbihDaysTableTableTableManager get tasbihDaysTable =>
      $$TasbihDaysTableTableTableManager(_db, _db.tasbihDaysTable);
  $$AdhkarProgressTableTableTableManager get adhkarProgressTable =>
      $$AdhkarProgressTableTableTableManager(_db, _db.adhkarProgressTable);
  $$AdhkarBookmarkTableTableTableManager get adhkarBookmarkTable =>
      $$AdhkarBookmarkTableTableTableManager(_db, _db.adhkarBookmarkTable);
  $$AdhkarReminderTableTableTableManager get adhkarReminderTable =>
      $$AdhkarReminderTableTableTableManager(_db, _db.adhkarReminderTable);
}
