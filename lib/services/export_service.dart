import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/structs.dart' as structs;
import 'instructor_service.dart';
import '../helpers/download_manager.dart';

class ExportService {
  static Future<String> exportCandidatesToCSV() async {
    final candidates = await FirebaseFirestore.instance
        .collection('candidates')
        .get()
        .then((snapshot) => snapshot.docs
            .map((doc) => structs.Candidate.fromFirestore(doc))
            .toList());

    final csv = StringBuffer();
    // Header
    csv.writeln('ID,Name,Phone,CIN,Start Date,Theory Passed,Total Paid Hours,Total Taken Hours,Remaining Hours,Assigned Instructor,Status,Notes');
    
    // Data rows
    for (var candidate in candidates) {
      csv.writeln(
        '${candidate.id},'
        '"${candidate.name}",'
        '${candidate.phone},'
        '${candidate.cin},'
        '${DateFormat('dd/MM/yyyy').format(candidate.startDate)},'
        '${candidate.theoryPassed ? "Yes" : "No"},'
        '${candidate.totalPaidHours},'
        '${candidate.totalTakenHours},'
        '${candidate.remainingHours},'
        '"${InstructorService().getInstructorName(candidate.assignedInstructorId)}",'
        '${candidate.status},'
        '"${candidate.notes.replaceAll('"', '""')}"'
      );
    }

    return _saveToFile('candidates', csv.toString());
  }

  static Future<String> exportSessionsToCSV() async {
    final sessions = await FirebaseFirestore.instance
        .collection('sessions')
        .orderBy('date', descending: true)
        .get()
        .then((snapshot) => snapshot.docs
            .map((doc) => structs.Session.fromFirestore(doc))
            .toList());

    final csv = StringBuffer();
    // Header
    csv.writeln('ID,Candidate ID,Instructor ID,Date,Start Time,End Time,Duration (hours),Status,Payment Status,Note');
    
    // Data rows
    for (var session in sessions) {
      csv.writeln(
        '${session.id},'
        '${session.candidateId},'
        '${session.instructorId},'
        '${DateFormat('dd/MM/yyyy').format(session.date)},'
        '${session.startTime},'
        '${session.endTime},'
        '${session.durationInHours.toStringAsFixed(2)},'
        '${session.status},'
        '${session.paymentStatus},'
        '"${session.note.replaceAll('"', '""')}"'
      );
    }

    return _saveToFile('sessions', csv.toString());
  }

  static Future<Map<String, String>> exportAllDataToCSV() async {
    final candidatesPath = await exportCandidatesToCSV();
    final sessionsPath = await exportSessionsToCSV();
    
    return {
      'candidatesPath': candidatesPath,
      'sessionsPath': sessionsPath,
    };
  }

  static Future<String> _saveToFile(String name, String content) async {
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = '${name}_$timestamp.csv';
      
      // Use DownloadManager to save to platform-specific download directory
      final filePath = await DownloadManager.saveTextFile(fileName, content);
      return filePath;
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }
}
