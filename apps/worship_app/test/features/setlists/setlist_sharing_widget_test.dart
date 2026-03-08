import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:worship_app/core/app_state.dart';
import 'package:worship_app/features/setlists/setlists_screen.dart';

void main() {
  testWidgets('manage sharing add and remove collaborator', (WidgetTester tester) async {
    final AppState state = await AppState.createForTest();
    await state.createSetlist(name: 'Sunday Morning', teamId: 'team-1');

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(home: SetlistsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manage Sharing').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Collaborator email or ID'),
      'musician@example.com',
    );
    await tester.tap(find.text('Add / Update Collaborator'));
    await tester.pumpAndSettle();

    expect(find.text('musician@example.com'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove collaborator').first);
    await tester.pumpAndSettle();

    expect(find.text('musician@example.com'), findsNothing);
  });
}
