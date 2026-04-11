import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/features/planning/domain/models/planning_action_type.dart';
import 'package:jardingue/features/planning/domain/models/planning_rule.dart';

void main() {
  group('PlanningRule.appliesToMonth', () {
    test('simple range (avril-juin)', () {
      final rule = PlanningRule(
        actionType: PlanningActionType.planting,
        monthStart: 4,
        monthEnd: 6,
      );

      expect(rule.appliesToMonth(3), isFalse);
      expect(rule.appliesToMonth(4), isTrue);
      expect(rule.appliesToMonth(5), isTrue);
      expect(rule.appliesToMonth(6), isTrue);
      expect(rule.appliesToMonth(7), isFalse);
    });

    test('wrap annuel (oct-mar)', () {
      final rule = PlanningRule(
        actionType:
            PlanningActionType.soilPreparation,
        monthStart: 10,
        monthEnd: 3,
      );

      expect(rule.appliesToMonth(10), isTrue);
      expect(rule.appliesToMonth(11), isTrue);
      expect(rule.appliesToMonth(12), isTrue);
      expect(rule.appliesToMonth(1), isTrue);
      expect(rule.appliesToMonth(2), isTrue);
      expect(rule.appliesToMonth(3), isTrue);
      expect(rule.appliesToMonth(4), isFalse);
      expect(rule.appliesToMonth(9), isFalse);
    });

    test('mois unique', () {
      final rule = PlanningRule(
        actionType: PlanningActionType.harvest,
        monthStart: 8,
        monthEnd: 8,
      );

      expect(rule.appliesToMonth(7), isFalse);
      expect(rule.appliesToMonth(8), isTrue);
      expect(rule.appliesToMonth(9), isFalse);
    });

    test('année complète (jan-dec)', () {
      final rule = PlanningRule(
        actionType: PlanningActionType.watering,
        monthStart: 1,
        monthEnd: 12,
      );

      for (var m = 1; m <= 12; m++) {
        expect(
          rule.appliesToMonth(m),
          isTrue,
          reason: 'Mois $m devrait passer',
        );
      }
    });

    test('wrap nov-fev', () {
      final rule = PlanningRule(
        actionType:
            PlanningActionType.frostProtection,
        monthStart: 11,
        monthEnd: 2,
      );

      expect(rule.appliesToMonth(11), isTrue);
      expect(rule.appliesToMonth(12), isTrue);
      expect(rule.appliesToMonth(1), isTrue);
      expect(rule.appliesToMonth(2), isTrue);
      expect(rule.appliesToMonth(3), isFalse);
      expect(rule.appliesToMonth(10), isFalse);
    });
  });
}
