import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/core/theme/app_colors.dart';
import 'package:pocketcrm/domain/models/workflow.dart';
import 'package:pocketcrm/domain/models/workflow_run.dart';
import 'package:pocketcrm/presentation/shared/snackbar_helper.dart';
import 'package:pocketcrm/presentation/workflows/slide_to_execute_button.dart';
import 'package:pocketcrm/presentation/workflows/workflow_input_form.dart';
import 'package:shimmer/shimmer.dart';

/// Orchestrator bottom sheet for workflow execution.
///
/// Manages a multi-step flow:
/// 1. **List** — shows available manual workflows
/// 2. **Form** — (optional) dynamic input form for workflows requiring parameters
/// 3. **Execute** — slide-to-execute confirmation
///
/// Use [WorkflowBottomSheet.show] to display it.
class WorkflowBottomSheet extends ConsumerStatefulWidget {
  final String objectType;
  final String recordId;

  const WorkflowBottomSheet({
    super.key,
    required this.objectType,
    required this.recordId,
  });

  /// Convenience method to show the bottom sheet.
  static void show(
    BuildContext context, {
    required String objectType,
    required String recordId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => WorkflowBottomSheet(
        objectType: objectType,
        recordId: recordId,
      ),
    );
  }

  @override
  ConsumerState<WorkflowBottomSheet> createState() =>
      _WorkflowBottomSheetState();
}

enum _SheetStep { list, form }
enum _SheetTab { workflows, history }

class _WorkflowBottomSheetState extends ConsumerState<WorkflowBottomSheet> {
  _SheetStep _currentStep = _SheetStep.list;
  _SheetTab _currentTab = _SheetTab.workflows;
  Workflow? _selectedWorkflow;
  Map<String, dynamic> _formValues = {};
  bool _isFormValid = false;
  String? _executionError;
  Timer? _pollingTimer;
  List<String> _localRunIds = [];

  @override
  void initState() {
    super.initState();
    _loadLocalRunIds();
  }

  Future<void> _loadLocalRunIds() async {
    final storage = ref.read(storageServiceProvider);
    final key = 'wf_runs_${widget.recordId}';
    final existingStr = await storage.read(key: key);
    if (existingStr != null && mounted) {
      setState(() {
        _localRunIds = existingStr.split(',').where((id) => id.isNotEmpty).toList();
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _currentTab == _SheetTab.history) {
        ref.invalidate(workflowRunsListProvider);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                transitionBuilder: (child, animation) {
                  // Horizontal slide transition
                  final isForward = child.key == const ValueKey('form');
                  final offset = Tween<Offset>(
                    begin: Offset(isForward ? 1.0 : -1.0, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return SlideTransition(
                    position: offset,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: _currentStep == _SheetStep.list
                    ? _buildListStep(key: const ValueKey('list'))
                    : _buildFormStep(key: const ValueKey('form')),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── LIST STEP ──────────────────────────────────────────────────────────────

  Widget _buildListStep({Key? key}) {
    final workflowsAsync =
        ref.watch(manualWorkflowsProvider(widget.objectType));

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tabbed Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentTab == _SheetTab.workflows ? 'Workflow' : 'History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentTab == _SheetTab.workflows
                        ? 'Select a workflow to run'
                        : 'Recent workflow executions',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(2),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _currentTab = _SheetTab.workflows),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _currentTab == _SheetTab.workflows
                            ? Theme.of(context).colorScheme.surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: _currentTab == _SheetTab.workflows
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        'Run',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _currentTab == _SheetTab.workflows
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _currentTab = _SheetTab.history);
                      _startPolling();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _currentTab == _SheetTab.history
                            ? Theme.of(context).colorScheme.surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: _currentTab == _SheetTab.history
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        'History',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _currentTab == _SheetTab.history
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (_currentTab == _SheetTab.workflows)
          workflowsAsync.when(
            data: (workflows) {
              if (workflows.isEmpty) return _buildEmptyState();
              return _buildWorkflowList(workflows);
            },
            loading: () => _buildLoadingSkeleton(),
            error: (err, _) => _buildErrorState(err),
          )
        else
          _buildHistoryTab(),
      ],
    );
  }

  Widget _buildWorkflowList(List<Workflow> workflows) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: workflows.map((workflow) {
        final hasInputs = workflow.inputSchema.isNotEmpty;
        final hasUnsupportedRequired = workflow.inputSchema.any(
          (field) => field.isRequired && !SupportedFieldTypes.isSupported(field.fieldType),
        );

        final subtitleText = hasUnsupportedRequired
            ? 'Contains unsupported required parameters (requires web app)'
            : (workflow.hasFormStep
                ? '⚠ Contains form step (may require web app)'
                : (workflow.description ?? (hasInputs
                    ? '${workflow.inputSchema.length} parameters required'
                    : 'No parameters required')));

        final trailingIcon = hasUnsupportedRequired
            ? const Icon(Icons.lock_outline, color: Colors.amber)
            : Icon(
                Icons.chevron_right,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              );

        Widget cardContent = ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hasUnsupportedRequired
                  ? Colors.amber.withOpacity(0.1)
                  : primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasUnsupportedRequired ? Icons.lock_outline : Icons.bolt,
              color: hasUnsupportedRequired ? Colors.amber : primaryColor,
              size: 22,
            ),
          ),
          title: Text(
            workflow.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: hasUnsupportedRequired
                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                  : null,
            ),
          ),
          subtitle: Text(
            subtitleText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: hasUnsupportedRequired
                  ? (isDark ? Colors.amber.shade300 : Colors.amber.shade800)
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.5),
            ),
          ),
          trailing: trailingIcon,
          onTap: hasUnsupportedRequired ? null : () => _onWorkflowTap(workflow),
        );

        if (hasUnsupportedRequired) {
          cardContent = Opacity(
            opacity: 0.7,
            child: cardContent,
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: cardContent,
        );
      }).toList(),
    );
  }

  void _onWorkflowTap(Workflow workflow) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedWorkflow = workflow;
      _formValues = {};
      _isFormValid = workflow.inputSchema.isEmpty; // No form = auto-valid
      _executionError = null;
    });

    if (workflow.inputSchema.isEmpty) {
      // No inputs → show slide-to-execute directly in a mini form step
      setState(() => _currentStep = _SheetStep.form);
    } else {
      setState(() => _currentStep = _SheetStep.form);
    }
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_fix_high_outlined,
            size: 56,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.25),
          ),
          const SizedBox(height: 20),
          Text(
            'No workflows available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Configure manual workflows from the Twenty web app.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.5),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.darkSurfaceHigh
        : Colors.grey.shade200;
    final highlightColor = isDark
        ? AppColors.darkSurface
        : Colors.grey.shade50;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading workflows',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString().replaceAll('Exception: ', ''),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              ref.invalidate(manualWorkflowsProvider(widget.objectType));
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ─── FORM STEP ──────────────────────────────────────────────────────────────

  Widget _buildFormStep({Key? key}) {
    final workflow = _selectedWorkflow!;
    final hasInputs = workflow.inputSchema.isNotEmpty;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with back button
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () {
                setState(() {
                  _currentStep = _SheetStep.list;
                  _selectedWorkflow = null;
                  _executionError = null;
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                workflow.name,
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        if (workflow.description != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              workflow.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Dynamic form (if needed)
        if (hasInputs) ...[
          WorkflowInputForm(
            fields: workflow.inputSchema,
            onChanged: (values) {
              _formValues = values;
            },
            onValidationChanged: (isValid) {
              if (mounted && _isFormValid != isValid) {
                setState(() => _isFormValid = isValid);
              }
            },
          ),
          const SizedBox(height: 24),
        ],

        // No-inputs info message
        if (!hasInputs)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This workflow does not require any parameters.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Error message
        if (_executionError != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _executionError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Slide to execute
        SlideToExecuteButton(
          enabled: _isFormValid,
          onExecute: _executeWorkflow,
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _executeWorkflow() async {
    final workflow = _selectedWorkflow!;
    setState(() => _executionError = null);

    final repo = await ref.read(crmRepositoryProvider.future);
    final result = await repo.triggerWorkflow(
      workflowId: workflow.versionId ?? workflow.id,
      recordId: widget.recordId,
      payload: _formValues.isNotEmpty ? _formValues : null,
    );

    if (!result.success) {
      setState(() {
        _executionError =
            result.error ?? 'Unable to start the workflow';
      });
      throw Exception(result.error);
    }

    if (result.workflowRunId != null) {
      final storage = ref.read(storageServiceProvider);
      final key = 'wf_runs_${widget.recordId}';
      final existingStr = await storage.read(key: key);
      final list = existingStr != null
          ? existingStr.split(',').where((id) => id.isNotEmpty).toList()
          : <String>[];
      if (!list.contains(result.workflowRunId)) {
        list.add(result.workflowRunId!);
        await storage.write(key: key, value: list.join(','));
        if (mounted) {
          setState(() {
            _localRunIds = list;
          });
        }
      }
    }

    // Refresh history list
    ref.invalidate(workflowRunsListProvider);

    if (mounted) {
      setState(() {
        _currentStep = _SheetStep.list;
        _currentTab = _SheetTab.history;
        _selectedWorkflow = null;
        _formValues = {};
        _isFormValid = false;
        _executionError = null;
      });
      _startPolling();

      SnackbarHelper.showSuccess(
        context,
        'Workflow "${workflow.name}" started successfully',
      );
    }
  }

  Widget _buildHistoryTab() {
    final runsAsync = ref.watch(workflowRunsListProvider);

    return runsAsync.when(
      data: (runs) {
        final filteredRuns =
            runs.where((run) => _localRunIds.contains(run.id)).toList();

        if (filteredRuns.isEmpty) {
          return _buildEmptyHistoryState();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Executions',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.invalidate(workflowRunsListProvider);
                  },
                  tooltip: 'Refresh history',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredRuns.length > 10 ? 10 : filteredRuns.length,
              itemBuilder: (context, index) {
                final run = filteredRuns[index];
                return _buildRunCard(run);
              },
            ),
          ],
        );
      },
      loading: () => _buildLoadingSkeleton(),
      error: (err, _) => _buildErrorState(err),
    );
  }

  Widget _buildRunCard(WorkflowRun run) {
    Color statusBgColor;
    Color statusTextColor;
    IconData statusIcon;

    switch (run.status.toUpperCase()) {
      case 'COMPLETED':
        statusBgColor = Colors.green.withOpacity(0.1);
        statusTextColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'RUNNING':
        statusBgColor = Colors.blue.withOpacity(0.1);
        statusTextColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case 'FAILED':
        statusBgColor = Colors.red.withOpacity(0.1);
        statusTextColor = Colors.red;
        statusIcon = Icons.error_outline;
        break;
      case 'STOPPED':
        statusBgColor = Colors.orange.withOpacity(0.1);
        statusTextColor = Colors.orange;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusBgColor = Colors.grey.withOpacity(0.1);
        statusTextColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    final timeStr = DateFormat('MMM d, yyyy • h:mm a').format(run.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_circle_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    run.workflowName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${run.id.length > 8 ? run.id.substring(0, 8) : run.id}... • $timeStr',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (run.status.toUpperCase() == 'RUNNING')
                    const Padding(
                      padding: EdgeInsets.only(right: 4.0),
                      child: SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                    )
                  else
                    Icon(
                      statusIcon,
                      size: 12,
                      color: statusTextColor,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    run.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history,
            size: 56,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.25),
          ),
          const SizedBox(height: 20),
          Text(
            'No runs recorded',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Executed workflows will appear here.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.5),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
