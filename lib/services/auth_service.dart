import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream to listen to auth state
  Stream<User?> get userState => _auth.authStateChanges();

  // 1. CHECK WHITELIST & ROLE (Space-Resistant Version)
  Future<bool> isEmailWhitelisted(String email, String expectedRole) async {
    try {
      // .trim() removes any leading/trailing spaces from your input
      final cleanEmail = email.trim().toLowerCase();
      
      // Step A: Search for a document where the ID matches the email
      var doc = await _db.collection('approved_users').doc(cleanEmail).get();
      
      // Step B: If not found by ID, try searching for a field named 'email' 
      // This is a safety net if the Document ID has an invisible space
      if (!doc.exists) {
        final query = await _db
            .collection('approved_users')
            .where('email', isEqualTo: cleanEmail)
            .limit(1)
            .get();
        
        if (query.docs.isNotEmpty) {
          doc = query.docs.first as DocumentSnapshot<Map<String, dynamic>>;
        }
      }

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        final actualRole = data?['role']?.toString().trim().toLowerCase();
        
        // Verify the role matches what was clicked on the entry screen
        return actualRole == expectedRole.toLowerCase();
      }
      
      debugPrint("No document found for: $cleanEmail");
      return false;
    } catch (e) {
      debugPrint("Whitelist error: $e");
      return false;
    }
  }

  // 2. SEND MAGIC LINK
  Future<void> sendLoginLink(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    
    final acs = ActionCodeSettings(
      // Ensure this URL is exactly what you see in your browser
      url: 'https://cobry-temp-check.web.app', 
      handleCodeInApp: true,
    );

    try {
      await _auth.sendSignInLinkToEmail(
        email: cleanEmail,
        actionCodeSettings: acs,
      );
    } catch (e) {
      debugPrint("Link sending failed: $e");
      rethrow;
    }
  }

  // 3. LOGOUT
  Future<void> signOut() async => await _auth.signOut();

  // Helper methods for the PWA link handling
  bool isSignInWithEmailLink(String link) => _auth.isSignInWithEmailLink(link);

  Future<UserCredential?> completeSignIn(String email, String emailLink) async {
    return await _auth.signInWithEmailLink(
      email: email.trim().toLowerCase(),
      emailLink: emailLink,
    );
  }
}