import 'package:flutter/material.dart';

class AppTheme {
  // Paleta de Colores
  static const Color _slate900 = Color(0xFF0F172A); // Fondo Principal
  static const Color _indigo = Color(0xFF6366F1); // Primario
  static const Color _red = Color(0xFFEF4444); // Gasto
  static const Color _green = Color(0xFF22C55E); // Ingreso
  static const Color _slate800 = Color(0xFF1E293B); // Tarjetas

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _slate900,

      // Configuración de Colores M3
      colorScheme: const ColorScheme.dark(
        primary: _indigo,
        onPrimary: Colors.white,
        secondary: _indigo,
        background: _slate900,
        surface: _slate800,
        error: _red,
        tertiary: _green, // Usaremos este para "Ingresos"
      ),

      // Estilo de las Tarjetas (Cards)
      cardTheme: CardThemeData(
        color: _slate800,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _indigo.withOpacity(0.1)),
        ),
      ),

      // Estilo del AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: _slate900,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      ),

      // Botón flotante
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _indigo,
        foregroundColor: Colors.white,
      ),
    );
  }
}
