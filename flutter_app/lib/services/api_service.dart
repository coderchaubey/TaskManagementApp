// ─────────────────────────────────────────────
//  TaskMaster – API Service
//  All HTTP communication with the FastAPI backend
//  is centralised here. No screen makes direct
//  HTTP calls — they all go through this class.
// ─────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiService {
  // 10.0.2.2 is the special Android emulator address that maps to the host PC's localhost.
  // If running on Chrome (flutter run -d chrome), change this to 'http://localhost:8000'.
  static const String baseUrl = 'http://localhost:8000';

  /// Fetches all tasks from the backend.
  /// Optionally filters by [search] (title substring) and [status].
  static Future<List<Task>> getTasks({String? search, String? status}) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status != 'All') queryParams['status'] = status;

    final uri = Uri.parse('$baseUrl/tasks').replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Task.fromJson(json)).toList();
    }
    throw Exception('Failed to load tasks');
  }

  /// Sends a POST request to create a new task.
  /// The backend applies a 2-second delay before responding.
  static Future<Task> createTask(Map<String, dynamic> taskData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(taskData),
    );

    if (response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body));
    }
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Failed to create task');
  }

  /// Sends a PUT request to update an existing task by [id].
  /// The backend applies a 2-second delay before responding.
  static Future<Task> updateTask(int id, Map<String, dynamic> taskData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(taskData),
    );

    if (response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body));
    }
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Failed to update task');
  }

  /// Sends a DELETE request to remove a task by [id].
  static Future<void> deleteTask(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/tasks/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete task');
    }
  }

  /// Returns up to 5 task title suggestions matching [query].
  /// Called by the debounced search bar for autocomplete.
  static Future<List<Map<String, dynamic>>> autocomplete(String query) async {
    if (query.isEmpty) return [];
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/search/autocomplete?q=$query'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }
}