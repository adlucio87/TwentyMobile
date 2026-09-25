import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/presentation/home/today_provider.dart';
import 'package:pocketcrm/presentation/home/widgets/task_today_card.dart';
import 'package:pocketcrm/presentation/home/widgets/recent_contacts_row.dart';
import 'package:pocketcrm/presentation/home/widgets/section_header.dart';
import 'package:pocketcrm/core/utils/platform_utils.dart';
import 'package:pocketcrm/presentation/scan/scan_card_screen.dart';
import 'package:pocketcrm/presentation/contacts/contacts_screen.dart';
import 'package:pocketcrm/presentation/tasks/tasks_screen.dart';
import 'package:pocketcrm/presentation/shared/error_state_widget.dart';
import 'package:pocketcrm/shared/widgets/constrained_content.dart';
import 'package:pocketcrm/l10n/app_localizations.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final todayState = ref.watch(todayNotifierProvider);

    return Scaffold(
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        spacing: 3,
        childPadding: const EdgeInsets.all(5),
        spaceBetweenChildren: 4,
        tooltip: l10n?.add ?? 'Add',
        heroTag: 'speed-dial-hero-tag',
        elevation: 8.0,
        animationCurve: Curves.easeOutCubic,
        isOpenOnStart: false,
        label: Text(l10n?.newAction ?? 'New'),
        children: [
          SpeedDialChild(
            child: const Icon(Icons.document_scanner),
            backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
            label: l10n?.scanBusinessCard ?? 'Scan business card',
            onTap: () {
              if (!PlatformUtils.supportsScan) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n?.onlyMobileScan ?? '📱 Only available on iPhone and Android'),
                ));
                return;
              }
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ScanCardScreen()));
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.person_add),
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
            label: l10n?.newContact ?? 'New contact',
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => const AddContactSheet(),
            ),
          ),
          SpeedDialChild(
            child: const Icon(Icons.add_task),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            label: l10n?.newQuickTask ?? 'New quick task',
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => const AddTaskSheet(),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(todayNotifierProvider.notifier).refresh(),
        child: ConstrainedContent(child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: 110.0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => context.push('/settings'),
                  tooltip: l10n?.settings ?? 'Settings',
                ),
              ],
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final top = constraints.biggest.height;
                  final statusBarHeight = MediaQuery.of(context).padding.top;
                  final minHeight = kToolbarHeight + statusBarHeight;
                  final maxHeight = 110.0 + statusBarHeight;
                  final t = ((top - minHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0);

                  return Consumer(
                    builder: (context, ref, child) {
                      final userNameAsync = ref.watch(currentUserNameProvider);
                      final userName = userNameAsync.valueOrNull ?? 'User';

                      final now = DateTime.now();
                      final hour = now.hour;
                      String greeting = l10n?.greetingMorning ?? "Good morning 👋  ";
                      if (hour >= 12 && hour < 18) {
                        greeting = l10n?.greetingAfternoon ?? "Good afternoon 👋  ";
                      } else if (hour >= 18 && hour < 24) {
                        greeting = l10n?.greetingEvening ?? "Good evening 👋  ";
                      } else if (hour >= 0 && hour < 5) {
                        greeting = l10n?.greetingNight ?? "Still awake? 👋  ";
                      }

                      final localeStr = Localizations.localeOf(context).toString();
                      final dateFormat = DateFormat('EEEE, d MMMM y', localeStr);
                      final dateString = dateFormat.format(now);
                      final formattedDate = dateString.replaceFirst(dateString[0], dateString[0].toUpperCase());

                      return Stack(
                        children: [
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 16,
                            child: Stack(
                              alignment: Alignment.bottomLeft,
                              children: [
                                Opacity(
                                  opacity: t,
                                  child: Transform.translate(
                                    offset: Offset(0, 10 * (1 - t)),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          greeting,
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formattedDate,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                        ),
                                        if (userName.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            userName,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                Opacity(
                                  opacity: 1 - t,
                                  child: Transform.translate(
                                    offset: Offset(0, -10 * t),
                                    child: Text(
                                      formattedDate,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            todayState.when(
              data: (data) {
                final hasOverdue = data.overdueTasks.isNotEmpty;
                final hasToday = data.todayTasks.isNotEmpty;
                final hasTomorrow = data.tomorrowTasks.isNotEmpty;
                final hasRecent = data.recentContacts.isNotEmpty;

                if (!hasOverdue && !hasToday && !hasTomorrow) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasRecent) ...[
                          SectionHeader(title: l10n?.recentContacts ?? "Recent"),
                          RecentContactsRow(contacts: data.recentContacts),
                          const Spacer(),
                        ],
                        const Text("🎉", style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        Text(
                          l10n?.allInOrder ?? "Everything is in order!",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n?.noTasksDueToday ?? "No tasks due today",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (context) => const AddTaskSheet(),
                          ),
                          child: Text(l10n?.addTask ?? "Add task"),
                        ),
                        if (hasRecent) const Spacer(flex: 2),
                      ],
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildListDelegate([
                    if (hasOverdue) ...[
                      SectionHeader(
                        title: l10n?.overdueTasks ?? "Overdue",
                        count: data.overdueTasks.length,
                        countColor: Theme.of(context).colorScheme.error,
                      ),
                      ...data.overdueTasks.map((t) => TaskTodayCard(task: t, isOverdue: true)),
                    ],

                    SectionHeader(
                      title: l10n?.todayTasks ?? "Today",
                      count: data.todayTasks.length,
                    ),
                    if (hasToday)
                      ...data.todayTasks.map((t) => TaskTodayCard(task: t))
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(l10n?.noTasksToday ?? "No tasks for today 🎉", style: Theme.of(context).textTheme.bodyMedium),
                      ),

                    if (hasTomorrow) ...[
                      SectionHeader(title: l10n?.tomorrowTasks ?? "Tomorrow"),
                      ...data.tomorrowTasks.take(3).map((t) => Opacity(
                        opacity: 0.7,
                        child: TaskTodayCard(task: t),
                      )),
                      if (data.tomorrowTasks.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 8),
                          child: Text(
                            l10n?.andMoreTasks(data.tomorrowTasks.length - 3) ??
                                "and ${data.tomorrowTasks.length - 3} more...",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],

                    if (hasRecent) ...[
                      SectionHeader(title: l10n?.recentContacts ?? "Recent"),
                      RecentContactsRow(contacts: data.recentContacts),
                    ],

                    const SizedBox(height: 80), // Padding for FAB
                  ]),
                );
              },
              loading: () => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Shimmer.fromColors(
                    baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    highlightColor: Theme.of(context).colorScheme.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 100, height: 20, color: Colors.white, margin: const EdgeInsets.only(top: 20, bottom: 8)),
                        Container(height: 70, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.symmetric(vertical: 4)),
                        Container(height: 70, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.symmetric(vertical: 4)),

                        Container(width: 100, height: 20, color: Colors.white, margin: const EdgeInsets.only(top: 30, bottom: 8)),
                        Row(
                          children: List.generate(4, (index) => Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          )),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              error: (err, stack) => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorStateWidget(
                  title: l10n?.loadingError ?? 'Loading error',
                  message: err.toString().replaceAll('Exception: ', ''),
                  onRetry: () => ref.read(todayNotifierProvider.notifier).refresh(),
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }
}
