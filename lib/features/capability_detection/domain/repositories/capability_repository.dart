import '../entities/capability_profile.dart';

abstract class CapabilityRepository {
  Future<CapabilityProfile> detectCapabilities();
}
