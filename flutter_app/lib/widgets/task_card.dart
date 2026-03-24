import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task.dart';
import '../services/app_theme.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final bool isBlocked;
  final Task? blocker;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final int index;

  const TaskCard({
    super.key,
    required this.task,
    required this.isBlocked,
    required this.onTap,
    required this.onDelete,
    this.blocker,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusColor(task.status);
    final cardColor = isBlocked ? AppTheme.surfaceCard.withAlpha(160) : AppTheme.surfaceCard;
    final textOpacity = isBlocked ? 0.45 : 1.0;

    return Animate(
      effects: [
        FadeEffect(delay: Duration(milliseconds: index * 60), duration: 300.ms),
        SlideEffect(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
          delay: Duration(milliseconds: index * 60),
          duration: 300.ms,
          curve: Curves.easeOut,
        ),
      ],
      child: Dismissible(
        key: Key('task_${task.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.accent.withAlpha(220),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, color: Colors.white, size: 26),
              SizedBox(height: 4),
              Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Delete Task'),
              content: Text('Delete "${task.title}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) => onDelete(),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isBlocked
                    ? AppTheme.blocked.withAlpha(80)
                    : statusColor.withAlpha(50),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top status bar
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isBlocked ? AppTheme.blocked : statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Opacity(
                              opacity: textOpacity,
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurface,
                                  decoration: task.status == 'Done'
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: AppTheme.success,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status badge
                          _StatusBadge(status: task.status, isBlocked: isBlocked),
                        ],
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Opacity(
                          opacity: textOpacity,
                          child: Text(
                            task.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.onSurfaceMuted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Due date
                          Opacity(
                            opacity: textOpacity,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 13,
                                  color: _dueDateColor(task.dueDate),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM d, yyyy').format(task.dueDate),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _dueDateColor(task.dueDate),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Recurring badge
                          if (task.isRecurring)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withAlpha(40),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.repeat, size: 11, color: AppTheme.primary),
                                  const SizedBox(width: 3),
                                  Text(
                                    task.recurrenceType ?? '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      // Blocked by banner
                      if (isBlocked && blocker != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.blocked.withAlpha(80),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_outline, size: 13, color: AppTheme.onSurfaceMuted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Blocked by: ${blocker!.title}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.onSurfaceMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _dueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (task.status == 'Done') return AppTheme.onSurfaceMuted;
    if (due.isBefore(today)) return AppTheme.accent;
    if (due == today) return AppTheme.warning;
    return AppTheme.onSurfaceMuted;
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isBlocked;

  const _StatusBadge({required this.status, required this.isBlocked});

  @override
  Widget build(BuildContext context) {
    final color = isBlocked ? AppTheme.blocked : AppTheme.statusColor(status);
    final label = isBlocked ? 'Blocked' : status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}