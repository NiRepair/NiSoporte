import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';

class NiTheme {
  static const background = Color(0xFF0C0F16);
  static const surface = Color(0xFF141925);
  static const surface2 = Color(0xFF1B2231);
  static const border = Color(0xFF252C3B);
  static const text = Color(0xFFEEF1F7);
  static const text2 = Color(0xFFC3C9D6);
  static const muted = Color(0xFF8D95A8);
  static const accent = Color(0xFF6F9BFF);
  static const accentStrong = Color(0xFF2F6FED);
  static const success = Color(0xFF34C48B);
  static const warning = Color(0xFFF0A13F);
  static const error = Color(0xFFF0616D);

  static const codeStyle = TextStyle(
    fontFamily: 'Cascadia Mono',
    fontFamilyFallback: ['Consolas', 'monospace'],
    fontSize: 30,
    fontWeight: FontWeight.w600,
    letterSpacing: 2,
    color: text,
  );

  // Preserve the extensions used by the existing desktop/session widgets.
  static final ThemeData darkTheme = MyTheme.darkTheme.copyWith(
    scaffoldBackgroundColor: background,
    canvasColor: background,
    cardColor: surface,
    dialogBackgroundColor: surface,
    dividerColor: border,
    colorScheme: MyTheme.darkTheme.colorScheme.copyWith(
      primary: accent,
      secondary: accent,
      surface: surface,
      background: background,
      error: error,
      onPrimary: text,
      onSurface: text,
    ),
    textTheme: MyTheme.darkTheme.textTheme.apply(
      fontFamily: 'Segoe UI',
      bodyColor: text,
      displayColor: text,
    ),
    iconTheme: const IconThemeData(color: text2),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentStrong,
        foregroundColor: text,
        elevation: 0,
        minimumSize: const Size(48, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: text2,
        minimumSize: const Size(48, 44),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: accent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: accent, width: 2),
      ),
    ),
  );
}
