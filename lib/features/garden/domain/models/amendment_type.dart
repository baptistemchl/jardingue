import 'package:flutter/material.dart';
import 'rotation_family.dart';

/// Types d'amendements applicables à une zone du potager.
enum AmendmentType {
  fumure(
    code: 'fumure',
    label: 'Fumure',
    emoji: '💩',
    color: 0xFF8D6E63,
    description: 'Fumier décomposé, riche en azote.',
  ),
  compost(
    code: 'compost',
    label: 'Compost',
    emoji: '🌱',
    color: 0xFF689F38,
    description: 'Matière organique décomposée, équilibrée.',
  ),
  paillage(
    code: 'paillage',
    label: 'Paillage',
    emoji: '🍂',
    color: 0xFFBCAAA4,
    description: 'Couverture du sol (paille, BRF, tontes).',
  ),
  engraisVert(
    code: 'engrais_vert',
    label: 'Engrais vert',
    emoji: '🌿',
    color: 0xFF7CB342,
    description: 'Culture intermédiaire enfouie (moutarde, phacélie…).',
  ),
  chaulage(
    code: 'chaulage',
    label: 'Chaulage',
    emoji: '⚪',
    color: 0xFFB0BEC5,
    description: 'Amendement calcaire, remonte le pH.',
  );

  const AmendmentType({
    required this.code,
    required this.label,
    required this.emoji,
    required this.color,
    required this.description,
  });

  final String code;
  final String label;
  final String emoji;
  final int color;
  final String description;

  static AmendmentType? fromCode(String? code) {
    if (code == null) return null;
    for (final t in AmendmentType.values) {
      if (t.code == code) return t;
    }
    return null;
  }
}

/// Genres et espèces réputés acidophiles (n'aiment pas les sols chaulés).
/// Matched on the latinName prefix pour résister aux ré-imports de
/// plants.json (aucun ID magique).
const Set<String> _acidophileGenera = {
  'solanum tuberosum', // pomme de terre + variétés
  'ipomoea batatas', // patate douce
  'fragaria', // fraisier
  'rheum', // rhubarbe
  'helianthus tuberosus', // topinambour
};

bool isAcidophile(String? latinName) {
  if (latinName == null) return false;
  final lower = latinName.trim().toLowerCase();
  return _acidophileGenera.any((prefix) => lower.startsWith(prefix));
}

/// Niveau de sévérité d'une alerte d'amendement.
enum AmendmentWarningSeverity {
  info,
  warning,
}

class AmendmentWarning {
  final AmendmentType type;
  final DateTime appliedAt;
  final AmendmentWarningSeverity severity;
  final String message;

  const AmendmentWarning({
    required this.type,
    required this.appliedAt,
    required this.severity,
    required this.message,
  });

  Color get color => severity == AmendmentWarningSeverity.warning
      ? Colors.orange
      : Colors.blue;
}

/// Évalue les conflits entre un amendement récent et la plante qu'on
/// s'apprête à implanter à cette zone. Retourne 0..n alertes.
///
/// Règles (simples et sans faux-positifs) :
/// - Chaulage < 3 ans + plante acidophile → WARNING fort
/// - Fumure < 1 an + légumineuses → INFO (risque de végétation excessive
///   au détriment de la production, les Fabacées fixent déjà l'azote)
/// - Fumure < 1 an + racines (Apiacées) → INFO (risque de fourchage)
List<AmendmentWarning> amendmentWarningsFor({
  required String? plantLatinName,
  required RotationFamily? plantFamily,
  required AmendmentType amendment,
  required DateTime appliedAt,
  required DateTime now,
}) {
  final ageDays = now.difference(appliedAt).inDays;
  final warnings = <AmendmentWarning>[];

  switch (amendment) {
    case AmendmentType.chaulage:
      if (ageDays < 365 * 3 && isAcidophile(plantLatinName)) {
        warnings.add(AmendmentWarning(
          type: amendment,
          appliedAt: appliedAt,
          severity: AmendmentWarningSeverity.warning,
          message:
              'Chaulage récent sur cette zone : cette plante acidophile '
              'risque de mal se développer (gale, déficit en fer).',
        ));
      }
      break;
    case AmendmentType.fumure:
      if (ageDays < 365) {
        if (plantFamily == RotationFamily.fabaceae) {
          warnings.add(AmendmentWarning(
            type: amendment,
            appliedAt: appliedAt,
            severity: AmendmentWarningSeverity.info,
            message:
                'Fumure récente : les légumineuses fixent déjà l\'azote, '
                'elles risquent de faire trop de feuillage.',
          ));
        } else if (plantFamily == RotationFamily.apiaceae) {
          warnings.add(AmendmentWarning(
            type: amendment,
            appliedAt: appliedAt,
            severity: AmendmentWarningSeverity.info,
            message:
                'Fumure récente : les racines (carotte, panais…) risquent '
                'de fourcher sur sol fraîchement fumé.',
          ));
        }
      }
      break;
    case AmendmentType.compost:
    case AmendmentType.paillage:
    case AmendmentType.engraisVert:
      // Pas d'alerte — amendements universellement bénéfiques.
      break;
  }

  return warnings;
}

/// Calcule l'opacité à appliquer au rendu d'un amendement selon son âge.
/// Année 0 = 0.6, décroît de 0.12/an, plancher 0.15.
double amendmentOpacity(DateTime appliedAt, DateTime now) {
  final ageYears = now.difference(appliedAt).inDays / 365.0;
  final raw = 0.6 - ageYears * 0.12;
  if (raw < 0.15) return 0.15;
  if (raw > 0.6) return 0.6;
  return raw;
}
