import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_sofia_artigas/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows login screen when there is no authenticated user', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
