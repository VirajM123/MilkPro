// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:milk_distribution_app/main.dart';
import 'package:milk_distribution_app/screens/auth/login_screen.dart';

void main() {
  testWidgets('app opens the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MilkDistributionApp());
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
