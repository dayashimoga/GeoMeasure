# Dependencies

All dependencies from `pubspec.yaml` v2.2.0+8.

## Runtime Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | Core cross-platform framework |
| `cupertino_icons` | ^1.0.6 | iOS-style icons |
| `vector_math` | ^2.1.4 | Spatial geometry, vector calculations |
| `path_provider` | ^2.1.0 | Platform-specific file paths |
| `hive` | ^2.2.3 | Lightweight NoSQL local database |
| `hive_flutter` | ^1.1.0 | Flutter bindings for Hive |
| `uuid` | ^4.3.3 | UUID generation for entities |
| `intl` | ^0.19.0 | Internationalisation and date formatting |
| `share_plus` | ^10.0.0 | Native share sheet for exports |
| `google_fonts` | ^6.1.0 | Google Fonts (Inter typeface) |
| `geolocator` | ^13.0.2 | Real-time GPS positioning |
| `permission_handler` | ^11.3.0 | Runtime permission management |
| `image_picker` | ^1.1.2 | Camera and gallery image capture |
| `pdf` | ^3.11.2 | PDF document generation |
| `printing` | ^5.13.5 | PDF preview and printing |

## Dev Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_test` | SDK | Unit and widget testing |
| `flutter_lints` | ^3.0.0 | Dart lint rules |
| `integration_test` | SDK | Integration testing framework |

## Environment

| Requirement | Constraint |
|-------------|-----------|
| Dart SDK | ≥3.0.0 <4.0.0 |
| Flutter | 3.22.0 (CI) |
| Java | 17 (Android builds) |
| Android minSdk | 24 |
| Android compileSdk | 35 |

## Not Yet Added (Planned)

| Package | Purpose | Blocker |
|---------|---------|---------|
| `google_mlkit_object_detection` | On-device object detection | Requires native setup |
| `google_mlkit_image_labeling` | Image classification | Requires native setup |
| `google_mlkit_barcode_scanning` | Barcode/QR scanning | Requires native setup |
| `google_mlkit_text_recognition` | OCR text extraction | Requires native setup |
