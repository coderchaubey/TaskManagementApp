class Task {
  final int id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String status; // "To-Do", "In Progress", "Done"
  final int? blockedById;
  final bool isRecurring;
  final String? recurrenceType; // "Daily" or "Weekly"
  final int sortOrder;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.blockedById,
    this.isRecurring = false,
    this.recurrenceType,
    this.sortOrder = 0,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      dueDate: DateTime.parse(json['due_date']),
      status: json['status'],
      blockedById: json['blocked_by_id'],
      isRecurring: json['is_recurring'] ?? false,
      recurrenceType: json['recurrence_type'],
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String().split('T')[0],
      'status': status,
      'blocked_by_id': blockedById,
      'is_recurring': isRecurring,
      'recurrence_type': recurrenceType,
    };
  }

  bool get isBlocked => blockedById != null;

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? status,
    int? blockedById,
    bool? isRecurring,
    String? recurrenceType,
    int? sortOrder,
    bool clearBlockedBy = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedById: clearBlockedBy ? null : (blockedById ?? this.blockedById),
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}