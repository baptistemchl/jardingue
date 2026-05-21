/// Cycle de vie d'un semis dans le carnet.
///
/// Le code stocké en DB est volontairement stable et court (anglais),
/// indépendant des labels d'affichage qui passent par l'ARB.
enum SeedlingStatus {
  germinating('germinating'),
  ready('ready'),
  transplanted('transplanted'),
  failed('failed');

  final String code;
  const SeedlingStatus(this.code);

  static SeedlingStatus fromCode(String code) {
    return SeedlingStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => SeedlingStatus.germinating,
    );
  }

  /// Statut suivant dans le cycle « heureux ». germinating → ready →
  /// transplanted. transplanted et failed n'avancent plus.
  SeedlingStatus? get next => switch (this) {
        SeedlingStatus.germinating => SeedlingStatus.ready,
        SeedlingStatus.ready => SeedlingStatus.transplanted,
        SeedlingStatus.transplanted => null,
        SeedlingStatus.failed => null,
      };

  bool get isArchived =>
      this == SeedlingStatus.transplanted || this == SeedlingStatus.failed;
}
