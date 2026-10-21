import 'package:flutter/material.dart';

/// All persisted dates in the database are ISO-8601 *local calendar dates*.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime? readDay(String? text) =>
    text == null ? null : DateTime.tryParse(text);
int weekdayFlag(int isoDay) => 1 << (isoDay - 1);

const palette = [
  Color(0xFFFFD51D),
  Color(0xFFFF4C89),
  Color(0xFFA6E529),
  Color(0xFF9573F5),
  Color(0xFF70DDE3),
];
const icons = <IconData>[
  Icons.menu_book_rounded,
  Icons.code_rounded,
  Icons.science_rounded,
  Icons.palette_rounded,
  Icons.self_improvement,
  Icons.star_rounded,
  Icons.bolt_rounded,
  Icons.local_florist_rounded,
];
Color colorFor(int index) => palette[index % palette.length];
IconData iconFor(int index) => icons[index % icons.length];

class Subject {
  const Subject(this.id, this.name, this.color, this.icon);
  final int id, color, icon;
  final String name;
}

class Task {
  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.subjectId,
    this.priority = 'medium',
    this.dueAt,
    this.reminderAt,
    this.completedAt,
    required this.createdAt,
    this.subtasks = const [],
  });
  final int id;
  final String title, description, priority, createdAt;
  final int? subjectId;
  final String? dueAt, reminderAt, completedAt;
  final List<Subtask> subtasks;
  bool get completed => completedAt != null;
  String? get dueDay => dueAt == null ? null : dueAt!.substring(0, 10);
  bool get overdue =>
      !completed &&
      dueDay != null &&
      dueDay!.compareTo(dayKey(DateTime.now())) < 0;
}

class Subtask {
  const Subtask(this.id, this.taskId, this.title, this.done);
  final int id, taskId;
  final String title;
  final bool done;
}

class ScheduleRevision {
  const ScheduleRevision(this.from, this.days);
  final String from;
  final int days;
}

class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.createdDay,
    this.description = '',
    this.color = 0,
    this.icon = 0,
    this.reminder,
    this.archivedDay,
    this.revisions = const [],
    this.logs = const <String>{},
    this.statusChanges = const <String, bool>{},
  });
  final int id, color, icon;
  final String name, description, createdDay;
  final String? reminder, archivedDay;
  final List<ScheduleRevision> revisions;
  final Set<String> logs;
  final Map<String, bool> statusChanges;
  bool scheduledOn(DateTime date) {
    final day = dayKey(date);
    if (day.compareTo(createdDay) < 0) return false;
    var active = true;
    for (final key in (statusChanges.keys.toList()..sort())) {
      if (key.compareTo(day) <= 0) active = statusChanges[key]!;
    }
    if (!active) return false;
    ScheduleRevision? match;
    for (final revision in revisions) {
      if (revision.from.compareTo(day) <= 0) match = revision;
    }
    return match != null && (match.days & weekdayFlag(date.weekday)) != 0;
  }

  bool doneOn(DateTime date) => logs.contains(dayKey(date));
  bool get archived => archivedDay != null;
}

class IdeaNote {
  const IdeaNote({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.pinned = false,
  });
  final int id;
  final String text, createdAt, updatedAt;
  final bool pinned;
}

class AppData {
  const AppData(
    this.tasks,
    this.subjects,
    this.habits, [
    this.notes = const [],
  ]);
  final List<Task> tasks;
  final List<Subject> subjects;
  final List<Habit> habits;
  final List<IdeaNote> notes;
  int get pending => tasks.where((t) => !t.completed).length;
  int get completed => tasks.where((t) => t.completed).length;
  int get overdue => tasks.where((t) => t.overdue).length;
  int get dueToday => tasks
      .where((t) => !t.completed && t.dueDay == dayKey(DateTime.now()))
      .length;
}

class DayStats {
  const DayStats(this.completed, this.scheduled);
  final int completed, scheduled;
  double? get rate => scheduled == 0 ? null : completed / scheduled;
}

DayStats statsFor(List<Habit> habits, DateTime day) {
  final applicable = habits.where((h) => h.scheduledOn(day)).toList();
  return DayStats(
    applicable.where((h) => h.doneOn(day)).length,
    applicable.length,
  );
}
