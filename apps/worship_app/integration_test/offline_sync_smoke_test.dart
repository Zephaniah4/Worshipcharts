import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:worship_app/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app starts and basic navigation is available', (WidgetTester tester) async {
    await tester.pumpWidget(const WorshipApp());
    await tester.pumpAndSettle();

    expect(find.text('Songs'), findsWidgets);

    // Navigate to Setlists tab.
    await tester.tap(find.text('Setlists').first);
    await tester.pumpAndSettle();

    expect(find.text('Setlists'), findsWidgets);

    // Navigate to Integrations tab.
    await tester.tap(find.text('Integrations').first);
    await tester.pumpAndSettle();

    expect(find.text('Integrations'), findsWidgets);
  });
}
