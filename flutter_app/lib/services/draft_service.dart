import 'package:shared_preferences/shared_preferences.dart';

/// Saves and restores the user's in-progress task form so they don't lose
/// their work if they accidentally navigate away.
class DraftService {
  static const _titleKey = 'draft_title';
  static const _descKey = 'draft_description';
  static const _dueDateKey = 'draft_due_date';
  static const _statusKey = 'draft_status';
  static const _blockedByKey = 'draft_blocked_by';
  static const _isRecurringKey = 'draft_is_recurring';
  static const _recurrenceTypeKey = 'draft_recurrence_type';

  static Future<void> saveDraft({
    required String title,
    required String description,
    required String dueDate,
    required String status,
    int? blockedById,
    bool isRecurring = false,
    String? recurrenceType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_titleKey, title);
    await prefs.setString(_descKey, description);
    await prefs.setString(_dueDateKey, dueDate);
    await prefs.setString(_statusKey, status);
    if (blockedById != null) {
      await prefs.setInt(_blockedByKey, blockedById);
    } else {
      await prefs.remove(_blockedByKey);
    }
    await prefs.setBool(_isRecurringKey, isRecurring);
    if (recurrenceType != null) {
      await prefs.setString(_recurrenceTypeKey, recurrenceType);
    } else {
      await prefs.remove(_recurrenceTypeKey);
    }
  }

  static Future<Map<String, dynamic>> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'title': prefs.getString(_titleKey) ?? '',
      'description': prefs.getString(_descKey) ?? '',
      'due_date': prefs.getString(_dueDateKey) ?? '',
      'status': prefs.getString(_statusKey) ?? 'To-Do',
      'blocked_by_id': prefs.getInt(_blockedByKey),
      'is_recurring': prefs.getBool(_isRecurringKey) ?? false,
      'recurrence_type': prefs.getString(_recurrenceTypeKey),
    };
  }

  static Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_titleKey);
    await prefs.remove(_descKey);
    await prefs.remove(_dueDateKey);
    await prefs.remove(_statusKey);
    await prefs.remove(_blockedByKey);
    await prefs.remove(_isRecurringKey);
    await prefs.remove(_recurrenceTypeKey);
  }

  static Future<bool> hasDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final title = prefs.getString(_titleKey) ?? '';
    return title.isNotEmpty;
  }
}