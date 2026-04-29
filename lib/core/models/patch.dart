/// Valeur optionnelle pour les mises à jour partielles, sans exposer
/// `drift.Value<T>` aux couches supérieures (repo, notifier, UI).
///
/// - `Patch<T>.absent()` : ne pas modifier le champ.
/// - `Patch<T>(v)` : écrire `v` (peut être `null` si `T` est nullable).
///
/// La traduction vers `drift.Value<T>` a lieu dans la couche data (repo
/// / database) via `patchToValue`. Aucune autre couche n'a besoin d'importer
/// drift.
class Patch<T> {
  final bool present;
  final T? _value;

  const Patch.absent()
      : present = false,
        _value = null;

  const Patch(T value)
      : present = true,
        _value = value;

  /// Valeur encapsulée. Ne lire que si [present] est vrai.
  T get value {
    if (!present) {
      throw StateError('Patch.value accessed on an absent patch.');
    }
    return _value as T;
  }
}
