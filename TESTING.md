# Testing Strategy & Benchmark Guidelines

## Targets
- **Build Success**: 100%
- **Lint Pass**: 100%
- **Static Analysis Pass**: 100%
- **Code Coverage Target**: > 90%

## Test Types
- **Unit Tests**: Domain entities, shoelace formula calculation, unit conversion precision, dynamic strategy selector.
- **Widget Tests**: Dashboard rendering, capability card status, unit toggle controls.
- **Integration Tests**: End-to-end probing to measurement flow.
- **Docker Test Command**: `docker compose run --rm app-test`
