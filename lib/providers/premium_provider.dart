import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

class PremiumNotifier extends StateNotifier<bool> {
  final Ref _ref;

  PremiumNotifier(this._ref) : super(false) {
    _init();
  }

  void _init() {
    final storage = _ref.read(storageServiceProvider);
    state = storage.isPremium;
  }

  Future<void> setPremium(bool value) async {
    final storage = _ref.read(storageServiceProvider);
    state = value;
    await storage.setIsPremium(value);
  }
}

final premiumProvider =
    StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier(ref);
});
