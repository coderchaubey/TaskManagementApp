// ─────────────────────────────────────────────
//  TaskMaster – Task Provider (State Management)
//  Uses the Provider package to hold the app's
//  task list in memory. Any widget that calls
//  context.watch<TaskProvider>() will rebuild
//  automatically when notifyListeners() is called.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _statusFilter = 'All';

  // Public getters — widgets read state through these
  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  /// Returns true if [task] is effectively blocked —
  /// i.e. it has a blocker assigned AND that blocker is not yet "Done".
  bool isTaskBlocked(Task task) {
    if (task.blockedById == null) return false;
    final blocker = _tasks.where((t) => t.id == task.blockedById).firstOrNull;
    if (blocker == null) return false;
    return blocker.status != 'Done';
  }

  /// Finds a task by ID from the in-memory list. Returns null if not found.
  Task? getTaskById(int id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Loads tasks from the backend, applying current search and filter values.
  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Tell widgets to show loading state

    try {
      _tasks = await ApiService.getTasks(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _statusFilter != 'All' ? _statusFilter : null,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners(); // Tell widgets to rebuild with new data (or error)
    }
  }

  /// Updates the search query and reloads tasks immediately.
  /// The 300ms debounce is handled in the SearchBar widget itself.
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
    loadTasks();
  }

  /// Updates the status filter chip and reloads tasks.
  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
    loadTasks();
  }

  /// Creates a new task via the API and appends it to the local list.
  Future<void> createTask(Map<String, dynamic> data) async {
    final task = await ApiService.createTask(data);
    _tasks.add(task);
    notifyListeners();
  }

  /// Updates a task via the API and reloads the full list.
  /// Full reload is needed to pick up any auto-generated recurring tasks.
  Future<void> updateTask(int id, Map<String, dynamic> data) async {
    final updated = await ApiService.updateTask(id, data);
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index] = updated;
    }
    await loadTasks();
  }

  /// Deletes a task via the API and removes it from the local list.
  Future<void> deleteTask(int id) async {
    await ApiService.deleteTask(id);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}