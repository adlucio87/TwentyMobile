import 'package:flutter/material.dart';
import 'package:pocketcrm/domain/models/note.dart';
import 'package:pocketcrm/shared/widgets/block_note_renderer.dart';
import 'package:pocketcrm/presentation/notes/edit_note_sheet.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final String? contactId;
  final String? companyId;
  const NoteCard({super.key, required this.note, this.contactId, this.companyId});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openFullNote(context),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LimitedBox(
                maxHeight: 120,
                child: IgnorePointer(
                  child: BlockNoteRenderer(json: note.body, compact: true),
                ),
              ),
              if (note.createdAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.createdAt!.toLocal().toString().split('.')[0],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Icon(Icons.open_in_full, size: 14, color: Colors.grey.shade400),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openFullNote(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.4,
        maxChildSize: 1.0,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      note.createdAt != null
                          ? note.createdAt!.toLocal().toString().split('.')[0]
                          : 'Note',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Edit note',
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => EditNoteSheet(
                          note: note,
                          contactId: contactId,
                          companyId: companyId,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: BlockNoteRenderer(json: note.body),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
