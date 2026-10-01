import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Centralized Material 3 theme definitions. Views never build their own
/// ThemeData or inline colors that duplicate brand tokens defined here.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryNavy,
      brightness: Brightness.light,
      // Gold is the app's primary accent: every Material control that
      // defaults to `primary` (switches, checkboxes, sliders, spinners,
      // text buttons, focus rings) picks it up.
      primary: AppColors.gold,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      // Tonal buttons (IconButton.filledTonal): a soft gold wash.
      secondaryContainer: AppColors.gold.withValues(alpha: 0.15),
      onSecondaryContainer: AppColors.gold,
      error: AppColors.error,
      surface: AppColors.surfaceLight,
    );

    return _withGoldControls(
      ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: scheme,
        scaffoldBackgroundColor: AppColors.scaffoldLight,
        textTheme: AppTextStyles.lightTextTheme,
        dividerColor: AppColors.divider,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.textPrimaryLight,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceLight,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceLight,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            // A quiet step darker than the resting border rather than a
            // coloured ring — the gold outline read as harsh on focus.
            borderSide: const BorderSide(color: Color(0xFFC5C8D2)),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceLight,
          selectedItemColor: AppColors.primaryNavy,
          unselectedItemColor: AppColors.textSecondaryLight,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
        ),
        tabBarTheme: const TabBarTheme(
          labelColor: AppColors.textPrimaryLight,
          unselectedLabelColor: AppColors.textSecondaryLight,
          indicatorColor: AppColors.gold,
          dividerColor: Colors.transparent,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipBackground: AppColors.scaffoldLight,
      chipLabel: AppColors.textPrimaryLight,
      chipBorder: AppColors.divider,
    );
  }

  static ThemeData get dark {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryNavy,
      brightness: Brightness.dark,
      primary: AppColors.gold,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      secondaryContainer: AppColors.gold.withValues(alpha: 0.2),
      onSecondaryContainer: AppColors.goldLight,
      error: AppColors.error,
      surface: AppColors.surfaceDark,
    );

    return _withGoldControls(
      ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: scheme,
        scaffoldBackgroundColor: AppColors.scaffoldDark,
        textTheme: AppTextStyles.darkTextTheme,
        dividerColor: AppColors.dividerDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.textPrimaryDark,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceDark,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceDark,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.dividerDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.dividerDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3A3E4C)),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceDark,
          selectedItemColor: AppColors.goldLight,
          unselectedItemColor: AppColors.textSecondaryDark,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
        ),
        tabBarTheme: const TabBarTheme(
          labelColor: AppColors.textPrimaryDark,
          unselectedLabelColor: AppColors.textSecondaryDark,
          indicatorColor: AppColors.goldLight,
          dividerColor: Colors.transparent,
        ),
      ),
      chipBackground: AppColors.surfaceDark,
      chipLabel: AppColors.textPrimaryDark,
      chipBorder: AppColors.dividerDark,
    );
  }

  /// Gold-and-white styling for the common controls, shared by both
  /// themes: filled/elevated buttons are gold with white text, outlined
  /// and text buttons are gold on white, and selected chips, segmented
  /// buttons, sliders, switches and checkboxes are gold.
  static ThemeData _withGoldControls(
    ThemeData base, {
    required Color chipBackground,
    required Color chipLabel,
    required Color chipBorder,
  }) {
    final RoundedRectangleBorder pill =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(28));
    const EdgeInsets buttonPadding =
        EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    const TextStyle buttonText = TextStyle(fontWeight: FontWeight.w500);
    return base.copyWith(
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white70,
          padding: buttonPadding,
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.white,
          padding: buttonPadding,
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.gold, width: 1.5),
          padding: buttonPadding,
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.gold),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (Set<WidgetState> states) => states.contains(WidgetState.selected)
                ? AppColors.gold
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (Set<WidgetState> states) => states.contains(WidgetState.selected)
                ? Colors.white
                : chipLabel,
          ),
          side:
              WidgetStatePropertyAll<BorderSide>(BorderSide(color: chipBorder)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBackground,
        selectedColor: AppColors.gold,
        labelStyle: TextStyle(fontSize: 11, color: chipLabel),
        secondaryLabelStyle: const TextStyle(
            fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
        showCheckmark: false,
        side: BorderSide(color: chipBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.gold,
        inactiveTrackColor: AppColors.gold.withValues(alpha: 0.2),
        thumbColor: AppColors.gold,
        overlayColor: AppColors.gold.withValues(alpha: 0.12),
        activeTickMarkColor: Colors.transparent,
        inactiveTickMarkColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected) ? AppColors.gold : null,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected) ? AppColors.gold : null,
        ),
        checkColor: const WidgetStatePropertyAll<Color>(Colors.white),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.gold),
    );
  }
}
