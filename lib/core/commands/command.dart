/// Command pattern implementation for undo/redo support.
///
/// Every user action that modifies measurement state is wrapped
/// in a [Command] and pushed to the [CommandManager] stack.
abstract class Command {
  final String description;
  final DateTime executedAt;

  Command({required this.description}) : executedAt = DateTime.now();

  /// Execute the command (or re-execute on redo).
  void execute();

  /// Reverse the command.
  void undo();
}

/// Manages undo/redo stacks with configurable depth.
class CommandManager {
  final int maxStackDepth;
  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];

  CommandManager({this.maxStackDepth = 50});

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;

  String? get lastUndoDescription =>
      _undoStack.isNotEmpty ? _undoStack.last.description : null;
  String? get lastRedoDescription =>
      _redoStack.isNotEmpty ? _redoStack.last.description : null;

  void execute(Command command) {
    command.execute();
    _undoStack.add(command);
    _redoStack.clear();
    if (_undoStack.length > maxStackDepth) {
      _undoStack.removeAt(0);
    }
  }

  void undo() {
    if (!canUndo) return;
    final command = _undoStack.removeLast();
    command.undo();
    _redoStack.add(command);
  }

  void redo() {
    if (!canRedo) return;
    final command = _redoStack.removeLast();
    command.execute();
    _undoStack.add(command);
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
