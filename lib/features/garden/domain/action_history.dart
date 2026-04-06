import 'package:flutter/foundation.dart';
import '../../../core/providers/garden_providers.dart';

/// Represente une action annulable/refaisable.
abstract class GardenAction {
  Future<void> execute(GardenNotifier notifier);
  Future<void> undo(GardenNotifier notifier);
  String get description;
}

/// Action de deplacement d'un element.
class MoveElementAction extends GardenAction {
  final int elementId;
  final int gardenId;
  final double oldX, oldY;
  final double newX, newY;

  MoveElementAction({
    required this.elementId,
    required this.gardenId,
    required this.oldX,
    required this.oldY,
    required this.newX,
    required this.newY,
  });

  @override
  Future<void> execute(GardenNotifier notifier) async {
    await notifier.moveElement(
      elementId, newX, newY, gardenId,
    );
  }

  @override
  Future<void> undo(GardenNotifier notifier) async {
    await notifier.moveElement(
      elementId, oldX, oldY, gardenId,
    );
  }

  @override
  String get description => 'Deplacement';
}

/// Action de suppression d'un element.
class DeleteElementAction extends GardenAction {
  final int elementId;
  final int gardenId;
  final bool isZone;
  final int? plantId;
  final String zoneType;
  final double xMeters;
  final double yMeters;
  final double widthMeters;
  final double heightMeters;

  DeleteElementAction({
    required this.elementId,
    required this.gardenId,
    required this.isZone,
    required this.plantId,
    required this.zoneType,
    required this.xMeters,
    required this.yMeters,
    required this.widthMeters,
    required this.heightMeters,
  });

  @override
  Future<void> execute(GardenNotifier notifier) async {
    await notifier.removeElement(elementId, gardenId);
  }

  @override
  Future<void> undo(GardenNotifier notifier) async {
    if (isZone) {
      await notifier.addZoneToGarden(
        gardenId: gardenId,
        xMeters: xMeters,
        yMeters: yMeters,
        widthMeters: widthMeters,
        heightMeters: heightMeters,
        zoneType: zoneType,
      );
      return;
    }
    await notifier.addPlantToGarden(
      gardenId: gardenId,
      plantId: plantId!,
      xMeters: xMeters,
      yMeters: yMeters,
      widthMeters: widthMeters,
      heightMeters: heightMeters,
    );
  }

  @override
  String get description => 'Suppression';
}

/// Action de redimensionnement d'un element.
class ResizeElementAction extends GardenAction {
  final int elementId;
  final int gardenId;
  final double oldWidth, oldHeight;
  final double newWidth, newHeight;

  ResizeElementAction({
    required this.elementId,
    required this.gardenId,
    required this.oldWidth,
    required this.oldHeight,
    required this.newWidth,
    required this.newHeight,
  });

  @override
  Future<void> execute(GardenNotifier notifier) async {
    await notifier.updateElementSize(
      elementId, newWidth, newHeight, gardenId,
    );
  }

  @override
  Future<void> undo(GardenNotifier notifier) async {
    await notifier.updateElementSize(
      elementId, oldWidth, oldHeight, gardenId,
    );
  }

  @override
  String get description => 'Redimensionnement';
}

/// Gestionnaire d'historique pour undo/redo.
class ActionHistory extends ChangeNotifier {
  final List<GardenAction> _undoStack = [];
  final List<GardenAction> _redoStack = [];
  static const int maxHistory = 50;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;

  void addAction(GardenAction action) {
    _undoStack.add(action);
    _redoStack.clear();
    if (_undoStack.length > maxHistory) {
      _undoStack.removeAt(0);
    }
    notifyListeners();
  }

  GardenAction? popUndo() {
    if (_undoStack.isEmpty) return null;
    final action = _undoStack.removeLast();
    _redoStack.add(action);
    notifyListeners();
    return action;
  }

  GardenAction? popRedo() {
    if (_redoStack.isEmpty) return null;
    final action = _redoStack.removeLast();
    _undoStack.add(action);
    notifyListeners();
    return action;
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }
}
