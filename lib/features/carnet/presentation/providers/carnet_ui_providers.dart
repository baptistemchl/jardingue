import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/carnet_tab.dart';

/// État UI du carnet : ouvert/fermé + onglet actif.
class CarnetUiState {
  final bool isOpen;
  final CarnetTab activeTab;

  const CarnetUiState({
    required this.isOpen,
    required this.activeTab,
  });

  CarnetUiState copyWith({bool? isOpen, CarnetTab? activeTab}) {
    return CarnetUiState(
      isOpen: isOpen ?? this.isOpen,
      activeTab: activeTab ?? this.activeTab,
    );
  }
}

class CarnetUiNotifier extends Notifier<CarnetUiState> {
  @override
  CarnetUiState build() {
    return const CarnetUiState(
      isOpen: false,
      activeTab: CarnetTab.harvests,
    );
  }

  void open([CarnetTab? tab]) {
    state = state.copyWith(
      isOpen: true,
      activeTab: tab ?? state.activeTab,
    );
  }

  void close() {
    state = state.copyWith(isOpen: false);
  }

  void toggle() {
    state = state.copyWith(isOpen: !state.isOpen);
  }

  void setTab(CarnetTab tab) {
    state = state.copyWith(activeTab: tab);
  }
}

final carnetUiProvider =
    NotifierProvider<CarnetUiNotifier, CarnetUiState>(CarnetUiNotifier.new);
