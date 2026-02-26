import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'app.dart';
import 'hive_registrar.g.dart';
import 'services/storage_service.dart';
import 'services/widget_service.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';

/// Global provider for StorageService so providers can access SharedPreferences.
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only block on what's strictly needed to render the first frame
  await Hive.initFlutter();
  Hive.registerAdapters();

  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);

  tz.initializeTimeZones();

  final container = ProviderContainer(
    overrides: [
      storageServiceProvider.overrideWithValue(storageService),
    ],
  );

  // Launch app immediately — don't wait for slow services
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AguaHoyApp(),
    ),
  );

  // Initialize slow services in parallel after first frame
  Future.wait([
    NotificationService.initialize(),
    WidgetService.initialize(),
    MobileAds.instance.initialize(),
  ]);

  PurchaseService.initialize(container);
}
