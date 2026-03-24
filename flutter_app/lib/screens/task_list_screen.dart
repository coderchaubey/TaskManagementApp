import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/search_bar.dart';
import '../services/app_theme.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<TaskProvider>().loadTasks());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchAndFilter(),
            Expanded(child: _buildTaskList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateTask(),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Task', style: TextStyle(fontWeight: FontWeight.w600)),
      ).animate().scale(delay: 300.ms, duration: 400.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accent],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.task_alt, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'TaskMaster',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
          const SizedBox(height: 4),
          Consumer<TaskProvider>(
            builder: (_, provider, __) => Text(
              '${provider.tasks.length} task${provider.tasks.length != 1 ? 's' : ''}',
              style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 14),
            ),
          ).animate().fadeIn(delay: 100.ms),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Consumer<TaskProvider>(
      builder: (_, provider, __) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          children: [
            DebouncedSearchBar(
              initialValue: provider.searchQuery,
              onSearch: provider.setSearchQuery,
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'To-Do', 'In Progress', 'Done'].map((status) {
                  final isSelected = provider.statusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (_) => provider.setStatusFilter(status),
                      selectedColor: AppTheme.primary,
                      backgroundColor: AppTheme.surfaceCard,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.onSurfaceMuted,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                      showCheckmark: false,
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.surfaceCardLight,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    return Consumer<TaskProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading && provider.tasks.isEmpty) {
          return _buildShimmer();
        }

        if (provider.error != null) {
          return _buildError(provider.error!, provider);
        }

        if (provider.tasks.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          color: AppTheme.primary,
          backgroundColor: AppTheme.surfaceCard,
          onRefresh: provider.loadTasks,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            itemCount: provider.tasks.length,
            itemBuilder: (context, index) {
              final task = provider.tasks[index];
              final blocked = provider.isTaskBlocked(task);
              final blocker = task.blockedById != null
                  ? provider.getTaskById(task.blockedById!)
                  : null;

              return TaskCard(
                task: task,
                isBlocked: blocked,
                blocker: blocker,
                index: index,
                onTap: () => _openEditTask(task.id),
                onDelete: () => provider.deleteTask(task.id),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, i) => Container(
        height: 110,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
        ),
      ).animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1200.ms, color: AppTheme.surfaceCardLight),
    );
  }

  Widget _buildError(String error, TaskProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 60, color: AppTheme.accent),
            const SizedBox(height: 16),
            const Text(
              'Cannot connect to server',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure the backend is running on port 8000',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.onSurfaceMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: provider.loadTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withAlpha(40),
                  AppTheme.accent.withAlpha(40),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.checklist_rounded,
              size: 40,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to create your first task',
            style: TextStyle(color: AppTheme.onSurfaceMuted),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  void _openCreateTask() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TaskFormScreen()),
    ).then((_) => context.read<TaskProvider>().loadTasks());
  }

  void _openEditTask(int taskId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(taskId: taskId)),
    ).then((_) => context.read<TaskProvider>().loadTasks());
  }
}