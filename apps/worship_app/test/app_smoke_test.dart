import 'package:flutter_test/flutter_test.dart';
import 'package:worship_app/app.dart';

void main() {
  testWidgets('app boots and shows loader/home shell', (WidgetTester tester) async {
    await tester.pumpWidget(const WorshipApp());
    await tester.pump();

    // App should at least render without throwing on startup.
    expect(find.byType(WorshipApp), findsOneWidget);
  });
}
