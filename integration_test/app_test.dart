import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:karya_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('app launches with home title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KaryaApp()));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('KĀRYA ✦'), findsOneWidget);
  });
}
