import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_yfa/main.dart';
import 'package:flutter_app_yfa/services/notification_service.dart';

void main() {
  testWidgets('Smoke test for app startup', (WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(notificationService: NotificationService()),
    );
  });
}
