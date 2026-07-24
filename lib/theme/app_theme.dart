import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:calendar_view/calendar_view.dart';

class NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF00696F),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFF64B5BC),
        onPrimaryContainer: Color(0xFF004549),
        secondary: Color(0xFF366669),
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFB7E9ED),
        onSecondaryContainer: Color(0xFF3A6A6E),
        tertiary: Color(0xFF516161),
        onTertiary: Color(0xFFFFFFFF),
        tertiaryContainer: Color(0xFF9BACAB),
        onTertiaryContainer: Color(0xFF304040),
        error: Color(0xFFBA1A1A),
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF93000A),
        surface: Color(0xFFF0F2F9), // Subtle lavender-grey match
        onSurface: Color(0xFF191C1D),
        surfaceContainerHighest: Color(0xFFE1E3E4),
        onSurfaceVariant: Color(0xFF3E4949),
        outline: Color(0xFF6E797A),
        outlineVariant: Color(0xFFBEC8C9),
      ),
      textTheme: GoogleFonts.interTextTheme(),
      extensions: [
        DayViewThemeData.light().copyWith(
          liveIndicatorColor: const Color(0xFF00696F),
          headerBackgroundColor: const Color(0xFFF0F2F9),
          headerIconColor: const Color(0xFF191C1D),
          headerTextColor: const Color(0xFF191C1D),
        ),
        WeekViewThemeData.light().copyWith(
          liveIndicatorColor: const Color(0xFF00696F),
          headerBackgroundColor: const Color(0xFFF0F2F9),
          headerIconColor: const Color(0xFF191C1D),
          headerTextColor: const Color(0xFF191C1D),
          weekDayTileColor: const Color(0xFF00696F),
          weekDayTextColor: const Color(0xFFFFFFFF),
        ),
        MonthViewThemeData.light().copyWith(
          headerBackgroundColor: const Color(0xFFF0F2F9),
          headerIconColor: const Color(0xFF191C1D),
          headerTextColor: const Color(0xFF191C1D),
          weekDayTileColor: const Color(0xFF00696F),
          weekDayTextColor: const Color(0xFFFFFFFF),
        ),
      ],
    );
  }
}
