import 'package:aurora_finance/core/auth/session_store.dart';
import 'package:aurora_finance/features/auth/registration_screen.dart';
import 'package:aurora_finance/main.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('without a saved session the app opens on phone sign-in', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await SessionStore.instance.clear();

    await tester.pumpWidget(const AuroraFinanceApp());
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(RegistrationScreen), findsOneWidget);
    expect(find.text('+998'), findsOneWidget);
  });
}
