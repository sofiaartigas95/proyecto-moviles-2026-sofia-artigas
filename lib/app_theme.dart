import 'package:flutter/material.dart';

class AppTheme {
  static const Color azulPrincipal = Color(0xFF1565C0);
  static const Color rojoAcento = Color(0xFFD32F2F);
  static const Color amarilloDetalle = Color(0xFFFBC02D);
  static const Color amarilloSuave = Color(0xFFFFF8E1);
  static const Color fondoApp = Color(0xFFFFFDF5);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: fondoApp,
      colorScheme: ColorScheme.fromSeed(
        seedColor: azulPrincipal,
        primary: azulPrincipal,
        secondary: amarilloDetalle,
        error: rojoAcento,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: azulPrincipal,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: rojoAcento,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: azulPrincipal,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
