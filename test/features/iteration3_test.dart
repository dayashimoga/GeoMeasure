import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:geomeasure/features/camera/camera_service.dart';
import 'package:geomeasure/features/export/pdf_exporter.dart';
import 'package:geomeasure/core/export/export_manager.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_result.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_algorithm.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_unit.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/spatial_shape.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/geodetic_calculator.dart';
import 'package:geomeasure/features/project_management/domain/entities/project.dart';
import 'package:geomeasure/features/cloud_sync/cloud_sync_service.dart';
import 'package:geomeasure/features/offline_maps/map_tile_cache_service.dart';
import 'package:geomeasure/features/auth/auth_service.dart';
import 'package:geomeasure/features/ar_measurement/ar_measurement_service.dart';

void main() {
  // ━━━ CapturedPhoto Serialization ━━━
  group('CapturedPhoto', () {
    test('serialization round-trip', () {
      final photo = CapturedPhoto(
        filePath: '/photos/room_1.jpg',
        latitude: 37.7749,
        longitude: -122.4194,
        description: 'Living room corner',
        annotations: [
          const PhotoAnnotation(
            x: 10,
            y: 20,
            label: '2.5m',
            type: AnnotationType.dimension,
          ),
          const PhotoAnnotation(
            x: 50,
            y: 30,
            label: 'Wall A',
            type: AnnotationType.label,
          ),
        ],
      );

      final json = photo.toJson();
      final restored = CapturedPhoto.fromJson(json);

      expect(restored.filePath, photo.filePath);
      expect(restored.latitude, photo.latitude);
      expect(restored.longitude, photo.longitude);
      expect(restored.description, photo.description);
      expect(restored.annotations.length, 2);
      expect(restored.annotations[0].label, '2.5m');
      expect(restored.annotations[0].type, AnnotationType.dimension);
      expect(restored.annotations[1].label, 'Wall A');
      expect(restored.annotations[1].type, AnnotationType.label);
    });

    test('copyWith preserves fields', () {
      final photo = CapturedPhoto(
        filePath: '/test.jpg',
        latitude: 10.0,
        longitude: 20.0,
      );
      final annotated = photo.copyWith(
        description: 'Updated',
        annotations: [
          const PhotoAnnotation(x: 5, y: 10, label: '3m'),
        ],
      );
      expect(annotated.filePath, photo.filePath);
      expect(annotated.latitude, photo.latitude);
      expect(annotated.description, 'Updated');
      expect(annotated.annotations.length, 1);
    });
  });

  // ━━━ PDF Exporter ━━━
  group('PdfExporter', () {
    test('generates measurement report with valid PDF header', () async {
      final result = MeasurementResult(
        area: 25.5,
        areaUnit: AreaUnit.squareMeters,
        perimeter: 20.0,
        distanceUnit: DistanceUnit.meters,
        volume: 76.5,
        algorithmUsed: MeasurementAlgorithm.arCoreArKit,
        estimatedAccuracyPercentage: 95.0,
        shapeType: ShapeType.room,
        shapeName: 'Living Room',
      );

      final bytes = await PdfExporter.generateMeasurementReport(result);
      expect(bytes.length, greaterThan(100));

      // PDF magic number: %PDF
      expect(bytes[0], 0x25);
      expect(bytes[1], 0x50);
      expect(bytes[2], 0x44);
      expect(bytes[3], 0x46);
    });

    test('generates project report with multiple measurements', () async {
      final project = Project(
        id: 'p1',
        name: 'Test Project',
        description: 'Full integration test',
        tags: ['indoor', 'commercial'],
        measurements: [
          MeasurementResult(
            area: 25.0,
            areaUnit: AreaUnit.squareMeters,
            perimeter: 20.0,
            distanceUnit: DistanceUnit.meters,
            volume: 75.0,
            algorithmUsed: MeasurementAlgorithm.manual,
            estimatedAccuracyPercentage: 98.0,
            shapeType: ShapeType.room,
            shapeName: 'Room 1',
          ),
          MeasurementResult(
            area: 40.0,
            areaUnit: AreaUnit.squareMeters,
            perimeter: 26.0,
            distanceUnit: DistanceUnit.meters,
            volume: 120.0,
            algorithmUsed: MeasurementAlgorithm.lidar,
            estimatedAccuracyPercentage: 99.5,
            shapeType: ShapeType.room,
            shapeName: 'Room 2',
          ),
        ],
      );

      final bytes = await PdfExporter.generateProjectReport(project);
      expect(bytes.length, greaterThan(100));
      expect(bytes[0], 0x25); // %PDF
    });
  });

  // ━━━ Export Manager ━━━
  group('ExportManager', () {
    test('supported formats for rectangle', () {
      const rect = RectangleShape(lengthMeters: 5, widthMeters: 3);
      final formats = ExportManager.supportedFormats(rect);
      expect(formats, contains(ExportFormat.dxf));
      expect(formats, contains(ExportFormat.svg));
      expect(formats, contains(ExportFormat.csv));
      expect(formats, contains(ExportFormat.pdf));
    });

    test('supported formats for plot', () {
      const plot = PlotShape(coordinates: [
        GpsCoordinate(latitude: 0, longitude: 0),
        GpsCoordinate(latitude: 1, longitude: 0),
        GpsCoordinate(latitude: 1, longitude: 1),
      ]);
      final formats = ExportManager.supportedFormats(plot);
      expect(formats, contains(ExportFormat.geoJson));
      expect(formats, contains(ExportFormat.kml));
    });

    test('file extensions are correct', () {
      expect(ExportManager.fileExtension(ExportFormat.dxf), '.dxf');
      expect(ExportManager.fileExtension(ExportFormat.csv), '.csv');
      expect(ExportManager.fileExtension(ExportFormat.geoJson), '.geojson');
      expect(ExportManager.fileExtension(ExportFormat.svg), '.svg');
      expect(ExportManager.fileExtension(ExportFormat.kml), '.kml');
      expect(ExportManager.fileExtension(ExportFormat.pdf), '.pdf');
    });

    test('MIME types are correct', () {
      expect(ExportManager.mimeType(ExportFormat.csv), 'text/csv');
      expect(ExportManager.mimeType(ExportFormat.geoJson), 'application/geo+json');
      expect(ExportManager.mimeType(ExportFormat.kml), 'application/vnd.google-earth.kml+xml');
    });

    test('export to string generates valid content', () {
      const rect = RectangleShape(lengthMeters: 5, widthMeters: 3);
      final dxf = ExportManager.exportToString(format: ExportFormat.dxf, shape: rect);
      expect(dxf, contains('LINE'));

      final svg = ExportManager.exportToString(format: ExportFormat.svg, shape: rect);
      expect(svg, contains('<svg'));
    });
  });

  // ━━━ SyncableEntity ━━━
  group('SyncableEntity', () {
    test('serialization round-trip', () {
      final entity = SyncableEntity(
        id: 'proj-1',
        type: 'project',
        data: {'name': 'Site A', 'area': 250.5},
        modifiedAt: DateTime(2026, 7, 26, 10, 30),
        version: 3,
        isDirty: true,
      );

      final json = entity.toJson();
      final restored = SyncableEntity.fromJson(json);

      expect(restored.id, entity.id);
      expect(restored.type, entity.type);
      expect(restored.data['name'], 'Site A');
      expect(restored.version, 3);
      expect(restored.isDirty, true);
    });

    test('markDirty updates timestamp and sets dirty flag', () {
      final entity = SyncableEntity(
        id: 'e1',
        type: 'measurement',
        data: {'value': 42},
        modifiedAt: DateTime(2026, 1, 1),
      );
      final dirty = entity.markDirty();

      expect(dirty.isDirty, true);
      expect(dirty.modifiedAt.isAfter(entity.modifiedAt), true);
      expect(dirty.checksum, isNotNull);
    });

    test('markClean increments version', () {
      final entity = SyncableEntity(
        id: 'e1',
        type: 'measurement',
        data: {'value': 42},
        modifiedAt: DateTime.now(),
        version: 2,
        isDirty: true,
      );
      final clean = entity.markClean();
      expect(clean.isDirty, false);
      expect(clean.version, 3);
    });
  });

  // ━━━ SyncConflict Resolution ━━━
  group('SyncConflict', () {
    test('serverWins returns remote entity', () {
      final local = SyncableEntity(
        id: 'c1', type: 'project', data: {'name': 'Local'},
        modifiedAt: DateTime(2026, 7, 26, 10, 0), version: 1,
      );
      final remote = SyncableEntity(
        id: 'c1', type: 'project', data: {'name': 'Remote'},
        modifiedAt: DateTime(2026, 7, 26, 11, 0), version: 2,
      );
      final conflict = SyncConflict(local: local, remote: remote);
      final resolved = conflict.resolve(ConflictStrategy.serverWins);
      expect(resolved.data['name'], 'Remote');
    });

    test('clientWins returns local entity with bumped version', () {
      final local = SyncableEntity(
        id: 'c1', type: 'project', data: {'name': 'Local'},
        modifiedAt: DateTime(2026, 7, 26, 12, 0), version: 1,
      );
      final remote = SyncableEntity(
        id: 'c1', type: 'project', data: {'name': 'Remote'},
        modifiedAt: DateTime(2026, 7, 26, 11, 0), version: 3,
      );
      final conflict = SyncConflict(local: local, remote: remote);
      final resolved = conflict.resolve(ConflictStrategy.clientWins);
      expect(resolved.data['name'], 'Local');
      expect(resolved.version, 4); // remote.version + 1
    });

    test('lastWriteWins picks most recent', () {
      final older = SyncableEntity(
        id: 'c1', type: 'project', data: {'name': 'Older'},
        modifiedAt: DateTime(2026, 7, 26, 10, 0), version: 1,
      );
      final newer = SyncableEntity(
        id: 'c1', type: 'project', data: {'name': 'Newer'},
        modifiedAt: DateTime(2026, 7, 26, 12, 0), version: 2,
      );
      final conflict = SyncConflict(local: older, remote: newer);
      final resolved = conflict.resolve(ConflictStrategy.lastWriteWins);
      expect(resolved.data['name'], 'Newer');
    });
  });

  // ━━━ GeoBounds ━━━
  group('GeoBounds', () {
    test('contains check', () {
      const bounds = GeoBounds(north: 38, south: 37, east: -122, west: -123);
      expect(bounds.contains(37.5, -122.5), true);
      expect(bounds.contains(39, -122.5), false); // too north
      expect(bounds.contains(37.5, -121), false); // too east
    });

    test('serialization round-trip', () {
      const bounds = GeoBounds(north: 38, south: 37, east: -122, west: -123);
      final json = bounds.toJson();
      final restored = GeoBounds.fromJson(json);
      expect(restored.north, bounds.north);
      expect(restored.south, bounds.south);
    });

    test('tile count estimation', () {
      const bounds = GeoBounds(north: 37.8, south: 37.7, east: -122.3, west: -122.5);
      final count = bounds.estimateTileCount(14, 16);
      expect(count, greaterThan(0));
    });
  });

  // ━━━ CachedRegion ━━━
  group('CachedRegion', () {
    test('formatted size displays correctly', () {
      final region = CachedRegion(
        id: 'r1',
        name: 'Test Area',
        bounds: const GeoBounds(north: 38, south: 37, east: -122, west: -123),
        tileCount: 100,
        sizeBytes: 5242880, // 5 MB
        cachedAt: DateTime.now(),
      );
      expect(region.formattedSize, '5.0 MB');
    });

    test('serialization round-trip', () {
      final region = CachedRegion(
        id: 'r1',
        name: 'Downtown',
        bounds: const GeoBounds(north: 37.8, south: 37.7, east: -122.3, west: -122.5),
        minZoom: 12,
        maxZoom: 17,
        tileCount: 250,
        sizeBytes: 1048576,
        cachedAt: DateTime(2026, 7, 26),
      );
      final json = region.toJson();
      final restored = CachedRegion.fromJson(json);
      expect(restored.name, 'Downtown');
      expect(restored.tileCount, 250);
      expect(restored.minZoom, 12);
    });
  });

  // ━━━ AppUser ━━━
  group('AppUser', () {
    test('serialization round-trip', () {
      final user = AppUser(
        uid: 'user-123',
        email: 'test@example.com',
        displayName: 'Test User',
        method: AuthMethod.email,
        createdAt: DateTime(2026, 7, 26, 10, 0),
        lastSignInAt: DateTime(2026, 7, 26, 14, 30),
      );

      final json = user.toJson();
      final restored = AppUser.fromJson(json);

      expect(restored.uid, user.uid);
      expect(restored.email, user.email);
      expect(restored.displayName, user.displayName);
      expect(restored.method, AuthMethod.email);
    });

    test('copyWith updates lastSignInAt', () {
      final user = AppUser(
        uid: 'u1',
        email: 'a@b.com',
        method: AuthMethod.email,
        createdAt: DateTime(2026, 1, 1),
        lastSignInAt: DateTime(2026, 1, 1),
      );
      final updated = user.copyWith(lastSignInAt: DateTime(2026, 7, 26));
      expect(updated.uid, user.uid);
      expect(updated.lastSignInAt.year, 2026);
      expect(updated.lastSignInAt.month, 7);
    });
  });

  // ━━━ Auth Validation ━━━
  group('Auth validation', () {
    late LocalAuthService authService;

    setUp(() async {
      Hive.init('.hive_test_${DateTime.now().millisecondsSinceEpoch}');
      authService = LocalAuthService();
    });

    tearDown(() async {
      authService.dispose();
    });

    test('sign up rejects short password', () async {
      final result = await authService.signUp(
        email: 'test@example.com',
        password: 'short',
      );
      expect(result.success, false);
      expect(result.errorMessage, contains('8 characters'));
    });

    test('sign up rejects invalid email', () async {
      final result = await authService.signUp(
        email: 'invalid',
        password: 'ValidPass123',
      );
      expect(result.success, false);
      expect(result.errorMessage, contains('email'));
    });

    test('sign up and sign in round-trip', () async {
      final signUp = await authService.signUp(
        email: 'alice@geo.com',
        password: 'SecurePass99',
        displayName: 'Alice',
      );
      expect(signUp.success, true);
      expect(signUp.user?.email, 'alice@geo.com');
      expect(signUp.user?.displayName, 'Alice');

      await authService.signOut();

      final signIn = await authService.signIn(
        email: 'alice@geo.com',
        password: 'SecurePass99',
      );
      expect(signIn.success, true);
      expect(signIn.user?.email, 'alice@geo.com');
    });

    test('sign in fails with wrong password', () async {
      await authService.signUp(
        email: 'bob@geo.com',
        password: 'CorrectPass1',
      );
      await authService.signOut();

      final result = await authService.signIn(
        email: 'bob@geo.com',
        password: 'WrongPass99',
      );
      expect(result.success, false);
      expect(result.errorMessage, contains('Invalid password'));
    });

    test('anonymous sign in works', () async {
      final result = await authService.signInAnonymously();
      expect(result.success, true);
      expect(result.user?.method, AuthMethod.anonymous);
      expect(result.user?.displayName, 'Guest');
    });

    test('duplicate sign up rejected', () async {
      await authService.signUp(email: 'dup@geo.com', password: 'Pass1234Aa');
      final result =
          await authService.signUp(email: 'dup@geo.com', password: 'Pass1234Aa');
      expect(result.success, false);
      expect(result.errorMessage, contains('already exists'));
    });
  });

  // ━━━ AR Measurement ━━━
  group('ArMeasurement', () {
    test('ManualArEngine places anchors at scaled positions', () async {
      final engine = ManualArEngine(pixelsPerMeter: 100);
      await engine.startSession();

      final a = await engine.hitTest(0, 0);
      expect(a, isNotNull);
      expect(a!.position.x, 0.0);
      expect(a.position.y, 0.0);

      final b = await engine.hitTest(300, 400);
      expect(b, isNotNull);
      expect(b!.position.x, 3.0);
      expect(b.position.y, 4.0);

      engine.dispose();
    });

    test('ArAnchor serialization', () {
      final anchor = ArAnchor(
        id: 'a1',
        position: const Point3D(1.5, 2.5, 0.3),
        placedAt: DateTime(2026, 7, 26),
      );
      final json = anchor.toJson();
      final restored = ArAnchor.fromJson(json);
      expect(restored.id, 'a1');
      expect(restored.position.x, 1.5);
      expect(restored.position.y, 2.5);
      expect(restored.position.z, 0.3);
    });

    test('provider calculates perimeter and area', () async {
      final engine = ManualArEngine(pixelsPerMeter: 100);
      final provider = ArMeasurementProvider(engine: engine);
      await provider.initialize();

      // Place a 3-4-5 right triangle
      await provider.placeAnchor(0, 0);
      await provider.placeAnchor(300, 0);
      await provider.placeAnchor(300, 400);

      expect(provider.anchors.length, 3);
      expect(provider.measurements.length, 2);
      expect(provider.totalPerimeter, closeTo(7.0, 0.01)); // 3 + 4 = 7 (two segments)

      // Area of 3×4 right triangle = 6
      expect(provider.estimatedArea, closeTo(6.0, 0.01));

      provider.dispose();
    });

    test('undo removes last anchor and measurement', () async {
      final engine = ManualArEngine(pixelsPerMeter: 100);
      final provider = ArMeasurementProvider(engine: engine);
      await provider.initialize();

      await provider.placeAnchor(0, 0);
      await provider.placeAnchor(100, 0);
      await provider.placeAnchor(100, 100);

      expect(provider.anchors.length, 3);
      expect(provider.measurements.length, 2);

      provider.undoLastAnchor();
      expect(provider.anchors.length, 2);
      expect(provider.measurements.length, 1);

      provider.dispose();
    });
  });
}
