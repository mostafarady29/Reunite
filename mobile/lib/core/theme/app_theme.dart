// Barrel: keeps `import 'app_theme.dart'` working across the app.
export 'app_palette.dart';
export 'theme_color_scheme.dart';
export 'theme_components.dart';
export 'theme_extras.dart';

import 'package:flutter/material.dart';
import 'app_palette.dart';
import 'app_typography.dart';
import 'theme_color_scheme.dart';
import 'theme_components.dart';
import 'theme_extras.dart';

/// App themes (light/dark). Palette + scheme + components composed here.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final AppPalette palette = isDark ? AppPalette.dark : AppPalette.light;
    final ColorScheme scheme = buildAppColorScheme(brightness, palette);
    final TextTheme textTheme = AppTypography.textTheme().apply(
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      textTheme: textTheme,
      fontFamily: AppTypography.fontFamily,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final p in TargetPlatform.values)
            p: const CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: buildAppBarTheme(textTheme, palette),
      inputDecorationTheme: buildInputTheme(textTheme, palette, isDark),
      switchTheme: buildSwitchTheme(palette),
      filledButtonTheme: buildFilledButtonTheme(scheme, textTheme),
      outlinedButtonTheme:
          buildOutlinedButtonTheme(scheme, textTheme, palette),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: buildChipTheme(textTheme, palette, isDark),
      snackBarTheme: buildSnackBarTheme(textTheme, isDark),
      bottomSheetTheme: buildBottomSheetTheme(palette),
      progressIndicatorTheme: buildProgressTheme(palette),
      dividerTheme: DividerThemeData(color: palette.border, thickness: 1),
      textSelectionTheme: buildSelectionTheme(),
      extensions: [palette],
    );
  }
}
