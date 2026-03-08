import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../core/constants.dart';

class ThemeNotifier extends StateNotifier<bool> {
  final Ref _ref;

  ThemeNotifier(this._ref) : super(false) {
    final storage = _ref.read(storageServiceProvider);
    state = storage.getBool(SPKeys.darkMode) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final storage = _ref.read(storageServiceProvider);
    await storage.setBool(SPKeys.darkMode, state);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier(ref);
});

/// Accent color index (0=blue, 1=green, etc.)
class AccentNotifier extends StateNotifier<int> {
  final Ref _ref;

  AccentNotifier(this._ref) : super(0) {
    state = _ref.read(storageServiceProvider).accentColorIndex;
  }

  Future<void> setIndex(int index) async {
    state = index;
    await _ref.read(storageServiceProvider).setAccentColorIndex(index);
  }
}

final accentProvider = StateNotifierProvider<AccentNotifier, int>((ref) {
  return AccentNotifier(ref);
});
