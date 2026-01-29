import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lpgTheme() {
  return ThemeData(
    // LPG Industry Colors - Blue and Orange theme
    primaryColor: Color(0xFF1565C0), // Deep Blue
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color(0xFF1565C0),
      secondary: Color(0xFFFF6F00), // Deep Orange
      tertiary: Color(0xFF2E7D32), // Green for safety
    ),
    scaffoldBackgroundColor: Color(0xFFF8F9FA), // Light gray background
    
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1565C0),
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white),
      elevation: 2,
    ),
    
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.roboto(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A1A),
      ),
      headlineMedium: GoogleFonts.roboto(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A1A),
      ),
      headlineSmall: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
      titleLarge: GoogleFonts.roboto(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
      titleMedium: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1A1A1A),
      ),
      bodyLarge: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: Color(0xFF424242),
      ),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: Color(0xFF424242),
      ),
      bodySmall: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: Color(0xFF757575),
      ),
      labelLarge: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Color(0xFF1565C0),
        side: BorderSide(color: Color(0xFF1565C0), width: 1.5),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Color(0xFF1565C0),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    cardTheme: CardTheme(
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.1),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFFD32F2F), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFFD32F2F), width: 2),
      ),
      labelStyle: GoogleFonts.roboto(
        color: Color(0xFF757575),
        fontSize: 16,
      ),
      hintStyle: GoogleFonts.roboto(
        color: Color(0xFF9E9E9E),
        fontSize: 16,
      ),
      errorStyle: GoogleFonts.roboto(
        color: Color(0xFFD32F2F),
        fontSize: 12,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    
    chipTheme: ChipThemeData(
      backgroundColor: Color(0xFFE3F2FD),
      labelStyle: GoogleFonts.roboto(
        color: Color(0xFF1565C0),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Color(0xFF1A1A1A),
      contentTextStyle: GoogleFonts.roboto(
        color: Colors.white,
        fontSize: 14,
      ),
      actionTextColor: Color(0xFFFF6F00),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF1565C0),
      unselectedItemColor: Color(0xFF9E9E9E),
      selectedLabelStyle: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFFF6F00),
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    dialogTheme: DialogTheme(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A1A),
      ),
      contentTextStyle: GoogleFonts.roboto(
        fontSize: 16,
        color: Color(0xFF424242),
      ),
    ),
    
    dividerTheme: DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
      space: 1,
    ),
    
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return Color(0xFF1565C0);
        }
        return Color(0xFFBDBDBD);
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return Color(0xFF1565C0).withOpacity(0.5);
        }
        return Color(0xFFBDBDBD).withOpacity(0.5);
      }),
    ),
    
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return Color(0xFF1565C0);
        }
        return Colors.transparent;
      }),
      checkColor: MaterialStateProperty.all(Colors.white),
      side: BorderSide(color: Color(0xFF9E9E9E), width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return Color(0xFF1565C0);
        }
        return Color(0xFF9E9E9E);
      }),
    ),
  );
}

// LPG-specific color constants
class LPGColors {
  static const Color primary = Color(0xFF1565C0);
  static const Color secondary = Color(0xFFFF6F00);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF0288D1);
  
  // Cylinder status colors
  static const Color cylinderEmpty = Color(0xFFE0E0E0);
  static const Color cylinderFilled = Color(0xFF4CAF50);
  static const Color cylinderSold = Color(0xFF2196F3);
  static const Color cylinderExchange = Color(0xFFFF9800);
  
  // Background colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF424242);
  static const Color textTertiary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFF9E9E9E);
  
  // Border colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderFocus = Color(0xFF1565C0);
  static const Color borderError = Color(0xFFD32F2F);
}

// LPG-specific text styles
class LPGTextStyles {
  static TextStyle get heading1 => GoogleFonts.roboto(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: LPGColors.textPrimary,
  );
  
  static TextStyle get heading2 => GoogleFonts.roboto(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: LPGColors.textPrimary,
  );
  
  static TextStyle get heading3 => GoogleFonts.roboto(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: LPGColors.textPrimary,
  );
  
  static TextStyle get subtitle1 => GoogleFonts.roboto(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: LPGColors.textPrimary,
  );
  
  static TextStyle get subtitle2 => GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: LPGColors.textSecondary,
  );
  
  static TextStyle get body1 => GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: LPGColors.textSecondary,
  );
  
  static TextStyle get body2 => GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: LPGColors.textSecondary,
  );
  
  static TextStyle get caption => GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: LPGColors.textTertiary,
  );
  
  static TextStyle get button => GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
}