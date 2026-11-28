import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color ink;
  final Color grey;
  final Color border;
  final Color accent;
  final Color green;
  final Color danger;

  const AppColors({
    required this.ink,
    required this.grey,
    required this.border,
    required this.accent,
    required this.green,
    required this.danger,
  });

  static const light = AppColors(
    ink: Color(0xFF101828),
    grey: Color(0xFF667085),
    border: Color(0xFFE4E7EC),
    accent: Color(0xFF3B62FF),
    green: Color(0xFF16A34A),
    danger: Color(0xFFD92D20),
  );

  static const dark = AppColors(
    ink: Color(0xFFFFFFFF),
    grey: Color(0xFF7F8289),
    border: Color(0xFF282C36),
    accent: Color(0xFF557AE1),
    green: Color(0xFF7DFF95),
    danger: Color(0xFFFF8080),
  );

  @override
  AppColors copyWith({
    Color? ink,
    Color? grey,
    Color? border,
    Color? accent,
    Color? green,
    Color? danger,
  }) {
    return AppColors(
      ink: ink ?? this.ink,
      grey: grey ?? this.grey,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      green: green ?? this.green,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      ink: Color.lerp(ink, other.ink, t)!,
      grey: Color.lerp(grey, other.grey, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      green: Color.lerp(green, other.green, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

ThemeData _theme(AppColors colors, Brightness brightness) {
  final scheme = ColorScheme(
    brightness: brightness,
    primary: colors.accent,
    onPrimary: brightness == Brightness.light ? Colors.white : colors.ink,
    secondary: colors.green,
    onSecondary: brightness == Brightness.light ? Colors.white : colors.ink,
    error: colors.danger,
    onError: Colors.white,
    surface: brightness == Brightness.light
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF151923),
    onSurface: colors.ink,
  );
  return ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    dividerColor: colors.border,
    textTheme:
        (brightness == Brightness.dark
                ? Typography.material2021(platform: TargetPlatform.android)
                      .white
                : Typography.material2021(platform: TargetPlatform.android)
                      .black)
            .apply(bodyColor: colors.ink, displayColor: colors.ink),
    cardColor: scheme.surface,
    dialogTheme: DialogThemeData(backgroundColor: scheme.surface),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: scheme.surface),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      labelStyle: TextStyle(color: colors.grey),
      hintStyle: TextStyle(color: colors.grey),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colors.accent, width: 1.5),
      ),
    ),
    extensions: [colors],
    useMaterial3: true,
  );
}

final appLightTheme = _theme(AppColors.light, Brightness.light);
final appDarkTheme = _theme(AppColors.dark, Brightness.dark);

extension AppColorsContext on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
