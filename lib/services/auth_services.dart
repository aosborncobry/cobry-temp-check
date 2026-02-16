import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream to listen to auth state (LoggedIn/LoggedOut)
  Stream<User?> get userState => _auth.authStateChanges();

  // 1. CHECK WHITELIST & ROLE
  // Verifies email exists in Firestore and matches the button they clicked
  Future<bool> isEmailWhitelisted(String email, String expectedRole) async {
    try {
      final doc = await _db.collection('approved_users').doc(email.toLowerCase()).get();
      if (doc.exists) {
        // Validation: Does the 'role' field match 'client' or 'staff'?
        return doc.data()?['role'] == expectedRole;
      }
      return false;
    } catch (e) {
      debugPrint("Whitelist error: $e");
      return false;
    }
  }

  // 2. SEND LOGIN LINK
  // Sends the passwordless link to the user's inbox
  Future<void> sendLoginLink(String email) async {
    final acs = ActionCodeSettings(
      // The URL to redirect back to. Must be whitelisted in Firebase Console.
      url: 'https://cobry-temp-check.firebaseapp.com/finishSignUp?email=$email',
      handleCodeInApp: true,
      iOSBundleId: 'com.cobry.tempcheck',
      androidPackageName: 'com.cobry.tempcheck',
      androidInstallApp: true,
      androidMinimumVersion: '12',
    );

    try {
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: acs,
      );
      debugPrint("Auth link sent to: $email");
    } catch (e) {
      debugPrint("Failed to send link: $e");
      rethrow;
    }
  }

  // 3. COMPLETE SIGN IN
  // Call this when the app is opened via the email link
  Future<UserCredential?> completeSignIn(String email, String emailLink) async {
    try {
      if (_auth.isSignInWithEmailLink(emailLink)) {
        final credential = await _auth.signInWithEmailLink(
          email: email,
          emailLink: emailLink,
        );
        return credential;
      }
    } catch (e) {
      debugPrint("Error completing sign in: $e");
      rethrow;
    }
    return null;
  }

  // 4. LOGOUT
  Future<void> signOut() async => await _auth.signOut();
}