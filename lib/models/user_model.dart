part of 'structs.dart';

class User {
  final String uid;
  final String displayName;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final DateTime createdAt;
  final String role; // 'developer', 'instructor', 'secretary'

  User({
    required this.uid,
    required this.displayName,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.createdAt,
    this.role = 'instructor', // Default role
  });

  // Factory method to create a User from Firestore document
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      uid: data['uid'] ?? '',
      displayName: data['displayName'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      createdAt: (data['createdAt'] ?? DateTime.now() as Timestamp).toDate(),
      role: data['role'] ?? 'instructor', // Default to instructor if not specified
    );
  }

  // Method to convert User to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
      'role': role,
    };
  }
}