import 'package:flutter/material.dart';

/// Shared design tokens so every screen in the app looks like part of the
/// same product: one indigo identity, one currency format, one card style.
class AppTheme {
  AppTheme._();

  // Core palette
  static const Color deepIndigo = Color(0xFF283593);
  static const Color primaryIndigo = Color(0xFF3F51B5);
  static const Color lightIndigo = Color(0xFF7986CB);
  static const Color backgroundGrey = Color(0xFFF5F6FA);
  static const Color textDark = Color(0xFF1E1E2C);
  static const Color textGrey = Color(0xFF6B7280);

  // Semantic accents (kept in the same cool family so the app still reads
  // as "indigo", while still letting income vs. expense be told apart)
  static const Color income = Color(0xFF00897B); // teal-green
  static const Color expense = Color(0xFFE53935); // red
  static const Color neutral = Color(0xFF5E35B1); // deep violet-indigo
  static const Color warning = Color(0xFFF39C12); // amber

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepIndigo, primaryIndigo],
  );

  static const double maxContentWidth = 900;

  /// South African Rand currency formatting, consistent everywhere.
  static String currency(double amount) {
    final sign = amount < 0 ? '-' : '';
    return '${sign}R ${amount.abs().toStringAsFixed(2)}';
  }

  static AppBar appBar(String title, {List<Widget>? actions}) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      centerTitle: false,
      backgroundColor: deepIndigo,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: actions,
    );
  }

  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
    color: color ?? Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Wraps page content so it stays readable and centered on wide/laptop
  /// screens, while filling the width naturally on phones.
  static Widget responsive(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxContentWidth),
        child: child,
      ),
    );
  }
}