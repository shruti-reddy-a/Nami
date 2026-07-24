import 'package:flutter/material.dart';
import 'package:nami/features/habit/data/habit.dart';

class HabitUIHelper {
  static const List<Color> pastelPalette = [
    Color(0xFFB5EAD7), // Mint
    Color(0xFFFFDAC1), // Peach
    Color(0xFFE2F0CB), // Light Green
    Color(0xFFFFB7B2), // Light Pink
    Color(0xFFC7CEEA), // Lavender
    Color(0xFFA6E3E9), // Sky Blue
    Color(0xFFFBE7C6), // Pale Yellow
  ];

  static Color getColorForHabit(String title) {
    if (title.isEmpty) return pastelPalette[0];
    final hash = title.toLowerCase().hashCode;
    return pastelPalette[hash % pastelPalette.length];
  }

  static IconData getIconForHabit(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('run')) return Icons.directions_run;
    if (lower.contains('water') || lower.contains('hydrat')) return Icons.water_drop;
    if (lower.contains('read') || lower.contains('book')) return Icons.menu_book;
    if (lower.contains('meditat')) return Icons.self_improvement;
    if (lower.contains('gym') || lower.contains('workout') || lower.contains('lift')) return Icons.fitness_center;
    if (lower.contains('journal')) return Icons.edit_note;
    if (lower.contains('sleep')) return Icons.bedtime;
    if (lower.contains('vitamin') || lower.contains('pill')) return Icons.medication;
    return Icons.star_border;
  }

  static String getFrequencyText(Habit habit) {
    return habit.recurrence.toReadableString();
  }

  static bool isMissed(Habit habit, bool isLogged) {
    if (isLogged) return false;
    if (habit.timeOfDay == null || habit.timeOfDay == 'Anytime') return false;
    
    final now = DateTime.now();
    final hour = now.hour;
    
    // If it's morning (before 12 PM), nothing is missed yet.
    if (hour < 12) return false;
    
    final timeLower = habit.timeOfDay!.toLowerCase();
    
    // If it's afternoon (12 PM - 5 PM), morning habits are missed.
    if (hour >= 12 && hour < 17) {
      if (timeLower.contains('morning')) return true;
    }
    
    // If it's evening/night (after 5 PM), morning and afternoon habits are missed.
    if (hour >= 17) {
      if (timeLower.contains('morning') || timeLower.contains('afternoon') || timeLower.contains('noon')) return true;
    }
    
    return false;
  }
}
