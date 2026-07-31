# Known Issues

## Critical — Fixed in 2.3.1 + 2.3.2

| Issue | Status | Notes |
|-------|--------|-------|
| All measurements used hardcoded defaults | ✅ Fixed | Dialogs now require real user input |
| GPS Land mode used fake SF coordinates | ✅ Fixed | Now navigates to real GPS tracking |
| PROJECT_STATUS claimed 90% completion | ✅ Fixed | Corrected to honest ~33% |
| Camera page `?? 3.0/2.5` fallbacks | ✅ Fixed | Validates before calculating |
| Wizard always saved as RectangleShape | ✅ Fixed | Uses correct shape type |
| SVG/KML/PDF export showed placeholder text | ✅ Fixed | Wired to real exporters |
| Dashboard 1716-line monolith | 🟡 Reduced | 1527 lines (−189), ExportPanel + AlgorithmBanner extracted |

## Critical — Open

| Issue | Impact | Mitigation |
|-------|--------|------------|
| No real sensor-driven measurement pipeline | Core product promise broken | All modes currently use manual text input; camera/AR/SLAM engines not implemented |
| ML Kit dependencies commented out | No object detection, OCR, barcode on mobile | Uncomment in pubspec.yaml when building for mobile only |
| AR engine is interface-only | No real AR measurement | Requires native ARCore/ARKit platform channel bindings |
| Dashboard still 1527 lines | Maintenance burden | Settings tab extraction planned |

## Environment

| Issue | Impact | Workaround |
|-------|--------|------------|
| Android SDK not installed locally | Cannot build APK without Docker | Use `docker compose run app-build-apk` |
| iOS builds require macOS + Xcode | Cannot validate on Windows | Use macOS CI runner or physical Mac |
| Google Fonts requires network on first run | Breaks offline-first on fresh install | Bundle fonts in `assets/` (planned) |
| Flutter SDK not in system PATH | Cannot run flutter commands directly | Use Docker or configure PATH |

## Architecture

| Issue | Impact | Mitigation |
|-------|--------|------------|
| Manual ServiceLocator DI | Doesn't scale past ~20 services | Consider migrating to `get_it` |
| Hive JSON string storage | Slower for >1000 measurements | Implement Hive TypeAdapters |
| Duplicate settings page | settings_page.dart AND inline dashboard tab | Consolidate into one |
| No state management framework | Raw ChangeNotifier everywhere | Consider Riverpod/Bloc |

## Testing

| Issue | Impact | Mitigation |
|-------|--------|------------|
| No integration tests | Cannot verify end-to-end flows | Implement using `integration_test` package |
| Coverage threshold not enforced | Regressions possible | Add `--min-coverage=85` to CI |
| Widget tests use `MissingPluginException` fallback | Tests don't exercise native channels | Expected; native testing requires device |

## Platform

| Issue | Impact | Mitigation |
|-------|--------|------------|
| AR features interface-only | ARCore/ARKit not functional | Requires native platform channel bindings |
| ML Kit scaffold only | No real on-device ML inference | Uncomment `google_mlkit_*` in pubspec |
| Cloud sync interface-only | No remote sync | Requires backend API implementation |
| Visual SLAM not implemented | No camera-based 3D reconstruction | Future sprint |
| LiDAR/Depth sensor not integrated | No hardware depth measurement | Requires platform plugins |

## UI/UX

| Issue | Impact | Mitigation |
|-------|--------|------------|
| Launcher icons are XML vector drawables | May not render on all Android versions | Generate PNG rasters via `flutter_launcher_icons` |
| No guided camera→measure workflow | Users must manually type dimensions | Planned for Sprint 2 |
| SegmentedButton can overflow on narrow screens | UI layout issue | Wrapped in SingleChildScrollView |
| No NavigationRail for tablets | Poor tablet experience | Planned for Sprint 2 |
