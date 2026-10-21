import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models.dart';
import '../core/state.dart';
import 'neo.dart';

/// Folder selection from the Home tab. No duplicate-value dropdowns.
final taskSubjectTarget = ValueNotifier<int?>(null);

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key, this.initialSubjectId});
  final int? initialSubjectId;
  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with AutomaticKeepAliveClientMixin<TasksScreen> {
  @override
  bool get wantKeepAlive => true;
  String filter = 'All', sort = 'Due', query = '';
  int? subjectId;
  @override
  void initState() {
    super.initState();
    subjectId = widget.initialSubjectId ?? taskSubjectTarget.value;
    taskSubjectTarget.addListener(_onSubjectChange);
  }

  void _onSubjectChange() {
    if (mounted) setState(() => subjectId = taskSubjectTarget.value);
  }

  @override
  void dispose() {
    taskSubjectTarget.removeListener(_onSubjectChange);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSubjectId != oldWidget.initialSubjectId)
      subjectId = widget.initialSubjectId;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final a = ref.watch(appProvider);
    return a.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (data) {
        var tasks = data.tasks
            .where(
              (t) =>
                  t.title.toLowerCase().contains(query.toLowerCase()) ||
                  t.description.toLowerCase().contains(query.toLowerCase()),
            )
            .where((t) => subjectId == null || t.subjectId == subjectId)
            .where(
              (t) => switch (filter) {
                'Today' => !t.completed && t.dueDay == dayKey(DateTime.now()),
                'Upcoming' =>
                  !t.completed &&
                      t.dueDay != null &&
                      t.dueDay!.compareTo(dayKey(DateTime.now())) > 0,
                'Overdue' => t.overdue,
                'Completed' => t.completed,
                _ => true,
              },
            )
            .toList();
        if (sort == 'Priority')
          tasks.sort(
            (a, b) => ({'high': 0, 'medium': 1, 'low': 2}[a.priority]!)
                .compareTo({'high': 0, 'medium': 1, 'low': 2}[b.priority]!),
          );
        if (sort == 'Newest') tasks.sort((a, b) => b.id.compareTo(a.id));
        return ScreenBody(
          children: [
            Headline('TASK BOARD', 'Your homework, without the chaos.'),
            TextField(
              onChanged: (s) => setState(() => query = s),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search tasks...',
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 0,
              children: ['All', 'Today', 'Upcoming', 'Overdue', 'Completed']
                  .map(
                    (f) => ChoiceChip(
                      label: Text(f),
                      selected: filter == f,
                      onSelected: (_) => setState(() => filter = f),
                    ),
                  )
                  .toList(),
            ),
            Row(
              children: [
                Expanded(
                  child: PopupMenuButton<int?>(
                    tooltip: 'Filter subjects',
                    onSelected: (v) => setState(() => subjectId = v),
                    itemBuilder: (_) => [
                      const PopupMenuItem<int?>(
                        value: null,
                        child: Text('All subjects'),
                      ),
                      ...data.subjects.map(
                        (s) => PopupMenuItem<int?>(
                          value: s.id,
                          child: Text(s.name),
                        ),
                      ),
                    ],
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Subject'),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              subjectId == null
                                  ? 'All subjects'
                                  : data.subjects
                                            .where((s) => s.id == subjectId)
                                            .map((s) => s.name)
                                            .firstOrNull ??
                                        'All subjects',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                PopupMenuButton<String>(
                  tooltip: 'Sort tasks',
                  onSelected: (v) => setState(() => sort = v),
                  itemBuilder: (_) => ['Due', 'Priority', 'Newest']
                      .map((v) => PopupMenuItem(value: v, child: Text(v)))
                      .toList(),
                  child: Chip(
                    label: Text(sort),
                    avatar: const Icon(Icons.sort, size: 17),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: NeoButton(
                    label: '+ ADD TASK',
                    icon: Icons.add,
                    onPressed: () => showTaskEditor(context, ref),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: NeoButton(
                    label: 'SUBJECTS',
                    icon: Icons.folder_copy_outlined,
                    color: themeColor(context, 3),
                    onPressed: () => showSubjects(context, ref, data),
                  ),
                ),
              ],
            ),
            if (tasks.isEmpty)
              const EmptyState(
                'No matching tasks.',
                'Try a different filter or create a task.',
              ),
            ...tasks.map(
              (t) => NeoCard(
                onTap: () => showTaskDetails(context, ref, t),
                child: Row(
                  children: [
                    Checkbox(
                      value: t.completed,
                      onChanged: (v) async {
                        await ref
                            .read(appProvider.notifier)
                            .change((db) => db.setTaskDone(t.id, v ?? false));
                        if (ref.read(hapticsProvider).value ?? true)
                          HapticFeedback.lightImpact();
                      },
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              decoration: t.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (t.description.isNotEmpty)
                            Text(
                              t.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (t.dueDay != null)
                                Text(
                                  t.dueDay!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              Text(
                                t.priority.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: t.priority == 'high'
                                      ? Colors.red
                                      : null,
                                ),
                              ),
                              if (t.subtasks.isNotEmpty)
                                Text(
                                  '${t.subtasks.where((s) => s.done).length}/${t.subtasks.length} steps',
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => showTaskEditor(context, ref, task: t),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

Future<void> showTaskEditor(
  BuildContext context,
  WidgetRef ref, {
  Task? task,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _TaskEditor(task: task),
  );
}

class _TaskEditor extends ConsumerStatefulWidget {
  const _TaskEditor({this.task});
  final Task? task;
  @override
  ConsumerState<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends ConsumerState<_TaskEditor> {
  late final title = TextEditingController(text: widget.task?.title ?? '');
  late final description = TextEditingController(
    text: widget.task?.description ?? '',
  );
  late String priority = widget.task?.priority ?? 'medium';
  late int? subjectId = widget.task == null
      ? taskSubjectTarget.value
      : widget.task!.subjectId;
  DateTime? due, reminder;
  bool busy = false, more = false;
  @override
  void initState() {
    super.initState();
    more = widget.task != null;
    due = DateTime.tryParse(widget.task?.dueAt ?? '');
    reminder = DateTime.tryParse(widget.task?.reminderAt ?? '');
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  Future<DateTime?> chooseDateTime(DateTime? current) async {
    final day = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (day == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        current ?? DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    return DateTime(
      day.year,
      day.month,
      day.day,
      time?.hour ?? 23,
      time?.minute ?? 59,
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(appProvider).value?.subjects ?? [];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        8,
        18,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.task == null ? 'NEW TASK ✦' : 'EDIT TASK',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 13),
            TextField(
              controller: title,
              autofocus: true,
              maxLength: 180,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'What do you need to do? *',
              ),
            ),
            const SizedBox(height: 9),
            TextButton.icon(
              onPressed: () => setState(() => more = !more),
              icon: Icon(more ? Icons.expand_less : Icons.tune_rounded),
              label: Text(
                more ? 'FEWER OPTIONS' : 'ADD SUBJECT, DATE & PRIORITY',
              ),
            ),
            if (more) ...[
              TextField(
                controller: description,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 12),
              PopupMenuButton<int?>(
                tooltip: 'Choose a subject',
                onSelected: (v) => setState(() => subjectId = v),
                itemBuilder: (_) => [
                  const PopupMenuItem<int?>(
                    value: null,
                    child: Text('No subject'),
                  ),
                  ...subjects.map(
                    (s) =>
                        PopupMenuItem<int?>(value: s.id, child: Text(s.name)),
                  ),
                ],
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Subject'),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          subjectId == null
                              ? 'No subject'
                              : subjects
                                        .where((s) => s.id == subjectId)
                                        .map((s) => s.name)
                                        .firstOrNull ??
                                    'No subject',
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Priority: '),
                  for (final p in ['low', 'medium', 'high'])
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: ChoiceChip(
                        label: Text(p),
                        selected: priority == p,
                        onSelected: (_) => setState(() => priority = p),
                      ),
                    ),
                ],
              ),
              ListTile(
                title: Text(
                  due == null
                      ? 'Set due date / time'
                      : DateFormat('EEE d MMM y, h:mm a').format(due!),
                ),
                leading: const Icon(Icons.event),
                trailing: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => due = null),
                ),
                onTap: () async {
                  final d = await chooseDateTime(due);
                  if (d != null) setState(() => due = d);
                },
              ),
              ListTile(
                title: Text(
                  reminder == null
                      ? 'Add optional reminder'
                      : DateFormat('EEE d MMM y, h:mm a').format(reminder!),
                ),
                leading: const Icon(Icons.notifications_active_outlined),
                trailing: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => reminder = null),
                ),
                onTap: () async {
                  final d = await chooseDateTime(reminder);
                  if (d != null) setState(() => reminder = d);
                },
              ),
            ],
            const SizedBox(height: 10),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (title.text.trim().isEmpty) {
                        toast(context, 'Add a task title first.');
                        return;
                      }
                      setState(() => busy = true);
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final automatic =
                            widget.task == null &&
                            due != null &&
                            (prefs.getBool('default_task_reminders') ?? false);
                        final chosenReminder =
                            reminder ??
                            (automatic
                                ? due!.subtract(const Duration(hours: 1))
                                : null);
                        await ref
                            .read(appProvider.notifier)
                            .change(
                              (db) => db.saveTask(
                                id: widget.task?.id,
                                title: title.text,
                                description: description.text,
                                subjectId:
                                    subjects.any((s) => s.id == subjectId)
                                    ? subjectId
                                    : null,
                                priority: priority,
                                dueAt: due?.toIso8601String(),
                                reminderAt: chosenReminder?.toIso8601String(),
                              ),
                            );
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted)
                          toast(context, 'Could not save: $e');
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
              child: Text(busy ? 'Saving...' : 'SAVE TASK'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The details sheet observes live task state so adding/checking off a step never
/// forces the student to close and reopen it.
Future<void> showTaskDetails(
  BuildContext context,
  WidgetRef parentRef,
  Task task,
) async {
  final controller = TextEditingController();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Consumer(
      builder: (ctx, ref, _) {
        final latest = ref.watch(appProvider).value?.tasks;
        final matches = latest?.where((item) => item.id == task.id).toList();
        if (matches == null) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (matches.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Task no longer exists.'),
          );
        }
        final current = matches.single;
        Future<void> addStep() async {
          final title = controller.text.trim();
          if (title.isEmpty) return;
          try {
            await ref
                .read(appProvider.notifier)
                .change((db) => db.addSubtask(current.id, title));
            controller.clear();
          } catch (error) {
            if (ctx.mounted) toast(ctx, 'Could not add step: $error');
          }
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            19,
            8,
            19,
            MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  current.title,
                  style: Theme.of(ctx).textTheme.headlineMedium,
                ),
                if (current.description.isNotEmpty) Text(current.description),
                const SizedBox(height: 18),
                const Text(
                  'SUBTASKS',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                for (final step in current.subtasks)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(step.title),
                    value: step.done,
                    onChanged: (value) async {
                      try {
                        await ref
                            .read(appProvider.notifier)
                            .change(
                              (db) =>
                                  db.setSubtaskDone(step.id, value ?? false),
                            );
                      } catch (error) {
                        if (ctx.mounted)
                          toast(ctx, 'Could not update step: $error');
                      }
                    },
                    secondary: IconButton(
                      tooltip: 'Delete step',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (!await confirmDelete(ctx, 'step')) return;
                        try {
                          await ref
                              .read(appProvider.notifier)
                              .change((db) => db.deleteSubtask(step.id));
                        } catch (error) {
                          if (ctx.mounted)
                            toast(ctx, 'Could not delete step: $error');
                        }
                      },
                    ),
                  ),
                TextField(
                  controller: controller,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => addStep(),
                  decoration: InputDecoration(
                    hintText: 'Add a smaller step',
                    suffixIcon: IconButton(
                      tooltip: 'Add step',
                      icon: const Icon(Icons.add),
                      onPressed: addStep,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (context.mounted)
                          showTaskEditor(context, parentRef, task: current);
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Duplicate'),
                      onPressed: () async {
                        await ref
                            .read(appProvider.notifier)
                            .change((db) => db.duplicateTask(current));
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      onPressed: () async {
                        if (!await confirmDelete(ctx, 'task')) return;
                        await ref
                            .read(appProvider.notifier)
                            .change((db) => db.deleteTask(current.id));
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  // Sheet reverse animation may briefly retain the TextField; dispose after it.
  Future<void>.delayed(const Duration(milliseconds: 400), controller.dispose);
}

Future<void> showSubjects(
  BuildContext context,
  WidgetRef ref,
  AppData data,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text('YOUR SUBJECTS', style: Theme.of(ctx).textTheme.headlineMedium),
          const SizedBox(height: 12),
          ...data.subjects.map(
            (s) => ListTile(
              leading: CircleAvatar(
                backgroundColor: colorFor(s.color),
                child: Icon(iconFor(s.icon), color: Colors.black),
              ),
              title: Text(s.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      showSubjectEditor(context, ref, s);
                    },
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: () async {
                      if (!await confirmDelete(ctx, 'subject')) return;
                      await ref
                          .read(appProvider.notifier)
                          .change((db) => db.deleteSubject(s.id));
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              showSubjectEditor(context, ref, null);
            },
            icon: const Icon(Icons.add),
            label: const Text('CREATE SUBJECT'),
          ),
        ],
      ),
    ),
  );
}

Future<void> showSubjectEditor(
  BuildContext context,
  WidgetRef ref,
  Subject? subject,
) async {
  final controller = TextEditingController(text: subject?.name ?? '');
  int color = subject?.color ?? 0, icon = subject?.icon ?? 0;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text(subject == null ? 'New subject' : 'Edit subject'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Subject name'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                children: [
                  for (var i = 0; i < palette.length; i++)
                    IconButton(
                      style: IconButton.styleFrom(backgroundColor: colorFor(i)),
                      onPressed: () => setLocal(() => color = i),
                      icon: Icon(
                        color == i ? Icons.check : Icons.circle,
                        color: Colors.black,
                      ),
                    ),
                ],
              ),
              Wrap(
                spacing: 6,
                children: [
                  for (var i = 0; i < icons.length; i++)
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: icon == i ? colorFor(3) : null,
                      ),
                      icon: Icon(iconFor(i)),
                      onPressed: () => setLocal(() => icon = i),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await ref
                    .read(appProvider.notifier)
                    .change(
                      (db) => db.saveSubject(
                        id: subject?.id,
                        name: controller.text,
                        color: color,
                        icon: icon,
                      ),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) toast(ctx, 'Could not save subject: $e');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  Future<void>.delayed(const Duration(milliseconds: 400), controller.dispose);
}
