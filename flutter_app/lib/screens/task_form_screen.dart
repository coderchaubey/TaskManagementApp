import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../services/app_theme.dart';
import '../services/draft_service.dart';
import '../models/task.dart';

class TaskFormScreen extends StatefulWidget {
  final int? taskId; // null = create, non-null = edit

  const TaskFormScreen({super.key, this.taskId});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _status = 'To-Do';
  DateTime? _dueDate;
  int? _blockedById;
  bool _isRecurring = false;
  String? _recurrenceType;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isEditMode = false;
  Task? _editTask;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.taskId != null;
    _loadInitialData();

    // Auto-save draft on every keystroke (create mode only)
    if (!_isEditMode) {
      _titleController.addListener(_saveDraft);
      _descController.addListener(_saveDraft);
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    if (_isEditMode) {
      final provider = context.read<TaskProvider>();
      _editTask = provider.getTaskById(widget.taskId!);
      if (_editTask != null) {
        _titleController.text = _editTask!.title;
        _descController.text = _editTask!.description;
        _status = _editTask!.status;
        _dueDate = _editTask!.dueDate;
        _blockedById = _editTask!.blockedById;
        _isRecurring = _editTask!.isRecurring;
        _recurrenceType = _editTask!.recurrenceType;
      }
    } else {
      // Load draft for create mode
      final draft = await DraftService.loadDraft();
      if (draft['title'] != '') {
        _titleController.text = draft['title'];
        _descController.text = draft['description'];
        _status = draft['status'];
        _blockedById = draft['blocked_by_id'];
        _isRecurring = draft['is_recurring'];
        _recurrenceType = draft['recurrence_type'];
        if (draft['due_date'] != '') {
          _dueDate = DateTime.tryParse(draft['due_date']);
        }
      }
    }

    setState(() => _isLoading = false);
  }

  void _saveDraft() {
    if (_isEditMode) return;
    DraftService.saveDraft(
      title: _titleController.text,
      description: _descController.text,
      dueDate: _dueDate?.toIso8601String().split('T')[0] ?? '',
      status: _status,
      blockedById: _blockedById,
      isRecurring: _isRecurring,
      recurrenceType: _recurrenceType,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            surface: AppTheme.surfaceCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
      _saveDraft();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date'), backgroundColor: AppTheme.accent),
      );
      return;
    }

    setState(() => _isSaving = true);

    final data = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'due_date': _dueDate!.toIso8601String().split('T')[0],
      'status': _status,
      'blocked_by_id': _blockedById,
      'is_recurring': _isRecurring,
      'recurrence_type': _isRecurring ? _recurrenceType : null,
    };

    try {
      final provider = context.read<TaskProvider>();
      if (_isEditMode) {
        await provider.updateTask(widget.taskId!, data);
      } else {
        await provider.createTask(data);
        await DraftService.clearDraft();
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppTheme.accent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Task' : 'New Task'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isEditMode)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                      )
                    : const Text('Save', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Title *'),
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: AppTheme.onSurface),
                      decoration: const InputDecoration(hintText: 'What needs to be done?'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Description'),
                    TextFormField(
                      controller: _descController,
                      style: const TextStyle(color: AppTheme.onSurface),
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Add details (optional)'),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Due Date *'),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.onSurfaceMuted),
                            const SizedBox(width: 10),
                            Text(
                              _dueDate != null
                                  ? DateFormat('MMM d, yyyy').format(_dueDate!)
                                  : 'Select a date',
                              style: TextStyle(
                                color: _dueDate != null ? AppTheme.onSurface : AppTheme.onSurfaceMuted,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Status'),
                    _buildDropdown<String>(
                      value: _status,
                      items: ['To-Do', 'In Progress', 'Done'],
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Blocked By (Optional)'),
                    _buildBlockedByDropdown(),
                    const SizedBox(height: 20),

                    // Recurring toggle
                    _buildRecurringSection(),

                    const SizedBox(height: 32),

                    if (!_isEditMode)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Saving...'),
                                  ],
                                )
                              : const Text('Create Task'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.onSurfaceMuted,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        dropdownColor: AppTheme.surfaceCard,
        underline: const SizedBox(),
        style: const TextStyle(color: AppTheme.onSurface, fontSize: 15),
        items: items
            .map((item) => DropdownMenuItem<T>(value: item, child: Text(item.toString())))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildBlockedByDropdown() {
    final provider = context.read<TaskProvider>();
    final availableTasks = provider.tasks
        .where((t) => _isEditMode ? t.id != widget.taskId : true)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<int?>(
        value: _blockedById,
        isExpanded: true,
        dropdownColor: AppTheme.surfaceCard,
        underline: const SizedBox(),
        style: const TextStyle(color: AppTheme.onSurface, fontSize: 15),
        hint: const Text('None', style: TextStyle(color: AppTheme.onSurfaceMuted)),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('None')),
          ...availableTasks.map((t) => DropdownMenuItem<int?>(
                value: t.id,
                child: Text(
                  t.title,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
        ],
        onChanged: (v) {
          setState(() => _blockedById = v);
          _saveDraft();
        },
      ),
    );
  }

  Widget _buildRecurringSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isRecurring ? AppTheme.primary.withAlpha(80) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.repeat, size: 18, color: AppTheme.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Recurring Task',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
              Switch(
                value: _isRecurring,
                onChanged: (v) {
                  setState(() {
                    _isRecurring = v;
                    if (!v) _recurrenceType = null;
                    else _recurrenceType = 'Weekly';
                  });
                  _saveDraft();
                },
                activeColor: AppTheme.primary,
              ),
            ],
          ),
          if (_isRecurring) ...[
            const SizedBox(height: 12),
            Row(
              children: ['Daily', 'Weekly'].map((type) {
                final selected = _recurrenceType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _recurrenceType = type);
                      _saveDraft();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.primary : AppTheme.surfaceCardLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          color: selected ? Colors.white : AppTheme.onSurfaceMuted,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}