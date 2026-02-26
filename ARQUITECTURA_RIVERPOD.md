# Arquitectura Riverpod - AguaHoy

Documento tecnico que explica la arquitectura de estado de la aplicacion **AguaHoy**, basada en [flutter_riverpod](https://pub.dev/packages/flutter_riverpod).

---

## 1. Que es Riverpod?

**Riverpod** es una libreria de gestion de estado para Flutter creada por Remi Rousselet (el mismo autor del paquete `provider`). Es la evolucion de Provider, pero resuelve varias limitaciones fundamentales.

### Por que Riverpod y no setState / Provider / Bloc?

| Alternativa | Limitacion que Riverpod resuelve |
|---|---|
| **setState** | Solo funciona dentro de un widget. No permite compartir estado entre pantallas ni persistirlo facilmente. Escala muy mal. |
| **Provider (clasico)** | Depende del arbol de widgets (`BuildContext`). Si intentas leer un provider fuera del arbol (en un callback, en `main()`, en un test), falla. Ademas tiene problemas de `ProviderNotFoundException` en tiempo de ejecucion. |
| **Bloc** | Requiere mucho boilerplate (eventos, estados, clases separadas). Para una app de tracking de agua es demasiada ceremonia. |
| **Riverpod** | Es **independiente del BuildContext**, se puede usar en `main()`, en tests y en cualquier lugar. Los errores se detectan en **tiempo de compilacion**. Es conciso y flexible. |

En AguaHoy, Riverpod nos permite:

- Inyectar `SharedPreferences` antes de que la app arranque (con `overrides`)
- Compartir el estado del agua entre `HomeScreen`, `SettingsScreen` y el widget nativo de Android
- Testear providers de forma aislada con `ProviderContainer`
- Mezclar estado sincrono (`StateNotifier`) con datos asincronos (`FutureProvider`)

---

## 2. Estructura del proyecto

```
lib/
 |-- main.dart                          # Punto de entrada. Inicializa servicios y crea ProviderContainer
 |-- app.dart                           # MaterialApp con rutas
 |
 |-- core/
 |    |-- constants.dart                # Claves de SharedPreferences (SPKeys), valores por defecto (Defaults), nombres de Hive boxes
 |    |-- date_utils.dart               # Utilidades de fecha (todayKey, parseKey, shortLabel)
 |    |-- theme.dart                    # Tema visual de la app
 |
 |-- models/
 |    |-- day_record.dart               # Modelo Hive para el registro diario (DayRecord)
 |    |-- day_record.g.dart             # Adaptador Hive generado automaticamente
 |
 |-- services/
 |    |-- storage_service.dart          # Wrapper de SharedPreferences (fuente de verdad compartida con widget nativo)
 |    |-- history_service.dart          # CRUD con Hive para historial de dias
 |    |-- widget_service.dart           # Sincronizacion bidireccional Flutter <-> Widget Android nativo
 |    |-- notification_service.dart     # Recordatorios de hidratacion
 |    |-- purchase_service.dart         # Compras in-app (premium)
 |
 |-- providers/
 |    |-- water_provider.dart           # StateNotifierProvider principal: conteo de vasos, meta, tamano
 |    |-- settings_provider.dart        # StateNotifierProvider de ajustes (meta, tamano vaso, recordatorios)
 |    |-- premium_provider.dart         # StateNotifierProvider booleano (es premium o no)
 |    |-- history_provider.dart         # FutureProviders para historial, racha y promedio semanal
 |
 |-- screens/
 |    |-- home/
 |    |    |-- home_screen.dart         # Pantalla principal (ConsumerStatefulWidget)
 |    |    |-- widgets/
 |    |         |-- progress_circle.dart
 |    |         |-- glass_icons_row.dart
 |    |         |-- water_button.dart
 |    |         |-- ml_label.dart
 |    |
 |    |-- history/
 |    |    |-- history_screen.dart      # Historial (ConsumerWidget)
 |    |    |-- widgets/
 |    |         |-- day_bar.dart
 |    |         |-- stats_card.dart
 |    |
 |    |-- settings/
 |         |-- settings_screen.dart     # Ajustes (ConsumerWidget)
 |         |-- widgets/
 |              |-- goal_picker.dart
 |              |-- reminder_config.dart
 |              |-- premium_card.dart
 |
 |-- widgets/
      |-- ad_banner_widget.dart         # Banner de AdMob (se oculta si es premium)
      |-- premium_gate.dart             # CTA para desbloquear premium
```

---

## 3. Providers del proyecto

### 3.1 `storageServiceProvider` - Provider simple

**Archivo:** `lib/main.dart`

```dart
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});
```

Este es un `Provider` simple (de solo lectura). Su funcion es **inyectar** la instancia de `StorageService` (un wrapper de `SharedPreferences`) en el arbol de providers.

**Truco clave:** Se declara con `throw UnimplementedError` porque **siempre** se sobreescribe con un `override` en `main()`:

```dart
final container = ProviderContainer(
  overrides: [
    storageServiceProvider.overrideWithValue(storageService),
  ],
);
```

Esto funciona porque `SharedPreferences.getInstance()` es asincrono y necesita ejecutarse **antes** de que Riverpod construya cualquier provider. Al crearlo como override, todos los demas providers pueden leerlo sincronamente con `ref.read(storageServiceProvider)`.

**StorageService** (`lib/services/storage_service.dart`) expone getters y setters para todas las claves de SharedPreferences:

```dart
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  int get currentCount => _prefs.getInt(SPKeys.currentCount) ?? 0;
  Future<void> setCurrentCount(int count) async {
    await _prefs.setInt(SPKeys.currentCount, count);
  }

  bool needsDailyReset() {
    final last = lastResetDate;
    return last != AppDateUtils.todayKey();
  }
  // ... mas getters/setters
}
```

Las claves de SharedPreferences estan centralizadas en `SPKeys` (`lib/core/constants.dart`) y son **compartidas con el widget nativo de Android** (Kotlin). Cualquier cambio en estas claves debe reflejarse en `WaterWidgetProvider.kt`.

---

### 3.2 `waterProvider` - StateNotifierProvider (el mas importante)

**Archivo:** `lib/providers/water_provider.dart`

Este es el corazon de la app. Gestiona el conteo de vasos de agua del dia actual.

#### WaterState (el estado)

```dart
class WaterState {
  final int currentCount;   // Vasos bebidos hoy
  final int dailyGoal;      // Meta diaria en vasos
  final int glassSizeMl;    // Tamano de cada vaso en ml

  // Propiedades derivadas (computed):
  int get currentMl => currentCount * glassSizeMl;          // ml totales bebidos
  int get goalMl => dailyGoal * glassSizeMl;                // meta en ml
  double get progress =>                                     // 0.0 a 1.0
      dailyGoal > 0 ? (currentCount / dailyGoal).clamp(0.0, 1.0) : 0.0;
  bool get goalMet => currentCount >= dailyGoal;            // meta cumplida?

  WaterState copyWith({...});  // Patron inmutable
}
```

El estado es **inmutable** (usa `copyWith`). Esto es fundamental: cada vez que cambia algo, se crea un nuevo `WaterState`, lo que provoca que todos los widgets suscritos se reconstruyan.

#### WaterNotifier (la logica)

```dart
class WaterNotifier extends StateNotifier<WaterState> {
  final Ref _ref;
  final HistoryService _historyService = HistoryService();

  WaterNotifier(this._ref) : super(const WaterState(
    currentCount: 0, dailyGoal: 8, glassSizeMl: 250,
  )) {
    _init();
  }
```

**Inicializacion (`_init`):**

1. Lee `StorageService` para obtener los valores persistidos
2. Comprueba si hay que hacer un **reset diario** (nuevo dia)
3. Establece el estado inicial con los datos de SharedPreferences

**Metodos principales:**

| Metodo | Que hace |
|---|---|
| `addGlass()` | Incrementa `currentCount`, persiste en SharedPreferences, sincroniza con widget nativo |
| `removeGlass()` | Decrementa (sin bajar de 0), persiste, sincroniza |
| `setGoal(int)` | Cambia la meta diaria |
| `setGlassSize(int)` | Cambia el tamano del vaso |
| `reconcileFromWidget()` | Lee SharedPreferences por si el widget nativo escribio un valor diferente |
| `_performDailyReset()` | Guarda el dia anterior en el historial (Hive), resetea contador a 0 |

**Ejemplo de `addGlass()`:**

```dart
Future<void> addGlass() async {
  final storage = _ref.read(storageServiceProvider);
  final newCount = state.currentCount + 1;
  state = state.copyWith(currentCount: newCount);   // 1. Actualiza estado (UI se reconstruye)
  await storage.setCurrentCount(newCount);            // 2. Persiste en SharedPreferences
  await _syncWidget();                                // 3. Sincroniza con widget Android nativo
}
```

**Reset diario (`_performDailyReset`):**

```dart
void _performDailyReset(dynamic storage) {
  final lastDate = storage.lastResetDate;
  final previousCount = storage.currentCount;

  // 1. Guarda el dia anterior en el historial de Hive
  if (lastDate != null && previousCount > 0) {
    _historyService.saveDay(DayRecord(
      dateKey: lastDate,
      glasses: previousCount,
      goalGlasses: storage.dailyGoal,
      glassSizeMl: storage.glassSizeMl,
    )).catchError((_) {});
  }

  // 2. Resetea el contador a 0
  storage.setCurrentCount(0);
  storage.setLastResetDate(AppDateUtils.todayKey());

  // 3. Sincroniza el widget nativo
  _trySyncWidget(currentCount: 0, dailyGoal: storage.dailyGoal, glassSizeMl: storage.glassSizeMl);
}
```

**Declaracion del provider:**

```dart
final waterProvider = StateNotifierProvider<WaterNotifier, WaterState>((ref) {
  return WaterNotifier(ref);
});
```

Los tipos genericos `<WaterNotifier, WaterState>` le dicen a Riverpod:
- El notifier es `WaterNotifier` (accesible via `ref.read(waterProvider.notifier)`)
- El estado expuesto es `WaterState` (accesible via `ref.watch(waterProvider)`)

---

### 3.3 `settingsProvider` - StateNotifierProvider

**Archivo:** `lib/providers/settings_provider.dart`

Gestiona los ajustes del usuario: meta diaria, tamano de vaso y configuracion de recordatorios.

#### SettingsState

```dart
class SettingsState {
  final int dailyGoal;            // Meta en vasos
  final int glassSizeMl;          // Tamano del vaso
  final bool remindersEnabled;    // Recordatorios activados?
  final int reminderStartHour;    // Hora de inicio de recordatorios
  final int reminderEndHour;      // Hora de fin
  final int reminderIntervalMin;  // Intervalo en minutos
}
```

#### SettingsNotifier

Sigue el mismo patron que `WaterNotifier`:

1. En `_init()`, lee todos los valores de `StorageService`
2. Cada setter actualiza `state` (inmutable) y persiste en SharedPreferences

```dart
Future<void> setDailyGoal(int goal) async {
  final storage = _ref.read(storageServiceProvider);
  state = state.copyWith(dailyGoal: goal);    // Actualiza estado
  await storage.setDailyGoal(goal);            // Persiste
}
```

**Nota importante:** Cuando el usuario cambia la meta o el tamano del vaso en `SettingsScreen`, se actualizan **dos** providers:

```dart
// En settings_screen.dart:
onChanged: (v) {
  ref.read(settingsProvider.notifier).setDailyGoal(v);   // Actualiza settings
  ref.read(waterProvider.notifier).setGoal(v);            // Actualiza water (y sincroniza widget)
},
```

Esto asegura que tanto `settingsProvider` como `waterProvider` se mantengan sincronizados.

---

### 3.4 `premiumProvider` - StateNotifierProvider booleano

**Archivo:** `lib/providers/premium_provider.dart`

El provider mas simple. Su estado es un `bool` que indica si el usuario es premium.

```dart
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

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier(ref);
});
```

Se usa en la UI para:
- Mostrar/ocultar banners de AdMob (`if (!isPremium) const AdBannerWidget()`)
- Limitar el historial a 7 dias (free) vs 30 dias (premium)
- Mostrar el `PremiumGate` CTA

---

### 3.5 `historyServiceProvider` - Provider simple

**Archivo:** `lib/providers/history_provider.dart`

```dart
final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService();
});
```

Simplemente expone una instancia de `HistoryService` (CRUD sobre Hive) para que otros providers la puedan usar.

`HistoryService` (`lib/services/history_service.dart`) maneja una caja Hive (`Box<DayRecord>`) con registros diarios:

```dart
class HistoryService {
  Box<DayRecord>? _box;

  Future<Box<DayRecord>> get box async {
    _box ??= await Hive.openBox<DayRecord>(HiveBoxes.history);
    return _box!;
  }

  Future<void> saveDay(DayRecord record) async { ... }
  Future<DayRecord?> getDay(String dateKey) async { ... }
  Future<List<DayRecord>> getRecentDays(int days) async { ... }
  Future<int> calculateStreak() async { ... }
  Future<double> averageGlasses(int days) async { ... }
  Future<void> prune(int keepDays) async { ... }
}
```

---

### 3.6 `recentHistoryProvider` - FutureProvider.family

```dart
final recentHistoryProvider =
    FutureProvider.family<List<DayRecord>, int>((ref, days) async {
  final service = ref.read(historyServiceProvider);
  return service.getRecentDays(days);
});
```

**Conceptos clave:**

- **`FutureProvider`**: Para datos asincronos. Expone un `AsyncValue<T>` que puede estar en estado `loading`, `data` o `error`.
- **`.family`**: Permite pasar un **parametro** al provider. En este caso, `days` (cuantos dias de historial queremos).

Uso en la UI:

```dart
// En history_screen.dart:
final maxDays = isPremium ? 30 : 7;
final historyAsync = ref.watch(recentHistoryProvider(maxDays));

historyAsync.when(
  data: (records) => ListView.separated(...),
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => Center(child: Text('Error: $e')),
);
```

El parametro `maxDays` cambia segun si el usuario es premium. Riverpod automaticamente cachea cada combinacion de parametro como un provider independiente.

---

### 3.7 `streakProvider` y `weeklyAverageProvider` - FutureProvider

```dart
final streakProvider = FutureProvider<int>((ref) async {
  final service = ref.read(historyServiceProvider);
  return service.calculateStreak();
});

final weeklyAverageProvider = FutureProvider<double>((ref) async {
  final service = ref.read(historyServiceProvider);
  return service.averageGlasses(7);
});
```

Ambos son `FutureProvider` simples (sin `.family`) que calculan estadisticas:

- **`streakProvider`**: Dias consecutivos cumpliendo la meta (hasta 365 dias atras)
- **`weeklyAverageProvider`**: Promedio de vasos por dia en los ultimos 7 dias

Se consumen con el patron `.when()`:

```dart
streakAsync.when(
  data: (streak) => StatsCard(label: 'Racha', value: '$streak dias', ...),
  loading: () => const StatsCard(label: 'Racha', value: '...', ...),
  error: (_, __) => const StatsCard(label: 'Racha', value: '0', ...),
);
```

---

## 4. Flujo de datos

### Flujo principal: usuario toca "+" en la app

```
 Usuario toca [+]
       |
       v
 HomeScreen llama:
 ref.read(waterProvider.notifier).addGlass()
       |
       v
 WaterNotifier.addGlass()
  |-- state = state.copyWith(currentCount: newCount)   ---> UI se reconstruye (ref.watch)
  |-- storage.setCurrentCount(newCount)                 ---> SharedPreferences actualizado
  |-- WidgetService.syncToWidget(...)                   ---> Widget Android nativo actualizado
```

### Flujo inverso: usuario toca el widget nativo de Android

```
 Usuario toca widget Android
       |
       v
 backgroundCallback(uri)  [top-level function en widget_service.dart]
  |-- Lee currentCount de SharedPreferences
  |-- Incrementa y escribe newCount en SharedPreferences
  |-- Actualiza UI del widget nativo
       |
       v
 Usuario abre la app (AppLifecycleState.resumed)
       |
       v
 HomeScreen.didChangeAppLifecycleState()
  |-- ref.read(waterProvider.notifier).reconcileFromWidget()
       |
       v
 WaterNotifier.reconcileFromWidget()
  |-- Lee currentCount de SharedPreferences (escrito por el widget)
  |-- Si es diferente al state actual, actualiza state
  |-- UI se reconstruye automaticamente
```

### Diagrama ASCII completo

```
+------------------+       +-------------------+       +---------------------+
|                  |       |                   |       |                     |
|   HomeScreen     |       |  SettingsScreen   |       |   HistoryScreen     |
|  (ConsumerState  |       |  (ConsumerWidget) |       |  (ConsumerWidget)   |
|   fulWidget)     |       |                   |       |                     |
+--------+---------+       +---------+---------+       +----------+----------+
         |                           |                            |
   ref.watch /               ref.watch /                   ref.watch
   ref.read                  ref.read                            |
         |                           |                            |
+--------v---------------------------v---+   +--------------------v-----------+
|                                        |   |                                |
|    waterProvider (StateNotifier)        |   |  recentHistoryProvider         |
|    settingsProvider (StateNotifier)     |   |  streakProvider                |
|    premiumProvider (StateNotifier)      |   |  weeklyAverageProvider         |
|                                        |   |       (FutureProvider)          |
+--------+------------------------------+   +----------+---------------------+
         |                                              |
   ref.read                                       ref.read
         |                                              |
+--------v----------------------------------------------v-----+
|                                                             |
|              storageServiceProvider (Provider)               |
|                     StorageService                           |
|                 (SharedPreferences wrapper)                  |
|                                                             |
+--------+-----------------------------------+----------------+
         |                                   |
         v                                   v
+------------------+              +--------------------+
| SharedPreferences|              |   Hive (Box)       |
| (datos del dia)  |              |  (historial dias)  |
+--------+---------+              +--------------------+
         |
         | Claves compartidas (SPKeys)
         v
+------------------+
| Widget Android   |
| nativo (Kotlin)  |
| WaterWidget      |
| Provider.kt      |
+------------------+
```

---

## 5. Como se usan en la UI

Riverpod ofrece dos tipos base de widgets para consumir providers:

### ConsumerWidget (sin estado local)

Equivalente a `StatelessWidget` pero con acceso a `ref`. Se usa cuando el widget no necesita `initState`, `dispose`, ni ninguna logica de ciclo de vida.

```dart
// lib/screens/history/history_screen.dart
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumProvider);
    final maxDays = isPremium ? 30 : 7;
    final historyAsync = ref.watch(recentHistoryProvider(maxDays));
    // ...
  }
}
```

```dart
// lib/screens/settings/settings_screen.dart
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isPremium = ref.watch(premiumProvider);
    // ...
  }
}
```

### ConsumerStatefulWidget (con estado local y ciclo de vida)

Equivalente a `StatefulWidget` pero con acceso a `ref`. Se usa cuando necesitas `initState`, `dispose`, u observar el ciclo de vida de la app.

```dart
// lib/screens/home/home_screen.dart
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);  // Necesita ciclo de vida
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(waterProvider.notifier).reconcileFromWidget();  // Usa ref
    }
  }

  @override
  Widget build(BuildContext context) {
    final water = ref.watch(waterProvider);  // Suscripcion reactiva
    // ...
  }
}
```

### ref.watch vs ref.read

| Metodo | Donde usarlo | Que hace |
|---|---|---|
| `ref.watch(provider)` | Dentro de `build()` | Se **suscribe** al provider. Cada vez que el estado cambia, el widget se reconstruye. |
| `ref.read(provider)` | Dentro de callbacks (`onPressed`, `onChanged`, `initState`) | Lee el valor **una sola vez** sin suscribirse. No causa reconstrucciones. |

**Ejemplo real de AguaHoy:**

```dart
@override
Widget build(BuildContext context) {
  // WATCH: se suscribe. Cada vez que el agua cambia, build() se ejecuta de nuevo.
  final water = ref.watch(waterProvider);

  return Column(
    children: [
      ProgressCircle(progress: water.progress, goalMet: water.goalMet),
      WaterButton(
        icon: Icons.add,
        onPressed: () {
          // READ: accion puntual. No necesita suscripcion.
          ref.read(waterProvider.notifier).addGlass();
        },
      ),
    ],
  );
}
```

**Regla de oro:** Usa `watch` para datos que afectan la UI. Usa `read` para disparar acciones.

---

## 6. Reconciliacion con el Widget nativo

AguaHoy tiene un widget de Android nativo (home screen widget) que permite al usuario agregar vasos sin abrir la app. Esto crea un desafio: **dos procesos distintos** (Flutter y el widget nativo) pueden modificar el mismo dato (`currentCount`) en SharedPreferences.

### Escritura: Flutter hacia el Widget

Cada vez que `WaterNotifier` modifica el estado, llama a `_syncWidget()`:

```dart
Future<void> _syncWidget() async {
  await _trySyncWidget(
    currentCount: state.currentCount,
    dailyGoal: state.dailyGoal,
    glassSizeMl: state.glassSizeMl,
  );
}
```

Que a su vez llama a `WidgetService.syncToWidget()`:

```dart
static Future<void> syncToWidget({
  required int currentCount,
  required int dailyGoal,
  required int glassSizeMl,
}) async {
  await Future.wait([
    HomeWidget.saveWidgetData<int>(SPKeys.currentCount, currentCount),
    HomeWidget.saveWidgetData<int>(SPKeys.dailyGoal, dailyGoal),
    HomeWidget.saveWidgetData<int>(SPKeys.glassSizeMl, glassSizeMl),
    HomeWidget.saveWidgetData<String>(SPKeys.lastResetDate, AppDateUtils.todayKey()),
  ]);
  await HomeWidget.updateWidget(androidName: 'WaterWidgetProvider');
}
```

### Escritura: Widget nativo hacia SharedPreferences

Cuando el usuario toca "+" en el widget de Android, se ejecuta un callback a nivel de proceso:

```dart
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.host == 'addWater') {
    final currentCount =
        await HomeWidget.getWidgetData<int>(SPKeys.currentCount) ?? 0;
    final newCount = currentCount + 1;
    await HomeWidget.saveWidgetData<int>(SPKeys.currentCount, newCount);
    await HomeWidget.updateWidget(androidName: 'WaterWidgetProvider');
  }
}
```

**Importante:** Este callback se ejecuta **fuera** del proceso de Flutter. No tiene acceso a Riverpod ni a ningun provider. Solo puede leer/escribir en SharedPreferences a traves de `HomeWidget`.

### Lectura: Flutter lee lo que escribio el widget

Cuando el usuario vuelve a abrir la app, `HomeScreen` detecta el evento `AppLifecycleState.resumed` y llama a `reconcileFromWidget()`:

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    ref.read(waterProvider.notifier).reconcileFromWidget();
  }
}
```

```dart
Future<void> reconcileFromWidget() async {
  final storage = _ref.read(storageServiceProvider);

  // 1. Verificar si hay que resetear el dia
  if (storage.needsDailyReset()) {
    _performDailyReset(storage);
    state = WaterState(
      currentCount: 0,
      dailyGoal: storage.dailyGoal,
      glassSizeMl: storage.glassSizeMl,
    );
    return;
  }

  // 2. Leer el valor que SharedPreferences tiene (pudo ser escrito por el widget)
  final widgetCount = storage.currentCount;
  if (widgetCount != state.currentCount) {
    state = state.copyWith(currentCount: widgetCount);  // Actualiza UI
  }
}
```

### Diagrama de reconciliacion

```
    App abierta                    App en background
    ===========                    =================

  [Usuario toca +]
        |
  WaterNotifier.addGlass()
        |
  state.currentCount = 5
  SharedPreferences = 5
  Widget nativo = 5
        |
  [Usuario minimiza app]
                                  [Usuario toca widget +]
                                        |
                                  backgroundCallback()
                                        |
                                  SharedPreferences = 6
                                  Widget nativo = 6
                                        |
                                  [Usuario toca widget +]
                                        |
                                  SharedPreferences = 7
                                  Widget nativo = 7

  [Usuario abre app]
        |
  didChangeAppLifecycleState(resumed)
        |
  reconcileFromWidget()
        |
  Lee SharedPreferences = 7
  state.currentCount era 5
  Diferente! -> state = 7
        |
  UI se reconstruye mostrando 7 vasos
```

---

## 7. Testing

Riverpod facilita enormemente el testing gracias a `ProviderContainer` y el sistema de `overrides`.

### Testing de providers con ProviderContainer

En los tests, no necesitamos un widget tree completo. Podemos crear un `ProviderContainer` aislado:

```dart
// test/providers/water_provider_test.dart

late ProviderContainer container;
late StorageService storageService;

setUp(() async {
  // 1. Configurar SharedPreferences con valores mock
  SharedPreferences.setMockInitialValues({
    SPKeys.currentCount: 0,
    SPKeys.dailyGoal: 8,
    SPKeys.glassSizeMl: 250,
    SPKeys.lastResetDate: '2026-02-26',  // Hoy
  });
  final prefs = await SharedPreferences.getInstance();
  storageService = StorageService(prefs);

  // 2. Crear container con override (igual que en main.dart)
  container = ProviderContainer(
    overrides: [
      storageServiceProvider.overrideWithValue(storageService),
    ],
  );
});

tearDown(() {
  container.dispose();  // Limpiar
});
```

### Ejemplos de tests reales del proyecto

**Test basico de estado inicial:**

```dart
test('initial state has count 0, goal 8, glass 250ml', () {
  final state = container.read(waterProvider);
  expect(state.currentCount, 0);
  expect(state.dailyGoal, 8);
  expect(state.glassSizeMl, 250);
});
```

**Test de addGlass:**

```dart
test('addGlass increments count', () async {
  await container.read(waterProvider.notifier).addGlass();
  final state = container.read(waterProvider);
  expect(state.currentCount, 1);
  expect(state.currentMl, 250);
});
```

**Test de que removeGlass no baja de 0:**

```dart
test('removeGlass does not go below 0', () async {
  await container.read(waterProvider.notifier).removeGlass();
  expect(container.read(waterProvider).currentCount, 0);
});
```

**Test de progreso y meta cumplida:**

```dart
test('progress calculates correctly', () async {
  for (var i = 0; i < 4; i++) {
    await container.read(waterProvider.notifier).addGlass();
  }
  final state = container.read(waterProvider);
  expect(state.progress, 0.5);    // 4/8 = 50%
  expect(state.goalMet, false);
});

test('goalMet is true when count >= goal', () async {
  for (var i = 0; i < 8; i++) {
    await container.read(waterProvider.notifier).addGlass();
  }
  expect(container.read(waterProvider).goalMet, true);
  expect(container.read(waterProvider).progress, 1.0);
});
```

**Test del reset diario:**

```dart
test('daily reset when lastResetDate is yesterday', () async {
  // Simular que la ultima fecha guardada es ayer
  SharedPreferences.setMockInitialValues({
    SPKeys.currentCount: 5,
    SPKeys.dailyGoal: 8,
    SPKeys.glassSizeMl: 250,
    SPKeys.lastResetDate: yesterdayKey,
  });
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);

  final newContainer = ProviderContainer(
    overrides: [
      storageServiceProvider.overrideWithValue(storage),
    ],
  );

  // Al inicializarse, detecta que es un nuevo dia y resetea
  final state = newContainer.read(waterProvider);
  expect(state.currentCount, 0);

  newContainer.dispose();
});
```

**Test de reconciliacion con el widget:**

```dart
test('reconcileFromWidget picks up widget changes', () async {
  // Simular que el widget nativo escribio un 3 en SharedPreferences
  await storageService.setCurrentCount(3);

  await container.read(waterProvider.notifier).reconcileFromWidget();
  expect(container.read(waterProvider).currentCount, 3);
});
```

### Testing de widgets con ProviderScope

Para tests de widgets, se usa `ProviderScope` (en lugar de `ProviderContainer`):

```dart
// test/screens/home_screen_test.dart

Widget createTestApp() {
  return ProviderScope(
    overrides: [
      storageServiceProvider.overrideWithValue(storageService),
    ],
    child: MaterialApp(
      theme: AguaTheme.lightTheme,
      home: const HomeScreen(),
    ),
  );
}

testWidgets('tapping + adds a glass and updates MlLabel', (tester) async {
  await tester.pumpWidget(createTestApp());
  await tester.pumpAndSettle();

  final addButton = find.byIcon(Icons.add);
  await tester.tap(addButton);
  await tester.pumpAndSettle();

  final mlLabel = tester.widget<MlLabel>(find.byType(MlLabel));
  expect(mlLabel.currentMl, 250);
});
```

### Por que los tests son tan limpios

1. **`ProviderContainer` es aislado**: Cada test crea su propio container con sus propios overrides. No hay estado compartido entre tests.
2. **`overrideWithValue` inyecta mocks**: Al sobreescribir `storageServiceProvider`, controlamos exactamente lo que SharedPreferences contiene.
3. **No se necesita mockear Riverpod**: Se usan providers reales con datos controlados. Solo se mockea la capa de persistencia.
4. **`_trySyncWidget` falla silenciosamente en tests**: El `try/catch` en `_trySyncWidget()` permite que los tests se ejecuten sin un platform channel disponible.

---

## Resumen

| Concepto | Archivo | Tipo de Provider |
|---|---|---|
| Inyeccion de SharedPreferences | `main.dart` | `Provider` (con override) |
| Conteo de agua del dia | `water_provider.dart` | `StateNotifierProvider` |
| Ajustes del usuario | `settings_provider.dart` | `StateNotifierProvider` |
| Estado premium | `premium_provider.dart` | `StateNotifierProvider<bool>` |
| Servicio de historial | `history_provider.dart` | `Provider` |
| Historial reciente (N dias) | `history_provider.dart` | `FutureProvider.family` |
| Racha de dias | `history_provider.dart` | `FutureProvider` |
| Promedio semanal | `history_provider.dart` | `FutureProvider` |

La arquitectura sigue un patron claro:

```
UI (Consumer widgets)
  --> watch/read Providers
    --> Providers manejan estado inmutable
      --> Persisten en StorageService (SharedPreferences) y HistoryService (Hive)
        --> Sincronizan con el widget nativo (WidgetService)
```

Todo el estado es **unidireccional** excepto la reconciliacion con el widget nativo, que introduce un flujo bidireccional controlado por `reconcileFromWidget()` en el momento en que la app vuelve al primer plano.
