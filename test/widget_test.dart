import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/features/auth/data/mock_auth_repository.dart';
import 'package:smart_campus_portal/features/auth/presentation/auth_controller.dart';
import 'package:smart_campus_portal/main.dart';

// Replaces Flutter's default counter test, which no longer applies.
void main() {
  testWidgets('app starts on the login screen', (tester) async {
    final auth = AuthController(MockAuthRepository())..bootstrap();

    await tester.pumpWidget(SmartCampusApp(auth: auth));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Hill City University'), findsOneWidget);
    expect(find.text('Sign in to your campus portal'), findsOneWidget);
  });
}
