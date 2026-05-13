import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

/// Sources & méthode du calendrier biodynamique affiché par Jardingue.
///
/// Référence publique de ce qui sous-tend chaque décision pour que
/// l'utilisateur puisse vérifier et faire confiance.
class LunarSourcesSheet extends StatelessWidget {
  const LunarSourcesSheet({super.key});

  static Future<void> show(BuildContext context) => AppBottomSheet.show(
        context: context,
        heightFraction: 0.86,
        child: const LunarSourcesSheet(),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppBottomSheetHandle(),
        const _SheetHeader(),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: const [
              _Section(
                title: 'Méthode',
                child: _BodyText(
                  'Jardingue applique le calendrier biodynamique de '
                  'Maria Thun : on combine la phase synodique, la '
                  'constellation sidérale que traverse la Lune, la '
                  'déclinaison (lune montante / descendante) et les '
                  'évènements spéciaux (nœuds, périgée, apogée). La '
                  'météo locale vient ensuite et peut bloquer une '
                  'activité que la Lune aurait pourtant validée — '
                  'jamais l\'inverse.',
                ),
              ),
              SizedBox(height: 22),
              _Section(
                title: 'Principes',
                child: _PrincipleList(),
              ),
              SizedBox(height: 22),
              _Section(
                title: 'Calcul astronomique',
                child: _AstronomyList(),
              ),
              SizedBox(height: 22),
              _Section(
                title: 'Calendriers de référence',
                child: _CalendarsList(),
              ),
              SizedBox(height: 22),
              _Section(
                title: 'Honnête à dire',
                child: _BodyText(
                  'Les effets de la Lune sur les plantes sont défendus '
                  'depuis 60 ans par Maria Thun mais ne font pas '
                  'consensus scientifique strict. Jardingue applique le '
                  'calendrier tel qu\'il est pratiqué par les '
                  'jardiniers biodynamiques, sans en garantir un effet '
                  'agronomique mesurable. La météo, elle, reste un '
                  'critère objectif.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              PhosphorIcons.bookOpen(PhosphorIconsStyle.duotone),
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sources & méthode',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'D\'où viennent les conseils du jour',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTypography.captionStrong.copyWith(
            color: AppColors.primary,
            letterSpacing: 1.2,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodyMedium.copyWith(
        height: 1.55,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _PrincipleList extends StatelessWidget {
  const _PrincipleList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Principle(
          icon: '🥕',
          title: 'Type de jour (Maria Thun)',
          body:
              'La Lune devant le Taureau, la Vierge ou le Capricorne → '
              'jour racines. Cancer, Scorpion, Poissons → jour feuilles. '
              'Gémeaux, Balance, Verseau → jour fleurs. Bélier, Lion, '
              'Sagittaire → jour fruits.',
        ),
        SizedBox(height: 12),
        _Principle(
          icon: '⬆',
          title: 'Lune montante / descendante',
          body:
              'Calculée sur la déclinaison équatoriale (≠ croissante / '
              'décroissante). Montante = sève qui monte → semis, '
              'greffes, récolte de fruits. Descendante = sève qui '
              'redescend → repiquage, taille, travail du sol.',
        ),
        SizedBox(height: 12),
        _Principle(
          icon: '🌑',
          title: 'Nœud lunaire',
          body:
              'Lorsque la Lune coupe le plan de l\'écliptique, les '
              'végétaux sont perturbés : abstention totale conseillée '
              '(les jardiniers biodynamiques s\'abstiennent ces jours-là).',
        ),
        SizedBox(height: 12),
        _Principle(
          icon: '🌕',
          title: 'Périgée / apogée',
          body:
              'Distance Terre-Lune minimale (périgée) ou maximale '
              '(apogée) : on s\'abstient également de semer ces jours-là, '
              'la croissance est déséquilibrée.',
        ),
        SizedBox(height: 12),
        _Principle(
          icon: '🌤',
          title: 'Météo en veto',
          body:
              'Même quand la Lune dit oui, le gel, un sol détrempé '
              '(>10 mm/24 h), un vent fort (>35 km/h) ou la canicule '
              'bloquent indépendamment. Une seule des deux dimensions '
              'qui dit non suffit.',
        ),
      ],
    );
  }
}

class _Principle extends StatelessWidget {
  final String icon;
  final String title;
  final String body;

  const _Principle({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: AppTypography.bodySmall.copyWith(height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AstronomyList extends StatelessWidget {
  const _AstronomyList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _SourceTile(
          label: 'Jean Meeus, Astronomical Algorithms (2ᵉ éd., 1998)',
          detail:
              'Chapitre 47 — position de la Lune. Formules simplifiées '
              '(~13 termes périodiques), précision ≈ 0,02° en longitude.',
          url:
              'https://www.willbell.com/math/mc1.htm',
        ),
        _SourceTile(
          label: 'SunCalc — Vladimir Agafonkin (MIT)',
          detail:
              'Portage JavaScript des formules Meeus. Notre module '
              'lunaire est dérivé de cette implémentation.',
          url: 'https://github.com/mourner/suncalc',
        ),
        _SourceTile(
          label: 'Open-Meteo',
          detail:
              'Source météo (température, vent, précipitations, '
              'UV, humidité, prévisions 7 jours). Gratuit, sans clé API, '
              'données ICON / GFS.',
          url: 'https://open-meteo.com/',
        ),
      ],
    );
  }
}

class _CalendarsList extends StatelessWidget {
  const _CalendarsList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _SourceTile(
          label: 'Maria Thun Biodynamic Calendar',
          detail:
              'Le calendrier de référence depuis 1962. 60 années '
              'd\'expérimentations sur l\'influence des rythmes '
              'lunaires et planétaires sur les cultures.',
          url:
              'https://www.florisbooks.co.uk/book/Titia-Thun/Maria+Thun+Biodynamic+Calendar/9781782509509',
        ),
        _SourceTile(
          label: 'Biodynamic Association (UK)',
          detail:
              'Présentation officielle des principes du semis biodynamique '
              '(jours racines / feuilles / fleurs / fruits, nœuds).',
          url:
              'https://www.biodynamic.org.uk/the-biodynamic-sowing-and-planting-calendar/',
        ),
        _SourceTile(
          label: 'Terre Vivante — Calendrier lunaire',
          detail:
              'Référence francophone (édité depuis 1980). Synthèse des '
              'pratiques jardinage avec la Lune.',
          url:
              'https://www.terrevivante.org/contenu/calendrier-lunaire/',
        ),
        _SourceTile(
          label: 'Gerbeaud — Calendrier lunaire',
          detail:
              'Calendrier mensuel grand public, illustrant les '
              'mêmes principes (lune montante / descendante, type de jour).',
          url:
              'https://www.gerbeaud.com/jardin/calendrier/calendrier-lunaire.php',
        ),
        _SourceTile(
          label: 'Rustica — Jardiner avec la lune',
          detail:
              'Magazine de jardinage français, applique le calendrier '
              'biodynamique simplifié auquel se réfèrent nos conseils.',
          url: 'https://www.rustica.fr/',
        ),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  final String label;
  final String detail;
  final String url;

  const _SourceTile({
    required this.label,
    required this.detail,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppSpacing.borderRadiusMd,
      onTap: () => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: AppTypography.bodySmall.copyWith(height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                PhosphorIcons.arrowSquareOut(PhosphorIconsStyle.regular),
                size: 18,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
