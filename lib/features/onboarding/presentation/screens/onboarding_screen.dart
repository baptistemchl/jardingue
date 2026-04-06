import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Clé SharedPreferences pour savoir si l'onboarding a été vu.
const _kOnboardingCompleteKey = 'onboarding_complete';

/// Vérifie si l'onboarding doit être affiché.
Future<bool> shouldShowOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool(_kOnboardingCompleteKey) ?? false);
}

/// Marque l'onboarding comme terminé.
Future<void> _completeOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingCompleteKey, true);
}

/// Écran d'onboarding avec 4 pages + page de bienvenue.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _controller = PageController();
  int _currentPage = 0;

  static final _pages = <_OnboardingPageData>[
    _OnboardingPageData(
      icon: PhosphorIcons.plant(PhosphorIconsStyle.fill),
      color: AppColors.primary,
      containerColor: AppColors.primaryContainer,
      title: 'Votre potager',
      subtitle: 'Concevez votre jardin',
      description:
          'Creez et organisez vos parcelles sur mesure. '
          'Placez vos plantes, visualisez votre potager et '
          'gerez plusieurs jardins facilement.',
    ),
    _OnboardingPageData(
      icon: PhosphorIcons.leaf(PhosphorIconsStyle.fill),
      color: AppColors.success,
      containerColor: const Color(0xFFE8F5E9),
      title: 'Catalogue de plantes',
      subtitle: 'Explorez les varietes',
      description:
          'Parcourez des dizaines de plantes avec leurs besoins '
          'en soleil, arrosage et associations. '
          'Trouvez les meilleurs compagnons pour votre potager.',
    ),
    _OnboardingPageData(
      icon: PhosphorIcons.calendar(PhosphorIconsStyle.fill),
      color: AppColors.info,
      containerColor: const Color(0xFFE3F2FD),
      title: 'Calendrier',
      subtitle: 'Planifiez vos saisons',
      description:
          'Suivez les periodes de semis, plantation et recolte. '
          'Ne ratez plus jamais le bon moment grace '
          'aux rappels et au calendrier interactif.',
    ),
    _OnboardingPageData(
      icon: PhosphorIcons.sun(PhosphorIconsStyle.fill),
      color: AppColors.secondary,
      containerColor: const Color(0xFFFFF8E1),
      title: 'Meteo intelligente',
      subtitle: 'Jardinez au bon moment',
      description:
          'Consultez la meteo locale, les phases de lune '
          'et recevez des conseils adaptes pour savoir '
          'quand arroser et quand planter.',
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await _completeOnboarding();
    widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textTertiary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    'Passer',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) => _OnboardingPage(data: _pages[i]),
              ),
            ),

            // Dots + bouton
            Padding(
              padding: EdgeInsets.only(
                left: 32,
                right: 32,
                bottom: bottomPadding + 24,
                top: 16,
              ),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? _pages[_currentPage].color
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Bouton principal
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: ElevatedButton(
                        key: ValueKey(_currentPage),
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pages[_currentPage].color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          shadowColor:
                              _pages[_currentPage].color.withValues(alpha: 0.3),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? 'Commencer'
                              : 'Suivant',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Données d'une page d'onboarding.
class _OnboardingPageData {
  final IconData icon;
  final Color color;
  final Color containerColor;
  final String title;
  final String subtitle;
  final String description;

  const _OnboardingPageData({
    required this.icon,
    required this.color,
    required this.containerColor,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}

/// Une page d'onboarding individuelle.
class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône avec cercles décoratifs
          _AnimatedIcon(data: data),
          const SizedBox(height: 48),

          // Titre
          Text(
            data.title,
            style: AppTypography.displayMedium.copyWith(
              color: data.color,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Sous-titre
          Text(
            data.subtitle,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Description
          Text(
            data.description,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Icône animée avec cercles décoratifs en fond.
class _AnimatedIcon extends StatefulWidget {
  final _OnboardingPageData data;

  const _AnimatedIcon({required this.data});

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bounce = Curves.easeInOut.transform(_controller.value) * 8;
        return Transform.translate(
          offset: Offset(0, -bounce),
          child: child,
        );
      },
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Cercle extérieur flou
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.data.color.withValues(alpha: 0.08),
              ),
            ),
            // Cercle intermédiaire
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.data.containerColor,
                border: Border.all(
                  color: widget.data.color.withValues(alpha: 0.15),
                ),
              ),
            ),
            // Icône
            Icon(
              widget.data.icon,
              size: 56,
              color: widget.data.color,
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper widget (identique à celui du nav bar).
class AnimatedBuilder extends AnimatedWidget {
  final TransitionBuilder builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, child);
}
