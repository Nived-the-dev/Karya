import 'package:karya_app/core/brain_dump.dart';
import 'package:karya_app/core/appearance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karya_app/core/models.dart';
import 'package:karya_app/core/commands.dart';

void main() {
  test('all five dark themes have true black backgrounds', () {
    for (var i = 0; i < 5; i++) {
      expect(paletteFor(i, true).canvas.value, 0xFF000000);
    }
  });
  test('offline Brain Dump proposes tasks without creating data', () {
    final tasks = suggestTasks(
      'Read a chapter tomorrow #reading !high\nBuy milk\nCall mum',
      DateTime(2026, 10, 21),
    );
    expect(tasks.length, 3);
    expect(tasks.first.title, 'Read a chapter');
    expect(tasks.first.dueAt, '2026-10-22');
    expect(tasks.last.title, 'Call mum');
  });

  test('date keys have stable, zero-padded local calendar representation', () {
    expect(dayKey(DateTime(2026, 1, 4)), '2026-01-04');
  });
  test('free-form task syntax from original Kārya is supported', () {
    final p = parseTaskInput(
      'Read 20 pages tomorrow #reading !high',
      DateTime(2026, 10, 21),
    );
    expect(p.title, 'Read 20 pages');
    expect(p.dueAt, '2026-10-22');
    expect(p.priority, 'high');
    expect(p.subject, 'reading');
  });
  test('chat commands are case insensitive', () {
    final cmd = Command.parse('/MARKDONE 14');
    expect(cmd.name, '/markdone');
    expect(cmd.arg, '14');
  });
  test('missing task title gives a useful error', () {
    expect(() => parseTaskInput(' ', DateTime.now()), throwsFormatException);
  });
  test('weekly schedules use Monday-first bitmask', () {
    final h = Habit(
      id: 1,
      name: 'Science',
      createdDay: '2026-10-01',
      revisions: [const ScheduleRevision('2026-10-01', 1 << 0)],
      logs: {'2026-10-19'},
    );
    expect(h.scheduledOn(DateTime(2026, 10, 19)), isTrue);
    expect(h.scheduledOn(DateTime(2026, 10, 20)), isFalse);
    expect(h.doneOn(DateTime(2026, 10, 19)), isTrue);
  });
  test('history respects schedule revisions, creation, archiving', () {
    final h = Habit(
      id: 2,
      name: 'Writing',
      createdDay: '2026-10-05',
      revisions: [
        const ScheduleRevision('2026-10-05', 127),
        const ScheduleRevision('2026-10-09', 1),
      ],
      statusChanges: {'2026-10-12': false, '2026-10-16': true},
    );
    expect(h.scheduledOn(DateTime(2026, 10, 4)), isFalse);
    expect(h.scheduledOn(DateTime(2026, 10, 8)), isTrue);
    expect(h.scheduledOn(DateTime(2026, 10, 9)), isFalse);
    expect(h.scheduledOn(DateTime(2026, 10, 12)), isFalse);
    expect(h.scheduledOn(DateTime(2026, 10, 19)), isTrue);
  });
  test('non-scheduled days have null progress, never zero-percent', () {
    expect(statsFor([], DateTime(2026, 10, 21)).rate, isNull);
  });
  test('duplicate day check-in is represented by a set', () {
    final logs = <String>{'2026-10-21'};
    logs.add('2026-10-21');
    expect(logs.length, 1);
  });
  test(
    'impossible calendar dates are rejected instead of silently normalized',
    () {
      expect(
        () => parseTaskInput('Study 2026-02-30', DateTime(2026, 1, 2)),
        throwsFormatException,
      );
      expect(
        parseTaskInput('Study due:2028-02-29', DateTime(2026, 1, 2)).dueAt,
        '2028-02-29',
      );
    },
  );
  test(
    'out-of-order archive status still preserves correct earlier history',
    () {
      final h = Habit(
        id: 8,
        name: 'Practice',
        createdDay: '2026-10-01',
        revisions: const [ScheduleRevision('2026-10-01', 127)],
        statusChanges: {'2026-10-20': true, '2026-10-14': false},
      );
      expect(h.scheduledOn(DateTime(2026, 10, 12)), isTrue);
      expect(h.scheduledOn(DateTime(2026, 10, 16)), isFalse);
      expect(h.scheduledOn(DateTime(2026, 10, 21)), isTrue);
    },
  );
}
