import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karya_app/features/neo.dart';
import 'package:karya_app/features/tasks.dart';
import 'package:karya_app/core/database.dart';
import 'package:karya_app/core/state.dart';
import 'package:drift/native.dart';

void main() {
  testWidgets('neo-brutalist task button responds to a tap', (tester) async {
    var presses = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeoButton(label: 'Add task', onPressed: () => presses++),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Add task'));
    expect(presses, 1);
  });
  testWidgets('task board renders and filters without dropdown assertion', (
    tester,
  ) async {
    final db = KaryaDatabase.test(NativeDatabase.memory());
    final math = await db.saveSubject(name: 'Maths', color: 0, icon: 0);
    await db.saveSubject(name: 'Science', color: 1, icon: 1);
    await db.saveTask(title: 'Review integrals', subjectId: math);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: const MaterialApp(home: Scaffold(body: TasksScreen())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('TASK BOARD'), findsOneWidget);
    expect(find.text('Review integrals'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
  testWidgets('empty state provides clear guidance', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: EmptyState('Nothing here', 'Create your first habit'),
          ),
        ),
      ),
    );
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Create your first habit'), findsOneWidget);
  });
}
