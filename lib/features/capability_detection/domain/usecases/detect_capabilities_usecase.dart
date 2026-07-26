import '../../../../core/usecases/usecase.dart';
import '../entities/capability_profile.dart';
import '../repositories/capability_repository.dart';

class DetectCapabilitiesUseCase
    implements UseCase<CapabilityProfile, NoParams> {
  final CapabilityRepository repository;

  DetectCapabilitiesUseCase(this.repository);

  @override
  Future<CapabilityProfile> call(NoParams params) async {
    return await repository.detectCapabilities();
  }
}
