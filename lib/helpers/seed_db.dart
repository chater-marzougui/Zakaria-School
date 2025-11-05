import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/structs.dart';

class TestDataGenerator {
  static final Random _random = Random();

  // Sample data for generating realistic test data
  static final List<String> _firstNames = [
    'Ahmed', 'Fatma', 'Mohamed', 'Amira', 'Youssef', 'Leila',
    'Omar', 'Salma', 'Karim', 'Nour', 'Hassan', 'Mariem',
    'Ali', 'Sarra', 'Mehdi', 'Ines', 'Bilel', 'Hana'
  ];

  static final List<String> _lastNames = [
    'Ben Ali', 'Trabelsi', 'Jebali', 'Hmida', 'Bouazizi',
    'Khedher', 'Sassi', 'Gharbi', 'Mabrouk', 'Khaldi',
    'Mejri', 'Oueslati', 'Dridi', 'Chebbi', 'Mansour'
  ];

  static final List<String> _instructorIds = [
    'instructor_001', 'instructor_002', 'instructor_003'
  ];

  static final List<String> _statuses = ['active', 'graduated', 'inactive'];
  static final List<String> _sessionStatuses = ['scheduled', 'done', 'missed', 'rescheduled'];

  static final List<String> _notes = [
    'Good progress, needs more practice on parallel parking',
    'Excellent student, very attentive',
    'Needs to work on highway driving',
    'Doing well with city driving',
    'Ready for exam soon',
    'Improving steadily',
    'Confident driver, needs minor adjustments',
    'Nervous at first, getting better',
    ''
  ];

  /// Main function to ensure minimum test data exists
  static Future<void> ensureTestData() async {
    try {
      print('🔍 Checking existing data...');

      // Check candidates count
      final candidatesSnapshot = await FirebaseFirestore.instance
          .collection('candidates')
          .get();

      final candidatesCount = candidatesSnapshot.docs.length;
      print('   Found $candidatesCount candidates');

      // Check sessions count
      final sessionsSnapshot = await FirebaseFirestore.instance
          .collection('sessions')
          .get();

      final sessionsCount = sessionsSnapshot.docs.length;
      print('   Found $sessionsCount sessions');

      // Create candidates if needed
      List<String> candidateIds = candidatesSnapshot.docs.map((doc) => doc.id).toList();

      if (candidatesCount < 21) {
        print('\n📝 Creating ${21 - candidatesCount} candidates...');
        final newIds = await createCandidates(21 - candidatesCount);
        candidateIds.addAll(newIds);
        print('   ✅ Candidates created successfully');
      } else {
        print('   ✅ Sufficient candidates exist');
      }

      // Create sessions if needed
      if (sessionsCount < 180) {
        print('\n📅 Creating ${180 - sessionsCount} sessions...');
        await createSessions(180 - sessionsCount, candidateIds);
        print('   ✅ Sessions created successfully');
      } else {
        print('   ✅ Sufficient sessions exist');
      }

      print('\n🎉 Test data setup complete!');
      print('   Total candidates: ${candidateIds.length}');
      print('   Total sessions: ${sessionsCount < 180 ? 180 : sessionsCount}');

    } catch (e) {
      print('❌ Error ensuring test data: $e');
      rethrow;
    }
  }

  /// Create fake candidates
  static Future<List<String>> createCandidates(int count) async {
    final List<String> createdIds = [];
    final batch = FirebaseFirestore.instance.batch();

    for (int i = 0; i < count; i++) {
      final candidateRef = FirebaseFirestore.instance.collection('candidates').doc();

      final candidate = _generateCandidate(candidateRef.id);
      batch.set(candidateRef, candidate.toFirestore());
      createdIds.add(candidateRef.id);

      print('   - Creating: ${candidate.name}');
    }

    await batch.commit();
    return createdIds;
  }

  /// Create fake sessions
  static Future<void> createSessions(int count, List<String> candidateIds) async {
    if (candidateIds.isEmpty) {
      print('   ⚠️  No candidates available to create sessions');
      return;
    }

    final batch = FirebaseFirestore.instance.batch();
    final now = DateTime.now();

    for (int i = 0; i < count; i++) {
      final sessionRef = FirebaseFirestore.instance.collection('sessions').doc();

      // Distribute sessions across past, present, and future
      final daysOffset = _random.nextInt(60) - 30; // -30 to +30 days
      final sessionDate = now.add(Duration(days: daysOffset));

      final session = _generateSession(
        sessionRef.id,
        candidateIds[_random.nextInt(candidateIds.length)],
        sessionDate,
      );

      batch.set(sessionRef, session.toFirestore());

      final dateStr = '${sessionDate.day}/${sessionDate.month}/${sessionDate.year}';
      print('   - Creating session on $dateStr at ${session.startTime}');
    }

    await batch.commit();
  }

  /// Generate a random candidate
  static Candidate _generateCandidate(String id) {
    final name = '${_firstNames[_random.nextInt(_firstNames.length)]} ${_lastNames[_random.nextInt(_lastNames.length)]}';
    final phone = '+216 ${20 + _random.nextInt(79)} ${_random.nextInt(900) + 100} ${_random.nextInt(900) + 100}';
    final cin = '${_random.nextInt(90000000) + 10000000}'; // 8-digit CIN

    // Random start date within last 6 months
    final startDate = DateTime.now().subtract(Duration(days: _random.nextInt(180)));

    final theoryPassed = _random.nextBool();
    final status = _statuses[_random.nextInt(_statuses.length)];

    // Generate realistic hours and balance
    final totalPaidHours = (_random.nextInt(30) + 10).toDouble(); // 10-40 hours
    final totalTakenHours = (_random.nextDouble() * totalPaidHours).clamp(0, totalPaidHours);
    final balance = (_random.nextInt(500) - 200).toDouble(); // -200 to +300

    return Candidate(
      id: id,
      name: name,
      phone: phone,
      cin: cin,
      startDate: startDate,
      theoryPassed: theoryPassed,
      totalPaidHours: totalPaidHours,
      totalTakenHours: double.parse(totalTakenHours.toStringAsFixed(1)),
      balance: balance,
      notes: _notes[_random.nextInt(_notes.length)],
      assignedInstructor: _instructorIds[_random.nextInt(_instructorIds.length)],
      status: status,
    );
  }

  /// Generate a random session
  static Session _generateSession(String id, String candidateId, DateTime date) {
    // Generate realistic time slots (8 AM to 6 PM)
    final startHour = 8 + _random.nextInt(9); // 8-16
    final startMinute = _random.nextBool() ? 0 : 30;
    final duration = _random.nextBool() ? 1.0 : 1.5; // 1 or 1.5 hours

    final startTime = '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';

    final endHour = startHour + duration.toInt();
    final endMinute = startMinute + ((duration % 1) * 60).toInt();
    final endTime = '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

    // Status based on date
    String status;
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      // Past sessions - mostly done, some missed
      status = _random.nextDouble() < 0.85 ? 'done' : 'missed';
    } else if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      // Future sessions - scheduled
      status = 'scheduled';
    } else {
      // Today's sessions - random
      status = _sessionStatuses[_random.nextInt(_sessionStatuses.length)];
    }

    final paymentStatus = status == 'done'
        ? (_random.nextDouble() < 0.7 ? 'paid' : 'unpaid')
        : 'unpaid';

    return Session(
      id: id,
      candidateId: candidateId,
      instructorId: _instructorIds[_random.nextInt(_instructorIds.length)],
      date: date,
      startTime: startTime,
      endTime: endTime,
      status: status,
      note: _random.nextBool() ? _notes[_random.nextInt(_notes.length)] : '',
      paymentStatus: paymentStatus,
    );
  }

  /// Clear all test data (use with caution!)
  static Future<void> clearAllData() async {
    print('⚠️  Clearing all test data...');

    // Delete all candidates
    final candidatesSnapshot = await FirebaseFirestore.instance
        .collection('candidates')
        .get();

    final candidatesBatch = FirebaseFirestore.instance.batch();
    for (var doc in candidatesSnapshot.docs) {
      candidatesBatch.delete(doc.reference);
    }
    await candidatesBatch.commit();
    print('   ✅ Deleted ${candidatesSnapshot.docs.length} candidates');

    // Delete all sessions
    final sessionsSnapshot = await FirebaseFirestore.instance
        .collection('sessions')
        .get();

    final sessionsBatch = FirebaseFirestore.instance.batch();
    for (var doc in sessionsSnapshot.docs) {
      sessionsBatch.delete(doc.reference);
    }
    await sessionsBatch.commit();
    print('   ✅ Deleted ${sessionsSnapshot.docs.length} sessions');

    print('🗑️  All data cleared!');
  }

  /// Get statistics about current data
  static Future<Map<String, dynamic>> getDataStats() async {
    final candidatesSnapshot = await FirebaseFirestore.instance
        .collection('candidates')
        .get();

    final sessionsSnapshot = await FirebaseFirestore.instance
        .collection('sessions')
        .get();

    final candidates = candidatesSnapshot.docs
        .map((doc) => Candidate.fromFirestore(doc))
        .toList();

    final activeCandidates = candidates.where((c) => c.status == 'active').length;
    final graduatedCandidates = candidates.where((c) => c.status == 'graduated').length;
    final inactiveCandidates = candidates.where((c) => c.status == 'inactive').length;

    final sessions = sessionsSnapshot.docs
        .map((doc) => Session.fromFirestore(doc))
        .toList();

    final scheduledSessions = sessions.where((s) => s.status == 'scheduled').length;
    final doneSessions = sessions.where((s) => s.status == 'done').length;
    final missedSessions = sessions.where((s) => s.status == 'missed').length;

    return {
      'totalCandidates': candidates.length,
      'activeCandidates': activeCandidates,
      'graduatedCandidates': graduatedCandidates,
      'inactiveCandidates': inactiveCandidates,
      'totalSessions': sessions.length,
      'scheduledSessions': scheduledSessions,
      'doneSessions': doneSessions,
      'missedSessions': missedSessions,
    };
  }
}