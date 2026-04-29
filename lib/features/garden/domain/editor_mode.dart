/// Mode d'interaction de l'editeur de potager.
///
/// `locked` : la grille est verrouillee, les elements ne peuvent que etre
/// tap pour ouvrir leur sheet d'edition.
/// `move` : drag-and-drop active pour deplacer les elements ; les poignees
/// de redimensionnement sont cachees.
/// `resize` : les poignees de redimensionnement sont visibles ; le drag est
/// desactive pour eviter les conflits de gesture.
enum EditorMode {
  locked,
  move,
  resize,
}

extension EditorModeX on EditorMode {
  bool get canDrag => this == EditorMode.move;
  bool get canResize => this == EditorMode.resize;
  bool get isUnlocked => this != EditorMode.locked;
}
