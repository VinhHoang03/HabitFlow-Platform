import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _db.collection('users').doc(userId);
  }

  Stream<UserModel?> streamUser(String userId) {
    return _userDoc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return UserModel.fromMap(data, snapshot.id);
    });
  }

  Future<void> ensureUserProfile(User user) async {
    final email = user.email ?? '';
    final fallbackName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : email.split('@').first;

    await _userDoc(user.uid).set({
      'name': fallbackName,
      'email': email,
      'avatar': user.photoURL ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateProfile(UserModel user) async {
    await _userDoc(user.userId).set({
      ...user.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
