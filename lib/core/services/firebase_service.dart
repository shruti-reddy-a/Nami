import 'package:nami/features/habit/data/habit_log.dart';
import 'package:nami/features/habit/data/habit.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nami/features/profile/data/user_profile.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _habitsRef {
    return _firestore.collection('users').doc(_userId).collection('habits');
  }

  CollectionReference<Map<String, dynamic>> get _logsRef {
    return _firestore.collection('users').doc(_userId).collection('habit_logs');
  }

  // --- Habits ---

  Stream<List<Habit>> getHabitsStream() {
    return _habitsRef.where('is_deleted', isEqualTo: 0).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Habit.fromMap(doc.data()..['id'] = doc.id)).toList();
    });
  }

  Future<void> insertHabit(Habit habit) async {
    final docRef = _habitsRef.doc(habit.id);
    await docRef.set(habit.toMap());
  }

  Future<void> updateHabit(Habit habit) async {
    final docRef = _habitsRef.doc(habit.id);
    await docRef.update(habit.toMap());
  }

  Future<void> deleteHabit(String id) async {
    final docRef = _habitsRef.doc(id);
    await docRef.update({'is_deleted': 1});
  }

  // --- Habit Logs ---

  Stream<List<HabitLog>> getHabitLogsStream() {
    return _logsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => HabitLog.fromMap(doc.data()..['id'] = doc.id)).toList();
    });
  }

  Future<void> insertHabitLog(HabitLog log) async {
    final docRef = _logsRef.doc(log.id);
    await docRef.set(log.toMap());
  }

  Future<void> deleteHabitLog(String logId) async {
    await _logsRef.doc(logId).delete();
  }

  // --- User Profile ---

  Stream<UserProfile?> getUserProfileStream() {
    return _firestore.collection('users').doc(_userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _firestore.collection('users').doc(_userId).set(profile.toMap(), SetOptions(merge: true));
  }

  Future<String> uploadProfileImage(File imageFile) async {
    final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/$_userId.jpg');
    final uploadTask = await storageRef.putFile(imageFile);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> deleteAccount() async {
    // 1. Delete Firestore data (simple version, ideally done via Cloud Functions)
    await _firestore.collection('users').doc(_userId).delete();
    // 2. Delete Auth user
    await _auth.currentUser?.delete();
  }
}
