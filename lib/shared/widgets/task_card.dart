import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketcrm/domain/models/task.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final bool isOverdue;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onToggleCompletion;

  const TaskCard({
    super.key,
    required this.task,
    this.isOverdue = false,
    this.onTap,
    this.onToggleCompletion,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  String _extractPlainText(String? body) {
    if (body == null || body.isEmpty) return '';
    try {
      final decoded = jsonDecode(body);
      if (decoded is List) {
        final buffer = StringBuffer();
        for (final block in decoded) {
          if (block is Map && block['content'] != null) {
            final content = block['content'];
            if (content is List) {
              for (final inline in content) {
                if (inline is Map && inline['text'] != null) {
                  buffer.write(inline['text']);
                }
              }
            } else if (content is String) {
              buffer.write(content);
            }
          }
          buffer.write(' ');
        }
        return buffer.toString().trim();
      }
    } catch (_) {}
    return body;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = task.completed == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: isOverdue && !isCompleted
            ? theme.colorScheme.error.withOpacity(0.08)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverdue && !isCompleted
              ? theme.colorScheme.error.withOpacity(0.3)
              : theme.dividerColor,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: isCompleted,
                  onChanged: onToggleCompletion,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: theme.textTheme.titleMedium!.copyWith(
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted
                            ? theme.textTheme.bodySmall?.color
                            : theme.textTheme.titleMedium?.color,
                        fontWeight: FontWeight.w600,
                      ),
                      child: Text(task.title),
                    ),
                    const SizedBox(height: 6),
                    _buildSubtitle(context, isCompleted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, bool isCompleted) {
    final theme = Theme.of(context);
    final secondaryColor = theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurfaceVariant;
    
    final plainBody = _extractPlainText(task.body);
    final hasBody = plainBody.isNotEmpty;
    
    final hasContact = task.contactId != null && task.contactName != null && task.contactName!.isNotEmpty;
    final hasDate = task.dueAt != null;

    if (!hasBody && !hasContact && !hasDate) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDate) ...[
          _buildDateRow(context, isCompleted, secondaryColor),
          const SizedBox(height: 6),
        ],
        if (hasContact) ...[
          _buildContactRow(context, secondaryColor),
          const SizedBox(height: 6),
        ],
        if (hasBody)
          Text(
            plainBody,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: secondaryColor,
              fontSize: 13,
            ),
          ),
      ],
    );
  }

  Widget _buildDateRow(BuildContext context, bool isCompleted, Color secondaryColor) {
    final theme = Theme.of(context);
    final date = task.dueAt!.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(date.year, date.month, date.day);
    final hasTime = date.hour != 0 || date.minute != 0;

    Color dateColor = secondaryColor;
    FontWeight dateWeight = FontWeight.w400;

    if (!isCompleted) {
      final difference = dueDay.difference(today).inDays;
      if (difference < 0 || (difference == 0 && hasTime && date.isBefore(now))) {
        dateColor = theme.colorScheme.error; // Overdue
        dateWeight = FontWeight.w600;
      } else if (difference == 0 && !hasTime) {
        dateColor = theme.colorScheme.error; // Today, no time
        dateWeight = FontWeight.w600;
      } else if (difference == 0) {
        dateColor = Colors.orange.shade700; // Today with time
        dateWeight = FontWeight.w500;
      }
    } else {
      dateColor = secondaryColor;
      dateWeight = FontWeight.w400;
    }

    String dateStr;
    final diffDays = dueDay.difference(today).inDays;
    if (diffDays == 0) {
      dateStr = 'Today';
    } else if (diffDays == 1) {
      dateStr = 'Tomorrow';
    } else if (diffDays == -1) {
      dateStr = 'Yesterday';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      dateStr = '${months[date.month - 1]} ${date.day}';
    }

    final timeStr = hasTime ? ' · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}' : '';

    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        bool hasNotification = false;
        if (snapshot.hasData) {
          hasNotification = snapshot.data!.getBool('task_notif_${task.id}') ?? true;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 14, color: dateColor),
            const SizedBox(width: 4),
            Text(
              '$dateStr$timeStr',
              style: theme.textTheme.bodySmall?.copyWith(
                color: dateColor,
                fontWeight: dateWeight,
              ),
            ),
            if (hasTime && hasNotification) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.notifications_active,
                size: 13,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildContactRow(BuildContext context, Color secondaryColor) {
    return InkWell(
      onTap: task.targetType == 'person' || task.targetType == null
          ? () => context.push('/contacts/${task.contactId}')
          : task.targetType == 'company'
              ? () => context.push('/companies/${task.contactId}')
              : null, // Opportunities don't have a detail screen yet
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: task.targetType == 'opportunity'
                ? Icon(
                    Icons.monetization_on_outlined,
                    size: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  )
                : task.targetType == 'company'
                  ? Icon(
                      Icons.business,
                      size: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    )
                  : Text(
                      _getInitials(task.contactName!),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                task.contactName!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: secondaryColor,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
