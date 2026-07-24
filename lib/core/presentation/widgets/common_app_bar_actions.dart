import 'package:flutter/material.dart';
import 'package:nami/features/profile/presentation/profile_screen.dart';

class CommonAppBarActions extends StatelessWidget {
  const CommonAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_none, color: theme.colorScheme.onSurface),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.help_outline, color: theme.colorScheme.onSurface),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0, left: 8.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.teal,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}
