import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_failure.dart';
import '../domain/user.dart';
import 'auth_repository.dart';

/// Production implementation of [AuthRepository] communicating with Firebase Authentication
/// and Cloud Firestore.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    fb_auth.FirebaseAuth? auth,
    firestore.FirebaseFirestore? firestoreInstance,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? fb_auth.FirebaseAuth.instance,
       _firestore = firestoreInstance ?? firestore.FirebaseFirestore.instance,
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(
             scopes: const <String>['email', 'profile'],
             serverClientId:
                 '1096787298947-o84vriapv2soord5o0u9q4121a6aj8c2.apps.googleusercontent.com',
           );

  final fb_auth.FirebaseAuth _auth;
  final firestore.FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      return _mapFirebaseUser(fbUser);
    });
  }

  @override
  Future<User?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return _mapFirebaseUser(fbUser);
  }

  @override
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final fbUser = credential.user;
      if (fbUser == null) {
        throw const ServerFailure(
          'No user returned from Firebase authentication.',
        );
      }

      return await _mapFirebaseUser(fbUser);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Authentication failed: ${e.toString()}');
    }
  }

  @override
  Future<User> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final fbUser = credential.user;
      if (fbUser == null) {
        throw const ServerFailure(
          'No user returned from Firebase registration.',
        );
      }

      final trimmedName = name.trim().isNotEmpty ? name.trim() : 'Learner';
      await fbUser.updateDisplayName(trimmedName);

      // Persist user profile to Firestore
      try {
        await _firestore.collection('users').doc(fbUser.uid).set({
          'id': fbUser.uid,
          'name': trimmedName,
          'email': fbUser.email,
          'preferredLanguage': 'DE',
          'createdAt': firestore.FieldValue.serverTimestamp(),
        }, firestore.SetOptions(merge: true));
      } catch (firestoreError) {
        debugPrint('Firestore profile creation notice: $firestoreError');
      }

      return User(
        id: fbUser.uid,
        name: trimmedName,
        email: fbUser.email,
        preferredLanguage: 'DE',
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<User> signInWithGoogle() async {
    try {
      // Ensure any stale Google session on Android is cleared before opening picker
      try {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
        }
      } catch (_) {}

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User aborted the Google account picker
        throw const GoogleSignInCancelledFailure();
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final fbUser = userCredential.user;
      if (fbUser == null) {
        throw const ServerFailure(
          'Failed to retrieve user from Google Sign-In.',
        );
      }

      final displayName =
          fbUser.displayName ?? googleUser.displayName ?? 'Learner';

      try {
        await _firestore.collection('users').doc(fbUser.uid).set({
          'id': fbUser.uid,
          'name': displayName,
          'email': fbUser.email,
          'updatedAt': firestore.FieldValue.serverTimestamp(),
        }, firestore.SetOptions(merge: true));
      } catch (firestoreError) {
        debugPrint('Firestore Google profile sync notice: $firestoreError');
      }

      return await _mapFirebaseUser(fbUser, fallbackName: displayName);
    } on PlatformException catch (e) {
      debugPrint('Google Sign-In PlatformException: ${e.code} / ${e.message}');
      // Code 10 / DEVELOPER_ERROR / sign_in_failed / ERROR signifies missing SHA-1 or unconfigured OAuth in Firebase Console
      if (e.code == '10' ||
          e.code == 'sign_in_failed' ||
          e.code == 'network_error' ||
          e.message == 'ERROR' ||
          (e.message?.contains('10') ?? false) ||
          (e.message?.contains('DEVELOPER_ERROR') ?? false)) {
        throw const GoogleSignInConfigFailure();
      }
      throw ServerFailure('Google sign-in error: ${e.message ?? e.code}');
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Google sign-in could not be completed: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw ServerFailure('Failed to send reset email: $e');
    }
  }

  @override
  Future<void> updateLanguage(String languageCode) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('users').doc(currentUser.uid).set({
        'preferredLanguage': languageCode,
      }, firestore.SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to update language in Firestore: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut().catchError((_) => null),
      ]);
    } catch (e) {
      debugPrint('Sign out notice: $e');
      await _auth.signOut();
    }
  }

  Future<User> _mapFirebaseUser(
    fb_auth.User fbUser, {
    String? fallbackName,
  }) async {
    String name = fallbackName ?? fbUser.displayName ?? '';
    String preferredLanguage = 'DE';

    try {
      final doc = await _firestore.collection('users').doc(fbUser.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final firestoreName = data['name'] as String?;
        if (firestoreName != null && firestoreName.isNotEmpty) {
          name = firestoreName;
        }
        final lang = data['preferredLanguage'] as String?;
        if (lang != null && lang.isNotEmpty) {
          preferredLanguage = lang;
        }
      }
    } catch (e) {
      debugPrint('Notice loading user profile from Firestore: $e');
    }

    if (name.isEmpty) {
      name = fbUser.email?.split('@').first ?? 'Learner';
      if (name.isNotEmpty) {
        name = '${name[0].toUpperCase()}${name.substring(1)}';
      }
    }

    return User(
      id: fbUser.uid,
      name: name,
      email: fbUser.email,
      preferredLanguage: preferredLanguage,
    );
  }

  AuthFailure _mapFirebaseAuthException(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-email':
        return const InvalidCredentialsFailure();
      case 'email-already-in-use':
        return const EmailAlreadyInUseFailure();
      case 'weak-password':
        return const WeakPasswordFailure();
      case 'user-disabled':
        return const UserDisabledFailure();
      case 'network-request-failed':
        return const NetworkFailure();
      default:
        return ServerFailure(e.message ?? 'An authentication error occurred.');
    }
  }
}
