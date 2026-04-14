import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const Color brandYellow = Color(0xFFFFDE42);
  static const Color olive = Color(0xFF4C5C2D);
  static const Color oliveDark = Color(0xFF313E17);
  static const Color deepWine = Color(0xFF1B0C0C);
  static const Color spaceBlack = Color(0xFF07070C);
  static const Color panel = Color(0xFF111119);
  static const Color panelSoft = Color(0xFF15151F);
  static const Color border = Color(0xFF25252F);
  static const Color textPrimary = Color(0xFFF5F4EA);
  static const Color textMuted = Color(0xFFAAA7A0);
  static const Color textSoft = Color(0xFF7B776E);
  static const Color success = Color(0xFF55EFC4);
  static const Color danger = Color(0xFFFF8A7A);
  static const Color info = Color(0xFF4FACFE);

  // Risk severity colors
  static const Color riskCritical = Color(0xFFFF1744);
  static const Color riskHigh = Color(0xFFFF9100);
  static const Color riskMedium = Color(0xFFFFEA00);
  static const Color riskLow = Color(0xFF2979FF);
  static const Color riskInfo = Color(0xFF69F0AE);

  // New component type colors
  static const Color apiGatewayColor = Color(0xFFE040FB);
  static const Color cronJobColor = Color(0xFF7C4DFF);
  static const Color thirdPartyColor = Color(0xFF00E5FF);
  static const Color serviceMeshColor = Color(0xFF76FF03);

  // Topology type badges
  static const Color liveBadgeColor = Color(0xFF00E676);
  static const Color experimentalBadgeColor = Color(0xFFFF9100);
}

class AppTheme {
  AppTheme._();

  static const double headlineScale = 0.85;

  static TextStyle syne({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.syne(
      color: color,
      fontSize: fontSize == null ? null : fontSize * headlineScale,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.spaceBlack,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brandYellow,
        secondary: AppColors.olive,
        surface: AppColors.panel,
        error: AppColors.danger,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.spaceBlack.withValues(alpha: 0.82),
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleTextStyle: syne(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.panel,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.panelSoft,
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.panelSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.brandYellow),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandYellow,
          foregroundColor: AppColors.deepWine,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: syne(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  static BoxDecoration glassCard({Color? color}) {
    return BoxDecoration(
      color: (color ?? AppColors.panel).withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 28,
          offset: Offset(0, 16),
        ),
      ],
    );
  }

  static LinearGradient accentGlow() {
    return const LinearGradient(
      colors: [AppColors.brandYellow, AppColors.olive],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
