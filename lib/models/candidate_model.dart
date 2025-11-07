part of 'structs.dart';

class TimeSlot {
  final String startTime;
  final String endTime;

  TimeSlot({
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      startTime: map['start_time'] ?? '',
      endTime: map['end_time'] ?? '',
    );
  }
}

class Candidate {
  final String id;
  final String name;
  final String phone;
  final String cin;
  final DateTime startDate;
  final bool theoryPassed;
  final double totalPaidHours;
  final double totalTakenHours;
  final String notes;
  final String assignedInstructorId;
  final String status; // 'active', 'graduated', 'inactive'
  final Map<String, List<TimeSlot>> availability;
  final DateTime? examDate; // Date of the driving exam

  Candidate({
    required this.id,
    required this.name,
    required this.phone,
    this.cin = '',
    required this.startDate,
    this.theoryPassed = false,
    this.totalPaidHours = 0.0,
    this.totalTakenHours = 0.0,
    this.notes = '',
    this.assignedInstructorId = '',
    this.status = 'active',
    this.availability = const {},
    this.examDate,
  });

  // Factory method to create a Candidate from Firestore document
  factory Candidate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse availability schedule
    Map<String, List<TimeSlot>> availability = {};
    if (data['availability'] != null) {
      final availabilityData = data['availability'] as Map<String, dynamic>;
      availabilityData.forEach((day, slots) {
        if (slots is List) {
          availability[day] = slots.map((slot) => TimeSlot.fromMap(slot as Map<String, dynamic>)).toList();
        }
      });
    }
    
    return Candidate(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      cin: data['cin'] ?? '',
      startDate: (data['start_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      theoryPassed: data['theory_passed'] ?? false,
      totalPaidHours: (data['total_paid_hours'] ?? 0.0).toDouble(),
      totalTakenHours: (data['total_taken_hours'] ?? 0.0).toDouble(),
      notes: data['notes'] ?? '',
      assignedInstructorId: data['assigned_instructor_id'] ?? '',
      status: data['status'] ?? 'active',
      availability: availability,
      examDate: (data['exam_date'] as Timestamp?)?.toDate(),
    );
  }

  // Method to convert Candidate to Firestore document
  Map<String, dynamic> toFirestore() {
    // Convert availability to Map
    Map<String, dynamic> availabilityMap = {};
    availability.forEach((day, slots) {
      availabilityMap[day] = slots.map((slot) => slot.toMap()).toList();
    });
    
    return {
      'name': name,
      'phone': phone,
      'cin': cin,
      'start_date': Timestamp.fromDate(startDate),
      'theory_passed': theoryPassed,
      'total_paid_hours': totalPaidHours,
      'total_taken_hours': totalTakenHours,
      'notes': notes,
      'assigned_instructor_id': assignedInstructorId,
      'status': status,
      'availability': availabilityMap,
      'exam_date': examDate != null ? Timestamp.fromDate(examDate!) : null,
    };
  }

  // Calculate progress percentage
  double get progressPercentage {
    if (totalPaidHours == 0) return 0.0;
    return (totalTakenHours / totalPaidHours * 100).clamp(0.0, 100.0);
  }

  // Get remaining hours
  double get remainingHours {
    return (totalPaidHours - totalTakenHours).clamp(0.0, double.infinity);
  }
}
