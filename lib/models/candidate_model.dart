part of 'structs.dart';

class Candidate {
  final String id;
  final String name;
  final String phone;
  final DateTime startDate;
  final bool theoryPassed;
  final double totalPaidHours;
  final double totalTakenHours;
  final double balance;
  final String notes;
  final String assignedInstructor;
  final String status; // 'active', 'graduated', 'inactive'

  Candidate({
    required this.id,
    required this.name,
    required this.phone,
    required this.startDate,
    this.theoryPassed = false,
    this.totalPaidHours = 0.0,
    this.totalTakenHours = 0.0,
    this.balance = 0.0,
    this.notes = '',
    this.assignedInstructor = '',
    this.status = 'active',
  });

  // Factory method to create a Candidate from Firestore document
  factory Candidate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Candidate(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      startDate: (data['start_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      theoryPassed: data['theory_passed'] ?? false,
      totalPaidHours: (data['total_paid_hours'] ?? 0.0).toDouble(),
      totalTakenHours: (data['total_taken_hours'] ?? 0.0).toDouble(),
      balance: (data['balance'] ?? 0.0).toDouble(),
      notes: data['notes'] ?? '',
      assignedInstructor: data['assigned_instructor'] ?? '',
      status: data['status'] ?? 'active',
    );
  }

  // Method to convert Candidate to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'start_date': Timestamp.fromDate(startDate),
      'theory_passed': theoryPassed,
      'total_paid_hours': totalPaidHours,
      'total_taken_hours': totalTakenHours,
      'balance': balance,
      'notes': notes,
      'assigned_instructor': assignedInstructor,
      'status': status,
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
