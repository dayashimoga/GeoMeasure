import '../../../measurement_engine/domain/entities/measurement_result.dart';

/// A project groups related measurements together.
///
/// Supports folders, tags, and metadata for professional use.
class Project {
  final String id;
  final String name;
  final String? description;
  final String? folder;
  final List<String> tags;
  final List<MeasurementResult> measurements;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProjectType type;
  final ProjectStatus status;

  Project({
    required this.id,
    required this.name,
    this.description,
    this.folder,
    this.tags = const [],
    this.measurements = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.type = ProjectType.general,
    this.status = ProjectStatus.active,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Project copyWith({
    String? name,
    String? description,
    String? folder,
    List<String>? tags,
    List<MeasurementResult>? measurements,
    DateTime? updatedAt,
    ProjectType? type,
    ProjectStatus? status,
  }) =>
      Project(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        folder: folder ?? this.folder,
        tags: tags ?? this.tags,
        measurements: measurements ?? this.measurements,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
        type: type ?? this.type,
        status: status ?? this.status,
      );

  int get measurementCount => measurements.length;

  double get totalArea {
    if (measurements.isEmpty) return 0.0;
    return measurements.fold(0.0, (sum, m) => sum + m.area);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'folder': folder,
        'tags': tags,
        'measurements': measurements.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'type': type.name,
        'status': status.name,
      };

  factory Project.fromJson(Map<String, dynamic> map) => Project(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        folder: map['folder'] as String?,
        tags:
            (map['tags'] as List<dynamic>?)?.map((t) => t as String).toList() ??
                [],
        measurements: (map['measurements'] as List<dynamic>?)
                ?.map(
                  (m) => MeasurementResult.fromJson(m as Map<String, dynamic>),
                )
                .toList() ??
            [],
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        type: ProjectType.values.firstWhere(
          (e) => e.name == (map['type'] as String?),
          orElse: () => ProjectType.general,
        ),
        status: ProjectStatus.values.firstWhere(
          (e) => e.name == (map['status'] as String?),
          orElse: () => ProjectStatus.active,
        ),
      );
}

enum ProjectType {
  general,
  indoor,
  outdoor,
  room,
  land,
  building,
  construction,
  survey,
}

enum ProjectStatus {
  active,
  archived,
  completed,
  draft,
}
