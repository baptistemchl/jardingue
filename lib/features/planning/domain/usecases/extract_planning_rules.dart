import 'dart:convert';

import '../models/planning_action_type.dart';
import '../models/planning_rule.dart';

/// Extrait les regles de planification depuis les
/// donnees JSON calendrier d'un plant.
class ExtractPlanningRules {
  const ExtractPlanningRules._();

  static List<PlanningRule> execute({
    required String? sowingCalendar,
    required String? plantingCalendar,
    required String? harvestCalendar,
    required int? plantingMinTempC,
  }) {
    final rules = <PlanningRule>[];

    _extractSowing(
      calendarJson: sowingCalendar,
      rules: rules,
      plantingMinTempC: plantingMinTempC,
    );

    _extractPlanting(
      calendarJson: plantingCalendar,
      rules: rules,
      plantingMinTempC: plantingMinTempC,
    );

    _extractHarvest(
      calendarJson: harvestCalendar,
      rules: rules,
    );

    return rules;
  }

  static void _extractSowing({
    required String? calendarJson,
    required List<PlanningRule> rules,
    required int? plantingMinTempC,
  }) {
    final data = _parseMonthlyPeriod(
      calendarJson,
    );
    if (data == null) return;

    for (final entry in data.entries) {
      final month = _monthIndex(entry.key);
      if (month == null) continue;

      final value = entry.value.toString();
      if (!value.startsWith('Oui')) continue;

      final isCover =
          value.contains('sous abri');
      final actionType = isCover
          ? PlanningActionType.sowingUnderCover
          : PlanningActionType.sowingOpenGround;

      rules.add(PlanningRule(
        actionType: actionType,
        monthStart: month,
        monthEnd: month,
        minTemp: isCover
            ? null
            : plantingMinTempC?.toDouble(),
        requiresNoFrost: !isCover,
        condition: isCover
            ? 'sous abri'
            : 'pleine terre',
        detail: _extractDetail(value),
      ));
    }
  }

  static void _extractPlanting({
    required String? calendarJson,
    required List<PlanningRule> rules,
    required int? plantingMinTempC,
  }) {
    final data = _parseMonthlyPeriod(
      calendarJson,
    );
    if (data == null) return;

    for (final entry in data.entries) {
      final month = _monthIndex(entry.key);
      if (month == null) continue;

      final value = entry.value.toString();
      if (!value.startsWith('Oui')) continue;

      rules.add(PlanningRule(
        actionType: PlanningActionType.planting,
        monthStart: month,
        monthEnd: month,
        minTemp: plantingMinTempC?.toDouble(),
        requiresNoFrost: true,
        detail: _extractDetail(value),
      ));
    }
  }

  static void _extractHarvest({
    required String? calendarJson,
    required List<PlanningRule> rules,
  }) {
    final data = _parseMonthlyPeriod(
      calendarJson,
    );
    if (data == null) return;

    for (final entry in data.entries) {
      final month = _monthIndex(entry.key);
      if (month == null) continue;

      final value = entry.value.toString();
      if (!value.startsWith('Oui')) continue;

      rules.add(PlanningRule(
        actionType: PlanningActionType.harvest,
        monthStart: month,
        monthEnd: month,
        detail: _extractDetail(value),
      ));
    }
  }

  static Map<String, dynamic>?
      _parseMonthlyPeriod(String? json) {
    if (json == null) return null;
    try {
      final data =
          jsonDecode(json) as Map<String, dynamic>;
      return data['monthly_period']
          as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  static String? _extractDetail(String value) {
    final match =
        RegExp(r'\(([^)]+)\)').firstMatch(value);
    return match?.group(1);
  }

  static const _months = {
    'January': 1,
    'February': 2,
    'March': 3,
    'April': 4,
    'May': 5,
    'June': 6,
    'July': 7,
    'August': 8,
    'September': 9,
    'October': 10,
    'November': 11,
    'December': 12,
  };

  static int? _monthIndex(String name) =>
      _months[name];
}
