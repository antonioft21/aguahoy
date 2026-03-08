import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aguahoy/providers/water_provider.dart';
import 'package:aguahoy/services/storage_service.dart';
import 'package:aguahoy/main.dart';
import 'package:aguahoy/core/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late StorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      SPKeys.currentCount: 0,
      SPKeys.dailyGoal: 8,
      SPKeys.glassSizeMl: 250,
      SPKeys.dailyGoalMl: 2000,
      SPKeys.lastResetDate:
          '${DateTime.now().year.toString().padLeft(4, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
    });
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);

    container = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('initial state has count 0, goalMl 2000', () {
    final state = container.read(waterProvider);
    expect(state.currentCount, 0);
    expect(state.goalMl, 2000);
  });

  test('addDrink increments count and ml', () async {
    await container.read(waterProvider.notifier).addDrink(250);
    final state = container.read(waterProvider);
    expect(state.currentCount, 1);
    expect(state.effectiveHydrationMl, 250);
  });

  test('undoLast removes last entry', () async {
    await container.read(waterProvider.notifier).addDrink(250);
    await container.read(waterProvider.notifier).addDrink(250);
    await container.read(waterProvider.notifier).undoLast();
    expect(container.read(waterProvider).currentCount, 1);
  });

  test('undoLast does nothing when empty', () async {
    await container.read(waterProvider.notifier).undoLast();
    expect(container.read(waterProvider).currentCount, 0);
  });

  test('progress calculates correctly', () async {
    // Add 1000ml out of 2000 = 50%
    for (var i = 0; i < 4; i++) {
      await container.read(waterProvider.notifier).addDrink(250);
    }
    final state = container.read(waterProvider);
    expect(state.progress, 0.5);
    expect(state.goalMet, false);
  });

  test('goalMet is true when effectiveMl >= goalMl', () async {
    for (var i = 0; i < 8; i++) {
      await container.read(waterProvider.notifier).addDrink(250);
    }
    expect(container.read(waterProvider).goalMet, true);
    expect(container.read(waterProvider).progress, 1.0);
  });

  test('progress clamps at 1.0 when exceeding goal', () async {
    for (var i = 0; i < 10; i++) {
      await container.read(waterProvider.notifier).addDrink(250);
    }
    expect(container.read(waterProvider).progress, 1.0);
  });

  test('setGoalMl updates goal', () async {
    await container.read(waterProvider.notifier).setGoalMl(2500);
    expect(container.read(waterProvider).goalMl, 2500);
  });

  test('daily reset when lastResetDate is yesterday', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayKey =
        '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    SharedPreferences.setMockInitialValues({
      SPKeys.currentCount: 5,
      SPKeys.dailyGoal: 8,
      SPKeys.glassSizeMl: 250,
      SPKeys.dailyGoalMl: 2000,
      SPKeys.lastResetDate: yesterdayKey,
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);

    final newContainer = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
    );

    // On init, should detect new day and reset
    final state = newContainer.read(waterProvider);
    expect(state.currentCount, 0);

    newContainer.dispose();
  });

  test('reconcileFromWidget picks up widget changes', () async {
    // Simulate widget writing to SharedPreferences
    await storageService.setCurrentCount(3);

    await container.read(waterProvider.notifier).reconcileFromWidget();
    expect(container.read(waterProvider).currentCount, 3);
  });

  test('mlByBeverage provides correct breakdown', () async {
    await container.read(waterProvider.notifier).addDrink(250);
    await container.read(waterProvider.notifier).addDrink(500);
    final state = container.read(waterProvider);
    expect(state.mlByBeverage['water'], 750);
  });
}
