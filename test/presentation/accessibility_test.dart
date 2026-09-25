import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketcrm/domain/models/contact.dart';
import 'package:pocketcrm/domain/models/task.dart';
import 'package:pocketcrm/presentation/home/widgets/recent_contacts_row.dart';
import 'package:pocketcrm/presentation/shared/empty_state_widget.dart';
import 'package:pocketcrm/presentation/shared/error_state_widget.dart';
import 'package:pocketcrm/presentation/shared/swipe_action_wrapper.dart';
import 'package:pocketcrm/presentation/workflows/slide_to_execute_button.dart';
import 'package:pocketcrm/shared/widgets/task_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Accessibility Tests', () {
    testWidgets('SlideToExecuteButton in standard mode exposes semantics button and hint', (tester) async {
      bool executed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideToExecuteButton(
              label: 'Slide to run test',
              onExecute: () async {
                executed = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final semanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == 'Slide to run test' && widget.properties.button == true,
      );
      expect(semanticsFinder, findsOneWidget);

      // Verify hint
      final semanticsWidget = tester.widget<Semantics>(semanticsFinder);
      expect(semanticsWidget.properties.hint, contains('Double tap to execute'));

      // Verify onTap executes
      semanticsWidget.properties.onTap?.call();
      await tester.pumpAndSettle();
      expect(executed, isTrue);
    });

    testWidgets('SlideToExecuteButton adapts to accessibleNavigation: true by rendering FilledButton', (tester) async {
      bool executed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(accessibleNavigation: true),
            child: Scaffold(
              body: SlideToExecuteButton(
                label: 'Run Accessible Workflow',
                onExecute: () async {
                  executed = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render a direct tap button instead of the slide track
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Run Accessible Workflow'), findsOneWidget);

      // Tapping it triggers execution directly
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(executed, isTrue);
      expect(find.text('Done!'), findsOneWidget);
    });

    testWidgets('SwipeActionWrapper exposes custom semantics actions for Edit and Delete', (tester) async {
      bool editCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionWrapper(
              itemKey: const ValueKey('swipe_test'),
              confirmTitle: 'Delete item',
              confirmMessage: 'Are you sure?',
              onEdit: () {
                editCalled = true;
              },
              onDelete: () {},
              child: const Text('Swipeable Item'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.customSemanticsActions != null &&
            widget.properties.customSemanticsActions!.keys.any((a) => a.label == 'Edit') &&
            widget.properties.customSemanticsActions!.keys.any((a) => a.label == 'Delete'),
      );
      expect(semanticsFinder, findsOneWidget);

      // Test invoking the Edit custom semantic action
      final semanticsWidget = tester.widget<Semantics>(semanticsFinder);
      final editActionKey = semanticsWidget.properties.customSemanticsActions!.keys.firstWhere((a) => a.label == 'Edit');
      semanticsWidget.properties.customSemanticsActions![editActionKey]!();
      expect(editCalled, isTrue);
    });

    testWidgets('TaskCard Checkbox has explicit semanticLabel matching task name', (tester) async {
      final task = Task(
        id: 't1',
        title: 'Review quarterly report',
        completed: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: task,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.semanticLabel, 'Mark "Review quarterly report" as complete');
    });

    testWidgets('EmptyStateWidget excludes decorative icon from semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              title: 'Empty Inbox',
              message: 'No messages found',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ExcludeSemantics), findsWidgets);
      expect(find.text('Empty Inbox'), findsOneWidget);
      expect(find.text('No messages found'), findsOneWidget);
    });

    testWidgets('ErrorStateWidget marks error content with liveRegion: true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              title: 'Connection Lost',
              message: 'Please check your connection',
              onRetry: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final liveRegionFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.liveRegion == true,
      );
      expect(liveRegionFinder, findsOneWidget);
    });

    testWidgets('RecentContactsRow wraps contact in Semantics with full name and button', (tester) async {
      final contacts = [
        Contact(
          id: 'c1',
          firstName: 'Marco',
          lastName: 'Rossi',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentContactsRow(contacts: contacts),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final contactSemantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.button == true &&
            widget.properties.label == 'Marco Rossi' &&
            widget.excludeSemantics == true,
      );
      expect(contactSemantics, findsOneWidget);
    });

    testWidgets('FloatingActionButton should have a tooltip for screen readers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              tooltip: 'Add task',
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fab.tooltip, 'Add task');
    });
  });
}

