import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:foodie/main.dart';

void main() {
  testWidgets('shows the login page for a signed-out user', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const FoodieApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Admin demo login'), findsOneWidget);
  });
}
