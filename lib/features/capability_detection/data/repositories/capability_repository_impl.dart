import '../../domain/entities/capability_profile.dart';
import '../../domain/repositories/capability_repository.dart';
import '../datasources/hardware_capability_datasource.dart';

class CapabilityRepositoryImpl implements CapabilityRepository {
  final HardwareCapabilityDataSource dataSource;

  CapabilityRepositoryImpl(this.dataSource);

  @override
  Future<CapabilityProfile> detectCapabilities() async {
    try {
      return await dataSource.probeHardware();
    } catch (_) {
      return CapabilityProfile.fallbackManual();
    }
  }
}
