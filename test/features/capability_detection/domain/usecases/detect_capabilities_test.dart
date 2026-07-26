import 'package:flutter_test/flutter_test.dart';
import 'package:meassure_app/core/usecases/usecase.dart';
import 'package:meassure_app/features/capability_detection/data/datasources/hardware_capability_datasource.dart';
import 'package:meassure_app/features/capability_detection/data/repositories/capability_repository_impl.dart';
import 'package:meassure_app/features/capability_detection/domain/usecases/detect_capabilities_usecase.dart';

void main() {
  group('DetectCapabilitiesUseCase Tests', () {
    test('should return probed CapabilityProfile successfully', () async {
      final dataSource = HardwareCapabilityDataSourceImpl();
      final repository = CapabilityRepositoryImpl(dataSource);
      final useCase = DetectCapabilitiesUseCase(repository);

      final profile = await useCase(const NoParams());

      expect(profile.ramMb, greaterThan(0));
      expect(profile.cpuCores, greaterThan(0));
      expect(profile.permissionsGranted, isTrue);
    });
  });
}
