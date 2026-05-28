import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../theme/app_typography.dart';
import '../../l10n/generated/app_localizations.dart';

/// Préfixe des clés SharedPreferences pour le suivi du "dismissed". Concaténé
/// avec `pageId` (ex: `page_help_dismissed_orchard`).
const _prefKeyPrefix = 'page_help_dismissed_';

/// Contenu d'une fiche d'aide pour une page. Quatre sections sont
/// obligatoires (Pourquoi / Comment / Quand / Où) pour garantir une
/// expérience homogène entre toutes les pages.
class PageHelp {
  /// Identifiant stable de la page. Utilisé pour la clé SharedPreferences,
  /// ne pas changer après publication sous peine de ré-onboarder tout le
  /// monde.
  final String pageId;

  /// Titre affiché en haut du dialog (ex: "Mon verger").
  final String title;

  /// Emoji d'illustration (ex: "🌳").
  final String emoji;

  final String why;
  final String how;
  final String when;
  final String where;

  const PageHelp({
    required this.pageId,
    required this.title,
    required this.emoji,
    required this.why,
    required this.how,
    required this.when,
    required this.where,
  });
}

/// Affiche immédiatement la fiche d'aide [help]. Utilisé par le bouton "?".
Future<void> showPageHelp(BuildContext context, PageHelp help) {
  return showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _PageHelpDialog(help: help),
  );
}

/// Affiche la fiche [help] uniquement si l'utilisateur ne l'a jamais fermée.
/// Marque la fiche comme vue dès l'ouverture. Appeler depuis l'`initState`
/// d'un écran (via `WidgetsBinding.instance.addPostFrameCallback`).
Future<void> maybeShowPageHelp(BuildContext context, PageHelp help) async {
  final prefs = await SharedPreferences.getInstance();
  final key = '$_prefKeyPrefix${help.pageId}';
  if (prefs.getBool(key) ?? false) return;
  if (!context.mounted) return;
  // Petit délai pour laisser le screen finir son build initial — sinon le
  // dialog se superpose à des animations de transition en cours.
  await Future<void>.delayed(const Duration(milliseconds: 400));
  if (!context.mounted) return;
  await showPageHelp(context, help);
  await prefs.setBool(key, true);
}

/// Pastille "?" à coller dans le header d'une page. Au tap, affiche la
/// fiche d'aide associée. Style : carré arrondi 32×32, `AppColors.info`.
class PageHelpButton extends StatelessWidget {
  final PageHelp help;

  /// Taille du bouton. 32 par défaut (cohérent avec le calendrier
  /// historique), passer 28 pour un header dense.
  final double size;

  const PageHelpButton({super.key, required this.help, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context)!.pageHelpTooltip,
      child: GestureDetector(
        onTap: () => showPageHelp(context, help),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            PhosphorIcons.question(PhosphorIconsStyle.bold),
            size: size * 0.5,
            color: AppColors.info,
          ),
        ),
      ),
    );
  }
}

class _PageHelpDialog extends StatelessWidget {
  final PageHelp help;

  const _PageHelpDialog({required this.help});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(help: help),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _Section(
                        emoji: '🎯',
                        label: loc.pageHelpWhy,
                        text: help.why,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 14),
                      _Section(
                        emoji: '🛠️',
                        label: loc.pageHelpHow,
                        text: help.how,
                        color: AppColors.info,
                      ),
                      const SizedBox(height: 14),
                      _Section(
                        emoji: '🗓️',
                        label: loc.pageHelpWhen,
                        text: help.when,
                        color: AppColors.warning,
                      ),
                      const SizedBox(height: 14),
                      _Section(
                        emoji: '📍',
                        label: loc.pageHelpWhere,
                        text: help.where,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    loc.pageHelpDismiss,
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final PageHelp help;

  const _Header({required this.help});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              help.emoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            help.title,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            PhosphorIcons.x(PhosphorIconsStyle.bold),
            size: 18,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String emoji;
  final String label;
  final String text;
  final Color color;

  const _Section({
    required this.emoji,
    required this.label,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
