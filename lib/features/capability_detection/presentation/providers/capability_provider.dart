import 'package:flutter/foundation.dart';
import 'package:geomeasure/core/usecases/usecase.dart';
import '../../domain/entities/capability_profile.dart';
import '../../domain/usecases/detect_capabilities_usecase.dart';

class CapabilityProvider extends ChangeNotifier {
  final DetectCapabilitiesUseCase detectCapabilitiesUseCase;

  CapabilityProfile _profile = CapabilityProfile.fallbackManual();
  bool _isLoading = false;

  CapabilityProfile get profile => _profile;
  bool get isLoading => _isLoading;

  CapabilityProvider({required this.detectCapabilitiesUseCase});

  Future<void> loadCapabilities() async {
    _isLoading = true;
    notifyListeners();

    _profile = await detectCapabilitiesUseCase(const NoParams());
    _isLoading = false;
    notifyListeners();
  }
}
