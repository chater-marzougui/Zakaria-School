import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/structs.dart';

/// Service for managing user accounts (instructors, secretaries, and developers)
/// Handles both Firebase Auth and Firestore operations
class UserService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  /// Create a new user with Firebase Auth and add to Firestore
  /// Note: This will temporarily sign out the current user and sign them back in
  static Future<String> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String role, // 'instructor', 'secretary', or 'developer'
  }) async {
    try {
      // Validate role
      if (role != 'instructor' && role != 'secretary' && role != 'developer') {
        throw Exception('Invalid role. Must be instructor, secretary, or developer.');
      }

      // Create Firebase Auth account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final displayName = '$firstName $lastName';

      // Create user document in Firestore
      final user = User(
        uid: uid,
        displayName: displayName,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        role: role,
      );

      await _db.collection('users').doc(uid).set(user.toFirestore());

      // Sign out the newly created user
      // Note: The AuthWrapper will detect the sign-out and redirect to login
      // The developer will need to sign back in with their credentials
      await _auth.signOut();
      
      return uid;
    } catch (e) {
      // Sign out to ensure clean state on error
      await _auth.signOut();
      throw Exception('Failed to create user: $e');
    }
  }

  /// Get a single user by ID
  static Future<User?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return User.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Get all users
  static Future<List<User>> getAllUsers() async {
    try {
      final snapshot = await _db.collection('users').get();
      return snapshot.docs
          .map((doc) => User.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  /// Get all instructors
  static Future<List<User>> getInstructors() async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'instructor')
          .get();
      return snapshot.docs
          .map((doc) => User.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get instructors: $e');
    }
  }

  /// Get all secretaries
  static Future<List<User>> getSecretaries() async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'secretary')
          .get();
      return snapshot.docs
          .map((doc) => User.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get secretaries: $e');
    }
  }

  /// Update a user's information (except email and password)
  static Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      // Remove uid, email, and createdAt if they're in updates
      updates.remove('uid');
      updates.remove('email');
      updates.remove('createdAt');
      
      await _db.collection('users').doc(uid).update(updates);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Delete a user (removes from Firestore only, not Firebase Auth)
  /// Note: Deleting from Firebase Auth requires the user to be signed in or admin SDK
  static Future<void> deleteUser(String uid) async {
    try {
      await _db.collection('users').doc(uid).delete();
      // Note: To delete from Firebase Auth, you would need Firebase Admin SDK
      // or have the user re-authenticate and call user.delete()
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Reset a user's password (sends password reset email)
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }
}
