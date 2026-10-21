import 'package:flutter/material.dart';

import '../data/models/models.dart';

class AppColors {
  static const ink = Color(0xFF243B5A);
  static const accent = Color(0xFFD9763D);
  static const accentSoft = Color(0xFFF3D2BE);
  static const canvas = Color(0xFFF6F4F1);
  static const chatBg = Color(0xFFDDE2EA);
  static const outgoing = Color(0xFF243B5A);
  static const incoming = Color(0xFFFFFFFF);
  static const unread = Color(0xFFD9763D);

  static const green = ink;
  static const teal = accent;
  static const lightGreen = accent;
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.ink,
    onPrimary: Colors.white,
    secondary: AppColors.accent,
    onSecondary: Colors.white,
    surface: AppColors.canvas,
    onSurface: Color(0xFF1C2433),
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.canvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.ink,
      foregroundColor: Colors.white,
      shape: StadiumBorder(),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.ink,
      unselectedLabelColor: Color(0xFF7A8494),
      indicatorColor: AppColors.accent,
      dividerColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4E0DA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4E0DA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    dividerColor: const Color(0xFFE7E2DB),
  );
}

String formatChatTime(DateTime? time) {
  if (time == null) return '';
  final now = DateTime.now();
  final local = time.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final timeLabel =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  if (day == today) return timeLabel;
  if (today.difference(day).inDays == 1) return 'أمس';
  return '${local.day}/${local.month}';
}

String initialsFor(String name) {
  final parts = SafeText.display(name)
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  String first(String value) {
    if (value.isEmpty) return '?';
    return String.fromCharCodes(value.runes.take(1)).toUpperCase();
  }
  if (parts.length == 1) return first(parts.first);
  return first(parts.first) + first(parts.last);
}

Color hexColor(String? value, {Color fallback = AppColors.ink}) {
  final hex = (value ?? '').replaceAll('#', '').trim();
  if (hex.length != 6 && hex.length != 8) return fallback;
  final parsed = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
  return parsed == null ? fallback : Color(parsed);
}
