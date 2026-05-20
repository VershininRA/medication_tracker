import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 Основная палитра
  static const Color primaryColor = Color(0xFFE8A4B8); // Нежно-розовый
  static const Color secondaryColor = Color(0xFFF4B4C9); // Светло-розовый
  static const Color tertiaryColor = Color(0xFF9C27B0); // Фиолетовый акцент
  static const Color backgroundColor = Color(0xFFF9F9FC); // Светлый фон
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFEF5350);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  
  // Текст
  static const Color textPrimary = Color(0xFF2D2428);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFFBDBDBD);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true, // Важно для современных виджетов
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      
      // Шрифты
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary, height: 1.4),
        bodySmall: TextStyle(fontSize: 12, color: textTertiary, height: 1.3),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
      ),

      // 🔹 Улучшенный CardTheme
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
      ),

      // Поля ввода
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIconColor: MaterialStateColor.resolveWith((states) =>
            states.contains(MaterialState.focused) ? primaryColor : textSecondary),
      ),

      // Кнопки - улучшенные
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      
      // AppBar - улучшенный
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        scrolledUnderElevation: 4,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        highlightElevation: 12,
        hoverElevation: 10,
        splashColor: Colors.white.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textTertiary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // Чипсы
      chipTheme: ChipThemeData(
        backgroundColor: secondaryColor.withOpacity(0.2),
        selectedColor: primaryColor,
        labelStyle: const TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}