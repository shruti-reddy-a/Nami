import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nami/features/profile/presentation/profile_screen.dart';
import 'package:nami/features/profile/providers/profile_provider.dart';

class CommonAppBarActions extends ConsumerWidget {
  const CommonAppBarActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider).value;
    final photoUrl = profile?.photoUrl;

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
            child: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              child: photoUrl != null
                  ? ClipOval(child: Image.network(photoUrl, width: 32, height: 32, fit: BoxFit.cover))
                  : Icon(Icons.person, color: theme.colorScheme.primary, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}
