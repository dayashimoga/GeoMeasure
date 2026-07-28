# CI/CD Pipeline Documentation

## GitHub Actions Workflow (`.github/workflows/ci.yml`)

The repository uses GitHub Actions for continuous integration and automated quality enforcement on every push and pull request to `main`.

### Pipeline Jobs

1. **Analyze & Test Job**:
   - Environment: `ubuntu-latest`
   - Flutter SDK: `stable`
   - Formatter check: `dart format --set-exit-if-changed .`
   - Static analysis: `flutter analyze --no-fatal-infos`
   - Test execution: `flutter test --coverage`
   - Target Coverage: >90%

2. **Android Build Job**:
   - Environment: `ubuntu-latest`
   - Java SDK: 17
   - Build command: `flutter build apk --debug`
   - Output artifact: `app-debug.apk`

3. **Web Build Job**:
   - Environment: `ubuntu-latest`
   - Build command: `flutter build web --release`
   - Output artifact: `build/web`

4. **Docker CI Enforcement**:
   - `Dockerfile` & `docker-compose.yml` provide identical local reproducible environments.
   - Command: `docker compose run app-ci`
