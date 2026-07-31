import 'dart:convert';

/// Tracks version history of project changes.
///
/// Each snapshot captures the project state at a point in time.
class ProjectVersionHistory {
  final List<ProjectSnapshot> _snapshots = [];

  List<ProjectSnapshot> get snapshots => List.unmodifiable(_snapshots);
  int get count => _snapshots.length;
  bool get isEmpty => _snapshots.isEmpty;

  /// Record a new snapshot.
  void addSnapshot({
    required String projectId,
    required Map<String, dynamic> data,
    String changeDescription = '',
  }) {
    _snapshots.add(ProjectSnapshot(
      version: _snapshots.length + 1,
      projectId: projectId,
      data: data,
      changeDescription: changeDescription,
      timestamp: DateTime.now(),
    ));
  }

  /// Get snapshot at a specific version (1-indexed).
  ProjectSnapshot? getVersion(int version) {
    if (version < 1 || version > _snapshots.length) return null;
    return _snapshots[version - 1];
  }

  /// Get the latest snapshot.
  ProjectSnapshot? get latest => _snapshots.isEmpty ? null : _snapshots.last;

  /// Compare two versions and return the diff keys.
  List<String> diffKeys(int versionA, int versionB) {
    final a = getVersion(versionA);
    final b = getVersion(versionB);
    if (a == null || b == null) return [];

    final allKeys = {...a.data.keys, ...b.data.keys};
    return allKeys
        .where((k) => jsonEncode(a.data[k]) != jsonEncode(b.data[k]))
        .toList();
  }

  /// Serialize all snapshots.
  List<Map<String, dynamic>> toJson() =>
      _snapshots.map((s) => s.toJson()).toList();

  /// Restore from serialized data.
  void loadFromJson(List<dynamic> list) {
    _snapshots.clear();
    for (final item in list) {
      _snapshots.add(ProjectSnapshot.fromJson(item as Map<String, dynamic>));
    }
  }
}

/// A single version snapshot of a project.
class ProjectSnapshot {
  final int version;
  final String projectId;
  final Map<String, dynamic> data;
  final String changeDescription;
  final DateTime timestamp;

  const ProjectSnapshot({
    required this.version,
    required this.projectId,
    required this.data,
    this.changeDescription = '',
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'projectId': projectId,
        'data': data,
        'changeDescription': changeDescription,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ProjectSnapshot.fromJson(Map<String, dynamic> json) =>
      ProjectSnapshot(
        version: json['version'] as int,
        projectId: json['projectId'] as String,
        data: json['data'] as Map<String, dynamic>,
        changeDescription: json['changeDescription'] as String? ?? '',
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
