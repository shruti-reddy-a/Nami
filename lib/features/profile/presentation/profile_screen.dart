import 'package:nami/features/habit/providers/habit_provider.dart';
import 'package:nami/features/profile/providers/profile_provider.dart';
import 'package:nami/features/profile/data/user_profile.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nami/features/auth/presentation/login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final List<String> _emojis = ['😊', '🚀', '🔥', '🌟', '🦄', '🍎', '🌈', '🍕', '🎉', '💡', '🎵', '🏆'];
  bool _isUploading = false;

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final service = ref.read(firebaseServiceProvider);
        await service.deleteAccount();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting account. You may need to log out and log in again first. ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800);
    
    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        final user = FirebaseAuth.instance.currentUser!;
        final service = ref.read(firebaseServiceProvider);
        final url = await service.uploadProfileImage(File(pickedFile.path));
        
        final currentProfile = ref.read(userProfileProvider).value;
        final newProfile = currentProfile?.copyWith(photoUrl: url) ?? UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: 'Nami User',
          photoUrl: url,
        );
        
        await service.updateUserProfile(newProfile);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _selectEmoji(String emoji) async {
    final user = FirebaseAuth.instance.currentUser!;
    final service = ref.read(firebaseServiceProvider);
    final currentProfile = ref.read(userProfileProvider).value;
    
    final newProfile = currentProfile?.copyWith(emoji: emoji, clearPhoto: true) ?? UserProfile(
      uid: user.uid,
      email: user.email ?? '',
      displayName: 'Nami User',
      emoji: emoji,
    );
    
    await service.updateUserProfile(newProfile);
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose Avatar', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Upload Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                const Divider(),
                const SizedBox(height: 12),
                Text('Or pick an emoji', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: _emojis.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _selectEmoji(_emojis[index]);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(_emojis[index], style: const TextStyle(fontSize: 32)),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (profile) {
          final photoUrl = profile?.photoUrl;
          final emoji = profile?.emoji ?? '😊';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: _showAvatarPicker,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 3),
                        ),
                        child: _isUploading
                            ? const Center(child: CircularProgressIndicator())
                            : photoUrl != null
                                ? ClipOval(child: Image.network(photoUrl, fit: BoxFit.cover))
                                : Center(child: Text(emoji, style: const TextStyle(fontSize: 56))),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.edit, color: theme.colorScheme.onPrimary, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  profile?.displayName ?? 'Nami User',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? '',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 48),
                
                // Actions
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Log Out'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _logout,
                      ),
                      Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2), height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.red),
                        title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.red),
                        onTap: _deleteAccount,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
