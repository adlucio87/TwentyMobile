import 'package:flutter/material.dart';

class DueDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;

  const DueDatePicker({super.key, required this.selectedDate, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Scadenza', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),

        // Shortcut rapidi
        Wrap(
          spacing: 8,
          children: [
            _ShortcutChip(
              label: 'Oggi',
              onTap: () => onDateSelected(DateTime.now()),
            ),
            _ShortcutChip(
              label: 'Domani',
              onTap: () => onDateSelected(DateTime.now().add(const Duration(days: 1))),
            ),
            _ShortcutChip(
              label: 'Settimana',
              onTap: () => onDateSelected(DateTime.now().add(const Duration(days: 7))),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Picker manuale
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
            );
            if (picked != null) onDateSelected(picked);
          },
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text(
            selectedDate != null
                ? _formatDate(selectedDate!)
                : 'Scegli data',
          ),
        ),

        // Rimuovi data
        if (selectedDate != null)
          TextButton(
            onPressed: () => onDateSelected(null),
            child: const Text('Rimuovi scadenza', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = DateTime(date.year, date.month, date.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Oggi';
    if (diff == 1) return 'Domani';
    if (diff == -1) return 'Ieri';
    if (diff > 1 && diff <= 7) return 'Tra $diff giorni';
    if (diff < -1 && diff >= -7) return '${diff.abs()} giorni fa';
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
