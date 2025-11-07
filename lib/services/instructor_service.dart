import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/structs.dart' as structs;

/// Service to manage instructor data and cache them for quick access
/// Initializes on app start and keeps instructors in memory
class InstructorService {
  static final InstructorService _instance = InstructorService._internal();
  factory InstructorService() => _instance;
  InstructorService._internal();

  final Map<String, structs.User> _instructorsCache = {};
  bool _isInitialized = false;
  bool _isLoading = false;

  /// Get all cached instructors
  Map<String, structs.User> get instructors => Map.unmodifiable(_instructorsCache);

  /// Check if the service has been initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the service by loading all instructors from Firestore
  Future<void> initialize() async {
    if (_isInitialized || _isLoading) {
      return;
    }

    _isLoading = true;

    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'instructor')
          .get();

      _instructorsCache.clear();

      for (var doc in usersSnapshot.docs) {
        final user = structs.User.fromFirestore(doc);
        _instructorsCache[user.uid] = user;
      }

      _isInitialized = true;
      print('InstructorService initialized with ${_instructorsCache.length} instructors');
    } catch (e) {
      print('Error initializing InstructorService: $e');
      // Don't set _isInitialized to true if there was an error
    } finally {
      _isLoading = false;
    }
  }

  /// Refresh the instructors cache
  Future<void> refresh() async {
    _isInitialized = false;
    await initialize();
  }

  /// Get an instructor by ID
  structs.User? getInstructor(String instructorId) {
    return _instructorsCache[instructorId];
  }

  /// Get instructor name by ID
  String getInstructorName(String instructorId) {
    final instructor = _instructorsCache[instructorId];
    if (instructor == null) {
      return instructorId.isEmpty ? '-' : 'Unknown';
    }
    return instructor.displayName.isNotEmpty 
        ? instructor.displayName 
        : '${instructor.firstName} ${instructor.lastName}';
  }

  /// Get all instructor IDs
  List<String> getInstructorIds() {
    return _instructorsCache.keys.toList();
  }

  /// Get all instructors as a list
  List<structs.User> getInstructorsList() {
    return _instructorsCache.values.toList();
  }

  /// Add or update an instructor in the cache
  void updateInstructor(structs.User instructor) {
    if (instructor.role == 'instructor') {
      _instructorsCache[instructor.uid] = instructor;
    }
  }

  /// Remove an instructor from the cache
  void removeInstructor(String instructorId) {
    _instructorsCache.remove(instructorId);
  }

  /// Clear all cached data
  void clear() {
    _instructorsCache.clear();
    _isInitialized = false;
  }
}
