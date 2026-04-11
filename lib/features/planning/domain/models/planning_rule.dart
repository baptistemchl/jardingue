import 'planning_action_type.dart';

class PlanningRule {
  final PlanningActionType actionType;
  final int monthStart;
  final int monthEnd;
  final double? minTemp;
  final bool requiresNoFrost;
  final String? condition;
  final String? detail;

  const PlanningRule({
    required this.actionType,
    required this.monthStart,
    required this.monthEnd,
    this.minTemp,
    this.requiresNoFrost = false,
    this.condition,
    this.detail,
  });

  bool appliesToMonth(int month) {
    if (monthStart <= monthEnd) {
      return month >= monthStart
          && month <= monthEnd;
    }
    // Wrap annuel (ex: Oct-Mar = 10-3)
    return month >= monthStart
        || month <= monthEnd;
  }
}
