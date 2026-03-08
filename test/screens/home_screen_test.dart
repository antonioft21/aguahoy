import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aguahoy/screens/home/home_screen.dart';
import 'package:aguahoy/screens/home/widgets/ml_label.dart';
import 'package:aguahoy/services/storage_service.dart';
import 'package:aguahoy/main.dart';
import 'package:aguahoy/core/constants.dart';
import 'package:aguahoy/core/theme.dart';

void main() {
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
  });

  Widget createTestApp() {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: MaterialApp(
        theme: AguaTheme.lightTheme(),
        home: const HomeScreen(),
      ),
    );
  }

  testWidgets('shows MlLabel with initial values', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    // MlLabel uses RichText, so verify the widget exists with correct props
    final mlLabel = tester.widget<MlLabel>(find.byType(MlLabel));
    expect(mlLabel.currentMl, 0);
    expect(mlLabel.goalMl, 2000);
  });

  testWidgets('shows 0% initially', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('tapping Vaso preset adds drink and updates MlLabel', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    // Find the "Vaso" preset button text and tap it
    final vasoButton = find.text('Vaso\n250ml');
    await tester.tap(vasoButton);
    await tester.pumpAndSettle();

    final mlLabel = tester.widget<MlLabel>(find.byType(MlLabel));
    expect(mlLabel.currentMl, 250);
  });

  testWidgets('shows AguaHoy title', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    expect(find.text('AguaHoy'), findsOneWidget);
  });

  testWidgets('has history and settings nav buttons', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.history), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
