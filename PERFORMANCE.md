# Performance Benchmarks & Constraints

- **Cold Startup**: Target < 2.0s (Current baseline ~0.8s)
- **Memory Footprint**: Heap usage < 120MB during active spatial mesh processing
- **Thermal Management**: Automatic frame rate throttling down to 30fps when thermal state reaches `elevated` or `critical`
- **Battery Optimization**: Sensor sampling rate dynamically adjusted based on active strategy
