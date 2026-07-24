import 'package:flutter/material.dart';
import 'package:nami/core/constants/app_strings.dart';
import 'package:nami/features/habit/presentation/screens/add_edit_habit_screen.dart';
import 'package:nami/core/presentation/widgets/common_app_bar_actions.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(AppStrings.appName, style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.primary, letterSpacing: 1)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [CommonAppBarActions()],
      ),
      body: _buildWelcomeState(context, theme),
    );
  }

  Widget _buildWelcomeState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.waves, size: 80, color: theme.colorScheme.primaryContainer),
            const SizedBox(height: 24),
            Text(
              AppStrings.welcomeTitle,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.welcomeSubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(AppStrings.createFirstHabit),
            ),
          ],
        ),
      ),
    );
  }

}
