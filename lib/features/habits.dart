import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models.dart';
import '../core/state.dart';
import 'neo.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});
  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen>
    with AutomaticKeepAliveClientMixin<HabitsScreen> {
  @override
  bool get wantKeepAlive => true;
  DateTime selected = dayOnly(DateTime.now());
  bool showArchived = false;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final a = ref.watch(appProvider);
    return a.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (data) {
        final scheduled = data.habits
            .where((h) => h.scheduledOn(selected))
            .toList();
        final completed = scheduled.where((h) => h.doneOn(selected)).length;
        final others = data.habits
            .where(
              (h) => showArchived
                  ? h.archived
                  : !h.archived && !h.scheduledOn(selected),
            )
            .toList();
        return ScreenBody(
          children: [
            Headline('HABIT LAB ✦', 'Consistency, your way.'),
            NeoCard(
              color: themeColor(context, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM').format(selected).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$completed / ${scheduled.length} habits done',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: scheduled.isEmpty ? 0 : completed / scheduled.length,
                    minHeight: 10,
                    backgroundColor: Colors.white,
                    color: const Color(0xFF111111),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous day',
                  onPressed: () => setState(
                    () => selected = DateTime(
                      selected.year,
                      selected.month,
                      selected.day - 1,
                    ),
                  ),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: selected,
                        firstDate: DateTime(2020),
                        lastDate: dayOnly(DateTime.now()),
                      );
                      if (d != null) setState(() => selected = d);
                    },
                    child: Text(DateFormat('d MMM yyyy').format(selected)),
                  ),
                ),
                IconButton(
                  tooltip: 'Next day',
                  onPressed:
                      !dayOnly(selected).isBefore(dayOnly(DateTime.now()))
                      ? null
                      : () => setState(
                          () => selected = DateTime(
                            selected.year,
                            selected.month,
                            selected.day + 1,
                          ),
                        ),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            NeoButton(
              label: '+ CREATE A HABIT',
              icon: Icons.add,
              onPressed: () => showHabitEditor(context, ref),
            ),
            const SizedBox(height: 10),
            if (scheduled.isEmpty)
              const EmptyState(
                'A fresh page.',
                'No habits were scheduled for this day.',
                icon: Icons.spa_outlined,
              ),
            ...scheduled.map(
              (h) => NeoCard(
                color: themeColor(context, h.color),
                child: Row(
                  children: [
                    Icon(iconFor(h.icon), color: Colors.black),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          if (h.description.isNotEmpty)
                            Text(
                              h.description,
                              style: const TextStyle(color: Colors.black),
                            ),
                        ],
                      ),
                    ),
                    Checkbox(
                      activeColor: Colors.black,
                      checkColor: Colors.white,
                      value: h.doneOn(selected),
                      onChanged: (v) async {
                        try {
                          await ref
                              .read(appProvider.notifier)
                              .change(
                                (db) =>
                                    db.setHabitDone(h, selected, v ?? false),
                              );
                          if (ref.read(hapticsProvider).value ?? true)
                            HapticFeedback.lightImpact();
                        } catch (e) {
                          if (context.mounted)
                            toast(context, 'Could not save: $e');
                        }
                      },
                    ),
                    IconButton(
                      tooltip: 'Edit habit',
                      onPressed: () => showHabitEditor(context, ref, habit: h),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    showArchived ? 'ARCHIVED HABITS' : 'OTHER HABITS',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => showArchived = !showArchived),
                  child: Text(showArchived ? 'Active' : 'Archived'),
                ),
              ],
            ),
            ...others.map(
              (h) => NeoCard(
                onTap: () => showHabitEditor(context, ref, habit: h),
                child: Row(
                  children: [
                    Icon(iconFor(h.icon)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        h.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(showArchived ? 'Archived' : 'Not today'),
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

Future<void> showHabitEditor(
  BuildContext context,
  WidgetRef ref, {
  Habit? habit,
}) async => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => _HabitEditor(habit: habit),
);

class _HabitEditor extends ConsumerStatefulWidget {
  const _HabitEditor({this.habit});
  final Habit? habit;
  @override
  ConsumerState<_HabitEditor> createState() => _HabitEditorState();
}

class _HabitEditorState extends ConsumerState<_HabitEditor> {
  late final name = TextEditingController(text: widget.habit?.name ?? '');
  late final description = TextEditingController(
    text: widget.habit?.description ?? '',
  );
  late int days = widget.habit == null
      ? 127
      : (widget.habit!.revisions.isEmpty
            ? 127
            : widget.habit!.revisions.last.days);
  late int color = widget.habit?.color ?? 1, icon = widget.habit?.icon ?? 0;
  TimeOfDay? reminder;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final bits = widget.habit?.reminder?.split(':');
    if (bits != null && bits.length == 2)
      reminder = TimeOfDay(
        hour: int.parse(bits[0]),
        minute: int.parse(bits[1]),
      );
    if (widget.habit == null)
      SharedPreferences.getInstance().then((prefs) {
        if (mounted &&
            reminder == null &&
            (prefs.getBool('default_habit_reminders') ?? false))
          setState(() => reminder = const TimeOfDay(hour: 18, minute: 0));
      });
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        8,
        18,
        MediaQuery.viewInsetsOf(context).bottom + 22,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.habit == null ? 'NEW HABIT ✦' : 'EDIT HABIT',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: name,
              maxLength: 150,
              decoration: const InputDecoration(labelText: 'Habit name *'),
            ),
            TextField(
              controller: description,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'REPEAT ON',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            Wrap(
              spacing: 7,
              children: [
                for (var i = 0; i < 7; i++)
                  FilterChip(
                    label: Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][i]),
                    selected: (days & (1 << i)) != 0,
                    onSelected: (v) => setState(
                      () => days = v ? days | (1 << i) : days & ~(1 << i),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'PICK A COLOR',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            Wrap(
              children: [
                for (var i = 0; i < palette.length; i++)
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: colorFor(i)),
                    onPressed: () => setState(() => color = i),
                    icon: Icon(
                      color == i ? Icons.check : Icons.circle,
                      color: Colors.black,
                    ),
                  ),
              ],
            ),
            const Text(
              'PICK AN ICON',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            Wrap(
              children: [
                for (var i = 0; i < icons.length; i++)
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: icon == i ? colorFor(3) : null,
                    ),
                    icon: Icon(iconFor(i)),
                    onPressed: () => setState(() => icon = i),
                  ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.notifications_none),
              title: Text(
                reminder == null
                    ? 'Set optional reminder'
                    : reminder!.format(context),
              ),
              trailing: IconButton(
                onPressed: () => setState(() => reminder = null),
                icon: const Icon(Icons.clear),
              ),
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: reminder ?? const TimeOfDay(hour: 18, minute: 0),
                );
                if (t != null) setState(() => reminder = t);
              },
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (days == 0 || name.text.trim().isEmpty) {
                        toast(
                          context,
                          'Add a name and select at least one day.',
                        );
                        return;
                      }
                      setState(() => saving = true);
                      try {
                        await ref
                            .read(appProvider.notifier)
                            .change(
                              (db) => db.saveHabit(
                                id: widget.habit?.id,
                                name: name.text,
                                description: description.text,
                                days: days,
                                color: color,
                                icon: icon,
                                reminder: reminder == null
                                    ? null
                                    : '${reminder!.hour.toString().padLeft(2, '0')}:${reminder!.minute.toString().padLeft(2, '0')}',
                              ),
                            );
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted)
                          toast(context, 'Could not save: $e');
                      } finally {
                        if (mounted) setState(() => saving = false);
                      }
                    },
              child: const Text('SAVE HABIT'),
            ),
            if (widget.habit != null) ...[
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref
                      .read(appProvider.notifier)
                      .change(
                        (db) => db.archiveHabit(
                          widget.habit!.id,
                          !widget.habit!.archived,
                        ),
                      );
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.archive_outlined),
                label: Text(widget.habit!.archived ? 'RESTORE' : 'ARCHIVE'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  if (!await confirmDelete(context, 'habit')) return;
                  await ref
                      .read(appProvider.notifier)
                      .change((db) => db.deleteHabit(widget.habit!.id));
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('DELETE HABIT'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
