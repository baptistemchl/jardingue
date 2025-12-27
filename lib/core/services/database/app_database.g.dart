// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PlantsTable extends Plants with TableInfo<$PlantsTable, Plant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _commonNameMeta = const VerificationMeta(
    'commonName',
  );
  @override
  late final GeneratedColumn<String> commonName = GeneratedColumn<String>(
    'common_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latinNameMeta = const VerificationMeta(
    'latinName',
  );
  @override
  late final GeneratedColumn<String> latinName = GeneratedColumn<String>(
    'latin_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryCodeMeta = const VerificationMeta(
    'categoryCode',
  );
  @override
  late final GeneratedColumn<String> categoryCode = GeneratedColumn<String>(
    'category_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryLabelMeta = const VerificationMeta(
    'categoryLabel',
  );
  @override
  late final GeneratedColumn<String> categoryLabel = GeneratedColumn<String>(
    'category_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spacingBetweenPlantsMeta =
      const VerificationMeta('spacingBetweenPlants');
  @override
  late final GeneratedColumn<int> spacingBetweenPlants = GeneratedColumn<int>(
    'spacing_between_plants',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spacingBetweenRowsMeta =
      const VerificationMeta('spacingBetweenRows');
  @override
  late final GeneratedColumn<int> spacingBetweenRows = GeneratedColumn<int>(
    'spacing_between_rows',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plantingDepthCmMeta = const VerificationMeta(
    'plantingDepthCm',
  );
  @override
  late final GeneratedColumn<int> plantingDepthCm = GeneratedColumn<int>(
    'planting_depth_cm',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sunExposureMeta = const VerificationMeta(
    'sunExposure',
  );
  @override
  late final GeneratedColumn<String> sunExposure = GeneratedColumn<String>(
    'sun_exposure',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _soilMoisturePreferenceMeta =
      const VerificationMeta('soilMoisturePreference');
  @override
  late final GeneratedColumn<String> soilMoisturePreference =
      GeneratedColumn<String>(
        'soil_moisture_preference',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _soilTreatmentAdviceMeta =
      const VerificationMeta('soilTreatmentAdvice');
  @override
  late final GeneratedColumn<String> soilTreatmentAdvice =
      GeneratedColumn<String>(
        'soil_treatment_advice',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _soilTypeMeta = const VerificationMeta(
    'soilType',
  );
  @override
  late final GeneratedColumn<String> soilType = GeneratedColumn<String>(
    'soil_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _growingZoneMeta = const VerificationMeta(
    'growingZone',
  );
  @override
  late final GeneratedColumn<String> growingZone = GeneratedColumn<String>(
    'growing_zone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wateringMeta = const VerificationMeta(
    'watering',
  );
  @override
  late final GeneratedColumn<String> watering = GeneratedColumn<String>(
    'watering',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plantingMinTempCMeta = const VerificationMeta(
    'plantingMinTempC',
  );
  @override
  late final GeneratedColumn<int> plantingMinTempC = GeneratedColumn<int>(
    'planting_min_temp_c',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plantingWeatherConditionsMeta =
      const VerificationMeta('plantingWeatherConditions');
  @override
  late final GeneratedColumn<String> plantingWeatherConditions =
      GeneratedColumn<String>(
        'planting_weather_conditions',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sowingUnderCoverPeriodMeta =
      const VerificationMeta('sowingUnderCoverPeriod');
  @override
  late final GeneratedColumn<String> sowingUnderCoverPeriod =
      GeneratedColumn<String>(
        'sowing_under_cover_period',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sowingOpenGroundPeriodMeta =
      const VerificationMeta('sowingOpenGroundPeriod');
  @override
  late final GeneratedColumn<String> sowingOpenGroundPeriod =
      GeneratedColumn<String>(
        'sowing_open_ground_period',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _transplantingPeriodMeta =
      const VerificationMeta('transplantingPeriod');
  @override
  late final GeneratedColumn<String> transplantingPeriod =
      GeneratedColumn<String>(
        'transplanting_period',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _harvestPeriodMeta = const VerificationMeta(
    'harvestPeriod',
  );
  @override
  late final GeneratedColumn<String> harvestPeriod = GeneratedColumn<String>(
    'harvest_period',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sowingRecommendationMeta =
      const VerificationMeta('sowingRecommendation');
  @override
  late final GeneratedColumn<String> sowingRecommendation =
      GeneratedColumn<String>(
        'sowing_recommendation',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cultivationGreenhouseMeta =
      const VerificationMeta('cultivationGreenhouse');
  @override
  late final GeneratedColumn<String> cultivationGreenhouse =
      GeneratedColumn<String>(
        'cultivation_greenhouse',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _plantingAdviceMeta = const VerificationMeta(
    'plantingAdvice',
  );
  @override
  late final GeneratedColumn<String> plantingAdvice = GeneratedColumn<String>(
    'planting_advice',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _careAdviceMeta = const VerificationMeta(
    'careAdvice',
  );
  @override
  late final GeneratedColumn<String> careAdvice = GeneratedColumn<String>(
    'care_advice',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _redFlagsMeta = const VerificationMeta(
    'redFlags',
  );
  @override
  late final GeneratedColumn<String> redFlags = GeneratedColumn<String>(
    'red_flags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mainDestroyersMeta = const VerificationMeta(
    'mainDestroyers',
  );
  @override
  late final GeneratedColumn<String> mainDestroyers = GeneratedColumn<String>(
    'main_destroyers',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sowingCalendarMeta = const VerificationMeta(
    'sowingCalendar',
  );
  @override
  late final GeneratedColumn<String> sowingCalendar = GeneratedColumn<String>(
    'sowing_calendar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plantingCalendarMeta = const VerificationMeta(
    'plantingCalendar',
  );
  @override
  late final GeneratedColumn<String> plantingCalendar = GeneratedColumn<String>(
    'planting_calendar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _harvestCalendarMeta = const VerificationMeta(
    'harvestCalendar',
  );
  @override
  late final GeneratedColumn<String> harvestCalendar = GeneratedColumn<String>(
    'harvest_calendar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isUserModifiedMeta = const VerificationMeta(
    'isUserModified',
  );
  @override
  late final GeneratedColumn<bool> isUserModified = GeneratedColumn<bool>(
    'is_user_modified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_user_modified" IN (0, 1))',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    commonName,
    latinName,
    categoryCode,
    categoryLabel,
    spacingBetweenPlants,
    spacingBetweenRows,
    plantingDepthCm,
    sunExposure,
    soilMoisturePreference,
    soilTreatmentAdvice,
    soilType,
    growingZone,
    watering,
    plantingMinTempC,
    plantingWeatherConditions,
    sowingUnderCoverPeriod,
    sowingOpenGroundPeriod,
    transplantingPeriod,
    harvestPeriod,
    sowingRecommendation,
    cultivationGreenhouse,
    plantingAdvice,
    careAdvice,
    redFlags,
    mainDestroyers,
    sowingCalendar,
    plantingCalendar,
    harvestCalendar,
    isUserModified,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plants';
  @override
  VerificationContext validateIntegrity(
    Insertable<Plant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('common_name')) {
      context.handle(
        _commonNameMeta,
        commonName.isAcceptableOrUnknown(data['common_name']!, _commonNameMeta),
      );
    } else if (isInserting) {
      context.missing(_commonNameMeta);
    }
    if (data.containsKey('latin_name')) {
      context.handle(
        _latinNameMeta,
        latinName.isAcceptableOrUnknown(data['latin_name']!, _latinNameMeta),
      );
    }
    if (data.containsKey('category_code')) {
      context.handle(
        _categoryCodeMeta,
        categoryCode.isAcceptableOrUnknown(
          data['category_code']!,
          _categoryCodeMeta,
        ),
      );
    }
    if (data.containsKey('category_label')) {
      context.handle(
        _categoryLabelMeta,
        categoryLabel.isAcceptableOrUnknown(
          data['category_label']!,
          _categoryLabelMeta,
        ),
      );
    }
    if (data.containsKey('spacing_between_plants')) {
      context.handle(
        _spacingBetweenPlantsMeta,
        spacingBetweenPlants.isAcceptableOrUnknown(
          data['spacing_between_plants']!,
          _spacingBetweenPlantsMeta,
        ),
      );
    }
    if (data.containsKey('spacing_between_rows')) {
      context.handle(
        _spacingBetweenRowsMeta,
        spacingBetweenRows.isAcceptableOrUnknown(
          data['spacing_between_rows']!,
          _spacingBetweenRowsMeta,
        ),
      );
    }
    if (data.containsKey('planting_depth_cm')) {
      context.handle(
        _plantingDepthCmMeta,
        plantingDepthCm.isAcceptableOrUnknown(
          data['planting_depth_cm']!,
          _plantingDepthCmMeta,
        ),
      );
    }
    if (data.containsKey('sun_exposure')) {
      context.handle(
        _sunExposureMeta,
        sunExposure.isAcceptableOrUnknown(
          data['sun_exposure']!,
          _sunExposureMeta,
        ),
      );
    }
    if (data.containsKey('soil_moisture_preference')) {
      context.handle(
        _soilMoisturePreferenceMeta,
        soilMoisturePreference.isAcceptableOrUnknown(
          data['soil_moisture_preference']!,
          _soilMoisturePreferenceMeta,
        ),
      );
    }
    if (data.containsKey('soil_treatment_advice')) {
      context.handle(
        _soilTreatmentAdviceMeta,
        soilTreatmentAdvice.isAcceptableOrUnknown(
          data['soil_treatment_advice']!,
          _soilTreatmentAdviceMeta,
        ),
      );
    }
    if (data.containsKey('soil_type')) {
      context.handle(
        _soilTypeMeta,
        soilType.isAcceptableOrUnknown(data['soil_type']!, _soilTypeMeta),
      );
    }
    if (data.containsKey('growing_zone')) {
      context.handle(
        _growingZoneMeta,
        growingZone.isAcceptableOrUnknown(
          data['growing_zone']!,
          _growingZoneMeta,
        ),
      );
    }
    if (data.containsKey('watering')) {
      context.handle(
        _wateringMeta,
        watering.isAcceptableOrUnknown(data['watering']!, _wateringMeta),
      );
    }
    if (data.containsKey('planting_min_temp_c')) {
      context.handle(
        _plantingMinTempCMeta,
        plantingMinTempC.isAcceptableOrUnknown(
          data['planting_min_temp_c']!,
          _plantingMinTempCMeta,
        ),
      );
    }
    if (data.containsKey('planting_weather_conditions')) {
      context.handle(
        _plantingWeatherConditionsMeta,
        plantingWeatherConditions.isAcceptableOrUnknown(
          data['planting_weather_conditions']!,
          _plantingWeatherConditionsMeta,
        ),
      );
    }
    if (data.containsKey('sowing_under_cover_period')) {
      context.handle(
        _sowingUnderCoverPeriodMeta,
        sowingUnderCoverPeriod.isAcceptableOrUnknown(
          data['sowing_under_cover_period']!,
          _sowingUnderCoverPeriodMeta,
        ),
      );
    }
    if (data.containsKey('sowing_open_ground_period')) {
      context.handle(
        _sowingOpenGroundPeriodMeta,
        sowingOpenGroundPeriod.isAcceptableOrUnknown(
          data['sowing_open_ground_period']!,
          _sowingOpenGroundPeriodMeta,
        ),
      );
    }
    if (data.containsKey('transplanting_period')) {
      context.handle(
        _transplantingPeriodMeta,
        transplantingPeriod.isAcceptableOrUnknown(
          data['transplanting_period']!,
          _transplantingPeriodMeta,
        ),
      );
    }
    if (data.containsKey('harvest_period')) {
      context.handle(
        _harvestPeriodMeta,
        harvestPeriod.isAcceptableOrUnknown(
          data['harvest_period']!,
          _harvestPeriodMeta,
        ),
      );
    }
    if (data.containsKey('sowing_recommendation')) {
      context.handle(
        _sowingRecommendationMeta,
        sowingRecommendation.isAcceptableOrUnknown(
          data['sowing_recommendation']!,
          _sowingRecommendationMeta,
        ),
      );
    }
    if (data.containsKey('cultivation_greenhouse')) {
      context.handle(
        _cultivationGreenhouseMeta,
        cultivationGreenhouse.isAcceptableOrUnknown(
          data['cultivation_greenhouse']!,
          _cultivationGreenhouseMeta,
        ),
      );
    }
    if (data.containsKey('planting_advice')) {
      context.handle(
        _plantingAdviceMeta,
        plantingAdvice.isAcceptableOrUnknown(
          data['planting_advice']!,
          _plantingAdviceMeta,
        ),
      );
    }
    if (data.containsKey('care_advice')) {
      context.handle(
        _careAdviceMeta,
        careAdvice.isAcceptableOrUnknown(data['care_advice']!, _careAdviceMeta),
      );
    }
    if (data.containsKey('red_flags')) {
      context.handle(
        _redFlagsMeta,
        redFlags.isAcceptableOrUnknown(data['red_flags']!, _redFlagsMeta),
      );
    }
    if (data.containsKey('main_destroyers')) {
      context.handle(
        _mainDestroyersMeta,
        mainDestroyers.isAcceptableOrUnknown(
          data['main_destroyers']!,
          _mainDestroyersMeta,
        ),
      );
    }
    if (data.containsKey('sowing_calendar')) {
      context.handle(
        _sowingCalendarMeta,
        sowingCalendar.isAcceptableOrUnknown(
          data['sowing_calendar']!,
          _sowingCalendarMeta,
        ),
      );
    }
    if (data.containsKey('planting_calendar')) {
      context.handle(
        _plantingCalendarMeta,
        plantingCalendar.isAcceptableOrUnknown(
          data['planting_calendar']!,
          _plantingCalendarMeta,
        ),
      );
    }
    if (data.containsKey('harvest_calendar')) {
      context.handle(
        _harvestCalendarMeta,
        harvestCalendar.isAcceptableOrUnknown(
          data['harvest_calendar']!,
          _harvestCalendarMeta,
        ),
      );
    }
    if (data.containsKey('is_user_modified')) {
      context.handle(
        _isUserModifiedMeta,
        isUserModified.isAcceptableOrUnknown(
          data['is_user_modified']!,
          _isUserModifiedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Plant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Plant(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      commonName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}common_name'],
      )!,
      latinName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}latin_name'],
      ),
      categoryCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_code'],
      ),
      categoryLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_label'],
      ),
      spacingBetweenPlants: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}spacing_between_plants'],
      ),
      spacingBetweenRows: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}spacing_between_rows'],
      ),
      plantingDepthCm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planting_depth_cm'],
      ),
      sunExposure: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sun_exposure'],
      ),
      soilMoisturePreference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}soil_moisture_preference'],
      ),
      soilTreatmentAdvice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}soil_treatment_advice'],
      ),
      soilType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}soil_type'],
      ),
      growingZone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}growing_zone'],
      ),
      watering: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}watering'],
      ),
      plantingMinTempC: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planting_min_temp_c'],
      ),
      plantingWeatherConditions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planting_weather_conditions'],
      ),
      sowingUnderCoverPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sowing_under_cover_period'],
      ),
      sowingOpenGroundPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sowing_open_ground_period'],
      ),
      transplantingPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transplanting_period'],
      ),
      harvestPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}harvest_period'],
      ),
      sowingRecommendation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sowing_recommendation'],
      ),
      cultivationGreenhouse: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cultivation_greenhouse'],
      ),
      plantingAdvice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planting_advice'],
      ),
      careAdvice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}care_advice'],
      ),
      redFlags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}red_flags'],
      ),
      mainDestroyers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}main_destroyers'],
      ),
      sowingCalendar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sowing_calendar'],
      ),
      plantingCalendar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planting_calendar'],
      ),
      harvestCalendar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}harvest_calendar'],
      ),
      isUserModified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_user_modified'],
      )!,
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
  $PlantsTable createAlias(String alias) {
    return $PlantsTable(attachedDatabase, alias);
  }
}

class Plant extends DataClass implements Insertable<Plant> {
  final int id;
  final String commonName;
  final String? latinName;
  final String? categoryCode;
  final String? categoryLabel;
  final int? spacingBetweenPlants;
  final int? spacingBetweenRows;
  final int? plantingDepthCm;
  final String? sunExposure;
  final String? soilMoisturePreference;
  final String? soilTreatmentAdvice;
  final String? soilType;
  final String? growingZone;
  final String? watering;
  final int? plantingMinTempC;
  final String? plantingWeatherConditions;
  final String? sowingUnderCoverPeriod;
  final String? sowingOpenGroundPeriod;
  final String? transplantingPeriod;
  final String? harvestPeriod;
  final String? sowingRecommendation;
  final String? cultivationGreenhouse;
  final String? plantingAdvice;
  final String? careAdvice;
  final String? redFlags;
  final String? mainDestroyers;
  final String? sowingCalendar;
  final String? plantingCalendar;
  final String? harvestCalendar;
  final bool isUserModified;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Plant({
    required this.id,
    required this.commonName,
    this.latinName,
    this.categoryCode,
    this.categoryLabel,
    this.spacingBetweenPlants,
    this.spacingBetweenRows,
    this.plantingDepthCm,
    this.sunExposure,
    this.soilMoisturePreference,
    this.soilTreatmentAdvice,
    this.soilType,
    this.growingZone,
    this.watering,
    this.plantingMinTempC,
    this.plantingWeatherConditions,
    this.sowingUnderCoverPeriod,
    this.sowingOpenGroundPeriod,
    this.transplantingPeriod,
    this.harvestPeriod,
    this.sowingRecommendation,
    this.cultivationGreenhouse,
    this.plantingAdvice,
    this.careAdvice,
    this.redFlags,
    this.mainDestroyers,
    this.sowingCalendar,
    this.plantingCalendar,
    this.harvestCalendar,
    required this.isUserModified,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['common_name'] = Variable<String>(commonName);
    if (!nullToAbsent || latinName != null) {
      map['latin_name'] = Variable<String>(latinName);
    }
    if (!nullToAbsent || categoryCode != null) {
      map['category_code'] = Variable<String>(categoryCode);
    }
    if (!nullToAbsent || categoryLabel != null) {
      map['category_label'] = Variable<String>(categoryLabel);
    }
    if (!nullToAbsent || spacingBetweenPlants != null) {
      map['spacing_between_plants'] = Variable<int>(spacingBetweenPlants);
    }
    if (!nullToAbsent || spacingBetweenRows != null) {
      map['spacing_between_rows'] = Variable<int>(spacingBetweenRows);
    }
    if (!nullToAbsent || plantingDepthCm != null) {
      map['planting_depth_cm'] = Variable<int>(plantingDepthCm);
    }
    if (!nullToAbsent || sunExposure != null) {
      map['sun_exposure'] = Variable<String>(sunExposure);
    }
    if (!nullToAbsent || soilMoisturePreference != null) {
      map['soil_moisture_preference'] = Variable<String>(
        soilMoisturePreference,
      );
    }
    if (!nullToAbsent || soilTreatmentAdvice != null) {
      map['soil_treatment_advice'] = Variable<String>(soilTreatmentAdvice);
    }
    if (!nullToAbsent || soilType != null) {
      map['soil_type'] = Variable<String>(soilType);
    }
    if (!nullToAbsent || growingZone != null) {
      map['growing_zone'] = Variable<String>(growingZone);
    }
    if (!nullToAbsent || watering != null) {
      map['watering'] = Variable<String>(watering);
    }
    if (!nullToAbsent || plantingMinTempC != null) {
      map['planting_min_temp_c'] = Variable<int>(plantingMinTempC);
    }
    if (!nullToAbsent || plantingWeatherConditions != null) {
      map['planting_weather_conditions'] = Variable<String>(
        plantingWeatherConditions,
      );
    }
    if (!nullToAbsent || sowingUnderCoverPeriod != null) {
      map['sowing_under_cover_period'] = Variable<String>(
        sowingUnderCoverPeriod,
      );
    }
    if (!nullToAbsent || sowingOpenGroundPeriod != null) {
      map['sowing_open_ground_period'] = Variable<String>(
        sowingOpenGroundPeriod,
      );
    }
    if (!nullToAbsent || transplantingPeriod != null) {
      map['transplanting_period'] = Variable<String>(transplantingPeriod);
    }
    if (!nullToAbsent || harvestPeriod != null) {
      map['harvest_period'] = Variable<String>(harvestPeriod);
    }
    if (!nullToAbsent || sowingRecommendation != null) {
      map['sowing_recommendation'] = Variable<String>(sowingRecommendation);
    }
    if (!nullToAbsent || cultivationGreenhouse != null) {
      map['cultivation_greenhouse'] = Variable<String>(cultivationGreenhouse);
    }
    if (!nullToAbsent || plantingAdvice != null) {
      map['planting_advice'] = Variable<String>(plantingAdvice);
    }
    if (!nullToAbsent || careAdvice != null) {
      map['care_advice'] = Variable<String>(careAdvice);
    }
    if (!nullToAbsent || redFlags != null) {
      map['red_flags'] = Variable<String>(redFlags);
    }
    if (!nullToAbsent || mainDestroyers != null) {
      map['main_destroyers'] = Variable<String>(mainDestroyers);
    }
    if (!nullToAbsent || sowingCalendar != null) {
      map['sowing_calendar'] = Variable<String>(sowingCalendar);
    }
    if (!nullToAbsent || plantingCalendar != null) {
      map['planting_calendar'] = Variable<String>(plantingCalendar);
    }
    if (!nullToAbsent || harvestCalendar != null) {
      map['harvest_calendar'] = Variable<String>(harvestCalendar);
    }
    map['is_user_modified'] = Variable<bool>(isUserModified);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlantsCompanion toCompanion(bool nullToAbsent) {
    return PlantsCompanion(
      id: Value(id),
      commonName: Value(commonName),
      latinName: latinName == null && nullToAbsent
          ? const Value.absent()
          : Value(latinName),
      categoryCode: categoryCode == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryCode),
      categoryLabel: categoryLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryLabel),
      spacingBetweenPlants: spacingBetweenPlants == null && nullToAbsent
          ? const Value.absent()
          : Value(spacingBetweenPlants),
      spacingBetweenRows: spacingBetweenRows == null && nullToAbsent
          ? const Value.absent()
          : Value(spacingBetweenRows),
      plantingDepthCm: plantingDepthCm == null && nullToAbsent
          ? const Value.absent()
          : Value(plantingDepthCm),
      sunExposure: sunExposure == null && nullToAbsent
          ? const Value.absent()
          : Value(sunExposure),
      soilMoisturePreference: soilMoisturePreference == null && nullToAbsent
          ? const Value.absent()
          : Value(soilMoisturePreference),
      soilTreatmentAdvice: soilTreatmentAdvice == null && nullToAbsent
          ? const Value.absent()
          : Value(soilTreatmentAdvice),
      soilType: soilType == null && nullToAbsent
          ? const Value.absent()
          : Value(soilType),
      growingZone: growingZone == null && nullToAbsent
          ? const Value.absent()
          : Value(growingZone),
      watering: watering == null && nullToAbsent
          ? const Value.absent()
          : Value(watering),
      plantingMinTempC: plantingMinTempC == null && nullToAbsent
          ? const Value.absent()
          : Value(plantingMinTempC),
      plantingWeatherConditions:
          plantingWeatherConditions == null && nullToAbsent
          ? const Value.absent()
          : Value(plantingWeatherConditions),
      sowingUnderCoverPeriod: sowingUnderCoverPeriod == null && nullToAbsent
          ? const Value.absent()
          : Value(sowingUnderCoverPeriod),
      sowingOpenGroundPeriod: sowingOpenGroundPeriod == null && nullToAbsent
          ? const Value.absent()
          : Value(sowingOpenGroundPeriod),
      transplantingPeriod: transplantingPeriod == null && nullToAbsent
          ? const Value.absent()
          : Value(transplantingPeriod),
      harvestPeriod: harvestPeriod == null && nullToAbsent
          ? const Value.absent()
          : Value(harvestPeriod),
      sowingRecommendation: sowingRecommendation == null && nullToAbsent
          ? const Value.absent()
          : Value(sowingRecommendation),
      cultivationGreenhouse: cultivationGreenhouse == null && nullToAbsent
          ? const Value.absent()
          : Value(cultivationGreenhouse),
      plantingAdvice: plantingAdvice == null && nullToAbsent
          ? const Value.absent()
          : Value(plantingAdvice),
      careAdvice: careAdvice == null && nullToAbsent
          ? const Value.absent()
          : Value(careAdvice),
      redFlags: redFlags == null && nullToAbsent
          ? const Value.absent()
          : Value(redFlags),
      mainDestroyers: mainDestroyers == null && nullToAbsent
          ? const Value.absent()
          : Value(mainDestroyers),
      sowingCalendar: sowingCalendar == null && nullToAbsent
          ? const Value.absent()
          : Value(sowingCalendar),
      plantingCalendar: plantingCalendar == null && nullToAbsent
          ? const Value.absent()
          : Value(plantingCalendar),
      harvestCalendar: harvestCalendar == null && nullToAbsent
          ? const Value.absent()
          : Value(harvestCalendar),
      isUserModified: Value(isUserModified),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Plant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Plant(
      id: serializer.fromJson<int>(json['id']),
      commonName: serializer.fromJson<String>(json['commonName']),
      latinName: serializer.fromJson<String?>(json['latinName']),
      categoryCode: serializer.fromJson<String?>(json['categoryCode']),
      categoryLabel: serializer.fromJson<String?>(json['categoryLabel']),
      spacingBetweenPlants: serializer.fromJson<int?>(
        json['spacingBetweenPlants'],
      ),
      spacingBetweenRows: serializer.fromJson<int?>(json['spacingBetweenRows']),
      plantingDepthCm: serializer.fromJson<int?>(json['plantingDepthCm']),
      sunExposure: serializer.fromJson<String?>(json['sunExposure']),
      soilMoisturePreference: serializer.fromJson<String?>(
        json['soilMoisturePreference'],
      ),
      soilTreatmentAdvice: serializer.fromJson<String?>(
        json['soilTreatmentAdvice'],
      ),
      soilType: serializer.fromJson<String?>(json['soilType']),
      growingZone: serializer.fromJson<String?>(json['growingZone']),
      watering: serializer.fromJson<String?>(json['watering']),
      plantingMinTempC: serializer.fromJson<int?>(json['plantingMinTempC']),
      plantingWeatherConditions: serializer.fromJson<String?>(
        json['plantingWeatherConditions'],
      ),
      sowingUnderCoverPeriod: serializer.fromJson<String?>(
        json['sowingUnderCoverPeriod'],
      ),
      sowingOpenGroundPeriod: serializer.fromJson<String?>(
        json['sowingOpenGroundPeriod'],
      ),
      transplantingPeriod: serializer.fromJson<String?>(
        json['transplantingPeriod'],
      ),
      harvestPeriod: serializer.fromJson<String?>(json['harvestPeriod']),
      sowingRecommendation: serializer.fromJson<String?>(
        json['sowingRecommendation'],
      ),
      cultivationGreenhouse: serializer.fromJson<String?>(
        json['cultivationGreenhouse'],
      ),
      plantingAdvice: serializer.fromJson<String?>(json['plantingAdvice']),
      careAdvice: serializer.fromJson<String?>(json['careAdvice']),
      redFlags: serializer.fromJson<String?>(json['redFlags']),
      mainDestroyers: serializer.fromJson<String?>(json['mainDestroyers']),
      sowingCalendar: serializer.fromJson<String?>(json['sowingCalendar']),
      plantingCalendar: serializer.fromJson<String?>(json['plantingCalendar']),
      harvestCalendar: serializer.fromJson<String?>(json['harvestCalendar']),
      isUserModified: serializer.fromJson<bool>(json['isUserModified']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'commonName': serializer.toJson<String>(commonName),
      'latinName': serializer.toJson<String?>(latinName),
      'categoryCode': serializer.toJson<String?>(categoryCode),
      'categoryLabel': serializer.toJson<String?>(categoryLabel),
      'spacingBetweenPlants': serializer.toJson<int?>(spacingBetweenPlants),
      'spacingBetweenRows': serializer.toJson<int?>(spacingBetweenRows),
      'plantingDepthCm': serializer.toJson<int?>(plantingDepthCm),
      'sunExposure': serializer.toJson<String?>(sunExposure),
      'soilMoisturePreference': serializer.toJson<String?>(
        soilMoisturePreference,
      ),
      'soilTreatmentAdvice': serializer.toJson<String?>(soilTreatmentAdvice),
      'soilType': serializer.toJson<String?>(soilType),
      'growingZone': serializer.toJson<String?>(growingZone),
      'watering': serializer.toJson<String?>(watering),
      'plantingMinTempC': serializer.toJson<int?>(plantingMinTempC),
      'plantingWeatherConditions': serializer.toJson<String?>(
        plantingWeatherConditions,
      ),
      'sowingUnderCoverPeriod': serializer.toJson<String?>(
        sowingUnderCoverPeriod,
      ),
      'sowingOpenGroundPeriod': serializer.toJson<String?>(
        sowingOpenGroundPeriod,
      ),
      'transplantingPeriod': serializer.toJson<String?>(transplantingPeriod),
      'harvestPeriod': serializer.toJson<String?>(harvestPeriod),
      'sowingRecommendation': serializer.toJson<String?>(sowingRecommendation),
      'cultivationGreenhouse': serializer.toJson<String?>(
        cultivationGreenhouse,
      ),
      'plantingAdvice': serializer.toJson<String?>(plantingAdvice),
      'careAdvice': serializer.toJson<String?>(careAdvice),
      'redFlags': serializer.toJson<String?>(redFlags),
      'mainDestroyers': serializer.toJson<String?>(mainDestroyers),
      'sowingCalendar': serializer.toJson<String?>(sowingCalendar),
      'plantingCalendar': serializer.toJson<String?>(plantingCalendar),
      'harvestCalendar': serializer.toJson<String?>(harvestCalendar),
      'isUserModified': serializer.toJson<bool>(isUserModified),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Plant copyWith({
    int? id,
    String? commonName,
    Value<String?> latinName = const Value.absent(),
    Value<String?> categoryCode = const Value.absent(),
    Value<String?> categoryLabel = const Value.absent(),
    Value<int?> spacingBetweenPlants = const Value.absent(),
    Value<int?> spacingBetweenRows = const Value.absent(),
    Value<int?> plantingDepthCm = const Value.absent(),
    Value<String?> sunExposure = const Value.absent(),
    Value<String?> soilMoisturePreference = const Value.absent(),
    Value<String?> soilTreatmentAdvice = const Value.absent(),
    Value<String?> soilType = const Value.absent(),
    Value<String?> growingZone = const Value.absent(),
    Value<String?> watering = const Value.absent(),
    Value<int?> plantingMinTempC = const Value.absent(),
    Value<String?> plantingWeatherConditions = const Value.absent(),
    Value<String?> sowingUnderCoverPeriod = const Value.absent(),
    Value<String?> sowingOpenGroundPeriod = const Value.absent(),
    Value<String?> transplantingPeriod = const Value.absent(),
    Value<String?> harvestPeriod = const Value.absent(),
    Value<String?> sowingRecommendation = const Value.absent(),
    Value<String?> cultivationGreenhouse = const Value.absent(),
    Value<String?> plantingAdvice = const Value.absent(),
    Value<String?> careAdvice = const Value.absent(),
    Value<String?> redFlags = const Value.absent(),
    Value<String?> mainDestroyers = const Value.absent(),
    Value<String?> sowingCalendar = const Value.absent(),
    Value<String?> plantingCalendar = const Value.absent(),
    Value<String?> harvestCalendar = const Value.absent(),
    bool? isUserModified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Plant(
    id: id ?? this.id,
    commonName: commonName ?? this.commonName,
    latinName: latinName.present ? latinName.value : this.latinName,
    categoryCode: categoryCode.present ? categoryCode.value : this.categoryCode,
    categoryLabel: categoryLabel.present
        ? categoryLabel.value
        : this.categoryLabel,
    spacingBetweenPlants: spacingBetweenPlants.present
        ? spacingBetweenPlants.value
        : this.spacingBetweenPlants,
    spacingBetweenRows: spacingBetweenRows.present
        ? spacingBetweenRows.value
        : this.spacingBetweenRows,
    plantingDepthCm: plantingDepthCm.present
        ? plantingDepthCm.value
        : this.plantingDepthCm,
    sunExposure: sunExposure.present ? sunExposure.value : this.sunExposure,
    soilMoisturePreference: soilMoisturePreference.present
        ? soilMoisturePreference.value
        : this.soilMoisturePreference,
    soilTreatmentAdvice: soilTreatmentAdvice.present
        ? soilTreatmentAdvice.value
        : this.soilTreatmentAdvice,
    soilType: soilType.present ? soilType.value : this.soilType,
    growingZone: growingZone.present ? growingZone.value : this.growingZone,
    watering: watering.present ? watering.value : this.watering,
    plantingMinTempC: plantingMinTempC.present
        ? plantingMinTempC.value
        : this.plantingMinTempC,
    plantingWeatherConditions: plantingWeatherConditions.present
        ? plantingWeatherConditions.value
        : this.plantingWeatherConditions,
    sowingUnderCoverPeriod: sowingUnderCoverPeriod.present
        ? sowingUnderCoverPeriod.value
        : this.sowingUnderCoverPeriod,
    sowingOpenGroundPeriod: sowingOpenGroundPeriod.present
        ? sowingOpenGroundPeriod.value
        : this.sowingOpenGroundPeriod,
    transplantingPeriod: transplantingPeriod.present
        ? transplantingPeriod.value
        : this.transplantingPeriod,
    harvestPeriod: harvestPeriod.present
        ? harvestPeriod.value
        : this.harvestPeriod,
    sowingRecommendation: sowingRecommendation.present
        ? sowingRecommendation.value
        : this.sowingRecommendation,
    cultivationGreenhouse: cultivationGreenhouse.present
        ? cultivationGreenhouse.value
        : this.cultivationGreenhouse,
    plantingAdvice: plantingAdvice.present
        ? plantingAdvice.value
        : this.plantingAdvice,
    careAdvice: careAdvice.present ? careAdvice.value : this.careAdvice,
    redFlags: redFlags.present ? redFlags.value : this.redFlags,
    mainDestroyers: mainDestroyers.present
        ? mainDestroyers.value
        : this.mainDestroyers,
    sowingCalendar: sowingCalendar.present
        ? sowingCalendar.value
        : this.sowingCalendar,
    plantingCalendar: plantingCalendar.present
        ? plantingCalendar.value
        : this.plantingCalendar,
    harvestCalendar: harvestCalendar.present
        ? harvestCalendar.value
        : this.harvestCalendar,
    isUserModified: isUserModified ?? this.isUserModified,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Plant copyWithCompanion(PlantsCompanion data) {
    return Plant(
      id: data.id.present ? data.id.value : this.id,
      commonName: data.commonName.present
          ? data.commonName.value
          : this.commonName,
      latinName: data.latinName.present ? data.latinName.value : this.latinName,
      categoryCode: data.categoryCode.present
          ? data.categoryCode.value
          : this.categoryCode,
      categoryLabel: data.categoryLabel.present
          ? data.categoryLabel.value
          : this.categoryLabel,
      spacingBetweenPlants: data.spacingBetweenPlants.present
          ? data.spacingBetweenPlants.value
          : this.spacingBetweenPlants,
      spacingBetweenRows: data.spacingBetweenRows.present
          ? data.spacingBetweenRows.value
          : this.spacingBetweenRows,
      plantingDepthCm: data.plantingDepthCm.present
          ? data.plantingDepthCm.value
          : this.plantingDepthCm,
      sunExposure: data.sunExposure.present
          ? data.sunExposure.value
          : this.sunExposure,
      soilMoisturePreference: data.soilMoisturePreference.present
          ? data.soilMoisturePreference.value
          : this.soilMoisturePreference,
      soilTreatmentAdvice: data.soilTreatmentAdvice.present
          ? data.soilTreatmentAdvice.value
          : this.soilTreatmentAdvice,
      soilType: data.soilType.present ? data.soilType.value : this.soilType,
      growingZone: data.growingZone.present
          ? data.growingZone.value
          : this.growingZone,
      watering: data.watering.present ? data.watering.value : this.watering,
      plantingMinTempC: data.plantingMinTempC.present
          ? data.plantingMinTempC.value
          : this.plantingMinTempC,
      plantingWeatherConditions: data.plantingWeatherConditions.present
          ? data.plantingWeatherConditions.value
          : this.plantingWeatherConditions,
      sowingUnderCoverPeriod: data.sowingUnderCoverPeriod.present
          ? data.sowingUnderCoverPeriod.value
          : this.sowingUnderCoverPeriod,
      sowingOpenGroundPeriod: data.sowingOpenGroundPeriod.present
          ? data.sowingOpenGroundPeriod.value
          : this.sowingOpenGroundPeriod,
      transplantingPeriod: data.transplantingPeriod.present
          ? data.transplantingPeriod.value
          : this.transplantingPeriod,
      harvestPeriod: data.harvestPeriod.present
          ? data.harvestPeriod.value
          : this.harvestPeriod,
      sowingRecommendation: data.sowingRecommendation.present
          ? data.sowingRecommendation.value
          : this.sowingRecommendation,
      cultivationGreenhouse: data.cultivationGreenhouse.present
          ? data.cultivationGreenhouse.value
          : this.cultivationGreenhouse,
      plantingAdvice: data.plantingAdvice.present
          ? data.plantingAdvice.value
          : this.plantingAdvice,
      careAdvice: data.careAdvice.present
          ? data.careAdvice.value
          : this.careAdvice,
      redFlags: data.redFlags.present ? data.redFlags.value : this.redFlags,
      mainDestroyers: data.mainDestroyers.present
          ? data.mainDestroyers.value
          : this.mainDestroyers,
      sowingCalendar: data.sowingCalendar.present
          ? data.sowingCalendar.value
          : this.sowingCalendar,
      plantingCalendar: data.plantingCalendar.present
          ? data.plantingCalendar.value
          : this.plantingCalendar,
      harvestCalendar: data.harvestCalendar.present
          ? data.harvestCalendar.value
          : this.harvestCalendar,
      isUserModified: data.isUserModified.present
          ? data.isUserModified.value
          : this.isUserModified,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Plant(')
          ..write('id: $id, ')
          ..write('commonName: $commonName, ')
          ..write('latinName: $latinName, ')
          ..write('categoryCode: $categoryCode, ')
          ..write('categoryLabel: $categoryLabel, ')
          ..write('spacingBetweenPlants: $spacingBetweenPlants, ')
          ..write('spacingBetweenRows: $spacingBetweenRows, ')
          ..write('plantingDepthCm: $plantingDepthCm, ')
          ..write('sunExposure: $sunExposure, ')
          ..write('soilMoisturePreference: $soilMoisturePreference, ')
          ..write('soilTreatmentAdvice: $soilTreatmentAdvice, ')
          ..write('soilType: $soilType, ')
          ..write('growingZone: $growingZone, ')
          ..write('watering: $watering, ')
          ..write('plantingMinTempC: $plantingMinTempC, ')
          ..write('plantingWeatherConditions: $plantingWeatherConditions, ')
          ..write('sowingUnderCoverPeriod: $sowingUnderCoverPeriod, ')
          ..write('sowingOpenGroundPeriod: $sowingOpenGroundPeriod, ')
          ..write('transplantingPeriod: $transplantingPeriod, ')
          ..write('harvestPeriod: $harvestPeriod, ')
          ..write('sowingRecommendation: $sowingRecommendation, ')
          ..write('cultivationGreenhouse: $cultivationGreenhouse, ')
          ..write('plantingAdvice: $plantingAdvice, ')
          ..write('careAdvice: $careAdvice, ')
          ..write('redFlags: $redFlags, ')
          ..write('mainDestroyers: $mainDestroyers, ')
          ..write('sowingCalendar: $sowingCalendar, ')
          ..write('plantingCalendar: $plantingCalendar, ')
          ..write('harvestCalendar: $harvestCalendar, ')
          ..write('isUserModified: $isUserModified, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    commonName,
    latinName,
    categoryCode,
    categoryLabel,
    spacingBetweenPlants,
    spacingBetweenRows,
    plantingDepthCm,
    sunExposure,
    soilMoisturePreference,
    soilTreatmentAdvice,
    soilType,
    growingZone,
    watering,
    plantingMinTempC,
    plantingWeatherConditions,
    sowingUnderCoverPeriod,
    sowingOpenGroundPeriod,
    transplantingPeriod,
    harvestPeriod,
    sowingRecommendation,
    cultivationGreenhouse,
    plantingAdvice,
    careAdvice,
    redFlags,
    mainDestroyers,
    sowingCalendar,
    plantingCalendar,
    harvestCalendar,
    isUserModified,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Plant &&
          other.id == this.id &&
          other.commonName == this.commonName &&
          other.latinName == this.latinName &&
          other.categoryCode == this.categoryCode &&
          other.categoryLabel == this.categoryLabel &&
          other.spacingBetweenPlants == this.spacingBetweenPlants &&
          other.spacingBetweenRows == this.spacingBetweenRows &&
          other.plantingDepthCm == this.plantingDepthCm &&
          other.sunExposure == this.sunExposure &&
          other.soilMoisturePreference == this.soilMoisturePreference &&
          other.soilTreatmentAdvice == this.soilTreatmentAdvice &&
          other.soilType == this.soilType &&
          other.growingZone == this.growingZone &&
          other.watering == this.watering &&
          other.plantingMinTempC == this.plantingMinTempC &&
          other.plantingWeatherConditions == this.plantingWeatherConditions &&
          other.sowingUnderCoverPeriod == this.sowingUnderCoverPeriod &&
          other.sowingOpenGroundPeriod == this.sowingOpenGroundPeriod &&
          other.transplantingPeriod == this.transplantingPeriod &&
          other.harvestPeriod == this.harvestPeriod &&
          other.sowingRecommendation == this.sowingRecommendation &&
          other.cultivationGreenhouse == this.cultivationGreenhouse &&
          other.plantingAdvice == this.plantingAdvice &&
          other.careAdvice == this.careAdvice &&
          other.redFlags == this.redFlags &&
          other.mainDestroyers == this.mainDestroyers &&
          other.sowingCalendar == this.sowingCalendar &&
          other.plantingCalendar == this.plantingCalendar &&
          other.harvestCalendar == this.harvestCalendar &&
          other.isUserModified == this.isUserModified &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PlantsCompanion extends UpdateCompanion<Plant> {
  final Value<int> id;
  final Value<String> commonName;
  final Value<String?> latinName;
  final Value<String?> categoryCode;
  final Value<String?> categoryLabel;
  final Value<int?> spacingBetweenPlants;
  final Value<int?> spacingBetweenRows;
  final Value<int?> plantingDepthCm;
  final Value<String?> sunExposure;
  final Value<String?> soilMoisturePreference;
  final Value<String?> soilTreatmentAdvice;
  final Value<String?> soilType;
  final Value<String?> growingZone;
  final Value<String?> watering;
  final Value<int?> plantingMinTempC;
  final Value<String?> plantingWeatherConditions;
  final Value<String?> sowingUnderCoverPeriod;
  final Value<String?> sowingOpenGroundPeriod;
  final Value<String?> transplantingPeriod;
  final Value<String?> harvestPeriod;
  final Value<String?> sowingRecommendation;
  final Value<String?> cultivationGreenhouse;
  final Value<String?> plantingAdvice;
  final Value<String?> careAdvice;
  final Value<String?> redFlags;
  final Value<String?> mainDestroyers;
  final Value<String?> sowingCalendar;
  final Value<String?> plantingCalendar;
  final Value<String?> harvestCalendar;
  final Value<bool> isUserModified;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PlantsCompanion({
    this.id = const Value.absent(),
    this.commonName = const Value.absent(),
    this.latinName = const Value.absent(),
    this.categoryCode = const Value.absent(),
    this.categoryLabel = const Value.absent(),
    this.spacingBetweenPlants = const Value.absent(),
    this.spacingBetweenRows = const Value.absent(),
    this.plantingDepthCm = const Value.absent(),
    this.sunExposure = const Value.absent(),
    this.soilMoisturePreference = const Value.absent(),
    this.soilTreatmentAdvice = const Value.absent(),
    this.soilType = const Value.absent(),
    this.growingZone = const Value.absent(),
    this.watering = const Value.absent(),
    this.plantingMinTempC = const Value.absent(),
    this.plantingWeatherConditions = const Value.absent(),
    this.sowingUnderCoverPeriod = const Value.absent(),
    this.sowingOpenGroundPeriod = const Value.absent(),
    this.transplantingPeriod = const Value.absent(),
    this.harvestPeriod = const Value.absent(),
    this.sowingRecommendation = const Value.absent(),
    this.cultivationGreenhouse = const Value.absent(),
    this.plantingAdvice = const Value.absent(),
    this.careAdvice = const Value.absent(),
    this.redFlags = const Value.absent(),
    this.mainDestroyers = const Value.absent(),
    this.sowingCalendar = const Value.absent(),
    this.plantingCalendar = const Value.absent(),
    this.harvestCalendar = const Value.absent(),
    this.isUserModified = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PlantsCompanion.insert({
    this.id = const Value.absent(),
    required String commonName,
    this.latinName = const Value.absent(),
    this.categoryCode = const Value.absent(),
    this.categoryLabel = const Value.absent(),
    this.spacingBetweenPlants = const Value.absent(),
    this.spacingBetweenRows = const Value.absent(),
    this.plantingDepthCm = const Value.absent(),
    this.sunExposure = const Value.absent(),
    this.soilMoisturePreference = const Value.absent(),
    this.soilTreatmentAdvice = const Value.absent(),
    this.soilType = const Value.absent(),
    this.growingZone = const Value.absent(),
    this.watering = const Value.absent(),
    this.plantingMinTempC = const Value.absent(),
    this.plantingWeatherConditions = const Value.absent(),
    this.sowingUnderCoverPeriod = const Value.absent(),
    this.sowingOpenGroundPeriod = const Value.absent(),
    this.transplantingPeriod = const Value.absent(),
    this.harvestPeriod = const Value.absent(),
    this.sowingRecommendation = const Value.absent(),
    this.cultivationGreenhouse = const Value.absent(),
    this.plantingAdvice = const Value.absent(),
    this.careAdvice = const Value.absent(),
    this.redFlags = const Value.absent(),
    this.mainDestroyers = const Value.absent(),
    this.sowingCalendar = const Value.absent(),
    this.plantingCalendar = const Value.absent(),
    this.harvestCalendar = const Value.absent(),
    this.isUserModified = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : commonName = Value(commonName);
  static Insertable<Plant> custom({
    Expression<int>? id,
    Expression<String>? commonName,
    Expression<String>? latinName,
    Expression<String>? categoryCode,
    Expression<String>? categoryLabel,
    Expression<int>? spacingBetweenPlants,
    Expression<int>? spacingBetweenRows,
    Expression<int>? plantingDepthCm,
    Expression<String>? sunExposure,
    Expression<String>? soilMoisturePreference,
    Expression<String>? soilTreatmentAdvice,
    Expression<String>? soilType,
    Expression<String>? growingZone,
    Expression<String>? watering,
    Expression<int>? plantingMinTempC,
    Expression<String>? plantingWeatherConditions,
    Expression<String>? sowingUnderCoverPeriod,
    Expression<String>? sowingOpenGroundPeriod,
    Expression<String>? transplantingPeriod,
    Expression<String>? harvestPeriod,
    Expression<String>? sowingRecommendation,
    Expression<String>? cultivationGreenhouse,
    Expression<String>? plantingAdvice,
    Expression<String>? careAdvice,
    Expression<String>? redFlags,
    Expression<String>? mainDestroyers,
    Expression<String>? sowingCalendar,
    Expression<String>? plantingCalendar,
    Expression<String>? harvestCalendar,
    Expression<bool>? isUserModified,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (commonName != null) 'common_name': commonName,
      if (latinName != null) 'latin_name': latinName,
      if (categoryCode != null) 'category_code': categoryCode,
      if (categoryLabel != null) 'category_label': categoryLabel,
      if (spacingBetweenPlants != null)
        'spacing_between_plants': spacingBetweenPlants,
      if (spacingBetweenRows != null)
        'spacing_between_rows': spacingBetweenRows,
      if (plantingDepthCm != null) 'planting_depth_cm': plantingDepthCm,
      if (sunExposure != null) 'sun_exposure': sunExposure,
      if (soilMoisturePreference != null)
        'soil_moisture_preference': soilMoisturePreference,
      if (soilTreatmentAdvice != null)
        'soil_treatment_advice': soilTreatmentAdvice,
      if (soilType != null) 'soil_type': soilType,
      if (growingZone != null) 'growing_zone': growingZone,
      if (watering != null) 'watering': watering,
      if (plantingMinTempC != null) 'planting_min_temp_c': plantingMinTempC,
      if (plantingWeatherConditions != null)
        'planting_weather_conditions': plantingWeatherConditions,
      if (sowingUnderCoverPeriod != null)
        'sowing_under_cover_period': sowingUnderCoverPeriod,
      if (sowingOpenGroundPeriod != null)
        'sowing_open_ground_period': sowingOpenGroundPeriod,
      if (transplantingPeriod != null)
        'transplanting_period': transplantingPeriod,
      if (harvestPeriod != null) 'harvest_period': harvestPeriod,
      if (sowingRecommendation != null)
        'sowing_recommendation': sowingRecommendation,
      if (cultivationGreenhouse != null)
        'cultivation_greenhouse': cultivationGreenhouse,
      if (plantingAdvice != null) 'planting_advice': plantingAdvice,
      if (careAdvice != null) 'care_advice': careAdvice,
      if (redFlags != null) 'red_flags': redFlags,
      if (mainDestroyers != null) 'main_destroyers': mainDestroyers,
      if (sowingCalendar != null) 'sowing_calendar': sowingCalendar,
      if (plantingCalendar != null) 'planting_calendar': plantingCalendar,
      if (harvestCalendar != null) 'harvest_calendar': harvestCalendar,
      if (isUserModified != null) 'is_user_modified': isUserModified,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PlantsCompanion copyWith({
    Value<int>? id,
    Value<String>? commonName,
    Value<String?>? latinName,
    Value<String?>? categoryCode,
    Value<String?>? categoryLabel,
    Value<int?>? spacingBetweenPlants,
    Value<int?>? spacingBetweenRows,
    Value<int?>? plantingDepthCm,
    Value<String?>? sunExposure,
    Value<String?>? soilMoisturePreference,
    Value<String?>? soilTreatmentAdvice,
    Value<String?>? soilType,
    Value<String?>? growingZone,
    Value<String?>? watering,
    Value<int?>? plantingMinTempC,
    Value<String?>? plantingWeatherConditions,
    Value<String?>? sowingUnderCoverPeriod,
    Value<String?>? sowingOpenGroundPeriod,
    Value<String?>? transplantingPeriod,
    Value<String?>? harvestPeriod,
    Value<String?>? sowingRecommendation,
    Value<String?>? cultivationGreenhouse,
    Value<String?>? plantingAdvice,
    Value<String?>? careAdvice,
    Value<String?>? redFlags,
    Value<String?>? mainDestroyers,
    Value<String?>? sowingCalendar,
    Value<String?>? plantingCalendar,
    Value<String?>? harvestCalendar,
    Value<bool>? isUserModified,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PlantsCompanion(
      id: id ?? this.id,
      commonName: commonName ?? this.commonName,
      latinName: latinName ?? this.latinName,
      categoryCode: categoryCode ?? this.categoryCode,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      spacingBetweenPlants: spacingBetweenPlants ?? this.spacingBetweenPlants,
      spacingBetweenRows: spacingBetweenRows ?? this.spacingBetweenRows,
      plantingDepthCm: plantingDepthCm ?? this.plantingDepthCm,
      sunExposure: sunExposure ?? this.sunExposure,
      soilMoisturePreference:
          soilMoisturePreference ?? this.soilMoisturePreference,
      soilTreatmentAdvice: soilTreatmentAdvice ?? this.soilTreatmentAdvice,
      soilType: soilType ?? this.soilType,
      growingZone: growingZone ?? this.growingZone,
      watering: watering ?? this.watering,
      plantingMinTempC: plantingMinTempC ?? this.plantingMinTempC,
      plantingWeatherConditions:
          plantingWeatherConditions ?? this.plantingWeatherConditions,
      sowingUnderCoverPeriod:
          sowingUnderCoverPeriod ?? this.sowingUnderCoverPeriod,
      sowingOpenGroundPeriod:
          sowingOpenGroundPeriod ?? this.sowingOpenGroundPeriod,
      transplantingPeriod: transplantingPeriod ?? this.transplantingPeriod,
      harvestPeriod: harvestPeriod ?? this.harvestPeriod,
      sowingRecommendation: sowingRecommendation ?? this.sowingRecommendation,
      cultivationGreenhouse:
          cultivationGreenhouse ?? this.cultivationGreenhouse,
      plantingAdvice: plantingAdvice ?? this.plantingAdvice,
      careAdvice: careAdvice ?? this.careAdvice,
      redFlags: redFlags ?? this.redFlags,
      mainDestroyers: mainDestroyers ?? this.mainDestroyers,
      sowingCalendar: sowingCalendar ?? this.sowingCalendar,
      plantingCalendar: plantingCalendar ?? this.plantingCalendar,
      harvestCalendar: harvestCalendar ?? this.harvestCalendar,
      isUserModified: isUserModified ?? this.isUserModified,
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
    if (commonName.present) {
      map['common_name'] = Variable<String>(commonName.value);
    }
    if (latinName.present) {
      map['latin_name'] = Variable<String>(latinName.value);
    }
    if (categoryCode.present) {
      map['category_code'] = Variable<String>(categoryCode.value);
    }
    if (categoryLabel.present) {
      map['category_label'] = Variable<String>(categoryLabel.value);
    }
    if (spacingBetweenPlants.present) {
      map['spacing_between_plants'] = Variable<int>(spacingBetweenPlants.value);
    }
    if (spacingBetweenRows.present) {
      map['spacing_between_rows'] = Variable<int>(spacingBetweenRows.value);
    }
    if (plantingDepthCm.present) {
      map['planting_depth_cm'] = Variable<int>(plantingDepthCm.value);
    }
    if (sunExposure.present) {
      map['sun_exposure'] = Variable<String>(sunExposure.value);
    }
    if (soilMoisturePreference.present) {
      map['soil_moisture_preference'] = Variable<String>(
        soilMoisturePreference.value,
      );
    }
    if (soilTreatmentAdvice.present) {
      map['soil_treatment_advice'] = Variable<String>(
        soilTreatmentAdvice.value,
      );
    }
    if (soilType.present) {
      map['soil_type'] = Variable<String>(soilType.value);
    }
    if (growingZone.present) {
      map['growing_zone'] = Variable<String>(growingZone.value);
    }
    if (watering.present) {
      map['watering'] = Variable<String>(watering.value);
    }
    if (plantingMinTempC.present) {
      map['planting_min_temp_c'] = Variable<int>(plantingMinTempC.value);
    }
    if (plantingWeatherConditions.present) {
      map['planting_weather_conditions'] = Variable<String>(
        plantingWeatherConditions.value,
      );
    }
    if (sowingUnderCoverPeriod.present) {
      map['sowing_under_cover_period'] = Variable<String>(
        sowingUnderCoverPeriod.value,
      );
    }
    if (sowingOpenGroundPeriod.present) {
      map['sowing_open_ground_period'] = Variable<String>(
        sowingOpenGroundPeriod.value,
      );
    }
    if (transplantingPeriod.present) {
      map['transplanting_period'] = Variable<String>(transplantingPeriod.value);
    }
    if (harvestPeriod.present) {
      map['harvest_period'] = Variable<String>(harvestPeriod.value);
    }
    if (sowingRecommendation.present) {
      map['sowing_recommendation'] = Variable<String>(
        sowingRecommendation.value,
      );
    }
    if (cultivationGreenhouse.present) {
      map['cultivation_greenhouse'] = Variable<String>(
        cultivationGreenhouse.value,
      );
    }
    if (plantingAdvice.present) {
      map['planting_advice'] = Variable<String>(plantingAdvice.value);
    }
    if (careAdvice.present) {
      map['care_advice'] = Variable<String>(careAdvice.value);
    }
    if (redFlags.present) {
      map['red_flags'] = Variable<String>(redFlags.value);
    }
    if (mainDestroyers.present) {
      map['main_destroyers'] = Variable<String>(mainDestroyers.value);
    }
    if (sowingCalendar.present) {
      map['sowing_calendar'] = Variable<String>(sowingCalendar.value);
    }
    if (plantingCalendar.present) {
      map['planting_calendar'] = Variable<String>(plantingCalendar.value);
    }
    if (harvestCalendar.present) {
      map['harvest_calendar'] = Variable<String>(harvestCalendar.value);
    }
    if (isUserModified.present) {
      map['is_user_modified'] = Variable<bool>(isUserModified.value);
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
    return (StringBuffer('PlantsCompanion(')
          ..write('id: $id, ')
          ..write('commonName: $commonName, ')
          ..write('latinName: $latinName, ')
          ..write('categoryCode: $categoryCode, ')
          ..write('categoryLabel: $categoryLabel, ')
          ..write('spacingBetweenPlants: $spacingBetweenPlants, ')
          ..write('spacingBetweenRows: $spacingBetweenRows, ')
          ..write('plantingDepthCm: $plantingDepthCm, ')
          ..write('sunExposure: $sunExposure, ')
          ..write('soilMoisturePreference: $soilMoisturePreference, ')
          ..write('soilTreatmentAdvice: $soilTreatmentAdvice, ')
          ..write('soilType: $soilType, ')
          ..write('growingZone: $growingZone, ')
          ..write('watering: $watering, ')
          ..write('plantingMinTempC: $plantingMinTempC, ')
          ..write('plantingWeatherConditions: $plantingWeatherConditions, ')
          ..write('sowingUnderCoverPeriod: $sowingUnderCoverPeriod, ')
          ..write('sowingOpenGroundPeriod: $sowingOpenGroundPeriod, ')
          ..write('transplantingPeriod: $transplantingPeriod, ')
          ..write('harvestPeriod: $harvestPeriod, ')
          ..write('sowingRecommendation: $sowingRecommendation, ')
          ..write('cultivationGreenhouse: $cultivationGreenhouse, ')
          ..write('plantingAdvice: $plantingAdvice, ')
          ..write('careAdvice: $careAdvice, ')
          ..write('redFlags: $redFlags, ')
          ..write('mainDestroyers: $mainDestroyers, ')
          ..write('sowingCalendar: $sowingCalendar, ')
          ..write('plantingCalendar: $plantingCalendar, ')
          ..write('harvestCalendar: $harvestCalendar, ')
          ..write('isUserModified: $isUserModified, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PlantCompanionsTable extends PlantCompanions
    with TableInfo<$PlantCompanionsTable, PlantCompanion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlantCompanionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _plantIdMeta = const VerificationMeta(
    'plantId',
  );
  @override
  late final GeneratedColumn<int> plantId = GeneratedColumn<int>(
    'plant_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plants (id)',
    ),
  );
  static const VerificationMeta _companionIdMeta = const VerificationMeta(
    'companionId',
  );
  @override
  late final GeneratedColumn<int> companionId = GeneratedColumn<int>(
    'companion_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plants (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [plantId, companionId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plant_companions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlantCompanion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('plant_id')) {
      context.handle(
        _plantIdMeta,
        plantId.isAcceptableOrUnknown(data['plant_id']!, _plantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_plantIdMeta);
    }
    if (data.containsKey('companion_id')) {
      context.handle(
        _companionIdMeta,
        companionId.isAcceptableOrUnknown(
          data['companion_id']!,
          _companionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_companionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {plantId, companionId};
  @override
  PlantCompanion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlantCompanion(
      plantId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plant_id'],
      )!,
      companionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}companion_id'],
      )!,
    );
  }

  @override
  $PlantCompanionsTable createAlias(String alias) {
    return $PlantCompanionsTable(attachedDatabase, alias);
  }
}

class PlantCompanion extends DataClass implements Insertable<PlantCompanion> {
  final int plantId;
  final int companionId;
  const PlantCompanion({required this.plantId, required this.companionId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['plant_id'] = Variable<int>(plantId);
    map['companion_id'] = Variable<int>(companionId);
    return map;
  }

  PlantCompanionsCompanion toCompanion(bool nullToAbsent) {
    return PlantCompanionsCompanion(
      plantId: Value(plantId),
      companionId: Value(companionId),
    );
  }

  factory PlantCompanion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlantCompanion(
      plantId: serializer.fromJson<int>(json['plantId']),
      companionId: serializer.fromJson<int>(json['companionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'plantId': serializer.toJson<int>(plantId),
      'companionId': serializer.toJson<int>(companionId),
    };
  }

  PlantCompanion copyWith({int? plantId, int? companionId}) => PlantCompanion(
    plantId: plantId ?? this.plantId,
    companionId: companionId ?? this.companionId,
  );
  PlantCompanion copyWithCompanion(PlantCompanionsCompanion data) {
    return PlantCompanion(
      plantId: data.plantId.present ? data.plantId.value : this.plantId,
      companionId: data.companionId.present
          ? data.companionId.value
          : this.companionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlantCompanion(')
          ..write('plantId: $plantId, ')
          ..write('companionId: $companionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(plantId, companionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlantCompanion &&
          other.plantId == this.plantId &&
          other.companionId == this.companionId);
}

class PlantCompanionsCompanion extends UpdateCompanion<PlantCompanion> {
  final Value<int> plantId;
  final Value<int> companionId;
  final Value<int> rowid;
  const PlantCompanionsCompanion({
    this.plantId = const Value.absent(),
    this.companionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlantCompanionsCompanion.insert({
    required int plantId,
    required int companionId,
    this.rowid = const Value.absent(),
  }) : plantId = Value(plantId),
       companionId = Value(companionId);
  static Insertable<PlantCompanion> custom({
    Expression<int>? plantId,
    Expression<int>? companionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (plantId != null) 'plant_id': plantId,
      if (companionId != null) 'companion_id': companionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlantCompanionsCompanion copyWith({
    Value<int>? plantId,
    Value<int>? companionId,
    Value<int>? rowid,
  }) {
    return PlantCompanionsCompanion(
      plantId: plantId ?? this.plantId,
      companionId: companionId ?? this.companionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (plantId.present) {
      map['plant_id'] = Variable<int>(plantId.value);
    }
    if (companionId.present) {
      map['companion_id'] = Variable<int>(companionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlantCompanionsCompanion(')
          ..write('plantId: $plantId, ')
          ..write('companionId: $companionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlantAntagonistsTable extends PlantAntagonists
    with TableInfo<$PlantAntagonistsTable, PlantAntagonist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlantAntagonistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _plantIdMeta = const VerificationMeta(
    'plantId',
  );
  @override
  late final GeneratedColumn<int> plantId = GeneratedColumn<int>(
    'plant_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plants (id)',
    ),
  );
  static const VerificationMeta _antagonistIdMeta = const VerificationMeta(
    'antagonistId',
  );
  @override
  late final GeneratedColumn<int> antagonistId = GeneratedColumn<int>(
    'antagonist_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plants (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [plantId, antagonistId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plant_antagonists';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlantAntagonist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('plant_id')) {
      context.handle(
        _plantIdMeta,
        plantId.isAcceptableOrUnknown(data['plant_id']!, _plantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_plantIdMeta);
    }
    if (data.containsKey('antagonist_id')) {
      context.handle(
        _antagonistIdMeta,
        antagonistId.isAcceptableOrUnknown(
          data['antagonist_id']!,
          _antagonistIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_antagonistIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {plantId, antagonistId};
  @override
  PlantAntagonist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlantAntagonist(
      plantId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plant_id'],
      )!,
      antagonistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}antagonist_id'],
      )!,
    );
  }

  @override
  $PlantAntagonistsTable createAlias(String alias) {
    return $PlantAntagonistsTable(attachedDatabase, alias);
  }
}

class PlantAntagonist extends DataClass implements Insertable<PlantAntagonist> {
  final int plantId;
  final int antagonistId;
  const PlantAntagonist({required this.plantId, required this.antagonistId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['plant_id'] = Variable<int>(plantId);
    map['antagonist_id'] = Variable<int>(antagonistId);
    return map;
  }

  PlantAntagonistsCompanion toCompanion(bool nullToAbsent) {
    return PlantAntagonistsCompanion(
      plantId: Value(plantId),
      antagonistId: Value(antagonistId),
    );
  }

  factory PlantAntagonist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlantAntagonist(
      plantId: serializer.fromJson<int>(json['plantId']),
      antagonistId: serializer.fromJson<int>(json['antagonistId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'plantId': serializer.toJson<int>(plantId),
      'antagonistId': serializer.toJson<int>(antagonistId),
    };
  }

  PlantAntagonist copyWith({int? plantId, int? antagonistId}) =>
      PlantAntagonist(
        plantId: plantId ?? this.plantId,
        antagonistId: antagonistId ?? this.antagonistId,
      );
  PlantAntagonist copyWithCompanion(PlantAntagonistsCompanion data) {
    return PlantAntagonist(
      plantId: data.plantId.present ? data.plantId.value : this.plantId,
      antagonistId: data.antagonistId.present
          ? data.antagonistId.value
          : this.antagonistId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlantAntagonist(')
          ..write('plantId: $plantId, ')
          ..write('antagonistId: $antagonistId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(plantId, antagonistId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlantAntagonist &&
          other.plantId == this.plantId &&
          other.antagonistId == this.antagonistId);
}

class PlantAntagonistsCompanion extends UpdateCompanion<PlantAntagonist> {
  final Value<int> plantId;
  final Value<int> antagonistId;
  final Value<int> rowid;
  const PlantAntagonistsCompanion({
    this.plantId = const Value.absent(),
    this.antagonistId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlantAntagonistsCompanion.insert({
    required int plantId,
    required int antagonistId,
    this.rowid = const Value.absent(),
  }) : plantId = Value(plantId),
       antagonistId = Value(antagonistId);
  static Insertable<PlantAntagonist> custom({
    Expression<int>? plantId,
    Expression<int>? antagonistId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (plantId != null) 'plant_id': plantId,
      if (antagonistId != null) 'antagonist_id': antagonistId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlantAntagonistsCompanion copyWith({
    Value<int>? plantId,
    Value<int>? antagonistId,
    Value<int>? rowid,
  }) {
    return PlantAntagonistsCompanion(
      plantId: plantId ?? this.plantId,
      antagonistId: antagonistId ?? this.antagonistId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (plantId.present) {
      map['plant_id'] = Variable<int>(plantId.value);
    }
    if (antagonistId.present) {
      map['antagonist_id'] = Variable<int>(antagonistId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlantAntagonistsCompanion(')
          ..write('plantId: $plantId, ')
          ..write('antagonistId: $antagonistId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GardensTable extends Gardens with TableInfo<$GardensTable, Garden> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GardensTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _widthCellsMeta = const VerificationMeta(
    'widthCells',
  );
  @override
  late final GeneratedColumn<int> widthCells = GeneratedColumn<int>(
    'width_cells',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  static const VerificationMeta _heightCellsMeta = const VerificationMeta(
    'heightCells',
  );
  @override
  late final GeneratedColumn<int> heightCells = GeneratedColumn<int>(
    'height_cells',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  static const VerificationMeta _cellSizeCmMeta = const VerificationMeta(
    'cellSizeCm',
  );
  @override
  late final GeneratedColumn<int> cellSizeCm = GeneratedColumn<int>(
    'cell_size_cm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    widthCells,
    heightCells,
    cellSizeCm,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gardens';
  @override
  VerificationContext validateIntegrity(
    Insertable<Garden> instance, {
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
    if (data.containsKey('width_cells')) {
      context.handle(
        _widthCellsMeta,
        widthCells.isAcceptableOrUnknown(data['width_cells']!, _widthCellsMeta),
      );
    }
    if (data.containsKey('height_cells')) {
      context.handle(
        _heightCellsMeta,
        heightCells.isAcceptableOrUnknown(
          data['height_cells']!,
          _heightCellsMeta,
        ),
      );
    }
    if (data.containsKey('cell_size_cm')) {
      context.handle(
        _cellSizeCmMeta,
        cellSizeCm.isAcceptableOrUnknown(
          data['cell_size_cm']!,
          _cellSizeCmMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Garden map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Garden(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      widthCells: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width_cells'],
      )!,
      heightCells: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height_cells'],
      )!,
      cellSizeCm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cell_size_cm'],
      )!,
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
  $GardensTable createAlias(String alias) {
    return $GardensTable(attachedDatabase, alias);
  }
}

class Garden extends DataClass implements Insertable<Garden> {
  final int id;
  final String name;
  final int widthCells;
  final int heightCells;
  final int cellSizeCm;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Garden({
    required this.id,
    required this.name,
    required this.widthCells,
    required this.heightCells,
    required this.cellSizeCm,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['width_cells'] = Variable<int>(widthCells);
    map['height_cells'] = Variable<int>(heightCells);
    map['cell_size_cm'] = Variable<int>(cellSizeCm);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GardensCompanion toCompanion(bool nullToAbsent) {
    return GardensCompanion(
      id: Value(id),
      name: Value(name),
      widthCells: Value(widthCells),
      heightCells: Value(heightCells),
      cellSizeCm: Value(cellSizeCm),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Garden.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Garden(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      widthCells: serializer.fromJson<int>(json['widthCells']),
      heightCells: serializer.fromJson<int>(json['heightCells']),
      cellSizeCm: serializer.fromJson<int>(json['cellSizeCm']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'widthCells': serializer.toJson<int>(widthCells),
      'heightCells': serializer.toJson<int>(heightCells),
      'cellSizeCm': serializer.toJson<int>(cellSizeCm),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Garden copyWith({
    int? id,
    String? name,
    int? widthCells,
    int? heightCells,
    int? cellSizeCm,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Garden(
    id: id ?? this.id,
    name: name ?? this.name,
    widthCells: widthCells ?? this.widthCells,
    heightCells: heightCells ?? this.heightCells,
    cellSizeCm: cellSizeCm ?? this.cellSizeCm,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Garden copyWithCompanion(GardensCompanion data) {
    return Garden(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      widthCells: data.widthCells.present
          ? data.widthCells.value
          : this.widthCells,
      heightCells: data.heightCells.present
          ? data.heightCells.value
          : this.heightCells,
      cellSizeCm: data.cellSizeCm.present
          ? data.cellSizeCm.value
          : this.cellSizeCm,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Garden(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('widthCells: $widthCells, ')
          ..write('heightCells: $heightCells, ')
          ..write('cellSizeCm: $cellSizeCm, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    widthCells,
    heightCells,
    cellSizeCm,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Garden &&
          other.id == this.id &&
          other.name == this.name &&
          other.widthCells == this.widthCells &&
          other.heightCells == this.heightCells &&
          other.cellSizeCm == this.cellSizeCm &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GardensCompanion extends UpdateCompanion<Garden> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> widthCells;
  final Value<int> heightCells;
  final Value<int> cellSizeCm;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const GardensCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.widthCells = const Value.absent(),
    this.heightCells = const Value.absent(),
    this.cellSizeCm = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  GardensCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.widthCells = const Value.absent(),
    this.heightCells = const Value.absent(),
    this.cellSizeCm = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Garden> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? widthCells,
    Expression<int>? heightCells,
    Expression<int>? cellSizeCm,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (widthCells != null) 'width_cells': widthCells,
      if (heightCells != null) 'height_cells': heightCells,
      if (cellSizeCm != null) 'cell_size_cm': cellSizeCm,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  GardensCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? widthCells,
    Value<int>? heightCells,
    Value<int>? cellSizeCm,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return GardensCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      widthCells: widthCells ?? this.widthCells,
      heightCells: heightCells ?? this.heightCells,
      cellSizeCm: cellSizeCm ?? this.cellSizeCm,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (widthCells.present) {
      map['width_cells'] = Variable<int>(widthCells.value);
    }
    if (heightCells.present) {
      map['height_cells'] = Variable<int>(heightCells.value);
    }
    if (cellSizeCm.present) {
      map['cell_size_cm'] = Variable<int>(cellSizeCm.value);
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
    return (StringBuffer('GardensCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('widthCells: $widthCells, ')
          ..write('heightCells: $heightCells, ')
          ..write('cellSizeCm: $cellSizeCm, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $GardenPlantsTable extends GardenPlants
    with TableInfo<$GardenPlantsTable, GardenPlant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GardenPlantsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _gardenIdMeta = const VerificationMeta(
    'gardenId',
  );
  @override
  late final GeneratedColumn<int> gardenId = GeneratedColumn<int>(
    'garden_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES gardens (id)',
    ),
  );
  static const VerificationMeta _plantIdMeta = const VerificationMeta(
    'plantId',
  );
  @override
  late final GeneratedColumn<int> plantId = GeneratedColumn<int>(
    'plant_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plants (id)',
    ),
  );
  static const VerificationMeta _gridXMeta = const VerificationMeta('gridX');
  @override
  late final GeneratedColumn<int> gridX = GeneratedColumn<int>(
    'grid_x',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gridYMeta = const VerificationMeta('gridY');
  @override
  late final GeneratedColumn<int> gridY = GeneratedColumn<int>(
    'grid_y',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthCellsMeta = const VerificationMeta(
    'widthCells',
  );
  @override
  late final GeneratedColumn<int> widthCells = GeneratedColumn<int>(
    'width_cells',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _heightCellsMeta = const VerificationMeta(
    'heightCells',
  );
  @override
  late final GeneratedColumn<int> heightCells = GeneratedColumn<int>(
    'height_cells',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _plantedAtMeta = const VerificationMeta(
    'plantedAt',
  );
  @override
  late final GeneratedColumn<DateTime> plantedAt = GeneratedColumn<DateTime>(
    'planted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gardenId,
    plantId,
    gridX,
    gridY,
    widthCells,
    heightCells,
    plantedAt,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'garden_plants';
  @override
  VerificationContext validateIntegrity(
    Insertable<GardenPlant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('garden_id')) {
      context.handle(
        _gardenIdMeta,
        gardenId.isAcceptableOrUnknown(data['garden_id']!, _gardenIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gardenIdMeta);
    }
    if (data.containsKey('plant_id')) {
      context.handle(
        _plantIdMeta,
        plantId.isAcceptableOrUnknown(data['plant_id']!, _plantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_plantIdMeta);
    }
    if (data.containsKey('grid_x')) {
      context.handle(
        _gridXMeta,
        gridX.isAcceptableOrUnknown(data['grid_x']!, _gridXMeta),
      );
    } else if (isInserting) {
      context.missing(_gridXMeta);
    }
    if (data.containsKey('grid_y')) {
      context.handle(
        _gridYMeta,
        gridY.isAcceptableOrUnknown(data['grid_y']!, _gridYMeta),
      );
    } else if (isInserting) {
      context.missing(_gridYMeta);
    }
    if (data.containsKey('width_cells')) {
      context.handle(
        _widthCellsMeta,
        widthCells.isAcceptableOrUnknown(data['width_cells']!, _widthCellsMeta),
      );
    }
    if (data.containsKey('height_cells')) {
      context.handle(
        _heightCellsMeta,
        heightCells.isAcceptableOrUnknown(
          data['height_cells']!,
          _heightCellsMeta,
        ),
      );
    }
    if (data.containsKey('planted_at')) {
      context.handle(
        _plantedAtMeta,
        plantedAt.isAcceptableOrUnknown(data['planted_at']!, _plantedAtMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
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
  GardenPlant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GardenPlant(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gardenId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}garden_id'],
      )!,
      plantId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plant_id'],
      )!,
      gridX: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grid_x'],
      )!,
      gridY: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grid_y'],
      )!,
      widthCells: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width_cells'],
      )!,
      heightCells: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height_cells'],
      )!,
      plantedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}planted_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GardenPlantsTable createAlias(String alias) {
    return $GardenPlantsTable(attachedDatabase, alias);
  }
}

class GardenPlant extends DataClass implements Insertable<GardenPlant> {
  final int id;
  final int gardenId;
  final int plantId;
  final int gridX;
  final int gridY;
  final int widthCells;
  final int heightCells;
  final DateTime? plantedAt;
  final String? notes;
  final DateTime createdAt;
  const GardenPlant({
    required this.id,
    required this.gardenId,
    required this.plantId,
    required this.gridX,
    required this.gridY,
    required this.widthCells,
    required this.heightCells,
    this.plantedAt,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['garden_id'] = Variable<int>(gardenId);
    map['plant_id'] = Variable<int>(plantId);
    map['grid_x'] = Variable<int>(gridX);
    map['grid_y'] = Variable<int>(gridY);
    map['width_cells'] = Variable<int>(widthCells);
    map['height_cells'] = Variable<int>(heightCells);
    if (!nullToAbsent || plantedAt != null) {
      map['planted_at'] = Variable<DateTime>(plantedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GardenPlantsCompanion toCompanion(bool nullToAbsent) {
    return GardenPlantsCompanion(
      id: Value(id),
      gardenId: Value(gardenId),
      plantId: Value(plantId),
      gridX: Value(gridX),
      gridY: Value(gridY),
      widthCells: Value(widthCells),
      heightCells: Value(heightCells),
      plantedAt: plantedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(plantedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory GardenPlant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GardenPlant(
      id: serializer.fromJson<int>(json['id']),
      gardenId: serializer.fromJson<int>(json['gardenId']),
      plantId: serializer.fromJson<int>(json['plantId']),
      gridX: serializer.fromJson<int>(json['gridX']),
      gridY: serializer.fromJson<int>(json['gridY']),
      widthCells: serializer.fromJson<int>(json['widthCells']),
      heightCells: serializer.fromJson<int>(json['heightCells']),
      plantedAt: serializer.fromJson<DateTime?>(json['plantedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gardenId': serializer.toJson<int>(gardenId),
      'plantId': serializer.toJson<int>(plantId),
      'gridX': serializer.toJson<int>(gridX),
      'gridY': serializer.toJson<int>(gridY),
      'widthCells': serializer.toJson<int>(widthCells),
      'heightCells': serializer.toJson<int>(heightCells),
      'plantedAt': serializer.toJson<DateTime?>(plantedAt),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GardenPlant copyWith({
    int? id,
    int? gardenId,
    int? plantId,
    int? gridX,
    int? gridY,
    int? widthCells,
    int? heightCells,
    Value<DateTime?> plantedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => GardenPlant(
    id: id ?? this.id,
    gardenId: gardenId ?? this.gardenId,
    plantId: plantId ?? this.plantId,
    gridX: gridX ?? this.gridX,
    gridY: gridY ?? this.gridY,
    widthCells: widthCells ?? this.widthCells,
    heightCells: heightCells ?? this.heightCells,
    plantedAt: plantedAt.present ? plantedAt.value : this.plantedAt,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  GardenPlant copyWithCompanion(GardenPlantsCompanion data) {
    return GardenPlant(
      id: data.id.present ? data.id.value : this.id,
      gardenId: data.gardenId.present ? data.gardenId.value : this.gardenId,
      plantId: data.plantId.present ? data.plantId.value : this.plantId,
      gridX: data.gridX.present ? data.gridX.value : this.gridX,
      gridY: data.gridY.present ? data.gridY.value : this.gridY,
      widthCells: data.widthCells.present
          ? data.widthCells.value
          : this.widthCells,
      heightCells: data.heightCells.present
          ? data.heightCells.value
          : this.heightCells,
      plantedAt: data.plantedAt.present ? data.plantedAt.value : this.plantedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GardenPlant(')
          ..write('id: $id, ')
          ..write('gardenId: $gardenId, ')
          ..write('plantId: $plantId, ')
          ..write('gridX: $gridX, ')
          ..write('gridY: $gridY, ')
          ..write('widthCells: $widthCells, ')
          ..write('heightCells: $heightCells, ')
          ..write('plantedAt: $plantedAt, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    gardenId,
    plantId,
    gridX,
    gridY,
    widthCells,
    heightCells,
    plantedAt,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GardenPlant &&
          other.id == this.id &&
          other.gardenId == this.gardenId &&
          other.plantId == this.plantId &&
          other.gridX == this.gridX &&
          other.gridY == this.gridY &&
          other.widthCells == this.widthCells &&
          other.heightCells == this.heightCells &&
          other.plantedAt == this.plantedAt &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class GardenPlantsCompanion extends UpdateCompanion<GardenPlant> {
  final Value<int> id;
  final Value<int> gardenId;
  final Value<int> plantId;
  final Value<int> gridX;
  final Value<int> gridY;
  final Value<int> widthCells;
  final Value<int> heightCells;
  final Value<DateTime?> plantedAt;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const GardenPlantsCompanion({
    this.id = const Value.absent(),
    this.gardenId = const Value.absent(),
    this.plantId = const Value.absent(),
    this.gridX = const Value.absent(),
    this.gridY = const Value.absent(),
    this.widthCells = const Value.absent(),
    this.heightCells = const Value.absent(),
    this.plantedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  GardenPlantsCompanion.insert({
    this.id = const Value.absent(),
    required int gardenId,
    required int plantId,
    required int gridX,
    required int gridY,
    this.widthCells = const Value.absent(),
    this.heightCells = const Value.absent(),
    this.plantedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : gardenId = Value(gardenId),
       plantId = Value(plantId),
       gridX = Value(gridX),
       gridY = Value(gridY);
  static Insertable<GardenPlant> custom({
    Expression<int>? id,
    Expression<int>? gardenId,
    Expression<int>? plantId,
    Expression<int>? gridX,
    Expression<int>? gridY,
    Expression<int>? widthCells,
    Expression<int>? heightCells,
    Expression<DateTime>? plantedAt,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gardenId != null) 'garden_id': gardenId,
      if (plantId != null) 'plant_id': plantId,
      if (gridX != null) 'grid_x': gridX,
      if (gridY != null) 'grid_y': gridY,
      if (widthCells != null) 'width_cells': widthCells,
      if (heightCells != null) 'height_cells': heightCells,
      if (plantedAt != null) 'planted_at': plantedAt,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  GardenPlantsCompanion copyWith({
    Value<int>? id,
    Value<int>? gardenId,
    Value<int>? plantId,
    Value<int>? gridX,
    Value<int>? gridY,
    Value<int>? widthCells,
    Value<int>? heightCells,
    Value<DateTime?>? plantedAt,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
  }) {
    return GardenPlantsCompanion(
      id: id ?? this.id,
      gardenId: gardenId ?? this.gardenId,
      plantId: plantId ?? this.plantId,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      widthCells: widthCells ?? this.widthCells,
      heightCells: heightCells ?? this.heightCells,
      plantedAt: plantedAt ?? this.plantedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gardenId.present) {
      map['garden_id'] = Variable<int>(gardenId.value);
    }
    if (plantId.present) {
      map['plant_id'] = Variable<int>(plantId.value);
    }
    if (gridX.present) {
      map['grid_x'] = Variable<int>(gridX.value);
    }
    if (gridY.present) {
      map['grid_y'] = Variable<int>(gridY.value);
    }
    if (widthCells.present) {
      map['width_cells'] = Variable<int>(widthCells.value);
    }
    if (heightCells.present) {
      map['height_cells'] = Variable<int>(heightCells.value);
    }
    if (plantedAt.present) {
      map['planted_at'] = Variable<DateTime>(plantedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GardenPlantsCompanion(')
          ..write('id: $id, ')
          ..write('gardenId: $gardenId, ')
          ..write('plantId: $plantId, ')
          ..write('gridX: $gridX, ')
          ..write('gridY: $gridY, ')
          ..write('widthCells: $widthCells, ')
          ..write('heightCells: $heightCells, ')
          ..write('plantedAt: $plantedAt, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlantsTable plants = $PlantsTable(this);
  late final $PlantCompanionsTable plantCompanions = $PlantCompanionsTable(
    this,
  );
  late final $PlantAntagonistsTable plantAntagonists = $PlantAntagonistsTable(
    this,
  );
  late final $GardensTable gardens = $GardensTable(this);
  late final $GardenPlantsTable gardenPlants = $GardenPlantsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    plants,
    plantCompanions,
    plantAntagonists,
    gardens,
    gardenPlants,
  ];
}

typedef $$PlantsTableCreateCompanionBuilder =
    PlantsCompanion Function({
      Value<int> id,
      required String commonName,
      Value<String?> latinName,
      Value<String?> categoryCode,
      Value<String?> categoryLabel,
      Value<int?> spacingBetweenPlants,
      Value<int?> spacingBetweenRows,
      Value<int?> plantingDepthCm,
      Value<String?> sunExposure,
      Value<String?> soilMoisturePreference,
      Value<String?> soilTreatmentAdvice,
      Value<String?> soilType,
      Value<String?> growingZone,
      Value<String?> watering,
      Value<int?> plantingMinTempC,
      Value<String?> plantingWeatherConditions,
      Value<String?> sowingUnderCoverPeriod,
      Value<String?> sowingOpenGroundPeriod,
      Value<String?> transplantingPeriod,
      Value<String?> harvestPeriod,
      Value<String?> sowingRecommendation,
      Value<String?> cultivationGreenhouse,
      Value<String?> plantingAdvice,
      Value<String?> careAdvice,
      Value<String?> redFlags,
      Value<String?> mainDestroyers,
      Value<String?> sowingCalendar,
      Value<String?> plantingCalendar,
      Value<String?> harvestCalendar,
      Value<bool> isUserModified,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$PlantsTableUpdateCompanionBuilder =
    PlantsCompanion Function({
      Value<int> id,
      Value<String> commonName,
      Value<String?> latinName,
      Value<String?> categoryCode,
      Value<String?> categoryLabel,
      Value<int?> spacingBetweenPlants,
      Value<int?> spacingBetweenRows,
      Value<int?> plantingDepthCm,
      Value<String?> sunExposure,
      Value<String?> soilMoisturePreference,
      Value<String?> soilTreatmentAdvice,
      Value<String?> soilType,
      Value<String?> growingZone,
      Value<String?> watering,
      Value<int?> plantingMinTempC,
      Value<String?> plantingWeatherConditions,
      Value<String?> sowingUnderCoverPeriod,
      Value<String?> sowingOpenGroundPeriod,
      Value<String?> transplantingPeriod,
      Value<String?> harvestPeriod,
      Value<String?> sowingRecommendation,
      Value<String?> cultivationGreenhouse,
      Value<String?> plantingAdvice,
      Value<String?> careAdvice,
      Value<String?> redFlags,
      Value<String?> mainDestroyers,
      Value<String?> sowingCalendar,
      Value<String?> plantingCalendar,
      Value<String?> harvestCalendar,
      Value<bool> isUserModified,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$PlantsTableReferences
    extends BaseReferences<_$AppDatabase, $PlantsTable, Plant> {
  $$PlantsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GardenPlantsTable, List<GardenPlant>>
  _gardenPlantsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.gardenPlants,
    aliasName: $_aliasNameGenerator(db.plants.id, db.gardenPlants.plantId),
  );

  $$GardenPlantsTableProcessedTableManager get gardenPlantsRefs {
    final manager = $$GardenPlantsTableTableManager(
      $_db,
      $_db.gardenPlants,
    ).filter((f) => f.plantId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_gardenPlantsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlantsTableFilterComposer
    extends Composer<_$AppDatabase, $PlantsTable> {
  $$PlantsTableFilterComposer({
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

  ColumnFilters<String> get commonName => $composableBuilder(
    column: $table.commonName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get latinName => $composableBuilder(
    column: $table.latinName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryCode => $composableBuilder(
    column: $table.categoryCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryLabel => $composableBuilder(
    column: $table.categoryLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get spacingBetweenPlants => $composableBuilder(
    column: $table.spacingBetweenPlants,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get spacingBetweenRows => $composableBuilder(
    column: $table.spacingBetweenRows,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plantingDepthCm => $composableBuilder(
    column: $table.plantingDepthCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sunExposure => $composableBuilder(
    column: $table.sunExposure,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soilMoisturePreference => $composableBuilder(
    column: $table.soilMoisturePreference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soilTreatmentAdvice => $composableBuilder(
    column: $table.soilTreatmentAdvice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soilType => $composableBuilder(
    column: $table.soilType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get growingZone => $composableBuilder(
    column: $table.growingZone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get watering => $composableBuilder(
    column: $table.watering,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plantingMinTempC => $composableBuilder(
    column: $table.plantingMinTempC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plantingWeatherConditions => $composableBuilder(
    column: $table.plantingWeatherConditions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sowingUnderCoverPeriod => $composableBuilder(
    column: $table.sowingUnderCoverPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sowingOpenGroundPeriod => $composableBuilder(
    column: $table.sowingOpenGroundPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transplantingPeriod => $composableBuilder(
    column: $table.transplantingPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get harvestPeriod => $composableBuilder(
    column: $table.harvestPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sowingRecommendation => $composableBuilder(
    column: $table.sowingRecommendation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cultivationGreenhouse => $composableBuilder(
    column: $table.cultivationGreenhouse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plantingAdvice => $composableBuilder(
    column: $table.plantingAdvice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get careAdvice => $composableBuilder(
    column: $table.careAdvice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get redFlags => $composableBuilder(
    column: $table.redFlags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mainDestroyers => $composableBuilder(
    column: $table.mainDestroyers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sowingCalendar => $composableBuilder(
    column: $table.sowingCalendar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plantingCalendar => $composableBuilder(
    column: $table.plantingCalendar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get harvestCalendar => $composableBuilder(
    column: $table.harvestCalendar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUserModified => $composableBuilder(
    column: $table.isUserModified,
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

  Expression<bool> gardenPlantsRefs(
    Expression<bool> Function($$GardenPlantsTableFilterComposer f) f,
  ) {
    final $$GardenPlantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gardenPlants,
      getReferencedColumn: (t) => t.plantId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GardenPlantsTableFilterComposer(
            $db: $db,
            $table: $db.gardenPlants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlantsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlantsTable> {
  $$PlantsTableOrderingComposer({
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

  ColumnOrderings<String> get commonName => $composableBuilder(
    column: $table.commonName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get latinName => $composableBuilder(
    column: $table.latinName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryCode => $composableBuilder(
    column: $table.categoryCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryLabel => $composableBuilder(
    column: $table.categoryLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get spacingBetweenPlants => $composableBuilder(
    column: $table.spacingBetweenPlants,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get spacingBetweenRows => $composableBuilder(
    column: $table.spacingBetweenRows,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plantingDepthCm => $composableBuilder(
    column: $table.plantingDepthCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sunExposure => $composableBuilder(
    column: $table.sunExposure,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soilMoisturePreference => $composableBuilder(
    column: $table.soilMoisturePreference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soilTreatmentAdvice => $composableBuilder(
    column: $table.soilTreatmentAdvice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soilType => $composableBuilder(
    column: $table.soilType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get growingZone => $composableBuilder(
    column: $table.growingZone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get watering => $composableBuilder(
    column: $table.watering,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plantingMinTempC => $composableBuilder(
    column: $table.plantingMinTempC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plantingWeatherConditions => $composableBuilder(
    column: $table.plantingWeatherConditions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sowingUnderCoverPeriod => $composableBuilder(
    column: $table.sowingUnderCoverPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sowingOpenGroundPeriod => $composableBuilder(
    column: $table.sowingOpenGroundPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transplantingPeriod => $composableBuilder(
    column: $table.transplantingPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get harvestPeriod => $composableBuilder(
    column: $table.harvestPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sowingRecommendation => $composableBuilder(
    column: $table.sowingRecommendation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cultivationGreenhouse => $composableBuilder(
    column: $table.cultivationGreenhouse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plantingAdvice => $composableBuilder(
    column: $table.plantingAdvice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get careAdvice => $composableBuilder(
    column: $table.careAdvice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get redFlags => $composableBuilder(
    column: $table.redFlags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mainDestroyers => $composableBuilder(
    column: $table.mainDestroyers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sowingCalendar => $composableBuilder(
    column: $table.sowingCalendar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plantingCalendar => $composableBuilder(
    column: $table.plantingCalendar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get harvestCalendar => $composableBuilder(
    column: $table.harvestCalendar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUserModified => $composableBuilder(
    column: $table.isUserModified,
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

class $$PlantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlantsTable> {
  $$PlantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get commonName => $composableBuilder(
    column: $table.commonName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get latinName =>
      $composableBuilder(column: $table.latinName, builder: (column) => column);

  GeneratedColumn<String> get categoryCode => $composableBuilder(
    column: $table.categoryCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryLabel => $composableBuilder(
    column: $table.categoryLabel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get spacingBetweenPlants => $composableBuilder(
    column: $table.spacingBetweenPlants,
    builder: (column) => column,
  );

  GeneratedColumn<int> get spacingBetweenRows => $composableBuilder(
    column: $table.spacingBetweenRows,
    builder: (column) => column,
  );

  GeneratedColumn<int> get plantingDepthCm => $composableBuilder(
    column: $table.plantingDepthCm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sunExposure => $composableBuilder(
    column: $table.sunExposure,
    builder: (column) => column,
  );

  GeneratedColumn<String> get soilMoisturePreference => $composableBuilder(
    column: $table.soilMoisturePreference,
    builder: (column) => column,
  );

  GeneratedColumn<String> get soilTreatmentAdvice => $composableBuilder(
    column: $table.soilTreatmentAdvice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get soilType =>
      $composableBuilder(column: $table.soilType, builder: (column) => column);

  GeneratedColumn<String> get growingZone => $composableBuilder(
    column: $table.growingZone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get watering =>
      $composableBuilder(column: $table.watering, builder: (column) => column);

  GeneratedColumn<int> get plantingMinTempC => $composableBuilder(
    column: $table.plantingMinTempC,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plantingWeatherConditions => $composableBuilder(
    column: $table.plantingWeatherConditions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sowingUnderCoverPeriod => $composableBuilder(
    column: $table.sowingUnderCoverPeriod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sowingOpenGroundPeriod => $composableBuilder(
    column: $table.sowingOpenGroundPeriod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transplantingPeriod => $composableBuilder(
    column: $table.transplantingPeriod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get harvestPeriod => $composableBuilder(
    column: $table.harvestPeriod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sowingRecommendation => $composableBuilder(
    column: $table.sowingRecommendation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cultivationGreenhouse => $composableBuilder(
    column: $table.cultivationGreenhouse,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plantingAdvice => $composableBuilder(
    column: $table.plantingAdvice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get careAdvice => $composableBuilder(
    column: $table.careAdvice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get redFlags =>
      $composableBuilder(column: $table.redFlags, builder: (column) => column);

  GeneratedColumn<String> get mainDestroyers => $composableBuilder(
    column: $table.mainDestroyers,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sowingCalendar => $composableBuilder(
    column: $table.sowingCalendar,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plantingCalendar => $composableBuilder(
    column: $table.plantingCalendar,
    builder: (column) => column,
  );

  GeneratedColumn<String> get harvestCalendar => $composableBuilder(
    column: $table.harvestCalendar,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isUserModified => $composableBuilder(
    column: $table.isUserModified,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> gardenPlantsRefs<T extends Object>(
    Expression<T> Function($$GardenPlantsTableAnnotationComposer a) f,
  ) {
    final $$GardenPlantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gardenPlants,
      getReferencedColumn: (t) => t.plantId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GardenPlantsTableAnnotationComposer(
            $db: $db,
            $table: $db.gardenPlants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlantsTable,
          Plant,
          $$PlantsTableFilterComposer,
          $$PlantsTableOrderingComposer,
          $$PlantsTableAnnotationComposer,
          $$PlantsTableCreateCompanionBuilder,
          $$PlantsTableUpdateCompanionBuilder,
          (Plant, $$PlantsTableReferences),
          Plant,
          PrefetchHooks Function({bool gardenPlantsRefs})
        > {
  $$PlantsTableTableManager(_$AppDatabase db, $PlantsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> commonName = const Value.absent(),
                Value<String?> latinName = const Value.absent(),
                Value<String?> categoryCode = const Value.absent(),
                Value<String?> categoryLabel = const Value.absent(),
                Value<int?> spacingBetweenPlants = const Value.absent(),
                Value<int?> spacingBetweenRows = const Value.absent(),
                Value<int?> plantingDepthCm = const Value.absent(),
                Value<String?> sunExposure = const Value.absent(),
                Value<String?> soilMoisturePreference = const Value.absent(),
                Value<String?> soilTreatmentAdvice = const Value.absent(),
                Value<String?> soilType = const Value.absent(),
                Value<String?> growingZone = const Value.absent(),
                Value<String?> watering = const Value.absent(),
                Value<int?> plantingMinTempC = const Value.absent(),
                Value<String?> plantingWeatherConditions = const Value.absent(),
                Value<String?> sowingUnderCoverPeriod = const Value.absent(),
                Value<String?> sowingOpenGroundPeriod = const Value.absent(),
                Value<String?> transplantingPeriod = const Value.absent(),
                Value<String?> harvestPeriod = const Value.absent(),
                Value<String?> sowingRecommendation = const Value.absent(),
                Value<String?> cultivationGreenhouse = const Value.absent(),
                Value<String?> plantingAdvice = const Value.absent(),
                Value<String?> careAdvice = const Value.absent(),
                Value<String?> redFlags = const Value.absent(),
                Value<String?> mainDestroyers = const Value.absent(),
                Value<String?> sowingCalendar = const Value.absent(),
                Value<String?> plantingCalendar = const Value.absent(),
                Value<String?> harvestCalendar = const Value.absent(),
                Value<bool> isUserModified = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PlantsCompanion(
                id: id,
                commonName: commonName,
                latinName: latinName,
                categoryCode: categoryCode,
                categoryLabel: categoryLabel,
                spacingBetweenPlants: spacingBetweenPlants,
                spacingBetweenRows: spacingBetweenRows,
                plantingDepthCm: plantingDepthCm,
                sunExposure: sunExposure,
                soilMoisturePreference: soilMoisturePreference,
                soilTreatmentAdvice: soilTreatmentAdvice,
                soilType: soilType,
                growingZone: growingZone,
                watering: watering,
                plantingMinTempC: plantingMinTempC,
                plantingWeatherConditions: plantingWeatherConditions,
                sowingUnderCoverPeriod: sowingUnderCoverPeriod,
                sowingOpenGroundPeriod: sowingOpenGroundPeriod,
                transplantingPeriod: transplantingPeriod,
                harvestPeriod: harvestPeriod,
                sowingRecommendation: sowingRecommendation,
                cultivationGreenhouse: cultivationGreenhouse,
                plantingAdvice: plantingAdvice,
                careAdvice: careAdvice,
                redFlags: redFlags,
                mainDestroyers: mainDestroyers,
                sowingCalendar: sowingCalendar,
                plantingCalendar: plantingCalendar,
                harvestCalendar: harvestCalendar,
                isUserModified: isUserModified,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String commonName,
                Value<String?> latinName = const Value.absent(),
                Value<String?> categoryCode = const Value.absent(),
                Value<String?> categoryLabel = const Value.absent(),
                Value<int?> spacingBetweenPlants = const Value.absent(),
                Value<int?> spacingBetweenRows = const Value.absent(),
                Value<int?> plantingDepthCm = const Value.absent(),
                Value<String?> sunExposure = const Value.absent(),
                Value<String?> soilMoisturePreference = const Value.absent(),
                Value<String?> soilTreatmentAdvice = const Value.absent(),
                Value<String?> soilType = const Value.absent(),
                Value<String?> growingZone = const Value.absent(),
                Value<String?> watering = const Value.absent(),
                Value<int?> plantingMinTempC = const Value.absent(),
                Value<String?> plantingWeatherConditions = const Value.absent(),
                Value<String?> sowingUnderCoverPeriod = const Value.absent(),
                Value<String?> sowingOpenGroundPeriod = const Value.absent(),
                Value<String?> transplantingPeriod = const Value.absent(),
                Value<String?> harvestPeriod = const Value.absent(),
                Value<String?> sowingRecommendation = const Value.absent(),
                Value<String?> cultivationGreenhouse = const Value.absent(),
                Value<String?> plantingAdvice = const Value.absent(),
                Value<String?> careAdvice = const Value.absent(),
                Value<String?> redFlags = const Value.absent(),
                Value<String?> mainDestroyers = const Value.absent(),
                Value<String?> sowingCalendar = const Value.absent(),
                Value<String?> plantingCalendar = const Value.absent(),
                Value<String?> harvestCalendar = const Value.absent(),
                Value<bool> isUserModified = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PlantsCompanion.insert(
                id: id,
                commonName: commonName,
                latinName: latinName,
                categoryCode: categoryCode,
                categoryLabel: categoryLabel,
                spacingBetweenPlants: spacingBetweenPlants,
                spacingBetweenRows: spacingBetweenRows,
                plantingDepthCm: plantingDepthCm,
                sunExposure: sunExposure,
                soilMoisturePreference: soilMoisturePreference,
                soilTreatmentAdvice: soilTreatmentAdvice,
                soilType: soilType,
                growingZone: growingZone,
                watering: watering,
                plantingMinTempC: plantingMinTempC,
                plantingWeatherConditions: plantingWeatherConditions,
                sowingUnderCoverPeriod: sowingUnderCoverPeriod,
                sowingOpenGroundPeriod: sowingOpenGroundPeriod,
                transplantingPeriod: transplantingPeriod,
                harvestPeriod: harvestPeriod,
                sowingRecommendation: sowingRecommendation,
                cultivationGreenhouse: cultivationGreenhouse,
                plantingAdvice: plantingAdvice,
                careAdvice: careAdvice,
                redFlags: redFlags,
                mainDestroyers: mainDestroyers,
                sowingCalendar: sowingCalendar,
                plantingCalendar: plantingCalendar,
                harvestCalendar: harvestCalendar,
                isUserModified: isUserModified,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PlantsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({gardenPlantsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (gardenPlantsRefs) db.gardenPlants],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (gardenPlantsRefs)
                    await $_getPrefetchedData<Plant, $PlantsTable, GardenPlant>(
                      currentTable: table,
                      referencedTable: $$PlantsTableReferences
                          ._gardenPlantsRefsTable(db),
                      managerFromTypedResult: (p0) => $$PlantsTableReferences(
                        db,
                        table,
                        p0,
                      ).gardenPlantsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.plantId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PlantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlantsTable,
      Plant,
      $$PlantsTableFilterComposer,
      $$PlantsTableOrderingComposer,
      $$PlantsTableAnnotationComposer,
      $$PlantsTableCreateCompanionBuilder,
      $$PlantsTableUpdateCompanionBuilder,
      (Plant, $$PlantsTableReferences),
      Plant,
      PrefetchHooks Function({bool gardenPlantsRefs})
    >;
typedef $$PlantCompanionsTableCreateCompanionBuilder =
    PlantCompanionsCompanion Function({
      required int plantId,
      required int companionId,
      Value<int> rowid,
    });
typedef $$PlantCompanionsTableUpdateCompanionBuilder =
    PlantCompanionsCompanion Function({
      Value<int> plantId,
      Value<int> companionId,
      Value<int> rowid,
    });

final class $$PlantCompanionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $PlantCompanionsTable, PlantCompanion> {
  $$PlantCompanionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlantsTable _plantIdTable(_$AppDatabase db) => db.plants.createAlias(
    $_aliasNameGenerator(db.plantCompanions.plantId, db.plants.id),
  );

  $$PlantsTableProcessedTableManager get plantId {
    final $_column = $_itemColumn<int>('plant_id')!;

    final manager = $$PlantsTableTableManager(
      $_db,
      $_db.plants,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_plantIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlantsTable _companionIdTable(_$AppDatabase db) =>
      db.plants.createAlias(
        $_aliasNameGenerator(db.plantCompanions.companionId, db.plants.id),
      );

  $$PlantsTableProcessedTableManager get companionId {
    final $_column = $_itemColumn<int>('companion_id')!;

    final manager = $$PlantsTableTableManager(
      $_db,
      $_db.plants,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_companionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlantCompanionsTableFilterComposer
    extends Composer<_$AppDatabase, $PlantCompanionsTable> {
  $$PlantCompanionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PlantsTableFilterComposer get plantId {
    final $$PlantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plantId,
      referencedTable: $db.plants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlantsTableFilterComposer(
            $db: $db,
            $table: $db.plants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlantsTableFilterComposer get companionId {
    final $$PlantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.companionId,
      referencedTable: $db.plants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlantsTableFilterComposer(
            $db: $db,
            $table: $db.plants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlantCompanionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlantCompanionsTable> {
  $$PlantCompanionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PlantsTableOrderingComposer get plantId {
    final $$PlantsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plantId,
      referencedTable: $db.plants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlantsTableOrderingComposer(
            $db: $db,
            $table: $db.plants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlantsTableOrderingComposer get companionId {
    final $$PlantsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.companionId,
      referencedTable: $db.plants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlantsTableOrderingComposer(
            $db: $db,
            $table: $db.plants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlantCompanionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlantCompanionsTable> {
  $$PlantCompanionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PlantsTableAnnotationComposer get plantId {
    final $$PlantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plantId,
      referencedTable: $db.plants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlantsTableAnnotationComposer(
            $db: $db,
            $table: $db.plants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlantsTableAnnotationComposer get companionId {
    final $$PlantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.companionId,
      referencedTable: $db.plants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlantsTableAnnotationComposer(
            $db: $db,
            $table: $db.plants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlantCompanionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlantCompanionsTable,
          PlantCompanion,
          $$PlantCompanionsTableFilterComposer,
          $$PlantCompanionsTableOrderingComposer,
          $$PlantCompanionsTableAnnotationComposer,
          $$PlantCompanionsTableCreateCompanionBuilder,
          $$PlantCompanionsTableUpdateCompanionBuilder,
          (PlantCompanion, $$PlantCompanionsTableReferences),
          PlantCompanion,
          PrefetchHooks Function({bool plantId, bool companionId})
        > {
  $$PlantCompanionsTableTableManager(
    _$AppDatabase db,
    $PlantCompanionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlantCompanionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlantCompanionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlantCompanionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> plantId = const Value.absent(),
                Value<int> companionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlantCompanionsCompanion(
                plantId: plantId,
                companionId: companionId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int plantId,
                required int companionId,
                Value<int> rowid = const Value.absent(),
              }) => PlantCompanionsCompanion.insert(
                plantId: plantId,
                companionId: companionId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlantCompanionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({plantId = false, companionId = false}) {
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
                    if (plantId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.plantId,
                                referencedTable:
                                    $$PlantCompanionsTableReferences
                                        ._plantIdTable(db),
                                referencedColumn:
                                    $$PlantCompanionsTableReferences
                                        ._plantIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (companionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.companionId,
                                referencedTable:
                                    $$PlantCompanionsTableReferences
                                        ._companionIdTable(db),
                                referencedColumn:
                                    $$PlantCompanionsTableReferences
                                        ._companionIdTable(db)
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

typedef $$PlantCompanionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlantCompanionsTable,
      PlantCompanion,
      $$PlantCompanionsTableFilterComposer,
      $$PlantCompanionsTableOrderingComposer,
      $$PlantCompanionsTableAnnotationComposer,
      $$PlantCompanionsTableCreateCompanionBuilder,
      $$PlantCompanionsTableUpdateCompanionBuilder,
      (PlantCompanion, $$PlantCompanionsTableReferences),
      PlantCompanion,
      PrefetchHooks Function({bool plantId, bool companionId})
    >;
typedef $$PlantAntagonistsTableCreateCompanionBuilder =
    PlantAntagonistsCompanion Function({
      required int plantId,
      required int antagonistId,
      Value<int> rowid,
    });
typedef $$PlantAntagonistsTableUpdateCompanionBuilder =
    PlantAntagonistsCompanion Function({
      Value<int> plantId,
      Value<int> antagonistId,
      Value<int> rowid,
    });

final class $$PlantAntagonistsTableReferences
    extends
        BaseReferences<_$AppDatabase, $PlantAntagonistsTable, PlantAntagonist> {
  $$PlantAntagonistsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlantsTable _plantIdTable(_$AppDatabase db) => db.plants.createAlias(
    $_aliasNameGenerator(db.plantAntagonists.plantId, db.plants.id),
  );

  $$PlantsTableProcessedTableManager get plantId {
    final $_column = $_itemColumn<int>('plant_id')!;

    final manager = $$PlantsTableTableManager(
      $_db,
      $_db.plants,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_plantIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlantsTable _antagonistIdTable(_$AppDatabase db) =>
      db.plants.createAlias(
        $_aliasNameGenerator(db.plantAntagonists.antagonistId, db.plants.id),
      );

  $$PlantsTableProcessedTableManager get antagonistId {
    final $_column = $_itemColumn<int>('antagonist_id')!;

    final manager = $$PlantsTableTableManager(
      $_db,
      $_db.plants,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_antagonistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlantAntagonistsTableFilterComposer
    extends Composer<_$AppDatabase, $PlantAntagonistsTable> {
  $$PlantAntagonistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PlantsTableFilterComposer get plantId {
    final $$PlantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plantId,
      referencedTable: $db.plants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlantsTableFilterComposer(
            $db: $db,
            $table: $db.plants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlantsTableFilterComposer get antagonistId {
    final $$PlantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.antagonistId,
      referencedTable: $db.plants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlantsTableFilterComposer(
            $db: $db,
            $table: $db.plants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlantAntagonistsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlantAntagonistsTable> {
  $$PlantAntagonistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PlantsTableOrderingComposer get plantId {
    final $$PlantsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plantId,
      referencedTable: $db.plants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlantsTableOrderingComposer(
            $db: $db,
            $table: $db.plants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlantsTableOrderingComposer get antagonistId {
    final $$PlantsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.antagonistId,
      referencedTable: $db.plants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlantsTableOrderingComposer(
            $db: $db,
            $table: $db.plants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlantAntagonistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlantAntagonistsTable> {
  $$PlantAntagonistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PlantsTableAnnotationComposer get plantId {
    final $$PlantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plantId,
      referencedTable: $db.plants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlantsTableAnnotationComposer(
            $db: $db,
            $table: $db.plants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlantsTableAnnotationComposer get antagonistId {
    final $$PlantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.antagonistId,
      referencedTable: $db.plants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlantsTableAnnotationComposer(
            $db: $db,
            $table: $db.plants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlantAntagonistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlantAntagonistsTable,
          PlantAntagonist,
          $$PlantAntagonistsTableFilterComposer,
          $$PlantAntagonistsTableOrderingComposer,
          $$PlantAntagonistsTableAnnotationComposer,
          $$PlantAntagonistsTableCreateCompanionBuilder,
          $$PlantAntagonistsTableUpdateCompanionBuilder,
          (PlantAntagonist, $$PlantAntagonistsTableReferences),
          PlantAntagonist,
          PrefetchHooks Function({bool plantId, bool antagonistId})
        > {
  $$PlantAntagonistsTableTableManager(
    _$AppDatabase db,
    $PlantAntagonistsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlantAntagonistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlantAntagonistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlantAntagonistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> plantId = const Value.absent(),
                Value<int> antagonistId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlantAntagonistsCompanion(
                plantId: plantId,
                antagonistId: antagonistId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int plantId,
                required int antagonistId,
                Value<int> rowid = const Value.absent(),
              }) => PlantAntagonistsCompanion.insert(
                plantId: plantId,
                antagonistId: antagonistId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlantAntagonistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({plantId = false, antagonistId = false}) {
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
                    if (plantId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.plantId,
                                referencedTable:
                                    $$PlantAntagonistsTableReferences
                                        ._plantIdTable(db),
                                referencedColumn:
                                    $$PlantAntagonistsTableReferences
                                        ._plantIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (antagonistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.antagonistId,
                                referencedTable:
                                    $$PlantAntagonistsTableReferences
                                        ._antagonistIdTable(db),
                                referencedColumn:
                                    $$PlantAntagonistsTableReferences
                                        ._antagonistIdTable(db)
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

typedef $$PlantAntagonistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlantAntagonistsTable,
      PlantAntagonist,
      $$PlantAntagonistsTableFilterComposer,
      $$PlantAntagonistsTableOrderingComposer,
      $$PlantAntagonistsTableAnnotationComposer,
      $$PlantAntagonistsTableCreateCompanionBuilder,
      $$PlantAntagonistsTableUpdateCompanionBuilder,
      (PlantAntagonist, $$PlantAntagonistsTableReferences),
      PlantAntagonist,
      PrefetchHooks Function({bool plantId, bool antagonistId})
    >;
typedef $$GardensTableCreateCompanionBuilder =
    GardensCompanion Function({
      Value<int> id,
      required String name,
      Value<int> widthCells,
      Value<int> heightCells,
      Value<int> cellSizeCm,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$GardensTableUpdateCompanionBuilder =
    GardensCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> widthCells,
      Value<int> heightCells,
      Value<int> cellSizeCm,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$GardensTableReferences
    extends BaseReferences<_$AppDatabase, $GardensTable, Garden> {
  $$GardensTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GardenPlantsTable, List<GardenPlant>>
  _gardenPlantsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.gardenPlants,
    aliasName: $_aliasNameGenerator(db.gardens.id, db.gardenPlants.gardenId),
  );

  $$GardenPlantsTableProcessedTableManager get gardenPlantsRefs {
    final manager = $$GardenPlantsTableTableManager(
      $_db,
      $_db.gardenPlants,
    ).filter((f) => f.gardenId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_gardenPlantsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GardensTableFilterComposer
    extends Composer<_$AppDatabase, $GardensTable> {
  $$GardensTableFilterComposer({
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

  ColumnFilters<int> get widthCells => $composableBuilder(
    column: $table.widthCells,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heightCells => $composableBuilder(
    column: $table.heightCells,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cellSizeCm => $composableBuilder(
    column: $table.cellSizeCm,
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

  Expression<bool> gardenPlantsRefs(
    Expression<bool> Function($$GardenPlantsTableFilterComposer f) f,
  ) {
    final $$GardenPlantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gardenPlants,
      getReferencedColumn: (t) => t.gardenId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GardenPlantsTableFilterComposer(
            $db: $db,
            $table: $db.gardenPlants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GardensTableOrderingComposer
    extends Composer<_$AppDatabase, $GardensTable> {
  $$GardensTableOrderingComposer({
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

  ColumnOrderings<int> get widthCells => $composableBuilder(
    column: $table.widthCells,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heightCells => $composableBuilder(
    column: $table.heightCells,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cellSizeCm => $composableBuilder(
    column: $table.cellSizeCm,
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

class $$GardensTableAnnotationComposer
    extends Composer<_$AppDatabase, $GardensTable> {
  $$GardensTableAnnotationComposer({
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

  GeneratedColumn<int> get widthCells => $composableBuilder(
    column: $table.widthCells,
    builder: (column) => column,
  );

  GeneratedColumn<int> get heightCells => $composableBuilder(
    column: $table.heightCells,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cellSizeCm => $composableBuilder(
    column: $table.cellSizeCm,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> gardenPlantsRefs<T extends Object>(
    Expression<T> Function($$GardenPlantsTableAnnotationComposer a) f,
  ) {
    final $$GardenPlantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gardenPlants,
      getReferencedColumn: (t) => t.gardenId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GardenPlantsTableAnnotationComposer(
            $db: $db,
            $table: $db.gardenPlants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GardensTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GardensTable,
          Garden,
          $$GardensTableFilterComposer,
          $$GardensTableOrderingComposer,
          $$GardensTableAnnotationComposer,
          $$GardensTableCreateCompanionBuilder,
          $$GardensTableUpdateCompanionBuilder,
          (Garden, $$GardensTableReferences),
          Garden,
          PrefetchHooks Function({bool gardenPlantsRefs})
        > {
  $$GardensTableTableManager(_$AppDatabase db, $GardensTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GardensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GardensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GardensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> widthCells = const Value.absent(),
                Value<int> heightCells = const Value.absent(),
                Value<int> cellSizeCm = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GardensCompanion(
                id: id,
                name: name,
                widthCells: widthCells,
                heightCells: heightCells,
                cellSizeCm: cellSizeCm,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> widthCells = const Value.absent(),
                Value<int> heightCells = const Value.absent(),
                Value<int> cellSizeCm = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GardensCompanion.insert(
                id: id,
                name: name,
                widthCells: widthCells,
                heightCells: heightCells,
                cellSizeCm: cellSizeCm,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GardensTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gardenPlantsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (gardenPlantsRefs) db.gardenPlants],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (gardenPlantsRefs)
                    await $_getPrefetchedData<
                      Garden,
                      $GardensTable,
                      GardenPlant
                    >(
                      currentTable: table,
                      referencedTable: $$GardensTableReferences
                          ._gardenPlantsRefsTable(db),
                      managerFromTypedResult: (p0) => $$GardensTableReferences(
                        db,
                        table,
                        p0,
                      ).gardenPlantsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.gardenId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$GardensTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GardensTable,
      Garden,
      $$GardensTableFilterComposer,
      $$GardensTableOrderingComposer,
      $$GardensTableAnnotationComposer,
      $$GardensTableCreateCompanionBuilder,
      $$GardensTableUpdateCompanionBuilder,
      (Garden, $$GardensTableReferences),
      Garden,
      PrefetchHooks Function({bool gardenPlantsRefs})
    >;
typedef $$GardenPlantsTableCreateCompanionBuilder =
    GardenPlantsCompanion Function({
      Value<int> id,
      required int gardenId,
      required int plantId,
      required int gridX,
      required int gridY,
      Value<int> widthCells,
      Value<int> heightCells,
      Value<DateTime?> plantedAt,
      Value<String?> notes,
      Value<DateTime> createdAt,
    });
typedef $$GardenPlantsTableUpdateCompanionBuilder =
    GardenPlantsCompanion Function({
      Value<int> id,
      Value<int> gardenId,
      Value<int> plantId,
      Value<int> gridX,
      Value<int> gridY,
      Value<int> widthCells,
      Value<int> heightCells,
      Value<DateTime?> plantedAt,
      Value<String?> notes,
      Value<DateTime> createdAt,
    });

final class $$GardenPlantsTableReferences
    extends BaseReferences<_$AppDatabase, $GardenPlantsTable, GardenPlant> {
  $$GardenPlantsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GardensTable _gardenIdTable(_$AppDatabase db) =>
      db.gardens.createAlias(
        $_aliasNameGenerator(db.gardenPlants.gardenId, db.gardens.id),
      );

  $$GardensTableProcessedTableManager get gardenId {
    final $_column = $_itemColumn<int>('garden_id')!;

    final manager = $$GardensTableTableManager(
      $_db,
      $_db.gardens,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gardenIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlantsTable _plantIdTable(_$AppDatabase db) => db.plants.createAlias(
    $_aliasNameGenerator(db.gardenPlants.plantId, db.plants.id),
  );

  $$PlantsTableProcessedTableManager get plantId {
    final $_column = $_itemColumn<int>('plant_id')!;

    final manager = $$PlantsTableTableManager(
      $_db,
      $_db.plants,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_plantIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GardenPlantsTableFilterComposer
    extends Composer<_$AppDatabase, $GardenPlantsTable> {
  $$GardenPlantsTableFilterComposer({
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

  ColumnFilters<int> get gridX => $composableBuilder(
    column: $table.gridX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gridY => $composableBuilder(
    column: $table.gridY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get widthCells => $composableBuilder(
    column: $table.widthCells,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heightCells => $composableBuilder(
    column: $table.heightCells,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get plantedAt => $composableBuilder(
    column: $table.plantedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GardensTableFilterComposer get gardenId {
    final $$GardensTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gardenId,
      referencedTable: $db.gardens,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GardensTableFilterComposer(
            $db: $db,
            $table: $db.gardens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlantsTableFilterComposer get plantId {
    final $$PlantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plantId,
      referencedTable: $db.plants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlantsTableFilterComposer(
            $db: $db,
            $table: $db.plants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GardenPlantsTableOrderingComposer
    extends Composer<_$AppDatabase, $GardenPlantsTable> {
  $$GardenPlantsTableOrderingComposer({
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

  ColumnOrderings<int> get gridX => $composableBuilder(
    column: $table.gridX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gridY => $composableBuilder(
    column: $table.gridY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get widthCells => $composableBuilder(
    column: $table.widthCells,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heightCells => $composableBuilder(
    column: $table.heightCells,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get plantedAt => $composableBuilder(
    column: $table.plantedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GardensTableOrderingComposer get gardenId {
    final $$GardensTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gardenId,
      referencedTable: $db.gardens,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GardensTableOrderingComposer(
            $db: $db,
            $table: $db.gardens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlantsTableOrderingComposer get plantId {
    final $$PlantsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plantId,
      referencedTable: $db.plants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlantsTableOrderingComposer(
            $db: $db,
            $table: $db.plants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GardenPlantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GardenPlantsTable> {
  $$GardenPlantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get gridX =>
      $composableBuilder(column: $table.gridX, builder: (column) => column);

  GeneratedColumn<int> get gridY =>
      $composableBuilder(column: $table.gridY, builder: (column) => column);

  GeneratedColumn<int> get widthCells => $composableBuilder(
    column: $table.widthCells,
    builder: (column) => column,
  );

  GeneratedColumn<int> get heightCells => $composableBuilder(
    column: $table.heightCells,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get plantedAt =>
      $composableBuilder(column: $table.plantedAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$GardensTableAnnotationComposer get gardenId {
    final $$GardensTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gardenId,
      referencedTable: $db.gardens,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GardensTableAnnotationComposer(
            $db: $db,
            $table: $db.gardens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlantsTableAnnotationComposer get plantId {
    final $$PlantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plantId,
      referencedTable: $db.plants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlantsTableAnnotationComposer(
            $db: $db,
            $table: $db.plants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GardenPlantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GardenPlantsTable,
          GardenPlant,
          $$GardenPlantsTableFilterComposer,
          $$GardenPlantsTableOrderingComposer,
          $$GardenPlantsTableAnnotationComposer,
          $$GardenPlantsTableCreateCompanionBuilder,
          $$GardenPlantsTableUpdateCompanionBuilder,
          (GardenPlant, $$GardenPlantsTableReferences),
          GardenPlant,
          PrefetchHooks Function({bool gardenId, bool plantId})
        > {
  $$GardenPlantsTableTableManager(_$AppDatabase db, $GardenPlantsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GardenPlantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GardenPlantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GardenPlantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> gardenId = const Value.absent(),
                Value<int> plantId = const Value.absent(),
                Value<int> gridX = const Value.absent(),
                Value<int> gridY = const Value.absent(),
                Value<int> widthCells = const Value.absent(),
                Value<int> heightCells = const Value.absent(),
                Value<DateTime?> plantedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GardenPlantsCompanion(
                id: id,
                gardenId: gardenId,
                plantId: plantId,
                gridX: gridX,
                gridY: gridY,
                widthCells: widthCells,
                heightCells: heightCells,
                plantedAt: plantedAt,
                notes: notes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int gardenId,
                required int plantId,
                required int gridX,
                required int gridY,
                Value<int> widthCells = const Value.absent(),
                Value<int> heightCells = const Value.absent(),
                Value<DateTime?> plantedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GardenPlantsCompanion.insert(
                id: id,
                gardenId: gardenId,
                plantId: plantId,
                gridX: gridX,
                gridY: gridY,
                widthCells: widthCells,
                heightCells: heightCells,
                plantedAt: plantedAt,
                notes: notes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GardenPlantsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gardenId = false, plantId = false}) {
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
                    if (gardenId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.gardenId,
                                referencedTable: $$GardenPlantsTableReferences
                                    ._gardenIdTable(db),
                                referencedColumn: $$GardenPlantsTableReferences
                                    ._gardenIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (plantId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.plantId,
                                referencedTable: $$GardenPlantsTableReferences
                                    ._plantIdTable(db),
                                referencedColumn: $$GardenPlantsTableReferences
                                    ._plantIdTable(db)
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

typedef $$GardenPlantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GardenPlantsTable,
      GardenPlant,
      $$GardenPlantsTableFilterComposer,
      $$GardenPlantsTableOrderingComposer,
      $$GardenPlantsTableAnnotationComposer,
      $$GardenPlantsTableCreateCompanionBuilder,
      $$GardenPlantsTableUpdateCompanionBuilder,
      (GardenPlant, $$GardenPlantsTableReferences),
      GardenPlant,
      PrefetchHooks Function({bool gardenId, bool plantId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlantsTableTableManager get plants =>
      $$PlantsTableTableManager(_db, _db.plants);
  $$PlantCompanionsTableTableManager get plantCompanions =>
      $$PlantCompanionsTableTableManager(_db, _db.plantCompanions);
  $$PlantAntagonistsTableTableManager get plantAntagonists =>
      $$PlantAntagonistsTableTableManager(_db, _db.plantAntagonists);
  $$GardensTableTableManager get gardens =>
      $$GardensTableTableManager(_db, _db.gardens);
  $$GardenPlantsTableTableManager get gardenPlants =>
      $$GardenPlantsTableTableManager(_db, _db.gardenPlants);
}
