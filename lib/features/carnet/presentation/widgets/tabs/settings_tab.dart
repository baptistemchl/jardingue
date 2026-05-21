import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_info.dart';
import '../../../../../core/services/preferences/user_guidance_preferences.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../router/app_router.dart';
import '../../providers/carnet_ui_providers.dart';

/// Onglet « Réglages » du Carnet de bord.
///
/// Regroupe les préférences (toggles guidance), des liens vers les
/// écrans premium / à propos, et un pied de page avec version +
/// remerciements. Palette Jardingue (vert sauge + accents jaune).
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final prefsAsync = ref.watch(userGuidancePreferencesProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _SectionHeader(label: loc.settingsGuidanceSectionTitle),
        const SizedBox(height: 8),
        _CarnetCard(
          child: prefsAsync.when(
            data: (prefs) => Column(
              children: [
                _GuidanceRow(
                  title: loc.settingsCompanionSuggestionsTitle,
                  subtitle: loc.settingsCompanionSuggestionsSubtitle,
                  value: prefs.companionSuggestionsEnabled,
                  onChanged: ref
                      .read(userGuidancePreferencesProvider.notifier)
                      .setCompanionSuggestionsEnabled,
                ),
                const _CarnetDivider(),
                _GuidanceRow(
                  title: loc.settingsAntagonistWarningsTitle,
                  subtitle: loc.settingsAntagonistWarningsSubtitle,
                  value: prefs.antagonistWarningsEnabled,
                  onChanged: ref
                      .read(userGuidancePreferencesProvider.notifier)
                      .setAntagonistWarningsEnabled,
                ),
              ],
            ),
            loading: () => const SizedBox(height: 168),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),

        const SizedBox(height: 24),
        _SectionHeader(label: loc.carnetSettingsMoreSection),
        const SizedBox(height: 8),
        _CarnetCard(
          child: Column(
            children: [
              _NavTile(
                icon: PhosphorIcons.cloudArrowUp(PhosphorIconsStyle.regular),
                title: loc.carnetSettingsPremiumTitle,
                subtitle: loc.carnetSettingsPremiumSubtitle,
                onTap: () {
                  ref.read(carnetUiProvider.notifier).close();
                  context.push(AppRoutes.premium);
                },
              ),
              const _CarnetDivider(),
              _NavTile(
                icon: PhosphorIcons.info(PhosphorIconsStyle.regular),
                title: loc.carnetSettingsAboutTitle,
                subtitle: loc.carnetSettingsAboutSubtitle,
                onTap: () {
                  ref.read(carnetUiProvider.notifier).close();
                  context.push(AppRoutes.about);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),
        const _ThanksFooter(),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _CarnetCard extends StatelessWidget {
  final Widget child;
  const _CarnetCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.carnetSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.carnetLine),
      ),
      child: child,
    );
  }
}

class _CarnetDivider extends StatelessWidget {
  const _CarnetDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 1,
        color: AppColors.carnetLine,
      ),
    );
  }
}

class _GuidanceRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _GuidanceRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.border,
            trackOutlineColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primary;
              }
              return AppColors.border;
            }),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThanksFooter extends StatelessWidget {
  const _ThanksFooter();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        // Cœur en accent jaune sur halo vert pâle pour donner du contraste
        // chaleureux avec le reste de la palette verte.
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            PhosphorIcons.heart(PhosphorIconsStyle.fill),
            size: 26,
            color: AppColors.carnetAccent,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          loc.carnetSettingsThanksMessage,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontStyle: FontStyle.italic,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            loc.aboutVersion(AppInfo.version),
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => launchUrl(
            Uri.parse(loc.aboutInstagramUrl),
            mode: LaunchMode.externalApplication,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.instagramLogo(PhosphorIconsStyle.regular),
                size: 13,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                loc.aboutInstagram,
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
