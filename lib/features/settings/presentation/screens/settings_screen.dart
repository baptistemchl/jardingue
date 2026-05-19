import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/preferences/user_guidance_preferences.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_back_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(userGuidancePreferencesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(
                top: 60,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              children: [
                Text(
                  'Paramètres',
                  style: AppTypography.headlineLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                _SectionHeader(
                  icon: PhosphorIcons.plant(PhosphorIconsStyle.fill),
                  title: 'Conseils de jardinage',
                  subtitle:
                      "Aide-toi des données de compagnonnage et "
                      "d'incompatibilité du catalogue. Désactivé par défaut.",
                ),
                const SizedBox(height: 12),
                prefsAsync.when(
                  data: (prefs) => _GuidanceCard(prefs: prefs),
                  loading: () => const _GuidanceCardSkeleton(),
                  error: (_, _) => _GuidanceCard(
                    prefs: const UserGuidancePreferences(),
                  ),
                ),
              ],
            ),
            const Positioned(
              top: 8,
              left: 12,
              child: AppBackButton.light(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
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
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
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
      ],
    );
  }
}

class _GuidanceCard extends ConsumerWidget {
  final UserGuidancePreferences prefs;

  const _GuidanceCard({required this.prefs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(userGuidancePreferencesProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _GuidanceRow(
            title: 'Suggérer les compagnons au dépôt',
            subtitle:
                "Après chaque plante posée, propose ses plantes "
                "compagnes (à ajouter au panier).",
            value: prefs.companionSuggestionsEnabled,
            onChanged: notifier.setCompanionSuggestionsEnabled,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1),
          ),
          _GuidanceRow(
            title: "Avertir des incompatibilités",
            subtitle:
                "Affiche un avertissement avant de placer une plante "
                "à côté d'un antagoniste connu.",
            value: prefs.antagonistWarningsEnabled,
            onChanged: notifier.setAntagonistWarningsEnabled,
          ),
        ],
      ),
    );
  }
}

class _GuidanceCardSkeleton extends StatelessWidget {
  const _GuidanceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
