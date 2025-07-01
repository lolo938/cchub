import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color secondary = Color(0xFFFF5722);
  static const Color secondaryDark = Color(0xFFE64A19);
  
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFF57C00);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF1A1A1A);
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFE0E0E0);
  
  // Consultation specific colors
  static const Color instantConsultation = Color(0xFFFF5722);
  static const Color scheduledConsultation = Color(0xFF2196F3);
  static const Color emergencyConsultation = Color(0xFFF44336);
  static const Color consultation = Color(0xFF2196F3);
  
  // Status colors
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9E9E9E);
  static const Color busy = Color(0xFFFF9800);
  
  // Wallet colors
  static const Color credit = Color(0xFF4CAF50);
  static const Color debit = Color(0xFFF44336);
  static const Color pending = Color(0xFFFF9800);
  static const Color walletPrimary = Color(0xFF4CAF50);
  static const Color walletSecondary = Color(0xFF66BB6A);
  
  // Doctor status colors
  static const Color available = Color(0xFF4CAF50);
  static const Color unavailable = Color(0xFF9E9E9E);
  static const Color inConsultation = Color(0xFFFF9800);
  
  // Gradient colors
  static const List<Color> primaryGradient = [
    Color(0xFF2196F3),
    Color(0xFF1976D2),
  ];
  
  static const List<Color> secondaryGradient = [
    Color(0xFFFF5722),
    Color(0xFFE64A19),
  ];
  
  static const List<Color> successGradient = [
    Color(0xFF4CAF50),
    Color(0xFF388E3C),
  ];
  
  static const List<Color> warningGradient = [
    Color(0xFFF57C00),
    Color(0xFFEF6C00),
  ];
}