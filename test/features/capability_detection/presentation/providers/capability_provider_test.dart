import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/capability_detection/data/datasources/hardware_capability_datasource.dart';
import 'package:geomeasure/features/capability_detection/data/repositories/capability_repository_impl.dart';
import 'package:geomeasure/features/capability_detection/domain/usecases/detect_capabilities_usecase.dart';
import 'package:geomeasure/features/capability_detection/presentation/providers/capability_provider.dart';

void main() {
  group('CapabilityProvider', () {
    test('loadCapabilities populates profile and clears loading', () async {
      final dataSource = HardwareCapabilityDataSourceImpl();
      final repository = CapabilityRepositoryImpl(dataSource);
      final useCase = DetectCapabilitiesUseCase(repository);
      final provider = CapabilityProvider(detectCapabilitiesUseCase: useCase);

      expect(provider.profile, isNotNull);
      await provider.loadCapabilities();
      expect(provider.isLoading, isFalse);
      expect(provider.profile, isNotNull);
      expect(provider.profile.osVersion, isNotEmpty);
    });
  });
}
