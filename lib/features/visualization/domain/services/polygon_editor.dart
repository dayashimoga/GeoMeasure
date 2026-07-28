import 'dart:math' as math;
import '../../../measurement_engine/domain/entities/spatial_shape.dart';

/// Interactive polygon editing operations for floor plan canvas.
///
/// Supports vertex add, delete, split edge, merge polygons,
/// rotate, scale, and snap operations.
class PolygonEditor {
  List<Point3D> _vertices;
  final List<List<Point3D>> _history = [];
  int _historyIndex = -1;

  PolygonEditor(List<Point3D> vertices)
      : _vertices = List.of(vertices) {
    _pushHistory();
  }

  List<Point3D> get vertices => List.unmodifiable(_vertices);
  int get vertexCount => _vertices.length;
  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  void _pushHistory() {
    // Trim any redo history
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(List.of(_vertices));
    _historyIndex = _history.length - 1;
  }

  /// Undo last operation.
  List<Point3D> undo() {
    if (canUndo) {
      _historyIndex--;
      _vertices = List.of(_history[_historyIndex]);
    }
    return vertices;
  }

  /// Redo last undone operation.
  List<Point3D> redo() {
    if (canRedo) {
      _historyIndex++;
      _vertices = List.of(_history[_historyIndex]);
    }
    return vertices;
  }

  /// Add a vertex at a specific index.
  List<Point3D> addVertex(int index, Point3D point) {
    if (index < 0 || index > _vertices.length) {
      throw RangeError('Index $index out of range [0, ${_vertices.length}]');
    }
    _vertices.insert(index, point);
    _pushHistory();
    return vertices;
  }

  /// Add a vertex at the end.
  List<Point3D> appendVertex(Point3D point) {
    _vertices.add(point);
    _pushHistory();
    return vertices;
  }

  /// Delete a vertex by index. Minimum 3 vertices maintained.
  List<Point3D> deleteVertex(int index) {
    if (_vertices.length <= 3) {
      throw StateError('Cannot delete vertex: minimum 3 vertices required');
    }
    if (index < 0 || index >= _vertices.length) {
      throw RangeError('Index $index out of range [0, ${_vertices.length - 1}]');
    }
    _vertices.removeAt(index);
    _pushHistory();
    return vertices;
  }

  /// Move a vertex to a new position.
  List<Point3D> moveVertex(int index, Point3D newPosition) {
    if (index < 0 || index >= _vertices.length) {
      throw RangeError('Index $index out of range');
    }
    _vertices[index] = newPosition;
    _pushHistory();
    return vertices;
  }

  /// Split an edge by inserting a midpoint between vertex[index] and vertex[index+1].
  List<Point3D> splitEdge(int index) {
    if (_vertices.length < 2) {
      throw StateError('Need at least 2 vertices to split an edge');
    }
    final nextIndex = (index + 1) % _vertices.length;
    final p1 = _vertices[index];
    final p2 = _vertices[nextIndex];
    final mid = Point3D(
      (p1.x + p2.x) / 2,
      (p1.y + p2.y) / 2,
      (p1.z + p2.z) / 2,
    );
    _vertices.insert(nextIndex, mid);
    _pushHistory();
    return vertices;
  }

  /// Rotate all vertices around centroid by given angle in degrees.
  List<Point3D> rotate(double angleDegrees) {
    if (_vertices.isEmpty) return vertices;
    final cx = _vertices.map((v) => v.x).reduce((a, b) => a + b) / _vertices.length;
    final cy = _vertices.map((v) => v.y).reduce((a, b) => a + b) / _vertices.length;
    final rad = angleDegrees * math.pi / 180.0;
    final cosA = math.cos(rad);
    final sinA = math.sin(rad);

    _vertices = _vertices.map((v) {
      final dx = v.x - cx;
      final dy = v.y - cy;
      return Point3D(
        cx + dx * cosA - dy * sinA,
        cy + dx * sinA + dy * cosA,
        v.z,
      );
    }).toList();
    _pushHistory();
    return vertices;
  }

  /// Scale all vertices from centroid by given factor.
  List<Point3D> scale(double factor) {
    if (_vertices.isEmpty || factor <= 0) return vertices;
    final cx = _vertices.map((v) => v.x).reduce((a, b) => a + b) / _vertices.length;
    final cy = _vertices.map((v) => v.y).reduce((a, b) => a + b) / _vertices.length;

    _vertices = _vertices.map((v) {
      return Point3D(
        cx + (v.x - cx) * factor,
        cy + (v.y - cy) * factor,
        v.z,
      );
    }).toList();
    _pushHistory();
    return vertices;
  }

  /// Snap a vertex to the nearest grid increment.
  List<Point3D> snapVertex(int index, double gridSize) {
    if (index < 0 || index >= _vertices.length) return vertices;
    final v = _vertices[index];
    _vertices[index] = Point3D(
      (v.x / gridSize).round() * gridSize,
      (v.y / gridSize).round() * gridSize,
      v.z,
    );
    _pushHistory();
    return vertices;
  }

  /// Snap all vertices to grid.
  List<Point3D> snapAll(double gridSize) {
    _vertices = _vertices.map((v) => Point3D(
      (v.x / gridSize).round() * gridSize,
      (v.y / gridSize).round() * gridSize,
      v.z,
    )).toList();
    _pushHistory();
    return vertices;
  }

  /// Calculate the centroid of the polygon.
  Point3D get centroid {
    if (_vertices.isEmpty) return const Point3D(0, 0, 0);
    final cx = _vertices.map((v) => v.x).reduce((a, b) => a + b) / _vertices.length;
    final cy = _vertices.map((v) => v.y).reduce((a, b) => a + b) / _vertices.length;
    return Point3D(cx, cy, 0);
  }

}
