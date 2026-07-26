# Contributing Guidelines

## Commit Message Conventions
Follow [Conventional Commits](https://www.conventionalcommits.org/):
- `feat: add LiDAR capability probe`
- `fix: correct shoelace polygon area calculation for concave polygons`
- `docs: update measurement engine documentation`
- `test: add unit conversion tests for Guntha and Cents`

## Code Formatting & Analysis
Run format and static analysis prior to creating pull requests:
```bash
flutter format lib test
flutter analyze
```
