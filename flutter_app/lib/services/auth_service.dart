import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  UserModel? _userProfile;
  UserModel? get userProfile => _userProfile;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    if (user != null) {
      await _loadUserProfile(user.uid);
    } else {
      _userProfile = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userProfile = UserModel.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      if (result.user != null) {
        await _createUserProfile(result.user!);
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _createUserProfile(User user) async {
    try {
      final now = DateTime.now();
      final userProfile = UserModel(
        id: user.uid,
        email: user.email ?? '',
        createdAt: now,
        updatedAt: now,
        profileImages: [],
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userProfile.toFirestore());

      _userProfile = userProfile;
    } catch (e) {
      debugPrint('Error creating user profile: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _userProfile = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      if (currentUser == null) return;

      updates['updated_at'] = Timestamp.now();
      
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update(updates);

      // Reload user profile
      await _loadUserProfile(currentUser!.uid);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user profile: $e');
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      default:
        return 'An undefined Error happened: ${e.message}';
    }
  }
}