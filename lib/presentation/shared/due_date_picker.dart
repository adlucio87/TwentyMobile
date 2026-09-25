import 'package:flutter/material.dart';
import 'package:pocketcrm/l10n/app_localizations.dart';

class DueDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;

  const DueDatePicker({super.key, required this.selectedDate, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)?.dueDate ?? 'Due Date', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),

        // Shortcut rapidi
        Wrap(
          spacing: 8,
          children: [
            _ShortcutChip(
              label: 'Today',
              onTap: () => onDateSelected(DateTime.now()),
            ),
            _ShortcutChip(
              label: 'Tomorrow',
              onTap: () => onDateSelected(DateTime.now().add(const Duration(days: 1))),
            ),
            _ShortcutChip(
              label: 'Next Week',
              onTap: () => onDateSelected(DateTime.now().add(const Duration(days: 7))),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Picker manuale
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    // Mantieni l'orario se già impostato
                    if (selectedDate != null) {
                      onDateSelected(DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        selectedDate!.hour,
                        selectedDate!.minute,
                      ));
                    } else {
                      onDateSelected(picked);
                    }
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  selectedDate != null
                      ? _formatDate(selectedDate!)
                      : 'Pick a date',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTimePicker(context),
            ),
          ],
        ),

        // Rimuovi data
        if (selectedDate != null)
          TextButton(
            onPressed: () => onDateSelected(null),
            child: Text(
              AppLocalizations.of(context)?.removeDueDate ?? 'Remove due date',
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    final hasTime = selectedDate != null &&
        (selectedDate!.hour != 0 || selectedDate!.minute != 0);

    return OutlinedButton.icon(
      onPressed: selectedDate == null
          ? null
          : () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: hasTime
                    ? TimeOfDay(hour: selectedDate!.hour, minute: selectedDate!.minute)
                    : const TimeOfDay(hour: 0, minute: 0),
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                onDateSelected(DateTime(
                  selectedDate!.year,
                  selectedDate!.month,
                  selectedDate!.day,
                  picked.hour,
                  picked.minute,
                ));
              }
            },
      icon: Icon(
        hasTime ? Icons.access_time_filled : Icons.access_time,
        size: 18,
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hasTime
                ? '${selectedDate!.hour.toString().padLeft(2, '0')}:${selectedDate!.minute.toString().padLeft(2, '0')}'
                : 'Time',
          ),
          if (hasTime) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                onDateSelected(DateTime(
                  selectedDate!.year,
                  selectedDate!.month,
                  selectedDate!.day,
                  0,
                  0,
                ));
              },
              child: const Icon(Icons.close, size: 14),
            ),
          ]
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = DateTime(date.year, date.month, date.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1 && diff <= 7) return 'In $diff days';
    if (diff < -1 && diff >= -7) return '${diff.abs()} days ago';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _ShortcutChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ShortcutChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}
