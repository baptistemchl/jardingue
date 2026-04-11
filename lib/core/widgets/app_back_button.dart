import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../constants/app_colors.dart';

/// Bouton retour uniforme pour toutes les pages
/// hors bottom navigation.
///
/// Deux variantes :
/// - [AppBackButton.light] : fond blanc translucide,
///   icône sombre — pour fonds colorés/images.
/// - [AppBackButton.dark] : fond noir translucide,
///   icône blanche — pour fonds clairs.
///
/// Utilisation en Positioned dans un Stack ou
/// comme leading d'un AppBar.
class AppBackButton extends StatelessWidget {
  final Color _background;
  final Color _iconColor;

  const AppBackButton._({
    required Color background,
    required Color iconColor,
  })  : _background = background,
        _iconColor = iconColor;

  /// Fond blanc translucide, icône sombre.
  /// Pour pages avec fond coloré (météo, etc.).
  const factory AppBackButton.light() =
      _LightBackButton;

  /// Fond noir translucide, icône blanche.
  /// Pour pages avec fond clair.
  const factory AppBackButton.dark() =
      _DarkBackButton;

  /// Variante adaptative : choisit light ou dark
  /// selon [onDarkBackground].
  factory AppBackButton.adaptive({
    bool onDarkBackground = false,
  }) {
    return onDarkBackground
        ? const AppBackButton.dark()
        : const AppBackButton.light();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.of(context).maybePop(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10,
            sigmaY: 10,
          ),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _background,
              borderRadius:
                  BorderRadius.circular(12),
              border: Border.all(
                color: _iconColor
                    .withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              PhosphorIcons.arrowLeft(
                PhosphorIconsStyle.bold,
              ),
              color: _iconColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _LightBackButton extends AppBackButton {
  const _LightBackButton()
      : super._(
          background: const Color(0x40FFFFFF),
          iconColor: AppColors.textPrimary,
        );
}

class _DarkBackButton extends AppBackButton {
  const _DarkBackButton()
      : super._(
          background: const Color(0x40000000),
          iconColor: Colors.white,
        );
}
