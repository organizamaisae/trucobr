import 'package:flutter/material.dart';

const navy = Color(0xFF001438);
const blue = Color(0xFF064DB7);
const gold = Color(0xFFF6BD41);
const cream = Color(0xFFFFF1AC);
const green = Color(0xFF00C63C);
const muted = Color(0xFFAAC6FF);
TextStyle royalText(double size, {Color color = Colors.white}) => TextStyle(
  fontFamily: 'RoyalSerif',
  fontFamilyFallback: const ['Georgia', 'serif'],
  fontSize: size,
  fontWeight: FontWeight.bold,
  color: color,
  height: 1.08,
  shadows: const [
    Shadow(color: Colors.black54, offset: Offset(0, 3), blurRadius: 3),
  ],
);
ThemeData royalTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: navy,
  colorScheme: const ColorScheme.dark(
    primary: gold,
    secondary: green,
    surface: navy,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.all(Colors.white),
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected) ? green : navy,
    ),
    trackOutlineColor: WidgetStateProperty.all(gold),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF05245F),
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: const BorderSide(color: gold, width: 3),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: const BorderSide(color: cream, width: 4),
    ),
    hintStyle: const TextStyle(color: muted, fontSize: 25),
  ),
);
