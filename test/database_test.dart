import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karya_app/core/database.dart';

void main() {
  late KaryaDatabase db;
  setUp(() => db = KaryaDatabase.test(NativeDatabase.memory()));
  tearDown(() async => db.close());
  test('tasks and subjects: create, update, complete, delete', () async {
    final id = await db.saveSubject(name: 'Mathematics', color: 0, icon: 0);
    final task = await db.saveTask(
      title: 'Linear algebra',
      subjectId: id,
      priority: 'high',
    );
    var state = await db.snapshot();
    expect(state.tasks.single.title, 'Linear algebra');
    expect(state.tasks.single.subjectId, id);
    await db.setTaskDone(task, true);
    expect((await db.snapshot()).tasks.single.completed, isTrue);
    await db.setTaskDone(task, false);
    expect((await db.snapshot()).tasks.single.completed, isFalse);
    await db.deleteSubject(id);
    expect((await db.snapshot()).tasks.single.subjectId, isNull);
    await db.deleteTask(task);
    expect((await db.snapshot()).tasks, isEmpty);
  });
  test('subtasks cascade on task deletion', () async {
    final id = await db.saveTask(title: 'Project');
    await db.addSubtask(id, 'Prototype');
    expect((await db.snapshot()).tasks.single.subtasks.length, 1);
    await db.deleteTask(id);
    expect((await db.snapshot()).tasks, isEmpty);
  });
  test('habit logs are unique by habit and date', () async {
    final id = await db.saveHabit(name: 'Read', days: 127);
    final state = await db.snapshot();
    final habit = state.habits.single;
    await db.setHabitDone(habit, DateTime.now(), true);
    await db.setHabitDone(habit, DateTime.now(), true);
    expect((await db.snapshot()).habits.single.logs.length, 1);
    await db.setHabitDone(
      (await db.snapshot()).habits.single,
      DateTime.now(),
      false,
    );
    expect((await db.snapshot()).habits.single.logs, isEmpty);
    await db.deleteHabit(id);
    expect((await db.snapshot()).habits, isEmpty);
  });
  test('ideas autosave, pins, editing and deletion', () async {
    final id = await db.saveIdea(text: 'Initial thought');
    expect((await db.snapshot()).notes.single.text, 'Initial thought');
    await db.saveIdea(id: id, text: 'Updated thought', pinned: true);
    final idea = (await db.snapshot()).notes.single;
    expect(idea.id, id);
    expect(idea.pinned, isTrue);
    expect(idea.text, 'Updated thought');
    await db.deleteIdea(id);
    expect((await db.snapshot()).notes, isEmpty);
  });
  test('clear all removes each collection', () async {
    await db.saveTask(title: 'One');
    await db.saveHabit(name: 'Two', days: 127);
    await db.saveIdea(text: 'Remember to make tea');
    await db.clearAll();
    final state = await db.snapshot();
    expect(state.tasks, isEmpty);
    expect(state.habits, isEmpty);
    expect(state.subjects, isEmpty);
    expect(state.notes, isEmpty);
  });
}
