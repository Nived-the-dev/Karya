import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/commands.dart';
import '../core/brain_dump.dart';
import 'tasks.dart';
import '../core/models.dart';
import '../core/state.dart';
import 'neo.dart';

class _Message {
  const _Message(this.text, this.fromUser);
  final String text;
  final bool fromUser;
}

class _CommandsScreen extends ConsumerStatefulWidget {
  const _CommandsScreen();
  @override
  ConsumerState<_CommandsScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<_CommandsScreen> {
  final input = TextEditingController(), scroll = ScrollController();
  final messages = <_Message>[
    const _Message(
      'Hey! I’m Kārya ✦\nI can add tasks, tick off habits, and show your progress. Type /help or choose a shortcut below.',
      false,
    ),
  ];
  bool sending = false;
  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send([String? shortcut]) async {
    final raw = (shortcut ?? input.text).trim();
    if (raw.isEmpty) return;
    input.clear();
    setState(() {
      messages.add(_Message(raw, true));
      sending = true;
    });
    try {
      final result = await runCommand(raw);
      if (mounted) setState(() => messages.add(_Message(result, false)));
    } catch (e) {
      if (mounted)
        setState(
          () => messages.add(_Message('Could not run that command: $e', false)),
        );
    } finally {
      if (mounted) {
        setState(() => sending = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scroll.hasClients)
            scroll.animateTo(
              scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
        });
      }
    }
  }

  Future<String> runCommand(String raw) async {
    try {
      final cmd = Command.parse(raw);
      final data =
          ref.read(appProvider).value ?? await ref.read(dbProvider).snapshot();
      final mutate = ref.read(appProvider.notifier);
      Task requireTask(String v) {
        final id = int.tryParse(v);
        if (id == null)
          throw const FormatException(
            'Use a task ID, e.g. /markdone 3. Find IDs with /viewtasks.',
          );
        final found = data.tasks.where((t) => t.id == id);
        if (found.isEmpty) throw FormatException('Task #$id not found.');
        return found.first;
      }

      Habit requireHabit(String v) {
        final id = int.tryParse(v);
        if (id == null)
          throw const FormatException('Use a habit ID. See /viewhabits.');
        final found = data.habits.where((h) => h.id == id);
        if (found.isEmpty) throw FormatException('Habit #$id not found.');
        return found.first;
      }

      switch (cmd.name) {
        case '/addtask':
        case '/add':
          final t = parseTaskInput(cmd.arg, DateTime.now());
          int? subjectId;
          if (t.subject != null) {
            final matches = data.subjects
                .where((s) => s.name.toLowerCase() == t.subject!.toLowerCase())
                .toList();
            if (matches.isNotEmpty) {
              subjectId = matches.first.id;
            } else {
              subjectId = await mutate.change(
                (db) => db.saveSubject(
                  name: t.subject!,
                  color: data.subjects.length % palette.length,
                  icon: 0,
                ),
              );
            }
          }
          final id = await mutate.change(
            (db) => db.saveTask(
              title: t.title,
              priority: t.priority,
              subjectId: subjectId,
              dueAt: t.dueAt == null ? null : '${t.dueAt}T23:59:00',
            ),
          );
          return 'Added task #$id: ${t.title} ✓${t.dueAt == null ? '' : '\nDue ${t.dueAt}'}';
        case '/viewtasks':
        case '/tasks':
          return 'ALL TASKS\n${taskLines(data.tasks)}';
        case '/today':
          return 'TODAY / PAST DUE\n${taskLines(data.tasks.where((t) => !t.completed && t.dueDay != null && t.dueDay!.compareTo(dayKey(DateTime.now())) <= 0).toList())}';
        case '/upcoming':
          return 'COMING UP\n${taskLines(data.tasks.where((t) => !t.completed && t.dueDay != null && t.dueDay!.compareTo(dayKey(DateTime.now())) > 0).toList())}';
        case '/overdue':
          return 'OVERDUE\n${taskLines(data.tasks.where((t) => t.overdue).toList())}';
        case '/completed':
          return 'DONE\n${taskLines(data.tasks.where((t) => t.completed).toList())}';
        case '/important':
          return 'HIGH PRIORITY\n${taskLines(data.tasks.where((t) => t.priority == 'high' && !t.completed).toList())}';
        case '/markdone':
        case '/done':
          final task = requireTask(cmd.arg);
          await mutate.change((db) => db.setTaskDone(task.id, true));
          return 'Great work! ✓ Task #${task.id} completed.';
        case '/undo':
          final task = requireTask(cmd.arg);
          await mutate.change((db) => db.setTaskDone(task.id, false));
          return 'Task #${task.id} reopened.';
        case '/delete':
        case '/remove':
          final task = requireTask(cmd.arg);
          final ok = await confirmDelete(context, 'task #${task.id}');
          if (!ok) return 'Deletion canceled.';
          await mutate.change((db) => db.deleteTask(task.id));
          return 'Deleted task #${task.id}.';
        case '/edit':
          final match = RegExp(
            r'^(\d+)\s+(.+)$',
            dotAll: true,
          ).firstMatch(cmd.arg);
          if (match == null)
            throw const FormatException('Use /edit 3 New task title');
          final task = requireTask(match.group(1)!);
          await mutate.change(
            (db) => db.saveTask(
              id: task.id,
              title: match.group(2)!,
              description: task.description,
              subjectId: task.subjectId,
              priority: task.priority,
              dueAt: task.dueAt,
              reminderAt: task.reminderAt,
            ),
          );
          return 'Renamed task #${task.id} ✓';
        case '/priority':
          final match = RegExp(
            r'^(\d+)\s+(low|medium|normal|high)$',
            caseSensitive: false,
          ).firstMatch(cmd.arg);
          if (match == null)
            throw const FormatException(
              'Use /priority 3 high (or medium / low)',
            );
          final task = requireTask(match.group(1)!);
          final priority = match
              .group(2)!
              .toLowerCase()
              .replaceAll('normal', 'medium');
          await mutate.change(
            (db) => db.saveTask(
              id: task.id,
              title: task.title,
              description: task.description,
              subjectId: task.subjectId,
              priority: priority,
              dueAt: task.dueAt,
              reminderAt: task.reminderAt,
            ),
          );
          return 'Task #${task.id} priority: $priority';
        case '/reschedule':
          final match = RegExp(r'^(\d+)\s+(.+)$').firstMatch(cmd.arg);
          if (match == null)
            throw const FormatException(
              'Use /reschedule 3 tomorrow (or YYYY-MM-DD / none)',
            );
          final task = requireTask(match.group(1)!);
          final arg = match.group(2)!.toLowerCase();
          final due = arg == 'none'
              ? null
              : parseTaskInput('something $arg', DateTime.now()).dueAt;
          if (arg != 'none' && due == null)
            throw const FormatException(
              'Date should be today, tomorrow, next week or YYYY-MM-DD.',
            );
          await mutate.change(
            (db) => db.saveTask(
              id: task.id,
              title: task.title,
              description: task.description,
              subjectId: task.subjectId,
              priority: task.priority,
              dueAt: due == null ? null : '${due}T23:59:00',
              reminderAt: task.reminderAt,
            ),
          );
          return due == null
              ? 'Cleared task #${task.id} deadline.'
              : 'Rescheduled task #${task.id} to $due.';
        case '/search':
          if (cmd.arg.isEmpty)
            throw const FormatException('Use /search keywords');
          return 'SEARCH RESULTS\n${taskLines(data.tasks.where((t) => t.title.toLowerCase().contains(cmd.arg.toLowerCase())).toList())}';
        case '/addhabit':
          if (cmd.arg.isEmpty)
            throw const FormatException('Use /addhabit Read for 20 minutes');
          final id = await mutate.change(
            (db) => db.saveHabit(name: cmd.arg, days: 127, color: 2, icon: 4),
          );
          return 'Created daily habit #$id: ${cmd.arg} ✓\nEdit it in Habits to select specific weekdays.';
        case '/viewhabits':
          if (data.habits.isEmpty)
            return 'No habits yet. Try /addhabit Read for 20 minutes';
          return 'YOUR HABITS\n${data.habits.map((h) => '${h.archived ? 'Archived' : '○'} #${h.id} ${h.name}').join('\n')}';
        case '/donehabit':
          final h = requireHabit(cmd.arg);
          await mutate.change((db) => db.setHabitDone(h, DateTime.now(), true));
          return 'Habit #${h.id} checked off for today ✓';
        case '/stats':
          final today = statsFor(data.habits, DateTime.now());
          return 'YOUR PROGRESS ✦\n${data.completed}/${data.tasks.length} tasks complete\n${data.overdue} overdue\n${today.completed}/${today.scheduled} habits completed today';
        case '/help':
          return commandsHelp;
        default:
          return 'I don’t know ${cmd.name} yet. Try /help for supported commands.\nThis is a rule-based assistant, not generative AI.';
      }
    } on FormatException catch (e) {
      return e.message;
    } on ArgumentError catch (e) {
      return e.message?.toString() ?? 'Invalid input.';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'ASK KĀRYA  /',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (ctx, i) {
                final msg = messages[i];
                return Align(
                  alignment: msg.fromUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(ctx).width * .87,
                    ),
                    child: NeoCard(
                      color: msg.fromUser ? colorFor(3) : null,
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          color: msg.fromUser ? Colors.black : null,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (sending) const LinearProgressIndicator(),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final cmd in [
                  '/help',
                  '/today',
                  '/viewtasks',
                  '/viewhabits',
                  '/stats',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ActionChip(
                      label: Text(cmd),
                      onPressed: () => send(cmd),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    maxLength: 600,
                    maxLines: 1,
                    onSubmitted: (_) => send(),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: 'Type /help or add a task',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: sending ? null : () => send(),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Brain Dump is the primary entry point; legacy slash commands remain optional.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _BrainHubState();
}

class _BrainHubState extends State<ChatScreen> {
  bool advanced = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('KĀRYA BRAIN DUMP ✦'),
      actions: [
        IconButton(
          tooltip: advanced ? 'Show Brain Dump' : 'Show command tools',
          icon: Icon(advanced ? Icons.lightbulb_outline : Icons.terminal),
          onPressed: () => setState(() => advanced = !advanced),
        ),
      ],
    ),
    body: advanced ? const _CommandsScreen() : const _BrainDumpScreen(),
  );
}

class _BrainDumpScreen extends ConsumerStatefulWidget {
  const _BrainDumpScreen();
  @override
  ConsumerState<_BrainDumpScreen> createState() => _BrainDumpState();
}

class _BrainDumpState extends ConsumerState<_BrainDumpScreen> {
  final input = TextEditingController();
  List<TaskInput> suggestions = [];
  final selected = <int>{};
  bool saving = false;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void parse() {
    final proposed = suggestTasks(input.text, DateTime.now());
    setState(() {
      suggestions = proposed;
      selected
        ..clear()
        ..addAll(List.generate(proposed.length, (i) => i));
    });
    if (proposed.isEmpty) toast(context, 'Write at least one idea first.');
  }

  Future<void> confirm() async {
    if (saving || selected.isEmpty) return;
    setState(() => saving = true);
    try {
      var count = 0;
      final folderIds = {
        for (final s in ref.read(appProvider).value?.subjects ?? <Subject>[])
          s.name.toLowerCase(): s.id,
      };
      for (final i in selected.toList()..sort()) {
        final t = suggestions[i];
        int? subjectId;
        if (t.subject != null) {
          final name = t.subject!.toLowerCase();
          subjectId = folderIds[name];
          if (subjectId == null) {
            subjectId = await ref
                .read(appProvider.notifier)
                .change(
                  (db) => db.saveSubject(
                    name: t.subject!,
                    color: folderIds.length % palette.length,
                    icon: 0,
                  ),
                );
            folderIds[name] = subjectId!;
          }
        }
        await ref
            .read(appProvider.notifier)
            .change(
              (db) => db.saveTask(
                title: t.title,
                priority: t.priority,
                subjectId: subjectId,
                dueAt: t.dueAt == null ? null : '${t.dueAt}T23:59:00',
              ),
            );
        count++;
      }
      if (mounted) {
        toast(context, 'Created $count task${count == 1 ? '' : 's'} ✦');
        setState(() {
          suggestions = [];
          selected.clear();
          input.clear();
        });
      }
    } catch (error) {
      if (mounted) toast(context, 'Could not add tasks: $error');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ScreenBody(
    children: [
      const Headline(
        'DUMP THE CHAOS.',
        'Write it messily. Kārya makes an editable task checklist.',
      ),
      const NeoCard(
        child: Text(
          'OFFLINE · RULE-BASED · PRIVATE\nThis is not generative AI. You always review before anything is saved.',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      TextField(
        controller: input,
        maxLength: 3000,
        maxLines: 6,
        minLines: 4,
        decoration: const InputDecoration(
          hintText:
              'Finish calculus tomorrow #math !high\nBuy a notebook\nRevise chemistry Friday...\n\nUse a new line for each task.',
        ),
      ),
      const SizedBox(height: 10),
      NeoButton(
        label: 'TURN INTO TASK SUGGESTIONS',
        icon: Icons.auto_fix_high_rounded,
        onPressed: parse,
      ),
      if (suggestions.isNotEmpty) ...[
        const SizedBox(height: 18),
        Text(
          'REVIEW BEFORE SAVING',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Text(
          'Tap a suggestion to include or exclude it. Check dates and subjects first. Missing #subjects will be created when you confirm.',
        ),
        for (var i = 0; i < suggestions.length; i++)
          NeoCard(
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(suggestions[i].title),
              subtitle: Text(
                [
                  if (suggestions[i].dueAt != null)
                    'Due ${suggestions[i].dueAt}',
                  if (suggestions[i].subject != null)
                    '#${suggestions[i].subject}',
                  suggestions[i].priority,
                ].join(' · '),
              ),
              value: selected.contains(i),
              onChanged: (v) => setState(
                () => v == true ? selected.add(i) : selected.remove(i),
              ),
            ),
          ),
        NeoButton(
          label: saving
              ? 'SAVING...'
              : 'ADD ${selected.length} TASK${selected.length == 1 ? '' : 'S'}',
          icon: Icons.check_rounded,
          onPressed: saving || selected.isEmpty ? null : confirm,
        ),
      ],
      const SizedBox(height: 14),
      NeoCard(
        onTap: () => showTaskEditor(context, ref),
        child: const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.add_task),
          title: Text('Rather add one task?'),
          subtitle: Text('Open the regular task editor'),
          trailing: Icon(Icons.chevron_right),
        ),
      ),
    ],
  );
}
