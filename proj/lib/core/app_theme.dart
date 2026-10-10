import 'package:flutter/material.dart';

/// Color themes. 'forest' is free; others unlock by watching a rewarded ad.
class AppTheme {
  static const Map<String, Map<String, Object>> themes = {
    'forest': {'name': 'Forest', 'seed': 0xFF2E7D32, 'locked': false},
    'sunset': {'name': 'Sunset', 'seed': 0xFFD84315, 'locked': true},
    'ocean': {'name': 'Ocean', 'seed': 0xFF1565C0, 'locked': true},
  };

  static ThemeData themeFor(String id) {
    final seed = Color((themes[id]?['seed'] as int?) ?? 0xFF2E7D32);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
