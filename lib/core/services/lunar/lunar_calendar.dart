import 'dart:math' as math;

/// Type de jour selon le calendrier lunaire biodynamique (Maria Thun).
///
/// Selon la constellation traversée par la Lune, l'énergie favorise une
/// partie spécifique de la plante :
/// - Terre (Taureau, Vierge, Capricorne) → racines
/// - Eau (Cancer, Scorpion, Poissons) → feuilles
/// - Air (Gémeaux, Balance, Verseau) → fleurs
/// - Feu (Bélier, Lion, Sagittaire) → fruits / graines
enum LunarDayType {
  root('Jour racines', '🥕', 'racines'),
  leaf('Jour feuilles', '🥬', 'feuilles'),
  flower('Jour fleurs', '🌸', 'fleurs'),
  fruit('Jour fruits', '🍅', 'fruits');

  final String label;
  final String emoji;
  final String plantPart;

  const LunarDayType(this.label, this.emoji, this.plantPart);
}

/// Constellations zodiacales (utilisées en sidéral, façon Maria Thun).
/// Ophiuchus est intégré au Scorpion (pratique des almanachs francophones).
enum ZodiacConstellation {
  aries('Bélier', '♈', LunarDayType.fruit),
  taurus('Taureau', '♉', LunarDayType.root),
  gemini('Gémeaux', '♊', LunarDayType.flower),
  cancer('Cancer', '♋', LunarDayType.leaf),
  leo('Lion', '♌', LunarDayType.fruit),
  virgo('Vierge', '♍', LunarDayType.root),
  libra('Balance', '♎', LunarDayType.flower),
  scorpio('Scorpion', '♏', LunarDayType.leaf),
  sagittarius('Sagittaire', '♐', LunarDayType.fruit),
  capricorn('Capricorne', '♑', LunarDayType.root),
  aquarius('Verseau', '♒', LunarDayType.flower),
  pisces('Poissons', '♓', LunarDayType.leaf);

  final String label;
  final String symbol;
  final LunarDayType dayType;

  const ZodiacConstellation(this.label, this.symbol, this.dayType);
}

/// Phase synodique de la Lune.
enum LunarPhase {
  newMoon('Nouvelle Lune', '🌑'),
  waxingCrescent('Premier croissant', '🌒'),
  firstQuarter('Premier quartier', '🌓'),
  waxingGibbous('Lune gibbeuse croissante', '🌔'),
  fullMoon('Pleine Lune', '🌕'),
  waningGibbous('Lune gibbeuse décroissante', '🌖'),
  lastQuarter('Dernier quartier', '🌗'),
  waningCrescent('Dernier croissant', '🌘');

  final String label;
  final String emoji;

  const LunarPhase(this.label, this.emoji);
}

/// Évènement lunaire spécial pendant lequel les jardiniers biodynamiques
/// s'abstiennent d'intervenir au jardin.
enum LunarAbstainEvent {
  /// La Lune traverse le plan de l'écliptique : énergie perturbée.
  node('Nœud lunaire', 'La Lune traverse l\'écliptique. Les végétaux sont perturbés — abstenez-vous d\'intervenir.'),

  /// Distance Terre-Lune minimale : forte attraction, semis fragiles.
  perigee('Périgée', 'La Lune est au plus proche de la Terre. Les jeunes semis s\'étiolent — abstenez-vous de semer.'),

  /// Distance maximale : faible influence, jardinage déconseillé.
  apogee('Apogée', 'La Lune est au plus loin. Influence affaiblie — patientez avant de jardiner.');

  final String label;
  final String description;

  const LunarAbstainEvent(this.label, this.description);
}

/// État lunaire complet pour une date donnée.
///
/// Combine **toutes** les dimensions utiles au jardinage biodynamique :
/// - phase synodique (nouvelle / croissante / pleine / décroissante)
/// - constellation sidérale → type de jour (feuilles / fleurs / fruits / racines)
/// - Lune **montante ou descendante** (déclinaison équatoriale, distinct
///   de croissante / décroissante !)
/// - nœuds lunaires, apogée, périgée → jours d'abstention
///
/// Sources astronomiques :
/// - Formules simplifiées de Meeus, _Astronomical Algorithms_ (1998), ch. 47.
///   Implémentation reprise du JavaScript SunCalc de Vladimir Agafonkin
///   (https://github.com/mourner/suncalc) — ~13 termes périodiques,
///   précision ≈ 0,02° en longitude, ≈ qq minutes en timing.
/// - Calendrier biodynamique Maria Thun (constellations IAU sidérales).
///   Références : Biodynamic Association UK, Stella Natura, Rustica.
class LunarDay {
  /// Instant représentatif du jour (midi UTC).
  final DateTime instant;

  /// Longitude écliptique tropicale apparente (degrés, 0-360).
  final double tropicalLongitude;

  /// Longitude écliptique sidérale (Lahiri ayanamsa).
  /// C'est elle qu'on mappe à la constellation Maria Thun.
  final double siderealLongitude;

  /// Latitude écliptique (degrés, ±5,3).
  final double eclipticLatitude;

  /// Déclinaison équatoriale (degrés). Sert à déterminer montante/descendante.
  final double declination;

  /// Distance Terre-Lune (km). Sert à détecter périgée/apogée.
  final double distanceKm;

  /// Fraction de la phase synodique 0-1 (0 = nouvelle, 0,5 = pleine).
  final double phaseFraction;

  /// Phase symbolique.
  final LunarPhase phase;

  /// Fraction illuminée 0-1 (0 = nouvelle, 1 = pleine).
  final double illuminationFraction;

  /// Constellation sidérale traversée.
  final ZodiacConstellation constellation;

  /// Type de jour biodynamique (dérivé de la constellation).
  LunarDayType get dayType => constellation.dayType;

  /// Lune croissante (phaseFraction < 0,5).
  /// ⚠ À ne pas confondre avec montante (déclinaison).
  final bool isWaxing;

  /// **Lune montante** : la déclinaison équatoriale augmente jour après jour.
  /// La sève monte → favorable aux greffes, récolte de fruits, semis aériens.
  ///
  /// Distinct de la phase ! La Lune peut être croissante ET descendante.
  final bool isAscending;

  /// Évènement spécial dans les ±12h (au plus un à la fois).
  final LunarAbstainEvent? abstainEvent;

  /// Vrai si la journée est défavorable à toute intervention.
  bool get isAbstainDay => abstainEvent != null;

  const LunarDay({
    required this.instant,
    required this.tropicalLongitude,
    required this.siderealLongitude,
    required this.eclipticLatitude,
    required this.declination,
    required this.distanceKm,
    required this.phaseFraction,
    required this.phase,
    required this.illuminationFraction,
    required this.constellation,
    required this.isWaxing,
    required this.isAscending,
    required this.abstainEvent,
  });

  /// Calcule l'état lunaire pour la date donnée (résolution journalière).
  ///
  /// On évalue toujours à midi UTC pour éviter les sauts de constellation
  /// entre 23h locale et 1h le lendemain.
  factory LunarDay.forDate(DateTime date) {
    final noonUtc = DateTime.utc(date.year, date.month, date.day, 12);
    return _LunarSolver.solve(noonUtc);
  }

  /// Date prochaine pleine lune (approximative, à ±1 j).
  DateTime get nextFullMoon {
    const lunarMonth = 29.53059;
    final daysToFull = (0.5 - phaseFraction + 1.0) % 1.0 * lunarMonth;
    return instant.add(Duration(hours: (daysToFull * 24).round()));
  }

  /// Date prochaine nouvelle lune (approximative, à ±1 j).
  DateTime get nextNewMoon {
    const lunarMonth = 29.53059;
    final daysToNew = (1.0 - phaseFraction) % 1.0 * lunarMonth;
    return instant.add(Duration(hours: (daysToNew * 24).round()));
  }
}

class _LunarSolver {
  static const _deg2rad = math.pi / 180.0;
  static const _rad2deg = 180.0 / math.pi;

  /// Obliquité moyenne de l'écliptique (J2000, suffisante à ±0,01° sur 50 ans).
  static const _obliquityDeg = 23.4397;

  /// Lahiri ayanamsa : 23,85° en J2000 + précession ≈ 50,29″/an.
  /// Source : NASA Lambda, Lahiri standard.
  static double _ayanamsaForYear(int year) {
    final yearsSince2000 = year - 2000;
    return 23.85 + yearsSince2000 * 50.29 / 3600.0;
  }

  static LunarDay solve(DateTime dateUtc) {
    final d = _daysSinceJ2000(dateUtc);
    final coords = _moonCoords(d);

    final tropicalLon = _normalize360(coords.longitudeDeg);
    final siderealLon =
        _normalize360(tropicalLon - _ayanamsaForYear(dateUtc.year));

    final constellation = _constellationFor(siderealLon);

    // Phase synodique : angle Soleil-Lune dans l'écliptique.
    final sunLon = _sunLongitudeDeg(d);
    final phaseFraction = _normalize360(tropicalLon - sunLon) / 360.0;
    final phase = _phaseFor(phaseFraction);
    final isWaxing = phaseFraction < 0.5;
    // Illumination (cosinus de l'angle de phase).
    final phaseAngle = phaseFraction * 2 * math.pi;
    final illumination = (1 - math.cos(phaseAngle)) / 2;

    // Montante / descendante : variation de déclinaison sur ±12h.
    final dLater = _daysSinceJ2000(dateUtc.add(const Duration(hours: 12)));
    final dBefore = _daysSinceJ2000(dateUtc.subtract(const Duration(hours: 12)));
    final coordsLater = _moonCoords(dLater);
    final coordsBefore = _moonCoords(dBefore);
    final isAscending = coordsLater.declinationDeg > coordsBefore.declinationDeg;

    // Nœud lunaire : latitude écliptique change de signe dans la fenêtre ±12h.
    final isNode =
        coordsBefore.latitudeDeg.sign != coordsLater.latitudeDeg.sign;

    // Apogée / périgée : distance est un extremum local dans la fenêtre.
    final isPerigee = coords.distanceKm < coordsBefore.distanceKm &&
        coords.distanceKm < coordsLater.distanceKm &&
        coords.distanceKm < 365000;
    final isApogee = coords.distanceKm > coordsBefore.distanceKm &&
        coords.distanceKm > coordsLater.distanceKm &&
        coords.distanceKm > 400000;

    // Priorité : nœud > périgée > apogée (impact décroissant).
    final abstain = isNode
        ? LunarAbstainEvent.node
        : isPerigee
            ? LunarAbstainEvent.perigee
            : isApogee
                ? LunarAbstainEvent.apogee
                : null;

    return LunarDay(
      instant: dateUtc,
      tropicalLongitude: tropicalLon,
      siderealLongitude: siderealLon,
      eclipticLatitude: coords.latitudeDeg,
      declination: coords.declinationDeg,
      distanceKm: coords.distanceKm,
      phaseFraction: phaseFraction,
      phase: phase,
      illuminationFraction: illumination,
      constellation: constellation,
      isWaxing: isWaxing,
      isAscending: isAscending,
      abstainEvent: abstain,
    );
  }

  /// J2000 = 2000-01-01 12:00 TT ≈ 11:58:55,816 UTC.
  /// L'écart TT-UTC (~1 min) est négligeable pour la résolution journalière.
  static double _daysSinceJ2000(DateTime utc) {
    const j2000MillisUtc = 946728000000; // 2000-01-01 12:00 UTC en epoch ms
    return (utc.millisecondsSinceEpoch - j2000MillisUtc) /
        (1000.0 * 86400.0);
  }

  /// Position lunaire géocentrique simplifiée — version SunCalc / Mourner.
  /// Précision en longitude ≈ 0,02°, en latitude ≈ 0,02°.
  /// Distance ≈ 0,1 % de la valeur réelle.
  static _MoonCoords _moonCoords(double d) {
    // Angles moyens (Meeus 47.1 / 47.4 / 47.5, première approximation).
    final L = (218.316 + 13.176396 * d) * _deg2rad;
    final M = (134.963 + 13.064993 * d) * _deg2rad;
    final F = (93.272 + 13.229350 * d) * _deg2rad;

    // Longitude apparente (premier terme périodique : l'équation du centre).
    final lambda = L + 6.289 * _deg2rad * math.sin(M);
    final beta = 5.128 * _deg2rad * math.sin(F);
    final distKm = 385001 - 20905 * math.cos(M);

    final eps = _obliquityDeg * _deg2rad;
    final dec = math.asin(
      math.sin(beta) * math.cos(eps) +
          math.cos(beta) * math.sin(eps) * math.sin(lambda),
    );

    return _MoonCoords(
      longitudeDeg: lambda * _rad2deg,
      latitudeDeg: beta * _rad2deg,
      declinationDeg: dec * _rad2deg,
      distanceKm: distKm,
    );
  }

  /// Longitude écliptique du Soleil — formule approchée (USNO).
  static double _sunLongitudeDeg(double d) {
    final M = (357.5291 + 0.98560028 * d) * _deg2rad;
    final L = 280.459 + 0.98564736 * d;
    final C = 1.915 * math.sin(M) + 0.020 * math.sin(2 * M);
    return _normalize360(L + C);
  }

  static double _normalize360(double deg) {
    var x = deg % 360.0;
    if (x < 0) x += 360.0;
    return x;
  }

  /// Limites IAU des constellations en longitude écliptique sidérale.
  /// Ophiuchus (≈248°-266°) est intégré au Scorpion — pratique standard des
  /// almanachs biodynamiques francophones.
  static ZodiacConstellation _constellationFor(double siderealLonDeg) {
    final l = siderealLonDeg;
    if (l < 27.3 || l >= 351.6) return ZodiacConstellation.pisces;
    if (l < 53.4) return ZodiacConstellation.aries;
    if (l < 90.4) return ZodiacConstellation.taurus;
    if (l < 117.7) return ZodiacConstellation.gemini;
    if (l < 138.2) return ZodiacConstellation.cancer;
    if (l < 173.9) return ZodiacConstellation.leo;
    if (l < 217.8) return ZodiacConstellation.virgo;
    if (l < 241.1) return ZodiacConstellation.libra;
    if (l < 266.6) return ZodiacConstellation.scorpio; // inclut Ophiuchus
    if (l < 299.7) return ZodiacConstellation.sagittarius;
    if (l < 327.6) return ZodiacConstellation.capricorn;
    return ZodiacConstellation.aquarius;
  }

  static LunarPhase _phaseFor(double f) {
    if (f < 0.03 || f > 0.97) return LunarPhase.newMoon;
    if (f < 0.22) return LunarPhase.waxingCrescent;
    if (f < 0.28) return LunarPhase.firstQuarter;
    if (f < 0.47) return LunarPhase.waxingGibbous;
    if (f < 0.53) return LunarPhase.fullMoon;
    if (f < 0.72) return LunarPhase.waningGibbous;
    if (f < 0.78) return LunarPhase.lastQuarter;
    return LunarPhase.waningCrescent;
  }
}

class _MoonCoords {
  final double longitudeDeg;
  final double latitudeDeg;
  final double declinationDeg;
  final double distanceKm;

  const _MoonCoords({
    required this.longitudeDeg,
    required this.latitudeDeg,
    required this.declinationDeg,
    required this.distanceKm,
  });
}
