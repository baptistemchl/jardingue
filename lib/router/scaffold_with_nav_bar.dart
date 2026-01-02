import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'app_router.dart';

/// Scaffold principal avec navigation bottom bar glassmorphism flottante
class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: const _FloatingGlassNavBar(),
    );
  }
}

class _FloatingGlassNavBar extends StatelessWidget {
  const _FloatingGlassNavBar();

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRoutes.garden)) return 0;
    if (location.startsWith(AppRoutes.plants)) return 1;
    if (location.startsWith(AppRoutes.calendar)) return 2;
    if (location.startsWith(AppRoutes.weather)) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.garden);
        break;
      case 1:
        context.go(AppRoutes.plants);
        break;
      case 2:
        context.go(AppRoutes.calendar);
        break;
      case 3:
        context.go(AppRoutes.weather);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, bottom: bottomPadding + 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Décorations de fond
                const _BackgroundDecorations(),

                // Nav items - centré verticalement
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _AnimatedNavItem(
                        icon: PhosphorIcons.plant(PhosphorIconsStyle.regular),
                        activeIcon: PhosphorIcons.plant(
                          PhosphorIconsStyle.fill,
                        ),
                        label: 'Potager',
                        isSelected: currentIndex == 0,
                        onTap: () => _onTap(context, 0),
                        color: AppColors.primary,
                      ),
                      _AnimatedNavItem(
                        icon: PhosphorIcons.leaf(PhosphorIconsStyle.regular),
                        activeIcon: PhosphorIcons.leaf(PhosphorIconsStyle.fill),
                        label: 'Plantes',
                        isSelected: currentIndex == 1,
                        onTap: () => _onTap(context, 1),
                        color: AppColors.success,
                      ),
                      _AnimatedNavItem(
                        icon: PhosphorIcons.calendar(
                          PhosphorIconsStyle.regular,
                        ),
                        activeIcon: PhosphorIcons.calendar(
                          PhosphorIconsStyle.fill,
                        ),
                        label: 'Calendrier',
                        isSelected: currentIndex == 2,
                        onTap: () => _onTap(context, 2),
                        color: AppColors.info,
                      ),
                      _AnimatedNavItem(
                        icon: PhosphorIcons.sun(PhosphorIconsStyle.regular),
                        activeIcon: PhosphorIcons.sun(PhosphorIconsStyle.fill),
                        label: 'Météo',
                        isSelected: currentIndex == 3,
                        onTap: () => _onTap(context, 3),
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Décorations de fond (petits cercles subtils)
class _BackgroundDecorations extends StatelessWidget {
  const _BackgroundDecorations();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Positioned(
            top: -8,
            left: 20,
            child: _Circle(18, AppColors.primary.withValues(alpha: 0.12)),
          ),
          Positioned(
            bottom: -10,
            left: 80,
            child: _Circle(22, AppColors.secondary.withValues(alpha: 0.15)),
          ),
          Positioned(
            top: -6,
            right: 40,
            child: _Circle(16, AppColors.success.withValues(alpha: 0.12)),
          ),
          Positioned(
            bottom: 6,
            right: 90,
            child: _Circle(10, AppColors.tertiary.withValues(alpha: 0.1)),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;

  const _Circle(this.size, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

/// Item de navigation avec animations
class _AnimatedNavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _AnimatedNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late AnimationController _rotationController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.2,
          end: 0.95,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.95,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
    ]).animate(_bounceController);

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0, end: 0.08),
            weight: 25,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.08, end: -0.08),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: -0.08, end: 0),
            weight: 25,
          ),
        ]).animate(
          CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
        );
  }

  @override
  void didUpdateWidget(_AnimatedNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _bounceController.forward(from: 0);
      _rotationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _bounceController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) => _scaleController.forward();
  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _bounceAnimation,
          _rotationAnimation,
        ]),
        builder: (context, child) {
          final scale = widget.isSelected
              ? _bounceAnimation.value
              : _scaleAnimation.value;
          return Transform.scale(
            scale: scale,
            child: Transform.rotate(
              angle: widget.isSelected ? _rotationAnimation.value : 0,
              child: child,
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSelected ? 10 : 6,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  widget.isSelected ? widget.activeIcon : widget.icon,
                  key: ValueKey(widget.isSelected),
                  size: 18,
                  color: widget.isSelected
                      ? widget.color
                      : AppColors.textTertiary,
                ),
              ),

              // Label animé
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: widget.isSelected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            widget.label,
                            style: AppTypography.caption.copyWith(
                              color: widget.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper widget pour animations
class AnimatedBuilder extends AnimatedWidget {
  final TransitionBuilder builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Listenable animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, child);
}
