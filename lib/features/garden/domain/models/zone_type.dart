/// Types de zones speciales dans un potager.
enum ZoneType {
  greenhouse('Serre', '\u{1F3E0}', 0xFFFF9800),
  path('Allee', '\u{1F6B6}', 0xFF607D8B),
  water('Point d\'eau', '\u{1F4A7}', 0xFF03A9F4),
  compost('Compost', '\u{267B}\u{FE0F}', 0xFF795548),
  storage('Rangement', '\u{1F4E6}', 0xFF9E9E9E);

  final String label;
  final String emoji;
  final int color;

  const ZoneType(this.label, this.emoji, this.color);

  static ZoneType? fromName(String? name) {
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
