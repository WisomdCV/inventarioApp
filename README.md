# Inventario App

Aplicación Flutter para gestión de inventario enfocada en Android. Permite registrar productos, asignar categorías, editar/eliminar registros, visualizar detalles y configurar el orden y visibilidad de columnas de forma personalizada y persistente.

## Características
- Gestión local de productos con almacenamiento en `Hive` (offline).
- CRUD completo: crear, editar, eliminar y ver detalles de productos.
- Columnas configurables: selecciona y reordena columnas; el orden se guarda y se respeta al agregar nuevas categorías.
- Ordenamiento por columna (asc/desc) con soporte de fecha (`fechaRegistro`).
- Búsqueda y navegación con barra inferior flotante.
- Captura de pantalla y compartir (`screenshot`, `share_plus`).

## Tecnologías
- Flutter
- Hive / Hive Flutter
- Intl (formateo de fechas)
- Kotlin DSL + Gradle 8.12 (Android)

## Requisitos
- Flutter instalado y en PATH.
- Android SDK y herramientas de desarrollo.
- JDK 21 (Gradle 8.12 utiliza JVM 21).

## Instalación
```bash
flutter pub get
```

## Ejecución (Android)
```bash
flutter run
```

## Compilación APK (debug)
```bash
flutter build apk --debug
```

## Estructura relevante
- `lib/main.dart`: punto de entrada.
- `lib/screens/main_screen_host.dart`: host de navegación y vistas principales.
- `lib/screens/add_edit_screen.dart`: formulario para crear/editar productos.
- `lib/views/product_list_view.dart`: tabla de productos y configuración de columnas.
- `lib/services/hive_service.dart`: operaciones CRUD en Hive.
- `lib/services/data_change_notifier.dart`: notificador de cambios para refrescos.
- `android/`: configuración de Gradle con Kotlin DSL.

## Configuración de columnas
- Abre el diálogo “Configurar Columnas” desde el ícono de columnas en la barra superior.
- Selecciona la visibilidad con el check y usa arrastrar y soltar para reordenar.
- Al presionar “Aplicar”, se guardan:
  - `visibleColumns`: lista filtrada y ordenada.
  - `columnOrder`: orden global de todas las columnas.
- Cuando se agregan nuevas categorías, se añaden al final del `columnOrder` sin romper tu orden previo; la vista respeta tu selección y orden.

## Persistencia de datos
- Los datos se guardan localmente en `Hive`.
- No requiere backend externo.

## Consejos de solución de problemas
- Si Gradle falla, verifica JDK 21 y que `android/settings.gradle.kts` y `android/build.gradle.kts` sigan el formato moderno de Flutter/AGP.
- Ejecuta `flutter clean` y luego `flutter pub get` antes de un build.

## Licencia
Pendiente de definición.

