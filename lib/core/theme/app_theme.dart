import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0B0F),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00E676),
        brightness: Brightness.dark,
      ),
      fontFamily: 'Roboto',
    );
  }
}