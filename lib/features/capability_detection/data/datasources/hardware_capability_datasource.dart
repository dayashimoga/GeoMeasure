import '../../../../core/platform/platform_channel_service.dart';
import '../../domain/entities/capability_profile.dart';

abstract class HardwareCapabilityDataSource {
  Future<CapabilityProfile> probeHardware();
}

class HardwareCapabilityDataSourceImpl implements HardwareCapabilityDataSource {
  final PlatformChannelService platformChannelService;

  HardwareCapabilityDataSourceImpl({PlatformChannelService? platformService})
      : platformChannelService = platformService ?? PlatformChannelService();

  @override
  Future<CapabilityProfile> probeHardware() async {
    return await platformChannelService.detectCapabilities();
  }
}
