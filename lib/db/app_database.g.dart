// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MovementsTable extends Movements
    with TableInfo<$MovementsTable, Movement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovementsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minWeightMeta = const VerificationMeta(
    'minWeight',
  );
  @override
  late final GeneratedColumn<double> minWeight = GeneratedColumn<double>(
    'min_weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightDeltaMeta = const VerificationMeta(
    'weightDelta',
  );
  @override
  late final GeneratedColumn<double> weightDelta = GeneratedColumn<double>(
    'weight_delta',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkMeta = const VerificationMeta('link');
  @override
  late final GeneratedColumn<String> link = GeneratedColumn<String>(
    'link',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _note1Meta = const VerificationMeta('note1');
  @override
  late final GeneratedColumn<String> note1 = GeneratedColumn<String>(
    'note1',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _note2Meta = const VerificationMeta('note2');
  @override
  late final GeneratedColumn<String> note2 = GeneratedColumn<String>(
    'note2',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MuscleGroup, String> muscleGroup =
      GeneratedColumn<String>(
        'muscle_group',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MuscleGroup>($MovementsTable.$convertermuscleGroup);
  static const VerificationMeta _subMuscleGroupMeta = const VerificationMeta(
    'subMuscleGroup',
  );
  @override
  late final GeneratedColumn<String> subMuscleGroup = GeneratedColumn<String>(
    'sub_muscle_group',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isRequiredRepsMeta = const VerificationMeta(
    'isRequiredReps',
  );
  @override
  late final GeneratedColumn<bool> isRequiredReps = GeneratedColumn<bool>(
    'is_required_reps',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_required_reps" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isRequiredWeightMeta = const VerificationMeta(
    'isRequiredWeight',
  );
  @override
  late final GeneratedColumn<bool> isRequiredWeight = GeneratedColumn<bool>(
    'is_required_weight',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_required_weight" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isRequiredTimeMeta = const VerificationMeta(
    'isRequiredTime',
  );
  @override
  late final GeneratedColumn<bool> isRequiredTime = GeneratedColumn<bool>(
    'is_required_time',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_required_time" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isRequiredDistanceMeta =
      const VerificationMeta('isRequiredDistance');
  @override
  late final GeneratedColumn<bool> isRequiredDistance = GeneratedColumn<bool>(
    'is_required_distance',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_required_distance" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<MovementCategory, String>
  category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<MovementCategory>($MovementsTable.$convertercategory);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    minWeight,
    weightDelta,
    link,
    note1,
    note2,
    muscleGroup,
    subMuscleGroup,
    isRequiredReps,
    isRequiredWeight,
    isRequiredTime,
    isRequiredDistance,
    category,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<Movement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('min_weight')) {
      context.handle(
        _minWeightMeta,
        minWeight.isAcceptableOrUnknown(data['min_weight']!, _minWeightMeta),
      );
    }
    if (data.containsKey('weight_delta')) {
      context.handle(
        _weightDeltaMeta,
        weightDelta.isAcceptableOrUnknown(
          data['weight_delta']!,
          _weightDeltaMeta,
        ),
      );
    }
    if (data.containsKey('link')) {
      context.handle(
        _linkMeta,
        link.isAcceptableOrUnknown(data['link']!, _linkMeta),
      );
    }
    if (data.containsKey('note1')) {
      context.handle(
        _note1Meta,
        note1.isAcceptableOrUnknown(data['note1']!, _note1Meta),
      );
    }
    if (data.containsKey('note2')) {
      context.handle(
        _note2Meta,
        note2.isAcceptableOrUnknown(data['note2']!, _note2Meta),
      );
    }
    if (data.containsKey('sub_muscle_group')) {
      context.handle(
        _subMuscleGroupMeta,
        subMuscleGroup.isAcceptableOrUnknown(
          data['sub_muscle_group']!,
          _subMuscleGroupMeta,
        ),
      );
    }
    if (data.containsKey('is_required_reps')) {
      context.handle(
        _isRequiredRepsMeta,
        isRequiredReps.isAcceptableOrUnknown(
          data['is_required_reps']!,
          _isRequiredRepsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isRequiredRepsMeta);
    }
    if (data.containsKey('is_required_weight')) {
      context.handle(
        _isRequiredWeightMeta,
        isRequiredWeight.isAcceptableOrUnknown(
          data['is_required_weight']!,
          _isRequiredWeightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isRequiredWeightMeta);
    }
    if (data.containsKey('is_required_time')) {
      context.handle(
        _isRequiredTimeMeta,
        isRequiredTime.isAcceptableOrUnknown(
          data['is_required_time']!,
          _isRequiredTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isRequiredTimeMeta);
    }
    if (data.containsKey('is_required_distance')) {
      context.handle(
        _isRequiredDistanceMeta,
        isRequiredDistance.isAcceptableOrUnknown(
          data['is_required_distance']!,
          _isRequiredDistanceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {name, muscleGroup},
  ];
  @override
  Movement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Movement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      minWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_weight'],
      ),
      weightDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_delta'],
      ),
      link: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}link'],
      ),
      note1: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note1'],
      ),
      note2: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note2'],
      ),
      muscleGroup: $MovementsTable.$convertermuscleGroup.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}muscle_group'],
        )!,
      ),
      subMuscleGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_muscle_group'],
      ),
      isRequiredReps: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_required_reps'],
      )!,
      isRequiredWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_required_weight'],
      )!,
      isRequiredTime: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_required_time'],
      )!,
      isRequiredDistance: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_required_distance'],
      )!,
      category: $MovementsTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category'],
        )!,
      ),
    );
  }

  @override
  $MovementsTable createAlias(String alias) {
    return $MovementsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MuscleGroup, String, String> $convertermuscleGroup =
      const EnumNameConverter<MuscleGroup>(MuscleGroup.values);
  static JsonTypeConverter2<MovementCategory, String, String>
  $convertercategory = const EnumNameConverter<MovementCategory>(
    MovementCategory.values,
  );
}

class Movement extends DataClass implements Insertable<Movement> {
  final int id;
  final String name;
  final double? minWeight;
  final double? weightDelta;
  final String? link;
  final String? note1;
  final String? note2;
  final MuscleGroup muscleGroup;
  final String? subMuscleGroup;
  final bool isRequiredReps;
  final bool isRequiredWeight;
  final bool isRequiredTime;
  final bool isRequiredDistance;
  final MovementCategory category;
  const Movement({
    required this.id,
    required this.name,
    this.minWeight,
    this.weightDelta,
    this.link,
    this.note1,
    this.note2,
    required this.muscleGroup,
    this.subMuscleGroup,
    required this.isRequiredReps,
    required this.isRequiredWeight,
    required this.isRequiredTime,
    required this.isRequiredDistance,
    required this.category,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || minWeight != null) {
      map['min_weight'] = Variable<double>(minWeight);
    }
    if (!nullToAbsent || weightDelta != null) {
      map['weight_delta'] = Variable<double>(weightDelta);
    }
    if (!nullToAbsent || link != null) {
      map['link'] = Variable<String>(link);
    }
    if (!nullToAbsent || note1 != null) {
      map['note1'] = Variable<String>(note1);
    }
    if (!nullToAbsent || note2 != null) {
      map['note2'] = Variable<String>(note2);
    }
    {
      map['muscle_group'] = Variable<String>(
        $MovementsTable.$convertermuscleGroup.toSql(muscleGroup),
      );
    }
    if (!nullToAbsent || subMuscleGroup != null) {
      map['sub_muscle_group'] = Variable<String>(subMuscleGroup);
    }
    map['is_required_reps'] = Variable<bool>(isRequiredReps);
    map['is_required_weight'] = Variable<bool>(isRequiredWeight);
    map['is_required_time'] = Variable<bool>(isRequiredTime);
    map['is_required_distance'] = Variable<bool>(isRequiredDistance);
    {
      map['category'] = Variable<String>(
        $MovementsTable.$convertercategory.toSql(category),
      );
    }
    return map;
  }

  MovementsCompanion toCompanion(bool nullToAbsent) {
    return MovementsCompanion(
      id: Value(id),
      name: Value(name),
      minWeight: minWeight == null && nullToAbsent
          ? const Value.absent()
          : Value(minWeight),
      weightDelta: weightDelta == null && nullToAbsent
          ? const Value.absent()
          : Value(weightDelta),
      link: link == null && nullToAbsent ? const Value.absent() : Value(link),
      note1: note1 == null && nullToAbsent
          ? const Value.absent()
          : Value(note1),
      note2: note2 == null && nullToAbsent
          ? const Value.absent()
          : Value(note2),
      muscleGroup: Value(muscleGroup),
      subMuscleGroup: subMuscleGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(subMuscleGroup),
      isRequiredReps: Value(isRequiredReps),
      isRequiredWeight: Value(isRequiredWeight),
      isRequiredTime: Value(isRequiredTime),
      isRequiredDistance: Value(isRequiredDistance),
      category: Value(category),
    );
  }

  factory Movement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Movement(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      minWeight: serializer.fromJson<double?>(json['minWeight']),
      weightDelta: serializer.fromJson<double?>(json['weightDelta']),
      link: serializer.fromJson<String?>(json['link']),
      note1: serializer.fromJson<String?>(json['note1']),
      note2: serializer.fromJson<String?>(json['note2']),
      muscleGroup: $MovementsTable.$convertermuscleGroup.fromJson(
        serializer.fromJson<String>(json['muscleGroup']),
      ),
      subMuscleGroup: serializer.fromJson<String?>(json['subMuscleGroup']),
      isRequiredReps: serializer.fromJson<bool>(json['isRequiredReps']),
      isRequiredWeight: serializer.fromJson<bool>(json['isRequiredWeight']),
      isRequiredTime: serializer.fromJson<bool>(json['isRequiredTime']),
      isRequiredDistance: serializer.fromJson<bool>(json['isRequiredDistance']),
      category: $MovementsTable.$convertercategory.fromJson(
        serializer.fromJson<String>(json['category']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'minWeight': serializer.toJson<double?>(minWeight),
      'weightDelta': serializer.toJson<double?>(weightDelta),
      'link': serializer.toJson<String?>(link),
      'note1': serializer.toJson<String?>(note1),
      'note2': serializer.toJson<String?>(note2),
      'muscleGroup': serializer.toJson<String>(
        $MovementsTable.$convertermuscleGroup.toJson(muscleGroup),
      ),
      'subMuscleGroup': serializer.toJson<String?>(subMuscleGroup),
      'isRequiredReps': serializer.toJson<bool>(isRequiredReps),
      'isRequiredWeight': serializer.toJson<bool>(isRequiredWeight),
      'isRequiredTime': serializer.toJson<bool>(isRequiredTime),
      'isRequiredDistance': serializer.toJson<bool>(isRequiredDistance),
      'category': serializer.toJson<String>(
        $MovementsTable.$convertercategory.toJson(category),
      ),
    };
  }

  Movement copyWith({
    int? id,
    String? name,
    Value<double?> minWeight = const Value.absent(),
    Value<double?> weightDelta = const Value.absent(),
    Value<String?> link = const Value.absent(),
    Value<String?> note1 = const Value.absent(),
    Value<String?> note2 = const Value.absent(),
    MuscleGroup? muscleGroup,
    Value<String?> subMuscleGroup = const Value.absent(),
    bool? isRequiredReps,
    bool? isRequiredWeight,
    bool? isRequiredTime,
    bool? isRequiredDistance,
    MovementCategory? category,
  }) => Movement(
    id: id ?? this.id,
    name: name ?? this.name,
    minWeight: minWeight.present ? minWeight.value : this.minWeight,
    weightDelta: weightDelta.present ? weightDelta.value : this.weightDelta,
    link: link.present ? link.value : this.link,
    note1: note1.present ? note1.value : this.note1,
    note2: note2.present ? note2.value : this.note2,
    muscleGroup: muscleGroup ?? this.muscleGroup,
    subMuscleGroup: subMuscleGroup.present
        ? subMuscleGroup.value
        : this.subMuscleGroup,
    isRequiredReps: isRequiredReps ?? this.isRequiredReps,
    isRequiredWeight: isRequiredWeight ?? this.isRequiredWeight,
    isRequiredTime: isRequiredTime ?? this.isRequiredTime,
    isRequiredDistance: isRequiredDistance ?? this.isRequiredDistance,
    category: category ?? this.category,
  );
  Movement copyWithCompanion(MovementsCompanion data) {
    return Movement(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      minWeight: data.minWeight.present ? data.minWeight.value : this.minWeight,
      weightDelta: data.weightDelta.present
          ? data.weightDelta.value
          : this.weightDelta,
      link: data.link.present ? data.link.value : this.link,
      note1: data.note1.present ? data.note1.value : this.note1,
      note2: data.note2.present ? data.note2.value : this.note2,
      muscleGroup: data.muscleGroup.present
          ? data.muscleGroup.value
          : this.muscleGroup,
      subMuscleGroup: data.subMuscleGroup.present
          ? data.subMuscleGroup.value
          : this.subMuscleGroup,
      isRequiredReps: data.isRequiredReps.present
          ? data.isRequiredReps.value
          : this.isRequiredReps,
      isRequiredWeight: data.isRequiredWeight.present
          ? data.isRequiredWeight.value
          : this.isRequiredWeight,
      isRequiredTime: data.isRequiredTime.present
          ? data.isRequiredTime.value
          : this.isRequiredTime,
      isRequiredDistance: data.isRequiredDistance.present
          ? data.isRequiredDistance.value
          : this.isRequiredDistance,
      category: data.category.present ? data.category.value : this.category,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Movement(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('minWeight: $minWeight, ')
          ..write('weightDelta: $weightDelta, ')
          ..write('link: $link, ')
          ..write('note1: $note1, ')
          ..write('note2: $note2, ')
          ..write('muscleGroup: $muscleGroup, ')
          ..write('subMuscleGroup: $subMuscleGroup, ')
          ..write('isRequiredReps: $isRequiredReps, ')
          ..write('isRequiredWeight: $isRequiredWeight, ')
          ..write('isRequiredTime: $isRequiredTime, ')
          ..write('isRequiredDistance: $isRequiredDistance, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    minWeight,
    weightDelta,
    link,
    note1,
    note2,
    muscleGroup,
    subMuscleGroup,
    isRequiredReps,
    isRequiredWeight,
    isRequiredTime,
    isRequiredDistance,
    category,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Movement &&
          other.id == this.id &&
          other.name == this.name &&
          other.minWeight == this.minWeight &&
          other.weightDelta == this.weightDelta &&
          other.link == this.link &&
          other.note1 == this.note1 &&
          other.note2 == this.note2 &&
          other.muscleGroup == this.muscleGroup &&
          other.subMuscleGroup == this.subMuscleGroup &&
          other.isRequiredReps == this.isRequiredReps &&
          other.isRequiredWeight == this.isRequiredWeight &&
          other.isRequiredTime == this.isRequiredTime &&
          other.isRequiredDistance == this.isRequiredDistance &&
          other.category == this.category);
}

class MovementsCompanion extends UpdateCompanion<Movement> {
  final Value<int> id;
  final Value<String> name;
  final Value<double?> minWeight;
  final Value<double?> weightDelta;
  final Value<String?> link;
  final Value<String?> note1;
  final Value<String?> note2;
  final Value<MuscleGroup> muscleGroup;
  final Value<String?> subMuscleGroup;
  final Value<bool> isRequiredReps;
  final Value<bool> isRequiredWeight;
  final Value<bool> isRequiredTime;
  final Value<bool> isRequiredDistance;
  final Value<MovementCategory> category;
  const MovementsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.minWeight = const Value.absent(),
    this.weightDelta = const Value.absent(),
    this.link = const Value.absent(),
    this.note1 = const Value.absent(),
    this.note2 = const Value.absent(),
    this.muscleGroup = const Value.absent(),
    this.subMuscleGroup = const Value.absent(),
    this.isRequiredReps = const Value.absent(),
    this.isRequiredWeight = const Value.absent(),
    this.isRequiredTime = const Value.absent(),
    this.isRequiredDistance = const Value.absent(),
    this.category = const Value.absent(),
  });
  MovementsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.minWeight = const Value.absent(),
    this.weightDelta = const Value.absent(),
    this.link = const Value.absent(),
    this.note1 = const Value.absent(),
    this.note2 = const Value.absent(),
    required MuscleGroup muscleGroup,
    this.subMuscleGroup = const Value.absent(),
    required bool isRequiredReps,
    required bool isRequiredWeight,
    required bool isRequiredTime,
    this.isRequiredDistance = const Value.absent(),
    required MovementCategory category,
  }) : name = Value(name),
       muscleGroup = Value(muscleGroup),
       isRequiredReps = Value(isRequiredReps),
       isRequiredWeight = Value(isRequiredWeight),
       isRequiredTime = Value(isRequiredTime),
       category = Value(category);
  static Insertable<Movement> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? minWeight,
    Expression<double>? weightDelta,
    Expression<String>? link,
    Expression<String>? note1,
    Expression<String>? note2,
    Expression<String>? muscleGroup,
    Expression<String>? subMuscleGroup,
    Expression<bool>? isRequiredReps,
    Expression<bool>? isRequiredWeight,
    Expression<bool>? isRequiredTime,
    Expression<bool>? isRequiredDistance,
    Expression<String>? category,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (minWeight != null) 'min_weight': minWeight,
      if (weightDelta != null) 'weight_delta': weightDelta,
      if (link != null) 'link': link,
      if (note1 != null) 'note1': note1,
      if (note2 != null) 'note2': note2,
      if (muscleGroup != null) 'muscle_group': muscleGroup,
      if (subMuscleGroup != null) 'sub_muscle_group': subMuscleGroup,
      if (isRequiredReps != null) 'is_required_reps': isRequiredReps,
      if (isRequiredWeight != null) 'is_required_weight': isRequiredWeight,
      if (isRequiredTime != null) 'is_required_time': isRequiredTime,
      if (isRequiredDistance != null)
        'is_required_distance': isRequiredDistance,
      if (category != null) 'category': category,
    });
  }

  MovementsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double?>? minWeight,
    Value<double?>? weightDelta,
    Value<String?>? link,
    Value<String?>? note1,
    Value<String?>? note2,
    Value<MuscleGroup>? muscleGroup,
    Value<String?>? subMuscleGroup,
    Value<bool>? isRequiredReps,
    Value<bool>? isRequiredWeight,
    Value<bool>? isRequiredTime,
    Value<bool>? isRequiredDistance,
    Value<MovementCategory>? category,
  }) {
    return MovementsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      minWeight: minWeight ?? this.minWeight,
      weightDelta: weightDelta ?? this.weightDelta,
      link: link ?? this.link,
      note1: note1 ?? this.note1,
      note2: note2 ?? this.note2,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      subMuscleGroup: subMuscleGroup ?? this.subMuscleGroup,
      isRequiredReps: isRequiredReps ?? this.isRequiredReps,
      isRequiredWeight: isRequiredWeight ?? this.isRequiredWeight,
      isRequiredTime: isRequiredTime ?? this.isRequiredTime,
      isRequiredDistance: isRequiredDistance ?? this.isRequiredDistance,
      category: category ?? this.category,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (minWeight.present) {
      map['min_weight'] = Variable<double>(minWeight.value);
    }
    if (weightDelta.present) {
      map['weight_delta'] = Variable<double>(weightDelta.value);
    }
    if (link.present) {
      map['link'] = Variable<String>(link.value);
    }
    if (note1.present) {
      map['note1'] = Variable<String>(note1.value);
    }
    if (note2.present) {
      map['note2'] = Variable<String>(note2.value);
    }
    if (muscleGroup.present) {
      map['muscle_group'] = Variable<String>(
        $MovementsTable.$convertermuscleGroup.toSql(muscleGroup.value),
      );
    }
    if (subMuscleGroup.present) {
      map['sub_muscle_group'] = Variable<String>(subMuscleGroup.value);
    }
    if (isRequiredReps.present) {
      map['is_required_reps'] = Variable<bool>(isRequiredReps.value);
    }
    if (isRequiredWeight.present) {
      map['is_required_weight'] = Variable<bool>(isRequiredWeight.value);
    }
    if (isRequiredTime.present) {
      map['is_required_time'] = Variable<bool>(isRequiredTime.value);
    }
    if (isRequiredDistance.present) {
      map['is_required_distance'] = Variable<bool>(isRequiredDistance.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
        $MovementsTable.$convertercategory.toSql(category.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovementsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('minWeight: $minWeight, ')
          ..write('weightDelta: $weightDelta, ')
          ..write('link: $link, ')
          ..write('note1: $note1, ')
          ..write('note2: $note2, ')
          ..write('muscleGroup: $muscleGroup, ')
          ..write('subMuscleGroup: $subMuscleGroup, ')
          ..write('isRequiredReps: $isRequiredReps, ')
          ..write('isRequiredWeight: $isRequiredWeight, ')
          ..write('isRequiredTime: $isRequiredTime, ')
          ..write('isRequiredDistance: $isRequiredDistance, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }
}

class $MesoTemplatesTable extends MesoTemplates
    with TableInfo<$MesoTemplatesTable, MesoTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MesoTemplatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meso_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<MesoTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MesoTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MesoTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MesoTemplatesTable createAlias(String alias) {
    return $MesoTemplatesTable(attachedDatabase, alias);
  }
}

class MesoTemplate extends DataClass implements Insertable<MesoTemplate> {
  final int id;
  final String name;
  final DateTime createdAt;
  const MesoTemplate({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MesoTemplatesCompanion toCompanion(bool nullToAbsent) {
    return MesoTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory MesoTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MesoTemplate(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MesoTemplate copyWith({int? id, String? name, DateTime? createdAt}) =>
      MesoTemplate(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );
  MesoTemplate copyWithCompanion(MesoTemplatesCompanion data) {
    return MesoTemplate(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MesoTemplate(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MesoTemplate &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class MesoTemplatesCompanion extends UpdateCompanion<MesoTemplate> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  const MesoTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MesoTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<MesoTemplate> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MesoTemplatesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
  }) {
    return MesoTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MesoTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WeekTemplatesTable extends WeekTemplates
    with TableInfo<$WeekTemplatesTable, WeekTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeekTemplatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _mesoTemplateIdMeta = const VerificationMeta(
    'mesoTemplateId',
  );
  @override
  late final GeneratedColumn<int> mesoTemplateId = GeneratedColumn<int>(
    'meso_template_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES meso_templates (id)',
    ),
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
  static const VerificationMeta _workoutCountMeta = const VerificationMeta(
    'workoutCount',
  );
  @override
  late final GeneratedColumn<int> workoutCount = GeneratedColumn<int>(
    'workout_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mesoTemplateId,
    name,
    workoutCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'week_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeekTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('meso_template_id')) {
      context.handle(
        _mesoTemplateIdMeta,
        mesoTemplateId.isAcceptableOrUnknown(
          data['meso_template_id']!,
          _mesoTemplateIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mesoTemplateIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('workout_count')) {
      context.handle(
        _workoutCountMeta,
        workoutCount.isAcceptableOrUnknown(
          data['workout_count']!,
          _workoutCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workoutCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeekTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeekTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      mesoTemplateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meso_template_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      workoutCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}workout_count'],
      )!,
    );
  }

  @override
  $WeekTemplatesTable createAlias(String alias) {
    return $WeekTemplatesTable(attachedDatabase, alias);
  }
}

class WeekTemplate extends DataClass implements Insertable<WeekTemplate> {
  final int id;
  final int mesoTemplateId;
  final String name;
  final int workoutCount;
  const WeekTemplate({
    required this.id,
    required this.mesoTemplateId,
    required this.name,
    required this.workoutCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['meso_template_id'] = Variable<int>(mesoTemplateId);
    map['name'] = Variable<String>(name);
    map['workout_count'] = Variable<int>(workoutCount);
    return map;
  }

  WeekTemplatesCompanion toCompanion(bool nullToAbsent) {
    return WeekTemplatesCompanion(
      id: Value(id),
      mesoTemplateId: Value(mesoTemplateId),
      name: Value(name),
      workoutCount: Value(workoutCount),
    );
  }

  factory WeekTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeekTemplate(
      id: serializer.fromJson<int>(json['id']),
      mesoTemplateId: serializer.fromJson<int>(json['mesoTemplateId']),
      name: serializer.fromJson<String>(json['name']),
      workoutCount: serializer.fromJson<int>(json['workoutCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mesoTemplateId': serializer.toJson<int>(mesoTemplateId),
      'name': serializer.toJson<String>(name),
      'workoutCount': serializer.toJson<int>(workoutCount),
    };
  }

  WeekTemplate copyWith({
    int? id,
    int? mesoTemplateId,
    String? name,
    int? workoutCount,
  }) => WeekTemplate(
    id: id ?? this.id,
    mesoTemplateId: mesoTemplateId ?? this.mesoTemplateId,
    name: name ?? this.name,
    workoutCount: workoutCount ?? this.workoutCount,
  );
  WeekTemplate copyWithCompanion(WeekTemplatesCompanion data) {
    return WeekTemplate(
      id: data.id.present ? data.id.value : this.id,
      mesoTemplateId: data.mesoTemplateId.present
          ? data.mesoTemplateId.value
          : this.mesoTemplateId,
      name: data.name.present ? data.name.value : this.name,
      workoutCount: data.workoutCount.present
          ? data.workoutCount.value
          : this.workoutCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeekTemplate(')
          ..write('id: $id, ')
          ..write('mesoTemplateId: $mesoTemplateId, ')
          ..write('name: $name, ')
          ..write('workoutCount: $workoutCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, mesoTemplateId, name, workoutCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeekTemplate &&
          other.id == this.id &&
          other.mesoTemplateId == this.mesoTemplateId &&
          other.name == this.name &&
          other.workoutCount == this.workoutCount);
}

class WeekTemplatesCompanion extends UpdateCompanion<WeekTemplate> {
  final Value<int> id;
  final Value<int> mesoTemplateId;
  final Value<String> name;
  final Value<int> workoutCount;
  const WeekTemplatesCompanion({
    this.id = const Value.absent(),
    this.mesoTemplateId = const Value.absent(),
    this.name = const Value.absent(),
    this.workoutCount = const Value.absent(),
  });
  WeekTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required int mesoTemplateId,
    required String name,
    required int workoutCount,
  }) : mesoTemplateId = Value(mesoTemplateId),
       name = Value(name),
       workoutCount = Value(workoutCount);
  static Insertable<WeekTemplate> custom({
    Expression<int>? id,
    Expression<int>? mesoTemplateId,
    Expression<String>? name,
    Expression<int>? workoutCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mesoTemplateId != null) 'meso_template_id': mesoTemplateId,
      if (name != null) 'name': name,
      if (workoutCount != null) 'workout_count': workoutCount,
    });
  }

  WeekTemplatesCompanion copyWith({
    Value<int>? id,
    Value<int>? mesoTemplateId,
    Value<String>? name,
    Value<int>? workoutCount,
  }) {
    return WeekTemplatesCompanion(
      id: id ?? this.id,
      mesoTemplateId: mesoTemplateId ?? this.mesoTemplateId,
      name: name ?? this.name,
      workoutCount: workoutCount ?? this.workoutCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mesoTemplateId.present) {
      map['meso_template_id'] = Variable<int>(mesoTemplateId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (workoutCount.present) {
      map['workout_count'] = Variable<int>(workoutCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeekTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('mesoTemplateId: $mesoTemplateId, ')
          ..write('name: $name, ')
          ..write('workoutCount: $workoutCount')
          ..write(')'))
        .toString();
  }
}

class $WorkoutTemplatesTable extends WorkoutTemplates
    with TableInfo<$WorkoutTemplatesTable, WorkoutTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutTemplatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _weekTemplateIdMeta = const VerificationMeta(
    'weekTemplateId',
  );
  @override
  late final GeneratedColumn<int> weekTemplateId = GeneratedColumn<int>(
    'week_template_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES week_templates (id)',
    ),
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
  static const VerificationMeta _isRestDayMeta = const VerificationMeta(
    'isRestDay',
  );
  @override
  late final GeneratedColumn<bool> isRestDay = GeneratedColumn<bool>(
    'is_rest_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_rest_day" IN (0, 1))',
    ),
  );
  static const VerificationMeta _dayIndexMeta = const VerificationMeta(
    'dayIndex',
  );
  @override
  late final GeneratedColumn<int> dayIndex = GeneratedColumn<int>(
    'day_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    weekTemplateId,
    name,
    isRestDay,
    dayIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('week_template_id')) {
      context.handle(
        _weekTemplateIdMeta,
        weekTemplateId.isAcceptableOrUnknown(
          data['week_template_id']!,
          _weekTemplateIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_weekTemplateIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_rest_day')) {
      context.handle(
        _isRestDayMeta,
        isRestDay.isAcceptableOrUnknown(data['is_rest_day']!, _isRestDayMeta),
      );
    } else if (isInserting) {
      context.missing(_isRestDayMeta);
    }
    if (data.containsKey('day_index')) {
      context.handle(
        _dayIndexMeta,
        dayIndex.isAcceptableOrUnknown(data['day_index']!, _dayIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_dayIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      weekTemplateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}week_template_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isRestDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_rest_day'],
      )!,
      dayIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_index'],
      )!,
    );
  }

  @override
  $WorkoutTemplatesTable createAlias(String alias) {
    return $WorkoutTemplatesTable(attachedDatabase, alias);
  }
}

class WorkoutTemplate extends DataClass implements Insertable<WorkoutTemplate> {
  final int id;
  final int weekTemplateId;
  final String name;
  final bool isRestDay;
  final int dayIndex;
  const WorkoutTemplate({
    required this.id,
    required this.weekTemplateId,
    required this.name,
    required this.isRestDay,
    required this.dayIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['week_template_id'] = Variable<int>(weekTemplateId);
    map['name'] = Variable<String>(name);
    map['is_rest_day'] = Variable<bool>(isRestDay);
    map['day_index'] = Variable<int>(dayIndex);
    return map;
  }

  WorkoutTemplatesCompanion toCompanion(bool nullToAbsent) {
    return WorkoutTemplatesCompanion(
      id: Value(id),
      weekTemplateId: Value(weekTemplateId),
      name: Value(name),
      isRestDay: Value(isRestDay),
      dayIndex: Value(dayIndex),
    );
  }

  factory WorkoutTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutTemplate(
      id: serializer.fromJson<int>(json['id']),
      weekTemplateId: serializer.fromJson<int>(json['weekTemplateId']),
      name: serializer.fromJson<String>(json['name']),
      isRestDay: serializer.fromJson<bool>(json['isRestDay']),
      dayIndex: serializer.fromJson<int>(json['dayIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'weekTemplateId': serializer.toJson<int>(weekTemplateId),
      'name': serializer.toJson<String>(name),
      'isRestDay': serializer.toJson<bool>(isRestDay),
      'dayIndex': serializer.toJson<int>(dayIndex),
    };
  }

  WorkoutTemplate copyWith({
    int? id,
    int? weekTemplateId,
    String? name,
    bool? isRestDay,
    int? dayIndex,
  }) => WorkoutTemplate(
    id: id ?? this.id,
    weekTemplateId: weekTemplateId ?? this.weekTemplateId,
    name: name ?? this.name,
    isRestDay: isRestDay ?? this.isRestDay,
    dayIndex: dayIndex ?? this.dayIndex,
  );
  WorkoutTemplate copyWithCompanion(WorkoutTemplatesCompanion data) {
    return WorkoutTemplate(
      id: data.id.present ? data.id.value : this.id,
      weekTemplateId: data.weekTemplateId.present
          ? data.weekTemplateId.value
          : this.weekTemplateId,
      name: data.name.present ? data.name.value : this.name,
      isRestDay: data.isRestDay.present ? data.isRestDay.value : this.isRestDay,
      dayIndex: data.dayIndex.present ? data.dayIndex.value : this.dayIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplate(')
          ..write('id: $id, ')
          ..write('weekTemplateId: $weekTemplateId, ')
          ..write('name: $name, ')
          ..write('isRestDay: $isRestDay, ')
          ..write('dayIndex: $dayIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, weekTemplateId, name, isRestDay, dayIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutTemplate &&
          other.id == this.id &&
          other.weekTemplateId == this.weekTemplateId &&
          other.name == this.name &&
          other.isRestDay == this.isRestDay &&
          other.dayIndex == this.dayIndex);
}

class WorkoutTemplatesCompanion extends UpdateCompanion<WorkoutTemplate> {
  final Value<int> id;
  final Value<int> weekTemplateId;
  final Value<String> name;
  final Value<bool> isRestDay;
  final Value<int> dayIndex;
  const WorkoutTemplatesCompanion({
    this.id = const Value.absent(),
    this.weekTemplateId = const Value.absent(),
    this.name = const Value.absent(),
    this.isRestDay = const Value.absent(),
    this.dayIndex = const Value.absent(),
  });
  WorkoutTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required int weekTemplateId,
    required String name,
    required bool isRestDay,
    required int dayIndex,
  }) : weekTemplateId = Value(weekTemplateId),
       name = Value(name),
       isRestDay = Value(isRestDay),
       dayIndex = Value(dayIndex);
  static Insertable<WorkoutTemplate> custom({
    Expression<int>? id,
    Expression<int>? weekTemplateId,
    Expression<String>? name,
    Expression<bool>? isRestDay,
    Expression<int>? dayIndex,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weekTemplateId != null) 'week_template_id': weekTemplateId,
      if (name != null) 'name': name,
      if (isRestDay != null) 'is_rest_day': isRestDay,
      if (dayIndex != null) 'day_index': dayIndex,
    });
  }

  WorkoutTemplatesCompanion copyWith({
    Value<int>? id,
    Value<int>? weekTemplateId,
    Value<String>? name,
    Value<bool>? isRestDay,
    Value<int>? dayIndex,
  }) {
    return WorkoutTemplatesCompanion(
      id: id ?? this.id,
      weekTemplateId: weekTemplateId ?? this.weekTemplateId,
      name: name ?? this.name,
      isRestDay: isRestDay ?? this.isRestDay,
      dayIndex: dayIndex ?? this.dayIndex,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (weekTemplateId.present) {
      map['week_template_id'] = Variable<int>(weekTemplateId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isRestDay.present) {
      map['is_rest_day'] = Variable<bool>(isRestDay.value);
    }
    if (dayIndex.present) {
      map['day_index'] = Variable<int>(dayIndex.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('weekTemplateId: $weekTemplateId, ')
          ..write('name: $name, ')
          ..write('isRestDay: $isRestDay, ')
          ..write('dayIndex: $dayIndex')
          ..write(')'))
        .toString();
  }
}

class $ExerciseTemplatesTable extends ExerciseTemplates
    with TableInfo<$ExerciseTemplatesTable, ExerciseTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseTemplatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _workoutTemplateIdMeta = const VerificationMeta(
    'workoutTemplateId',
  );
  @override
  late final GeneratedColumn<int> workoutTemplateId = GeneratedColumn<int>(
    'workout_template_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workout_templates (id)',
    ),
  );
  static const VerificationMeta _movementIdMeta = const VerificationMeta(
    'movementId',
  );
  @override
  late final GeneratedColumn<int> movementId = GeneratedColumn<int>(
    'movement_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES movements (id)',
    ),
  );
  static const VerificationMeta _exerciseIndexMeta = const VerificationMeta(
    'exerciseIndex',
  );
  @override
  late final GeneratedColumn<int> exerciseIndex = GeneratedColumn<int>(
    'exercise_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workoutTemplateId,
    movementId,
    exerciseIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('workout_template_id')) {
      context.handle(
        _workoutTemplateIdMeta,
        workoutTemplateId.isAcceptableOrUnknown(
          data['workout_template_id']!,
          _workoutTemplateIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workoutTemplateIdMeta);
    }
    if (data.containsKey('movement_id')) {
      context.handle(
        _movementIdMeta,
        movementId.isAcceptableOrUnknown(data['movement_id']!, _movementIdMeta),
      );
    } else if (isInserting) {
      context.missing(_movementIdMeta);
    }
    if (data.containsKey('exercise_index')) {
      context.handle(
        _exerciseIndexMeta,
        exerciseIndex.isAcceptableOrUnknown(
          data['exercise_index']!,
          _exerciseIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      workoutTemplateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}workout_template_id'],
      )!,
      movementId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}movement_id'],
      )!,
      exerciseIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_index'],
      )!,
    );
  }

  @override
  $ExerciseTemplatesTable createAlias(String alias) {
    return $ExerciseTemplatesTable(attachedDatabase, alias);
  }
}

class ExerciseTemplate extends DataClass
    implements Insertable<ExerciseTemplate> {
  final int id;
  final int workoutTemplateId;
  final int movementId;
  final int exerciseIndex;
  const ExerciseTemplate({
    required this.id,
    required this.workoutTemplateId,
    required this.movementId,
    required this.exerciseIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['workout_template_id'] = Variable<int>(workoutTemplateId);
    map['movement_id'] = Variable<int>(movementId);
    map['exercise_index'] = Variable<int>(exerciseIndex);
    return map;
  }

  ExerciseTemplatesCompanion toCompanion(bool nullToAbsent) {
    return ExerciseTemplatesCompanion(
      id: Value(id),
      workoutTemplateId: Value(workoutTemplateId),
      movementId: Value(movementId),
      exerciseIndex: Value(exerciseIndex),
    );
  }

  factory ExerciseTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseTemplate(
      id: serializer.fromJson<int>(json['id']),
      workoutTemplateId: serializer.fromJson<int>(json['workoutTemplateId']),
      movementId: serializer.fromJson<int>(json['movementId']),
      exerciseIndex: serializer.fromJson<int>(json['exerciseIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'workoutTemplateId': serializer.toJson<int>(workoutTemplateId),
      'movementId': serializer.toJson<int>(movementId),
      'exerciseIndex': serializer.toJson<int>(exerciseIndex),
    };
  }

  ExerciseTemplate copyWith({
    int? id,
    int? workoutTemplateId,
    int? movementId,
    int? exerciseIndex,
  }) => ExerciseTemplate(
    id: id ?? this.id,
    workoutTemplateId: workoutTemplateId ?? this.workoutTemplateId,
    movementId: movementId ?? this.movementId,
    exerciseIndex: exerciseIndex ?? this.exerciseIndex,
  );
  ExerciseTemplate copyWithCompanion(ExerciseTemplatesCompanion data) {
    return ExerciseTemplate(
      id: data.id.present ? data.id.value : this.id,
      workoutTemplateId: data.workoutTemplateId.present
          ? data.workoutTemplateId.value
          : this.workoutTemplateId,
      movementId: data.movementId.present
          ? data.movementId.value
          : this.movementId,
      exerciseIndex: data.exerciseIndex.present
          ? data.exerciseIndex.value
          : this.exerciseIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseTemplate(')
          ..write('id: $id, ')
          ..write('workoutTemplateId: $workoutTemplateId, ')
          ..write('movementId: $movementId, ')
          ..write('exerciseIndex: $exerciseIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, workoutTemplateId, movementId, exerciseIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseTemplate &&
          other.id == this.id &&
          other.workoutTemplateId == this.workoutTemplateId &&
          other.movementId == this.movementId &&
          other.exerciseIndex == this.exerciseIndex);
}

class ExerciseTemplatesCompanion extends UpdateCompanion<ExerciseTemplate> {
  final Value<int> id;
  final Value<int> workoutTemplateId;
  final Value<int> movementId;
  final Value<int> exerciseIndex;
  const ExerciseTemplatesCompanion({
    this.id = const Value.absent(),
    this.workoutTemplateId = const Value.absent(),
    this.movementId = const Value.absent(),
    this.exerciseIndex = const Value.absent(),
  });
  ExerciseTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required int workoutTemplateId,
    required int movementId,
    required int exerciseIndex,
  }) : workoutTemplateId = Value(workoutTemplateId),
       movementId = Value(movementId),
       exerciseIndex = Value(exerciseIndex);
  static Insertable<ExerciseTemplate> custom({
    Expression<int>? id,
    Expression<int>? workoutTemplateId,
    Expression<int>? movementId,
    Expression<int>? exerciseIndex,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutTemplateId != null) 'workout_template_id': workoutTemplateId,
      if (movementId != null) 'movement_id': movementId,
      if (exerciseIndex != null) 'exercise_index': exerciseIndex,
    });
  }

  ExerciseTemplatesCompanion copyWith({
    Value<int>? id,
    Value<int>? workoutTemplateId,
    Value<int>? movementId,
    Value<int>? exerciseIndex,
  }) {
    return ExerciseTemplatesCompanion(
      id: id ?? this.id,
      workoutTemplateId: workoutTemplateId ?? this.workoutTemplateId,
      movementId: movementId ?? this.movementId,
      exerciseIndex: exerciseIndex ?? this.exerciseIndex,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (workoutTemplateId.present) {
      map['workout_template_id'] = Variable<int>(workoutTemplateId.value);
    }
    if (movementId.present) {
      map['movement_id'] = Variable<int>(movementId.value);
    }
    if (exerciseIndex.present) {
      map['exercise_index'] = Variable<int>(exerciseIndex.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('workoutTemplateId: $workoutTemplateId, ')
          ..write('movementId: $movementId, ')
          ..write('exerciseIndex: $exerciseIndex')
          ..write(')'))
        .toString();
  }
}

class $MesocyclesTable extends Mesocycles
    with TableInfo<$MesocyclesTable, Mesocycle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MesocyclesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _mesoTemplateIdMeta = const VerificationMeta(
    'mesoTemplateId',
  );
  @override
  late final GeneratedColumn<int> mesoTemplateId = GeneratedColumn<int>(
    'meso_template_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES meso_templates (id)',
    ),
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
  static const VerificationMeta _totalWeekCountMeta = const VerificationMeta(
    'totalWeekCount',
  );
  @override
  late final GeneratedColumn<int> totalWeekCount = GeneratedColumn<int>(
    'total_week_count',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mesoTemplateId,
    name,
    totalWeekCount,
    createdAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mesocycles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Mesocycle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('meso_template_id')) {
      context.handle(
        _mesoTemplateIdMeta,
        mesoTemplateId.isAcceptableOrUnknown(
          data['meso_template_id']!,
          _mesoTemplateIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mesoTemplateIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('total_week_count')) {
      context.handle(
        _totalWeekCountMeta,
        totalWeekCount.isAcceptableOrUnknown(
          data['total_week_count']!,
          _totalWeekCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalWeekCountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Mesocycle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Mesocycle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      mesoTemplateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meso_template_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      totalWeekCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_week_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $MesocyclesTable createAlias(String alias) {
    return $MesocyclesTable(attachedDatabase, alias);
  }
}

class Mesocycle extends DataClass implements Insertable<Mesocycle> {
  final int id;
  final int mesoTemplateId;
  final String name;
  final int totalWeekCount;
  final DateTime createdAt;
  final DateTime? completedAt;
  const Mesocycle({
    required this.id,
    required this.mesoTemplateId,
    required this.name,
    required this.totalWeekCount,
    required this.createdAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['meso_template_id'] = Variable<int>(mesoTemplateId);
    map['name'] = Variable<String>(name);
    map['total_week_count'] = Variable<int>(totalWeekCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  MesocyclesCompanion toCompanion(bool nullToAbsent) {
    return MesocyclesCompanion(
      id: Value(id),
      mesoTemplateId: Value(mesoTemplateId),
      name: Value(name),
      totalWeekCount: Value(totalWeekCount),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory Mesocycle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Mesocycle(
      id: serializer.fromJson<int>(json['id']),
      mesoTemplateId: serializer.fromJson<int>(json['mesoTemplateId']),
      name: serializer.fromJson<String>(json['name']),
      totalWeekCount: serializer.fromJson<int>(json['totalWeekCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mesoTemplateId': serializer.toJson<int>(mesoTemplateId),
      'name': serializer.toJson<String>(name),
      'totalWeekCount': serializer.toJson<int>(totalWeekCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  Mesocycle copyWith({
    int? id,
    int? mesoTemplateId,
    String? name,
    int? totalWeekCount,
    DateTime? createdAt,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => Mesocycle(
    id: id ?? this.id,
    mesoTemplateId: mesoTemplateId ?? this.mesoTemplateId,
    name: name ?? this.name,
    totalWeekCount: totalWeekCount ?? this.totalWeekCount,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  Mesocycle copyWithCompanion(MesocyclesCompanion data) {
    return Mesocycle(
      id: data.id.present ? data.id.value : this.id,
      mesoTemplateId: data.mesoTemplateId.present
          ? data.mesoTemplateId.value
          : this.mesoTemplateId,
      name: data.name.present ? data.name.value : this.name,
      totalWeekCount: data.totalWeekCount.present
          ? data.totalWeekCount.value
          : this.totalWeekCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Mesocycle(')
          ..write('id: $id, ')
          ..write('mesoTemplateId: $mesoTemplateId, ')
          ..write('name: $name, ')
          ..write('totalWeekCount: $totalWeekCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mesoTemplateId,
    name,
    totalWeekCount,
    createdAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Mesocycle &&
          other.id == this.id &&
          other.mesoTemplateId == this.mesoTemplateId &&
          other.name == this.name &&
          other.totalWeekCount == this.totalWeekCount &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt);
}

class MesocyclesCompanion extends UpdateCompanion<Mesocycle> {
  final Value<int> id;
  final Value<int> mesoTemplateId;
  final Value<String> name;
  final Value<int> totalWeekCount;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  const MesocyclesCompanion({
    this.id = const Value.absent(),
    this.mesoTemplateId = const Value.absent(),
    this.name = const Value.absent(),
    this.totalWeekCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  MesocyclesCompanion.insert({
    this.id = const Value.absent(),
    required int mesoTemplateId,
    required String name,
    required int totalWeekCount,
    required DateTime createdAt,
    this.completedAt = const Value.absent(),
  }) : mesoTemplateId = Value(mesoTemplateId),
       name = Value(name),
       totalWeekCount = Value(totalWeekCount),
       createdAt = Value(createdAt);
  static Insertable<Mesocycle> custom({
    Expression<int>? id,
    Expression<int>? mesoTemplateId,
    Expression<String>? name,
    Expression<int>? totalWeekCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mesoTemplateId != null) 'meso_template_id': mesoTemplateId,
      if (name != null) 'name': name,
      if (totalWeekCount != null) 'total_week_count': totalWeekCount,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  MesocyclesCompanion copyWith({
    Value<int>? id,
    Value<int>? mesoTemplateId,
    Value<String>? name,
    Value<int>? totalWeekCount,
    Value<DateTime>? createdAt,
    Value<DateTime?>? completedAt,
  }) {
    return MesocyclesCompanion(
      id: id ?? this.id,
      mesoTemplateId: mesoTemplateId ?? this.mesoTemplateId,
      name: name ?? this.name,
      totalWeekCount: totalWeekCount ?? this.totalWeekCount,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mesoTemplateId.present) {
      map['meso_template_id'] = Variable<int>(mesoTemplateId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (totalWeekCount.present) {
      map['total_week_count'] = Variable<int>(totalWeekCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MesocyclesCompanion(')
          ..write('id: $id, ')
          ..write('mesoTemplateId: $mesoTemplateId, ')
          ..write('name: $name, ')
          ..write('totalWeekCount: $totalWeekCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $WeeksTable extends Weeks with TableInfo<$WeeksTable, Week> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeeksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _mesocycleIdMeta = const VerificationMeta(
    'mesocycleId',
  );
  @override
  late final GeneratedColumn<int> mesocycleId = GeneratedColumn<int>(
    'mesocycle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES mesocycles (id)',
    ),
  );
  static const VerificationMeta _weekNumberMeta = const VerificationMeta(
    'weekNumber',
  );
  @override
  late final GeneratedColumn<int> weekNumber = GeneratedColumn<int>(
    'week_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WeekGoal, String> goal =
      GeneratedColumn<String>(
        'goal',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WeekGoal>($WeeksTable.$convertergoal);
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
    mesocycleId,
    weekNumber,
    goal,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weeks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Week> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('mesocycle_id')) {
      context.handle(
        _mesocycleIdMeta,
        mesocycleId.isAcceptableOrUnknown(
          data['mesocycle_id']!,
          _mesocycleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mesocycleIdMeta);
    }
    if (data.containsKey('week_number')) {
      context.handle(
        _weekNumberMeta,
        weekNumber.isAcceptableOrUnknown(data['week_number']!, _weekNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_weekNumberMeta);
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {mesocycleId, weekNumber},
  ];
  @override
  Week map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Week(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      mesocycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mesocycle_id'],
      )!,
      weekNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}week_number'],
      )!,
      goal: $WeeksTable.$convertergoal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}goal'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WeeksTable createAlias(String alias) {
    return $WeeksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WeekGoal, String, String> $convertergoal =
      const EnumNameConverter<WeekGoal>(WeekGoal.values);
}

class Week extends DataClass implements Insertable<Week> {
  final int id;
  final int mesocycleId;
  final int weekNumber;
  final WeekGoal goal;
  final DateTime createdAt;
  const Week({
    required this.id,
    required this.mesocycleId,
    required this.weekNumber,
    required this.goal,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['mesocycle_id'] = Variable<int>(mesocycleId);
    map['week_number'] = Variable<int>(weekNumber);
    {
      map['goal'] = Variable<String>($WeeksTable.$convertergoal.toSql(goal));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WeeksCompanion toCompanion(bool nullToAbsent) {
    return WeeksCompanion(
      id: Value(id),
      mesocycleId: Value(mesocycleId),
      weekNumber: Value(weekNumber),
      goal: Value(goal),
      createdAt: Value(createdAt),
    );
  }

  factory Week.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Week(
      id: serializer.fromJson<int>(json['id']),
      mesocycleId: serializer.fromJson<int>(json['mesocycleId']),
      weekNumber: serializer.fromJson<int>(json['weekNumber']),
      goal: $WeeksTable.$convertergoal.fromJson(
        serializer.fromJson<String>(json['goal']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mesocycleId': serializer.toJson<int>(mesocycleId),
      'weekNumber': serializer.toJson<int>(weekNumber),
      'goal': serializer.toJson<String>(
        $WeeksTable.$convertergoal.toJson(goal),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Week copyWith({
    int? id,
    int? mesocycleId,
    int? weekNumber,
    WeekGoal? goal,
    DateTime? createdAt,
  }) => Week(
    id: id ?? this.id,
    mesocycleId: mesocycleId ?? this.mesocycleId,
    weekNumber: weekNumber ?? this.weekNumber,
    goal: goal ?? this.goal,
    createdAt: createdAt ?? this.createdAt,
  );
  Week copyWithCompanion(WeeksCompanion data) {
    return Week(
      id: data.id.present ? data.id.value : this.id,
      mesocycleId: data.mesocycleId.present
          ? data.mesocycleId.value
          : this.mesocycleId,
      weekNumber: data.weekNumber.present
          ? data.weekNumber.value
          : this.weekNumber,
      goal: data.goal.present ? data.goal.value : this.goal,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Week(')
          ..write('id: $id, ')
          ..write('mesocycleId: $mesocycleId, ')
          ..write('weekNumber: $weekNumber, ')
          ..write('goal: $goal, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, mesocycleId, weekNumber, goal, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Week &&
          other.id == this.id &&
          other.mesocycleId == this.mesocycleId &&
          other.weekNumber == this.weekNumber &&
          other.goal == this.goal &&
          other.createdAt == this.createdAt);
}

class WeeksCompanion extends UpdateCompanion<Week> {
  final Value<int> id;
  final Value<int> mesocycleId;
  final Value<int> weekNumber;
  final Value<WeekGoal> goal;
  final Value<DateTime> createdAt;
  const WeeksCompanion({
    this.id = const Value.absent(),
    this.mesocycleId = const Value.absent(),
    this.weekNumber = const Value.absent(),
    this.goal = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WeeksCompanion.insert({
    this.id = const Value.absent(),
    required int mesocycleId,
    required int weekNumber,
    required WeekGoal goal,
    required DateTime createdAt,
  }) : mesocycleId = Value(mesocycleId),
       weekNumber = Value(weekNumber),
       goal = Value(goal),
       createdAt = Value(createdAt);
  static Insertable<Week> custom({
    Expression<int>? id,
    Expression<int>? mesocycleId,
    Expression<int>? weekNumber,
    Expression<String>? goal,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mesocycleId != null) 'mesocycle_id': mesocycleId,
      if (weekNumber != null) 'week_number': weekNumber,
      if (goal != null) 'goal': goal,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WeeksCompanion copyWith({
    Value<int>? id,
    Value<int>? mesocycleId,
    Value<int>? weekNumber,
    Value<WeekGoal>? goal,
    Value<DateTime>? createdAt,
  }) {
    return WeeksCompanion(
      id: id ?? this.id,
      mesocycleId: mesocycleId ?? this.mesocycleId,
      weekNumber: weekNumber ?? this.weekNumber,
      goal: goal ?? this.goal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mesocycleId.present) {
      map['mesocycle_id'] = Variable<int>(mesocycleId.value);
    }
    if (weekNumber.present) {
      map['week_number'] = Variable<int>(weekNumber.value);
    }
    if (goal.present) {
      map['goal'] = Variable<String>(
        $WeeksTable.$convertergoal.toSql(goal.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeeksCompanion(')
          ..write('id: $id, ')
          ..write('mesocycleId: $mesocycleId, ')
          ..write('weekNumber: $weekNumber, ')
          ..write('goal: $goal, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WorkoutsTable extends Workouts with TableInfo<$WorkoutsTable, Workout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _weekIdMeta = const VerificationMeta('weekId');
  @override
  late final GeneratedColumn<int> weekId = GeneratedColumn<int>(
    'week_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES weeks (id)',
    ),
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
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isRestDayMeta = const VerificationMeta(
    'isRestDay',
  );
  @override
  late final GeneratedColumn<bool> isRestDay = GeneratedColumn<bool>(
    'is_rest_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_rest_day" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    weekId,
    name,
    orderIndex,
    isRestDay,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Workout> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('week_id')) {
      context.handle(
        _weekIdMeta,
        weekId.isAcceptableOrUnknown(data['week_id']!, _weekIdMeta),
      );
    } else if (isInserting) {
      context.missing(_weekIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('is_rest_day')) {
      context.handle(
        _isRestDayMeta,
        isRestDay.isAcceptableOrUnknown(data['is_rest_day']!, _isRestDayMeta),
      );
    } else if (isInserting) {
      context.missing(_isRestDayMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {weekId, orderIndex},
  ];
  @override
  Workout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Workout(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      weekId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}week_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      isRestDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_rest_day'],
      )!,
    );
  }

  @override
  $WorkoutsTable createAlias(String alias) {
    return $WorkoutsTable(attachedDatabase, alias);
  }
}

class Workout extends DataClass implements Insertable<Workout> {
  final int id;
  final int weekId;
  final String name;
  final int orderIndex;
  final bool isRestDay;
  const Workout({
    required this.id,
    required this.weekId,
    required this.name,
    required this.orderIndex,
    required this.isRestDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['week_id'] = Variable<int>(weekId);
    map['name'] = Variable<String>(name);
    map['order_index'] = Variable<int>(orderIndex);
    map['is_rest_day'] = Variable<bool>(isRestDay);
    return map;
  }

  WorkoutsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutsCompanion(
      id: Value(id),
      weekId: Value(weekId),
      name: Value(name),
      orderIndex: Value(orderIndex),
      isRestDay: Value(isRestDay),
    );
  }

  factory Workout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Workout(
      id: serializer.fromJson<int>(json['id']),
      weekId: serializer.fromJson<int>(json['weekId']),
      name: serializer.fromJson<String>(json['name']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      isRestDay: serializer.fromJson<bool>(json['isRestDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'weekId': serializer.toJson<int>(weekId),
      'name': serializer.toJson<String>(name),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'isRestDay': serializer.toJson<bool>(isRestDay),
    };
  }

  Workout copyWith({
    int? id,
    int? weekId,
    String? name,
    int? orderIndex,
    bool? isRestDay,
  }) => Workout(
    id: id ?? this.id,
    weekId: weekId ?? this.weekId,
    name: name ?? this.name,
    orderIndex: orderIndex ?? this.orderIndex,
    isRestDay: isRestDay ?? this.isRestDay,
  );
  Workout copyWithCompanion(WorkoutsCompanion data) {
    return Workout(
      id: data.id.present ? data.id.value : this.id,
      weekId: data.weekId.present ? data.weekId.value : this.weekId,
      name: data.name.present ? data.name.value : this.name,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      isRestDay: data.isRestDay.present ? data.isRestDay.value : this.isRestDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Workout(')
          ..write('id: $id, ')
          ..write('weekId: $weekId, ')
          ..write('name: $name, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('isRestDay: $isRestDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, weekId, name, orderIndex, isRestDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Workout &&
          other.id == this.id &&
          other.weekId == this.weekId &&
          other.name == this.name &&
          other.orderIndex == this.orderIndex &&
          other.isRestDay == this.isRestDay);
}

class WorkoutsCompanion extends UpdateCompanion<Workout> {
  final Value<int> id;
  final Value<int> weekId;
  final Value<String> name;
  final Value<int> orderIndex;
  final Value<bool> isRestDay;
  const WorkoutsCompanion({
    this.id = const Value.absent(),
    this.weekId = const Value.absent(),
    this.name = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.isRestDay = const Value.absent(),
  });
  WorkoutsCompanion.insert({
    this.id = const Value.absent(),
    required int weekId,
    required String name,
    required int orderIndex,
    required bool isRestDay,
  }) : weekId = Value(weekId),
       name = Value(name),
       orderIndex = Value(orderIndex),
       isRestDay = Value(isRestDay);
  static Insertable<Workout> custom({
    Expression<int>? id,
    Expression<int>? weekId,
    Expression<String>? name,
    Expression<int>? orderIndex,
    Expression<bool>? isRestDay,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weekId != null) 'week_id': weekId,
      if (name != null) 'name': name,
      if (orderIndex != null) 'order_index': orderIndex,
      if (isRestDay != null) 'is_rest_day': isRestDay,
    });
  }

  WorkoutsCompanion copyWith({
    Value<int>? id,
    Value<int>? weekId,
    Value<String>? name,
    Value<int>? orderIndex,
    Value<bool>? isRestDay,
  }) {
    return WorkoutsCompanion(
      id: id ?? this.id,
      weekId: weekId ?? this.weekId,
      name: name ?? this.name,
      orderIndex: orderIndex ?? this.orderIndex,
      isRestDay: isRestDay ?? this.isRestDay,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (weekId.present) {
      map['week_id'] = Variable<int>(weekId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (isRestDay.present) {
      map['is_rest_day'] = Variable<bool>(isRestDay.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('weekId: $weekId, ')
          ..write('name: $name, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('isRestDay: $isRestDay')
          ..write(')'))
        .toString();
  }
}

class $PlannedWorkoutsTable extends PlannedWorkouts
    with TableInfo<$PlannedWorkoutsTable, PlannedWorkout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannedWorkoutsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _workoutIdMeta = const VerificationMeta(
    'workoutId',
  );
  @override
  late final GeneratedColumn<int> workoutId = GeneratedColumn<int>(
    'workout_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES workouts (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, workoutId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planned_workouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannedWorkout> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlannedWorkout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannedWorkout(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}workout_id'],
      )!,
    );
  }

  @override
  $PlannedWorkoutsTable createAlias(String alias) {
    return $PlannedWorkoutsTable(attachedDatabase, alias);
  }
}

class PlannedWorkout extends DataClass implements Insertable<PlannedWorkout> {
  final int id;
  final int workoutId;
  const PlannedWorkout({required this.id, required this.workoutId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['workout_id'] = Variable<int>(workoutId);
    return map;
  }

  PlannedWorkoutsCompanion toCompanion(bool nullToAbsent) {
    return PlannedWorkoutsCompanion(id: Value(id), workoutId: Value(workoutId));
  }

  factory PlannedWorkout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannedWorkout(
      id: serializer.fromJson<int>(json['id']),
      workoutId: serializer.fromJson<int>(json['workoutId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'workoutId': serializer.toJson<int>(workoutId),
    };
  }

  PlannedWorkout copyWith({int? id, int? workoutId}) =>
      PlannedWorkout(id: id ?? this.id, workoutId: workoutId ?? this.workoutId);
  PlannedWorkout copyWithCompanion(PlannedWorkoutsCompanion data) {
    return PlannedWorkout(
      id: data.id.present ? data.id.value : this.id,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannedWorkout(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, workoutId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannedWorkout &&
          other.id == this.id &&
          other.workoutId == this.workoutId);
}

class PlannedWorkoutsCompanion extends UpdateCompanion<PlannedWorkout> {
  final Value<int> id;
  final Value<int> workoutId;
  const PlannedWorkoutsCompanion({
    this.id = const Value.absent(),
    this.workoutId = const Value.absent(),
  });
  PlannedWorkoutsCompanion.insert({
    this.id = const Value.absent(),
    required int workoutId,
  }) : workoutId = Value(workoutId);
  static Insertable<PlannedWorkout> custom({
    Expression<int>? id,
    Expression<int>? workoutId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutId != null) 'workout_id': workoutId,
    });
  }

  PlannedWorkoutsCompanion copyWith({Value<int>? id, Value<int>? workoutId}) {
    return PlannedWorkoutsCompanion(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<int>(workoutId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannedWorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId')
          ..write(')'))
        .toString();
  }
}

class $CompletedWorkoutsTable extends CompletedWorkouts
    with TableInfo<$CompletedWorkoutsTable, CompletedWorkout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletedWorkoutsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _workoutIdMeta = const VerificationMeta(
    'workoutId',
  );
  @override
  late final GeneratedColumn<int> workoutId = GeneratedColumn<int>(
    'workout_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES workouts (id)',
    ),
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
  @override
  late final GeneratedColumnWithTypeConverter<WorkoutStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WorkoutStatus>($CompletedWorkoutsTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<WorkoutSkipReason?, String>
  skipReason =
      GeneratedColumn<String>(
        'skip_reason',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<WorkoutSkipReason?>(
        $CompletedWorkoutsTable.$converterskipReasonn,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workoutId,
    startedAt,
    completedAt,
    status,
    skipReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completed_workouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompletedWorkout> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompletedWorkout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompletedWorkout(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}workout_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      status: $CompletedWorkoutsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      skipReason: $CompletedWorkoutsTable.$converterskipReasonn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}skip_reason'],
        ),
      ),
    );
  }

  @override
  $CompletedWorkoutsTable createAlias(String alias) {
    return $CompletedWorkoutsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WorkoutStatus, String, String> $converterstatus =
      const EnumNameConverter<WorkoutStatus>(WorkoutStatus.values);
  static JsonTypeConverter2<WorkoutSkipReason, String, String>
  $converterskipReason = const EnumNameConverter<WorkoutSkipReason>(
    WorkoutSkipReason.values,
  );
  static JsonTypeConverter2<WorkoutSkipReason?, String?, String?>
  $converterskipReasonn = JsonTypeConverter2.asNullable($converterskipReason);
}

class CompletedWorkout extends DataClass
    implements Insertable<CompletedWorkout> {
  final int id;
  final int workoutId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final WorkoutStatus status;
  final WorkoutSkipReason? skipReason;
  const CompletedWorkout({
    required this.id,
    required this.workoutId,
    required this.startedAt,
    this.completedAt,
    required this.status,
    this.skipReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['workout_id'] = Variable<int>(workoutId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    {
      map['status'] = Variable<String>(
        $CompletedWorkoutsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || skipReason != null) {
      map['skip_reason'] = Variable<String>(
        $CompletedWorkoutsTable.$converterskipReasonn.toSql(skipReason),
      );
    }
    return map;
  }

  CompletedWorkoutsCompanion toCompanion(bool nullToAbsent) {
    return CompletedWorkoutsCompanion(
      id: Value(id),
      workoutId: Value(workoutId),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      status: Value(status),
      skipReason: skipReason == null && nullToAbsent
          ? const Value.absent()
          : Value(skipReason),
    );
  }

  factory CompletedWorkout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompletedWorkout(
      id: serializer.fromJson<int>(json['id']),
      workoutId: serializer.fromJson<int>(json['workoutId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      status: $CompletedWorkoutsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      skipReason: $CompletedWorkoutsTable.$converterskipReasonn.fromJson(
        serializer.fromJson<String?>(json['skipReason']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'workoutId': serializer.toJson<int>(workoutId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'status': serializer.toJson<String>(
        $CompletedWorkoutsTable.$converterstatus.toJson(status),
      ),
      'skipReason': serializer.toJson<String?>(
        $CompletedWorkoutsTable.$converterskipReasonn.toJson(skipReason),
      ),
    };
  }

  CompletedWorkout copyWith({
    int? id,
    int? workoutId,
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    WorkoutStatus? status,
    Value<WorkoutSkipReason?> skipReason = const Value.absent(),
  }) => CompletedWorkout(
    id: id ?? this.id,
    workoutId: workoutId ?? this.workoutId,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    status: status ?? this.status,
    skipReason: skipReason.present ? skipReason.value : this.skipReason,
  );
  CompletedWorkout copyWithCompanion(CompletedWorkoutsCompanion data) {
    return CompletedWorkout(
      id: data.id.present ? data.id.value : this.id,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      status: data.status.present ? data.status.value : this.status,
      skipReason: data.skipReason.present
          ? data.skipReason.value
          : this.skipReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompletedWorkout(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('status: $status, ')
          ..write('skipReason: $skipReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, workoutId, startedAt, completedAt, status, skipReason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompletedWorkout &&
          other.id == this.id &&
          other.workoutId == this.workoutId &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.status == this.status &&
          other.skipReason == this.skipReason);
}

class CompletedWorkoutsCompanion extends UpdateCompanion<CompletedWorkout> {
  final Value<int> id;
  final Value<int> workoutId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<WorkoutStatus> status;
  final Value<WorkoutSkipReason?> skipReason;
  const CompletedWorkoutsCompanion({
    this.id = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.skipReason = const Value.absent(),
  });
  CompletedWorkoutsCompanion.insert({
    this.id = const Value.absent(),
    required int workoutId,
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    required WorkoutStatus status,
    this.skipReason = const Value.absent(),
  }) : workoutId = Value(workoutId),
       startedAt = Value(startedAt),
       status = Value(status);
  static Insertable<CompletedWorkout> custom({
    Expression<int>? id,
    Expression<int>? workoutId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<String>? status,
    Expression<String>? skipReason,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutId != null) 'workout_id': workoutId,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (status != null) 'status': status,
      if (skipReason != null) 'skip_reason': skipReason,
    });
  }

  CompletedWorkoutsCompanion copyWith({
    Value<int>? id,
    Value<int>? workoutId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
    Value<WorkoutStatus>? status,
    Value<WorkoutSkipReason?>? skipReason,
  }) {
    return CompletedWorkoutsCompanion(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      skipReason: skipReason ?? this.skipReason,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<int>(workoutId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $CompletedWorkoutsTable.$converterstatus.toSql(status.value),
      );
    }
    if (skipReason.present) {
      map['skip_reason'] = Variable<String>(
        $CompletedWorkoutsTable.$converterskipReasonn.toSql(skipReason.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletedWorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('status: $status, ')
          ..write('skipReason: $skipReason')
          ..write(')'))
        .toString();
  }
}

class $PlannedExercisesTable extends PlannedExercises
    with TableInfo<$PlannedExercisesTable, PlannedExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannedExercisesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _plannedWorkoutIdMeta = const VerificationMeta(
    'plannedWorkoutId',
  );
  @override
  late final GeneratedColumn<int> plannedWorkoutId = GeneratedColumn<int>(
    'planned_workout_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES planned_workouts (id)',
    ),
  );
  static const VerificationMeta _movementIdMeta = const VerificationMeta(
    'movementId',
  );
  @override
  late final GeneratedColumn<int> movementId = GeneratedColumn<int>(
    'movement_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES movements (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, plannedWorkoutId, movementId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planned_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannedExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('planned_workout_id')) {
      context.handle(
        _plannedWorkoutIdMeta,
        plannedWorkoutId.isAcceptableOrUnknown(
          data['planned_workout_id']!,
          _plannedWorkoutIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedWorkoutIdMeta);
    }
    if (data.containsKey('movement_id')) {
      context.handle(
        _movementIdMeta,
        movementId.isAcceptableOrUnknown(data['movement_id']!, _movementIdMeta),
      );
    } else if (isInserting) {
      context.missing(_movementIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlannedExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannedExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      plannedWorkoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_workout_id'],
      )!,
      movementId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}movement_id'],
      )!,
    );
  }

  @override
  $PlannedExercisesTable createAlias(String alias) {
    return $PlannedExercisesTable(attachedDatabase, alias);
  }
}

class PlannedExercise extends DataClass implements Insertable<PlannedExercise> {
  final int id;
  final int plannedWorkoutId;
  final int movementId;
  const PlannedExercise({
    required this.id,
    required this.plannedWorkoutId,
    required this.movementId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['planned_workout_id'] = Variable<int>(plannedWorkoutId);
    map['movement_id'] = Variable<int>(movementId);
    return map;
  }

  PlannedExercisesCompanion toCompanion(bool nullToAbsent) {
    return PlannedExercisesCompanion(
      id: Value(id),
      plannedWorkoutId: Value(plannedWorkoutId),
      movementId: Value(movementId),
    );
  }

  factory PlannedExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannedExercise(
      id: serializer.fromJson<int>(json['id']),
      plannedWorkoutId: serializer.fromJson<int>(json['plannedWorkoutId']),
      movementId: serializer.fromJson<int>(json['movementId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'plannedWorkoutId': serializer.toJson<int>(plannedWorkoutId),
      'movementId': serializer.toJson<int>(movementId),
    };
  }

  PlannedExercise copyWith({int? id, int? plannedWorkoutId, int? movementId}) =>
      PlannedExercise(
        id: id ?? this.id,
        plannedWorkoutId: plannedWorkoutId ?? this.plannedWorkoutId,
        movementId: movementId ?? this.movementId,
      );
  PlannedExercise copyWithCompanion(PlannedExercisesCompanion data) {
    return PlannedExercise(
      id: data.id.present ? data.id.value : this.id,
      plannedWorkoutId: data.plannedWorkoutId.present
          ? data.plannedWorkoutId.value
          : this.plannedWorkoutId,
      movementId: data.movementId.present
          ? data.movementId.value
          : this.movementId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannedExercise(')
          ..write('id: $id, ')
          ..write('plannedWorkoutId: $plannedWorkoutId, ')
          ..write('movementId: $movementId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, plannedWorkoutId, movementId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannedExercise &&
          other.id == this.id &&
          other.plannedWorkoutId == this.plannedWorkoutId &&
          other.movementId == this.movementId);
}

class PlannedExercisesCompanion extends UpdateCompanion<PlannedExercise> {
  final Value<int> id;
  final Value<int> plannedWorkoutId;
  final Value<int> movementId;
  const PlannedExercisesCompanion({
    this.id = const Value.absent(),
    this.plannedWorkoutId = const Value.absent(),
    this.movementId = const Value.absent(),
  });
  PlannedExercisesCompanion.insert({
    this.id = const Value.absent(),
    required int plannedWorkoutId,
    required int movementId,
  }) : plannedWorkoutId = Value(plannedWorkoutId),
       movementId = Value(movementId);
  static Insertable<PlannedExercise> custom({
    Expression<int>? id,
    Expression<int>? plannedWorkoutId,
    Expression<int>? movementId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plannedWorkoutId != null) 'planned_workout_id': plannedWorkoutId,
      if (movementId != null) 'movement_id': movementId,
    });
  }

  PlannedExercisesCompanion copyWith({
    Value<int>? id,
    Value<int>? plannedWorkoutId,
    Value<int>? movementId,
  }) {
    return PlannedExercisesCompanion(
      id: id ?? this.id,
      plannedWorkoutId: plannedWorkoutId ?? this.plannedWorkoutId,
      movementId: movementId ?? this.movementId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (plannedWorkoutId.present) {
      map['planned_workout_id'] = Variable<int>(plannedWorkoutId.value);
    }
    if (movementId.present) {
      map['movement_id'] = Variable<int>(movementId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannedExercisesCompanion(')
          ..write('id: $id, ')
          ..write('plannedWorkoutId: $plannedWorkoutId, ')
          ..write('movementId: $movementId')
          ..write(')'))
        .toString();
  }
}

class $CompletedExercisesTable extends CompletedExercises
    with TableInfo<$CompletedExercisesTable, CompletedExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletedExercisesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _completedWorkoutIdMeta =
      const VerificationMeta('completedWorkoutId');
  @override
  late final GeneratedColumn<int> completedWorkoutId = GeneratedColumn<int>(
    'completed_workout_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES completed_workouts (id)',
    ),
  );
  static const VerificationMeta _movementIdMeta = const VerificationMeta(
    'movementId',
  );
  @override
  late final GeneratedColumn<int> movementId = GeneratedColumn<int>(
    'movement_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES movements (id)',
    ),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPersistentMeta = const VerificationMeta(
    'isPersistent',
  );
  @override
  late final GeneratedColumn<bool> isPersistent = GeneratedColumn<bool>(
    'is_persistent',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_persistent" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SkipReason?, String> skipReason =
      GeneratedColumn<String>(
        'skip_reason',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<SkipReason?>(
        $CompletedExercisesTable.$converterskipReasonn,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    completedWorkoutId,
    movementId,
    orderIndex,
    isPersistent,
    skipReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completed_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompletedExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('completed_workout_id')) {
      context.handle(
        _completedWorkoutIdMeta,
        completedWorkoutId.isAcceptableOrUnknown(
          data['completed_workout_id']!,
          _completedWorkoutIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedWorkoutIdMeta);
    }
    if (data.containsKey('movement_id')) {
      context.handle(
        _movementIdMeta,
        movementId.isAcceptableOrUnknown(data['movement_id']!, _movementIdMeta),
      );
    } else if (isInserting) {
      context.missing(_movementIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('is_persistent')) {
      context.handle(
        _isPersistentMeta,
        isPersistent.isAcceptableOrUnknown(
          data['is_persistent']!,
          _isPersistentMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {completedWorkoutId, orderIndex},
  ];
  @override
  CompletedExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompletedExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      completedWorkoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_workout_id'],
      )!,
      movementId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}movement_id'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      isPersistent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_persistent'],
      )!,
      skipReason: $CompletedExercisesTable.$converterskipReasonn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}skip_reason'],
        ),
      ),
    );
  }

  @override
  $CompletedExercisesTable createAlias(String alias) {
    return $CompletedExercisesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SkipReason, String, String> $converterskipReason =
      const EnumNameConverter<SkipReason>(SkipReason.values);
  static JsonTypeConverter2<SkipReason?, String?, String?>
  $converterskipReasonn = JsonTypeConverter2.asNullable($converterskipReason);
}

class CompletedExercise extends DataClass
    implements Insertable<CompletedExercise> {
  final int id;
  final int completedWorkoutId;
  final int movementId;
  final int orderIndex;
  final bool isPersistent;
  final SkipReason? skipReason;
  const CompletedExercise({
    required this.id,
    required this.completedWorkoutId,
    required this.movementId,
    required this.orderIndex,
    required this.isPersistent,
    this.skipReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['completed_workout_id'] = Variable<int>(completedWorkoutId);
    map['movement_id'] = Variable<int>(movementId);
    map['order_index'] = Variable<int>(orderIndex);
    map['is_persistent'] = Variable<bool>(isPersistent);
    if (!nullToAbsent || skipReason != null) {
      map['skip_reason'] = Variable<String>(
        $CompletedExercisesTable.$converterskipReasonn.toSql(skipReason),
      );
    }
    return map;
  }

  CompletedExercisesCompanion toCompanion(bool nullToAbsent) {
    return CompletedExercisesCompanion(
      id: Value(id),
      completedWorkoutId: Value(completedWorkoutId),
      movementId: Value(movementId),
      orderIndex: Value(orderIndex),
      isPersistent: Value(isPersistent),
      skipReason: skipReason == null && nullToAbsent
          ? const Value.absent()
          : Value(skipReason),
    );
  }

  factory CompletedExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompletedExercise(
      id: serializer.fromJson<int>(json['id']),
      completedWorkoutId: serializer.fromJson<int>(json['completedWorkoutId']),
      movementId: serializer.fromJson<int>(json['movementId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      isPersistent: serializer.fromJson<bool>(json['isPersistent']),
      skipReason: $CompletedExercisesTable.$converterskipReasonn.fromJson(
        serializer.fromJson<String?>(json['skipReason']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'completedWorkoutId': serializer.toJson<int>(completedWorkoutId),
      'movementId': serializer.toJson<int>(movementId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'isPersistent': serializer.toJson<bool>(isPersistent),
      'skipReason': serializer.toJson<String?>(
        $CompletedExercisesTable.$converterskipReasonn.toJson(skipReason),
      ),
    };
  }

  CompletedExercise copyWith({
    int? id,
    int? completedWorkoutId,
    int? movementId,
    int? orderIndex,
    bool? isPersistent,
    Value<SkipReason?> skipReason = const Value.absent(),
  }) => CompletedExercise(
    id: id ?? this.id,
    completedWorkoutId: completedWorkoutId ?? this.completedWorkoutId,
    movementId: movementId ?? this.movementId,
    orderIndex: orderIndex ?? this.orderIndex,
    isPersistent: isPersistent ?? this.isPersistent,
    skipReason: skipReason.present ? skipReason.value : this.skipReason,
  );
  CompletedExercise copyWithCompanion(CompletedExercisesCompanion data) {
    return CompletedExercise(
      id: data.id.present ? data.id.value : this.id,
      completedWorkoutId: data.completedWorkoutId.present
          ? data.completedWorkoutId.value
          : this.completedWorkoutId,
      movementId: data.movementId.present
          ? data.movementId.value
          : this.movementId,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      isPersistent: data.isPersistent.present
          ? data.isPersistent.value
          : this.isPersistent,
      skipReason: data.skipReason.present
          ? data.skipReason.value
          : this.skipReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompletedExercise(')
          ..write('id: $id, ')
          ..write('completedWorkoutId: $completedWorkoutId, ')
          ..write('movementId: $movementId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('isPersistent: $isPersistent, ')
          ..write('skipReason: $skipReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    completedWorkoutId,
    movementId,
    orderIndex,
    isPersistent,
    skipReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompletedExercise &&
          other.id == this.id &&
          other.completedWorkoutId == this.completedWorkoutId &&
          other.movementId == this.movementId &&
          other.orderIndex == this.orderIndex &&
          other.isPersistent == this.isPersistent &&
          other.skipReason == this.skipReason);
}

class CompletedExercisesCompanion extends UpdateCompanion<CompletedExercise> {
  final Value<int> id;
  final Value<int> completedWorkoutId;
  final Value<int> movementId;
  final Value<int> orderIndex;
  final Value<bool> isPersistent;
  final Value<SkipReason?> skipReason;
  const CompletedExercisesCompanion({
    this.id = const Value.absent(),
    this.completedWorkoutId = const Value.absent(),
    this.movementId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.isPersistent = const Value.absent(),
    this.skipReason = const Value.absent(),
  });
  CompletedExercisesCompanion.insert({
    this.id = const Value.absent(),
    required int completedWorkoutId,
    required int movementId,
    required int orderIndex,
    this.isPersistent = const Value.absent(),
    this.skipReason = const Value.absent(),
  }) : completedWorkoutId = Value(completedWorkoutId),
       movementId = Value(movementId),
       orderIndex = Value(orderIndex);
  static Insertable<CompletedExercise> custom({
    Expression<int>? id,
    Expression<int>? completedWorkoutId,
    Expression<int>? movementId,
    Expression<int>? orderIndex,
    Expression<bool>? isPersistent,
    Expression<String>? skipReason,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (completedWorkoutId != null)
        'completed_workout_id': completedWorkoutId,
      if (movementId != null) 'movement_id': movementId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (isPersistent != null) 'is_persistent': isPersistent,
      if (skipReason != null) 'skip_reason': skipReason,
    });
  }

  CompletedExercisesCompanion copyWith({
    Value<int>? id,
    Value<int>? completedWorkoutId,
    Value<int>? movementId,
    Value<int>? orderIndex,
    Value<bool>? isPersistent,
    Value<SkipReason?>? skipReason,
  }) {
    return CompletedExercisesCompanion(
      id: id ?? this.id,
      completedWorkoutId: completedWorkoutId ?? this.completedWorkoutId,
      movementId: movementId ?? this.movementId,
      orderIndex: orderIndex ?? this.orderIndex,
      isPersistent: isPersistent ?? this.isPersistent,
      skipReason: skipReason ?? this.skipReason,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (completedWorkoutId.present) {
      map['completed_workout_id'] = Variable<int>(completedWorkoutId.value);
    }
    if (movementId.present) {
      map['movement_id'] = Variable<int>(movementId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (isPersistent.present) {
      map['is_persistent'] = Variable<bool>(isPersistent.value);
    }
    if (skipReason.present) {
      map['skip_reason'] = Variable<String>(
        $CompletedExercisesTable.$converterskipReasonn.toSql(skipReason.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletedExercisesCompanion(')
          ..write('id: $id, ')
          ..write('completedWorkoutId: $completedWorkoutId, ')
          ..write('movementId: $movementId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('isPersistent: $isPersistent, ')
          ..write('skipReason: $skipReason')
          ..write(')'))
        .toString();
  }
}

class $PlannedSetsTable extends PlannedSets
    with TableInfo<$PlannedSetsTable, PlannedSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannedSetsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _plannedExerciseIdMeta = const VerificationMeta(
    'plannedExerciseId',
  );
  @override
  late final GeneratedColumn<int> plannedExerciseId = GeneratedColumn<int>(
    'planned_exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES planned_exercises (id)',
    ),
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<double> time = GeneratedColumn<double>(
    'time',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMeta = const VerificationMeta(
    'distance',
  );
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
    'distance',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    plannedExerciseId,
    reps,
    weight,
    time,
    distance,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planned_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannedSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('planned_exercise_id')) {
      context.handle(
        _plannedExerciseIdMeta,
        plannedExerciseId.isAcceptableOrUnknown(
          data['planned_exercise_id']!,
          _plannedExerciseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedExerciseIdMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    }
    if (data.containsKey('distance')) {
      context.handle(
        _distanceMeta,
        distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlannedSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannedSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      plannedExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_exercise_id'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      ),
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      ),
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}time'],
      ),
      distance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance'],
      ),
    );
  }

  @override
  $PlannedSetsTable createAlias(String alias) {
    return $PlannedSetsTable(attachedDatabase, alias);
  }
}

class PlannedSet extends DataClass implements Insertable<PlannedSet> {
  final int id;
  final int plannedExerciseId;
  final int? reps;
  final double? weight;
  final double? time;
  final double? distance;
  const PlannedSet({
    required this.id,
    required this.plannedExerciseId,
    this.reps,
    this.weight,
    this.time,
    this.distance,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['planned_exercise_id'] = Variable<int>(plannedExerciseId);
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    if (!nullToAbsent || time != null) {
      map['time'] = Variable<double>(time);
    }
    if (!nullToAbsent || distance != null) {
      map['distance'] = Variable<double>(distance);
    }
    return map;
  }

  PlannedSetsCompanion toCompanion(bool nullToAbsent) {
    return PlannedSetsCompanion(
      id: Value(id),
      plannedExerciseId: Value(plannedExerciseId),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      weight: weight == null && nullToAbsent
          ? const Value.absent()
          : Value(weight),
      time: time == null && nullToAbsent ? const Value.absent() : Value(time),
      distance: distance == null && nullToAbsent
          ? const Value.absent()
          : Value(distance),
    );
  }

  factory PlannedSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannedSet(
      id: serializer.fromJson<int>(json['id']),
      plannedExerciseId: serializer.fromJson<int>(json['plannedExerciseId']),
      reps: serializer.fromJson<int?>(json['reps']),
      weight: serializer.fromJson<double?>(json['weight']),
      time: serializer.fromJson<double?>(json['time']),
      distance: serializer.fromJson<double?>(json['distance']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'plannedExerciseId': serializer.toJson<int>(plannedExerciseId),
      'reps': serializer.toJson<int?>(reps),
      'weight': serializer.toJson<double?>(weight),
      'time': serializer.toJson<double?>(time),
      'distance': serializer.toJson<double?>(distance),
    };
  }

  PlannedSet copyWith({
    int? id,
    int? plannedExerciseId,
    Value<int?> reps = const Value.absent(),
    Value<double?> weight = const Value.absent(),
    Value<double?> time = const Value.absent(),
    Value<double?> distance = const Value.absent(),
  }) => PlannedSet(
    id: id ?? this.id,
    plannedExerciseId: plannedExerciseId ?? this.plannedExerciseId,
    reps: reps.present ? reps.value : this.reps,
    weight: weight.present ? weight.value : this.weight,
    time: time.present ? time.value : this.time,
    distance: distance.present ? distance.value : this.distance,
  );
  PlannedSet copyWithCompanion(PlannedSetsCompanion data) {
    return PlannedSet(
      id: data.id.present ? data.id.value : this.id,
      plannedExerciseId: data.plannedExerciseId.present
          ? data.plannedExerciseId.value
          : this.plannedExerciseId,
      reps: data.reps.present ? data.reps.value : this.reps,
      weight: data.weight.present ? data.weight.value : this.weight,
      time: data.time.present ? data.time.value : this.time,
      distance: data.distance.present ? data.distance.value : this.distance,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannedSet(')
          ..write('id: $id, ')
          ..write('plannedExerciseId: $plannedExerciseId, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight, ')
          ..write('time: $time, ')
          ..write('distance: $distance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, plannedExerciseId, reps, weight, time, distance);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannedSet &&
          other.id == this.id &&
          other.plannedExerciseId == this.plannedExerciseId &&
          other.reps == this.reps &&
          other.weight == this.weight &&
          other.time == this.time &&
          other.distance == this.distance);
}

class PlannedSetsCompanion extends UpdateCompanion<PlannedSet> {
  final Value<int> id;
  final Value<int> plannedExerciseId;
  final Value<int?> reps;
  final Value<double?> weight;
  final Value<double?> time;
  final Value<double?> distance;
  const PlannedSetsCompanion({
    this.id = const Value.absent(),
    this.plannedExerciseId = const Value.absent(),
    this.reps = const Value.absent(),
    this.weight = const Value.absent(),
    this.time = const Value.absent(),
    this.distance = const Value.absent(),
  });
  PlannedSetsCompanion.insert({
    this.id = const Value.absent(),
    required int plannedExerciseId,
    this.reps = const Value.absent(),
    this.weight = const Value.absent(),
    this.time = const Value.absent(),
    this.distance = const Value.absent(),
  }) : plannedExerciseId = Value(plannedExerciseId);
  static Insertable<PlannedSet> custom({
    Expression<int>? id,
    Expression<int>? plannedExerciseId,
    Expression<int>? reps,
    Expression<double>? weight,
    Expression<double>? time,
    Expression<double>? distance,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plannedExerciseId != null) 'planned_exercise_id': plannedExerciseId,
      if (reps != null) 'reps': reps,
      if (weight != null) 'weight': weight,
      if (time != null) 'time': time,
      if (distance != null) 'distance': distance,
    });
  }

  PlannedSetsCompanion copyWith({
    Value<int>? id,
    Value<int>? plannedExerciseId,
    Value<int?>? reps,
    Value<double?>? weight,
    Value<double?>? time,
    Value<double?>? distance,
  }) {
    return PlannedSetsCompanion(
      id: id ?? this.id,
      plannedExerciseId: plannedExerciseId ?? this.plannedExerciseId,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      time: time ?? this.time,
      distance: distance ?? this.distance,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (plannedExerciseId.present) {
      map['planned_exercise_id'] = Variable<int>(plannedExerciseId.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (time.present) {
      map['time'] = Variable<double>(time.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannedSetsCompanion(')
          ..write('id: $id, ')
          ..write('plannedExerciseId: $plannedExerciseId, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight, ')
          ..write('time: $time, ')
          ..write('distance: $distance')
          ..write(')'))
        .toString();
  }
}

class $CompletedSetsTable extends CompletedSets
    with TableInfo<$CompletedSetsTable, CompletedSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletedSetsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _completedExerciseIdMeta =
      const VerificationMeta('completedExerciseId');
  @override
  late final GeneratedColumn<int> completedExerciseId = GeneratedColumn<int>(
    'completed_exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES completed_exercises (id)',
    ),
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<double> time = GeneratedColumn<double>(
    'time',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMeta = const VerificationMeta(
    'distance',
  );
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
    'distance',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SkipReason?, String> skipReason =
      GeneratedColumn<String>(
        'skip_reason',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<SkipReason?>($CompletedSetsTable.$converterskipReasonn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    completedExerciseId,
    reps,
    weight,
    time,
    distance,
    skipReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completed_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompletedSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('completed_exercise_id')) {
      context.handle(
        _completedExerciseIdMeta,
        completedExerciseId.isAcceptableOrUnknown(
          data['completed_exercise_id']!,
          _completedExerciseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedExerciseIdMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    }
    if (data.containsKey('distance')) {
      context.handle(
        _distanceMeta,
        distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompletedSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompletedSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      completedExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_exercise_id'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      ),
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      ),
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}time'],
      ),
      distance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance'],
      ),
      skipReason: $CompletedSetsTable.$converterskipReasonn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}skip_reason'],
        ),
      ),
    );
  }

  @override
  $CompletedSetsTable createAlias(String alias) {
    return $CompletedSetsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SkipReason, String, String> $converterskipReason =
      const EnumNameConverter<SkipReason>(SkipReason.values);
  static JsonTypeConverter2<SkipReason?, String?, String?>
  $converterskipReasonn = JsonTypeConverter2.asNullable($converterskipReason);
}

class CompletedSet extends DataClass implements Insertable<CompletedSet> {
  final int id;
  final int completedExerciseId;
  final int? reps;
  final double? weight;
  final double? time;
  final double? distance;
  final SkipReason? skipReason;
  const CompletedSet({
    required this.id,
    required this.completedExerciseId,
    this.reps,
    this.weight,
    this.time,
    this.distance,
    this.skipReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['completed_exercise_id'] = Variable<int>(completedExerciseId);
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    if (!nullToAbsent || time != null) {
      map['time'] = Variable<double>(time);
    }
    if (!nullToAbsent || distance != null) {
      map['distance'] = Variable<double>(distance);
    }
    if (!nullToAbsent || skipReason != null) {
      map['skip_reason'] = Variable<String>(
        $CompletedSetsTable.$converterskipReasonn.toSql(skipReason),
      );
    }
    return map;
  }

  CompletedSetsCompanion toCompanion(bool nullToAbsent) {
    return CompletedSetsCompanion(
      id: Value(id),
      completedExerciseId: Value(completedExerciseId),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      weight: weight == null && nullToAbsent
          ? const Value.absent()
          : Value(weight),
      time: time == null && nullToAbsent ? const Value.absent() : Value(time),
      distance: distance == null && nullToAbsent
          ? const Value.absent()
          : Value(distance),
      skipReason: skipReason == null && nullToAbsent
          ? const Value.absent()
          : Value(skipReason),
    );
  }

  factory CompletedSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompletedSet(
      id: serializer.fromJson<int>(json['id']),
      completedExerciseId: serializer.fromJson<int>(
        json['completedExerciseId'],
      ),
      reps: serializer.fromJson<int?>(json['reps']),
      weight: serializer.fromJson<double?>(json['weight']),
      time: serializer.fromJson<double?>(json['time']),
      distance: serializer.fromJson<double?>(json['distance']),
      skipReason: $CompletedSetsTable.$converterskipReasonn.fromJson(
        serializer.fromJson<String?>(json['skipReason']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'completedExerciseId': serializer.toJson<int>(completedExerciseId),
      'reps': serializer.toJson<int?>(reps),
      'weight': serializer.toJson<double?>(weight),
      'time': serializer.toJson<double?>(time),
      'distance': serializer.toJson<double?>(distance),
      'skipReason': serializer.toJson<String?>(
        $CompletedSetsTable.$converterskipReasonn.toJson(skipReason),
      ),
    };
  }

  CompletedSet copyWith({
    int? id,
    int? completedExerciseId,
    Value<int?> reps = const Value.absent(),
    Value<double?> weight = const Value.absent(),
    Value<double?> time = const Value.absent(),
    Value<double?> distance = const Value.absent(),
    Value<SkipReason?> skipReason = const Value.absent(),
  }) => CompletedSet(
    id: id ?? this.id,
    completedExerciseId: completedExerciseId ?? this.completedExerciseId,
    reps: reps.present ? reps.value : this.reps,
    weight: weight.present ? weight.value : this.weight,
    time: time.present ? time.value : this.time,
    distance: distance.present ? distance.value : this.distance,
    skipReason: skipReason.present ? skipReason.value : this.skipReason,
  );
  CompletedSet copyWithCompanion(CompletedSetsCompanion data) {
    return CompletedSet(
      id: data.id.present ? data.id.value : this.id,
      completedExerciseId: data.completedExerciseId.present
          ? data.completedExerciseId.value
          : this.completedExerciseId,
      reps: data.reps.present ? data.reps.value : this.reps,
      weight: data.weight.present ? data.weight.value : this.weight,
      time: data.time.present ? data.time.value : this.time,
      distance: data.distance.present ? data.distance.value : this.distance,
      skipReason: data.skipReason.present
          ? data.skipReason.value
          : this.skipReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompletedSet(')
          ..write('id: $id, ')
          ..write('completedExerciseId: $completedExerciseId, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight, ')
          ..write('time: $time, ')
          ..write('distance: $distance, ')
          ..write('skipReason: $skipReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    completedExerciseId,
    reps,
    weight,
    time,
    distance,
    skipReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompletedSet &&
          other.id == this.id &&
          other.completedExerciseId == this.completedExerciseId &&
          other.reps == this.reps &&
          other.weight == this.weight &&
          other.time == this.time &&
          other.distance == this.distance &&
          other.skipReason == this.skipReason);
}

class CompletedSetsCompanion extends UpdateCompanion<CompletedSet> {
  final Value<int> id;
  final Value<int> completedExerciseId;
  final Value<int?> reps;
  final Value<double?> weight;
  final Value<double?> time;
  final Value<double?> distance;
  final Value<SkipReason?> skipReason;
  const CompletedSetsCompanion({
    this.id = const Value.absent(),
    this.completedExerciseId = const Value.absent(),
    this.reps = const Value.absent(),
    this.weight = const Value.absent(),
    this.time = const Value.absent(),
    this.distance = const Value.absent(),
    this.skipReason = const Value.absent(),
  });
  CompletedSetsCompanion.insert({
    this.id = const Value.absent(),
    required int completedExerciseId,
    this.reps = const Value.absent(),
    this.weight = const Value.absent(),
    this.time = const Value.absent(),
    this.distance = const Value.absent(),
    this.skipReason = const Value.absent(),
  }) : completedExerciseId = Value(completedExerciseId);
  static Insertable<CompletedSet> custom({
    Expression<int>? id,
    Expression<int>? completedExerciseId,
    Expression<int>? reps,
    Expression<double>? weight,
    Expression<double>? time,
    Expression<double>? distance,
    Expression<String>? skipReason,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (completedExerciseId != null)
        'completed_exercise_id': completedExerciseId,
      if (reps != null) 'reps': reps,
      if (weight != null) 'weight': weight,
      if (time != null) 'time': time,
      if (distance != null) 'distance': distance,
      if (skipReason != null) 'skip_reason': skipReason,
    });
  }

  CompletedSetsCompanion copyWith({
    Value<int>? id,
    Value<int>? completedExerciseId,
    Value<int?>? reps,
    Value<double?>? weight,
    Value<double?>? time,
    Value<double?>? distance,
    Value<SkipReason?>? skipReason,
  }) {
    return CompletedSetsCompanion(
      id: id ?? this.id,
      completedExerciseId: completedExerciseId ?? this.completedExerciseId,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      time: time ?? this.time,
      distance: distance ?? this.distance,
      skipReason: skipReason ?? this.skipReason,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (completedExerciseId.present) {
      map['completed_exercise_id'] = Variable<int>(completedExerciseId.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (time.present) {
      map['time'] = Variable<double>(time.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (skipReason.present) {
      map['skip_reason'] = Variable<String>(
        $CompletedSetsTable.$converterskipReasonn.toSql(skipReason.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletedSetsCompanion(')
          ..write('id: $id, ')
          ..write('completedExerciseId: $completedExerciseId, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight, ')
          ..write('time: $time, ')
          ..write('distance: $distance, ')
          ..write('skipReason: $skipReason')
          ..write(')'))
        .toString();
  }
}

class $PreWorkoutCheckinsTable extends PreWorkoutCheckins
    with TableInfo<$PreWorkoutCheckinsTable, PreWorkoutCheckin> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreWorkoutCheckinsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _workoutIdMeta = const VerificationMeta(
    'workoutId',
  );
  @override
  late final GeneratedColumn<int> workoutId = GeneratedColumn<int>(
    'workout_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES workouts (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Soreness?, String> quads =
      GeneratedColumn<String>(
        'quads',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Soreness?>($PreWorkoutCheckinsTable.$converterquadsn);
  @override
  late final GeneratedColumnWithTypeConverter<Soreness?, String> hamstrings =
      GeneratedColumn<String>(
        'hamstrings',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Soreness?>(
        $PreWorkoutCheckinsTable.$converterhamstringsn,
      );
  @override
  late final GeneratedColumnWithTypeConverter<Soreness?, String> abs =
      GeneratedColumn<String>(
        'abs',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Soreness?>($PreWorkoutCheckinsTable.$converterabsn);
  @override
  late final GeneratedColumnWithTypeConverter<Soreness?, String> chest =
      GeneratedColumn<String>(
        'chest',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Soreness?>($PreWorkoutCheckinsTable.$converterchestn);
  @override
  late final GeneratedColumnWithTypeConverter<Soreness?, String> back =
      GeneratedColumn<String>(
        'back',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Soreness?>($PreWorkoutCheckinsTable.$converterbackn);
  @override
  late final GeneratedColumnWithTypeConverter<Soreness?, String> biceps =
      GeneratedColumn<String>(
        'biceps',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Soreness?>($PreWorkoutCheckinsTable.$converterbicepsn);
  @override
  late final GeneratedColumnWithTypeConverter<Soreness?, String> triceps =
      GeneratedColumn<String>(
        'triceps',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Soreness?>($PreWorkoutCheckinsTable.$convertertricepsn);
  @override
  late final GeneratedColumnWithTypeConverter<Soreness?, String> traps =
      GeneratedColumn<String>(
        'traps',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Soreness?>($PreWorkoutCheckinsTable.$convertertrapsn);
  @override
  late final GeneratedColumnWithTypeConverter<Soreness?, String> forearms =
      GeneratedColumn<String>(
        'forearms',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Soreness?>($PreWorkoutCheckinsTable.$converterforearmsn);
  @override
  late final GeneratedColumnWithTypeConverter<Soreness?, String> glutes =
      GeneratedColumn<String>(
        'glutes',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Soreness?>($PreWorkoutCheckinsTable.$converterglutesn);
  @override
  late final GeneratedColumnWithTypeConverter<Soreness?, String> calves =
      GeneratedColumn<String>(
        'calves',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Soreness?>($PreWorkoutCheckinsTable.$convertercalvesn);
  @override
  late final GeneratedColumnWithTypeConverter<Soreness?, String> shoulders =
      GeneratedColumn<String>(
        'shoulders',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Soreness?>($PreWorkoutCheckinsTable.$convertershouldersn);
  @override
  late final GeneratedColumnWithTypeConverter<CurrentState?, String>
  sleepQuality =
      GeneratedColumn<String>(
        'sleep_quality',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<CurrentState?>(
        $PreWorkoutCheckinsTable.$convertersleepQualityn,
      );
  @override
  late final GeneratedColumnWithTypeConverter<CurrentState?, String> vimVigor =
      GeneratedColumn<String>(
        'vim_vigor',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<CurrentState?>(
        $PreWorkoutCheckinsTable.$convertervimVigorn,
      );
  @override
  late final GeneratedColumnWithTypeConverter<CurrentState?, String>
  mentalState =
      GeneratedColumn<String>(
        'mental_state',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<CurrentState?>(
        $PreWorkoutCheckinsTable.$convertermentalStaten,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workoutId,
    quads,
    hamstrings,
    abs,
    chest,
    back,
    biceps,
    triceps,
    traps,
    forearms,
    glutes,
    calves,
    shoulders,
    sleepQuality,
    vimVigor,
    mentalState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pre_workout_checkins';
  @override
  VerificationContext validateIntegrity(
    Insertable<PreWorkoutCheckin> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PreWorkoutCheckin map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PreWorkoutCheckin(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}workout_id'],
      )!,
      quads: $PreWorkoutCheckinsTable.$converterquadsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}quads'],
        ),
      ),
      hamstrings: $PreWorkoutCheckinsTable.$converterhamstringsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}hamstrings'],
        ),
      ),
      abs: $PreWorkoutCheckinsTable.$converterabsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}abs'],
        ),
      ),
      chest: $PreWorkoutCheckinsTable.$converterchestn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}chest'],
        ),
      ),
      back: $PreWorkoutCheckinsTable.$converterbackn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}back'],
        ),
      ),
      biceps: $PreWorkoutCheckinsTable.$converterbicepsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}biceps'],
        ),
      ),
      triceps: $PreWorkoutCheckinsTable.$convertertricepsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}triceps'],
        ),
      ),
      traps: $PreWorkoutCheckinsTable.$convertertrapsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}traps'],
        ),
      ),
      forearms: $PreWorkoutCheckinsTable.$converterforearmsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}forearms'],
        ),
      ),
      glutes: $PreWorkoutCheckinsTable.$converterglutesn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}glutes'],
        ),
      ),
      calves: $PreWorkoutCheckinsTable.$convertercalvesn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}calves'],
        ),
      ),
      shoulders: $PreWorkoutCheckinsTable.$convertershouldersn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}shoulders'],
        ),
      ),
      sleepQuality: $PreWorkoutCheckinsTable.$convertersleepQualityn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sleep_quality'],
        ),
      ),
      vimVigor: $PreWorkoutCheckinsTable.$convertervimVigorn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}vim_vigor'],
        ),
      ),
      mentalState: $PreWorkoutCheckinsTable.$convertermentalStaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}mental_state'],
        ),
      ),
    );
  }

  @override
  $PreWorkoutCheckinsTable createAlias(String alias) {
    return $PreWorkoutCheckinsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Soreness, String, String> $converterquads =
      const EnumNameConverter<Soreness>(Soreness.values);
  static JsonTypeConverter2<Soreness?, String?, String?> $converterquadsn =
      JsonTypeConverter2.asNullable($converterquads);
  static JsonTypeConverter2<Soreness, String, String> $converterhamstrings =
      const EnumNameConverter<Soreness>(Soreness.values);
  static JsonTypeConverter2<Soreness?, String?, String?> $converterhamstringsn =
      JsonTypeConverter2.asNullable($converterhamstrings);
  static JsonTypeConverter2<Soreness, String, String> $converterabs =
      const EnumNameConverter<Soreness>(Soreness.values);
  static JsonTypeConverter2<Soreness?, String?, String?> $converterabsn =
      JsonTypeConverter2.asNullable($converterabs);
  static JsonTypeConverter2<Soreness, String, String> $converterchest =
      const EnumNameConverter<Soreness>(Soreness.values);
  static JsonTypeConverter2<Soreness?, String?, String?> $converterchestn =
      JsonTypeConverter2.asNullable($converterchest);
  static JsonTypeConverter2<Soreness, String, String> $converterback =
      const EnumNameConverter<Soreness>(Soreness.values);
  static JsonTypeConverter2<Soreness?, String?, String?> $converterbackn =
      JsonTypeConverter2.asNullable($converterback);
  static JsonTypeConverter2<Soreness, String, String> $converterbiceps =
      const EnumNameConverter<Soreness>(Soreness.values);
  static JsonTypeConverter2<Soreness?, String?, String?> $converterbicepsn =
      JsonTypeConverter2.asNullable($converterbiceps);
  static JsonTypeConverter2<Soreness, String, String> $convertertriceps =
      const EnumNameConverter<Soreness>(Soreness.values);
  static JsonTypeConverter2<Soreness?, String?, String?> $convertertricepsn =
      JsonTypeConverter2.asNullable($convertertriceps);
  static JsonTypeConverter2<Soreness, String, String> $convertertraps =
      const EnumNameConverter<Soreness>(Soreness.values);
  static JsonTypeConverter2<Soreness?, String?, String?> $convertertrapsn =
      JsonTypeConverter2.asNullable($convertertraps);
  static JsonTypeConverter2<Soreness, String, String> $converterforearms =
      const EnumNameConverter<Soreness>(Soreness.values);
  static JsonTypeConverter2<Soreness?, String?, String?> $converterforearmsn =
      JsonTypeConverter2.asNullable($converterforearms);
  static JsonTypeConverter2<Soreness, String, String> $converterglutes =
      const EnumNameConverter<Soreness>(Soreness.values);
  static JsonTypeConverter2<Soreness?, String?, String?> $converterglutesn =
      JsonTypeConverter2.asNullable($converterglutes);
  static JsonTypeConverter2<Soreness, String, String> $convertercalves =
      const EnumNameConverter<Soreness>(Soreness.values);
  static JsonTypeConverter2<Soreness?, String?, String?> $convertercalvesn =
      JsonTypeConverter2.asNullable($convertercalves);
  static JsonTypeConverter2<Soreness, String, String> $convertershoulders =
      const EnumNameConverter<Soreness>(Soreness.values);
  static JsonTypeConverter2<Soreness?, String?, String?> $convertershouldersn =
      JsonTypeConverter2.asNullable($convertershoulders);
  static JsonTypeConverter2<CurrentState, String, String>
  $convertersleepQuality = const EnumNameConverter<CurrentState>(
    CurrentState.values,
  );
  static JsonTypeConverter2<CurrentState?, String?, String?>
  $convertersleepQualityn = JsonTypeConverter2.asNullable(
    $convertersleepQuality,
  );
  static JsonTypeConverter2<CurrentState, String, String> $convertervimVigor =
      const EnumNameConverter<CurrentState>(CurrentState.values);
  static JsonTypeConverter2<CurrentState?, String?, String?>
  $convertervimVigorn = JsonTypeConverter2.asNullable($convertervimVigor);
  static JsonTypeConverter2<CurrentState, String, String>
  $convertermentalState = const EnumNameConverter<CurrentState>(
    CurrentState.values,
  );
  static JsonTypeConverter2<CurrentState?, String?, String?>
  $convertermentalStaten = JsonTypeConverter2.asNullable($convertermentalState);
}

class PreWorkoutCheckin extends DataClass
    implements Insertable<PreWorkoutCheckin> {
  final int id;
  final int workoutId;
  final Soreness? quads;
  final Soreness? hamstrings;
  final Soreness? abs;
  final Soreness? chest;
  final Soreness? back;
  final Soreness? biceps;
  final Soreness? triceps;
  final Soreness? traps;
  final Soreness? forearms;
  final Soreness? glutes;
  final Soreness? calves;
  final Soreness? shoulders;
  final CurrentState? sleepQuality;
  final CurrentState? vimVigor;
  final CurrentState? mentalState;
  const PreWorkoutCheckin({
    required this.id,
    required this.workoutId,
    this.quads,
    this.hamstrings,
    this.abs,
    this.chest,
    this.back,
    this.biceps,
    this.triceps,
    this.traps,
    this.forearms,
    this.glutes,
    this.calves,
    this.shoulders,
    this.sleepQuality,
    this.vimVigor,
    this.mentalState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['workout_id'] = Variable<int>(workoutId);
    if (!nullToAbsent || quads != null) {
      map['quads'] = Variable<String>(
        $PreWorkoutCheckinsTable.$converterquadsn.toSql(quads),
      );
    }
    if (!nullToAbsent || hamstrings != null) {
      map['hamstrings'] = Variable<String>(
        $PreWorkoutCheckinsTable.$converterhamstringsn.toSql(hamstrings),
      );
    }
    if (!nullToAbsent || abs != null) {
      map['abs'] = Variable<String>(
        $PreWorkoutCheckinsTable.$converterabsn.toSql(abs),
      );
    }
    if (!nullToAbsent || chest != null) {
      map['chest'] = Variable<String>(
        $PreWorkoutCheckinsTable.$converterchestn.toSql(chest),
      );
    }
    if (!nullToAbsent || back != null) {
      map['back'] = Variable<String>(
        $PreWorkoutCheckinsTable.$converterbackn.toSql(back),
      );
    }
    if (!nullToAbsent || biceps != null) {
      map['biceps'] = Variable<String>(
        $PreWorkoutCheckinsTable.$converterbicepsn.toSql(biceps),
      );
    }
    if (!nullToAbsent || triceps != null) {
      map['triceps'] = Variable<String>(
        $PreWorkoutCheckinsTable.$convertertricepsn.toSql(triceps),
      );
    }
    if (!nullToAbsent || traps != null) {
      map['traps'] = Variable<String>(
        $PreWorkoutCheckinsTable.$convertertrapsn.toSql(traps),
      );
    }
    if (!nullToAbsent || forearms != null) {
      map['forearms'] = Variable<String>(
        $PreWorkoutCheckinsTable.$converterforearmsn.toSql(forearms),
      );
    }
    if (!nullToAbsent || glutes != null) {
      map['glutes'] = Variable<String>(
        $PreWorkoutCheckinsTable.$converterglutesn.toSql(glutes),
      );
    }
    if (!nullToAbsent || calves != null) {
      map['calves'] = Variable<String>(
        $PreWorkoutCheckinsTable.$convertercalvesn.toSql(calves),
      );
    }
    if (!nullToAbsent || shoulders != null) {
      map['shoulders'] = Variable<String>(
        $PreWorkoutCheckinsTable.$convertershouldersn.toSql(shoulders),
      );
    }
    if (!nullToAbsent || sleepQuality != null) {
      map['sleep_quality'] = Variable<String>(
        $PreWorkoutCheckinsTable.$convertersleepQualityn.toSql(sleepQuality),
      );
    }
    if (!nullToAbsent || vimVigor != null) {
      map['vim_vigor'] = Variable<String>(
        $PreWorkoutCheckinsTable.$convertervimVigorn.toSql(vimVigor),
      );
    }
    if (!nullToAbsent || mentalState != null) {
      map['mental_state'] = Variable<String>(
        $PreWorkoutCheckinsTable.$convertermentalStaten.toSql(mentalState),
      );
    }
    return map;
  }

  PreWorkoutCheckinsCompanion toCompanion(bool nullToAbsent) {
    return PreWorkoutCheckinsCompanion(
      id: Value(id),
      workoutId: Value(workoutId),
      quads: quads == null && nullToAbsent
          ? const Value.absent()
          : Value(quads),
      hamstrings: hamstrings == null && nullToAbsent
          ? const Value.absent()
          : Value(hamstrings),
      abs: abs == null && nullToAbsent ? const Value.absent() : Value(abs),
      chest: chest == null && nullToAbsent
          ? const Value.absent()
          : Value(chest),
      back: back == null && nullToAbsent ? const Value.absent() : Value(back),
      biceps: biceps == null && nullToAbsent
          ? const Value.absent()
          : Value(biceps),
      triceps: triceps == null && nullToAbsent
          ? const Value.absent()
          : Value(triceps),
      traps: traps == null && nullToAbsent
          ? const Value.absent()
          : Value(traps),
      forearms: forearms == null && nullToAbsent
          ? const Value.absent()
          : Value(forearms),
      glutes: glutes == null && nullToAbsent
          ? const Value.absent()
          : Value(glutes),
      calves: calves == null && nullToAbsent
          ? const Value.absent()
          : Value(calves),
      shoulders: shoulders == null && nullToAbsent
          ? const Value.absent()
          : Value(shoulders),
      sleepQuality: sleepQuality == null && nullToAbsent
          ? const Value.absent()
          : Value(sleepQuality),
      vimVigor: vimVigor == null && nullToAbsent
          ? const Value.absent()
          : Value(vimVigor),
      mentalState: mentalState == null && nullToAbsent
          ? const Value.absent()
          : Value(mentalState),
    );
  }

  factory PreWorkoutCheckin.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PreWorkoutCheckin(
      id: serializer.fromJson<int>(json['id']),
      workoutId: serializer.fromJson<int>(json['workoutId']),
      quads: $PreWorkoutCheckinsTable.$converterquadsn.fromJson(
        serializer.fromJson<String?>(json['quads']),
      ),
      hamstrings: $PreWorkoutCheckinsTable.$converterhamstringsn.fromJson(
        serializer.fromJson<String?>(json['hamstrings']),
      ),
      abs: $PreWorkoutCheckinsTable.$converterabsn.fromJson(
        serializer.fromJson<String?>(json['abs']),
      ),
      chest: $PreWorkoutCheckinsTable.$converterchestn.fromJson(
        serializer.fromJson<String?>(json['chest']),
      ),
      back: $PreWorkoutCheckinsTable.$converterbackn.fromJson(
        serializer.fromJson<String?>(json['back']),
      ),
      biceps: $PreWorkoutCheckinsTable.$converterbicepsn.fromJson(
        serializer.fromJson<String?>(json['biceps']),
      ),
      triceps: $PreWorkoutCheckinsTable.$convertertricepsn.fromJson(
        serializer.fromJson<String?>(json['triceps']),
      ),
      traps: $PreWorkoutCheckinsTable.$convertertrapsn.fromJson(
        serializer.fromJson<String?>(json['traps']),
      ),
      forearms: $PreWorkoutCheckinsTable.$converterforearmsn.fromJson(
        serializer.fromJson<String?>(json['forearms']),
      ),
      glutes: $PreWorkoutCheckinsTable.$converterglutesn.fromJson(
        serializer.fromJson<String?>(json['glutes']),
      ),
      calves: $PreWorkoutCheckinsTable.$convertercalvesn.fromJson(
        serializer.fromJson<String?>(json['calves']),
      ),
      shoulders: $PreWorkoutCheckinsTable.$convertershouldersn.fromJson(
        serializer.fromJson<String?>(json['shoulders']),
      ),
      sleepQuality: $PreWorkoutCheckinsTable.$convertersleepQualityn.fromJson(
        serializer.fromJson<String?>(json['sleepQuality']),
      ),
      vimVigor: $PreWorkoutCheckinsTable.$convertervimVigorn.fromJson(
        serializer.fromJson<String?>(json['vimVigor']),
      ),
      mentalState: $PreWorkoutCheckinsTable.$convertermentalStaten.fromJson(
        serializer.fromJson<String?>(json['mentalState']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'workoutId': serializer.toJson<int>(workoutId),
      'quads': serializer.toJson<String?>(
        $PreWorkoutCheckinsTable.$converterquadsn.toJson(quads),
      ),
      'hamstrings': serializer.toJson<String?>(
        $PreWorkoutCheckinsTable.$converterhamstringsn.toJson(hamstrings),
      ),
      'abs': serializer.toJson<String?>(
        $PreWorkoutCheckinsTable.$converterabsn.toJson(abs),
      ),
      'chest': serializer.toJson<String?>(
        $PreWorkoutCheckinsTable.$converterchestn.toJson(chest),
      ),
      'back': serializer.toJson<String?>(
        $PreWorkoutCheckinsTable.$converterbackn.toJson(back),
      ),
      'biceps': serializer.toJson<String?>(
        $PreWorkoutCheckinsTable.$converterbicepsn.toJson(biceps),
      ),
      'triceps': serializer.toJson<String?>(
        $PreWorkoutCheckinsTable.$convertertricepsn.toJson(triceps),
      ),
      'traps': serializer.toJson<String?>(
        $PreWorkoutCheckinsTable.$convertertrapsn.toJson(traps),
      ),
      'forearms': serializer.toJson<String?>(
        $PreWorkoutCheckinsTable.$converterforearmsn.toJson(forearms),
      ),
      'glutes': serializer.toJson<String?>(
        $PreWorkoutCheckinsTable.$converterglutesn.toJson(glutes),
      ),
      'calves': serializer.toJson<String?>(
        $PreWorkoutCheckinsTable.$convertercalvesn.toJson(calves),
      ),
      'shoulders': serializer.toJson<String?>(
        $PreWorkoutCheckinsTable.$convertershouldersn.toJson(shoulders),
      ),
      'sleepQuality': serializer.toJson<String?>(
        $PreWorkoutCheckinsTable.$convertersleepQualityn.toJson(sleepQuality),
      ),
      'vimVigor': serializer.toJson<String?>(
        $PreWorkoutCheckinsTable.$convertervimVigorn.toJson(vimVigor),
      ),
      'mentalState': serializer.toJson<String?>(
        $PreWorkoutCheckinsTable.$convertermentalStaten.toJson(mentalState),
      ),
    };
  }

  PreWorkoutCheckin copyWith({
    int? id,
    int? workoutId,
    Value<Soreness?> quads = const Value.absent(),
    Value<Soreness?> hamstrings = const Value.absent(),
    Value<Soreness?> abs = const Value.absent(),
    Value<Soreness?> chest = const Value.absent(),
    Value<Soreness?> back = const Value.absent(),
    Value<Soreness?> biceps = const Value.absent(),
    Value<Soreness?> triceps = const Value.absent(),
    Value<Soreness?> traps = const Value.absent(),
    Value<Soreness?> forearms = const Value.absent(),
    Value<Soreness?> glutes = const Value.absent(),
    Value<Soreness?> calves = const Value.absent(),
    Value<Soreness?> shoulders = const Value.absent(),
    Value<CurrentState?> sleepQuality = const Value.absent(),
    Value<CurrentState?> vimVigor = const Value.absent(),
    Value<CurrentState?> mentalState = const Value.absent(),
  }) => PreWorkoutCheckin(
    id: id ?? this.id,
    workoutId: workoutId ?? this.workoutId,
    quads: quads.present ? quads.value : this.quads,
    hamstrings: hamstrings.present ? hamstrings.value : this.hamstrings,
    abs: abs.present ? abs.value : this.abs,
    chest: chest.present ? chest.value : this.chest,
    back: back.present ? back.value : this.back,
    biceps: biceps.present ? biceps.value : this.biceps,
    triceps: triceps.present ? triceps.value : this.triceps,
    traps: traps.present ? traps.value : this.traps,
    forearms: forearms.present ? forearms.value : this.forearms,
    glutes: glutes.present ? glutes.value : this.glutes,
    calves: calves.present ? calves.value : this.calves,
    shoulders: shoulders.present ? shoulders.value : this.shoulders,
    sleepQuality: sleepQuality.present ? sleepQuality.value : this.sleepQuality,
    vimVigor: vimVigor.present ? vimVigor.value : this.vimVigor,
    mentalState: mentalState.present ? mentalState.value : this.mentalState,
  );
  PreWorkoutCheckin copyWithCompanion(PreWorkoutCheckinsCompanion data) {
    return PreWorkoutCheckin(
      id: data.id.present ? data.id.value : this.id,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      quads: data.quads.present ? data.quads.value : this.quads,
      hamstrings: data.hamstrings.present
          ? data.hamstrings.value
          : this.hamstrings,
      abs: data.abs.present ? data.abs.value : this.abs,
      chest: data.chest.present ? data.chest.value : this.chest,
      back: data.back.present ? data.back.value : this.back,
      biceps: data.biceps.present ? data.biceps.value : this.biceps,
      triceps: data.triceps.present ? data.triceps.value : this.triceps,
      traps: data.traps.present ? data.traps.value : this.traps,
      forearms: data.forearms.present ? data.forearms.value : this.forearms,
      glutes: data.glutes.present ? data.glutes.value : this.glutes,
      calves: data.calves.present ? data.calves.value : this.calves,
      shoulders: data.shoulders.present ? data.shoulders.value : this.shoulders,
      sleepQuality: data.sleepQuality.present
          ? data.sleepQuality.value
          : this.sleepQuality,
      vimVigor: data.vimVigor.present ? data.vimVigor.value : this.vimVigor,
      mentalState: data.mentalState.present
          ? data.mentalState.value
          : this.mentalState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PreWorkoutCheckin(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('quads: $quads, ')
          ..write('hamstrings: $hamstrings, ')
          ..write('abs: $abs, ')
          ..write('chest: $chest, ')
          ..write('back: $back, ')
          ..write('biceps: $biceps, ')
          ..write('triceps: $triceps, ')
          ..write('traps: $traps, ')
          ..write('forearms: $forearms, ')
          ..write('glutes: $glutes, ')
          ..write('calves: $calves, ')
          ..write('shoulders: $shoulders, ')
          ..write('sleepQuality: $sleepQuality, ')
          ..write('vimVigor: $vimVigor, ')
          ..write('mentalState: $mentalState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workoutId,
    quads,
    hamstrings,
    abs,
    chest,
    back,
    biceps,
    triceps,
    traps,
    forearms,
    glutes,
    calves,
    shoulders,
    sleepQuality,
    vimVigor,
    mentalState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PreWorkoutCheckin &&
          other.id == this.id &&
          other.workoutId == this.workoutId &&
          other.quads == this.quads &&
          other.hamstrings == this.hamstrings &&
          other.abs == this.abs &&
          other.chest == this.chest &&
          other.back == this.back &&
          other.biceps == this.biceps &&
          other.triceps == this.triceps &&
          other.traps == this.traps &&
          other.forearms == this.forearms &&
          other.glutes == this.glutes &&
          other.calves == this.calves &&
          other.shoulders == this.shoulders &&
          other.sleepQuality == this.sleepQuality &&
          other.vimVigor == this.vimVigor &&
          other.mentalState == this.mentalState);
}

class PreWorkoutCheckinsCompanion extends UpdateCompanion<PreWorkoutCheckin> {
  final Value<int> id;
  final Value<int> workoutId;
  final Value<Soreness?> quads;
  final Value<Soreness?> hamstrings;
  final Value<Soreness?> abs;
  final Value<Soreness?> chest;
  final Value<Soreness?> back;
  final Value<Soreness?> biceps;
  final Value<Soreness?> triceps;
  final Value<Soreness?> traps;
  final Value<Soreness?> forearms;
  final Value<Soreness?> glutes;
  final Value<Soreness?> calves;
  final Value<Soreness?> shoulders;
  final Value<CurrentState?> sleepQuality;
  final Value<CurrentState?> vimVigor;
  final Value<CurrentState?> mentalState;
  const PreWorkoutCheckinsCompanion({
    this.id = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.quads = const Value.absent(),
    this.hamstrings = const Value.absent(),
    this.abs = const Value.absent(),
    this.chest = const Value.absent(),
    this.back = const Value.absent(),
    this.biceps = const Value.absent(),
    this.triceps = const Value.absent(),
    this.traps = const Value.absent(),
    this.forearms = const Value.absent(),
    this.glutes = const Value.absent(),
    this.calves = const Value.absent(),
    this.shoulders = const Value.absent(),
    this.sleepQuality = const Value.absent(),
    this.vimVigor = const Value.absent(),
    this.mentalState = const Value.absent(),
  });
  PreWorkoutCheckinsCompanion.insert({
    this.id = const Value.absent(),
    required int workoutId,
    this.quads = const Value.absent(),
    this.hamstrings = const Value.absent(),
    this.abs = const Value.absent(),
    this.chest = const Value.absent(),
    this.back = const Value.absent(),
    this.biceps = const Value.absent(),
    this.triceps = const Value.absent(),
    this.traps = const Value.absent(),
    this.forearms = const Value.absent(),
    this.glutes = const Value.absent(),
    this.calves = const Value.absent(),
    this.shoulders = const Value.absent(),
    this.sleepQuality = const Value.absent(),
    this.vimVigor = const Value.absent(),
    this.mentalState = const Value.absent(),
  }) : workoutId = Value(workoutId);
  static Insertable<PreWorkoutCheckin> custom({
    Expression<int>? id,
    Expression<int>? workoutId,
    Expression<String>? quads,
    Expression<String>? hamstrings,
    Expression<String>? abs,
    Expression<String>? chest,
    Expression<String>? back,
    Expression<String>? biceps,
    Expression<String>? triceps,
    Expression<String>? traps,
    Expression<String>? forearms,
    Expression<String>? glutes,
    Expression<String>? calves,
    Expression<String>? shoulders,
    Expression<String>? sleepQuality,
    Expression<String>? vimVigor,
    Expression<String>? mentalState,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutId != null) 'workout_id': workoutId,
      if (quads != null) 'quads': quads,
      if (hamstrings != null) 'hamstrings': hamstrings,
      if (abs != null) 'abs': abs,
      if (chest != null) 'chest': chest,
      if (back != null) 'back': back,
      if (biceps != null) 'biceps': biceps,
      if (triceps != null) 'triceps': triceps,
      if (traps != null) 'traps': traps,
      if (forearms != null) 'forearms': forearms,
      if (glutes != null) 'glutes': glutes,
      if (calves != null) 'calves': calves,
      if (shoulders != null) 'shoulders': shoulders,
      if (sleepQuality != null) 'sleep_quality': sleepQuality,
      if (vimVigor != null) 'vim_vigor': vimVigor,
      if (mentalState != null) 'mental_state': mentalState,
    });
  }

  PreWorkoutCheckinsCompanion copyWith({
    Value<int>? id,
    Value<int>? workoutId,
    Value<Soreness?>? quads,
    Value<Soreness?>? hamstrings,
    Value<Soreness?>? abs,
    Value<Soreness?>? chest,
    Value<Soreness?>? back,
    Value<Soreness?>? biceps,
    Value<Soreness?>? triceps,
    Value<Soreness?>? traps,
    Value<Soreness?>? forearms,
    Value<Soreness?>? glutes,
    Value<Soreness?>? calves,
    Value<Soreness?>? shoulders,
    Value<CurrentState?>? sleepQuality,
    Value<CurrentState?>? vimVigor,
    Value<CurrentState?>? mentalState,
  }) {
    return PreWorkoutCheckinsCompanion(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      quads: quads ?? this.quads,
      hamstrings: hamstrings ?? this.hamstrings,
      abs: abs ?? this.abs,
      chest: chest ?? this.chest,
      back: back ?? this.back,
      biceps: biceps ?? this.biceps,
      triceps: triceps ?? this.triceps,
      traps: traps ?? this.traps,
      forearms: forearms ?? this.forearms,
      glutes: glutes ?? this.glutes,
      calves: calves ?? this.calves,
      shoulders: shoulders ?? this.shoulders,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      vimVigor: vimVigor ?? this.vimVigor,
      mentalState: mentalState ?? this.mentalState,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<int>(workoutId.value);
    }
    if (quads.present) {
      map['quads'] = Variable<String>(
        $PreWorkoutCheckinsTable.$converterquadsn.toSql(quads.value),
      );
    }
    if (hamstrings.present) {
      map['hamstrings'] = Variable<String>(
        $PreWorkoutCheckinsTable.$converterhamstringsn.toSql(hamstrings.value),
      );
    }
    if (abs.present) {
      map['abs'] = Variable<String>(
        $PreWorkoutCheckinsTable.$converterabsn.toSql(abs.value),
      );
    }
    if (chest.present) {
      map['chest'] = Variable<String>(
        $PreWorkoutCheckinsTable.$converterchestn.toSql(chest.value),
      );
    }
    if (back.present) {
      map['back'] = Variable<String>(
        $PreWorkoutCheckinsTable.$converterbackn.toSql(back.value),
      );
    }
    if (biceps.present) {
      map['biceps'] = Variable<String>(
        $PreWorkoutCheckinsTable.$converterbicepsn.toSql(biceps.value),
      );
    }
    if (triceps.present) {
      map['triceps'] = Variable<String>(
        $PreWorkoutCheckinsTable.$convertertricepsn.toSql(triceps.value),
      );
    }
    if (traps.present) {
      map['traps'] = Variable<String>(
        $PreWorkoutCheckinsTable.$convertertrapsn.toSql(traps.value),
      );
    }
    if (forearms.present) {
      map['forearms'] = Variable<String>(
        $PreWorkoutCheckinsTable.$converterforearmsn.toSql(forearms.value),
      );
    }
    if (glutes.present) {
      map['glutes'] = Variable<String>(
        $PreWorkoutCheckinsTable.$converterglutesn.toSql(glutes.value),
      );
    }
    if (calves.present) {
      map['calves'] = Variable<String>(
        $PreWorkoutCheckinsTable.$convertercalvesn.toSql(calves.value),
      );
    }
    if (shoulders.present) {
      map['shoulders'] = Variable<String>(
        $PreWorkoutCheckinsTable.$convertershouldersn.toSql(shoulders.value),
      );
    }
    if (sleepQuality.present) {
      map['sleep_quality'] = Variable<String>(
        $PreWorkoutCheckinsTable.$convertersleepQualityn.toSql(
          sleepQuality.value,
        ),
      );
    }
    if (vimVigor.present) {
      map['vim_vigor'] = Variable<String>(
        $PreWorkoutCheckinsTable.$convertervimVigorn.toSql(vimVigor.value),
      );
    }
    if (mentalState.present) {
      map['mental_state'] = Variable<String>(
        $PreWorkoutCheckinsTable.$convertermentalStaten.toSql(
          mentalState.value,
        ),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreWorkoutCheckinsCompanion(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('quads: $quads, ')
          ..write('hamstrings: $hamstrings, ')
          ..write('abs: $abs, ')
          ..write('chest: $chest, ')
          ..write('back: $back, ')
          ..write('biceps: $biceps, ')
          ..write('triceps: $triceps, ')
          ..write('traps: $traps, ')
          ..write('forearms: $forearms, ')
          ..write('glutes: $glutes, ')
          ..write('calves: $calves, ')
          ..write('shoulders: $shoulders, ')
          ..write('sleepQuality: $sleepQuality, ')
          ..write('vimVigor: $vimVigor, ')
          ..write('mentalState: $mentalState')
          ..write(')'))
        .toString();
  }
}

class $PostExerciseCheckinsTable extends PostExerciseCheckins
    with TableInfo<$PostExerciseCheckinsTable, PostExerciseCheckin> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PostExerciseCheckinsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _completedExerciseIdMeta =
      const VerificationMeta('completedExerciseId');
  @override
  late final GeneratedColumn<int> completedExerciseId = GeneratedColumn<int>(
    'completed_exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES completed_exercises (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Soreness, String> jointPain =
      GeneratedColumn<String>(
        'joint_pain',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Soreness>($PostExerciseCheckinsTable.$converterjointPain);
  @override
  List<GeneratedColumn> get $columns => [id, completedExerciseId, jointPain];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'post_exercise_checkins';
  @override
  VerificationContext validateIntegrity(
    Insertable<PostExerciseCheckin> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('completed_exercise_id')) {
      context.handle(
        _completedExerciseIdMeta,
        completedExerciseId.isAcceptableOrUnknown(
          data['completed_exercise_id']!,
          _completedExerciseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedExerciseIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PostExerciseCheckin map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PostExerciseCheckin(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      completedExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_exercise_id'],
      )!,
      jointPain: $PostExerciseCheckinsTable.$converterjointPain.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}joint_pain'],
        )!,
      ),
    );
  }

  @override
  $PostExerciseCheckinsTable createAlias(String alias) {
    return $PostExerciseCheckinsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Soreness, String, String> $converterjointPain =
      const EnumNameConverter<Soreness>(Soreness.values);
}

class PostExerciseCheckin extends DataClass
    implements Insertable<PostExerciseCheckin> {
  final int id;
  final int completedExerciseId;
  final Soreness jointPain;
  const PostExerciseCheckin({
    required this.id,
    required this.completedExerciseId,
    required this.jointPain,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['completed_exercise_id'] = Variable<int>(completedExerciseId);
    {
      map['joint_pain'] = Variable<String>(
        $PostExerciseCheckinsTable.$converterjointPain.toSql(jointPain),
      );
    }
    return map;
  }

  PostExerciseCheckinsCompanion toCompanion(bool nullToAbsent) {
    return PostExerciseCheckinsCompanion(
      id: Value(id),
      completedExerciseId: Value(completedExerciseId),
      jointPain: Value(jointPain),
    );
  }

  factory PostExerciseCheckin.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PostExerciseCheckin(
      id: serializer.fromJson<int>(json['id']),
      completedExerciseId: serializer.fromJson<int>(
        json['completedExerciseId'],
      ),
      jointPain: $PostExerciseCheckinsTable.$converterjointPain.fromJson(
        serializer.fromJson<String>(json['jointPain']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'completedExerciseId': serializer.toJson<int>(completedExerciseId),
      'jointPain': serializer.toJson<String>(
        $PostExerciseCheckinsTable.$converterjointPain.toJson(jointPain),
      ),
    };
  }

  PostExerciseCheckin copyWith({
    int? id,
    int? completedExerciseId,
    Soreness? jointPain,
  }) => PostExerciseCheckin(
    id: id ?? this.id,
    completedExerciseId: completedExerciseId ?? this.completedExerciseId,
    jointPain: jointPain ?? this.jointPain,
  );
  PostExerciseCheckin copyWithCompanion(PostExerciseCheckinsCompanion data) {
    return PostExerciseCheckin(
      id: data.id.present ? data.id.value : this.id,
      completedExerciseId: data.completedExerciseId.present
          ? data.completedExerciseId.value
          : this.completedExerciseId,
      jointPain: data.jointPain.present ? data.jointPain.value : this.jointPain,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PostExerciseCheckin(')
          ..write('id: $id, ')
          ..write('completedExerciseId: $completedExerciseId, ')
          ..write('jointPain: $jointPain')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, completedExerciseId, jointPain);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PostExerciseCheckin &&
          other.id == this.id &&
          other.completedExerciseId == this.completedExerciseId &&
          other.jointPain == this.jointPain);
}

class PostExerciseCheckinsCompanion
    extends UpdateCompanion<PostExerciseCheckin> {
  final Value<int> id;
  final Value<int> completedExerciseId;
  final Value<Soreness> jointPain;
  const PostExerciseCheckinsCompanion({
    this.id = const Value.absent(),
    this.completedExerciseId = const Value.absent(),
    this.jointPain = const Value.absent(),
  });
  PostExerciseCheckinsCompanion.insert({
    this.id = const Value.absent(),
    required int completedExerciseId,
    required Soreness jointPain,
  }) : completedExerciseId = Value(completedExerciseId),
       jointPain = Value(jointPain);
  static Insertable<PostExerciseCheckin> custom({
    Expression<int>? id,
    Expression<int>? completedExerciseId,
    Expression<String>? jointPain,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (completedExerciseId != null)
        'completed_exercise_id': completedExerciseId,
      if (jointPain != null) 'joint_pain': jointPain,
    });
  }

  PostExerciseCheckinsCompanion copyWith({
    Value<int>? id,
    Value<int>? completedExerciseId,
    Value<Soreness>? jointPain,
  }) {
    return PostExerciseCheckinsCompanion(
      id: id ?? this.id,
      completedExerciseId: completedExerciseId ?? this.completedExerciseId,
      jointPain: jointPain ?? this.jointPain,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (completedExerciseId.present) {
      map['completed_exercise_id'] = Variable<int>(completedExerciseId.value);
    }
    if (jointPain.present) {
      map['joint_pain'] = Variable<String>(
        $PostExerciseCheckinsTable.$converterjointPain.toSql(jointPain.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PostExerciseCheckinsCompanion(')
          ..write('id: $id, ')
          ..write('completedExerciseId: $completedExerciseId, ')
          ..write('jointPain: $jointPain')
          ..write(')'))
        .toString();
  }
}

class $PostMuscleGroupCheckinsTable extends PostMuscleGroupCheckins
    with TableInfo<$PostMuscleGroupCheckinsTable, PostMuscleGroupCheckin> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PostMuscleGroupCheckinsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _completedWorkoutIdMeta =
      const VerificationMeta('completedWorkoutId');
  @override
  late final GeneratedColumn<int> completedWorkoutId = GeneratedColumn<int>(
    'completed_workout_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES completed_workouts (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<MuscleGroup, String> muscleGroup =
      GeneratedColumn<String>(
        'muscle_group',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MuscleGroup>(
        $PostMuscleGroupCheckinsTable.$convertermuscleGroup,
      );
  @override
  late final GeneratedColumnWithTypeConverter<Effort, String> effortLevel =
      GeneratedColumn<String>(
        'effort_level',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Effort>(
        $PostMuscleGroupCheckinsTable.$convertereffortLevel,
      );
  @override
  late final GeneratedColumnWithTypeConverter<Volume, String> volumeLevel =
      GeneratedColumn<String>(
        'volume_level',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Volume>(
        $PostMuscleGroupCheckinsTable.$convertervolumeLevel,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    completedWorkoutId,
    muscleGroup,
    effortLevel,
    volumeLevel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'post_muscle_group_checkins';
  @override
  VerificationContext validateIntegrity(
    Insertable<PostMuscleGroupCheckin> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('completed_workout_id')) {
      context.handle(
        _completedWorkoutIdMeta,
        completedWorkoutId.isAcceptableOrUnknown(
          data['completed_workout_id']!,
          _completedWorkoutIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedWorkoutIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {completedWorkoutId, muscleGroup},
  ];
  @override
  PostMuscleGroupCheckin map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PostMuscleGroupCheckin(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      completedWorkoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_workout_id'],
      )!,
      muscleGroup: $PostMuscleGroupCheckinsTable.$convertermuscleGroup.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}muscle_group'],
        )!,
      ),
      effortLevel: $PostMuscleGroupCheckinsTable.$convertereffortLevel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}effort_level'],
        )!,
      ),
      volumeLevel: $PostMuscleGroupCheckinsTable.$convertervolumeLevel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}volume_level'],
        )!,
      ),
    );
  }

  @override
  $PostMuscleGroupCheckinsTable createAlias(String alias) {
    return $PostMuscleGroupCheckinsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MuscleGroup, String, String> $convertermuscleGroup =
      const EnumNameConverter<MuscleGroup>(MuscleGroup.values);
  static JsonTypeConverter2<Effort, String, String> $convertereffortLevel =
      const EnumNameConverter<Effort>(Effort.values);
  static JsonTypeConverter2<Volume, String, String> $convertervolumeLevel =
      const EnumNameConverter<Volume>(Volume.values);
}

class PostMuscleGroupCheckin extends DataClass
    implements Insertable<PostMuscleGroupCheckin> {
  final int id;
  final int completedWorkoutId;
  final MuscleGroup muscleGroup;
  final Effort effortLevel;
  final Volume volumeLevel;
  const PostMuscleGroupCheckin({
    required this.id,
    required this.completedWorkoutId,
    required this.muscleGroup,
    required this.effortLevel,
    required this.volumeLevel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['completed_workout_id'] = Variable<int>(completedWorkoutId);
    {
      map['muscle_group'] = Variable<String>(
        $PostMuscleGroupCheckinsTable.$convertermuscleGroup.toSql(muscleGroup),
      );
    }
    {
      map['effort_level'] = Variable<String>(
        $PostMuscleGroupCheckinsTable.$convertereffortLevel.toSql(effortLevel),
      );
    }
    {
      map['volume_level'] = Variable<String>(
        $PostMuscleGroupCheckinsTable.$convertervolumeLevel.toSql(volumeLevel),
      );
    }
    return map;
  }

  PostMuscleGroupCheckinsCompanion toCompanion(bool nullToAbsent) {
    return PostMuscleGroupCheckinsCompanion(
      id: Value(id),
      completedWorkoutId: Value(completedWorkoutId),
      muscleGroup: Value(muscleGroup),
      effortLevel: Value(effortLevel),
      volumeLevel: Value(volumeLevel),
    );
  }

  factory PostMuscleGroupCheckin.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PostMuscleGroupCheckin(
      id: serializer.fromJson<int>(json['id']),
      completedWorkoutId: serializer.fromJson<int>(json['completedWorkoutId']),
      muscleGroup: $PostMuscleGroupCheckinsTable.$convertermuscleGroup.fromJson(
        serializer.fromJson<String>(json['muscleGroup']),
      ),
      effortLevel: $PostMuscleGroupCheckinsTable.$convertereffortLevel.fromJson(
        serializer.fromJson<String>(json['effortLevel']),
      ),
      volumeLevel: $PostMuscleGroupCheckinsTable.$convertervolumeLevel.fromJson(
        serializer.fromJson<String>(json['volumeLevel']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'completedWorkoutId': serializer.toJson<int>(completedWorkoutId),
      'muscleGroup': serializer.toJson<String>(
        $PostMuscleGroupCheckinsTable.$convertermuscleGroup.toJson(muscleGroup),
      ),
      'effortLevel': serializer.toJson<String>(
        $PostMuscleGroupCheckinsTable.$convertereffortLevel.toJson(effortLevel),
      ),
      'volumeLevel': serializer.toJson<String>(
        $PostMuscleGroupCheckinsTable.$convertervolumeLevel.toJson(volumeLevel),
      ),
    };
  }

  PostMuscleGroupCheckin copyWith({
    int? id,
    int? completedWorkoutId,
    MuscleGroup? muscleGroup,
    Effort? effortLevel,
    Volume? volumeLevel,
  }) => PostMuscleGroupCheckin(
    id: id ?? this.id,
    completedWorkoutId: completedWorkoutId ?? this.completedWorkoutId,
    muscleGroup: muscleGroup ?? this.muscleGroup,
    effortLevel: effortLevel ?? this.effortLevel,
    volumeLevel: volumeLevel ?? this.volumeLevel,
  );
  PostMuscleGroupCheckin copyWithCompanion(
    PostMuscleGroupCheckinsCompanion data,
  ) {
    return PostMuscleGroupCheckin(
      id: data.id.present ? data.id.value : this.id,
      completedWorkoutId: data.completedWorkoutId.present
          ? data.completedWorkoutId.value
          : this.completedWorkoutId,
      muscleGroup: data.muscleGroup.present
          ? data.muscleGroup.value
          : this.muscleGroup,
      effortLevel: data.effortLevel.present
          ? data.effortLevel.value
          : this.effortLevel,
      volumeLevel: data.volumeLevel.present
          ? data.volumeLevel.value
          : this.volumeLevel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PostMuscleGroupCheckin(')
          ..write('id: $id, ')
          ..write('completedWorkoutId: $completedWorkoutId, ')
          ..write('muscleGroup: $muscleGroup, ')
          ..write('effortLevel: $effortLevel, ')
          ..write('volumeLevel: $volumeLevel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    completedWorkoutId,
    muscleGroup,
    effortLevel,
    volumeLevel,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PostMuscleGroupCheckin &&
          other.id == this.id &&
          other.completedWorkoutId == this.completedWorkoutId &&
          other.muscleGroup == this.muscleGroup &&
          other.effortLevel == this.effortLevel &&
          other.volumeLevel == this.volumeLevel);
}

class PostMuscleGroupCheckinsCompanion
    extends UpdateCompanion<PostMuscleGroupCheckin> {
  final Value<int> id;
  final Value<int> completedWorkoutId;
  final Value<MuscleGroup> muscleGroup;
  final Value<Effort> effortLevel;
  final Value<Volume> volumeLevel;
  const PostMuscleGroupCheckinsCompanion({
    this.id = const Value.absent(),
    this.completedWorkoutId = const Value.absent(),
    this.muscleGroup = const Value.absent(),
    this.effortLevel = const Value.absent(),
    this.volumeLevel = const Value.absent(),
  });
  PostMuscleGroupCheckinsCompanion.insert({
    this.id = const Value.absent(),
    required int completedWorkoutId,
    required MuscleGroup muscleGroup,
    required Effort effortLevel,
    required Volume volumeLevel,
  }) : completedWorkoutId = Value(completedWorkoutId),
       muscleGroup = Value(muscleGroup),
       effortLevel = Value(effortLevel),
       volumeLevel = Value(volumeLevel);
  static Insertable<PostMuscleGroupCheckin> custom({
    Expression<int>? id,
    Expression<int>? completedWorkoutId,
    Expression<String>? muscleGroup,
    Expression<String>? effortLevel,
    Expression<String>? volumeLevel,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (completedWorkoutId != null)
        'completed_workout_id': completedWorkoutId,
      if (muscleGroup != null) 'muscle_group': muscleGroup,
      if (effortLevel != null) 'effort_level': effortLevel,
      if (volumeLevel != null) 'volume_level': volumeLevel,
    });
  }

  PostMuscleGroupCheckinsCompanion copyWith({
    Value<int>? id,
    Value<int>? completedWorkoutId,
    Value<MuscleGroup>? muscleGroup,
    Value<Effort>? effortLevel,
    Value<Volume>? volumeLevel,
  }) {
    return PostMuscleGroupCheckinsCompanion(
      id: id ?? this.id,
      completedWorkoutId: completedWorkoutId ?? this.completedWorkoutId,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      effortLevel: effortLevel ?? this.effortLevel,
      volumeLevel: volumeLevel ?? this.volumeLevel,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (completedWorkoutId.present) {
      map['completed_workout_id'] = Variable<int>(completedWorkoutId.value);
    }
    if (muscleGroup.present) {
      map['muscle_group'] = Variable<String>(
        $PostMuscleGroupCheckinsTable.$convertermuscleGroup.toSql(
          muscleGroup.value,
        ),
      );
    }
    if (effortLevel.present) {
      map['effort_level'] = Variable<String>(
        $PostMuscleGroupCheckinsTable.$convertereffortLevel.toSql(
          effortLevel.value,
        ),
      );
    }
    if (volumeLevel.present) {
      map['volume_level'] = Variable<String>(
        $PostMuscleGroupCheckinsTable.$convertervolumeLevel.toSql(
          volumeLevel.value,
        ),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PostMuscleGroupCheckinsCompanion(')
          ..write('id: $id, ')
          ..write('completedWorkoutId: $completedWorkoutId, ')
          ..write('muscleGroup: $muscleGroup, ')
          ..write('effortLevel: $effortLevel, ')
          ..write('volumeLevel: $volumeLevel')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MovementsTable movements = $MovementsTable(this);
  late final $MesoTemplatesTable mesoTemplates = $MesoTemplatesTable(this);
  late final $WeekTemplatesTable weekTemplates = $WeekTemplatesTable(this);
  late final $WorkoutTemplatesTable workoutTemplates = $WorkoutTemplatesTable(
    this,
  );
  late final $ExerciseTemplatesTable exerciseTemplates =
      $ExerciseTemplatesTable(this);
  late final $MesocyclesTable mesocycles = $MesocyclesTable(this);
  late final $WeeksTable weeks = $WeeksTable(this);
  late final $WorkoutsTable workouts = $WorkoutsTable(this);
  late final $PlannedWorkoutsTable plannedWorkouts = $PlannedWorkoutsTable(
    this,
  );
  late final $CompletedWorkoutsTable completedWorkouts =
      $CompletedWorkoutsTable(this);
  late final $PlannedExercisesTable plannedExercises = $PlannedExercisesTable(
    this,
  );
  late final $CompletedExercisesTable completedExercises =
      $CompletedExercisesTable(this);
  late final $PlannedSetsTable plannedSets = $PlannedSetsTable(this);
  late final $CompletedSetsTable completedSets = $CompletedSetsTable(this);
  late final $PreWorkoutCheckinsTable preWorkoutCheckins =
      $PreWorkoutCheckinsTable(this);
  late final $PostExerciseCheckinsTable postExerciseCheckins =
      $PostExerciseCheckinsTable(this);
  late final $PostMuscleGroupCheckinsTable postMuscleGroupCheckins =
      $PostMuscleGroupCheckinsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    movements,
    mesoTemplates,
    weekTemplates,
    workoutTemplates,
    exerciseTemplates,
    mesocycles,
    weeks,
    workouts,
    plannedWorkouts,
    completedWorkouts,
    plannedExercises,
    completedExercises,
    plannedSets,
    completedSets,
    preWorkoutCheckins,
    postExerciseCheckins,
    postMuscleGroupCheckins,
  ];
}

typedef $$MovementsTableCreateCompanionBuilder =
    MovementsCompanion Function({
      Value<int> id,
      required String name,
      Value<double?> minWeight,
      Value<double?> weightDelta,
      Value<String?> link,
      Value<String?> note1,
      Value<String?> note2,
      required MuscleGroup muscleGroup,
      Value<String?> subMuscleGroup,
      required bool isRequiredReps,
      required bool isRequiredWeight,
      required bool isRequiredTime,
      Value<bool> isRequiredDistance,
      required MovementCategory category,
    });
typedef $$MovementsTableUpdateCompanionBuilder =
    MovementsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<double?> minWeight,
      Value<double?> weightDelta,
      Value<String?> link,
      Value<String?> note1,
      Value<String?> note2,
      Value<MuscleGroup> muscleGroup,
      Value<String?> subMuscleGroup,
      Value<bool> isRequiredReps,
      Value<bool> isRequiredWeight,
      Value<bool> isRequiredTime,
      Value<bool> isRequiredDistance,
      Value<MovementCategory> category,
    });

final class $$MovementsTableReferences
    extends BaseReferences<_$AppDatabase, $MovementsTable, Movement> {
  $$MovementsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ExerciseTemplatesTable, List<ExerciseTemplate>>
  _exerciseTemplatesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.exerciseTemplates,
        aliasName: $_aliasNameGenerator(
          db.movements.id,
          db.exerciseTemplates.movementId,
        ),
      );

  $$ExerciseTemplatesTableProcessedTableManager get exerciseTemplatesRefs {
    final manager = $$ExerciseTemplatesTableTableManager(
      $_db,
      $_db.exerciseTemplates,
    ).filter((f) => f.movementId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exerciseTemplatesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlannedExercisesTable, List<PlannedExercise>>
  _plannedExercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.plannedExercises,
    aliasName: $_aliasNameGenerator(
      db.movements.id,
      db.plannedExercises.movementId,
    ),
  );

  $$PlannedExercisesTableProcessedTableManager get plannedExercisesRefs {
    final manager = $$PlannedExercisesTableTableManager(
      $_db,
      $_db.plannedExercises,
    ).filter((f) => f.movementId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _plannedExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CompletedExercisesTable, List<CompletedExercise>>
  _completedExercisesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.completedExercises,
        aliasName: $_aliasNameGenerator(
          db.movements.id,
          db.completedExercises.movementId,
        ),
      );

  $$CompletedExercisesTableProcessedTableManager get completedExercisesRefs {
    final manager = $$CompletedExercisesTableTableManager(
      $_db,
      $_db.completedExercises,
    ).filter((f) => f.movementId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _completedExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MovementsTableFilterComposer
    extends Composer<_$AppDatabase, $MovementsTable> {
  $$MovementsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minWeight => $composableBuilder(
    column: $table.minWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightDelta => $composableBuilder(
    column: $table.weightDelta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note1 => $composableBuilder(
    column: $table.note1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note2 => $composableBuilder(
    column: $table.note2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MuscleGroup, MuscleGroup, String>
  get muscleGroup => $composableBuilder(
    column: $table.muscleGroup,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get subMuscleGroup => $composableBuilder(
    column: $table.subMuscleGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRequiredReps => $composableBuilder(
    column: $table.isRequiredReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRequiredWeight => $composableBuilder(
    column: $table.isRequiredWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRequiredTime => $composableBuilder(
    column: $table.isRequiredTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRequiredDistance => $composableBuilder(
    column: $table.isRequiredDistance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MovementCategory, MovementCategory, String>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  Expression<bool> exerciseTemplatesRefs(
    Expression<bool> Function($$ExerciseTemplatesTableFilterComposer f) f,
  ) {
    final $$ExerciseTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseTemplates,
      getReferencedColumn: (t) => t.movementId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.exerciseTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> plannedExercisesRefs(
    Expression<bool> Function($$PlannedExercisesTableFilterComposer f) f,
  ) {
    final $$PlannedExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedExercises,
      getReferencedColumn: (t) => t.movementId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedExercisesTableFilterComposer(
            $db: $db,
            $table: $db.plannedExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> completedExercisesRefs(
    Expression<bool> Function($$CompletedExercisesTableFilterComposer f) f,
  ) {
    final $$CompletedExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completedExercises,
      getReferencedColumn: (t) => t.movementId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedExercisesTableFilterComposer(
            $db: $db,
            $table: $db.completedExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $MovementsTable> {
  $$MovementsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minWeight => $composableBuilder(
    column: $table.minWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightDelta => $composableBuilder(
    column: $table.weightDelta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note1 => $composableBuilder(
    column: $table.note1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note2 => $composableBuilder(
    column: $table.note2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get muscleGroup => $composableBuilder(
    column: $table.muscleGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subMuscleGroup => $composableBuilder(
    column: $table.subMuscleGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRequiredReps => $composableBuilder(
    column: $table.isRequiredReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRequiredWeight => $composableBuilder(
    column: $table.isRequiredWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRequiredTime => $composableBuilder(
    column: $table.isRequiredTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRequiredDistance => $composableBuilder(
    column: $table.isRequiredDistance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MovementsTable> {
  $$MovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get minWeight =>
      $composableBuilder(column: $table.minWeight, builder: (column) => column);

  GeneratedColumn<double> get weightDelta => $composableBuilder(
    column: $table.weightDelta,
    builder: (column) => column,
  );

  GeneratedColumn<String> get link =>
      $composableBuilder(column: $table.link, builder: (column) => column);

  GeneratedColumn<String> get note1 =>
      $composableBuilder(column: $table.note1, builder: (column) => column);

  GeneratedColumn<String> get note2 =>
      $composableBuilder(column: $table.note2, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MuscleGroup, String> get muscleGroup =>
      $composableBuilder(
        column: $table.muscleGroup,
        builder: (column) => column,
      );

  GeneratedColumn<String> get subMuscleGroup => $composableBuilder(
    column: $table.subMuscleGroup,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRequiredReps => $composableBuilder(
    column: $table.isRequiredReps,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRequiredWeight => $composableBuilder(
    column: $table.isRequiredWeight,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRequiredTime => $composableBuilder(
    column: $table.isRequiredTime,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRequiredDistance => $composableBuilder(
    column: $table.isRequiredDistance,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<MovementCategory, String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  Expression<T> exerciseTemplatesRefs<T extends Object>(
    Expression<T> Function($$ExerciseTemplatesTableAnnotationComposer a) f,
  ) {
    final $$ExerciseTemplatesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.exerciseTemplates,
          getReferencedColumn: (t) => t.movementId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExerciseTemplatesTableAnnotationComposer(
                $db: $db,
                $table: $db.exerciseTemplates,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> plannedExercisesRefs<T extends Object>(
    Expression<T> Function($$PlannedExercisesTableAnnotationComposer a) f,
  ) {
    final $$PlannedExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedExercises,
      getReferencedColumn: (t) => t.movementId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.plannedExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> completedExercisesRefs<T extends Object>(
    Expression<T> Function($$CompletedExercisesTableAnnotationComposer a) f,
  ) {
    final $$CompletedExercisesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.completedExercises,
          getReferencedColumn: (t) => t.movementId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CompletedExercisesTableAnnotationComposer(
                $db: $db,
                $table: $db.completedExercises,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MovementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MovementsTable,
          Movement,
          $$MovementsTableFilterComposer,
          $$MovementsTableOrderingComposer,
          $$MovementsTableAnnotationComposer,
          $$MovementsTableCreateCompanionBuilder,
          $$MovementsTableUpdateCompanionBuilder,
          (Movement, $$MovementsTableReferences),
          Movement,
          PrefetchHooks Function({
            bool exerciseTemplatesRefs,
            bool plannedExercisesRefs,
            bool completedExercisesRefs,
          })
        > {
  $$MovementsTableTableManager(_$AppDatabase db, $MovementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double?> minWeight = const Value.absent(),
                Value<double?> weightDelta = const Value.absent(),
                Value<String?> link = const Value.absent(),
                Value<String?> note1 = const Value.absent(),
                Value<String?> note2 = const Value.absent(),
                Value<MuscleGroup> muscleGroup = const Value.absent(),
                Value<String?> subMuscleGroup = const Value.absent(),
                Value<bool> isRequiredReps = const Value.absent(),
                Value<bool> isRequiredWeight = const Value.absent(),
                Value<bool> isRequiredTime = const Value.absent(),
                Value<bool> isRequiredDistance = const Value.absent(),
                Value<MovementCategory> category = const Value.absent(),
              }) => MovementsCompanion(
                id: id,
                name: name,
                minWeight: minWeight,
                weightDelta: weightDelta,
                link: link,
                note1: note1,
                note2: note2,
                muscleGroup: muscleGroup,
                subMuscleGroup: subMuscleGroup,
                isRequiredReps: isRequiredReps,
                isRequiredWeight: isRequiredWeight,
                isRequiredTime: isRequiredTime,
                isRequiredDistance: isRequiredDistance,
                category: category,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<double?> minWeight = const Value.absent(),
                Value<double?> weightDelta = const Value.absent(),
                Value<String?> link = const Value.absent(),
                Value<String?> note1 = const Value.absent(),
                Value<String?> note2 = const Value.absent(),
                required MuscleGroup muscleGroup,
                Value<String?> subMuscleGroup = const Value.absent(),
                required bool isRequiredReps,
                required bool isRequiredWeight,
                required bool isRequiredTime,
                Value<bool> isRequiredDistance = const Value.absent(),
                required MovementCategory category,
              }) => MovementsCompanion.insert(
                id: id,
                name: name,
                minWeight: minWeight,
                weightDelta: weightDelta,
                link: link,
                note1: note1,
                note2: note2,
                muscleGroup: muscleGroup,
                subMuscleGroup: subMuscleGroup,
                isRequiredReps: isRequiredReps,
                isRequiredWeight: isRequiredWeight,
                isRequiredTime: isRequiredTime,
                isRequiredDistance: isRequiredDistance,
                category: category,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MovementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                exerciseTemplatesRefs = false,
                plannedExercisesRefs = false,
                completedExercisesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (exerciseTemplatesRefs) db.exerciseTemplates,
                    if (plannedExercisesRefs) db.plannedExercises,
                    if (completedExercisesRefs) db.completedExercises,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (exerciseTemplatesRefs)
                        await $_getPrefetchedData<
                          Movement,
                          $MovementsTable,
                          ExerciseTemplate
                        >(
                          currentTable: table,
                          referencedTable: $$MovementsTableReferences
                              ._exerciseTemplatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MovementsTableReferences(
                                db,
                                table,
                                p0,
                              ).exerciseTemplatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.movementId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (plannedExercisesRefs)
                        await $_getPrefetchedData<
                          Movement,
                          $MovementsTable,
                          PlannedExercise
                        >(
                          currentTable: table,
                          referencedTable: $$MovementsTableReferences
                              ._plannedExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MovementsTableReferences(
                                db,
                                table,
                                p0,
                              ).plannedExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.movementId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (completedExercisesRefs)
                        await $_getPrefetchedData<
                          Movement,
                          $MovementsTable,
                          CompletedExercise
                        >(
                          currentTable: table,
                          referencedTable: $$MovementsTableReferences
                              ._completedExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MovementsTableReferences(
                                db,
                                table,
                                p0,
                              ).completedExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.movementId == item.id,
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

typedef $$MovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MovementsTable,
      Movement,
      $$MovementsTableFilterComposer,
      $$MovementsTableOrderingComposer,
      $$MovementsTableAnnotationComposer,
      $$MovementsTableCreateCompanionBuilder,
      $$MovementsTableUpdateCompanionBuilder,
      (Movement, $$MovementsTableReferences),
      Movement,
      PrefetchHooks Function({
        bool exerciseTemplatesRefs,
        bool plannedExercisesRefs,
        bool completedExercisesRefs,
      })
    >;
typedef $$MesoTemplatesTableCreateCompanionBuilder =
    MesoTemplatesCompanion Function({
      Value<int> id,
      required String name,
      Value<DateTime> createdAt,
    });
typedef $$MesoTemplatesTableUpdateCompanionBuilder =
    MesoTemplatesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> createdAt,
    });

final class $$MesoTemplatesTableReferences
    extends BaseReferences<_$AppDatabase, $MesoTemplatesTable, MesoTemplate> {
  $$MesoTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$WeekTemplatesTable, List<WeekTemplate>>
  _weekTemplatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.weekTemplates,
    aliasName: $_aliasNameGenerator(
      db.mesoTemplates.id,
      db.weekTemplates.mesoTemplateId,
    ),
  );

  $$WeekTemplatesTableProcessedTableManager get weekTemplatesRefs {
    final manager = $$WeekTemplatesTableTableManager(
      $_db,
      $_db.weekTemplates,
    ).filter((f) => f.mesoTemplateId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_weekTemplatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MesocyclesTable, List<Mesocycle>>
  _mesocyclesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mesocycles,
    aliasName: $_aliasNameGenerator(
      db.mesoTemplates.id,
      db.mesocycles.mesoTemplateId,
    ),
  );

  $$MesocyclesTableProcessedTableManager get mesocyclesRefs {
    final manager = $$MesocyclesTableTableManager(
      $_db,
      $_db.mesocycles,
    ).filter((f) => f.mesoTemplateId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_mesocyclesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MesoTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $MesoTemplatesTable> {
  $$MesoTemplatesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> weekTemplatesRefs(
    Expression<bool> Function($$WeekTemplatesTableFilterComposer f) f,
  ) {
    final $$WeekTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weekTemplates,
      getReferencedColumn: (t) => t.mesoTemplateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeekTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.weekTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> mesocyclesRefs(
    Expression<bool> Function($$MesocyclesTableFilterComposer f) f,
  ) {
    final $$MesocyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mesocycles,
      getReferencedColumn: (t) => t.mesoTemplateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MesocyclesTableFilterComposer(
            $db: $db,
            $table: $db.mesocycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MesoTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $MesoTemplatesTable> {
  $$MesoTemplatesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MesoTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MesoTemplatesTable> {
  $$MesoTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> weekTemplatesRefs<T extends Object>(
    Expression<T> Function($$WeekTemplatesTableAnnotationComposer a) f,
  ) {
    final $$WeekTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weekTemplates,
      getReferencedColumn: (t) => t.mesoTemplateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeekTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.weekTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> mesocyclesRefs<T extends Object>(
    Expression<T> Function($$MesocyclesTableAnnotationComposer a) f,
  ) {
    final $$MesocyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mesocycles,
      getReferencedColumn: (t) => t.mesoTemplateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MesocyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.mesocycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MesoTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MesoTemplatesTable,
          MesoTemplate,
          $$MesoTemplatesTableFilterComposer,
          $$MesoTemplatesTableOrderingComposer,
          $$MesoTemplatesTableAnnotationComposer,
          $$MesoTemplatesTableCreateCompanionBuilder,
          $$MesoTemplatesTableUpdateCompanionBuilder,
          (MesoTemplate, $$MesoTemplatesTableReferences),
          MesoTemplate,
          PrefetchHooks Function({bool weekTemplatesRefs, bool mesocyclesRefs})
        > {
  $$MesoTemplatesTableTableManager(_$AppDatabase db, $MesoTemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MesoTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MesoTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MesoTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MesoTemplatesCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<DateTime> createdAt = const Value.absent(),
              }) => MesoTemplatesCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MesoTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({weekTemplatesRefs = false, mesocyclesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (weekTemplatesRefs) db.weekTemplates,
                    if (mesocyclesRefs) db.mesocycles,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (weekTemplatesRefs)
                        await $_getPrefetchedData<
                          MesoTemplate,
                          $MesoTemplatesTable,
                          WeekTemplate
                        >(
                          currentTable: table,
                          referencedTable: $$MesoTemplatesTableReferences
                              ._weekTemplatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MesoTemplatesTableReferences(
                                db,
                                table,
                                p0,
                              ).weekTemplatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.mesoTemplateId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (mesocyclesRefs)
                        await $_getPrefetchedData<
                          MesoTemplate,
                          $MesoTemplatesTable,
                          Mesocycle
                        >(
                          currentTable: table,
                          referencedTable: $$MesoTemplatesTableReferences
                              ._mesocyclesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MesoTemplatesTableReferences(
                                db,
                                table,
                                p0,
                              ).mesocyclesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.mesoTemplateId == item.id,
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

typedef $$MesoTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MesoTemplatesTable,
      MesoTemplate,
      $$MesoTemplatesTableFilterComposer,
      $$MesoTemplatesTableOrderingComposer,
      $$MesoTemplatesTableAnnotationComposer,
      $$MesoTemplatesTableCreateCompanionBuilder,
      $$MesoTemplatesTableUpdateCompanionBuilder,
      (MesoTemplate, $$MesoTemplatesTableReferences),
      MesoTemplate,
      PrefetchHooks Function({bool weekTemplatesRefs, bool mesocyclesRefs})
    >;
typedef $$WeekTemplatesTableCreateCompanionBuilder =
    WeekTemplatesCompanion Function({
      Value<int> id,
      required int mesoTemplateId,
      required String name,
      required int workoutCount,
    });
typedef $$WeekTemplatesTableUpdateCompanionBuilder =
    WeekTemplatesCompanion Function({
      Value<int> id,
      Value<int> mesoTemplateId,
      Value<String> name,
      Value<int> workoutCount,
    });

final class $$WeekTemplatesTableReferences
    extends BaseReferences<_$AppDatabase, $WeekTemplatesTable, WeekTemplate> {
  $$WeekTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MesoTemplatesTable _mesoTemplateIdTable(_$AppDatabase db) =>
      db.mesoTemplates.createAlias(
        $_aliasNameGenerator(
          db.weekTemplates.mesoTemplateId,
          db.mesoTemplates.id,
        ),
      );

  $$MesoTemplatesTableProcessedTableManager get mesoTemplateId {
    final $_column = $_itemColumn<int>('meso_template_id')!;

    final manager = $$MesoTemplatesTableTableManager(
      $_db,
      $_db.mesoTemplates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mesoTemplateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WorkoutTemplatesTable, List<WorkoutTemplate>>
  _workoutTemplatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutTemplates,
    aliasName: $_aliasNameGenerator(
      db.weekTemplates.id,
      db.workoutTemplates.weekTemplateId,
    ),
  );

  $$WorkoutTemplatesTableProcessedTableManager get workoutTemplatesRefs {
    final manager = $$WorkoutTemplatesTableTableManager(
      $_db,
      $_db.workoutTemplates,
    ).filter((f) => f.weekTemplateId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _workoutTemplatesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WeekTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $WeekTemplatesTable> {
  $$WeekTemplatesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get workoutCount => $composableBuilder(
    column: $table.workoutCount,
    builder: (column) => ColumnFilters(column),
  );

  $$MesoTemplatesTableFilterComposer get mesoTemplateId {
    final $$MesoTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mesoTemplateId,
      referencedTable: $db.mesoTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MesoTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.mesoTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> workoutTemplatesRefs(
    Expression<bool> Function($$WorkoutTemplatesTableFilterComposer f) f,
  ) {
    final $$WorkoutTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutTemplates,
      getReferencedColumn: (t) => t.weekTemplateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.workoutTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WeekTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $WeekTemplatesTable> {
  $$WeekTemplatesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get workoutCount => $composableBuilder(
    column: $table.workoutCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$MesoTemplatesTableOrderingComposer get mesoTemplateId {
    final $$MesoTemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mesoTemplateId,
      referencedTable: $db.mesoTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MesoTemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.mesoTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeekTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeekTemplatesTable> {
  $$WeekTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get workoutCount => $composableBuilder(
    column: $table.workoutCount,
    builder: (column) => column,
  );

  $$MesoTemplatesTableAnnotationComposer get mesoTemplateId {
    final $$MesoTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mesoTemplateId,
      referencedTable: $db.mesoTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MesoTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.mesoTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> workoutTemplatesRefs<T extends Object>(
    Expression<T> Function($$WorkoutTemplatesTableAnnotationComposer a) f,
  ) {
    final $$WorkoutTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutTemplates,
      getReferencedColumn: (t) => t.weekTemplateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WeekTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeekTemplatesTable,
          WeekTemplate,
          $$WeekTemplatesTableFilterComposer,
          $$WeekTemplatesTableOrderingComposer,
          $$WeekTemplatesTableAnnotationComposer,
          $$WeekTemplatesTableCreateCompanionBuilder,
          $$WeekTemplatesTableUpdateCompanionBuilder,
          (WeekTemplate, $$WeekTemplatesTableReferences),
          WeekTemplate,
          PrefetchHooks Function({
            bool mesoTemplateId,
            bool workoutTemplatesRefs,
          })
        > {
  $$WeekTemplatesTableTableManager(_$AppDatabase db, $WeekTemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeekTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeekTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeekTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> mesoTemplateId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> workoutCount = const Value.absent(),
              }) => WeekTemplatesCompanion(
                id: id,
                mesoTemplateId: mesoTemplateId,
                name: name,
                workoutCount: workoutCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int mesoTemplateId,
                required String name,
                required int workoutCount,
              }) => WeekTemplatesCompanion.insert(
                id: id,
                mesoTemplateId: mesoTemplateId,
                name: name,
                workoutCount: workoutCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WeekTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({mesoTemplateId = false, workoutTemplatesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workoutTemplatesRefs) db.workoutTemplates,
                  ],
                  addJoins:
                      <
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
                        if (mesoTemplateId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.mesoTemplateId,
                                    referencedTable:
                                        $$WeekTemplatesTableReferences
                                            ._mesoTemplateIdTable(db),
                                    referencedColumn:
                                        $$WeekTemplatesTableReferences
                                            ._mesoTemplateIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workoutTemplatesRefs)
                        await $_getPrefetchedData<
                          WeekTemplate,
                          $WeekTemplatesTable,
                          WorkoutTemplate
                        >(
                          currentTable: table,
                          referencedTable: $$WeekTemplatesTableReferences
                              ._workoutTemplatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WeekTemplatesTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutTemplatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.weekTemplateId == item.id,
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

typedef $$WeekTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeekTemplatesTable,
      WeekTemplate,
      $$WeekTemplatesTableFilterComposer,
      $$WeekTemplatesTableOrderingComposer,
      $$WeekTemplatesTableAnnotationComposer,
      $$WeekTemplatesTableCreateCompanionBuilder,
      $$WeekTemplatesTableUpdateCompanionBuilder,
      (WeekTemplate, $$WeekTemplatesTableReferences),
      WeekTemplate,
      PrefetchHooks Function({bool mesoTemplateId, bool workoutTemplatesRefs})
    >;
typedef $$WorkoutTemplatesTableCreateCompanionBuilder =
    WorkoutTemplatesCompanion Function({
      Value<int> id,
      required int weekTemplateId,
      required String name,
      required bool isRestDay,
      required int dayIndex,
    });
typedef $$WorkoutTemplatesTableUpdateCompanionBuilder =
    WorkoutTemplatesCompanion Function({
      Value<int> id,
      Value<int> weekTemplateId,
      Value<String> name,
      Value<bool> isRestDay,
      Value<int> dayIndex,
    });

final class $$WorkoutTemplatesTableReferences
    extends
        BaseReferences<_$AppDatabase, $WorkoutTemplatesTable, WorkoutTemplate> {
  $$WorkoutTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WeekTemplatesTable _weekTemplateIdTable(_$AppDatabase db) =>
      db.weekTemplates.createAlias(
        $_aliasNameGenerator(
          db.workoutTemplates.weekTemplateId,
          db.weekTemplates.id,
        ),
      );

  $$WeekTemplatesTableProcessedTableManager get weekTemplateId {
    final $_column = $_itemColumn<int>('week_template_id')!;

    final manager = $$WeekTemplatesTableTableManager(
      $_db,
      $_db.weekTemplates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_weekTemplateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ExerciseTemplatesTable, List<ExerciseTemplate>>
  _exerciseTemplatesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.exerciseTemplates,
        aliasName: $_aliasNameGenerator(
          db.workoutTemplates.id,
          db.exerciseTemplates.workoutTemplateId,
        ),
      );

  $$ExerciseTemplatesTableProcessedTableManager get exerciseTemplatesRefs {
    final manager = $$ExerciseTemplatesTableTableManager(
      $_db,
      $_db.exerciseTemplates,
    ).filter((f) => f.workoutTemplateId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exerciseTemplatesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkoutTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRestDay => $composableBuilder(
    column: $table.isRestDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayIndex => $composableBuilder(
    column: $table.dayIndex,
    builder: (column) => ColumnFilters(column),
  );

  $$WeekTemplatesTableFilterComposer get weekTemplateId {
    final $$WeekTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.weekTemplateId,
      referencedTable: $db.weekTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeekTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.weekTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> exerciseTemplatesRefs(
    Expression<bool> Function($$ExerciseTemplatesTableFilterComposer f) f,
  ) {
    final $$ExerciseTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseTemplates,
      getReferencedColumn: (t) => t.workoutTemplateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.exerciseTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRestDay => $composableBuilder(
    column: $table.isRestDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayIndex => $composableBuilder(
    column: $table.dayIndex,
    builder: (column) => ColumnOrderings(column),
  );

  $$WeekTemplatesTableOrderingComposer get weekTemplateId {
    final $$WeekTemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.weekTemplateId,
      referencedTable: $db.weekTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeekTemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.weekTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isRestDay =>
      $composableBuilder(column: $table.isRestDay, builder: (column) => column);

  GeneratedColumn<int> get dayIndex =>
      $composableBuilder(column: $table.dayIndex, builder: (column) => column);

  $$WeekTemplatesTableAnnotationComposer get weekTemplateId {
    final $$WeekTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.weekTemplateId,
      referencedTable: $db.weekTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeekTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.weekTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> exerciseTemplatesRefs<T extends Object>(
    Expression<T> Function($$ExerciseTemplatesTableAnnotationComposer a) f,
  ) {
    final $$ExerciseTemplatesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.exerciseTemplates,
          getReferencedColumn: (t) => t.workoutTemplateId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExerciseTemplatesTableAnnotationComposer(
                $db: $db,
                $table: $db.exerciseTemplates,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$WorkoutTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutTemplatesTable,
          WorkoutTemplate,
          $$WorkoutTemplatesTableFilterComposer,
          $$WorkoutTemplatesTableOrderingComposer,
          $$WorkoutTemplatesTableAnnotationComposer,
          $$WorkoutTemplatesTableCreateCompanionBuilder,
          $$WorkoutTemplatesTableUpdateCompanionBuilder,
          (WorkoutTemplate, $$WorkoutTemplatesTableReferences),
          WorkoutTemplate,
          PrefetchHooks Function({
            bool weekTemplateId,
            bool exerciseTemplatesRefs,
          })
        > {
  $$WorkoutTemplatesTableTableManager(
    _$AppDatabase db,
    $WorkoutTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> weekTemplateId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isRestDay = const Value.absent(),
                Value<int> dayIndex = const Value.absent(),
              }) => WorkoutTemplatesCompanion(
                id: id,
                weekTemplateId: weekTemplateId,
                name: name,
                isRestDay: isRestDay,
                dayIndex: dayIndex,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int weekTemplateId,
                required String name,
                required bool isRestDay,
                required int dayIndex,
              }) => WorkoutTemplatesCompanion.insert(
                id: id,
                weekTemplateId: weekTemplateId,
                name: name,
                isRestDay: isRestDay,
                dayIndex: dayIndex,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkoutTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({weekTemplateId = false, exerciseTemplatesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (exerciseTemplatesRefs) db.exerciseTemplates,
                  ],
                  addJoins:
                      <
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
                        if (weekTemplateId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.weekTemplateId,
                                    referencedTable:
                                        $$WorkoutTemplatesTableReferences
                                            ._weekTemplateIdTable(db),
                                    referencedColumn:
                                        $$WorkoutTemplatesTableReferences
                                            ._weekTemplateIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (exerciseTemplatesRefs)
                        await $_getPrefetchedData<
                          WorkoutTemplate,
                          $WorkoutTemplatesTable,
                          ExerciseTemplate
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutTemplatesTableReferences
                              ._exerciseTemplatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutTemplatesTableReferences(
                                db,
                                table,
                                p0,
                              ).exerciseTemplatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workoutTemplateId == item.id,
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

typedef $$WorkoutTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutTemplatesTable,
      WorkoutTemplate,
      $$WorkoutTemplatesTableFilterComposer,
      $$WorkoutTemplatesTableOrderingComposer,
      $$WorkoutTemplatesTableAnnotationComposer,
      $$WorkoutTemplatesTableCreateCompanionBuilder,
      $$WorkoutTemplatesTableUpdateCompanionBuilder,
      (WorkoutTemplate, $$WorkoutTemplatesTableReferences),
      WorkoutTemplate,
      PrefetchHooks Function({bool weekTemplateId, bool exerciseTemplatesRefs})
    >;
typedef $$ExerciseTemplatesTableCreateCompanionBuilder =
    ExerciseTemplatesCompanion Function({
      Value<int> id,
      required int workoutTemplateId,
      required int movementId,
      required int exerciseIndex,
    });
typedef $$ExerciseTemplatesTableUpdateCompanionBuilder =
    ExerciseTemplatesCompanion Function({
      Value<int> id,
      Value<int> workoutTemplateId,
      Value<int> movementId,
      Value<int> exerciseIndex,
    });

final class $$ExerciseTemplatesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ExerciseTemplatesTable,
          ExerciseTemplate
        > {
  $$ExerciseTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkoutTemplatesTable _workoutTemplateIdTable(_$AppDatabase db) =>
      db.workoutTemplates.createAlias(
        $_aliasNameGenerator(
          db.exerciseTemplates.workoutTemplateId,
          db.workoutTemplates.id,
        ),
      );

  $$WorkoutTemplatesTableProcessedTableManager get workoutTemplateId {
    final $_column = $_itemColumn<int>('workout_template_id')!;

    final manager = $$WorkoutTemplatesTableTableManager(
      $_db,
      $_db.workoutTemplates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutTemplateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MovementsTable _movementIdTable(_$AppDatabase db) =>
      db.movements.createAlias(
        $_aliasNameGenerator(db.exerciseTemplates.movementId, db.movements.id),
      );

  $$MovementsTableProcessedTableManager get movementId {
    final $_column = $_itemColumn<int>('movement_id')!;

    final manager = $$MovementsTableTableManager(
      $_db,
      $_db.movements,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_movementIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExerciseTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseTemplatesTable> {
  $$ExerciseTemplatesTableFilterComposer({
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

  ColumnFilters<int> get exerciseIndex => $composableBuilder(
    column: $table.exerciseIndex,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutTemplatesTableFilterComposer get workoutTemplateId {
    final $$WorkoutTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutTemplateId,
      referencedTable: $db.workoutTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.workoutTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovementsTableFilterComposer get movementId {
    final $$MovementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movementId,
      referencedTable: $db.movements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovementsTableFilterComposer(
            $db: $db,
            $table: $db.movements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseTemplatesTable> {
  $$ExerciseTemplatesTableOrderingComposer({
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

  ColumnOrderings<int> get exerciseIndex => $composableBuilder(
    column: $table.exerciseIndex,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutTemplatesTableOrderingComposer get workoutTemplateId {
    final $$WorkoutTemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutTemplateId,
      referencedTable: $db.workoutTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutTemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.workoutTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovementsTableOrderingComposer get movementId {
    final $$MovementsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movementId,
      referencedTable: $db.movements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovementsTableOrderingComposer(
            $db: $db,
            $table: $db.movements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseTemplatesTable> {
  $$ExerciseTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get exerciseIndex => $composableBuilder(
    column: $table.exerciseIndex,
    builder: (column) => column,
  );

  $$WorkoutTemplatesTableAnnotationComposer get workoutTemplateId {
    final $$WorkoutTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutTemplateId,
      referencedTable: $db.workoutTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovementsTableAnnotationComposer get movementId {
    final $$MovementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movementId,
      referencedTable: $db.movements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovementsTableAnnotationComposer(
            $db: $db,
            $table: $db.movements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseTemplatesTable,
          ExerciseTemplate,
          $$ExerciseTemplatesTableFilterComposer,
          $$ExerciseTemplatesTableOrderingComposer,
          $$ExerciseTemplatesTableAnnotationComposer,
          $$ExerciseTemplatesTableCreateCompanionBuilder,
          $$ExerciseTemplatesTableUpdateCompanionBuilder,
          (ExerciseTemplate, $$ExerciseTemplatesTableReferences),
          ExerciseTemplate,
          PrefetchHooks Function({bool workoutTemplateId, bool movementId})
        > {
  $$ExerciseTemplatesTableTableManager(
    _$AppDatabase db,
    $ExerciseTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseTemplatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> workoutTemplateId = const Value.absent(),
                Value<int> movementId = const Value.absent(),
                Value<int> exerciseIndex = const Value.absent(),
              }) => ExerciseTemplatesCompanion(
                id: id,
                workoutTemplateId: workoutTemplateId,
                movementId: movementId,
                exerciseIndex: exerciseIndex,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int workoutTemplateId,
                required int movementId,
                required int exerciseIndex,
              }) => ExerciseTemplatesCompanion.insert(
                id: id,
                workoutTemplateId: workoutTemplateId,
                movementId: movementId,
                exerciseIndex: exerciseIndex,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExerciseTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({workoutTemplateId = false, movementId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
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
                        if (workoutTemplateId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workoutTemplateId,
                                    referencedTable:
                                        $$ExerciseTemplatesTableReferences
                                            ._workoutTemplateIdTable(db),
                                    referencedColumn:
                                        $$ExerciseTemplatesTableReferences
                                            ._workoutTemplateIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (movementId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.movementId,
                                    referencedTable:
                                        $$ExerciseTemplatesTableReferences
                                            ._movementIdTable(db),
                                    referencedColumn:
                                        $$ExerciseTemplatesTableReferences
                                            ._movementIdTable(db)
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

typedef $$ExerciseTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseTemplatesTable,
      ExerciseTemplate,
      $$ExerciseTemplatesTableFilterComposer,
      $$ExerciseTemplatesTableOrderingComposer,
      $$ExerciseTemplatesTableAnnotationComposer,
      $$ExerciseTemplatesTableCreateCompanionBuilder,
      $$ExerciseTemplatesTableUpdateCompanionBuilder,
      (ExerciseTemplate, $$ExerciseTemplatesTableReferences),
      ExerciseTemplate,
      PrefetchHooks Function({bool workoutTemplateId, bool movementId})
    >;
typedef $$MesocyclesTableCreateCompanionBuilder =
    MesocyclesCompanion Function({
      Value<int> id,
      required int mesoTemplateId,
      required String name,
      required int totalWeekCount,
      required DateTime createdAt,
      Value<DateTime?> completedAt,
    });
typedef $$MesocyclesTableUpdateCompanionBuilder =
    MesocyclesCompanion Function({
      Value<int> id,
      Value<int> mesoTemplateId,
      Value<String> name,
      Value<int> totalWeekCount,
      Value<DateTime> createdAt,
      Value<DateTime?> completedAt,
    });

final class $$MesocyclesTableReferences
    extends BaseReferences<_$AppDatabase, $MesocyclesTable, Mesocycle> {
  $$MesocyclesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MesoTemplatesTable _mesoTemplateIdTable(_$AppDatabase db) =>
      db.mesoTemplates.createAlias(
        $_aliasNameGenerator(db.mesocycles.mesoTemplateId, db.mesoTemplates.id),
      );

  $$MesoTemplatesTableProcessedTableManager get mesoTemplateId {
    final $_column = $_itemColumn<int>('meso_template_id')!;

    final manager = $$MesoTemplatesTableTableManager(
      $_db,
      $_db.mesoTemplates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mesoTemplateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WeeksTable, List<Week>> _weeksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.weeks,
    aliasName: $_aliasNameGenerator(db.mesocycles.id, db.weeks.mesocycleId),
  );

  $$WeeksTableProcessedTableManager get weeksRefs {
    final manager = $$WeeksTableTableManager(
      $_db,
      $_db.weeks,
    ).filter((f) => f.mesocycleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_weeksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MesocyclesTableFilterComposer
    extends Composer<_$AppDatabase, $MesocyclesTable> {
  $$MesocyclesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalWeekCount => $composableBuilder(
    column: $table.totalWeekCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MesoTemplatesTableFilterComposer get mesoTemplateId {
    final $$MesoTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mesoTemplateId,
      referencedTable: $db.mesoTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MesoTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.mesoTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> weeksRefs(
    Expression<bool> Function($$WeeksTableFilterComposer f) f,
  ) {
    final $$WeeksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weeks,
      getReferencedColumn: (t) => t.mesocycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeeksTableFilterComposer(
            $db: $db,
            $table: $db.weeks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MesocyclesTableOrderingComposer
    extends Composer<_$AppDatabase, $MesocyclesTable> {
  $$MesocyclesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalWeekCount => $composableBuilder(
    column: $table.totalWeekCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MesoTemplatesTableOrderingComposer get mesoTemplateId {
    final $$MesoTemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mesoTemplateId,
      referencedTable: $db.mesoTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MesoTemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.mesoTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MesocyclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MesocyclesTable> {
  $$MesocyclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get totalWeekCount => $composableBuilder(
    column: $table.totalWeekCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  $$MesoTemplatesTableAnnotationComposer get mesoTemplateId {
    final $$MesoTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mesoTemplateId,
      referencedTable: $db.mesoTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MesoTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.mesoTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> weeksRefs<T extends Object>(
    Expression<T> Function($$WeeksTableAnnotationComposer a) f,
  ) {
    final $$WeeksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weeks,
      getReferencedColumn: (t) => t.mesocycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeeksTableAnnotationComposer(
            $db: $db,
            $table: $db.weeks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MesocyclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MesocyclesTable,
          Mesocycle,
          $$MesocyclesTableFilterComposer,
          $$MesocyclesTableOrderingComposer,
          $$MesocyclesTableAnnotationComposer,
          $$MesocyclesTableCreateCompanionBuilder,
          $$MesocyclesTableUpdateCompanionBuilder,
          (Mesocycle, $$MesocyclesTableReferences),
          Mesocycle,
          PrefetchHooks Function({bool mesoTemplateId, bool weeksRefs})
        > {
  $$MesocyclesTableTableManager(_$AppDatabase db, $MesocyclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MesocyclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MesocyclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MesocyclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> mesoTemplateId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> totalWeekCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
              }) => MesocyclesCompanion(
                id: id,
                mesoTemplateId: mesoTemplateId,
                name: name,
                totalWeekCount: totalWeekCount,
                createdAt: createdAt,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int mesoTemplateId,
                required String name,
                required int totalWeekCount,
                required DateTime createdAt,
                Value<DateTime?> completedAt = const Value.absent(),
              }) => MesocyclesCompanion.insert(
                id: id,
                mesoTemplateId: mesoTemplateId,
                name: name,
                totalWeekCount: totalWeekCount,
                createdAt: createdAt,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MesocyclesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mesoTemplateId = false, weeksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (weeksRefs) db.weeks],
              addJoins:
                  <
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
                    if (mesoTemplateId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.mesoTemplateId,
                                referencedTable: $$MesocyclesTableReferences
                                    ._mesoTemplateIdTable(db),
                                referencedColumn: $$MesocyclesTableReferences
                                    ._mesoTemplateIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (weeksRefs)
                    await $_getPrefetchedData<
                      Mesocycle,
                      $MesocyclesTable,
                      Week
                    >(
                      currentTable: table,
                      referencedTable: $$MesocyclesTableReferences
                          ._weeksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MesocyclesTableReferences(db, table, p0).weeksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.mesocycleId == item.id,
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

typedef $$MesocyclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MesocyclesTable,
      Mesocycle,
      $$MesocyclesTableFilterComposer,
      $$MesocyclesTableOrderingComposer,
      $$MesocyclesTableAnnotationComposer,
      $$MesocyclesTableCreateCompanionBuilder,
      $$MesocyclesTableUpdateCompanionBuilder,
      (Mesocycle, $$MesocyclesTableReferences),
      Mesocycle,
      PrefetchHooks Function({bool mesoTemplateId, bool weeksRefs})
    >;
typedef $$WeeksTableCreateCompanionBuilder =
    WeeksCompanion Function({
      Value<int> id,
      required int mesocycleId,
      required int weekNumber,
      required WeekGoal goal,
      required DateTime createdAt,
    });
typedef $$WeeksTableUpdateCompanionBuilder =
    WeeksCompanion Function({
      Value<int> id,
      Value<int> mesocycleId,
      Value<int> weekNumber,
      Value<WeekGoal> goal,
      Value<DateTime> createdAt,
    });

final class $$WeeksTableReferences
    extends BaseReferences<_$AppDatabase, $WeeksTable, Week> {
  $$WeeksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MesocyclesTable _mesocycleIdTable(_$AppDatabase db) =>
      db.mesocycles.createAlias(
        $_aliasNameGenerator(db.weeks.mesocycleId, db.mesocycles.id),
      );

  $$MesocyclesTableProcessedTableManager get mesocycleId {
    final $_column = $_itemColumn<int>('mesocycle_id')!;

    final manager = $$MesocyclesTableTableManager(
      $_db,
      $_db.mesocycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mesocycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WorkoutsTable, List<Workout>> _workoutsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.workouts,
    aliasName: $_aliasNameGenerator(db.weeks.id, db.workouts.weekId),
  );

  $$WorkoutsTableProcessedTableManager get workoutsRefs {
    final manager = $$WorkoutsTableTableManager(
      $_db,
      $_db.workouts,
    ).filter((f) => f.weekId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WeeksTableFilterComposer extends Composer<_$AppDatabase, $WeeksTable> {
  $$WeeksTableFilterComposer({
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

  ColumnFilters<int> get weekNumber => $composableBuilder(
    column: $table.weekNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WeekGoal, WeekGoal, String> get goal =>
      $composableBuilder(
        column: $table.goal,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MesocyclesTableFilterComposer get mesocycleId {
    final $$MesocyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mesocycleId,
      referencedTable: $db.mesocycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MesocyclesTableFilterComposer(
            $db: $db,
            $table: $db.mesocycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> workoutsRefs(
    Expression<bool> Function($$WorkoutsTableFilterComposer f) f,
  ) {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.weekId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WeeksTableOrderingComposer
    extends Composer<_$AppDatabase, $WeeksTable> {
  $$WeeksTableOrderingComposer({
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

  ColumnOrderings<int> get weekNumber => $composableBuilder(
    column: $table.weekNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MesocyclesTableOrderingComposer get mesocycleId {
    final $$MesocyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mesocycleId,
      referencedTable: $db.mesocycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MesocyclesTableOrderingComposer(
            $db: $db,
            $table: $db.mesocycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeeksTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeeksTable> {
  $$WeeksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get weekNumber => $composableBuilder(
    column: $table.weekNumber,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<WeekGoal, String> get goal =>
      $composableBuilder(column: $table.goal, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$MesocyclesTableAnnotationComposer get mesocycleId {
    final $$MesocyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mesocycleId,
      referencedTable: $db.mesocycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MesocyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.mesocycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> workoutsRefs<T extends Object>(
    Expression<T> Function($$WorkoutsTableAnnotationComposer a) f,
  ) {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.weekId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WeeksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeeksTable,
          Week,
          $$WeeksTableFilterComposer,
          $$WeeksTableOrderingComposer,
          $$WeeksTableAnnotationComposer,
          $$WeeksTableCreateCompanionBuilder,
          $$WeeksTableUpdateCompanionBuilder,
          (Week, $$WeeksTableReferences),
          Week,
          PrefetchHooks Function({bool mesocycleId, bool workoutsRefs})
        > {
  $$WeeksTableTableManager(_$AppDatabase db, $WeeksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeeksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeeksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeeksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> mesocycleId = const Value.absent(),
                Value<int> weekNumber = const Value.absent(),
                Value<WeekGoal> goal = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => WeeksCompanion(
                id: id,
                mesocycleId: mesocycleId,
                weekNumber: weekNumber,
                goal: goal,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int mesocycleId,
                required int weekNumber,
                required WeekGoal goal,
                required DateTime createdAt,
              }) => WeeksCompanion.insert(
                id: id,
                mesocycleId: mesocycleId,
                weekNumber: weekNumber,
                goal: goal,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$WeeksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({mesocycleId = false, workoutsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (workoutsRefs) db.workouts],
              addJoins:
                  <
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
                    if (mesocycleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.mesocycleId,
                                referencedTable: $$WeeksTableReferences
                                    ._mesocycleIdTable(db),
                                referencedColumn: $$WeeksTableReferences
                                    ._mesocycleIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workoutsRefs)
                    await $_getPrefetchedData<Week, $WeeksTable, Workout>(
                      currentTable: table,
                      referencedTable: $$WeeksTableReferences
                          ._workoutsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$WeeksTableReferences(db, table, p0).workoutsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.weekId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WeeksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeeksTable,
      Week,
      $$WeeksTableFilterComposer,
      $$WeeksTableOrderingComposer,
      $$WeeksTableAnnotationComposer,
      $$WeeksTableCreateCompanionBuilder,
      $$WeeksTableUpdateCompanionBuilder,
      (Week, $$WeeksTableReferences),
      Week,
      PrefetchHooks Function({bool mesocycleId, bool workoutsRefs})
    >;
typedef $$WorkoutsTableCreateCompanionBuilder =
    WorkoutsCompanion Function({
      Value<int> id,
      required int weekId,
      required String name,
      required int orderIndex,
      required bool isRestDay,
    });
typedef $$WorkoutsTableUpdateCompanionBuilder =
    WorkoutsCompanion Function({
      Value<int> id,
      Value<int> weekId,
      Value<String> name,
      Value<int> orderIndex,
      Value<bool> isRestDay,
    });

final class $$WorkoutsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutsTable, Workout> {
  $$WorkoutsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WeeksTable _weekIdTable(_$AppDatabase db) => db.weeks.createAlias(
    $_aliasNameGenerator(db.workouts.weekId, db.weeks.id),
  );

  $$WeeksTableProcessedTableManager get weekId {
    final $_column = $_itemColumn<int>('week_id')!;

    final manager = $$WeeksTableTableManager(
      $_db,
      $_db.weeks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_weekIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PlannedWorkoutsTable, List<PlannedWorkout>>
  _plannedWorkoutsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.plannedWorkouts,
    aliasName: $_aliasNameGenerator(
      db.workouts.id,
      db.plannedWorkouts.workoutId,
    ),
  );

  $$PlannedWorkoutsTableProcessedTableManager get plannedWorkoutsRefs {
    final manager = $$PlannedWorkoutsTableTableManager(
      $_db,
      $_db.plannedWorkouts,
    ).filter((f) => f.workoutId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _plannedWorkoutsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CompletedWorkoutsTable, List<CompletedWorkout>>
  _completedWorkoutsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.completedWorkouts,
        aliasName: $_aliasNameGenerator(
          db.workouts.id,
          db.completedWorkouts.workoutId,
        ),
      );

  $$CompletedWorkoutsTableProcessedTableManager get completedWorkoutsRefs {
    final manager = $$CompletedWorkoutsTableTableManager(
      $_db,
      $_db.completedWorkouts,
    ).filter((f) => f.workoutId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _completedWorkoutsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PreWorkoutCheckinsTable, List<PreWorkoutCheckin>>
  _preWorkoutCheckinsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.preWorkoutCheckins,
        aliasName: $_aliasNameGenerator(
          db.workouts.id,
          db.preWorkoutCheckins.workoutId,
        ),
      );

  $$PreWorkoutCheckinsTableProcessedTableManager get preWorkoutCheckinsRefs {
    final manager = $$PreWorkoutCheckinsTableTableManager(
      $_db,
      $_db.preWorkoutCheckins,
    ).filter((f) => f.workoutId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _preWorkoutCheckinsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRestDay => $composableBuilder(
    column: $table.isRestDay,
    builder: (column) => ColumnFilters(column),
  );

  $$WeeksTableFilterComposer get weekId {
    final $$WeeksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.weekId,
      referencedTable: $db.weeks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeeksTableFilterComposer(
            $db: $db,
            $table: $db.weeks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> plannedWorkoutsRefs(
    Expression<bool> Function($$PlannedWorkoutsTableFilterComposer f) f,
  ) {
    final $$PlannedWorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedWorkouts,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedWorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.plannedWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> completedWorkoutsRefs(
    Expression<bool> Function($$CompletedWorkoutsTableFilterComposer f) f,
  ) {
    final $$CompletedWorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completedWorkouts,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedWorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.completedWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> preWorkoutCheckinsRefs(
    Expression<bool> Function($$PreWorkoutCheckinsTableFilterComposer f) f,
  ) {
    final $$PreWorkoutCheckinsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.preWorkoutCheckins,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PreWorkoutCheckinsTableFilterComposer(
            $db: $db,
            $table: $db.preWorkoutCheckins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRestDay => $composableBuilder(
    column: $table.isRestDay,
    builder: (column) => ColumnOrderings(column),
  );

  $$WeeksTableOrderingComposer get weekId {
    final $$WeeksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.weekId,
      referencedTable: $db.weeks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeeksTableOrderingComposer(
            $db: $db,
            $table: $db.weeks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRestDay =>
      $composableBuilder(column: $table.isRestDay, builder: (column) => column);

  $$WeeksTableAnnotationComposer get weekId {
    final $$WeeksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.weekId,
      referencedTable: $db.weeks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeeksTableAnnotationComposer(
            $db: $db,
            $table: $db.weeks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> plannedWorkoutsRefs<T extends Object>(
    Expression<T> Function($$PlannedWorkoutsTableAnnotationComposer a) f,
  ) {
    final $$PlannedWorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedWorkouts,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedWorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.plannedWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> completedWorkoutsRefs<T extends Object>(
    Expression<T> Function($$CompletedWorkoutsTableAnnotationComposer a) f,
  ) {
    final $$CompletedWorkoutsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.completedWorkouts,
          getReferencedColumn: (t) => t.workoutId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CompletedWorkoutsTableAnnotationComposer(
                $db: $db,
                $table: $db.completedWorkouts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> preWorkoutCheckinsRefs<T extends Object>(
    Expression<T> Function($$PreWorkoutCheckinsTableAnnotationComposer a) f,
  ) {
    final $$PreWorkoutCheckinsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.preWorkoutCheckins,
          getReferencedColumn: (t) => t.workoutId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PreWorkoutCheckinsTableAnnotationComposer(
                $db: $db,
                $table: $db.preWorkoutCheckins,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$WorkoutsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutsTable,
          Workout,
          $$WorkoutsTableFilterComposer,
          $$WorkoutsTableOrderingComposer,
          $$WorkoutsTableAnnotationComposer,
          $$WorkoutsTableCreateCompanionBuilder,
          $$WorkoutsTableUpdateCompanionBuilder,
          (Workout, $$WorkoutsTableReferences),
          Workout,
          PrefetchHooks Function({
            bool weekId,
            bool plannedWorkoutsRefs,
            bool completedWorkoutsRefs,
            bool preWorkoutCheckinsRefs,
          })
        > {
  $$WorkoutsTableTableManager(_$AppDatabase db, $WorkoutsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> weekId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<bool> isRestDay = const Value.absent(),
              }) => WorkoutsCompanion(
                id: id,
                weekId: weekId,
                name: name,
                orderIndex: orderIndex,
                isRestDay: isRestDay,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int weekId,
                required String name,
                required int orderIndex,
                required bool isRestDay,
              }) => WorkoutsCompanion.insert(
                id: id,
                weekId: weekId,
                name: name,
                orderIndex: orderIndex,
                isRestDay: isRestDay,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkoutsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                weekId = false,
                plannedWorkoutsRefs = false,
                completedWorkoutsRefs = false,
                preWorkoutCheckinsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (plannedWorkoutsRefs) db.plannedWorkouts,
                    if (completedWorkoutsRefs) db.completedWorkouts,
                    if (preWorkoutCheckinsRefs) db.preWorkoutCheckins,
                  ],
                  addJoins:
                      <
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
                        if (weekId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.weekId,
                                    referencedTable: $$WorkoutsTableReferences
                                        ._weekIdTable(db),
                                    referencedColumn: $$WorkoutsTableReferences
                                        ._weekIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (plannedWorkoutsRefs)
                        await $_getPrefetchedData<
                          Workout,
                          $WorkoutsTable,
                          PlannedWorkout
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutsTableReferences
                              ._plannedWorkoutsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).plannedWorkoutsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workoutId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (completedWorkoutsRefs)
                        await $_getPrefetchedData<
                          Workout,
                          $WorkoutsTable,
                          CompletedWorkout
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutsTableReferences
                              ._completedWorkoutsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).completedWorkoutsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workoutId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (preWorkoutCheckinsRefs)
                        await $_getPrefetchedData<
                          Workout,
                          $WorkoutsTable,
                          PreWorkoutCheckin
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutsTableReferences
                              ._preWorkoutCheckinsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).preWorkoutCheckinsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workoutId == item.id,
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

typedef $$WorkoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutsTable,
      Workout,
      $$WorkoutsTableFilterComposer,
      $$WorkoutsTableOrderingComposer,
      $$WorkoutsTableAnnotationComposer,
      $$WorkoutsTableCreateCompanionBuilder,
      $$WorkoutsTableUpdateCompanionBuilder,
      (Workout, $$WorkoutsTableReferences),
      Workout,
      PrefetchHooks Function({
        bool weekId,
        bool plannedWorkoutsRefs,
        bool completedWorkoutsRefs,
        bool preWorkoutCheckinsRefs,
      })
    >;
typedef $$PlannedWorkoutsTableCreateCompanionBuilder =
    PlannedWorkoutsCompanion Function({Value<int> id, required int workoutId});
typedef $$PlannedWorkoutsTableUpdateCompanionBuilder =
    PlannedWorkoutsCompanion Function({Value<int> id, Value<int> workoutId});

final class $$PlannedWorkoutsTableReferences
    extends
        BaseReferences<_$AppDatabase, $PlannedWorkoutsTable, PlannedWorkout> {
  $$PlannedWorkoutsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.workouts.createAlias(
        $_aliasNameGenerator(db.plannedWorkouts.workoutId, db.workouts.id),
      );

  $$WorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<int>('workout_id')!;

    final manager = $$WorkoutsTableTableManager(
      $_db,
      $_db.workouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PlannedExercisesTable, List<PlannedExercise>>
  _plannedExercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.plannedExercises,
    aliasName: $_aliasNameGenerator(
      db.plannedWorkouts.id,
      db.plannedExercises.plannedWorkoutId,
    ),
  );

  $$PlannedExercisesTableProcessedTableManager get plannedExercisesRefs {
    final manager = $$PlannedExercisesTableTableManager(
      $_db,
      $_db.plannedExercises,
    ).filter((f) => f.plannedWorkoutId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _plannedExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlannedWorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $PlannedWorkoutsTable> {
  $$PlannedWorkoutsTableFilterComposer({
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

  $$WorkoutsTableFilterComposer get workoutId {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> plannedExercisesRefs(
    Expression<bool> Function($$PlannedExercisesTableFilterComposer f) f,
  ) {
    final $$PlannedExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedExercises,
      getReferencedColumn: (t) => t.plannedWorkoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedExercisesTableFilterComposer(
            $db: $db,
            $table: $db.plannedExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlannedWorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlannedWorkoutsTable> {
  $$PlannedWorkoutsTableOrderingComposer({
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

  $$WorkoutsTableOrderingComposer get workoutId {
    final $$WorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlannedWorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlannedWorkoutsTable> {
  $$PlannedWorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  $$WorkoutsTableAnnotationComposer get workoutId {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> plannedExercisesRefs<T extends Object>(
    Expression<T> Function($$PlannedExercisesTableAnnotationComposer a) f,
  ) {
    final $$PlannedExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedExercises,
      getReferencedColumn: (t) => t.plannedWorkoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.plannedExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlannedWorkoutsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlannedWorkoutsTable,
          PlannedWorkout,
          $$PlannedWorkoutsTableFilterComposer,
          $$PlannedWorkoutsTableOrderingComposer,
          $$PlannedWorkoutsTableAnnotationComposer,
          $$PlannedWorkoutsTableCreateCompanionBuilder,
          $$PlannedWorkoutsTableUpdateCompanionBuilder,
          (PlannedWorkout, $$PlannedWorkoutsTableReferences),
          PlannedWorkout,
          PrefetchHooks Function({bool workoutId, bool plannedExercisesRefs})
        > {
  $$PlannedWorkoutsTableTableManager(
    _$AppDatabase db,
    $PlannedWorkoutsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannedWorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannedWorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlannedWorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> workoutId = const Value.absent(),
              }) => PlannedWorkoutsCompanion(id: id, workoutId: workoutId),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int workoutId,
              }) =>
                  PlannedWorkoutsCompanion.insert(id: id, workoutId: workoutId),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlannedWorkoutsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({workoutId = false, plannedExercisesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (plannedExercisesRefs) db.plannedExercises,
                  ],
                  addJoins:
                      <
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
                        if (workoutId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workoutId,
                                    referencedTable:
                                        $$PlannedWorkoutsTableReferences
                                            ._workoutIdTable(db),
                                    referencedColumn:
                                        $$PlannedWorkoutsTableReferences
                                            ._workoutIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (plannedExercisesRefs)
                        await $_getPrefetchedData<
                          PlannedWorkout,
                          $PlannedWorkoutsTable,
                          PlannedExercise
                        >(
                          currentTable: table,
                          referencedTable: $$PlannedWorkoutsTableReferences
                              ._plannedExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlannedWorkoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).plannedExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.plannedWorkoutId == item.id,
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

typedef $$PlannedWorkoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlannedWorkoutsTable,
      PlannedWorkout,
      $$PlannedWorkoutsTableFilterComposer,
      $$PlannedWorkoutsTableOrderingComposer,
      $$PlannedWorkoutsTableAnnotationComposer,
      $$PlannedWorkoutsTableCreateCompanionBuilder,
      $$PlannedWorkoutsTableUpdateCompanionBuilder,
      (PlannedWorkout, $$PlannedWorkoutsTableReferences),
      PlannedWorkout,
      PrefetchHooks Function({bool workoutId, bool plannedExercisesRefs})
    >;
typedef $$CompletedWorkoutsTableCreateCompanionBuilder =
    CompletedWorkoutsCompanion Function({
      Value<int> id,
      required int workoutId,
      required DateTime startedAt,
      Value<DateTime?> completedAt,
      required WorkoutStatus status,
      Value<WorkoutSkipReason?> skipReason,
    });
typedef $$CompletedWorkoutsTableUpdateCompanionBuilder =
    CompletedWorkoutsCompanion Function({
      Value<int> id,
      Value<int> workoutId,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
      Value<WorkoutStatus> status,
      Value<WorkoutSkipReason?> skipReason,
    });

final class $$CompletedWorkoutsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CompletedWorkoutsTable,
          CompletedWorkout
        > {
  $$CompletedWorkoutsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.workouts.createAlias(
        $_aliasNameGenerator(db.completedWorkouts.workoutId, db.workouts.id),
      );

  $$WorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<int>('workout_id')!;

    final manager = $$WorkoutsTableTableManager(
      $_db,
      $_db.workouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CompletedExercisesTable, List<CompletedExercise>>
  _completedExercisesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.completedExercises,
        aliasName: $_aliasNameGenerator(
          db.completedWorkouts.id,
          db.completedExercises.completedWorkoutId,
        ),
      );

  $$CompletedExercisesTableProcessedTableManager get completedExercisesRefs {
    final manager =
        $$CompletedExercisesTableTableManager(
          $_db,
          $_db.completedExercises,
        ).filter(
          (f) => f.completedWorkoutId.id.sqlEquals($_itemColumn<int>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _completedExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $PostMuscleGroupCheckinsTable,
    List<PostMuscleGroupCheckin>
  >
  _postMuscleGroupCheckinsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.postMuscleGroupCheckins,
        aliasName: $_aliasNameGenerator(
          db.completedWorkouts.id,
          db.postMuscleGroupCheckins.completedWorkoutId,
        ),
      );

  $$PostMuscleGroupCheckinsTableProcessedTableManager
  get postMuscleGroupCheckinsRefs {
    final manager =
        $$PostMuscleGroupCheckinsTableTableManager(
          $_db,
          $_db.postMuscleGroupCheckins,
        ).filter(
          (f) => f.completedWorkoutId.id.sqlEquals($_itemColumn<int>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _postMuscleGroupCheckinsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CompletedWorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $CompletedWorkoutsTable> {
  $$CompletedWorkoutsTableFilterComposer({
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

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WorkoutStatus, WorkoutStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<WorkoutSkipReason?, WorkoutSkipReason, String>
  get skipReason => $composableBuilder(
    column: $table.skipReason,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$WorkoutsTableFilterComposer get workoutId {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> completedExercisesRefs(
    Expression<bool> Function($$CompletedExercisesTableFilterComposer f) f,
  ) {
    final $$CompletedExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completedExercises,
      getReferencedColumn: (t) => t.completedWorkoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedExercisesTableFilterComposer(
            $db: $db,
            $table: $db.completedExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> postMuscleGroupCheckinsRefs(
    Expression<bool> Function($$PostMuscleGroupCheckinsTableFilterComposer f) f,
  ) {
    final $$PostMuscleGroupCheckinsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.postMuscleGroupCheckins,
          getReferencedColumn: (t) => t.completedWorkoutId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PostMuscleGroupCheckinsTableFilterComposer(
                $db: $db,
                $table: $db.postMuscleGroupCheckins,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CompletedWorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $CompletedWorkoutsTable> {
  $$CompletedWorkoutsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skipReason => $composableBuilder(
    column: $table.skipReason,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutsTableOrderingComposer get workoutId {
    final $$WorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletedWorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompletedWorkoutsTable> {
  $$CompletedWorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<WorkoutStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WorkoutSkipReason?, String> get skipReason =>
      $composableBuilder(
        column: $table.skipReason,
        builder: (column) => column,
      );

  $$WorkoutsTableAnnotationComposer get workoutId {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> completedExercisesRefs<T extends Object>(
    Expression<T> Function($$CompletedExercisesTableAnnotationComposer a) f,
  ) {
    final $$CompletedExercisesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.completedExercises,
          getReferencedColumn: (t) => t.completedWorkoutId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CompletedExercisesTableAnnotationComposer(
                $db: $db,
                $table: $db.completedExercises,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> postMuscleGroupCheckinsRefs<T extends Object>(
    Expression<T> Function($$PostMuscleGroupCheckinsTableAnnotationComposer a)
    f,
  ) {
    final $$PostMuscleGroupCheckinsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.postMuscleGroupCheckins,
          getReferencedColumn: (t) => t.completedWorkoutId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PostMuscleGroupCheckinsTableAnnotationComposer(
                $db: $db,
                $table: $db.postMuscleGroupCheckins,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CompletedWorkoutsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompletedWorkoutsTable,
          CompletedWorkout,
          $$CompletedWorkoutsTableFilterComposer,
          $$CompletedWorkoutsTableOrderingComposer,
          $$CompletedWorkoutsTableAnnotationComposer,
          $$CompletedWorkoutsTableCreateCompanionBuilder,
          $$CompletedWorkoutsTableUpdateCompanionBuilder,
          (CompletedWorkout, $$CompletedWorkoutsTableReferences),
          CompletedWorkout,
          PrefetchHooks Function({
            bool workoutId,
            bool completedExercisesRefs,
            bool postMuscleGroupCheckinsRefs,
          })
        > {
  $$CompletedWorkoutsTableTableManager(
    _$AppDatabase db,
    $CompletedWorkoutsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletedWorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletedWorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompletedWorkoutsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> workoutId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<WorkoutStatus> status = const Value.absent(),
                Value<WorkoutSkipReason?> skipReason = const Value.absent(),
              }) => CompletedWorkoutsCompanion(
                id: id,
                workoutId: workoutId,
                startedAt: startedAt,
                completedAt: completedAt,
                status: status,
                skipReason: skipReason,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int workoutId,
                required DateTime startedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                required WorkoutStatus status,
                Value<WorkoutSkipReason?> skipReason = const Value.absent(),
              }) => CompletedWorkoutsCompanion.insert(
                id: id,
                workoutId: workoutId,
                startedAt: startedAt,
                completedAt: completedAt,
                status: status,
                skipReason: skipReason,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CompletedWorkoutsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                workoutId = false,
                completedExercisesRefs = false,
                postMuscleGroupCheckinsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (completedExercisesRefs) db.completedExercises,
                    if (postMuscleGroupCheckinsRefs) db.postMuscleGroupCheckins,
                  ],
                  addJoins:
                      <
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
                        if (workoutId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workoutId,
                                    referencedTable:
                                        $$CompletedWorkoutsTableReferences
                                            ._workoutIdTable(db),
                                    referencedColumn:
                                        $$CompletedWorkoutsTableReferences
                                            ._workoutIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (completedExercisesRefs)
                        await $_getPrefetchedData<
                          CompletedWorkout,
                          $CompletedWorkoutsTable,
                          CompletedExercise
                        >(
                          currentTable: table,
                          referencedTable: $$CompletedWorkoutsTableReferences
                              ._completedExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CompletedWorkoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).completedExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.completedWorkoutId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (postMuscleGroupCheckinsRefs)
                        await $_getPrefetchedData<
                          CompletedWorkout,
                          $CompletedWorkoutsTable,
                          PostMuscleGroupCheckin
                        >(
                          currentTable: table,
                          referencedTable: $$CompletedWorkoutsTableReferences
                              ._postMuscleGroupCheckinsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CompletedWorkoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).postMuscleGroupCheckinsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.completedWorkoutId == item.id,
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

typedef $$CompletedWorkoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompletedWorkoutsTable,
      CompletedWorkout,
      $$CompletedWorkoutsTableFilterComposer,
      $$CompletedWorkoutsTableOrderingComposer,
      $$CompletedWorkoutsTableAnnotationComposer,
      $$CompletedWorkoutsTableCreateCompanionBuilder,
      $$CompletedWorkoutsTableUpdateCompanionBuilder,
      (CompletedWorkout, $$CompletedWorkoutsTableReferences),
      CompletedWorkout,
      PrefetchHooks Function({
        bool workoutId,
        bool completedExercisesRefs,
        bool postMuscleGroupCheckinsRefs,
      })
    >;
typedef $$PlannedExercisesTableCreateCompanionBuilder =
    PlannedExercisesCompanion Function({
      Value<int> id,
      required int plannedWorkoutId,
      required int movementId,
    });
typedef $$PlannedExercisesTableUpdateCompanionBuilder =
    PlannedExercisesCompanion Function({
      Value<int> id,
      Value<int> plannedWorkoutId,
      Value<int> movementId,
    });

final class $$PlannedExercisesTableReferences
    extends
        BaseReferences<_$AppDatabase, $PlannedExercisesTable, PlannedExercise> {
  $$PlannedExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlannedWorkoutsTable _plannedWorkoutIdTable(_$AppDatabase db) =>
      db.plannedWorkouts.createAlias(
        $_aliasNameGenerator(
          db.plannedExercises.plannedWorkoutId,
          db.plannedWorkouts.id,
        ),
      );

  $$PlannedWorkoutsTableProcessedTableManager get plannedWorkoutId {
    final $_column = $_itemColumn<int>('planned_workout_id')!;

    final manager = $$PlannedWorkoutsTableTableManager(
      $_db,
      $_db.plannedWorkouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_plannedWorkoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MovementsTable _movementIdTable(_$AppDatabase db) =>
      db.movements.createAlias(
        $_aliasNameGenerator(db.plannedExercises.movementId, db.movements.id),
      );

  $$MovementsTableProcessedTableManager get movementId {
    final $_column = $_itemColumn<int>('movement_id')!;

    final manager = $$MovementsTableTableManager(
      $_db,
      $_db.movements,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_movementIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PlannedSetsTable, List<PlannedSet>>
  _plannedSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.plannedSets,
    aliasName: $_aliasNameGenerator(
      db.plannedExercises.id,
      db.plannedSets.plannedExerciseId,
    ),
  );

  $$PlannedSetsTableProcessedTableManager get plannedSetsRefs {
    final manager = $$PlannedSetsTableTableManager(
      $_db,
      $_db.plannedSets,
    ).filter((f) => f.plannedExerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_plannedSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlannedExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $PlannedExercisesTable> {
  $$PlannedExercisesTableFilterComposer({
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

  $$PlannedWorkoutsTableFilterComposer get plannedWorkoutId {
    final $$PlannedWorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedWorkoutId,
      referencedTable: $db.plannedWorkouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedWorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.plannedWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovementsTableFilterComposer get movementId {
    final $$MovementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movementId,
      referencedTable: $db.movements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovementsTableFilterComposer(
            $db: $db,
            $table: $db.movements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> plannedSetsRefs(
    Expression<bool> Function($$PlannedSetsTableFilterComposer f) f,
  ) {
    final $$PlannedSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedSets,
      getReferencedColumn: (t) => t.plannedExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedSetsTableFilterComposer(
            $db: $db,
            $table: $db.plannedSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlannedExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlannedExercisesTable> {
  $$PlannedExercisesTableOrderingComposer({
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

  $$PlannedWorkoutsTableOrderingComposer get plannedWorkoutId {
    final $$PlannedWorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedWorkoutId,
      referencedTable: $db.plannedWorkouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedWorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.plannedWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovementsTableOrderingComposer get movementId {
    final $$MovementsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movementId,
      referencedTable: $db.movements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovementsTableOrderingComposer(
            $db: $db,
            $table: $db.movements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlannedExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlannedExercisesTable> {
  $$PlannedExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  $$PlannedWorkoutsTableAnnotationComposer get plannedWorkoutId {
    final $$PlannedWorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedWorkoutId,
      referencedTable: $db.plannedWorkouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedWorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.plannedWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovementsTableAnnotationComposer get movementId {
    final $$MovementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movementId,
      referencedTable: $db.movements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovementsTableAnnotationComposer(
            $db: $db,
            $table: $db.movements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> plannedSetsRefs<T extends Object>(
    Expression<T> Function($$PlannedSetsTableAnnotationComposer a) f,
  ) {
    final $$PlannedSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedSets,
      getReferencedColumn: (t) => t.plannedExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.plannedSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlannedExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlannedExercisesTable,
          PlannedExercise,
          $$PlannedExercisesTableFilterComposer,
          $$PlannedExercisesTableOrderingComposer,
          $$PlannedExercisesTableAnnotationComposer,
          $$PlannedExercisesTableCreateCompanionBuilder,
          $$PlannedExercisesTableUpdateCompanionBuilder,
          (PlannedExercise, $$PlannedExercisesTableReferences),
          PlannedExercise,
          PrefetchHooks Function({
            bool plannedWorkoutId,
            bool movementId,
            bool plannedSetsRefs,
          })
        > {
  $$PlannedExercisesTableTableManager(
    _$AppDatabase db,
    $PlannedExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannedExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannedExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlannedExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> plannedWorkoutId = const Value.absent(),
                Value<int> movementId = const Value.absent(),
              }) => PlannedExercisesCompanion(
                id: id,
                plannedWorkoutId: plannedWorkoutId,
                movementId: movementId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int plannedWorkoutId,
                required int movementId,
              }) => PlannedExercisesCompanion.insert(
                id: id,
                plannedWorkoutId: plannedWorkoutId,
                movementId: movementId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlannedExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                plannedWorkoutId = false,
                movementId = false,
                plannedSetsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (plannedSetsRefs) db.plannedSets,
                  ],
                  addJoins:
                      <
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
                        if (plannedWorkoutId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.plannedWorkoutId,
                                    referencedTable:
                                        $$PlannedExercisesTableReferences
                                            ._plannedWorkoutIdTable(db),
                                    referencedColumn:
                                        $$PlannedExercisesTableReferences
                                            ._plannedWorkoutIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (movementId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.movementId,
                                    referencedTable:
                                        $$PlannedExercisesTableReferences
                                            ._movementIdTable(db),
                                    referencedColumn:
                                        $$PlannedExercisesTableReferences
                                            ._movementIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (plannedSetsRefs)
                        await $_getPrefetchedData<
                          PlannedExercise,
                          $PlannedExercisesTable,
                          PlannedSet
                        >(
                          currentTable: table,
                          referencedTable: $$PlannedExercisesTableReferences
                              ._plannedSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlannedExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).plannedSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.plannedExerciseId == item.id,
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

typedef $$PlannedExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlannedExercisesTable,
      PlannedExercise,
      $$PlannedExercisesTableFilterComposer,
      $$PlannedExercisesTableOrderingComposer,
      $$PlannedExercisesTableAnnotationComposer,
      $$PlannedExercisesTableCreateCompanionBuilder,
      $$PlannedExercisesTableUpdateCompanionBuilder,
      (PlannedExercise, $$PlannedExercisesTableReferences),
      PlannedExercise,
      PrefetchHooks Function({
        bool plannedWorkoutId,
        bool movementId,
        bool plannedSetsRefs,
      })
    >;
typedef $$CompletedExercisesTableCreateCompanionBuilder =
    CompletedExercisesCompanion Function({
      Value<int> id,
      required int completedWorkoutId,
      required int movementId,
      required int orderIndex,
      Value<bool> isPersistent,
      Value<SkipReason?> skipReason,
    });
typedef $$CompletedExercisesTableUpdateCompanionBuilder =
    CompletedExercisesCompanion Function({
      Value<int> id,
      Value<int> completedWorkoutId,
      Value<int> movementId,
      Value<int> orderIndex,
      Value<bool> isPersistent,
      Value<SkipReason?> skipReason,
    });

final class $$CompletedExercisesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CompletedExercisesTable,
          CompletedExercise
        > {
  $$CompletedExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CompletedWorkoutsTable _completedWorkoutIdTable(_$AppDatabase db) =>
      db.completedWorkouts.createAlias(
        $_aliasNameGenerator(
          db.completedExercises.completedWorkoutId,
          db.completedWorkouts.id,
        ),
      );

  $$CompletedWorkoutsTableProcessedTableManager get completedWorkoutId {
    final $_column = $_itemColumn<int>('completed_workout_id')!;

    final manager = $$CompletedWorkoutsTableTableManager(
      $_db,
      $_db.completedWorkouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_completedWorkoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MovementsTable _movementIdTable(_$AppDatabase db) =>
      db.movements.createAlias(
        $_aliasNameGenerator(db.completedExercises.movementId, db.movements.id),
      );

  $$MovementsTableProcessedTableManager get movementId {
    final $_column = $_itemColumn<int>('movement_id')!;

    final manager = $$MovementsTableTableManager(
      $_db,
      $_db.movements,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_movementIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CompletedSetsTable, List<CompletedSet>>
  _completedSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.completedSets,
    aliasName: $_aliasNameGenerator(
      db.completedExercises.id,
      db.completedSets.completedExerciseId,
    ),
  );

  $$CompletedSetsTableProcessedTableManager get completedSetsRefs {
    final manager = $$CompletedSetsTableTableManager($_db, $_db.completedSets)
        .filter(
          (f) => f.completedExerciseId.id.sqlEquals($_itemColumn<int>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_completedSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $PostExerciseCheckinsTable,
    List<PostExerciseCheckin>
  >
  _postExerciseCheckinsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.postExerciseCheckins,
        aliasName: $_aliasNameGenerator(
          db.completedExercises.id,
          db.postExerciseCheckins.completedExerciseId,
        ),
      );

  $$PostExerciseCheckinsTableProcessedTableManager
  get postExerciseCheckinsRefs {
    final manager =
        $$PostExerciseCheckinsTableTableManager(
          $_db,
          $_db.postExerciseCheckins,
        ).filter(
          (f) => f.completedExerciseId.id.sqlEquals($_itemColumn<int>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _postExerciseCheckinsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CompletedExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $CompletedExercisesTable> {
  $$CompletedExercisesTableFilterComposer({
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

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPersistent => $composableBuilder(
    column: $table.isPersistent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SkipReason?, SkipReason, String>
  get skipReason => $composableBuilder(
    column: $table.skipReason,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$CompletedWorkoutsTableFilterComposer get completedWorkoutId {
    final $$CompletedWorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completedWorkoutId,
      referencedTable: $db.completedWorkouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedWorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.completedWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovementsTableFilterComposer get movementId {
    final $$MovementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movementId,
      referencedTable: $db.movements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovementsTableFilterComposer(
            $db: $db,
            $table: $db.movements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> completedSetsRefs(
    Expression<bool> Function($$CompletedSetsTableFilterComposer f) f,
  ) {
    final $$CompletedSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completedSets,
      getReferencedColumn: (t) => t.completedExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedSetsTableFilterComposer(
            $db: $db,
            $table: $db.completedSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> postExerciseCheckinsRefs(
    Expression<bool> Function($$PostExerciseCheckinsTableFilterComposer f) f,
  ) {
    final $$PostExerciseCheckinsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.postExerciseCheckins,
      getReferencedColumn: (t) => t.completedExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PostExerciseCheckinsTableFilterComposer(
            $db: $db,
            $table: $db.postExerciseCheckins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CompletedExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $CompletedExercisesTable> {
  $$CompletedExercisesTableOrderingComposer({
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

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPersistent => $composableBuilder(
    column: $table.isPersistent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skipReason => $composableBuilder(
    column: $table.skipReason,
    builder: (column) => ColumnOrderings(column),
  );

  $$CompletedWorkoutsTableOrderingComposer get completedWorkoutId {
    final $$CompletedWorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completedWorkoutId,
      referencedTable: $db.completedWorkouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedWorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.completedWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovementsTableOrderingComposer get movementId {
    final $$MovementsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movementId,
      referencedTable: $db.movements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovementsTableOrderingComposer(
            $db: $db,
            $table: $db.movements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletedExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompletedExercisesTable> {
  $$CompletedExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPersistent => $composableBuilder(
    column: $table.isPersistent,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SkipReason?, String> get skipReason =>
      $composableBuilder(
        column: $table.skipReason,
        builder: (column) => column,
      );

  $$CompletedWorkoutsTableAnnotationComposer get completedWorkoutId {
    final $$CompletedWorkoutsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.completedWorkoutId,
          referencedTable: $db.completedWorkouts,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CompletedWorkoutsTableAnnotationComposer(
                $db: $db,
                $table: $db.completedWorkouts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$MovementsTableAnnotationComposer get movementId {
    final $$MovementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movementId,
      referencedTable: $db.movements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovementsTableAnnotationComposer(
            $db: $db,
            $table: $db.movements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> completedSetsRefs<T extends Object>(
    Expression<T> Function($$CompletedSetsTableAnnotationComposer a) f,
  ) {
    final $$CompletedSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completedSets,
      getReferencedColumn: (t) => t.completedExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.completedSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> postExerciseCheckinsRefs<T extends Object>(
    Expression<T> Function($$PostExerciseCheckinsTableAnnotationComposer a) f,
  ) {
    final $$PostExerciseCheckinsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.postExerciseCheckins,
          getReferencedColumn: (t) => t.completedExerciseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PostExerciseCheckinsTableAnnotationComposer(
                $db: $db,
                $table: $db.postExerciseCheckins,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CompletedExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompletedExercisesTable,
          CompletedExercise,
          $$CompletedExercisesTableFilterComposer,
          $$CompletedExercisesTableOrderingComposer,
          $$CompletedExercisesTableAnnotationComposer,
          $$CompletedExercisesTableCreateCompanionBuilder,
          $$CompletedExercisesTableUpdateCompanionBuilder,
          (CompletedExercise, $$CompletedExercisesTableReferences),
          CompletedExercise,
          PrefetchHooks Function({
            bool completedWorkoutId,
            bool movementId,
            bool completedSetsRefs,
            bool postExerciseCheckinsRefs,
          })
        > {
  $$CompletedExercisesTableTableManager(
    _$AppDatabase db,
    $CompletedExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletedExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletedExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompletedExercisesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> completedWorkoutId = const Value.absent(),
                Value<int> movementId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<bool> isPersistent = const Value.absent(),
                Value<SkipReason?> skipReason = const Value.absent(),
              }) => CompletedExercisesCompanion(
                id: id,
                completedWorkoutId: completedWorkoutId,
                movementId: movementId,
                orderIndex: orderIndex,
                isPersistent: isPersistent,
                skipReason: skipReason,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int completedWorkoutId,
                required int movementId,
                required int orderIndex,
                Value<bool> isPersistent = const Value.absent(),
                Value<SkipReason?> skipReason = const Value.absent(),
              }) => CompletedExercisesCompanion.insert(
                id: id,
                completedWorkoutId: completedWorkoutId,
                movementId: movementId,
                orderIndex: orderIndex,
                isPersistent: isPersistent,
                skipReason: skipReason,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CompletedExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                completedWorkoutId = false,
                movementId = false,
                completedSetsRefs = false,
                postExerciseCheckinsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (completedSetsRefs) db.completedSets,
                    if (postExerciseCheckinsRefs) db.postExerciseCheckins,
                  ],
                  addJoins:
                      <
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
                        if (completedWorkoutId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.completedWorkoutId,
                                    referencedTable:
                                        $$CompletedExercisesTableReferences
                                            ._completedWorkoutIdTable(db),
                                    referencedColumn:
                                        $$CompletedExercisesTableReferences
                                            ._completedWorkoutIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (movementId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.movementId,
                                    referencedTable:
                                        $$CompletedExercisesTableReferences
                                            ._movementIdTable(db),
                                    referencedColumn:
                                        $$CompletedExercisesTableReferences
                                            ._movementIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (completedSetsRefs)
                        await $_getPrefetchedData<
                          CompletedExercise,
                          $CompletedExercisesTable,
                          CompletedSet
                        >(
                          currentTable: table,
                          referencedTable: $$CompletedExercisesTableReferences
                              ._completedSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CompletedExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).completedSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.completedExerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (postExerciseCheckinsRefs)
                        await $_getPrefetchedData<
                          CompletedExercise,
                          $CompletedExercisesTable,
                          PostExerciseCheckin
                        >(
                          currentTable: table,
                          referencedTable: $$CompletedExercisesTableReferences
                              ._postExerciseCheckinsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CompletedExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).postExerciseCheckinsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.completedExerciseId == item.id,
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

typedef $$CompletedExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompletedExercisesTable,
      CompletedExercise,
      $$CompletedExercisesTableFilterComposer,
      $$CompletedExercisesTableOrderingComposer,
      $$CompletedExercisesTableAnnotationComposer,
      $$CompletedExercisesTableCreateCompanionBuilder,
      $$CompletedExercisesTableUpdateCompanionBuilder,
      (CompletedExercise, $$CompletedExercisesTableReferences),
      CompletedExercise,
      PrefetchHooks Function({
        bool completedWorkoutId,
        bool movementId,
        bool completedSetsRefs,
        bool postExerciseCheckinsRefs,
      })
    >;
typedef $$PlannedSetsTableCreateCompanionBuilder =
    PlannedSetsCompanion Function({
      Value<int> id,
      required int plannedExerciseId,
      Value<int?> reps,
      Value<double?> weight,
      Value<double?> time,
      Value<double?> distance,
    });
typedef $$PlannedSetsTableUpdateCompanionBuilder =
    PlannedSetsCompanion Function({
      Value<int> id,
      Value<int> plannedExerciseId,
      Value<int?> reps,
      Value<double?> weight,
      Value<double?> time,
      Value<double?> distance,
    });

final class $$PlannedSetsTableReferences
    extends BaseReferences<_$AppDatabase, $PlannedSetsTable, PlannedSet> {
  $$PlannedSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlannedExercisesTable _plannedExerciseIdTable(_$AppDatabase db) =>
      db.plannedExercises.createAlias(
        $_aliasNameGenerator(
          db.plannedSets.plannedExerciseId,
          db.plannedExercises.id,
        ),
      );

  $$PlannedExercisesTableProcessedTableManager get plannedExerciseId {
    final $_column = $_itemColumn<int>('planned_exercise_id')!;

    final manager = $$PlannedExercisesTableTableManager(
      $_db,
      $_db.plannedExercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_plannedExerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlannedSetsTableFilterComposer
    extends Composer<_$AppDatabase, $PlannedSetsTable> {
  $$PlannedSetsTableFilterComposer({
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

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnFilters(column),
  );

  $$PlannedExercisesTableFilterComposer get plannedExerciseId {
    final $$PlannedExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedExerciseId,
      referencedTable: $db.plannedExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedExercisesTableFilterComposer(
            $db: $db,
            $table: $db.plannedExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlannedSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlannedSetsTable> {
  $$PlannedSetsTableOrderingComposer({
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

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlannedExercisesTableOrderingComposer get plannedExerciseId {
    final $$PlannedExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedExerciseId,
      referencedTable: $db.plannedExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.plannedExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlannedSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlannedSetsTable> {
  $$PlannedSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<double> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  $$PlannedExercisesTableAnnotationComposer get plannedExerciseId {
    final $$PlannedExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedExerciseId,
      referencedTable: $db.plannedExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.plannedExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlannedSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlannedSetsTable,
          PlannedSet,
          $$PlannedSetsTableFilterComposer,
          $$PlannedSetsTableOrderingComposer,
          $$PlannedSetsTableAnnotationComposer,
          $$PlannedSetsTableCreateCompanionBuilder,
          $$PlannedSetsTableUpdateCompanionBuilder,
          (PlannedSet, $$PlannedSetsTableReferences),
          PlannedSet,
          PrefetchHooks Function({bool plannedExerciseId})
        > {
  $$PlannedSetsTableTableManager(_$AppDatabase db, $PlannedSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannedSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannedSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlannedSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> plannedExerciseId = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<double?> weight = const Value.absent(),
                Value<double?> time = const Value.absent(),
                Value<double?> distance = const Value.absent(),
              }) => PlannedSetsCompanion(
                id: id,
                plannedExerciseId: plannedExerciseId,
                reps: reps,
                weight: weight,
                time: time,
                distance: distance,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int plannedExerciseId,
                Value<int?> reps = const Value.absent(),
                Value<double?> weight = const Value.absent(),
                Value<double?> time = const Value.absent(),
                Value<double?> distance = const Value.absent(),
              }) => PlannedSetsCompanion.insert(
                id: id,
                plannedExerciseId: plannedExerciseId,
                reps: reps,
                weight: weight,
                time: time,
                distance: distance,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlannedSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({plannedExerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                    if (plannedExerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.plannedExerciseId,
                                referencedTable: $$PlannedSetsTableReferences
                                    ._plannedExerciseIdTable(db),
                                referencedColumn: $$PlannedSetsTableReferences
                                    ._plannedExerciseIdTable(db)
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

typedef $$PlannedSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlannedSetsTable,
      PlannedSet,
      $$PlannedSetsTableFilterComposer,
      $$PlannedSetsTableOrderingComposer,
      $$PlannedSetsTableAnnotationComposer,
      $$PlannedSetsTableCreateCompanionBuilder,
      $$PlannedSetsTableUpdateCompanionBuilder,
      (PlannedSet, $$PlannedSetsTableReferences),
      PlannedSet,
      PrefetchHooks Function({bool plannedExerciseId})
    >;
typedef $$CompletedSetsTableCreateCompanionBuilder =
    CompletedSetsCompanion Function({
      Value<int> id,
      required int completedExerciseId,
      Value<int?> reps,
      Value<double?> weight,
      Value<double?> time,
      Value<double?> distance,
      Value<SkipReason?> skipReason,
    });
typedef $$CompletedSetsTableUpdateCompanionBuilder =
    CompletedSetsCompanion Function({
      Value<int> id,
      Value<int> completedExerciseId,
      Value<int?> reps,
      Value<double?> weight,
      Value<double?> time,
      Value<double?> distance,
      Value<SkipReason?> skipReason,
    });

final class $$CompletedSetsTableReferences
    extends BaseReferences<_$AppDatabase, $CompletedSetsTable, CompletedSet> {
  $$CompletedSetsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CompletedExercisesTable _completedExerciseIdTable(_$AppDatabase db) =>
      db.completedExercises.createAlias(
        $_aliasNameGenerator(
          db.completedSets.completedExerciseId,
          db.completedExercises.id,
        ),
      );

  $$CompletedExercisesTableProcessedTableManager get completedExerciseId {
    final $_column = $_itemColumn<int>('completed_exercise_id')!;

    final manager = $$CompletedExercisesTableTableManager(
      $_db,
      $_db.completedExercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_completedExerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CompletedSetsTableFilterComposer
    extends Composer<_$AppDatabase, $CompletedSetsTable> {
  $$CompletedSetsTableFilterComposer({
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

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SkipReason?, SkipReason, String>
  get skipReason => $composableBuilder(
    column: $table.skipReason,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$CompletedExercisesTableFilterComposer get completedExerciseId {
    final $$CompletedExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completedExerciseId,
      referencedTable: $db.completedExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedExercisesTableFilterComposer(
            $db: $db,
            $table: $db.completedExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletedSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $CompletedSetsTable> {
  $$CompletedSetsTableOrderingComposer({
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

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skipReason => $composableBuilder(
    column: $table.skipReason,
    builder: (column) => ColumnOrderings(column),
  );

  $$CompletedExercisesTableOrderingComposer get completedExerciseId {
    final $$CompletedExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completedExerciseId,
      referencedTable: $db.completedExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.completedExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletedSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompletedSetsTable> {
  $$CompletedSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<double> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SkipReason?, String> get skipReason =>
      $composableBuilder(
        column: $table.skipReason,
        builder: (column) => column,
      );

  $$CompletedExercisesTableAnnotationComposer get completedExerciseId {
    final $$CompletedExercisesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.completedExerciseId,
          referencedTable: $db.completedExercises,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CompletedExercisesTableAnnotationComposer(
                $db: $db,
                $table: $db.completedExercises,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$CompletedSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompletedSetsTable,
          CompletedSet,
          $$CompletedSetsTableFilterComposer,
          $$CompletedSetsTableOrderingComposer,
          $$CompletedSetsTableAnnotationComposer,
          $$CompletedSetsTableCreateCompanionBuilder,
          $$CompletedSetsTableUpdateCompanionBuilder,
          (CompletedSet, $$CompletedSetsTableReferences),
          CompletedSet,
          PrefetchHooks Function({bool completedExerciseId})
        > {
  $$CompletedSetsTableTableManager(_$AppDatabase db, $CompletedSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletedSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletedSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompletedSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> completedExerciseId = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<double?> weight = const Value.absent(),
                Value<double?> time = const Value.absent(),
                Value<double?> distance = const Value.absent(),
                Value<SkipReason?> skipReason = const Value.absent(),
              }) => CompletedSetsCompanion(
                id: id,
                completedExerciseId: completedExerciseId,
                reps: reps,
                weight: weight,
                time: time,
                distance: distance,
                skipReason: skipReason,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int completedExerciseId,
                Value<int?> reps = const Value.absent(),
                Value<double?> weight = const Value.absent(),
                Value<double?> time = const Value.absent(),
                Value<double?> distance = const Value.absent(),
                Value<SkipReason?> skipReason = const Value.absent(),
              }) => CompletedSetsCompanion.insert(
                id: id,
                completedExerciseId: completedExerciseId,
                reps: reps,
                weight: weight,
                time: time,
                distance: distance,
                skipReason: skipReason,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CompletedSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({completedExerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                    if (completedExerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.completedExerciseId,
                                referencedTable: $$CompletedSetsTableReferences
                                    ._completedExerciseIdTable(db),
                                referencedColumn: $$CompletedSetsTableReferences
                                    ._completedExerciseIdTable(db)
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

typedef $$CompletedSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompletedSetsTable,
      CompletedSet,
      $$CompletedSetsTableFilterComposer,
      $$CompletedSetsTableOrderingComposer,
      $$CompletedSetsTableAnnotationComposer,
      $$CompletedSetsTableCreateCompanionBuilder,
      $$CompletedSetsTableUpdateCompanionBuilder,
      (CompletedSet, $$CompletedSetsTableReferences),
      CompletedSet,
      PrefetchHooks Function({bool completedExerciseId})
    >;
typedef $$PreWorkoutCheckinsTableCreateCompanionBuilder =
    PreWorkoutCheckinsCompanion Function({
      Value<int> id,
      required int workoutId,
      Value<Soreness?> quads,
      Value<Soreness?> hamstrings,
      Value<Soreness?> abs,
      Value<Soreness?> chest,
      Value<Soreness?> back,
      Value<Soreness?> biceps,
      Value<Soreness?> triceps,
      Value<Soreness?> traps,
      Value<Soreness?> forearms,
      Value<Soreness?> glutes,
      Value<Soreness?> calves,
      Value<Soreness?> shoulders,
      Value<CurrentState?> sleepQuality,
      Value<CurrentState?> vimVigor,
      Value<CurrentState?> mentalState,
    });
typedef $$PreWorkoutCheckinsTableUpdateCompanionBuilder =
    PreWorkoutCheckinsCompanion Function({
      Value<int> id,
      Value<int> workoutId,
      Value<Soreness?> quads,
      Value<Soreness?> hamstrings,
      Value<Soreness?> abs,
      Value<Soreness?> chest,
      Value<Soreness?> back,
      Value<Soreness?> biceps,
      Value<Soreness?> triceps,
      Value<Soreness?> traps,
      Value<Soreness?> forearms,
      Value<Soreness?> glutes,
      Value<Soreness?> calves,
      Value<Soreness?> shoulders,
      Value<CurrentState?> sleepQuality,
      Value<CurrentState?> vimVigor,
      Value<CurrentState?> mentalState,
    });

final class $$PreWorkoutCheckinsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PreWorkoutCheckinsTable,
          PreWorkoutCheckin
        > {
  $$PreWorkoutCheckinsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.workouts.createAlias(
        $_aliasNameGenerator(db.preWorkoutCheckins.workoutId, db.workouts.id),
      );

  $$WorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<int>('workout_id')!;

    final manager = $$WorkoutsTableTableManager(
      $_db,
      $_db.workouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PreWorkoutCheckinsTableFilterComposer
    extends Composer<_$AppDatabase, $PreWorkoutCheckinsTable> {
  $$PreWorkoutCheckinsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<Soreness?, Soreness, String> get quads =>
      $composableBuilder(
        column: $table.quads,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Soreness?, Soreness, String> get hamstrings =>
      $composableBuilder(
        column: $table.hamstrings,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Soreness?, Soreness, String> get abs =>
      $composableBuilder(
        column: $table.abs,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Soreness?, Soreness, String> get chest =>
      $composableBuilder(
        column: $table.chest,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Soreness?, Soreness, String> get back =>
      $composableBuilder(
        column: $table.back,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Soreness?, Soreness, String> get biceps =>
      $composableBuilder(
        column: $table.biceps,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Soreness?, Soreness, String> get triceps =>
      $composableBuilder(
        column: $table.triceps,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Soreness?, Soreness, String> get traps =>
      $composableBuilder(
        column: $table.traps,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Soreness?, Soreness, String> get forearms =>
      $composableBuilder(
        column: $table.forearms,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Soreness?, Soreness, String> get glutes =>
      $composableBuilder(
        column: $table.glutes,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Soreness?, Soreness, String> get calves =>
      $composableBuilder(
        column: $table.calves,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Soreness?, Soreness, String> get shoulders =>
      $composableBuilder(
        column: $table.shoulders,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<CurrentState?, CurrentState, String>
  get sleepQuality => $composableBuilder(
    column: $table.sleepQuality,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<CurrentState?, CurrentState, String>
  get vimVigor => $composableBuilder(
    column: $table.vimVigor,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<CurrentState?, CurrentState, String>
  get mentalState => $composableBuilder(
    column: $table.mentalState,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$WorkoutsTableFilterComposer get workoutId {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PreWorkoutCheckinsTableOrderingComposer
    extends Composer<_$AppDatabase, $PreWorkoutCheckinsTable> {
  $$PreWorkoutCheckinsTableOrderingComposer({
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

  ColumnOrderings<String> get quads => $composableBuilder(
    column: $table.quads,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hamstrings => $composableBuilder(
    column: $table.hamstrings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get abs => $composableBuilder(
    column: $table.abs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chest => $composableBuilder(
    column: $table.chest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get biceps => $composableBuilder(
    column: $table.biceps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get triceps => $composableBuilder(
    column: $table.triceps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get traps => $composableBuilder(
    column: $table.traps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get forearms => $composableBuilder(
    column: $table.forearms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get glutes => $composableBuilder(
    column: $table.glutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calves => $composableBuilder(
    column: $table.calves,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shoulders => $composableBuilder(
    column: $table.shoulders,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sleepQuality => $composableBuilder(
    column: $table.sleepQuality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vimVigor => $composableBuilder(
    column: $table.vimVigor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mentalState => $composableBuilder(
    column: $table.mentalState,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutsTableOrderingComposer get workoutId {
    final $$WorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PreWorkoutCheckinsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreWorkoutCheckinsTable> {
  $$PreWorkoutCheckinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Soreness?, String> get quads =>
      $composableBuilder(column: $table.quads, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Soreness?, String> get hamstrings =>
      $composableBuilder(
        column: $table.hamstrings,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Soreness?, String> get abs =>
      $composableBuilder(column: $table.abs, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Soreness?, String> get chest =>
      $composableBuilder(column: $table.chest, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Soreness?, String> get back =>
      $composableBuilder(column: $table.back, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Soreness?, String> get biceps =>
      $composableBuilder(column: $table.biceps, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Soreness?, String> get triceps =>
      $composableBuilder(column: $table.triceps, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Soreness?, String> get traps =>
      $composableBuilder(column: $table.traps, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Soreness?, String> get forearms =>
      $composableBuilder(column: $table.forearms, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Soreness?, String> get glutes =>
      $composableBuilder(column: $table.glutes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Soreness?, String> get calves =>
      $composableBuilder(column: $table.calves, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Soreness?, String> get shoulders =>
      $composableBuilder(column: $table.shoulders, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CurrentState?, String> get sleepQuality =>
      $composableBuilder(
        column: $table.sleepQuality,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<CurrentState?, String> get vimVigor =>
      $composableBuilder(column: $table.vimVigor, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CurrentState?, String> get mentalState =>
      $composableBuilder(
        column: $table.mentalState,
        builder: (column) => column,
      );

  $$WorkoutsTableAnnotationComposer get workoutId {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PreWorkoutCheckinsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreWorkoutCheckinsTable,
          PreWorkoutCheckin,
          $$PreWorkoutCheckinsTableFilterComposer,
          $$PreWorkoutCheckinsTableOrderingComposer,
          $$PreWorkoutCheckinsTableAnnotationComposer,
          $$PreWorkoutCheckinsTableCreateCompanionBuilder,
          $$PreWorkoutCheckinsTableUpdateCompanionBuilder,
          (PreWorkoutCheckin, $$PreWorkoutCheckinsTableReferences),
          PreWorkoutCheckin,
          PrefetchHooks Function({bool workoutId})
        > {
  $$PreWorkoutCheckinsTableTableManager(
    _$AppDatabase db,
    $PreWorkoutCheckinsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreWorkoutCheckinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreWorkoutCheckinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreWorkoutCheckinsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> workoutId = const Value.absent(),
                Value<Soreness?> quads = const Value.absent(),
                Value<Soreness?> hamstrings = const Value.absent(),
                Value<Soreness?> abs = const Value.absent(),
                Value<Soreness?> chest = const Value.absent(),
                Value<Soreness?> back = const Value.absent(),
                Value<Soreness?> biceps = const Value.absent(),
                Value<Soreness?> triceps = const Value.absent(),
                Value<Soreness?> traps = const Value.absent(),
                Value<Soreness?> forearms = const Value.absent(),
                Value<Soreness?> glutes = const Value.absent(),
                Value<Soreness?> calves = const Value.absent(),
                Value<Soreness?> shoulders = const Value.absent(),
                Value<CurrentState?> sleepQuality = const Value.absent(),
                Value<CurrentState?> vimVigor = const Value.absent(),
                Value<CurrentState?> mentalState = const Value.absent(),
              }) => PreWorkoutCheckinsCompanion(
                id: id,
                workoutId: workoutId,
                quads: quads,
                hamstrings: hamstrings,
                abs: abs,
                chest: chest,
                back: back,
                biceps: biceps,
                triceps: triceps,
                traps: traps,
                forearms: forearms,
                glutes: glutes,
                calves: calves,
                shoulders: shoulders,
                sleepQuality: sleepQuality,
                vimVigor: vimVigor,
                mentalState: mentalState,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int workoutId,
                Value<Soreness?> quads = const Value.absent(),
                Value<Soreness?> hamstrings = const Value.absent(),
                Value<Soreness?> abs = const Value.absent(),
                Value<Soreness?> chest = const Value.absent(),
                Value<Soreness?> back = const Value.absent(),
                Value<Soreness?> biceps = const Value.absent(),
                Value<Soreness?> triceps = const Value.absent(),
                Value<Soreness?> traps = const Value.absent(),
                Value<Soreness?> forearms = const Value.absent(),
                Value<Soreness?> glutes = const Value.absent(),
                Value<Soreness?> calves = const Value.absent(),
                Value<Soreness?> shoulders = const Value.absent(),
                Value<CurrentState?> sleepQuality = const Value.absent(),
                Value<CurrentState?> vimVigor = const Value.absent(),
                Value<CurrentState?> mentalState = const Value.absent(),
              }) => PreWorkoutCheckinsCompanion.insert(
                id: id,
                workoutId: workoutId,
                quads: quads,
                hamstrings: hamstrings,
                abs: abs,
                chest: chest,
                back: back,
                biceps: biceps,
                triceps: triceps,
                traps: traps,
                forearms: forearms,
                glutes: glutes,
                calves: calves,
                shoulders: shoulders,
                sleepQuality: sleepQuality,
                vimVigor: vimVigor,
                mentalState: mentalState,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PreWorkoutCheckinsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workoutId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                    if (workoutId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workoutId,
                                referencedTable:
                                    $$PreWorkoutCheckinsTableReferences
                                        ._workoutIdTable(db),
                                referencedColumn:
                                    $$PreWorkoutCheckinsTableReferences
                                        ._workoutIdTable(db)
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

typedef $$PreWorkoutCheckinsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreWorkoutCheckinsTable,
      PreWorkoutCheckin,
      $$PreWorkoutCheckinsTableFilterComposer,
      $$PreWorkoutCheckinsTableOrderingComposer,
      $$PreWorkoutCheckinsTableAnnotationComposer,
      $$PreWorkoutCheckinsTableCreateCompanionBuilder,
      $$PreWorkoutCheckinsTableUpdateCompanionBuilder,
      (PreWorkoutCheckin, $$PreWorkoutCheckinsTableReferences),
      PreWorkoutCheckin,
      PrefetchHooks Function({bool workoutId})
    >;
typedef $$PostExerciseCheckinsTableCreateCompanionBuilder =
    PostExerciseCheckinsCompanion Function({
      Value<int> id,
      required int completedExerciseId,
      required Soreness jointPain,
    });
typedef $$PostExerciseCheckinsTableUpdateCompanionBuilder =
    PostExerciseCheckinsCompanion Function({
      Value<int> id,
      Value<int> completedExerciseId,
      Value<Soreness> jointPain,
    });

final class $$PostExerciseCheckinsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PostExerciseCheckinsTable,
          PostExerciseCheckin
        > {
  $$PostExerciseCheckinsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CompletedExercisesTable _completedExerciseIdTable(_$AppDatabase db) =>
      db.completedExercises.createAlias(
        $_aliasNameGenerator(
          db.postExerciseCheckins.completedExerciseId,
          db.completedExercises.id,
        ),
      );

  $$CompletedExercisesTableProcessedTableManager get completedExerciseId {
    final $_column = $_itemColumn<int>('completed_exercise_id')!;

    final manager = $$CompletedExercisesTableTableManager(
      $_db,
      $_db.completedExercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_completedExerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PostExerciseCheckinsTableFilterComposer
    extends Composer<_$AppDatabase, $PostExerciseCheckinsTable> {
  $$PostExerciseCheckinsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<Soreness, Soreness, String> get jointPain =>
      $composableBuilder(
        column: $table.jointPain,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$CompletedExercisesTableFilterComposer get completedExerciseId {
    final $$CompletedExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completedExerciseId,
      referencedTable: $db.completedExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedExercisesTableFilterComposer(
            $db: $db,
            $table: $db.completedExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PostExerciseCheckinsTableOrderingComposer
    extends Composer<_$AppDatabase, $PostExerciseCheckinsTable> {
  $$PostExerciseCheckinsTableOrderingComposer({
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

  ColumnOrderings<String> get jointPain => $composableBuilder(
    column: $table.jointPain,
    builder: (column) => ColumnOrderings(column),
  );

  $$CompletedExercisesTableOrderingComposer get completedExerciseId {
    final $$CompletedExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completedExerciseId,
      referencedTable: $db.completedExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.completedExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PostExerciseCheckinsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PostExerciseCheckinsTable> {
  $$PostExerciseCheckinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Soreness, String> get jointPain =>
      $composableBuilder(column: $table.jointPain, builder: (column) => column);

  $$CompletedExercisesTableAnnotationComposer get completedExerciseId {
    final $$CompletedExercisesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.completedExerciseId,
          referencedTable: $db.completedExercises,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CompletedExercisesTableAnnotationComposer(
                $db: $db,
                $table: $db.completedExercises,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PostExerciseCheckinsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PostExerciseCheckinsTable,
          PostExerciseCheckin,
          $$PostExerciseCheckinsTableFilterComposer,
          $$PostExerciseCheckinsTableOrderingComposer,
          $$PostExerciseCheckinsTableAnnotationComposer,
          $$PostExerciseCheckinsTableCreateCompanionBuilder,
          $$PostExerciseCheckinsTableUpdateCompanionBuilder,
          (PostExerciseCheckin, $$PostExerciseCheckinsTableReferences),
          PostExerciseCheckin,
          PrefetchHooks Function({bool completedExerciseId})
        > {
  $$PostExerciseCheckinsTableTableManager(
    _$AppDatabase db,
    $PostExerciseCheckinsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PostExerciseCheckinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PostExerciseCheckinsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PostExerciseCheckinsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> completedExerciseId = const Value.absent(),
                Value<Soreness> jointPain = const Value.absent(),
              }) => PostExerciseCheckinsCompanion(
                id: id,
                completedExerciseId: completedExerciseId,
                jointPain: jointPain,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int completedExerciseId,
                required Soreness jointPain,
              }) => PostExerciseCheckinsCompanion.insert(
                id: id,
                completedExerciseId: completedExerciseId,
                jointPain: jointPain,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PostExerciseCheckinsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({completedExerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                    if (completedExerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.completedExerciseId,
                                referencedTable:
                                    $$PostExerciseCheckinsTableReferences
                                        ._completedExerciseIdTable(db),
                                referencedColumn:
                                    $$PostExerciseCheckinsTableReferences
                                        ._completedExerciseIdTable(db)
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

typedef $$PostExerciseCheckinsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PostExerciseCheckinsTable,
      PostExerciseCheckin,
      $$PostExerciseCheckinsTableFilterComposer,
      $$PostExerciseCheckinsTableOrderingComposer,
      $$PostExerciseCheckinsTableAnnotationComposer,
      $$PostExerciseCheckinsTableCreateCompanionBuilder,
      $$PostExerciseCheckinsTableUpdateCompanionBuilder,
      (PostExerciseCheckin, $$PostExerciseCheckinsTableReferences),
      PostExerciseCheckin,
      PrefetchHooks Function({bool completedExerciseId})
    >;
typedef $$PostMuscleGroupCheckinsTableCreateCompanionBuilder =
    PostMuscleGroupCheckinsCompanion Function({
      Value<int> id,
      required int completedWorkoutId,
      required MuscleGroup muscleGroup,
      required Effort effortLevel,
      required Volume volumeLevel,
    });
typedef $$PostMuscleGroupCheckinsTableUpdateCompanionBuilder =
    PostMuscleGroupCheckinsCompanion Function({
      Value<int> id,
      Value<int> completedWorkoutId,
      Value<MuscleGroup> muscleGroup,
      Value<Effort> effortLevel,
      Value<Volume> volumeLevel,
    });

final class $$PostMuscleGroupCheckinsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PostMuscleGroupCheckinsTable,
          PostMuscleGroupCheckin
        > {
  $$PostMuscleGroupCheckinsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CompletedWorkoutsTable _completedWorkoutIdTable(_$AppDatabase db) =>
      db.completedWorkouts.createAlias(
        $_aliasNameGenerator(
          db.postMuscleGroupCheckins.completedWorkoutId,
          db.completedWorkouts.id,
        ),
      );

  $$CompletedWorkoutsTableProcessedTableManager get completedWorkoutId {
    final $_column = $_itemColumn<int>('completed_workout_id')!;

    final manager = $$CompletedWorkoutsTableTableManager(
      $_db,
      $_db.completedWorkouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_completedWorkoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PostMuscleGroupCheckinsTableFilterComposer
    extends Composer<_$AppDatabase, $PostMuscleGroupCheckinsTable> {
  $$PostMuscleGroupCheckinsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<MuscleGroup, MuscleGroup, String>
  get muscleGroup => $composableBuilder(
    column: $table.muscleGroup,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Effort, Effort, String> get effortLevel =>
      $composableBuilder(
        column: $table.effortLevel,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Volume, Volume, String> get volumeLevel =>
      $composableBuilder(
        column: $table.volumeLevel,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$CompletedWorkoutsTableFilterComposer get completedWorkoutId {
    final $$CompletedWorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completedWorkoutId,
      referencedTable: $db.completedWorkouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedWorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.completedWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PostMuscleGroupCheckinsTableOrderingComposer
    extends Composer<_$AppDatabase, $PostMuscleGroupCheckinsTable> {
  $$PostMuscleGroupCheckinsTableOrderingComposer({
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

  ColumnOrderings<String> get muscleGroup => $composableBuilder(
    column: $table.muscleGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get effortLevel => $composableBuilder(
    column: $table.effortLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get volumeLevel => $composableBuilder(
    column: $table.volumeLevel,
    builder: (column) => ColumnOrderings(column),
  );

  $$CompletedWorkoutsTableOrderingComposer get completedWorkoutId {
    final $$CompletedWorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completedWorkoutId,
      referencedTable: $db.completedWorkouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedWorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.completedWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PostMuscleGroupCheckinsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PostMuscleGroupCheckinsTable> {
  $$PostMuscleGroupCheckinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MuscleGroup, String> get muscleGroup =>
      $composableBuilder(
        column: $table.muscleGroup,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Effort, String> get effortLevel =>
      $composableBuilder(
        column: $table.effortLevel,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Volume, String> get volumeLevel =>
      $composableBuilder(
        column: $table.volumeLevel,
        builder: (column) => column,
      );

  $$CompletedWorkoutsTableAnnotationComposer get completedWorkoutId {
    final $$CompletedWorkoutsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.completedWorkoutId,
          referencedTable: $db.completedWorkouts,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CompletedWorkoutsTableAnnotationComposer(
                $db: $db,
                $table: $db.completedWorkouts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PostMuscleGroupCheckinsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PostMuscleGroupCheckinsTable,
          PostMuscleGroupCheckin,
          $$PostMuscleGroupCheckinsTableFilterComposer,
          $$PostMuscleGroupCheckinsTableOrderingComposer,
          $$PostMuscleGroupCheckinsTableAnnotationComposer,
          $$PostMuscleGroupCheckinsTableCreateCompanionBuilder,
          $$PostMuscleGroupCheckinsTableUpdateCompanionBuilder,
          (PostMuscleGroupCheckin, $$PostMuscleGroupCheckinsTableReferences),
          PostMuscleGroupCheckin,
          PrefetchHooks Function({bool completedWorkoutId})
        > {
  $$PostMuscleGroupCheckinsTableTableManager(
    _$AppDatabase db,
    $PostMuscleGroupCheckinsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PostMuscleGroupCheckinsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PostMuscleGroupCheckinsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PostMuscleGroupCheckinsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> completedWorkoutId = const Value.absent(),
                Value<MuscleGroup> muscleGroup = const Value.absent(),
                Value<Effort> effortLevel = const Value.absent(),
                Value<Volume> volumeLevel = const Value.absent(),
              }) => PostMuscleGroupCheckinsCompanion(
                id: id,
                completedWorkoutId: completedWorkoutId,
                muscleGroup: muscleGroup,
                effortLevel: effortLevel,
                volumeLevel: volumeLevel,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int completedWorkoutId,
                required MuscleGroup muscleGroup,
                required Effort effortLevel,
                required Volume volumeLevel,
              }) => PostMuscleGroupCheckinsCompanion.insert(
                id: id,
                completedWorkoutId: completedWorkoutId,
                muscleGroup: muscleGroup,
                effortLevel: effortLevel,
                volumeLevel: volumeLevel,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PostMuscleGroupCheckinsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({completedWorkoutId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                    if (completedWorkoutId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.completedWorkoutId,
                                referencedTable:
                                    $$PostMuscleGroupCheckinsTableReferences
                                        ._completedWorkoutIdTable(db),
                                referencedColumn:
                                    $$PostMuscleGroupCheckinsTableReferences
                                        ._completedWorkoutIdTable(db)
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

typedef $$PostMuscleGroupCheckinsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PostMuscleGroupCheckinsTable,
      PostMuscleGroupCheckin,
      $$PostMuscleGroupCheckinsTableFilterComposer,
      $$PostMuscleGroupCheckinsTableOrderingComposer,
      $$PostMuscleGroupCheckinsTableAnnotationComposer,
      $$PostMuscleGroupCheckinsTableCreateCompanionBuilder,
      $$PostMuscleGroupCheckinsTableUpdateCompanionBuilder,
      (PostMuscleGroupCheckin, $$PostMuscleGroupCheckinsTableReferences),
      PostMuscleGroupCheckin,
      PrefetchHooks Function({bool completedWorkoutId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MovementsTableTableManager get movements =>
      $$MovementsTableTableManager(_db, _db.movements);
  $$MesoTemplatesTableTableManager get mesoTemplates =>
      $$MesoTemplatesTableTableManager(_db, _db.mesoTemplates);
  $$WeekTemplatesTableTableManager get weekTemplates =>
      $$WeekTemplatesTableTableManager(_db, _db.weekTemplates);
  $$WorkoutTemplatesTableTableManager get workoutTemplates =>
      $$WorkoutTemplatesTableTableManager(_db, _db.workoutTemplates);
  $$ExerciseTemplatesTableTableManager get exerciseTemplates =>
      $$ExerciseTemplatesTableTableManager(_db, _db.exerciseTemplates);
  $$MesocyclesTableTableManager get mesocycles =>
      $$MesocyclesTableTableManager(_db, _db.mesocycles);
  $$WeeksTableTableManager get weeks =>
      $$WeeksTableTableManager(_db, _db.weeks);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db, _db.workouts);
  $$PlannedWorkoutsTableTableManager get plannedWorkouts =>
      $$PlannedWorkoutsTableTableManager(_db, _db.plannedWorkouts);
  $$CompletedWorkoutsTableTableManager get completedWorkouts =>
      $$CompletedWorkoutsTableTableManager(_db, _db.completedWorkouts);
  $$PlannedExercisesTableTableManager get plannedExercises =>
      $$PlannedExercisesTableTableManager(_db, _db.plannedExercises);
  $$CompletedExercisesTableTableManager get completedExercises =>
      $$CompletedExercisesTableTableManager(_db, _db.completedExercises);
  $$PlannedSetsTableTableManager get plannedSets =>
      $$PlannedSetsTableTableManager(_db, _db.plannedSets);
  $$CompletedSetsTableTableManager get completedSets =>
      $$CompletedSetsTableTableManager(_db, _db.completedSets);
  $$PreWorkoutCheckinsTableTableManager get preWorkoutCheckins =>
      $$PreWorkoutCheckinsTableTableManager(_db, _db.preWorkoutCheckins);
  $$PostExerciseCheckinsTableTableManager get postExerciseCheckins =>
      $$PostExerciseCheckinsTableTableManager(_db, _db.postExerciseCheckins);
  $$PostMuscleGroupCheckinsTableTableManager get postMuscleGroupCheckins =>
      $$PostMuscleGroupCheckinsTableTableManager(
        _db,
        _db.postMuscleGroupCheckins,
      );
}
