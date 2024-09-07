
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? get currentUser => _auth.currentUser;
  bool get isSignedIN => currentUser != null;
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    notifyListeners();
  }

  Future<void> signUp(
      String name, String imageUrl, String email, String password) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'uid': userCredential.user!.uid,
      'email': email,
      'name': name,
      'imageUrl': imageUrl,
    });
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();

  }
}
