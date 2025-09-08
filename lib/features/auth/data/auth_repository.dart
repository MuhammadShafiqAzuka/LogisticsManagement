import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // ✅ Save FCM token
    await _updateFcmToken(credential.user!.uid);

    return credential.user;
  }

  Future<User?> signUp(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // ✅ Save FCM token for new user
    await _firestore.collection("users").doc(credential.user!.uid).set({
      "email": email,
      "role": "driver",
      "createdAt": FieldValue.serverTimestamp(),
    });

    await _updateFcmToken(credential.user!.uid);

    return credential.user;
  }

  Future<void> _updateFcmToken(String uid) async {
    try {
      // ✅ Get APNs token (iOS only, but don't block FCM if null)
      if (Platform.isIOS) {
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        print("📱 iOS APNs token: $apnsToken");
      }

      // ✅ Always get latest FCM token
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      print("📱 Current FCM token: $fcmToken");

      if (fcmToken != null) {
        await _firestore.collection("users").doc(uid).set({
          "fcmToken": fcmToken,
          "lastLogin": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // ✅ overwrite safely
      }

      // ✅ Listen for future token refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        print("🔄 Token refreshed: $newToken");
        await _firestore.collection("users").doc(uid).set({
          "fcmToken": newToken,
        }, SetOptions(merge: true));
      });
    } catch (e) {
      print("Error updating FCM token: $e");
    }
  }

  Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection("users").doc(user.uid).update({
          "fcmToken": FieldValue.delete(), // ✅ clear token
        });
      } catch (e) {
        print("Error clearing FCM token on signOut: $e");
      }
    }

    await _auth.signOut();
  }

  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection("users").doc(uid).get();
      if (doc.exists) return doc.data()?["role"] as String?;
    } catch (e) {
      print("Error getting user role: $e");
    }
    return null;
  }

  User? get currentUser => _auth.currentUser;
}