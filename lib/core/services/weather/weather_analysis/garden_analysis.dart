import 'dart:math' as math;

import '../weather_models.dart';

/// Statut visuel d'une activité au jardin.
enum GardenStatus { good, warning, bad }

/// Sévérité globale du verdict du jour.
enum GardenSeverity { critical, hard, ok, good, great }

/// Source du verdict (utile pour expliquer à l'utilisateur **pourquoi** une
/// activité est défavorable : la cascade lune > météo est explicite).
enum GardenVerdictSource { lunar, weather, both }

/// Verdict pour une activité spécifique (semer, repiquer, récolter...).
///
/// La cascade biodynamique : la **lune** détermine la base (favorable ou non),
/// la **météo** ne peut que bloquer (jamais débloquer). Si l'un OU l'autre
/// dit "non", le verdict est négatif — avec la raison explicite.
class ActivityVerdict {
  final GardenStatus status;

  /// Étiquette courte (« Idéal », « À éviter », « Trop froid »...).
  final String label;

  /// Quelle dimension a déclenché ce verdict (utile pour l'UI : "à cause
  /// de la lune" vs "à cause de la météo").
  final GardenVerdictSource source;

  /// Recommandations / suggestions ordonnées (max 4-5).
  final List<String> recommendations;

  const ActivityVerdict({
    required this.status,
    required this.label,
    required this.source,
    required this.recommendations,
  });
}

/// Analyse jardinage complète du jour, **cohérente** entre lune et météo.
///
/// Source unique de vérité utilisée par toute la page météo. Les activités
/// (semis, plantation, récolte) sont déterminées par une cascade explicite :
/// 1. Si la Lune est en **nœud, apogée, périgée** → tout est défavorable.
/// 2. Sinon, la lune montante/descendante + type de jour fixent la base.
/// 3. La météo peut **bloquer** (gel, vent fort, canicule, sol détrempé)
///    mais **ne peut jamais débloquer** ce que la lune déconseille.
class GardenAnalysis {
  /// Verdict global affiché en titre ("Excellentes conditions", etc.).
  final String verdict;
  final String emoji;
  final String scoreLabel;
  final GardenSeverity severity;

  /// Phrase concise utilisable en bandeau (« Jour racines — favorable au
  /// repiquage des carottes »). Toujours cohérente avec [verdict].
  final String headline;

  /// Sous-titre explicatif (« La météo n'est pas contre-indiquée », ou
  /// « Le gel attendu cette nuit bloque toute plantation »...).
  final String summary;

  /// Alertes critiques météo (gel, canicule, vent violent...).
  final List<String> alerts;

  /// Verdict par activité — toujours en cascade lune → météo.
  final ActivityVerdict sowing; // semer
  final ActivityVerdict planting; // repiquer / planter en pleine terre
  final ActivityVerdict harvest; // récolter
  final ActivityVerdict watering; // arroser

  /// Détail état lunaire (pour affichage dans la section dédiée).
  final LunarDay lunar;

  /// Détail des "couches" de la cascade pour l'UI didactique.
  final List<CascadeLayer> cascade;

  const GardenAnalysis({
    required this.verdict,
    required this.emoji,
    required this.scoreLabel,
    required this.severity,
    required this.headline,
    required this.summary,
    required this.alerts,
    required this.sowing,
    required this.planting,
    required this.harvest,
    required this.watering,
    required this.lunar,
    required this.cascade,
  });

  factory GardenAnalysis.fromWeather(WeatherData weather) {
    return _GardenAnalysisCalculator().calculate(weather);
  }
}

/// Représente une étape de la cascade affichée à l'utilisateur.
/// Permet d'expliquer le raisonnement : « 1. Jour racines → 2. Lune
/// descendante → 3. Pas de gel → favorable au repiquage ».
class CascadeLayer {
  final String emoji;
  final String label;
  final String detail;
  final GardenStatus status;
  final bool isVeto;

  const CascadeLayer({
    required this.emoji,
    required this.label,
    required this.detail,
    required this.status,
    this.isVeto = false,
  });
}

class _GardenAnalysisCalculator {
  GardenAnalysis calculate(WeatherData weather) {
    final lunar = weather.lunar;
    final current = weather.current;
    final hourly = weather.hourlyForecast;
    final daily = weather.dailyForecast;

    final temp = current.temperature;
    final humidity = current.humidity;
    final precip = current.precipitation;
    final wind = current.windSpeed;
    final uv = current.uvIndex;

    final minTempTonight = _minTempTonight(daily, temp);
    final forecast = _forecast(hourly, precip);

    final weatherEval = _evaluateWeather(
      temp: temp,
      minTempTonight: minTempTonight,
      wind: wind,
      precip: precip,
      humidity: humidity,
      uv: uv,
      maxPrecipProb: forecast.maxPrecipProb,
      totalPrecip24h: forecast.totalPrecip24h,
    );

    final alerts = weatherEval.alerts;

    // === CASCADE PAR ACTIVITÉ ===
    final sowing = _evaluateSowing(lunar, weatherEval);
    final planting = _evaluatePlanting(lunar, weatherEval);
    final harvest = _evaluateHarvest(lunar, weatherEval);
    final watering = _evaluateWatering(lunar, weatherEval);

    // === VERDICT GLOBAL ===
    final global = _composeGlobal(
      lunar: lunar,
      weatherEval: weatherEval,
      sowing: sowing,
      planting: planting,
      harvest: harvest,
      alerts: alerts,
    );

    final cascade = _buildCascade(lunar, weatherEval);

    return GardenAnalysis(
      verdict: global.verdict,
      emoji: global.emoji,
      scoreLabel: global.scoreLabel,
      severity: global.severity,
      headline: global.headline,
      summary: global.summary,
      alerts: alerts,
      sowing: sowing,
      planting: planting,
      harvest: harvest,
      watering: watering,
      lunar: lunar,
      cascade: cascade,
    );
  }

  double _minTempTonight(List<DailyForecast> daily, double fallback) {
    if (daily.isEmpty) return fallback;
    return daily[0].tempMin;
  }

  _ForecastData _forecast(List<HourlyForecast> hourly, double currentPrecip) {
    double totalPrecip24h = currentPrecip;
    int maxPrecipProb = 0;

    for (var i = 0; i < math.min(24, hourly.length); i++) {
      final h = hourly[i];
      totalPrecip24h += h.precipitation;
      if (h.precipitationProbability > maxPrecipProb) {
        maxPrecipProb = h.precipitationProbability;
      }
    }

    return _ForecastData(
      totalPrecip24h: totalPrecip24h,
      maxPrecipProb: maxPrecipProb,
    );
  }

  _WeatherEval _evaluateWeather({
    required double temp,
    required double minTempTonight,
    required double wind,
    required double precip,
    required double humidity,
    required double uv,
    required int maxPrecipProb,
    required double totalPrecip24h,
  }) {
    final alerts = <String>[];
    _WeatherSeverity gardenWide = _WeatherSeverity.none;
    String? gardenWideReason;

    // --- Vétos critiques météo (bloquent toute intervention) ---
    if (temp < 0) {
      gardenWide = _WeatherSeverity.block;
      gardenWideReason = 'Gel actif (${temp.round()}°C)';
      alerts.add('Gel actif ! Rentrez les plants sensibles immédiatement.');
    } else if (minTempTonight < 0) {
      if (temp < 5) {
        gardenWide = _WeatherSeverity.block;
        gardenWideReason = 'Gel attendu cette nuit (${minTempTonight.round()}°C)';
      } else {
        gardenWide = _WeatherSeverity.caution;
        gardenWideReason = 'Gel attendu cette nuit';
      }
      alerts.add(
        'Gel prévu cette nuit (${minTempTonight.round()}°C). '
        'Protégez vos plants.',
      );
    } else if (minTempTonight < 3) {
      gardenWide = _WeatherSeverity.caution;
      gardenWideReason = 'Risque de gelée nocturne';
      alerts.add('Risque de gelée cette nuit. Surveillez les jeunes plants.');
    }

    if (temp > 35) {
      gardenWide = _WeatherSeverity.block;
      gardenWideReason ??= 'Canicule (${temp.round()}°C)';
      alerts.add(
        'Canicule : évitez toute activité au jardin entre 11h et 17h.',
      );
    } else if (temp > 30 && gardenWide.index < _WeatherSeverity.caution.index) {
      gardenWide = _WeatherSeverity.caution;
      gardenWideReason ??= 'Forte chaleur';
    }

    if (wind > 50) {
      gardenWide = _WeatherSeverity.block;
      gardenWideReason ??= 'Vent violent (${wind.round()} km/h)';
      alerts.add(
        'Vent violent (${wind.round()} km/h). Tuteurez vos plants hauts.',
      );
    } else if (wind > 30 && gardenWide.index < _WeatherSeverity.caution.index) {
      gardenWide = _WeatherSeverity.caution;
      gardenWideReason ??= 'Vent soutenu (${wind.round()} km/h)';
    }

    if (uv > 8) {
      alerts.add('UV très élevés. Protégez-vous si vous jardinez.');
    }

    return _WeatherEval(
      temp: temp,
      minTempTonight: minTempTonight,
      wind: wind,
      precip: precip,
      humidity: humidity,
      uv: uv,
      maxPrecipProb: maxPrecipProb,
      totalPrecip24h: totalPrecip24h,
      gardenWide: gardenWide,
      gardenWideReason: gardenWideReason,
      alerts: alerts,
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // SEMIS  — favorable en lune **montante**, jour adapté à la plante visée.
  // ─────────────────────────────────────────────────────────────────────
  ActivityVerdict _evaluateSowing(LunarDay lunar, _WeatherEval w) {
    if (lunar.isAbstainDay) {
      return ActivityVerdict(
        status: GardenStatus.bad,
        label: lunar.abstainEvent!.label,
        source: GardenVerdictSource.lunar,
        recommendations: [
          'À éviter aujourd\'hui : ${lunar.abstainEvent!.label.toLowerCase()}.',
          lunar.abstainEvent!.description,
        ],
      );
    }

    // Météo : sol détrempé / pluie en cours bloquent les semis.
    if (w.precip > 2 || w.totalPrecip24h > 10) {
      return const ActivityVerdict(
        status: GardenStatus.bad,
        label: 'Sol détrempé',
        source: GardenVerdictSource.weather,
        recommendations: [
          '✗ Sol gorgé d\'eau — les graines pourrissent.',
          'Attendez 2-3 jours après la pluie.',
        ],
      );
    }

    // Météo : gel actif ou imminent bloque.
    if (w.gardenWide == _WeatherSeverity.block &&
        (w.temp < 5 || w.minTempTonight < 0)) {
      return ActivityVerdict(
        status: GardenStatus.bad,
        label: 'Trop froid',
        source: GardenVerdictSource.weather,
        recommendations: [
          '✗ ${w.gardenWideReason ?? "Gel"} — les graines ne lèveront pas.',
          '• Semis en intérieur / sous abri possibles.',
        ],
      );
    }

    // Météo : vent fort emporte les graines.
    if (w.wind > 35) {
      return ActivityVerdict(
        status: GardenStatus.bad,
        label: 'Vent trop fort',
        source: GardenVerdictSource.weather,
        recommendations: [
          '✗ Vent à ${w.wind.round()} km/h — graines emportées.',
          'Reportez à un jour plus calme.',
        ],
      );
    }

    // Base lunaire.
    final dayType = lunar.dayType;
    if (lunar.isAscending) {
      // Lune montante → semis favorable. Jour détermine quoi semer.
      final crops = _sowingCropsFor(dayType);
      return ActivityVerdict(
        status: GardenStatus.good,
        label: 'Favorable — ${dayType.label.toLowerCase()}',
        source: GardenVerdictSource.lunar,
        recommendations: [
          '✓ Lune montante : la sève monte, les graines lèvent bien.',
          '✓ Jour ${dayType.plantText} : $crops',
          if (w.gardenWide == _WeatherSeverity.caution)
            '• Météo : ${w.gardenWideReason ?? "à surveiller"}.',
          if (w.maxPrecipProb > 50) '• Pluie prévue, parfait pour arroser après semis.',
        ],
      );
    } else {
      // Lune descendante → moins favorable au semis (sauf racines en jour racines).
      if (dayType == LunarDayType.root) {
        final crops = _sowingCropsFor(dayType);
        return ActivityVerdict(
          status: GardenStatus.good,
          label: 'Favorable aux légumes-racines',
          source: GardenVerdictSource.lunar,
          recommendations: [
            '✓ Lune descendante + jour racines : conditions idéales.',
            '✓ Semez : $crops',
            if (w.gardenWide == _WeatherSeverity.caution)
              '• Météo : ${w.gardenWideReason ?? "à surveiller"}.',
          ],
        );
      }
      return ActivityVerdict(
        status: GardenStatus.warning,
        label: 'Peu favorable',
        source: GardenVerdictSource.lunar,
        recommendations: [
          '• Lune descendante : préférez le repiquage aux semis aériens.',
          '• Si vous semez : restez sur des légumes-racines (jour ${dayType.plantText}).',
        ],
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // PLANTATION / REPIQUAGE — favorable en lune **descendante**.
  // ─────────────────────────────────────────────────────────────────────
  ActivityVerdict _evaluatePlanting(LunarDay lunar, _WeatherEval w) {
    if (lunar.isAbstainDay) {
      return ActivityVerdict(
        status: GardenStatus.bad,
        label: lunar.abstainEvent!.label,
        source: GardenVerdictSource.lunar,
        recommendations: [
          'À éviter : ${lunar.abstainEvent!.label.toLowerCase()}.',
          'Les jeunes plants n\'enracinent pas correctement.',
        ],
      );
    }

    // Météo bloquante.
    if (w.gardenWide == _WeatherSeverity.block &&
        (w.temp < 5 || w.minTempTonight < 0 || w.temp > 32)) {
      return ActivityVerdict(
        status: GardenStatus.bad,
        label: w.temp > 32 ? 'Trop chaud' : 'Trop froid',
        source: GardenVerdictSource.weather,
        recommendations: [
          '✗ ${w.gardenWideReason ?? "Conditions extrêmes"} — choc thermique.',
          if (w.temp > 32) '• Reportez au matin / soir.'
          else '• Restez en serre / sous abri.',
        ],
      );
    }

    if (w.wind > 40) {
      return ActivityVerdict(
        status: GardenStatus.bad,
        label: 'Vent trop fort',
        source: GardenVerdictSource.weather,
        recommendations: [
          '✗ Vent à ${w.wind.round()} km/h — plants déshydratés et arrachés.',
        ],
      );
    }

    if (w.precip > 5 || w.totalPrecip24h > 15) {
      return const ActivityVerdict(
        status: GardenStatus.warning,
        label: 'Sol détrempé',
        source: GardenVerdictSource.weather,
        recommendations: [
          '• Sol gorgé d\'eau — attendez qu\'il ressuie.',
          '• Le repiquage en boue compacte mal autour des racines.',
        ],
      );
    }

    // Base lunaire.
    final dayType = lunar.dayType;
    if (!lunar.isAscending) {
      // Lune descendante = idéal pour repiquer.
      final crops = _plantingCropsFor(dayType);
      return ActivityVerdict(
        status: GardenStatus.good,
        label: 'Idéal — ${dayType.label.toLowerCase()}',
        source: GardenVerdictSource.lunar,
        recommendations: [
          '✓ Lune descendante : la sève redescend, les racines prennent.',
          '✓ Jour ${dayType.plantText} : $crops',
          if (w.maxPrecipProb > 50)
            '✓ Pluie prévue — arrosage naturel post-repiquage.',
          if (w.gardenWide == _WeatherSeverity.caution)
            '• Météo : ${w.gardenWideReason ?? "à surveiller"}.',
        ],
      );
    }

    // Lune montante + jour adapté → repiquage acceptable
    return ActivityVerdict(
      status: GardenStatus.warning,
      label: 'Moins favorable',
      source: GardenVerdictSource.lunar,
      recommendations: [
        '• Lune montante : préférez aujourd\'hui les semis.',
        '• Repiquage possible, mais reprise plus lente.',
        '• Idéal dans ~7 jours quand la lune redescendra.',
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // RÉCOLTE — fruits en lune montante, racines en descendante.
  // ─────────────────────────────────────────────────────────────────────
  ActivityVerdict _evaluateHarvest(LunarDay lunar, _WeatherEval w) {
    if (lunar.isAbstainDay) {
      return ActivityVerdict(
        status: GardenStatus.warning,
        label: lunar.abstainEvent!.label,
        source: GardenVerdictSource.lunar,
        recommendations: [
          '• ${lunar.abstainEvent!.label} : la récolte se conserve mal.',
          '• Récoltez seulement en consommation immédiate.',
        ],
      );
    }

    // Sol mouillé / récolte humide pourrit.
    if (w.precip > 3 || w.humidity > 90) {
      return const ActivityVerdict(
        status: GardenStatus.warning,
        label: 'Trop humide',
        source: GardenVerdictSource.weather,
        recommendations: [
          '• Récolte humide = conservation plus courte (pourriture).',
          '• Attendez quelques heures de soleil.',
        ],
      );
    }

    if (w.temp > 32) {
      return const ActivityVerdict(
        status: GardenStatus.warning,
        label: 'Récoltez tôt',
        source: GardenVerdictSource.weather,
        recommendations: [
          '• Récoltez avant 10h ou après 18h — sinon plants stressés.',
        ],
      );
    }

    // Base lunaire.
    final dayType = lunar.dayType;
    if (lunar.isAscending) {
      final what = dayType == LunarDayType.fruit
          ? 'tomates, courgettes, fruits, graines à conserver'
          : dayType == LunarDayType.flower
              ? 'fleurs coupées, brocolis, choux-fleurs'
              : dayType == LunarDayType.leaf
                  ? 'salades, épinards, herbes aromatiques'
                  : 'récolte ponctuelle (les racines préfèrent la lune descendante)';
      return ActivityVerdict(
        status: GardenStatus.good,
        label: 'Bon — pleine vitalité',
        source: GardenVerdictSource.lunar,
        recommendations: [
          '✓ Lune montante : maximum de sève et de saveur.',
          '✓ Jour ${dayType.plantText} : $what.',
        ],
      );
    } else {
      final what = dayType == LunarDayType.root
          ? 'carottes, pommes de terre, betteraves'
          : 'récolte de conservation (longue garde)';
      return ActivityVerdict(
        status: GardenStatus.good,
        label: 'Bon — pour conservation',
        source: GardenVerdictSource.lunar,
        recommendations: [
          '✓ Lune descendante : moins d\'eau dans les fruits, meilleure garde.',
          '✓ Jour ${dayType.plantText} : $what.',
        ],
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // ARROSAGE — essentiellement météo. Lune influe peu, sauf à éviter
  // arrosage en pleine lune (excès d'eau accentué).
  // ─────────────────────────────────────────────────────────────────────
  ActivityVerdict _evaluateWatering(LunarDay lunar, _WeatherEval w) {
    if (w.precip > 2 || w.totalPrecip24h > 5) {
      return const ActivityVerdict(
        status: GardenStatus.good,
        label: 'Inutile aujourd\'hui',
        source: GardenVerdictSource.weather,
        recommendations: [
          '✓ La pluie s\'en charge — n\'arrosez pas en double.',
        ],
      );
    }

    if (w.maxPrecipProb > 60) {
      return ActivityVerdict(
        status: GardenStatus.good,
        label: 'Pluie prévue',
        source: GardenVerdictSource.weather,
        recommendations: [
          '✓ Pluie annoncée à ${w.maxPrecipProb}% — reportez l\'arrosage.',
        ],
      );
    }

    if (w.temp > 28 && w.humidity < 50) {
      return const ActivityVerdict(
        status: GardenStatus.warning,
        label: 'Arrosage urgent',
        source: GardenVerdictSource.weather,
        recommendations: [
          '• Forte évaporation : arrosez **ce soir** en profondeur.',
          '• Jamais en plein soleil (gouttes = loupes).',
          '• Paillez pour retenir l\'humidité.',
        ],
      );
    }

    if (w.humidity < 40 && w.precip == 0) {
      return const ActivityVerdict(
        status: GardenStatus.warning,
        label: 'Sol sec',
        source: GardenVerdictSource.weather,
        recommendations: [
          '• Air sec, arrosez le soir pour limiter l\'évaporation.',
        ],
      );
    }

    // Pleine lune : on évite l'arrosage abondant (favorise l'humidité excessive).
    if (lunar.phase == LunarPhase.fullMoon) {
      return const ActivityVerdict(
        status: GardenStatus.good,
        label: 'Modérez',
        source: GardenVerdictSource.lunar,
        recommendations: [
          '✓ Pleine lune : plantes saturées, arrosage modéré suffit.',
        ],
      );
    }

    return const ActivityVerdict(
      status: GardenStatus.good,
      label: 'Selon besoin',
      source: GardenVerdictSource.weather,
      recommendations: [
        '✓ Vérifiez l\'humidité du sol en profondeur (1 doigt enfoncé).',
        '✓ Arrosage le soir de préférence.',
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // VERDICT GLOBAL — synthèse cohérente.
  // ─────────────────────────────────────────────────────────────────────
  _GlobalVerdict _composeGlobal({
    required LunarDay lunar,
    required _WeatherEval weatherEval,
    required ActivityVerdict sowing,
    required ActivityVerdict planting,
    required ActivityVerdict harvest,
    required List<String> alerts,
  }) {
    // 1) Jour d'abstention lunaire → tout est défavorable.
    if (lunar.isAbstainDay) {
      final ev = lunar.abstainEvent!;
      return _GlobalVerdict(
        verdict: ev.label,
        emoji: '🌑',
        scoreLabel: '0/5',
        severity: GardenSeverity.critical,
        headline: '${ev.label} — repos du jardin',
        summary: ev.description,
      );
    }

    // 2) Météo critique → bloque tout.
    if (weatherEval.gardenWide == _WeatherSeverity.block) {
      return _GlobalVerdict(
        verdict: 'Conditions critiques',
        emoji: '⛔',
        scoreLabel: '1/5',
        severity: GardenSeverity.critical,
        headline: weatherEval.gardenWideReason ?? 'Météo extrême',
        summary: 'La lune serait propice mais la météo bloque '
            'toute intervention au jardin.',
      );
    }

    // 3) Verdict de base = activité favorisée par la lune aujourd'hui.
    final dayType = lunar.dayType;
    final isAsc = lunar.isAscending;
    final primaryAction = isAsc ? 'aux semis' : 'au repiquage';
    final exemplarCrop = isAsc
        ? _sowingCropsFor(dayType)
        : _plantingCropsFor(dayType);

    // Calcul du score d'après les activités.
    var score = 0;
    score += _scoreOf(sowing.status);
    score += _scoreOf(planting.status);
    score += _scoreOf(harvest.status);

    final headline =
        '${dayType.label} — favorable $primaryAction ($exemplarCrop)';
    final ascDescLabel = isAsc ? 'montante' : 'descendante';
    final phaseLabel = lunar.phase.label.toLowerCase();

    // Météo en cascade
    final weatherSuffix = weatherEval.gardenWide == _WeatherSeverity.caution
        ? ' Attention : ${weatherEval.gardenWideReason?.toLowerCase()}.'
        : '';

    final summary =
        'Lune $ascDescLabel ($phaseLabel) en ${lunar.constellation.label}.'
        '$weatherSuffix';

    if (weatherEval.gardenWide == _WeatherSeverity.caution || score < 4) {
      return _GlobalVerdict(
        verdict: 'Bonnes conditions',
        emoji: '👍',
        scoreLabel: '${math.min(score + 1, 4)}/5',
        severity: GardenSeverity.good,
        headline: headline,
        summary: summary,
      );
    }

    if (score >= 5) {
      return _GlobalVerdict(
        verdict: 'Excellentes conditions',
        emoji: '🌟',
        scoreLabel: '5/5',
        severity: GardenSeverity.great,
        headline: headline,
        summary: summary,
      );
    }

    return _GlobalVerdict(
      verdict: 'Conditions acceptables',
      emoji: '👌',
      scoreLabel: '3/5',
      severity: GardenSeverity.ok,
      headline: headline,
      summary: summary,
    );
  }

  List<CascadeLayer> _buildCascade(LunarDay lunar, _WeatherEval w) {
    final layers = <CascadeLayer>[];

    // 1. Type de jour
    layers.add(CascadeLayer(
      emoji: lunar.dayType.emoji,
      label: lunar.dayType.label,
      detail: 'Lune en ${lunar.constellation.label} — '
          'favorise les ${lunar.dayType.plantPart}.',
      status: GardenStatus.good,
    ));

    // 2. Montante / descendante
    layers.add(CascadeLayer(
      emoji: lunar.isAscending ? '⬆️' : '⬇️',
      label: lunar.isAscending ? 'Lune montante' : 'Lune descendante',
      detail: lunar.isAscending
          ? 'La sève monte — favorable aux semis et greffes.'
          : 'La sève redescend — favorable au repiquage et au travail du sol.',
      status: GardenStatus.good,
    ));

    // 3. Phase
    layers.add(CascadeLayer(
      emoji: lunar.phase.emoji,
      label: lunar.phase.label,
      detail: lunar.isWaxing
          ? 'Phase croissante : énergie de croissance.'
          : 'Phase décroissante : énergie de consolidation et de conservation.',
      status: GardenStatus.good,
    ));

    // 4. Évènement spécial (veto)
    if (lunar.isAbstainDay) {
      final ev = lunar.abstainEvent!;
      layers.add(CascadeLayer(
        emoji: '⛔',
        label: ev.label,
        detail: ev.description,
        status: GardenStatus.bad,
        isVeto: true,
      ));
    }

    // 5. Météo (veto possible)
    final wStatus = switch (w.gardenWide) {
      _WeatherSeverity.none => GardenStatus.good,
      _WeatherSeverity.caution => GardenStatus.warning,
      _WeatherSeverity.block => GardenStatus.bad,
    };
    layers.add(CascadeLayer(
      emoji: w.gardenWide == _WeatherSeverity.block
          ? '⛔'
          : w.gardenWide == _WeatherSeverity.caution
              ? '⚠️'
              : '🌤️',
      label: 'Météo',
      detail: w.gardenWideReason ??
          'Conditions clémentes — ${w.temp.round()}°C, vent ${w.wind.round()} km/h.',
      status: wStatus,
      isVeto: w.gardenWide == _WeatherSeverity.block,
    ));

    return layers;
  }

  String _sowingCropsFor(LunarDayType type) => switch (type) {
        LunarDayType.root => 'carottes, radis, betteraves, navets',
        LunarDayType.leaf => 'salades, épinards, choux, blettes',
        LunarDayType.flower => 'brocolis, choux-fleurs, artichauts, fleurs',
        LunarDayType.fruit => 'tomates, courgettes, haricots, melons',
      };

  String _plantingCropsFor(LunarDayType type) => switch (type) {
        LunarDayType.root => 'carottes, pommes de terre, oignons (en pleine terre)',
        LunarDayType.leaf => 'salades, choux, poireaux (à repiquer)',
        LunarDayType.flower => 'brocolis, choux-fleurs, vivaces fleuries',
        LunarDayType.fruit => 'tomates, courgettes, aubergines, fraisiers',
      };

  int _scoreOf(GardenStatus status) => switch (status) {
        GardenStatus.good => 2,
        GardenStatus.warning => 1,
        GardenStatus.bad => 0,
      };
}

class _ForecastData {
  final double totalPrecip24h;
  final int maxPrecipProb;

  const _ForecastData({
    required this.totalPrecip24h,
    required this.maxPrecipProb,
  });
}

enum _WeatherSeverity { none, caution, block }

class _WeatherEval {
  final double temp;
  final double minTempTonight;
  final double wind;
  final double precip;
  final double humidity;
  final double uv;
  final int maxPrecipProb;
  final double totalPrecip24h;
  final _WeatherSeverity gardenWide;
  final String? gardenWideReason;
  final List<String> alerts;

  const _WeatherEval({
    required this.temp,
    required this.minTempTonight,
    required this.wind,
    required this.precip,
    required this.humidity,
    required this.uv,
    required this.maxPrecipProb,
    required this.totalPrecip24h,
    required this.gardenWide,
    required this.gardenWideReason,
    required this.alerts,
  });
}

class _GlobalVerdict {
  final String verdict;
  final String emoji;
  final String scoreLabel;
  final GardenSeverity severity;
  final String headline;
  final String summary;

  const _GlobalVerdict({
    required this.verdict,
    required this.emoji,
    required this.scoreLabel,
    required this.severity,
    required this.headline,
    required this.summary,
  });
}

/// Extension utilitaire pour [LunarDayType] (texte naturel).
extension on LunarDayType {
  String get plantText => switch (this) {
        LunarDayType.root => 'racines',
        LunarDayType.leaf => 'feuilles',
        LunarDayType.flower => 'fleurs',
        LunarDayType.fruit => 'fruits',
      };
}
