import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'models.dart';

/// SQL deliberately kept in one place; Drift handles connections and transactions.
/// No code generation is needed to build this project.
class KaryaDatabase extends GeneratedDatabase {
  KaryaDatabase()
    : super(
        LazyDatabase(() async {
          final dir = await getApplicationDocumentsDirectory();
          return NativeDatabase.createInBackground(
            File(p.join(dir.path, 'karya.sqlite')),
          );
        }),
      );

  KaryaDatabase.test(QueryExecutor executor) : super(executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];
  @override
  int get schemaVersion => 2;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await customStatement('PRAGMA foreign_keys = ON');
      for (final sql in schema) {
        await customStatement(sql);
      }
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) await customStatement(notesSchema);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static const notesSchema =
      '''CREATE TABLE IF NOT EXISTS ideas (id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT NOT NULL, pinned INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''';
  static const schema = <String>[
    notesSchema,
    '''CREATE TABLE subjects (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE COLLATE NOCASE, color INTEGER NOT NULL DEFAULT 0, icon INTEGER NOT NULL DEFAULT 0)''',
    '''CREATE TABLE tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, description TEXT NOT NULL DEFAULT '', subject_id INTEGER REFERENCES subjects(id) ON DELETE SET NULL, priority TEXT NOT NULL CHECK(priority IN ('low','medium','high')), due_at TEXT, reminder_at TEXT, created_at TEXT NOT NULL, completed_at TEXT)''',
    '''CREATE INDEX idx_task_due ON tasks(due_at, completed_at)''',
    '''CREATE INDEX idx_task_subject ON tasks(subject_id)''',
    '''CREATE TABLE subtasks (id INTEGER PRIMARY KEY AUTOINCREMENT, task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE, title TEXT NOT NULL, done INTEGER NOT NULL DEFAULT 0)''',
    '''CREATE INDEX idx_subtasks_parent ON subtasks(task_id)''',
    '''CREATE TABLE habits (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT NOT NULL DEFAULT '', icon INTEGER NOT NULL DEFAULT 0, color INTEGER NOT NULL DEFAULT 0, reminder TEXT, created_day TEXT NOT NULL, archived_day TEXT)''',
    '''CREATE TABLE habit_schedules (habit_id INTEGER NOT NULL REFERENCES habits(id) ON DELETE CASCADE, from_day TEXT NOT NULL, days INTEGER NOT NULL CHECK(days BETWEEN 1 AND 127), PRIMARY KEY(habit_id, from_day))''',
    '''CREATE TABLE habit_logs (habit_id INTEGER NOT NULL REFERENCES habits(id) ON DELETE CASCADE, day TEXT NOT NULL, PRIMARY KEY(habit_id, day))''',
    '''CREATE INDEX idx_habit_logs_day ON habit_logs(day)''',
    '''CREATE TABLE habit_status (habit_id INTEGER NOT NULL REFERENCES habits(id) ON DELETE CASCADE, day TEXT NOT NULL, active INTEGER NOT NULL CHECK(active IN (0,1)), PRIMARY KEY(habit_id,day))''',
  ];
  Future<AppData> snapshot() async {
    final subjects =
        (await customSelect(
              'SELECT * FROM subjects ORDER BY name COLLATE NOCASE',
            ).get())
            .map(
              (r) => Subject(
                r.read<int>('id'),
                r.read<String>('name'),
                r.read<int>('color'),
                r.read<int>('icon'),
              ),
            )
            .toList();
    final subrows = await customSelect(
      'SELECT * FROM subtasks ORDER BY id',
    ).get();
    final subMap = <int, List<Subtask>>{};
    for (final r in subrows) {
      final s = Subtask(
        r.read<int>('id'),
        r.read<int>('task_id'),
        r.read<String>('title'),
        r.read<int>('done') == 1,
      );
      subMap.putIfAbsent(s.taskId, () => []).add(s);
    }
    final tasks =
        (await customSelect(
          'SELECT * FROM tasks ORDER BY CASE WHEN completed_at IS NULL THEN 0 ELSE 1 END, CASE WHEN due_at IS NULL THEN 1 ELSE 0 END, due_at, id DESC',
        ).get()).map((r) {
          final id = r.read<int>('id');
          return Task(
            id: id,
            title: r.read<String>('title'),
            description: r.read<String>('description'),
            subjectId: r.readNullable<int>('subject_id'),
            priority: r.read<String>('priority'),
            dueAt: r.readNullable<String>('due_at'),
            reminderAt: r.readNullable<String>('reminder_at'),
            createdAt: r.read<String>('created_at'),
            completedAt: r.readNullable<String>('completed_at'),
            subtasks: subMap[id] ?? [],
          );
        }).toList();
    final revisions = <int, List<ScheduleRevision>>{};
    for (final r in await customSelect(
      'SELECT * FROM habit_schedules ORDER BY from_day ASC',
    ).get()) {
      revisions
          .putIfAbsent(r.read<int>('habit_id'), () => [])
          .add(
            ScheduleRevision(r.read<String>('from_day'), r.read<int>('days')),
          );
    }
    final logs = <int, Set<String>>{};
    for (final r in await customSelect('SELECT * FROM habit_logs').get()) {
      logs
          .putIfAbsent(r.read<int>('habit_id'), () => {})
          .add(r.read<String>('day'));
    }
    final statuses = <int, Map<String, bool>>{};
    for (final r in await customSelect(
      'SELECT * FROM habit_status ORDER BY day ASC',
    ).get()) {
      statuses.putIfAbsent(
        r.read<int>('habit_id'),
        () => {},
      )[r.read<String>('day')] = r.read<int>('active') == 1;
    }
    final habits =
        (await customSelect(
          'SELECT * FROM habits ORDER BY archived_day IS NOT NULL, id DESC',
        ).get()).map((r) {
          final id = r.read<int>('id');
          return Habit(
            id: id,
            name: r.read<String>('name'),
            description: r.read<String>('description'),
            icon: r.read<int>('icon'),
            color: r.read<int>('color'),
            reminder: r.readNullable<String>('reminder'),
            createdDay: r.read<String>('created_day'),
            archivedDay: r.readNullable<String>('archived_day'),
            revisions: revisions[id] ?? [],
            logs: logs[id] ?? {},
            statusChanges: statuses[id] ?? {},
          );
        }).toList();
    final notes =
        (await customSelect(
              'SELECT * FROM ideas ORDER BY pinned DESC, updated_at DESC, id DESC',
            ).get())
            .map(
              (r) => IdeaNote(
                id: r.read<int>('id'),
                text: r.read<String>('text'),
                pinned: r.read<int>('pinned') == 1,
                createdAt: r.read<String>('created_at'),
                updatedAt: r.read<String>('updated_at'),
              ),
            )
            .toList();
    return AppData(tasks, subjects, habits, notes);
  }

  Future<int> saveSubject({
    int? id,
    required String name,
    required int color,
    required int icon,
  }) async {
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError('Subject name cannot be empty.');
    if (id == null)
      return customInsert(
        'INSERT INTO subjects(name,color,icon) VALUES(?,?,?)',
        variables: [
          Variable.withString(clean),
          Variable.withInt(color),
          Variable.withInt(icon),
        ],
      );
    await customUpdate(
      'UPDATE subjects SET name=?,color=?,icon=? WHERE id=?',
      variables: [
        Variable.withString(clean),
        Variable.withInt(color),
        Variable.withInt(icon),
        Variable.withInt(id),
      ],
    );
    return id;
  }

  Future<void> deleteSubject(int id) async =>
      customStatement('DELETE FROM subjects WHERE id=?', [id]);
  Future<int> saveTask({
    int? id,
    required String title,
    String description = '',
    int? subjectId,
    String priority = 'medium',
    String? dueAt,
    String? reminderAt,
  }) async {
    final clean = title.trim();
    if (clean.isEmpty || clean.length > 180)
      throw ArgumentError('Task title must contain 1–180 characters.');
    final values = [
      Variable.withString(clean),
      Variable.withString(description.trim()),
      subjectId == null
          ? const Variable<int>(null)
          : Variable.withInt(subjectId),
      Variable.withString(priority),
      dueAt == null ? const Variable<String>(null) : Variable.withString(dueAt),
      reminderAt == null
          ? const Variable<String>(null)
          : Variable.withString(reminderAt),
    ];
    if (id == null) {
      return customInsert(
        'INSERT INTO tasks(title,description,subject_id,priority,due_at,reminder_at,created_at) VALUES(?,?,?,?,?,?,?)',
        variables: [
          ...values,
          Variable.withString(DateTime.now().toIso8601String()),
        ],
      );
    }
    await customUpdate(
      'UPDATE tasks SET title=?,description=?,subject_id=?,priority=?,due_at=?,reminder_at=? WHERE id=?',
      variables: [...values, Variable.withInt(id)],
    );
    return id;
  }

  Future<void> setTaskDone(int id, bool done) => customStatement(
    'UPDATE tasks SET completed_at=? WHERE id=?',
    [done ? DateTime.now().toIso8601String() : null, id],
  );
  Future<void> deleteTask(int id) =>
      customStatement('DELETE FROM tasks WHERE id=?', [id]);
  Future<int> duplicateTask(Task task) async {
    return transaction(() async {
      final newId = await saveTask(
        title: '${task.title} (copy)',
        description: task.description,
        subjectId: task.subjectId,
        priority: task.priority,
        dueAt: task.dueAt,
        reminderAt: null,
      );
      for (final sub in task.subtasks) {
        await addSubtask(newId, sub.title);
      }
      return newId;
    });
  }

  Future<int> addSubtask(int taskId, String title) => customInsert(
    'INSERT INTO subtasks(task_id,title) VALUES(?,?)',
    variables: [Variable.withInt(taskId), Variable.withString(title.trim())],
  );
  Future<void> setSubtaskDone(int id, bool done) => customStatement(
    'UPDATE subtasks SET done=? WHERE id=?',
    [done ? 1 : 0, id],
  );
  Future<void> deleteSubtask(int id) =>
      customStatement('DELETE FROM subtasks WHERE id=?', [id]);
  Future<int> saveHabit({
    int? id,
    required String name,
    String description = '',
    required int days,
    int icon = 0,
    int color = 0,
    String? reminder,
  }) async {
    if (name.trim().isEmpty) throw ArgumentError('Give your habit a name.');
    if (days < 1 || days > 127) throw ArgumentError('Select at least one day.');
    final today = dayKey(DateTime.now());
    return transaction(() async {
      late final int habitId;
      if (id == null) {
        habitId = await customInsert(
          'INSERT INTO habits(name,description,icon,color,reminder,created_day) VALUES(?,?,?,?,?,?)',
          variables: [
            Variable.withString(name.trim()),
            Variable.withString(description.trim()),
            Variable.withInt(icon),
            Variable.withInt(color),
            reminder == null
                ? const Variable<String>(null)
                : Variable.withString(reminder),
            Variable.withString(today),
          ],
        );
      } else {
        habitId = id;
        await customUpdate(
          'UPDATE habits SET name=?,description=?,icon=?,color=?,reminder=? WHERE id=?',
          variables: [
            Variable.withString(name.trim()),
            Variable.withString(description.trim()),
            Variable.withInt(icon),
            Variable.withInt(color),
            reminder == null
                ? const Variable<String>(null)
                : Variable.withString(reminder),
            Variable.withInt(id),
          ],
        );
      }
      final existing = await customSelect(
        'SELECT days FROM habit_schedules WHERE habit_id=? AND from_day<=? ORDER BY from_day DESC LIMIT 1',
        variables: [Variable.withInt(habitId), Variable.withString(today)],
      ).getSingleOrNull();
      if (existing == null || existing.read<int>('days') != days) {
        await customStatement(
          'INSERT INTO habit_schedules(habit_id,from_day,days) VALUES(?,?,?) ON CONFLICT(habit_id,from_day) DO UPDATE SET days=excluded.days',
          [habitId, today, days],
        );
      }
      return habitId;
    });
  }

  Future<void> setHabitDone(Habit habit, DateTime day, bool done) async {
    if (!habit.scheduledOn(day))
      throw ArgumentError('This habit is not scheduled for that date.');
    if (done) {
      await customStatement(
        'INSERT OR IGNORE INTO habit_logs(habit_id,day) VALUES(?,?)',
        [habit.id, dayKey(day)],
      );
    } else {
      await customStatement(
        'DELETE FROM habit_logs WHERE habit_id=? AND day=?',
        [habit.id, dayKey(day)],
      );
    }
  }

  Future<void> archiveHabit(int id, bool archive) async {
    final day = dayKey(DateTime.now());
    await transaction(() async {
      await customStatement('UPDATE habits SET archived_day=? WHERE id=?', [
        archive ? day : null,
        id,
      ]);
      await customStatement(
        'INSERT INTO habit_status(habit_id,day,active) VALUES(?,?,?) ON CONFLICT(habit_id,day) DO UPDATE SET active=excluded.active',
        [id, day, archive ? 0 : 1],
      );
    });
  }

  Future<void> deleteHabit(int id) =>
      customStatement('DELETE FROM habits WHERE id=?', [id]);

  Future<int> saveIdea({
    int? id,
    required String text,
    bool pinned = false,
  }) async {
    final now = DateTime.now().toIso8601String();
    final clean = text.trim();
    if (clean.isEmpty) throw ArgumentError('Write something first.');
    if (clean.length > 10000)
      throw ArgumentError('Idea must be 10,000 characters or fewer.');
    if (id == null)
      return customInsert(
        'INSERT INTO ideas(text,pinned,created_at,updated_at) VALUES(?,?,?,?)',
        variables: [
          Variable.withString(clean),
          Variable.withInt(pinned ? 1 : 0),
          Variable.withString(now),
          Variable.withString(now),
        ],
      );
    await customUpdate(
      'UPDATE ideas SET text=?,pinned=?,updated_at=? WHERE id=?',
      variables: [
        Variable.withString(clean),
        Variable.withInt(pinned ? 1 : 0),
        Variable.withString(now),
        Variable.withInt(id),
      ],
    );
    return id;
  }

  Future<void> deleteIdea(int id) =>
      customStatement('DELETE FROM ideas WHERE id=?', [id]);
  Future<void> clearAll() async {
    await transaction(() async {
      await customStatement('DELETE FROM habit_logs');
      await customStatement('DELETE FROM habit_schedules');
      await customStatement('DELETE FROM habit_status');
      await customStatement('DELETE FROM habits');
      await customStatement('DELETE FROM subtasks');
      await customStatement('DELETE FROM tasks');
      await customStatement('DELETE FROM subjects');
      await customStatement('DELETE FROM ideas');
    });
  }
}
