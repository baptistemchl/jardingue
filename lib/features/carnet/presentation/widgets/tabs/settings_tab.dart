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
/// écrans premium / cloud / à propos, et un pied de page avec
/// version + remerciements.
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
        _KraftCard(
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
                const _KraftDivider(),
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
        _KraftCard(
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
              const _KraftDivider(),
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
        color: AppColors.kraftInk.withValues(alpha: 0.6),
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _KraftCard extends StatelessWidget {
  final Widget child;
  const _KraftCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kraftPaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.kraftLine.withValues(alpha: 0.4),
        ),
      ),
      child: child,
    );
  }
}

class _KraftDivider extends StatelessWidget {
  const _KraftDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 1,
        color: AppColors.kraftLine.withValues(alpha: 0.3),
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
                    color: AppColors.kraftInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.kraftInk.withValues(alpha: 0.65),
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
            activeTrackColor: AppColors.kraftTab,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.kraftLine,
            trackOutlineColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.kraftTab;
              }
              return AppColors.kraftLine;
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
                color: AppColors.kraftTab.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.kraftTab),
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
                      color: AppColors.kraftInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.kraftInk.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
              size: 16,
              color: AppColors.kraftInk.withValues(alpha: 0.5),
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
        Icon(
          PhosphorIcons.heart(PhosphorIconsStyle.fill),
          size: 22,
          color: AppColors.kraftTab,
        ),
        const SizedBox(height: 10),
        Text(
          loc.carnetSettingsThanksMessage,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.kraftInk,
            fontStyle: FontStyle.italic,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          loc.aboutVersion(AppInfo.version),
          style: AppTypography.caption.copyWith(
            color: AppColors.kraftInk.withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
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
                color: AppColors.kraftTab,
              ),
              const SizedBox(width: 6),
              Text(
                loc.aboutInstagram,
                style: AppTypography.caption.copyWith(
                  color: AppColors.kraftTab,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.kraftTab,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
