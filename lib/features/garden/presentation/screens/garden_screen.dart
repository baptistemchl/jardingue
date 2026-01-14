import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jardingue/features/garden/presentation/widgets/smart_weather_card.dart';
import 'package:jardingue/features/orchard/presentation/widgets/orchard_container.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/garden_providers.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../router/app_router.dart';
import 'garden_create_screen.dart';

const double kNavBarHeight = 100.0;

// ============================================
// BACKGROUND DÉCORATIF - RONDS ÉPARS
// ============================================

class _DecorativeBackground extends StatelessWidget {
  const _DecorativeBackground();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.background,
      child: CustomPaint(
        size: size,
        painter: _OrganicBlobsPainter(
          primaryColor: AppColors.primary,
          primaryLightColor: AppColors.primaryContainer,
        ),
      ),
    );
  }
}

class _OrganicBlobsPainter extends CustomPainter {
  final Color primaryColor;
  final Color primaryLightColor;

  _OrganicBlobsPainter({
    required this.primaryColor,
    required this.primaryLightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Ronds verts foncés (primary)
    final darkPaint = Paint()..style = PaintingStyle.fill;

    // Ronds verts clairs (primaryContainer)
    final lightPaint = Paint()..style = PaintingStyle.fill;

    // === COIN HAUT DROITE ===
    // Grand rond vert clair
    lightPaint.color = primaryLightColor.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(size.width + 20, -30), 120, lightPaint);

    // Rond vert foncé moyen
    darkPaint.color = primaryColor.withValues(alpha: 0.15);
    canvas.drawCircle(Offset(size.width - 40, 60), 45, darkPaint);

    // Petit rond vert clair
    lightPaint.color = primaryLightColor.withValues(alpha: 0.4);
    canvas.drawCircle(Offset(size.width - 20, 130), 25, lightPaint);

    // === COIN HAUT GAUCHE ===
    // Rond moyen vert clair
    lightPaint.color = primaryLightColor.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(-30, 80), 55, lightPaint);

    // Petit rond vert foncé
    darkPaint.color = primaryColor.withValues(alpha: 0.12);
    canvas.drawCircle(Offset(40, 50), 20, darkPaint);

    // === MILIEU GAUCHE ===
    // Grand rond vert clair
    lightPaint.color = primaryLightColor.withValues(alpha: 0.3);
    canvas.drawCircle(Offset(-60, size.height * 0.4), 90, lightPaint);

    // Petit rond vert foncé
    darkPaint.color = primaryColor.withValues(alpha: 0.1);
    canvas.drawCircle(Offset(25, size.height * 0.35), 18, darkPaint);

    // === MILIEU DROITE ===
    // Rond moyen vert clair
    lightPaint.color = primaryLightColor.withValues(alpha: 0.25);
    canvas.drawCircle(
      Offset(size.width + 30, size.height * 0.5),
      70,
      lightPaint,
    );

    // Petit rond vert foncé
    darkPaint.color = primaryColor.withValues(alpha: 0.08);
    canvas.drawCircle(
      Offset(size.width - 35, size.height * 0.45),
      15,
      darkPaint,
    );

    // === BAS GAUCHE ===
    // Grand rond vert clair
    lightPaint.color = primaryLightColor.withValues(alpha: 0.4);
    canvas.drawCircle(Offset(-50, size.height * 0.75), 100, lightPaint);

    // Rond moyen vert foncé
    darkPaint.color = primaryColor.withValues(alpha: 0.12);
    canvas.drawCircle(Offset(50, size.height * 0.8), 35, darkPaint);

    // Petit rond vert clair
    lightPaint.color = primaryLightColor.withValues(alpha: 0.3);
    canvas.drawCircle(Offset(20, size.height * 0.7), 22, lightPaint);

    // === BAS DROITE ===
    // Rond moyen vert clair
    lightPaint.color = primaryLightColor.withValues(alpha: 0.35);
    canvas.drawCircle(
      Offset(size.width + 40, size.height * 0.85),
      80,
      lightPaint,
    );

    // Petit rond vert foncé
    darkPaint.color = primaryColor.withValues(alpha: 0.1);
    canvas.drawCircle(
      Offset(size.width - 50, size.height * 0.9),
      25,
      darkPaint,
    );

    // === PETITS RONDS DISPERSÉS ===
    // Quelques petits ronds pour remplir subtilement
    darkPaint.color = primaryColor.withValues(alpha: 0.06);
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.15),
      12,
      darkPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.3),
      10,
      darkPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.55),
      8,
      darkPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.65),
      14,
      darkPaint,
    );

    lightPaint.color = primaryLightColor.withValues(alpha: 0.2);
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.2),
      16,
      lightPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.6),
      12,
      lightPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.75),
      10,
      lightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gardensAsync = ref.watch(gardensListProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background décoratif
          const _DecorativeBackground(),

          // Contenu principal
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                // Header avec logo et titre
                SliverToBoxAdapter(
                  child: Padding(
                    padding: AppSpacing.screenPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.md),

                        // Logo + Nom app
                        Row(
                          children: [
                            // Logo de l'application
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/icon/app_icon.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Nom de l'app
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Jardingue',
                                  style: AppTypography.titleLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Mon potager connecté',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),

                // Carte météo intelligente
                SliverToBoxAdapter(
                  child: Padding(
                    padding: AppSpacing.horizontalPadding,
                    child: const SmartWeatherCard(),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Section liste des potagers (container unique)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: AppSpacing.horizontalPadding,
                    child: _GardenListContainer(
                      gardensAsync: gardensAsync,
                      onCreateTap: () => _showCreateSheet(context, ref),
                      onGardenTap: (garden) => _openGarden(context, garden),
                      onGardenEdit: (garden) =>
                          _showEditSheet(context, ref, garden),
                      onGardenDelete: (garden) =>
                          _confirmDelete(context, ref, garden),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Section verger
                SliverPadding(
                  padding: AppSpacing.horizontalPadding,
                  sliver: SliverToBoxAdapter(child: OrchardContainer()),
                ),

                SliverToBoxAdapter(child: SizedBox(height: kNavBarHeight)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // IMPORTANT: Utiliser le rootNavigator pour éviter les conflits avec go_router
      useRootNavigator: true,
      builder: (_) => GardenCreateScreen(
        onSaved: () {
          // Invalider le provider pour rafraîchir la liste
          ref.invalidate(gardensListProvider);
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, Garden garden) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // IMPORTANT: Utiliser le rootNavigator pour éviter les conflits avec go_router
      useRootNavigator: true,
      builder: (_) => GardenCreateScreen(
        garden: garden,
        onSaved: () {
          // Invalider le provider pour rafraîchir la liste
          ref.invalidate(gardensListProvider);
        },
      ),
    );
  }

  void _openGarden(BuildContext context, Garden garden) {
    // Utiliser GoRouter pour naviguer vers l'éditeur
    context.push('${AppRoutes.garden}/editor/${garden.id}');
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Garden garden) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le potager ?'),
        content: Text('Voulez-vous supprimer "${garden.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(gardenNotifierProvider.notifier)
                  .deleteGarden(garden.id);
              ref.invalidate(gardensListProvider);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ============================================
// CONTAINER LISTE DES POTAGERS (TOUT EN UN)
// ============================================

class _GardenListContainer extends StatelessWidget {
  final AsyncValue<List<Garden>> gardensAsync;
  final VoidCallback onCreateTap;
  final void Function(Garden) onGardenTap;
  final void Function(Garden) onGardenEdit;
  final void Function(Garden) onGardenDelete;

  const _GardenListContainer({
    required this.gardensAsync,
    required this.onCreateTap,
    required this.onGardenTap,
    required this.onGardenEdit,
    required this.onGardenDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
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
                    PhosphorIcons.squaresFour(PhosphorIconsStyle.duotone),
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
                        'Mes potagers',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getSubtitle(),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: AppColors.border),

          // Contenu
          gardensAsync.when(
            data: (gardens) {
              if (gardens.isEmpty) {
                return _EmptyContent(onCreateTap: onCreateTap);
              }
              return _GardensList(
                gardens: gardens,
                onCreateTap: onCreateTap,
                onGardenTap: onGardenTap,
                onGardenEdit: onGardenEdit,
                onGardenDelete: onGardenDelete,
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text('Erreur: $e')),
            ),
          ),
        ],
      ),
    );
  }

  String _getSubtitle() {
    return gardensAsync.maybeWhen(
      data: (gardens) {
        if (gardens.isEmpty) return 'Aucun potager créé';
        if (gardens.length == 1) return '1 potager';
        return '${gardens.length} potagers';
      },
      orElse: () => 'Chargement...',
    );
  }
}

class _EmptyContent extends StatelessWidget {
  final VoidCallback onCreateTap;

  const _EmptyContent({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.plant(PhosphorIconsStyle.duotone),
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun potager',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Créez votre premier potager pour commencer',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _CreateButton(onTap: onCreateTap),
          ],
        ),
      ),
    );
  }
}

class _GardensList extends StatelessWidget {
  final List<Garden> gardens;
  final VoidCallback onCreateTap;
  final void Function(Garden) onGardenTap;
  final void Function(Garden) onGardenEdit;
  final void Function(Garden) onGardenDelete;

  const _GardensList({
    required this.gardens,
    required this.onCreateTap,
    required this.onGardenTap,
    required this.onGardenEdit,
    required this.onGardenDelete,
  });

  // Convertir les cellules en mètres
  String _formatDimensions(Garden garden) {
    final widthMeters = (garden.widthCells * garden.cellSizeCm) / 100;
    final heightMeters = (garden.heightCells * garden.cellSizeCm) / 100;
    return '${widthMeters.toStringAsFixed(1)} m × ${heightMeters.toStringAsFixed(1)} m';
  }

  // Calculer la surface en m²
  String _formatSurface(Garden garden) {
    final surface =
        (garden.widthCells *
            garden.cellSizeCm *
            garden.heightCells *
            garden.cellSizeCm) /
            10000;
    return '${surface.toStringAsFixed(1)} m²';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Liste des potagers
        ...gardens.map(
              (garden) => Column(
            children: [
              InkWell(
                onTap: () => onGardenTap(garden),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      // Icône du jardin
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('🌱', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Infos du jardin
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nom du jardin
                            Text(
                              garden.name,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),

                            // Infos avec emojis
                            Row(
                              children: [
                                // Dimensions
                                _GardenInfoChip(
                                  emoji: '📐',
                                  label: _formatDimensions(garden),
                                ),
                                const SizedBox(width: 10),
                                // Surface
                                _GardenInfoChip(
                                  emoji: '📏',
                                  label: _formatSurface(garden),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Menu options
                      PopupMenuButton<String>(
                        icon: Icon(
                          PhosphorIcons.dotsThreeVertical(
                            PhosphorIconsStyle.bold,
                          ),
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'edit') onGardenEdit(garden);
                          if (value == 'delete') onGardenDelete(garden);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  PhosphorIcons.pencil(
                                    PhosphorIconsStyle.regular,
                                  ),
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 10),
                                const Text('Modifier'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  PhosphorIcons.trash(
                                    PhosphorIconsStyle.regular,
                                  ),
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Supprimer',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (gardens.last != garden)
                Divider(
                  height: 1,
                  color: AppColors.border,
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          ),
        ),

        // Bouton créer en bas
        Divider(height: 1, color: AppColors.border),
        InkWell(
          onTap: onCreateTap,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIcons.plus(PhosphorIconsStyle.bold),
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Créer un potager',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Petit chip d'info pour les jardins
class _GardenInfoChip extends StatelessWidget {
  final String emoji;
  final String label;

  const _GardenInfoChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ============================================
// BOUTON CRÉER
// ============================================

class _CreateButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.plus(PhosphorIconsStyle.bold),
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              'Créer mon premier potager',
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}