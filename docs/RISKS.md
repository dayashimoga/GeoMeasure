# Risk Register

| ID | Risk | Impact | Likelihood | Mitigation |
|----|------|--------|-----------|-----------|
| R-01 | Sensor drift in low-end hardware | High | Medium | Enforce accuracy thresholds; fallback to Visual SLAM or manual |
| R-02 | High battery drain during AR/LiDAR | Medium | High | Dynamic sensor sampling rate; thermal throttling guards |
| R-03 | ARCore/ARKit API divergence | High | Low | Abstract behind unified domain contracts in `ar_measurement` |
| R-04 | ML Kit not available on all devices | Medium | Medium | Pure Dart `LocalVisionService` as universal fallback |
| R-05 | Hive performance at scale (>1000 records) | Medium | Low | Migrate to TypeAdapters or SQLite if needed |
| R-06 | Google Fonts network dependency | Low | Medium | Bundle Inter font in assets |
| R-07 | ServiceLocator scaling | Low | Medium | Migrate to `get_it` when service count exceeds ~20 |
| R-08 | No integration tests | High | High | Implement before production release |
| R-09 | iOS build not validated | Medium | Medium | Set up macOS CI runner or test on physical device |
| R-10 | Encryption key is deterministic dev key | High | Low | Generate random key; store in platform keychain for production |
