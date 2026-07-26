import 'package:flutter_test/flutter_test.dart';
import 'package:meassure_app/features/capability_detection/data/datasources/hardware_capability_datasource.dart';
import 'package:meassure_app/features/capability_detection/data/repositories/capability_repository_impl.dart';
import 'package:meassure_app/features/capability_detection/domain/usecases/detect_capabilities_usecase.dart';
import 'package:meassure_app/features/capability_detection/presentation/providers/capability_provider.dart';

void main() {
  group('CapabilityProvider State Tests', () {
    test('loadCapabilities updates profile and resets loading flag', () async {
      final dataSource = HardwareCapabilityDataSourceImpl();
      final repository = CapabilityRepositoryImpl(dataSource);
      final useCase = DetectCapabilitiesUseCase(repository);
      final provider = CapabilityProvider(detectCapabilitiesUseCase: useCase);

      expect(provider.profile, isNull);

      await provider.loadCapabilities();

      expect(provider.isLoading, isFalse);
      expect(provider.profile, isNotNull);
    });
  });
}
