import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/domain/models/contact.dart';
import 'package:pocketcrm/domain/models/task.dart';
import 'package:pocketcrm/l10n/app_localizations.dart';
import 'package:pocketcrm/presentation/home/today_screen.dart';
import 'package:pocketcrm/presentation/home/widgets/task_today_card.dart';
import 'package:pocketcrm/presentation/home/widgets/recent_contacts_row.dart';
import 'package:pocketcrm/presentation/shared/error_state_widget.dart';
import 'package:shimmer/shimmer.dart';

import '../core/di/providers_test.mocks.dart';

void main() {
  group('TodayScreen Tests', () {
    late MockCRMRepository mockCRMRepository;

    setUp(() {
      mockCRMRepository = MockCRMRepository();
      when(mockCRMRepository.getCurrentUserName()).thenAnswer((_) async => 'John Doe');
    });

    Widget createWidgetUnderTest() {
      return ProviderScope(
        overrides: [
          crmRepositoryProvider.overrideWith((ref) => Future.value(mockCRMRepository)),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'),
            Locale('it'),
          ],
          locale: Locale('en'),
          home: TodayScreen(),
        ),
      );
    }

    testWidgets('Renders loading shimmer while today data is loading', (WidgetTester tester) async {
      when(mockCRMRepository.getOverdueTasks()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return [];
      });
      when(mockCRMRepository.getTodayTasks()).thenAnswer((_) async => []);
      when(mockCRMRepository.getTomorrowTasks()).thenAnswer((_) async => []);
      when(mockCRMRepository.getRecentContacts(limit: 5)).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(Shimmer), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('Renders empty state when there are no tasks', (WidgetTester tester) async {
      when(mockCRMRepository.getOverdueTasks()).thenAnswer((_) async => []);
      when(mockCRMRepository.getTodayTasks()).thenAnswer((_) async => []);
      when(mockCRMRepository.getTomorrowTasks()).thenAnswer((_) async => []);
      when(mockCRMRepository.getRecentContacts(limit: 5)).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Everything is in order!'), findsOneWidget);
      expect(find.text('No tasks due today'), findsOneWidget);
      expect(find.text('Add Task'), findsOneWidget);
    });

    testWidgets('Renders tasks in Overdue, Today and Tomorrow sections', (WidgetTester tester) async {
      final now = DateTime.now();
      final overdueTask = Task(
        id: 't-1',
        title: 'Overdue Follow-up',
        dueAt: now.subtract(const Duration(days: 2)),
        completed: false,
      );
      final todayTask = Task(
        id: 't-2',
        title: 'Meeting with Client',
        dueAt: now,
        completed: false,
      );
      final tomorrowTask = Task(
        id: 't-3',
        title: 'Send Proposal',
        dueAt: now.add(const Duration(days: 1)),
        completed: false,
      );

      when(mockCRMRepository.getOverdueTasks()).thenAnswer((_) async => [overdueTask]);
      when(mockCRMRepository.getTodayTasks()).thenAnswer((_) async => [todayTask]);
      when(mockCRMRepository.getTomorrowTasks()).thenAnswer((_) async => [tomorrowTask]);
      when(mockCRMRepository.getRecentContacts(limit: 5)).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Overdue Follow-up'), findsOneWidget);
      expect(find.text('Meeting with Client'), findsOneWidget);
      expect(find.text('Send Proposal'), findsOneWidget);
      expect(find.byType(TaskTodayCard), findsNWidgets(3));
    });

    testWidgets('Renders recent contacts when available', (WidgetTester tester) async {
      final contact = Contact(
        id: 'c-1',
        firstName: 'Alice',
        lastName: 'Smith',
        email: 'alice@example.com',
      );

      when(mockCRMRepository.getOverdueTasks()).thenAnswer((_) async => []);
      when(mockCRMRepository.getTodayTasks()).thenAnswer((_) async => []);
      when(mockCRMRepository.getTomorrowTasks()).thenAnswer((_) async => []);
      when(mockCRMRepository.getRecentContacts(limit: 5)).thenAnswer((_) async => [contact]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(RecentContactsRow), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('Renders error state when repository throws auth error', (WidgetTester tester) async {
      when(mockCRMRepository.getOverdueTasks()).thenThrow(Exception('unauthenticated'));
      when(mockCRMRepository.getTodayTasks()).thenThrow(Exception('unauthenticated'));
      when(mockCRMRepository.getTomorrowTasks()).thenThrow(Exception('unauthenticated'));
      when(mockCRMRepository.getRecentContacts(limit: 5)).thenThrow(Exception('unauthenticated'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.text('Loading error'), findsOneWidget);
    });

    testWidgets('Displays floating action button with speed dial options', (WidgetTester tester) async {
      when(mockCRMRepository.getOverdueTasks()).thenAnswer((_) async => []);
      when(mockCRMRepository.getTodayTasks()).thenAnswer((_) async => []);
      when(mockCRMRepository.getTomorrowTasks()).thenAnswer((_) async => []);
      when(mockCRMRepository.getRecentContacts(limit: 5)).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
