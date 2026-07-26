# Known Issues

## Environment

| Issue | Impact | Workaround |
|-------|--------|-----------|
| Android SDK not installed locally | Cannot build APK without Docker | Use `docker compose run app-build-apk` |
| iOS builds require macOS + Xcode | Cannot validate on Windows | Use macOS CI runner or physical Mac |
| Google Fonts requires network on first run | Breaks offline-first on fresh install | Bundle fonts in `assets/` (planned) |

## Architecture

| Issue | Impact | Mitigation |
|-------|--------|-----------|
| Manual ServiceLocator DI | Doesn't scale past ~20 services | Consider migrating to `get_it` |
| Hive JSON string storage | Slower for >1000 measurements | Implement Hive TypeAdapters |
| `AppConfig.appVersion` hardcoded as `1.2.0` | Doesn't match `pubspec.yaml` `2.2.0` | Read from package info at runtime |

## Testing

| Issue | Impact | Mitigation |
|-------|--------|-----------|
| No integration tests | Cannot verify end-to-end flows | Implement using `integration_test` package |
| Widget tests use `MissingPluginException` fallback | Tests don't exercise native channels | Expected; native testing requires device |
| Coverage threshold not enforced | Regressions possible | Add `--min-coverage=85` to CI |

## Platform

| Issue | Impact | Mitigation |
|-------|--------|-----------|
| AR features interface-only | ARCore/ARKit not functional | Requires native platform channel bindings |
| ML Kit scaffold only | No real on-device ML inference | Add `google_mlkit_*` to pubspec |
| Cloud sync interface-only | No remote sync | Requires backend API implementation |

## UI/UX

| Issue | Impact | Mitigation |
|-------|--------|-----------|
| Launcher icons are XML vector drawables | May not render on all Android versions | Generate PNG rasters via `flutter_launcher_icons` |
| No onboarding flow | New users may be confused | Design onboarding screens |
