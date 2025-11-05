import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/structs.dart';

/// Database service for managing candidates and sessions
/// Provides CRUD operations and validation logic
class DatabaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== CANDIDATE OPERATIONS ====================

  /// Create a new candidate
  static Future<String> createCandidate(Candidate candidate) async {
    try {
      final docRef = await _db.collection('candidates').add(candidate.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create candidate: $e');
    }
  }

  /// Get a single candidate by ID
  static Future<Candidate?> getCandidate(String candidateId) async {
    try {
      final doc = await _db.collection('candidates').doc(candidateId).get();
      if (!doc.exists) return null;
      return Candidate.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get candidate: $e');
    }
  }

  /// Get all candidates
  static Future<List<Candidate>> getAllCandidates() async {
    try {
      final snapshot = await _db.collection('candidates').get();
      return snapshot.docs
          .map((doc) => Candidate.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get candidates: $e');
    }
  }

  /// Update a candidate
  static Future<void> updateCandidate(String candidateId, Map<String, dynamic> updates) async {
    try {
      await _db.collection('candidates').doc(candidateId).update(updates);
    } catch (e) {
      throw Exception('Failed to update candidate: $e');
    }
  }

  /// Delete a candidate and all their sessions
  static Future<void> deleteCandidate(String candidateId) async {
    try {
      // Delete all sessions for this candidate
      final sessionsSnapshot = await _db
          .collection('sessions')
          .where('candidate_id', isEqualTo: candidateId)
          .get();

      final batch = _db.batch();
      for (var doc in sessionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the candidate
      batch.delete(_db.collection('candidates').doc(candidateId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete candidate: $e');
    }
  }

  /// Delete all candidates and their sessions
  static Future<void> deleteAllCandidates() async {
    try {
      // Get all candidates
      final candidatesSnapshot = await _db.collection('candidates').get();
      
      // Get all sessions
      final sessionsSnapshot = await _db.collection('sessions').get();

      // Batch delete
      final batch = _db.batch();
      
      for (var doc in candidatesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      for (var doc in sessionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all candidates: $e');
    }
  }

  // ==================== SESSION OPERATIONS ====================

  /// Create a new session with overlap validation
  static Future<String> createSession(Session session, {bool checkOverlap = true}) async {
    try {
      // Check for overlapping sessions if requested
      if (checkOverlap) {
        final hasOverlap = await _checkSessionOverlap(
          candidateId: session.candidateId,
          date: session.date,
          startTime: session.startTime,
          endTime: session.endTime,
          excludeSessionId: null,
        );

        if (hasOverlap) {
          throw Exception(
            'This candidate already has a session at this time. '
            'Sessions cannot overlap for the same candidate.'
          );
        }
      }

      final docRef = await _db.collection('sessions').add(session.toFirestore());
      return docRef.id;
    } catch (e) {
      if (e.toString().contains('overlap')) {
        rethrow; // Rethrow overlap error as-is
      }
      throw Exception('Failed to create session: $e');
    }
  }

  /// Get a single session by ID
  static Future<Session?> getSession(String sessionId) async {
    try {
      final doc = await _db.collection('sessions').doc(sessionId).get();
      if (!doc.exists) return null;
      return Session.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get session: $e');
    }
  }

  /// Get all sessions for a candidate
  static Future<List<Session>> getCandidateSessions(String candidateId) async {
    try {
      final snapshot = await _db
          .collection('sessions')
          .where('candidate_id', isEqualTo: candidateId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Session.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get candidate sessions: $e');
    }
  }

  /// Get all sessions
  static Future<List<Session>> getAllSessions() async {
    try {
      final snapshot = await _db
          .collection('sessions')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Session.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get sessions: $e');
    }
  }

  /// Get sessions for a date range
  static Future<List<Session>> getSessionsInDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _db
          .collection('sessions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThan: Timestamp.fromDate(endDate))
          .orderBy('date')
          .get();

      return snapshot.docs
          .map((doc) => Session.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get sessions in date range: $e');
    }
  }

  /// Update a session with overlap validation
  static Future<void> updateSession(
    String sessionId,
    Map<String, dynamic> updates, {
    bool checkOverlap = true,
  }) async {
    try {
      // If updating time-related fields, check for overlap
      if (checkOverlap && 
          (updates.containsKey('date') || 
           updates.containsKey('start_time') || 
           updates.containsKey('end_time') ||
           updates.containsKey('candidate_id'))) {
        
        // Get current session data
        final currentSession = await getSession(sessionId);
        if (currentSession == null) {
          throw Exception('Session not found');
        }

        // Merge updates with current data
        final candidateId = updates['candidate_id'] ?? currentSession.candidateId;
        final date = updates['date'] is Timestamp 
            ? (updates['date'] as Timestamp).toDate()
            : (updates['date'] ?? currentSession.date);
        final startTime = updates['start_time'] ?? currentSession.startTime;
        final endTime = updates['end_time'] ?? currentSession.endTime;

        final hasOverlap = await _checkSessionOverlap(
          candidateId: candidateId,
          date: date,
          startTime: startTime,
          endTime: endTime,
          excludeSessionId: sessionId,
        );

        if (hasOverlap) {
          throw Exception(
            'This candidate already has a session at this time. '
            'Sessions cannot overlap for the same candidate.'
          );
        }
      }

      await _db.collection('sessions').doc(sessionId).update(updates);
    } catch (e) {
      if (e.toString().contains('overlap')) {
        rethrow; // Rethrow overlap error as-is
      }
      throw Exception('Failed to update session: $e');
    }
  }

  /// Delete a session
  static Future<void> deleteSession(String sessionId) async {
    try {
      await _db.collection('sessions').doc(sessionId).delete();
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }

  /// Delete all sessions
  static Future<void> deleteAllSessions() async {
    try {
      final snapshot = await _db.collection('sessions').get();
      
      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all sessions: $e');
    }
  }

  // ==================== VALIDATION HELPERS ====================

  /// Check if a session overlaps with existing sessions for a candidate
  /// 
  /// Algorithm: Two time ranges overlap if start1 < end2 AND start2 < end1
  /// Example:
  ///   Existing: 9:00-10:00
  ///   New: 9:30-10:30 → OVERLAPS (9:30 < 10:00 AND 9:00 < 10:30)
  ///   New: 10:00-11:00 → NO OVERLAP (10:00 >= 10:00)
  /// 
  /// Returns true if there is an overlap
  static Future<bool> _checkSessionOverlap({
    required String candidateId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? excludeSessionId,
  }) async {
    try {
      // Get all sessions for this candidate on the same day
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _db
          .collection('sessions')
          .where('candidate_id', isEqualTo: candidateId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final existingSessions = snapshot.docs
          .map((doc) => Session.fromFirestore(doc))
          .where((s) => excludeSessionId == null || s.id != excludeSessionId)
          .toList();

      // Convert time strings to minutes for easier comparison
      final newStart = _timeToMinutes(startTime);
      final newEnd = _timeToMinutes(endTime);

      // Check each existing session for overlap
      for (var session in existingSessions) {
        final existingStart = _timeToMinutes(session.startTime);
        final existingEnd = _timeToMinutes(session.endTime);

        // Check if times overlap
        // Two time ranges overlap if: start1 < end2 AND start2 < end1
        if (newStart < existingEnd && existingStart < newEnd) {
          return true; // Overlap found
        }
      }

      return false; // No overlap
    } catch (e) {
      throw Exception('Failed to check session overlap: $e');
    }
  }

  /// Convert time string (HH:mm) to minutes since midnight
  static int _timeToMinutes(String timeString) {
    final parts = timeString.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  /// Convert minutes since midnight to time string (HH:mm)
  static String _minutesToTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  // ==================== STATISTICS ====================

  /// Get database statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final candidatesSnapshot = await _db.collection('candidates').get();
      final sessionsSnapshot = await _db.collection('sessions').get();

      final candidates = candidatesSnapshot.docs
          .map((doc) => Candidate.fromFirestore(doc))
          .toList();

      final sessions = sessionsSnapshot.docs
          .map((doc) => Session.fromFirestore(doc))
          .toList();

      return {
        'totalCandidates': candidates.length,
        'activeCandidates': candidates.where((c) => c.status == 'active').length,
        'graduatedCandidates': candidates.where((c) => c.status == 'graduated').length,
        'inactiveCandidates': candidates.where((c) => c.status == 'inactive').length,
        'totalSessions': sessions.length,
        'scheduledSessions': sessions.where((s) => s.status == 'scheduled').length,
        'doneSessions': sessions.where((s) => s.status == 'done').length,
        'missedSessions': sessions.where((s) => s.status == 'missed').length,
        'rescheduledSessions': sessions.where((s) => s.status == 'rescheduled').length,
        'paidSessions': sessions.where((s) => s.paymentStatus == 'paid').length,
        'unpaidSessions': sessions.where((s) => s.paymentStatus == 'unpaid').length,
      };
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }
}
