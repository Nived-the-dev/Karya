import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/models.dart';
import '../core/state.dart';
import '../core/appearance.dart';
import '../main.dart';
import 'neo.dart';
import 'tasks.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(appProvider), c = look(context);
    return a.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load Home: $e')),
      data: (data) {
        final today = DateTime.now();
        final habits = data.habits.where((h) => h.scheduledOn(today)).toList();
        final completed = habits.where((h) => h.doneOn(today)).length;
        final pending = data.tasks.where((t) => !t.completed).toList();
        final urgent = pending
            .where((t) => t.overdue || t.dueDay == dayKey(today))
            .toList();
        final upcoming = pending
            .where(
              (t) => t.dueDay != null && t.dueDay!.compareTo(dayKey(today)) > 0,
            )
            .toList();
        final week = List.generate(
          7,
          (i) => DateTime(today.year, today.month, today.day - i),
        );
        final weekly = week.fold(
          0,
          (int sum, d) => sum + statsFor(data.habits, d).completed,
        );
        return ScreenBody(
          children: [
            Headline(
              'YOUR SPACE ✦',
              DateFormat('EEEE, d MMMM y').format(today),
            ),
            Row(
              children: [
                Expanded(
                  child: NeoCard(
                    color: c.primary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DUE + OVERDUE',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${urgent.length}',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: NeoCard(
                    color: c.secondary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HABITS TODAY',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '$completed/${habits.length}',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'SUBJECT BOARDS',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Add a subject',
                  onPressed: () => showSubjectEditor(context, ref, null),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
                IconButton(
                  tooltip: 'Manage subjects',
                  onPressed: () => showSubjects(context, ref, data),
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (data.subjects.isEmpty)
              NeoCard(
                onTap: () => showSubjectEditor(context, ref, null),
                color: c.tertiary,
                child: const ListTile(
                  leading: Icon(Icons.create_new_folder_outlined, size: 30),
                  title: Text(
                    'CREATE YOUR FIRST SUBJECT',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text('Mathematics? Work? Personal? Your call.'),
                  trailing: Icon(Icons.add_circle_outline),
                ),
              ),
            if (data.subjects.isNotEmpty)
              LayoutBuilder(
                builder: (context, box) {
                  final width = (box.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 2,
                    children: [
                      for (final s in data.subjects)
                        SizedBox(
                          width: width,
                          child: NeoCard(
                            color: themeColor(context, s.color),
                            onTap: () {
                              taskSubjectTarget.value = s.id;
                              selectKaryaTab(1);
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  iconFor(s.icon),
                                  color: Colors.black,
                                  size: 30,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  s.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${pending.where((t) => t.subjectId == s.id).length} tasks to do',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(
                        width: width,
                        child: NeoCard(
                          onTap: () => showSubjectEditor(context, ref, null),
                          child: const SizedBox(
                            height: 90,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 29),
                                Text(
                                  'NEW BOARD',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 8),
            NeoButton(
              label: '+ ADD A TASK',
              icon: Icons.add_circle_outline_rounded,
              onPressed: () {
                taskSubjectTarget.value = null;
                showTaskEditor(context, ref);
              },
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'UP NEXT',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: () => selectKaryaTab(1),
                  child: const Text('All tasks →'),
                ),
              ],
            ),
            if (urgent.isEmpty)
              const EmptyState(
                'All clear! ✦',
                'No tasks due today or overdue.',
                icon: Icons.celebration_outlined,
              ),
            ...urgent
                .take(4)
                .map(
                  (t) => NeoCard(
                    onTap: () => showTaskDetails(context, ref, t),
                    child: Row(
                      children: [
                        Icon(
                          t.overdue
                              ? Icons.warning_amber_rounded
                              : Icons.assignment_outlined,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            t.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          t.overdue ? 'OVERDUE' : 'TODAY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: t.overdue ? Colors.red : c.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (upcoming.isNotEmpty)
              NeoCard(
                child: Text(
                  '${upcoming.length} assignment${upcoming.length == 1 ? '' : 's'} coming up • Next: ${upcoming.first.title}',
                ),
              ),
            NeoCard(
              onTap: () => selectKaryaTab(4),
              child: Row(
                children: [
                  const Icon(Icons.insights_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$weekly habit check-ins this week • ${data.completed} tasks done',
                    ),
                  ),
                ],
              ),
            ),
            NeoButton(
              label: 'BRAIN DUMP  ✦',
              icon: Icons.bubble_chart_outlined,
              color: c.tertiary,
              onPressed: () => context.push('/chat'),
            ),
          ],
        );
      },
    );
  }
}
