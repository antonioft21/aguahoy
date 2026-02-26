# AguaHoy - Documento de Progreso

**Version:** 1.0.0+1
**Stack:** Flutter 3.8+ / Dart / Kotlin (widget nativo Android)
**Arquitectura:** Riverpod + SharedPreferences + Hive CE

---

## 1. Estado actual del proyecto

### Fase 1 - Core: Tracking de agua

- **Pantalla principal (HomeScreen):** Circulo de progreso animado, fila de iconos de vasos llenos/vacios, botones de agregar/quitar vaso con feedback haptico, etiqueta de ml actuales vs. objetivo.
- **Modelo de datos (`DayRecord`):** Registro diario con fecha, vasos, objetivo, tamano de vaso. Persistido en Hive CE con type adapter generado.
- **Estado reactivo (`WaterProvider`):** StateNotifier con Riverpod. Gestiona conteo actual, objetivo diario y tamano de vaso. Reset automatico diario con guardado de historial del dia anterior.
- **Almacenamiento dual:**
  - `StorageService` sobre SharedPreferences para el estado del dia actual (compartido con widget nativo).
  - `HistoryService` sobre Hive para el historial de dias pasados (CRUD, racha, media, poda).

### Fase 2 - Widget de Android (home_widget + Kotlin nativo)

- **`WaterWidgetProvider.kt`:** Widget nativo con layout XML personalizado (titulo, contador "X / Y", barra de progreso, etiqueta de ml, boton "+ Vaso").
- **Sincronizacion bidireccional:** Flutter escribe a SharedPreferences via `home_widget`; Kotlin lee. Kotlin escribe via `SharedPreferences`; Flutter reconcilia al volver al foreground (`reconcileFromWidget`).
- **Background callback:** Tap en el boton del widget incrementa el contador via Dart `backgroundCallback` sin abrir la app.
- **Reset diario nativo:** El widget detecta cambio de fecha y resetea a 0 sin depender de Flutter.
- **Layout:** `water_widget.xml` con fondo redondeado (`widget_background.xml`), boton azul estilizado (`widget_btn_bg.xml`), dimensiones minimas 180x180dp, redimensionable.

### Fase 3 - Historial y estadisticas

- **Pantalla de historial (HistoryScreen):** Lista de dias con barras visuales (`DayBar`), tarjetas de racha y media semanal (`StatsCard`).
- **Providers asincronos:** `recentHistoryProvider` (parametrizado por dias), `streakProvider` (hasta 365 dias de busqueda), `weeklyAverageProvider`.
- **Premium gate:** Usuarios free ven 7 dias de historial; premium desbloquea 30 dias con indicador visual (`PremiumGate`).

### Fase 4 - Ajustes y personalizacion

- **Pantalla de ajustes (SettingsScreen):**
  - `GoalPicker`: Selector de objetivo diario (1-20 vasos) y tamano de vaso (100-500 ml en pasos de 50).
  - `ReminderConfig`: Activar/desactivar recordatorios, intervalo configurable.
- **Notificaciones locales:** `NotificationService` con `flutter_local_notifications`. Programacion de recordatorios recurrentes entre hora inicio/fin con intervalo configurable. Canal dedicado "Recordatorios de agua".
- **Persistencia de ajustes:** `SettingsProvider` sincroniza todo a SharedPreferences.

### Fase 5 - Monetizacion

- **AdMob (`AdBannerWidget`):** Banner publicitario en HomeScreen e HistoryScreen. Usa IDs de test actualmente (`ca-app-pub-3940256099942544/6300978111`). Se oculta automaticamente para usuarios premium.
- **In-App Purchase (`PurchaseService`):** Compra no consumible `com.aguahoy.app.premium` a 1.99 EUR. Flujo completo: compra, restauracion, listener de stream de compras. Persiste estado premium en SharedPreferences.
- **PremiumCard:** Tarjeta en ajustes con beneficios (sin anuncios, 30 dias historial, colores widget), boton comprar, boton restaurar. Botones DEBUG protegidos por `kDebugMode` (solo visibles en desarrollo).

### Fase 6 - Tema y UI

- **`AguaTheme`:** Material 3 con paleta azul personalizada (primary, light, dark, success green). AppBar transparente, botones redondeados (16px radius), tarjetas sin elevacion con bordes redondeados (20px radius).
- **Interfaz en espanol** nativa (textos, notificaciones, widget).

---

## 2. Lo que le meteria (mejoras propuestas)

### Animaciones y microinteracciones
- Confetti o splash al completar el objetivo diario.
- Animacion de agua llenandose en el circulo de progreso.
- Transiciones suaves entre pantallas (Hero, page transitions).
- Animacion del boton "+" al pulsar (scale bounce).

### Temas y colores personalizables
- Modo oscuro (dark theme) completo.
- Colores de widget personalizables para usuarios premium.
- Selector de paleta de colores en ajustes.

### Gamificacion
- Sistema de logros/badges:
  - Primera vez que completas el objetivo.
  - Primera semana consecutiva.
  - 30 dias seguidos.
  - 100 dias totales.
  - 1000 vasos totales.
- Pantalla de logros con progreso visual.
- Notificacion push al desbloquear un logro.

### Export de datos
- Exportar historial completo en CSV.
- Generar reporte PDF con graficas de consumo.
- Compartir reporte por mensajeria/email.

### Widget de pantalla de bloqueo
- Glance widget para Android 14+ (lock screen widget).
- La arquitectura actual con `home_widget` + Kotlin ya facilita la extension.
- Requiere `widgetCategory="home_screen|keyguard"` en `water_widget_info.xml`.

### Onboarding para nuevos usuarios
- Pantalla de bienvenida con 3-4 slides:
  - Que hace la app.
  - Como configurar tu objetivo.
  - Como anadir el widget.
  - Beneficios de premium.
- Solo se muestra la primera vez (flag en SharedPreferences).

### Ajuste inteligente del objetivo
- Calcular objetivo de agua basado en peso corporal.
- Ajustar por nivel de actividad fisica (sedentario, moderado, activo).
- Ajustar por clima/temperatura (integracion con API de clima, opcional).

### Sonidos al anadir vaso
- Efecto de sonido sutil al pulsar "+" (sonido de agua/gota).
- Sonido especial al completar el objetivo.
- Toggle en ajustes para activar/desactivar.

### Backup en la nube
- Sincronizacion con Google Drive (guardar/restaurar historial Hive).
- Login con Google Sign-In.
- Backup automatico diario o manual.

### Integracion con salud
- Google Fit / Health Connect (Android).
- Apple Health (iOS, si se expande a esa plataforma).
- Registrar automaticamente el consumo de agua en la plataforma de salud.

---

## 3. Lo que falta para salir a produccion

### Identidad visual
- [ ] Disenar icono de app personalizado (gota de agua / vaso) en todas las resoluciones (`mipmap-*`).
- [ ] Crear splash screen con branding de AguaHoy (usar `flutter_native_splash` o configurar manualmente `launch_background.xml`).

### Firma y build
- [ ] Generar keystore de release: `keytool -genkey -v -keystore aguahoy-release.jks -keyalg RSA -keysize 2048 -validity 10000`.
- [ ] Configurar `android/key.properties` con la ruta y credenciales del keystore.
- [ ] Configurar `android/app/build.gradle` para firmar con el keystore en modo release.
- [ ] Configurar ProGuard/R8 para release (reglas de ofuscacion, keep rules para plugins).
- [ ] Build final: `flutter build appbundle --release`.
- [ ] Verificar que el APK/AAB resultante funciona correctamente.

### Anuncios
- [ ] Reemplazar el ID de test de AdMob (`ca-app-pub-3940256099942544/6300978111`) en `ad_banner_widget.dart` por el ID de produccion real.
- [ ] Crear cuenta de AdMob y registrar la app.
- [ ] Verificar que los anuncios cargan correctamente en el build de release.

### Compras in-app
- [ ] Crear cuenta de Google Play Developer (25 USD, pago unico).
- [ ] Crear producto IAP en Play Console: ID `com.aguahoy.app.premium`, precio 1.99 EUR, tipo "no consumible".
- [ ] Probar flujo de compra completo con test tracks (internal testing).
- [ ] Verificar restauracion de compras.

### Legal y privacidad
- [ ] Crear politica de privacidad (usar iubenda.com o similar) y publicarla en una URL accesible.
- [ ] Incluir enlace a la politica de privacidad en ajustes de la app.
- [ ] Completar la clasificacion de contenido IARC en Play Console.

### Store listing (ficha de Google Play)
- [ ] Titulo: "AguaHoy - Recordatorio de Agua" (max 30 caracteres).
- [ ] Descripcion corta (max 80 caracteres).
- [ ] Descripcion larga (max 4000 caracteres) con keywords relevantes.
- [ ] Capturar screenshots de la app en diferentes pantallas (home, historial, ajustes, widget).
- [ ] Crear feature graphic (1024x500px).
- [ ] Icono de alta resolucion (512x512px).
- [ ] Seleccionar categoria: Salud y bienestar.
- [ ] Preparar capturas del widget en funcionamiento.

### Testing
- [ ] Testing en dispositivos fisicos reales (minimo 2-3 dispositivos Android diferentes).
- [ ] Verificar que el widget funciona en diferentes launchers (stock, Nova, Pixel, Samsung One UI).
- [ ] Probar reset diario del widget (cambiar fecha del dispositivo o esperar).
- [ ] Probar notificaciones en diferentes versiones de Android (API 26+).
- [ ] Verificar reconciliacion app <-> widget (agregar vasos desde widget, abrir app).
- [ ] Probar compra premium y verificar que los anuncios desaparecen.
- [ ] Probar restauracion de compra en dispositivo limpio.

### Revision final de codigo
- [ ] Verificar que los botones DEBUG de `premium_card.dart` no aparecen en release (estan protegidos por `kDebugMode`, pero hacer build de release y confirmar visualmente).
- [ ] Verificar permisos minimos en `AndroidManifest.xml` (solo los necesarios: internet para ads, notificaciones).
- [ ] Revisar que no hay `print()` o logs de debug sueltos en el codigo.
- [ ] Ejecutar `flutter analyze` sin warnings criticos.
- [ ] Ejecutar tests existentes: `flutter test`.

### Publicacion
- [ ] Subir AAB a Play Console en internal testing track.
- [ ] Invitar testers internos y recopilar feedback.
- [ ] Corregir bugs encontrados en testing.
- [ ] Promover a produccion (open testing o directamente a produccion).
- [ ] Monitorear crashes via Firebase Crashlytics (opcional pero recomendado).

---

*Ultima actualizacion: 26 de febrero de 2026*
