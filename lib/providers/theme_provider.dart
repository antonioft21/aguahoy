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
