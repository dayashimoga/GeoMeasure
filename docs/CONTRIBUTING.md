# Contributing

## Prerequisites

- Flutter SDK ≥3.0.0
- Dart SDK ≥3.0.0
- Git

Or use Docker (no local Flutter required):
```bash
docker compose run --rm app-test
```

## Commit Conventions

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add LiDAR capability probe
fix: correct shoelace polygon area for concave polygons
docs: update measurement engine documentation
test: add unit conversion tests for Guntha
refactor: extract geodetic calculator into separate service
```

## Code Quality

Run before submitting a PR:

```bash
# Format
dart format .

# Analyse
flutter analyze

# Test
flutter test
```

All three must pass. CI enforces this automatically.

## PR Checklist

- [ ] Code formatted with `dart format`
- [ ] `flutter analyze` passes with 0 errors
- [ ] All existing tests pass
- [ ] New tests added for new functionality
- [ ] Documentation updated if behaviour changes
- [ ] No hardcoded secrets or credentials

## Architecture Guidelines

- Follow Clean Architecture layers (see [ARCHITECTURE.md](ARCHITECTURE.md))
- New features go in `lib/features/<feature_name>/`
- Domain entities must be pure Dart — no Flutter or platform imports
- Use `ServiceLocator` for new service wiring
- Add feature flags in `AppConfig` for gated features

## File Naming

- `snake_case.dart` for all files
- `PascalCase` for classes
- `camelCase` for methods and variables
- Test files: `*_test.dart`
