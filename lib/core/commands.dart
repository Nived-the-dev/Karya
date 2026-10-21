import 'models.dart';

class TaskInput {
  const TaskInput(this.title, this.dueAt, this.priority, this.subject);
  final String title, priority;
  final String? dueAt, subject;
}

TaskInput parseTaskInput(String raw, DateTime now) {
  var s = raw.trim();
  if (s.isEmpty)
    throw const FormatException(
      'Example: /addtask Revise calculus tomorrow #math !high',
    );
  String? date, subject;
  var priority = 'medium';
  final tagged = RegExp(r'(?<!\S)#([\w-]+)').firstMatch(s);
  if (tagged != null) {
    subject = tagged.group(1);
    s = s.replaceRange(tagged.start, tagged.end, ' ');
  }
  final prio = RegExp(
    r'(?<!\S)!(high|medium|normal|low)\b',
    caseSensitive: false,
  ).firstMatch(s);
  if (prio != null) {
    priority = prio.group(1)!.toLowerCase().replaceAll('normal', 'medium');
    s = s.replaceRange(prio.start, prio.end, ' ');
  }
  final when = RegExp(
    r'\b(next week|today|tomorrow)\b|(?<!\S)(?:@|due:)?\d{4}-\d{2}-\d{2}\b',
    caseSensitive: false,
  ).firstMatch(s);
  if (when != null) {
    final token = when.group(0)!.toLowerCase();
    final target = switch (token) {
      'today' => now,
      'tomorrow' => DateTime(now.year, now.month, now.day + 1),
      'next week' => DateTime(now.year, now.month, now.day + 7),
      _ => DateTime.tryParse(token.replaceFirst(RegExp(r'^(@|due:)'), '')),
    };
    if (target == null ||
        (RegExp(r'^(@|due:)?\d{4}-\d{2}-\d{2}$').hasMatch(token) &&
            dayKey(target) != token.replaceFirst(RegExp(r'^(@|due:)'), ''))) {
      throw const FormatException(
        'Invalid date. Use a real date in YYYY-MM-DD format.',
      );
    }
    date = dayKey(target);
    s = s.replaceRange(when.start, when.end, ' ');
  }
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (s.isEmpty || s.length > 180)
    throw const FormatException('A task needs a title of 1–180 characters.');
  return TaskInput(s, date, priority, subject);
}

class Command {
  const Command(this.name, this.arg);
  final String name, arg;
  static Command parse(String text) {
    final raw = text.trim();
    if (raw.length > 600)
      throw const FormatException(
        'Command is too long (600 characters maximum).',
      );
    if (raw.isEmpty)
      throw const FormatException('Type a command or task first.');
    if (!raw.startsWith('/')) return Command('/addtask', raw);
    final split = raw.indexOf(' ');
    return split < 0
        ? Command(raw.toLowerCase(), '')
        : Command(
            raw.substring(0, split).toLowerCase(),
            raw.substring(split + 1).trim(),
          );
  }
}

const commandsHelp = '''I’m Kārya, your command-based task buddy ✦
/addtask Revise calculus tomorrow #math !high
/viewtasks  /today  /upcoming  /overdue
/markdone 3  /undo 3  /edit 3 New title
/delete 3  /priority 3 high
/reschedule 3 tomorrow  /search physics
/addhabit Read for 20 minutes
/viewhabits  /donehabit 2  /stats  /help
Tip: Type a task directly to add it. IDs come from /viewtasks.''';
String taskLines(List<Task> items) => items.isEmpty
    ? 'Nothing here yet.'
    : items
          .take(20)
          .map(
            (t) =>
                '${t.completed ? '✓' : '○'} #${t.id} ${t.title}${t.dueDay == null ? '' : ' • ${t.dueDay}'}',
          )
          .join('\n');
