import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_roles.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Sign Up with Email, Password, Name, and Phone Number.
  ///
  /// Creates the Firebase Auth user and a Firestore profile with role
  /// [AppRoles.muzakki] only. Admin promotion is done in Firebase Console
  /// (see [AppRoles]).
  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      debugPrint('🚀 [Auth] Starting Sign Up for email: $email');

      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(name.trim());
        final String emailLower = email.trim().toLowerCase();

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name.trim(),
          'email': emailLower,
          'phoneNumber': phoneNumber.trim(),
          'role': AppRoles.muzakki,
          'createdAt': FieldValue.serverTimestamp(),
          'totalZakatPaid': 0.0,
          'totalSadaqahPaid': 0.0,
        });

        debugPrint(
          '✅ [Auth] Sign Up complete for User UID: ${user.uid} '
          'with role: ${AppRoles.muzakki}',
        );
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '❌ [Auth] Sign Up failed with FirebaseAuthException [${e.code}]: ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('❌ [Auth] Sign Up failed with unexpected error: $e');
      rethrow;
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🚀 [Auth] Starting Sign In for email: $email');
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      debugPrint(
        '✅ [Auth] Sign In successful for User UID: ${userCredential.user?.uid}',
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '❌ [Auth] Sign In failed with FirebaseAuthException [${e.code}]: ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('❌ [Auth] Sign In failed with unexpected error: $e');
      rethrow;
    }
  }

  /// Reads the user's role from Firestore. Never assigns admin based on email.
  ///
  /// If the profile document or role field is missing, returns [AppRoles.muzakki].
  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final role = data['role'];
          if (role != null && role.toString().isNotEmpty) {
            return role.toString().toLowerCase();
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [Auth] Failed to get user role for UID $uid: $e');
    }
    return AppRoles.muzakki;
  }

  /// Returns true when the signed-in user has the admin role in Firestore.
  Future<bool> isCurrentUserAdmin() async {
    final user = currentUser;
    if (user == null) return false;
    final role = await getUserRole(user.uid);
    return AppRoles.isAdminRole(role);
  }

  Future<void> signOut() async {
    try {
      debugPrint('🚀 [Auth] Signing out user: ${_auth.currentUser?.uid}');
      await _auth.signOut();
      debugPrint('✅ [Auth] User signed out successfully.');
    } catch (e) {
      debugPrint('❌ [Auth] Sign out failed: $e');
      rethrow;
    }
  }
}
