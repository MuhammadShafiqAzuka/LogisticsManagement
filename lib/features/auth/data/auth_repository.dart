import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<User?> signUp(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user document in Firestore
    await _firestore.collection("users").doc(credential.user!.uid).set({
      "email": email,
      "role": "driver",
      "createdAt": FieldValue.serverTimestamp(),
    });

    return credential.user;
  }

  Future<void> signOut() async => await _auth.signOut();

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