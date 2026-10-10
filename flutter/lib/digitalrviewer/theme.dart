// DigitalRViewer design system: tokens and ThemeData built from the "Soft Lilac" mockups.
//
// This file must only import Flutter, so the screens can be previewed outside the app
// (branding/ui_preview). The app maps its own state onto these tokens; nothing here knows
// about RustDesk.
import 'package:flutter/material.dart';

/// Display name shown in the UI. The internal app name stays "DigitalRViewer"
/// (install paths, URL scheme), see src/branding.rs.
const String kDrDisplayName = 'Digital R Viewer';

const String kDrSans = 'AlbertSans';
const String kDrSerif = 'SourceSerif4';

@immutable
class DrColors extends ThemeExtension<DrColors> {
  final Color bg; // window background
  final Color surface; // cards
  final Color surfaceSunk; // inputs, inner panels
  final Color text;
  final Color textMuted; // secondary text
  final Color textSubtle; // tertiary / captions
  final Color placeholder;
  final Color border; // card borders
  final Color borderStrong; // inputs, secondary buttons
  final Color divider; // row separators
  final Color chrome; // top bar segmented background
  final Color primary; // primary button fill
  final Color onPrimary;
  final Color accent; // lilac tint (hero card, selected nav, chips)
  final Color accentText; // text on accent tint
  final Color accentTextMuted;
  final Color accentBorder;
  final Color link; // hover / link colour
  final Color online;
  final Color onlineText;
  final Color offline;
  final Color danger;
  final Color toggleOff;
  final Color disabledFill;
  final Color disabledText;
  final Color scrim;

  const DrColors({
    required this.bg,
    required this.surface,
    required this.surfaceSunk,
    required this.text,
    required this.textMuted,
    required this.textSubtle,
    required this.placeholder,
    required this.border,
    required this.borderStrong,
    required this.divider,
    required this.chrome,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.accentText,
    required this.accentTextMuted,
    required this.accentBorder,
    required this.link,
    required this.online,
    required this.onlineText,
    required this.offline,
    required this.danger,
    required this.toggleOff,
    required this.disabledFill,
    required this.disabledText,
    required this.scrim,
  });

  static const light = DrColors(
    bg: Color(0xFFFBFAF7),
    surface: Color(0xFFFFFFFF),
    surfaceSunk: Color(0xFFFBFAF7),
    text: Color(0xFF161513),
    textMuted: Color(0xFF5A564E),
    textSubtle: Color(0xFF66625A),
    placeholder: Color(0xFF8C877E),
    border: Color(0xFFECE8E1),
    borderStrong: Color(0xFFE2DED6),
    divider: Color(0xFFF2EFE9),
    chrome: Color(0xFFF2EFE9),
    primary: Color(0xFF161513),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFFEEEAFB),
    accentText: Color(0xFF2E2766),
    accentTextMuted: Color(0xFF4B4470),
    accentBorder: Color(0xFFCFC7EE),
    link: Color(0xFF5B4BC4),
    online: Color(0xFF3A9A6A),
    onlineText: Color(0xFF2C7A52),
    offline: Color(0xFFC9C3B8),
    danger: Color(0xFFA1381F),
    toggleOff: Color(0xFFE2DED6),
    disabledFill: Color(0xFFF6F4EF),
    disabledText: Color(0xFF8C877E),
    scrim: Color(0x57161513),
  );

  // Warm dark counterpart (not in the mockups): same hues, inverted lightness.
  static const dark = DrColors(
    bg: Color(0xFF161513),
    surface: Color(0xFF201E1B),
    surfaceSunk: Color(0xFF1A1917),
    text: Color(0xFFF3F1EC),
    textMuted: Color(0xFFB5AFA4),
    textSubtle: Color(0xFFA39D92),
    placeholder: Color(0xFF7D786F),
    border: Color(0xFF2E2B27),
    borderStrong: Color(0xFF3A3631),
    divider: Color(0xFF292622),
    chrome: Color(0xFF24221F),
    primary: Color(0xFFF3F1EC),
    onPrimary: Color(0xFF161513),
    accent: Color(0xFF2A2547),
    accentText: Color(0xFFDCD5F7),
    accentTextMuted: Color(0xFFB9B1DD),
    accentBorder: Color(0xFF4A4378),
    link: Color(0xFFA99CF0),
    online: Color(0xFF52B884),
    onlineText: Color(0xFF6FCB9A),
    offline: Color(0xFF5E5A53),
    danger: Color(0xFFE07A5F),
    toggleOff: Color(0xFF3A3631),
    disabledFill: Color(0xFF24221F),
    disabledText: Color(0xFF7D786F),
    scrim: Color(0x8C000000),
  );

  static DrColors of(BuildContext context) =>
      Theme.of(context).extension<DrColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  DrColors copyWith() => this;

  @override
  DrColors lerp(ThemeExtension<DrColors>? other, double t) =>
      (other is DrColors && t >= 0.5) ? other : this;
}

/// Radii from the mockups.
class DrRadius {
  static const double window = 12;
  static const double hero = 24; // Home cards
  static const double card = 20; // tables, settings groups
  static const double tile = 18; // device tiles, inner panels
  static const double option = 16; // radio cards
  static const double nav = 12; // settings nav items
  static const double logo = 8;
  static const double dialog = 28;
  static const double pill = 999;
}

/// Text styles from the mockups (sizes in logical px, same as CSS px).
class DrText {
  static TextStyle serif(double size, Color color) => TextStyle(
      fontFamily: kDrSerif,
      fontSize: size,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.015 * size,
      height: 1.15,
      color: color);

  static TextStyle sans(double size, Color color,
          {FontWeight weight = FontWeight.w400,
          double? letterSpacing,
          double? height,
          bool tabular = false}) =>
      TextStyle(
          fontFamily: kDrSans,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: letterSpacing,
          height: height,
          color: color,
          fontFeatures:
              tabular ? const [FontFeature.tabularFigures()] : null);
}

class DrShadow {
  static const segmentOn = [
    BoxShadow(color: Color(0x14161513), blurRadius: 2, offset: Offset(0, 1))
  ];
  static const card = [
    BoxShadow(color: Color(0x08161513), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A161513), blurRadius: 32, offset: Offset(0, 12)),
  ];
  static const dialog = [
    BoxShadow(color: Color(0x47161513), blurRadius: 80, offset: Offset(0, 30))
  ];
}

/// Builds the app-wide ThemeData so stock RustDesk widgets pick up the look too.
ThemeData drThemeData(Brightness brightness, {ThemeData? base}) {
  final c = brightness == Brightness.dark ? DrColors.dark : DrColors.light;
  final start = base ?? ThemeData(brightness: brightness, useMaterial3: false);
  final scheme = ColorScheme.fromSeed(
    seedColor: c.link,
    brightness: brightness,
  ).copyWith(
    primary: c.primary,
    onPrimary: c.onPrimary,
    secondary: c.link,
    surface: c.surface,
    onSurface: c.text,
    error: c.danger,
  );
  const pill = StadiumBorder();
  final textTheme = start.textTheme.apply(
      fontFamily: kDrSans, bodyColor: c.text, displayColor: c.text);

  return start.copyWith(
    colorScheme: scheme,
    primaryColor: c.primary,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    cardColor: c.surface,
    dividerColor: c.divider,
    hintColor: c.placeholder,
    disabledColor: c.disabledText,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    extensions: [
      ...start.extensions.values.where((e) => e is! DrColors),
      c,
    ],
    dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
    cardTheme: CardTheme(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DrRadius.card),
          side: BorderSide(color: c.border)),
    ),
    listTileTheme: ListTileThemeData(
      textColor: c.text,
      iconColor: c.textMuted,
      selectedColor: c.accentText,
      selectedTileColor: c.accent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        disabledBackgroundColor: c.disabledFill,
        disabledForegroundColor: c.disabledText,
        elevation: 0,
        shape: pill,
        minimumSize: const Size(64, 40),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        textStyle: DrText.sans(14, c.onPrimary, weight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        backgroundColor: c.surface,
        side: BorderSide(color: c.borderStrong),
        shape: pill,
        minimumSize: const Size(64, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        textStyle: DrText.sans(14, c.text, weight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.text,
        shape: pill,
        textStyle: DrText.sans(13, c.text, weight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceSunk,
      hintStyle: DrText.sans(14, c.placeholder),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DrRadius.option),
          borderSide: BorderSide(color: c.borderStrong)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DrRadius.option),
          borderSide: BorderSide(color: c.borderStrong)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DrRadius.option),
          borderSide: BorderSide(color: c.text, width: 1.5)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.toggleOff),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? c.primary : Colors.transparent),
      checkColor: WidgetStateProperty.all(c.onPrimary),
      side: BorderSide(color: c.placeholder, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? c.primary : c.placeholder),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DrRadius.dialog)),
      titleTextStyle: DrText.serif(24, c.text),
      contentTextStyle: DrText.sans(14, c.textMuted),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
          color: c.primary, borderRadius: BorderRadius.circular(8)),
      textStyle: DrText.sans(12, c.onPrimary, weight: FontWeight.w500),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.border)),
      textStyle: DrText.sans(13, c.text),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(c.borderStrong),
      radius: const Radius.circular(8),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.text,
      selectionColor: c.accentBorder,
    ),
  );
}
