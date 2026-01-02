import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/weather_providers.dart';
import '../../../../core/providers/garden_providers.dart';
import '../../../../core/services/weather/weather_models.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../router/app_router.dart';
import '../../../weather/presentation/widgets/weather_animations.dart';
import 'garden_create_screen.dart';
import 'garden_editor_screen.dart';

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
                    child: const _SmartWeatherCard(),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl),
                ),

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
      builder: (_) => GardenCreateScreen(
        onSaved: () {
          ref.invalidate(gardensListProvider);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, Garden garden) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GardenCreateScreen(
        garden: garden,
        onSaved: () {
          ref.invalidate(gardensListProvider);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openGarden(BuildContext context, Garden garden) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GardenEditorScreen(gardenId: garden.id),
      ),
    );
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

// ============================================
// CARTE MÉTÉO INTELLIGENTE
// ============================================

class _SmartWeatherCard extends ConsumerWidget {
  const _SmartWeatherCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherDataProvider);

    // Utiliser .when avec skipLoadingOnRefresh pour gérer proprement les états
    return weatherAsync.when(
      skipLoadingOnRefresh: true,
      data: (weather) => _WeatherCardContent(
        weather: weather,
        onTap: () => context.go(AppRoutes.weather),
      ),
      loading: () => const _WeatherCardSkeleton(),
      error: (error, stack) {
        // Vérifier si c'est vraiment une erreur ou juste un état initial
        // Si l'erreur contient "initial" ou similaire, on affiche le skeleton
        final errorStr = error.toString().toLowerCase();
        final isInitialState =
            errorStr.contains('null') ||
            errorStr.contains('initial') ||
            errorStr.contains('no element');

        if (isInitialState) {
          return const _WeatherCardSkeleton();
        }

        return _WeatherCardError(
          onRetry: () => ref.invalidate(weatherDataProvider),
          errorMessage: error.toString(),
        );
      },
    );
  }
}

class _WeatherCardError extends StatelessWidget {
  final VoidCallback onRetry;
  final String errorMessage;

  const _WeatherCardError({required this.onRetry, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    // Déterminer si c'est une erreur de localisation ou de réseau
    final isLocationError =
        errorMessage.contains('location') ||
        errorMessage.contains('permission') ||
        errorMessage.contains('Location');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLocationError
                ? PhosphorIcons.mapPinLine(PhosphorIconsStyle.duotone)
                : PhosphorIcons.cloudSlash(PhosphorIconsStyle.duotone),
            size: 40,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            isLocationError ? 'Localisation requise' : 'Météo indisponible',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isLocationError
                ? 'Activez la localisation pour voir la météo'
                : 'Impossible de charger les données météo',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(
              PhosphorIcons.arrowClockwise(PhosphorIconsStyle.bold),
              size: 16,
            ),
            label: const Text('Réessayer'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// Skeleton loading pour la météo
// ============================================
// SKELETON LOADING MÉTÉO
// ============================================

class _WeatherCardSkeleton extends StatefulWidget {
  const _WeatherCardSkeleton();

  @override
  State<_WeatherCardSkeleton> createState() => _WeatherCardSkeletonState();
}

class _WeatherCardSkeletonState extends State<_WeatherCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _shimmerController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne 1: Température + condition + icône
              Row(
                children: [
                  _ShimmerBox(
                    width: 75,
                    height: 48,
                    borderRadius: 8,
                    shimmerValue: _shimmerController.value,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShimmerBox(
                          width: 100,
                          height: 14,
                          borderRadius: 4,
                          shimmerValue: _shimmerController.value,
                        ),
                        const SizedBox(height: 8),
                        _ShimmerBox(
                          width: 70,
                          height: 12,
                          borderRadius: 4,
                          shimmerValue: _shimmerController.value,
                        ),
                      ],
                    ),
                  ),
                  _ShimmerBox(
                    width: 48,
                    height: 48,
                    borderRadius: 12,
                    shimmerValue: _shimmerController.value,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Ligne 2: Verdict
              _ShimmerBox(
                width: double.infinity,
                height: 38,
                borderRadius: 12,
                shimmerValue: _shimmerController.value,
              ),

              const SizedBox(height: 14),

              // Ligne 3: 3 indicateurs
              Row(
                children: [
                  Expanded(
                    child: _ShimmerBox(
                      height: 46,
                      borderRadius: 8,
                      shimmerValue: _shimmerController.value,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ShimmerBox(
                      height: 46,
                      borderRadius: 8,
                      shimmerValue: _shimmerController.value,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ShimmerBox(
                      height: 46,
                      borderRadius: 8,
                      shimmerValue: _shimmerController.value,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final double shimmerValue;

  const _ShimmerBox({
    this.width,
    required this.height,
    required this.borderRadius,
    required this.shimmerValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + 2 * shimmerValue, 0),
          end: Alignment(-0.5 + 2 * shimmerValue, 0),
          colors: [
            AppColors.border,
            AppColors.border.withValues(alpha: 0.3),
            AppColors.border,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _WeatherCardContent extends StatelessWidget {
  final WeatherData weather;
  final VoidCallback onTap;

  const _WeatherCardContent({required this.weather, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final analysis = _GardenWeatherAnalysis.fromWeather(weather);
    final condition = weather.current.condition;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(condition.primaryColor).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background animé
              Positioned.fill(child: WeatherBackground(condition: condition)),

              // Contenu
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ligne 1: Température + condition
                    Row(
                      children: [
                        Text(
                          weather.current.temperatureDisplay,
                          style: AppTypography.displayLarge.copyWith(
                            fontSize: 44,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                condition.label,
                                style: AppTypography.labelMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              Text(
                                'Ressenti ${weather.current.feelsLikeDisplay}',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          condition.icon,
                          style: const TextStyle(fontSize: 48),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Ligne 2: Verdict principal
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: analysis.verdictColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: analysis.verdictColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            analysis.verdictEmoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              analysis.verdict,
                              style: AppTypography.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Ligne 3: Indicateurs détaillés
                    Row(
                      children: [
                        _DetailIndicator(
                          icon: '🌡️',
                          label: analysis.tempAdvice,
                          status: analysis.tempStatus,
                        ),
                        const SizedBox(width: 8),
                        _DetailIndicator(
                          icon: '💧',
                          label: analysis.waterAdvice,
                          status: analysis.waterStatus,
                        ),
                        const SizedBox(width: 8),
                        _DetailIndicator(
                          icon: '🌱',
                          label: analysis.plantAdvice,
                          status: analysis.plantStatus,
                        ),
                      ],
                    ),

                    // Ligne 4: Alerte redesignée
                    if (analysis.alert != null) ...[
                      const SizedBox(height: 14),
                      _WeatherAlertBanner(alert: analysis.alert!),
                    ],
                  ],
                ),
              ),

              // Chevron
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                    size: 14,
                    color: Colors.white,
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

// ============================================
// ALERTE MÉTÉO SOBRE MAIS VISIBLE
// ============================================

class _WeatherAlertBanner extends StatelessWidget {
  final String alert;

  const _WeatherAlertBanner({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade800,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade400, width: 1),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              alert,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// INDICATEURS DÉTAILLÉS
// ============================================

class _DetailIndicator extends StatelessWidget {
  final String icon;
  final String label;
  final _IndicatorStatus status;

  const _DetailIndicator({
    required this.icon,
    required this.label,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    switch (status) {
      case _IndicatorStatus.good:
        bgColor = Colors.green.withValues(alpha: 0.3);
        break;
      case _IndicatorStatus.warning:
        bgColor = Colors.orange.withValues(alpha: 0.3);
        break;
      case _IndicatorStatus.bad:
        bgColor = Colors.red.withValues(alpha: 0.3);
        break;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

enum _IndicatorStatus { good, warning, bad }

// ============================================
// ANALYSE MÉTÉO INTELLIGENTE
// ============================================

class _GardenWeatherAnalysis {
  final String verdict;
  final String verdictEmoji;
  final Color verdictColor;
  final String tempAdvice;
  final _IndicatorStatus tempStatus;
  final String waterAdvice;
  final _IndicatorStatus waterStatus;
  final String plantAdvice;
  final _IndicatorStatus plantStatus;
  final String? alert;

  _GardenWeatherAnalysis({
    required this.verdict,
    required this.verdictEmoji,
    required this.verdictColor,
    required this.tempAdvice,
    required this.tempStatus,
    required this.waterAdvice,
    required this.waterStatus,
    required this.plantAdvice,
    required this.plantStatus,
    this.alert,
  });

  factory _GardenWeatherAnalysis.fromWeather(WeatherData weather) {
    final current = weather.current;
    final temp = current.temperature;
    final _ = current.feelsLike;
    final humidity = current.humidity;
    final precipitation = current.precipitation;
    final windSpeed = current.windSpeed;
    final uvIndex = current.uvIndex;

    // Prévisions
    final hourly = weather.hourlyForecast;
    final daily = weather.dailyForecast;

    // Analyse température pour les prochaines heures
    double minTempNext12h = temp;
    double maxTempNext12h = temp;
    double totalPrecipNext12h = precipitation;
    int maxPrecipProb = 0;

    for (int i = 0; i < math.min(12, hourly.length); i++) {
      final h = hourly[i];
      if (h.temperature < minTempNext12h) minTempNext12h = h.temperature;
      if (h.temperature > maxTempNext12h) maxTempNext12h = h.temperature;
      totalPrecipNext12h += h.precipitation;
      if (h.precipitationProbability > maxPrecipProb) {
        maxPrecipProb = h.precipitationProbability;
      }
    }

    // Température min ce soir/nuit (risque gel)
    double minTempTonight = temp;
    if (daily.isNotEmpty) {
      minTempTonight = daily[0].tempMin;
    }

    // === ANALYSE TEMPÉRATURE ===
    String tempAdvice;
    _IndicatorStatus tempStatus;

    if (temp < 0) {
      tempAdvice = 'Gel actif';
      tempStatus = _IndicatorStatus.bad;
    } else if (temp < 5) {
      tempAdvice = 'Trop froid';
      tempStatus = _IndicatorStatus.bad;
    } else if (temp < 10) {
      tempAdvice = 'Frais';
      tempStatus = _IndicatorStatus.warning;
    } else if (temp > 35) {
      tempAdvice = 'Canicule';
      tempStatus = _IndicatorStatus.bad;
    } else if (temp > 30) {
      tempAdvice = 'Très chaud';
      tempStatus = _IndicatorStatus.warning;
    } else if (temp >= 15 && temp <= 25) {
      tempAdvice = 'Idéal';
      tempStatus = _IndicatorStatus.good;
    } else {
      tempAdvice = 'Correct';
      tempStatus = _IndicatorStatus.good;
    }

    // === ANALYSE ARROSAGE ===
    String waterAdvice;
    _IndicatorStatus waterStatus;

    if (precipitation > 0) {
      waterAdvice = 'Pluie en cours';
      waterStatus = _IndicatorStatus.good; // Pas besoin d'arroser
    } else if (totalPrecipNext12h > 2) {
      waterAdvice = 'Pluie prévue';
      waterStatus = _IndicatorStatus.good;
    } else if (maxPrecipProb > 60) {
      waterAdvice = 'Pluie probable';
      waterStatus = _IndicatorStatus.good;
    } else if (temp > 30 && humidity < 40) {
      waterAdvice = 'Arrosez ce soir';
      waterStatus = _IndicatorStatus.warning;
    } else if (humidity < 30) {
      waterAdvice = 'Sol sec';
      waterStatus = _IndicatorStatus.warning;
    } else if (humidity > 80) {
      waterAdvice = 'Sol humide';
      waterStatus = _IndicatorStatus.good;
    } else {
      waterAdvice = 'Normal';
      waterStatus = _IndicatorStatus.good;
    }

    // === ANALYSE PLANTATION ===
    String plantAdvice;
    _IndicatorStatus plantStatus;

    if (temp < 5 || minTempTonight < 2) {
      plantAdvice = 'Évitez';
      plantStatus = _IndicatorStatus.bad;
    } else if (windSpeed > 40) {
      plantAdvice = 'Vent fort';
      plantStatus = _IndicatorStatus.bad;
    } else if (windSpeed > 25) {
      plantAdvice = 'Venteux';
      plantStatus = _IndicatorStatus.warning;
    } else if (precipitation > 5) {
      plantAdvice = 'Trop humide';
      plantStatus = _IndicatorStatus.warning;
    } else if (temp > 30) {
      plantAdvice = 'Trop chaud';
      plantStatus = _IndicatorStatus.warning;
    } else if (temp >= 12 &&
        temp <= 25 &&
        windSpeed < 20 &&
        precipitation < 2) {
      plantAdvice = 'Idéal';
      plantStatus = _IndicatorStatus.good;
    } else {
      plantAdvice = 'Possible';
      plantStatus = _IndicatorStatus.good;
    }

    // === VERDICT GLOBAL ===
    String verdict;
    String verdictEmoji;
    Color verdictColor;
    String? alert;

    // Cas critiques
    if (temp < 0) {
      verdict = 'Gel : protégez vos plants !';
      verdictEmoji = '🥶';
      verdictColor = Colors.blue;
      alert = 'Température négative. Rentrez les plants sensibles.';
    } else if (minTempTonight < 0) {
      verdict = 'Gel prévu cette nuit';
      verdictEmoji = '❄️';
      verdictColor = Colors.blue;
      alert = 'Protégez vos plants sensibles au gel avant ce soir.';
    } else if (temp < 5) {
      verdict = 'Trop froid pour jardiner';
      verdictEmoji = '🧊';
      verdictColor = Colors.blue;
    } else if (temp > 35) {
      verdict = 'Canicule : évitez le jardin';
      verdictEmoji = '🔥';
      verdictColor = Colors.red;
      alert = 'Arrosez tôt le matin ou tard le soir uniquement.';
    } else if (windSpeed > 50) {
      verdict = 'Vent violent : restez à l\'abri';
      verdictEmoji = '💨';
      verdictColor = Colors.orange;
    } else if (precipitation > 10) {
      verdict = 'Fortes pluies en cours';
      verdictEmoji = '🌧️';
      verdictColor = Colors.blue;
    }
    // Cas moyens
    else if (temp > 30) {
      verdict = 'Chaleur : jardinez tôt ou tard';
      verdictEmoji = '☀️';
      verdictColor = Colors.orange;
    } else if (temp < 10) {
      verdict = 'Frais : travaux légers possibles';
      verdictEmoji = '🌥️';
      verdictColor = Colors.orange;
    } else if (precipitation > 2) {
      verdict = 'Pluie légère';
      verdictEmoji = '🌦️';
      verdictColor = Colors.blue;
    } else if (maxPrecipProb > 70) {
      verdict = 'Pluie prévue : reportez l\'arrosage';
      verdictEmoji = '🌧️';
      verdictColor = Colors.blue;
    }
    // Cas favorables
    else if (temp >= 15 &&
        temp <= 25 &&
        windSpeed < 15 &&
        precipitation == 0 &&
        uvIndex < 7) {
      verdict = 'Conditions parfaites !';
      verdictEmoji = '🌟';
      verdictColor = Colors.green;
    } else if (temp >= 12 && temp <= 28 && windSpeed < 25) {
      verdict = 'Bon moment pour jardiner';
      verdictEmoji = '👍';
      verdictColor = Colors.green;
    } else {
      verdict = 'Conditions acceptables';
      verdictEmoji = '👌';
      verdictColor = Colors.green;
    }

    return _GardenWeatherAnalysis(
      verdict: verdict,
      verdictEmoji: verdictEmoji,
      verdictColor: verdictColor,
      tempAdvice: tempAdvice,
      tempStatus: tempStatus,
      waterAdvice: waterAdvice,
      waterStatus: waterStatus,
      plantAdvice: plantAdvice,
      plantStatus: plantStatus,
      alert: alert,
    );
  }
}
