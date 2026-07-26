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
import '../../features/project_management/data/datasources/project_local_datasource.dart';
import '../../features/project_management/data/repositories/project_repository_impl.dart';
import '../../features/project_management/domain/repositories/project_repository.dart';
import '../../features/project_management/presentation/providers/project_provider.dart';
import '../commands/command.dart';
import '../config/app_config.dart';
import '../logging/app_logger.dart';
import '../platform/platform_channel_service.dart';

/// Manual dependency injection / service locator.
///
/// Initializes all feature modules in dependency order.
/// In production, consider migrating to `get_it` or `riverpod`
/// for more scalable DI.
class ServiceLocator {
  // ── Core ──
  late final AppConfig config;
  late final AppLogger appLogger;
  late final CommandManager commandManager;
  late final PlatformChannelService platformChannelService;

  // ── Capability Detection ──
  late final HardwareCapabilityDataSource hardwareCapabilityDataSource;
  late final CapabilityRepository capabilityRepository;
  late final DetectCapabilitiesUseCase detectCapabilitiesUseCase;
  late final CapabilityProvider capabilityProvider;

  // ── Measurement Engine ──
  late final MeasurementLocalDataSource measurementLocalDataSource;
  late final MeasurementRepository measurementRepository;
  late final ExecuteMeasurementUseCase executeMeasurementUseCase;
  late final MeasurementProvider measurementProvider;

  // ── Project Management ──
  late final ProjectLocalDataSource projectLocalDataSource;
  late final ProjectRepository projectRepository;
  late final ProjectProvider projectProvider;

  void init() {
    // Core services
    config = AppConfig();
    appLogger = AppLogger();
    commandManager = CommandManager(
      maxStackDepth: AppConfig.maxUndoStackDepth,
    );

    // Platform
    platformChannelService = PlatformChannelService();

    // Capability Detection
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

    // Measurement Engine
    measurementLocalDataSource = MeasurementLocalDataSourceImpl();
    measurementRepository = MeasurementRepositoryImpl(
      measurementLocalDataSource,
    );
    executeMeasurementUseCase = ExecuteMeasurementUseCase();
    measurementProvider = MeasurementProvider(
      executeMeasurementUseCase: executeMeasurementUseCase,
      repository: measurementRepository,
    );

    // Project Management
    projectLocalDataSource = ProjectLocalDataSourceImpl();
    projectRepository = ProjectRepositoryImpl(projectLocalDataSource);
    projectProvider = ProjectProvider(repository: projectRepository);

    appLogger.info('ServiceLocator initialized', tag: 'DI');
  }
}

final sl = ServiceLocator();
