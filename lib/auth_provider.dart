import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getter for the current user
  User? get currentUser => _auth.currentUser;

  // Getter to check if the user is signed in
  bool get isSignedIN => currentUser != null;

  // Method to sign in a user
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
    } catch (e) {
      rethrow; // You can handle specific errors here if necessary
    }
  }

  // Method to sign up a user
  Future<void> signUp(String name, String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // Add user information to Firestore after successful sign-up
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'imageUrl': '', // If you're not using image URLs, keep this empty
      });

      notifyListeners();
    } catch (e) {
      rethrow; // You can handle specific errors here if necessary
    }
  }

  // Method to sign out a user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      rethrow; // Handle errors if necessary
    }
  }
}
