import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketcrm/domain/models/task.dart';
import 'package:pocketcrm/presentation/home/today_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketcrm/presentation/shared/swipe_action_wrapper.dart';
import 'package:pocketcrm/presentation/tasks/tasks_screen.dart';
import 'package:pocketcrm/presentation/shared/snackbar_helper.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/core/utils/demo_utils.dart';
import 'package:pocketcrm/shared/widgets/task_card.dart';

class TaskTodayCard extends ConsumerWidget {
  final Task task;
  final bool isOverdue;

  const TaskTodayCard({super.key, required this.task, this.isOverdue = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwipeActionWrapper(
      itemKey: ValueKey('today_task_${task.id}'),
      confirmTitle: 'Delete task',
      confirmMessage: 'Do you want to delete \'${task.title}\'?',
      onEdit: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => EditTaskSheet(task: task),
        );
      },
      onDelete: () async {
        if (!await DemoUtils.checkDemoAction(context, ref)) return;
        try {
          await ref.read(tasksProvider.notifier).deleteTask(task.id);
          ref.invalidate(todayNotifierProvider);
          if (context.mounted) {
            SnackbarHelper.showSuccess(context, 'Task deleted');
          }
        } catch (e) {
          if (context.mounted) {
            SnackbarHelper.showError(context, 'Error during deletion');
          }
        }
      },
      child: TaskCard(
        task: task,
        isOverdue: isOverdue,
        onTap: () {
          // You could optionally navigate to details or leave it disabled for today
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => EditTaskSheet(task: task),
          );
        },
        onToggleCompletion: (_) async {
          if (!await DemoUtils.checkDemoAction(context, ref)) return;
          ref.read(todayNotifierProvider.notifier).completeTask(task.id);
        },
      ),
    );
  }
}
