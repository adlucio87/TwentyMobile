import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/domain/models/task.dart';
import 'package:pocketcrm/domain/models/contact.dart';

part 'today_provider.freezed.dart';
part 'today_provider.g.dart';

@riverpod
class TodayNotifier extends _$TodayNotifier {
  @override
  Future<TodayData> build() async {
    return _loadTodayData();
  }

  Future<TodayData> _loadTodayData() async {
    final repo = await ref.read(crmRepositoryProvider.future);

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));
    final startOfTomorrow = endOfToday;
    final endOfTomorrow = startOfTomorrow.add(const Duration(days: 1));

    final List<Task> overdueTasks = [];
    final List<Task> todayTasks = [];
    final List<Task> tomorrowTasks = [];
    final List<Contact> recentContacts = [];
    int authErrors = 0;
    String? lastAuthError;

    void handleError(Object e) {
      if (_isTokenError(e)) {
        authErrors++;
        lastAuthError = e.toString();
      }
    }

    await Future.wait([
      repo.getOverdueTasks().then(overdueTasks.addAll).catchError((e) {
        print('>>> [1/4] ERROR: overdueTasks failed: $e');
        handleError(e);
      }),
      repo.getTodayTasks().then(todayTasks.addAll).catchError((e) {
        print('>>> [2/4] ERROR: todayTasks failed: $e');
        handleError(e);
      }),
      repo.getTomorrowTasks().then(tomorrowTasks.addAll).catchError((e) {
        print('>>> [3/4] ERROR: tomorrowTasks failed: $e');
        handleError(e);
      }),
      repo.getRecentContacts(limit: 5).then(recentContacts.addAll).catchError((e) {
        print('>>> [4/4] ERROR: recentContacts failed: $e');
        handleError(e);
      }),
    ]);

    // If ALL calls failed due to auth, propagate the error so the UI can show it
    if (authErrors == 4 && lastAuthError != null) {
      throw Exception(lastAuthError);
    }

    return TodayData(
      overdueTasks: overdueTasks,
      todayTasks: todayTasks,
      tomorrowTasks: tomorrowTasks,
      recentContacts: recentContacts,
    );
  }

  bool _isTokenError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('token has expired') ||
        msg.contains('token expired') ||
        msg.contains('unauthenticated') ||
        msg.contains('session expired');
  }

  Future<void> completeTask(String taskId) async {
    // Aggiorniamo lo status passando completed: true al metodo esistente
    final repo = await ref.read(crmRepositoryProvider.future);
    await repo.updateTask(taskId, completed: true);
    ref.invalidateSelf(); // ricarica tutto
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

@freezed
class TodayData with _$TodayData {
  factory TodayData({
    required List<Task> overdueTasks,
    required List<Task> todayTasks,
    required List<Task> tomorrowTasks,
    required List<Contact> recentContacts,
  }) = _TodayData;
}