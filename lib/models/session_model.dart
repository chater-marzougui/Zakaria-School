part of 'structs.dart';

class Session {
  final String id;
  final String candidateId;
  final String instructorId;
  final DateTime date;
  final String startTime; // Format: "HH:mm"
  final String endTime; // Format: "HH:mm"
  final String status; // 'scheduled', 'done', 'missed', 'rescheduled'
  final String note;
  final String paymentStatus; // 'paid', 'unpaid'

  Session({
    required this.id,
    required this.candidateId,
    required this.instructorId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.status = 'scheduled',
    this.note = '',
    this.paymentStatus = 'unpaid',
  });

  // Factory method to create a Session from Firestore document
  factory Session.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Session(
      id: doc.id,
      candidateId: data['candidate_id'] ?? '',
      instructorId: data['instructor_id'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: data['start_time'] ?? '00:00',
      endTime: data['end_time'] ?? '00:00',
      status: data['status'] ?? 'scheduled',
      note: data['note'] ?? '',
      paymentStatus: data['payment_status'] ?? 'unpaid',
    );
  }

  // Method to convert Session to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'candidate_id': candidateId,
      'instructor_id': instructorId,
      'date': Timestamp.fromDate(date),
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'note': note,
      'payment_status': paymentStatus,
    };
  }

  // Calculate session duration in hours
  double get durationInHours {
    try {
      final start = _parseTime(startTime);
      final end = _parseTime(endTime);
      final diff = end.difference(start);
      return diff.inMinutes / 60.0;
    } catch (e) {
      return 0.0;
    }
  }

  DateTime _parseTime(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }
}
