import 'package:flutter/material.dart';

const _tohum = Color(0xFF0B5CAD);

ThemeData tema(Brightness parlaklik) {
  final renkler = ColorScheme.fromSeed(seedColor: _tohum, brightness: parlaklik);
  return ThemeData(
    colorScheme: renkler,
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    cardTheme: const CardThemeData(margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6)),
  );
}
