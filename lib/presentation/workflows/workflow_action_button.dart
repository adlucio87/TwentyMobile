import 'package:flutter/material.dart';
import 'package:pocketcrm/presentation/workflows/workflow_bottom_sheet.dart';

/// Entry-point button for the AppBar in record detail screens.
/// Opens the [WorkflowBottomSheet] to list and execute manual workflows.
class WorkflowActionButton extends StatelessWidget {
  final String objectType;
  final String recordId;

  const WorkflowActionButton({
    super.key,
    required this.objectType,
    required this.recordId,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.bolt),
      tooltip: 'Workflow actions',
      onPressed: () {
        WorkflowBottomSheet.show(
          context,
          objectType: objectType,
          recordId: recordId,
        );
      },
    );
  }
}
