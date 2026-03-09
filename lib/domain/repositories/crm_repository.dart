import 'package:pocketcrm/domain/models/company.dart';
import 'package:pocketcrm/domain/models/contact.dart';
import 'package:pocketcrm/domain/models/note.dart';
import 'package:pocketcrm/domain/models/task.dart';

abstract class CRMRepository {
  // Auth
  Future<bool> testConnection(String baseUrl, String apiToken);
  Future<String> getCurrentUserName();

  // Contacts
  Future<List<Contact>> getContacts({
    String? search,
    int page = 1,
    int pageSize = 20,
  });
  Future<Contact> getContactById(String id);
  Future<Contact> createContact({
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
  });
  Future<Contact> updateContact(
    String id, {
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  });

  // Companies
  Future<List<Company>> getCompanies({String? search, int page = 1});
  Future<Company> getCompanyById(String id);

  // Notes
  Future<List<Note>> getNotesByContact(String contactId);
  Future<Note> createNote({required String contactId, required String body});

  // Tasks
  Future<List<Task>> getTasks({bool? completed});
  Future<Task> createTask({
    required String title,
    String? body,
    DateTime? dueAt,
    String? contactId,
  });
  Future<Task> completeTask(String id);
}
