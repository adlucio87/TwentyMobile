import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pocketcrm/presentation/shared/dialog_helper.dart';

class SwipeActionWrapper extends StatelessWidget {
  final Key itemKey;
  final Widget child;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final String confirmTitle;
  final String confirmMessage;
  final String editLabel;
  final String deleteLabel;

  const SwipeActionWrapper({
    super.key,
    required this.itemKey,
    required this.child,
    required this.onDelete,
    this.onEdit,
    required this.confirmTitle,
    required this.confirmMessage,
    this.editLabel = 'Edit',
    this.deleteLabel = 'Delete',
  });

  @override
  Widget build(BuildContext context) {
    final customSemanticsActions = <CustomSemanticsAction, VoidCallback>{
      if (onEdit != null)
        CustomSemanticsAction(label: editLabel): () {
          onEdit!();
        },
      CustomSemanticsAction(label: deleteLabel): () async {
        final confirmed = await DialogHelper.showDeleteConfirmDialog(
          context: context,
          title: confirmTitle,
          message: confirmMessage,
        );
        if (confirmed == true) {
          onDelete();
        }
      },
    };

    return Semantics(
      customSemanticsActions: customSemanticsActions,
      child: Dismissible(
        key: itemKey,
        direction: onEdit != null ? DismissDirection.horizontal : DismissDirection.endToStart,
        background: ExcludeSemantics(
          child: Container(
            color: Theme.of(context).colorScheme.primary,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(
              Icons.edit,
              color: Colors.white,
            ),
          ),
        ),
        secondaryBackground: ExcludeSemantics(
          child: Container(
            color: Theme.of(context).colorScheme.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
        ),
        confirmDismiss: (direction) async {
          HapticFeedback.mediumImpact();
          if (direction == DismissDirection.startToEnd) {
            onEdit?.call();
            return false; // Non rimuoviamo la card dal widget tree per l'edit
          } else {
            return await DialogHelper.showDeleteConfirmDialog(
              context: context,
              title: confirmTitle,
              message: confirmMessage,
            );
          }
        },
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            onDelete();
          }
        },
        child: child,
      ),
    );
  }
}

