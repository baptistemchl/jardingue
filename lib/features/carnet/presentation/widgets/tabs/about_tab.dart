import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_info.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../l10n/generated/app_localizations.dart';

/// Onglet « À propos » du Carnet de bord.
///
/// Embarque tout le contenu de l'ancienne AboutScreen (logo + version,
/// remerciements, dédicace famille, sources, contact, Instagram,
/// copyright) en palette carnet — pas de navigation, tout est lu sans
/// changer d'écran.
class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const _LogoBlock(),
        const SizedBox(height: 20),
        _ThanksCard(
          title: loc.aboutThanks,
          message: loc.aboutThanksMessage,
        ),
        const SizedBox(height: 12),
        _FamilyCard(
          title: loc.aboutFamilyTitle,
          message: loc.aboutFamilyMessage,
        ),
        const SizedBox(height: 12),
        _SectionCard(
          icon: PhosphorIcons.bookOpen(PhosphorIconsStyle.fill),
          title: loc.aboutSourcesTitle,
          body: loc.aboutSourcesBody,
        ),
        const SizedBox(height: 16),
        const _ContactFooter(),
      ],
    );
  }
}

class _LogoBlock extends StatelessWidget {
  const _LogoBlock();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/icon/app_icon.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          loc.appName,
          style: AppTypography.displaySmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.6),
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
        const SizedBox(height: 6),
        Text(
          loc.aboutSubtitle,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ThanksCard extends StatelessWidget {
  final String title;
  final String message;
  const _ThanksCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.secondary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.heart(PhosphorIconsStyle.fill),
                size: 18,
                color: AppColors.error,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  final String title;
  final String message;
  const _FamilyCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary.withValues(alpha: 0.10),
            AppColors.tertiary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.house(PhosphorIconsStyle.fill),
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.carnetSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.carnetLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactFooter extends StatelessWidget {
  const _ContactFooter();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.carnetSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.carnetLine),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.code(PhosphorIconsStyle.bold),
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  loc.aboutMadeWithLove,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _LinkRow(
            icon: PhosphorIcons.envelope(PhosphorIconsStyle.regular),
            label: loc.aboutContact,
            onTap: () => launchUrl(Uri.parse('mailto:${loc.aboutContact}')),
          ),
          const SizedBox(height: 6),
          _LinkRow(
            icon: PhosphorIcons.instagramLogo(PhosphorIconsStyle.regular),
            label: loc.aboutInstagram,
            onTap: () => launchUrl(
              Uri.parse(loc.aboutInstagramUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.aboutCopyright(DateTime.now().year.toString()),
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
