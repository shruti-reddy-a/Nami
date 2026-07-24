import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nami/features/profile/data/user_profile.dart';
import 'package:nami/features/habit/providers/habit_provider.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.value == null) {
    return Stream.value(null);
  }
  
  final service = ref.watch(firebaseServiceProvider);
  return service.getUserProfileStream();
});
