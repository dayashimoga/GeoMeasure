# Performance

## Measured Benchmarks

| Metric | Value | Target |
|--------|-------|--------|
| Cold startup | ~0.8s | <2.0s ✅ |
| Test suite (226 tests) | ~5s | <10s ✅ |
| Web build | ~28s | <60s ✅ |
| Web bundle (tree-shaken) | ~14 KB icons | — |

## Optimisation Strategies

### Build Size
- Material Icons tree-shaken: 1.6 MB → 14.7 KB (99.1% reduction)
- Cupertino Icons tree-shaken: 257 KB → 1.5 KB (99.4% reduction)

### Runtime
- **Thermal management**: Automatic frame rate throttling when device reaches elevated/critical thermal state
- **Battery optimisation**: Sensor sampling rate dynamically adjusted based on active measurement strategy
- **Memory**: Pure Dart implementations for vision/photogrammetry avoid native memory overhead
- **Lazy loading**: Feature flags gate expensive modules (AR, AI, cloud sync)

### Export Performance
- Excel exporter uses streaming ZIP builder — no intermediate files
- PDF generation uses `pdf` package with deferred page composition
- All exporters are synchronous and single-pass

## Profiling

```bash
# Flutter performance profiling
flutter run --profile

# Memory profiling
flutter run --observatory-port=8888

# Build size analysis
flutter build apk --analyze-size
```

## Optimisation Opportunities

| Area | Opportunity | Impact |
|------|-----------|--------|
| Hive storage | Use TypeAdapters instead of JSON strings for >1000 measurements | Medium |
| Google Fonts | Bundle Inter font for offline-first guarantee | Low |
| ServiceLocator | Migrate to `get_it` for lazy instantiation | Low |
| Image processing | Use Isolates for FAST corner detection on large images | Medium |
