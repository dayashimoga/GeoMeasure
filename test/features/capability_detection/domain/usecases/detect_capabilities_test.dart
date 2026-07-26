import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/core/usecases/usecase.dart';
import 'package:geomeasure/features/capability_detection/data/datasources/hardware_capability_datasource.dart';
import 'package:geomeasure/features/capability_detection/data/repositories/capability_repository_impl.dart';
import 'package:geomeasure/features/capability_detection/domain/usecases/detect_capabilities_usecase.dart';

void main() {
  group('DetectCapabilitiesUseCase', () {
    test('returns probed CapabilityProfile successfully', () async {
      final dataSource = HardwareCapabilityDataSourceImpl();
      final repository = CapabilityRepositoryImpl(dataSource);
      final useCase = DetectCapabilitiesUseCase(repository);

      final profile = await useCase(const NoParams());

      expect(profile.ramMb, greaterThan(0));
      expect(profile.cpuCores, greaterThan(0));
      expect(profile.permissionsGranted, isTrue);
      expect(profile.osVersion, isNotEmpty);
    });
  });
}
