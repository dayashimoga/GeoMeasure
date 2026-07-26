# Roadmap

## Completed Phases

### Phase 1: Core Foundation ✅
- Clean Architecture structure & feature modules
- Capability detection engine & normalised profile
- Measurement engine with 25 shape types
- Docker environment & CI/CD pipeline
- 9 export formats

### Phase 2: Platform Services ✅
- Firebase authentication
- GPS tracking (Geolocator)
- Camera service (image_picker)
- Hive local storage with encrypted secure storage
- Project management

### Phase 3: AI & Advanced Math ✅
- Edge detection (Sobel, Harris)
- FAST corner detection
- Object counting with NMS
- Photogrammetry pipeline (NCC, DLT)
- Sensor fusion (9 sensor types)
- Material estimation & cost calculation
- 5 PDF report templates
- Excel export (pure Dart)

## Upcoming

### Phase 4: Native SDK Integration
- [ ] Add `google_mlkit_*` packages to pubspec
- [ ] Wire `MlKitVisionService` to real ML Kit APIs
- [ ] Implement ARCore platform channel bridge (Android)
- [ ] Implement ARKit platform channel bridge (iOS)
- [ ] Native sensor fusion with Kalman filter

### Phase 5: Production Polish
- [ ] Integration tests for end-to-end flows
- [ ] Coverage threshold enforcement (85%+)
- [ ] Bundle Google Fonts for offline-first
- [ ] Generate proper PNG launcher icons
- [ ] Onboarding flow for new users
- [ ] Migrate ServiceLocator to `get_it`

### Phase 6: Cloud & Collaboration
- [ ] Backend API for cloud sync
- [ ] Multi-user project sharing
- [ ] Real-time collaboration
- [ ] Remote config for feature flags
