import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kCompanionSuggestionsEnabled = 'guidance_companion_suggestions_enabled';
const _kAntagonistWarningsEnabled = 'guidance_antagonist_warnings_enabled';

/// Préférences utilisateur pour les conseils de jardinage (off par défaut).
///
/// - [companionSuggestionsEnabled] : afficher une bottom sheet de compagnons
///   après chaque placement de plante (cf. CompanionSuggestionsSheet).
/// - [antagonistWarningsEnabled] : afficher un AlertDialog de confirmation
///   quand on s'apprête à placer une plante près d'un antagoniste
///   (cf. AntagonistWarningDialog).
class UserGuidancePreferences {
  final bool companionSuggestionsEnabled;
  final bool antagonistWarningsEnabled;

  const UserGuidancePreferences({
    this.companionSuggestionsEnabled = false,
    this.antagonistWarningsEnabled = false,
  });

  UserGuidancePreferences copyWith({
    bool? companionSuggestionsEnabled,
    bool? antagonistWarningsEnabled,
  }) {
    return UserGuidancePreferences(
      companionSuggestionsEnabled:
          companionSuggestionsEnabled ?? this.companionSuggestionsEnabled,
      antagonistWarningsEnabled:
          antagonistWarningsEnabled ?? this.antagonistWarningsEnabled,
    );
  }
}

class UserGuidancePreferencesNotifier
    extends AsyncNotifier<UserGuidancePreferences> {
  @override
  Future<UserGuidancePreferences> build() async {
    final prefs = await SharedPreferences.getInstance();
    return UserGuidancePreferences(
      companionSuggestionsEnabled:
          prefs.getBool(_kCompanionSuggestionsEnabled) ?? false,
      antagonistWarningsEnabled:
          prefs.getBool(_kAntagonistWarningsEnabled) ?? false,
    );
  }

  Future<void> setCompanionSuggestionsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCompanionSuggestionsEnabled, value);
    final current = state.value ?? const UserGuidancePreferences();
    state = AsyncData(current.copyWith(companionSuggestionsEnabled: value));
  }

  Future<void> setAntagonistWarningsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAntagonistWarningsEnabled, value);
    final current = state.value ?? const UserGuidancePreferences();
    state = AsyncData(current.copyWith(antagonistWarningsEnabled: value));
  }
}

final userGuidancePreferencesProvider = AsyncNotifierProvider<
    UserGuidancePreferencesNotifier, UserGuidancePreferences>(
  UserGuidancePreferencesNotifier.new,
);

/// Helper pour lire la préférence de manière synchrone (default false).
/// Utile dans les call sites où on ne peut pas attendre le futur (drag/drop).
extension UserGuidancePreferencesRefX on Ref {
  UserGuidancePreferences readGuidancePrefs() {
    return read(userGuidancePreferencesProvider).value ??
        const UserGuidancePreferences();
  }
}

extension UserGuidancePreferencesWidgetRefX on WidgetRef {
  UserGuidancePreferences readGuidancePrefs() {
    return read(userGuidancePreferencesProvider).value ??
        const UserGuidancePreferences();
  }
}
