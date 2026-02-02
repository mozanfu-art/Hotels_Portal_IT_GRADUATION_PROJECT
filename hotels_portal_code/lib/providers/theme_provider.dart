import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData get currentTheme => _theme;

  static final ThemeData _theme = ThemeData(
    primaryColor: Color(0xFF004D40),
    scaffoldBackgroundColor: Color(0x0ffffbf0),
    canvasColor: Color(0x0ffffbf0),
    colorScheme: ColorScheme.light(
      primary: Color(0xFF004D40),
      onPrimary: Color(0xFFFFFFFF),
      surface: Colors.white,
      onSurface: Colors.grey[600]!,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF004D40),
      foregroundColor: Color(0xFFFFFFFF),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF004D40),
        foregroundColor: Color(0xFFFFFFFF),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Color(0xFF004D40),
        side: BorderSide(color: Color(0xFF004D40)),
      ),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
