import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_yfa/main.dart';

void main() {
  testWidgets('Smoke test for app startup', (WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(),
    );
  });
}
