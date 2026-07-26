import '../../features/capability_detection/data/datasources/hardware_capability_datasource.dart';
import '../../features/capability_detection/data/repositories/capability_repository_impl.dart';
import '../../features/capability_detection/domain/repositories/capability_repository.dart';
import '../../features/capability_detection/domain/usecases/detect_capabilities_usecase.dart';
import '../../features/capability_detection/presentation/providers/capability_provider.dart';
import '../../features/measurement_engine/data/datasources/measurement_local_datasource.dart';
import '../../features/measurement_engine/data/repositories/measurement_repository_impl.dart';
import '../../features/measurement_engine/domain/repositories/measurement_repository.dart';
import '../../features/measurement_engine/domain/usecases/execute_measurement_usecase.dart';
import '../../features/measurement_engine/presentation/providers/measurement_provider.dart';
import '../platform/platform_channel_service.dart';

class ServiceLocator {
  late final PlatformChannelService platformChannelService;
  late final HardwareCapabilityDataSource hardwareCapabilityDataSource;
  late final CapabilityRepository capabilityRepository;
  late final DetectCapabilitiesUseCase detectCapabilitiesUseCase;
  late final CapabilityProvider capabilityProvider;

  late final MeasurementLocalDataSource measurementLocalDataSource;
  late final MeasurementRepository measurementRepository;
  late final ExecuteMeasurementUseCase executeMeasurementUseCase;
  late final MeasurementProvider measurementProvider;

  void init() {
    platformChannelService = PlatformChannelService();
    hardwareCapabilityDataSource = HardwareCapabilityDataSourceImpl(
      platformService: platformChannelService,
    );
    capabilityRepository = CapabilityRepositoryImpl(
      hardwareCapabilityDataSource,
    );
    detectCapabilitiesUseCase = DetectCapabilitiesUseCase(
      capabilityRepository,
    );
    capabilityProvider = CapabilityProvider(
      detectCapabilitiesUseCase: detectCapabilitiesUseCase,
    );

    measurementLocalDataSource = MeasurementLocalDataSourceImpl();
    measurementRepository = MeasurementRepositoryImpl(
      measurementLocalDataSource,
    );
    executeMeasurementUseCase = ExecuteMeasurementUseCase();
    measurementProvider = MeasurementProvider(
      executeMeasurementUseCase: executeMeasurementUseCase,
      repository: measurementRepository,
    );
  }
}

final sl = ServiceLocator();
