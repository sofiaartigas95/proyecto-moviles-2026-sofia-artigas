import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_sofia_artigas/main.dart';

void main() {
  // Asegura que los bindings de Flutter estén inicializados
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows login screen when there is no authenticated user', (
    WidgetTester tester,
  ) async {
    // Construye la aplicación directamente
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verifica que aparezcan los textos clave de la pantalla de inicio de sesión
    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
