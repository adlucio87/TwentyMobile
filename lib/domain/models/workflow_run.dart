class WorkflowRun {
  final String id;
  final String status;
  final DateTime createdAt;
  final String workflowName;

  WorkflowRun({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.workflowName,
  });

  factory WorkflowRun.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final status = json['status'] as String? ?? 'UNKNOWN';
    final createdAtStr = json['createdAt'] as String?;
    final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();

    var workflowName = 'Unnamed Workflow';
    final version = json['workflowVersion'];
    if (version is Map<String, dynamic>) {
      final workflow = version['workflow'];
      if (workflow is Map<String, dynamic>) {
        workflowName = workflow['name'] as String? ?? 'Unnamed Workflow';
      }
    }

    return WorkflowRun(
      id: id,
      status: status,
      createdAt: createdAt.toLocal(),
      workflowName: workflowName,
    );
  }
}
