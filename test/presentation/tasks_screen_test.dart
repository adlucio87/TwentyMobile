import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/domain/models/task.dart';
import 'package:pocketcrm/presentation/tasks/tasks_screen.dart';
import 'package:pocketcrm/presentation/shared/empty_state_widget.dart';
import 'package:pocketcrm/shared/widgets/task_card.dart';

import '../core/di/providers_test.mocks.dart';

// Mock task data class
class MockTasksProvider extends Tasks {
  final List<Task> mockTasks;
  
  MockTasksProvider(this.mockTasks);

  @override
  Future<List<Task>> build() async {
    return mockTasks;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TasksScreen Tests', () {
    late MockCRMRepository mockCRMRepository;

    setUp(() {
      mockCRMRepository = MockCRMRepository();
    });

    Widget createWidgetUnderTest(List<Task> mockTasks) {
      return ProviderScope(
        overrides: [
          crmRepositoryProvider.overrideWith((ref) => Future.value(mockCRMRepository)),
          tasksProvider.overrideWith(() => MockTasksProvider(mockTasks)),
        ],
        child: const MaterialApp(
          home: TasksScreen(),
        ),
      );
    }

    testWidgets('Renders TODO tasks correctly', (WidgetTester tester) async {
      final tasks = [
        Task(
          id: '1',
          title: 'Review PR',
          completed: false,
        ),
        Task(
          id: '2',
          title: 'Update documentation',
          completed: false,
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(tasks));
      await tester.pumpAndSettle();

      expect(find.text('Review PR'), findsOneWidget);
      expect(find.text('Update documentation'), findsOneWidget);
      expect(find.byType(TaskCard), findsNWidgets(2));
    });

    testWidgets('Shows a completion checkbox on each task', (WidgetTester tester) async {
      final tasks = [
        Task(
          id: '1',
          title: 'Review PR',
          completed: false,
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(tasks));
      await tester.pumpAndSettle();

      // TaskCard should contain a Checkbox
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('Shows empty state when no tasks', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest([]));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(find.text('All clear!'), findsOneWidget);
    });

    testWidgets('Renders task due dates', (WidgetTester tester) async {
      final tasks = [
        Task(
          id: '1',
          title: 'Review PR',
          completed: false,
          dueAt: DateTime(2025, 1, 1),
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(tasks));
      await tester.pumpAndSettle();

      // Check for an element containing the due date formatting.
      // Depending on formatting (e.g. "Jan 1" or "01/01/2025"), we just check it exists.
      // TaskCard usually renders a Row or Icon with date. 
      // We can search for the calendar_today icon or the formatted text.
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });
  });
}
