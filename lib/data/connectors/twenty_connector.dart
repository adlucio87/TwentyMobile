import 'dart:ui' show VoidCallback;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pocketcrm/core/auth/auth_service.dart';
import 'package:pocketcrm/core/utils/storage_service.dart';
import 'package:pocketcrm/data/connectors/base_graphql_connector.dart';
import 'package:pocketcrm/data/repositories/twenty_company_repository.dart';
import 'package:pocketcrm/data/repositories/twenty_contact_repository.dart';
import 'package:pocketcrm/data/repositories/twenty_note_repository.dart';
import 'package:pocketcrm/data/repositories/twenty_task_repository.dart';
import 'package:pocketcrm/data/repositories/twenty_workflow_repository.dart';
import 'package:pocketcrm/domain/models/company.dart';
import 'package:pocketcrm/domain/models/contact.dart';
import 'package:pocketcrm/domain/models/note.dart';
import 'package:pocketcrm/domain/models/task.dart';
import 'package:pocketcrm/domain/models/workflow.dart';
import 'package:pocketcrm/domain/models/workflow_run.dart';
import 'package:pocketcrm/domain/models/workspace_member.dart';
import 'package:pocketcrm/domain/repositories/crm_repository.dart';

/// Concrete implementation of [CRMRepository] for Twenty CRM.
///
/// Refactored into domain-specific repositories:
/// - [TwentyContactRepository] for contacts and people queries/mutations
/// - [TwentyCompanyRepository] for companies and workspace members
/// - [TwentyNoteRepository] for notes and blocknote mutations
/// - [TwentyTaskRepository] for tasks and target assignments
/// - [TwentyWorkflowRepository] for workflows and runs
///
/// Shared GraphQL transport, authentication refresh, retry logic, and error handling
/// are managed by [BaseGraphQLConnector].
class TwentyConnector implements CRMRepository {
  final BaseGraphQLConnector _base;
  late final TwentyContactRepository _contacts;
  late final TwentyCompanyRepository _companies;
  late final TwentyNoteRepository _notes;
  late final TwentyTaskRepository _tasks;
  late final TwentyWorkflowRepository _workflows;

  TwentyConnector({
    required GraphQLClient client,
    required StorageService storageService,
    AuthService? authService,
    VoidCallback? onTokenRefreshed,
    Map<String, List<String>> customFields = const {},
  }) : _base = BaseGraphQLConnector(
          client: client,
          storageService: storageService,
          authService: authService,
          onTokenRefreshed: onTokenRefreshed,
          customFields: customFields,
        ) {
    _contacts = TwentyContactRepository(_base);
    _companies = TwentyCompanyRepository(_base);
    _notes = TwentyNoteRepository(_base);
    _tasks = TwentyTaskRepository(_base);
    _workflows = TwentyWorkflowRepository(_base);
  }

  // ── Exposed sub-repositories ──
  BaseGraphQLConnector get baseConnector => _base;
  TwentyContactRepository get contactRepository => _contacts;
  TwentyCompanyRepository get companyRepository => _companies;
  TwentyNoteRepository get noteRepository => _notes;
  TwentyTaskRepository get taskRepository => _tasks;
  TwentyWorkflowRepository get workflowRepository => _workflows;

  // ── Backward-compatibility getters ──
  GraphQLClient get client => _base.client;
  AuthService? get authService => _base.authService;
  StorageService get storageService => _base.storageService;
  VoidCallback? get onTokenRefreshed => _base.onTokenRefreshed;
  Map<String, List<String>> get customFields => _base.customFields;

  static Future<bool> testConnection(String baseUrl, String apiToken) =>
      BaseGraphQLConnector.testConnection(baseUrl, apiToken);

  // ── Auth & Profile ──
  @override
  Future<String> getCurrentUserName() => _companies.getCurrentUserName();

  // ── Contacts ──
  @override
  Future<({List<Contact> contacts, String? endCursor, bool hasNextPage})>
      getContacts({String? search, int pageSize = 20, String? after}) =>
          _contacts.getContacts(search: search, pageSize: pageSize, after: after);

  @override
  Future<Contact> getContactById(String id) => _contacts.getContactById(id);

  @override
  Future<List<Contact>> getContactsByCompany(String companyId) =>
      _contacts.getContactsByCompany(companyId);

  @override
  Future<List<Contact>> getContactsByTask(String taskId) =>
      _contacts.getContactsByTask(taskId);

  @override
  Future<Contact> createContact({
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
  }) =>
      _contacts.createContact(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
      );

  @override
  Future<Contact> updateContact(
    String id, {
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? companyId,
    bool clearCompany = false,
    Map<String, dynamic>? customFields,
  }) =>
      _contacts.updateContact(
        id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        companyId: companyId,
        clearCompany: clearCompany,
        customFields: customFields,
      );

  @override
  Future<void> deleteContact(String id) => _contacts.deleteContact(id);

  @override
  Future<List<Contact>> getRecentContacts({int limit = 5}) =>
      _contacts.getRecentContacts(limit: limit);

  // ── Companies ──
  @override
  Future<({List<Company> companies, String? endCursor, bool hasNextPage})>
      getCompanies({String? search, int pageSize = 20, String? after}) =>
          _companies.getCompanies(search: search, pageSize: pageSize, after: after);

  @override
  Future<Company> getCompanyById(String id) => _companies.getCompanyById(id);

  @override
  Future<Company> createCompany({required String name, String? domainName}) =>
      _companies.createCompany(name: name, domainName: domainName);

  @override
  Future<Company> updateCompany(
    String id, {
    String? name,
    String? domainName,
    Map<String, dynamic>? customFields,
  }) =>
      _companies.updateCompany(
        id,
        name: name,
        domainName: domainName,
        customFields: customFields,
      );

  @override
  Future<void> deleteCompany(String id) => _companies.deleteCompany(id);

  @override
  Future<List<WorkspaceMember>> getWorkspaceMembers() =>
      _companies.getWorkspaceMembers();

  // ── Notes ──
  @override
  Future<List<Note>> getNotesByContact(String contactId) =>
      _notes.getNotesByContact(contactId);

  @override
  Future<List<Note>> getNotesByCompany(String companyId) =>
      _notes.getNotesByCompany(companyId);

  @override
  Future<Note> createNote({
    required String contactId,
    required String body,
    DateTime? dueAt,
  }) =>
      _notes.createNote(contactId: contactId, body: body, dueAt: dueAt);

  @override
  Future<Note> updateNote(
    String id, {
    required String body,
    DateTime? dueAt,
  }) =>
      _notes.updateNote(id, body: body, dueAt: dueAt);

  @override
  Future<void> deleteNote(String id) => _notes.deleteNote(id);

  // ── Tasks ──
  @override
  Future<List<Task>> getTasks({bool? completed}) =>
      _tasks.getTasks(completed: completed);

  @override
  Future<List<Task>> getOverdueTasks() => _tasks.getOverdueTasks();

  @override
  Future<List<Task>> getTodayTasks() => _tasks.getTodayTasks();

  @override
  Future<List<Task>> getTomorrowTasks() => _tasks.getTomorrowTasks();

  @override
  Future<Task> createTask({
    required String title,
    String? body,
    DateTime? dueAt,
    String? contactId,
    String? assigneeId,
  }) =>
      _tasks.createTask(
        title: title,
        body: body,
        dueAt: dueAt,
        contactId: contactId,
        assigneeId: assigneeId,
      );

  @override
  Future<Task> updateTask(
    String id, {
    String? title,
    String? body,
    DateTime? dueAt,
    bool clearDueDate = false,
    bool? completed,
    String? assigneeId,
  }) =>
      _tasks.updateTask(
        id,
        title: title,
        body: body,
        dueAt: dueAt,
        clearDueDate: clearDueDate,
        completed: completed,
        assigneeId: assigneeId,
      );

  @override
  Future<void> deleteTask(String id) => _tasks.deleteTask(id);

  // ── Workflows ──
  @override
  Future<List<Workflow>> getManualWorkflows({required String objectType}) =>
      _workflows.getManualWorkflows(objectType: objectType);

  @override
  Future<({bool success, String? workflowRunId, String? error})>
      triggerWorkflow({
    required String workflowId,
    required String recordId,
    Map<String, dynamic>? payload,
  }) =>
          _workflows.triggerWorkflow(
            workflowId: workflowId,
            recordId: recordId,
            payload: payload,
          );

  @override
  Future<List<WorkflowRun>> getWorkflowRuns() => _workflows.getWorkflowRuns();
}
