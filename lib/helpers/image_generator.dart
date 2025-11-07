import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/structs.dart' as structs;
import '../helpers/download_manager.dart';

class PlanningImageGenerator {
  static Future<void> generateAndShare({
    required BuildContext context,
    required structs.Candidate candidate,
    required List<structs.Session> sessions,
  }) async {
    try {
      // Generate the image
      final imageBytes = await _generatePlanningImage(
        candidateName: candidate.name,
        sessions: sessions,
      );

      // Save to download directory using DownloadManager
      final fileName = 'planning_${candidate.id}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.png';
      final filePath = await DownloadManager.saveFile(fileName, imageBytes);

      // Share via WhatsApp
      await _shareViaWhatsApp(
        context: context,
        filePath: filePath,
        phoneNumber: candidate.phone,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  static Future<Uint8List> _generatePlanningImage({
    required String candidateName,
    required List<structs.Session> sessions,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Image dimensions
    const double width = 1240;
    const double rowHeight = 60.0;
    const double headerHeight = 80.0;
    final double totalHeight = headerHeight * 2 + (sessions.length / 2 * rowHeight) + 40;

    // Background
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, totalHeight), paint);

    // Draw header
    _drawHeader(canvas, candidateName, width, headerHeight);

    // Draw table
    _drawTable(canvas, sessions, width, headerHeight, rowHeight);

    // Convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), totalHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  static void _drawHeader(Canvas canvas, String candidateName, double width, double headerHeight) {
    // Red background
    final headerPaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, headerHeight), headerPaint);

    // Title
    final titlePainter = TextPainter(
      text: TextSpan(
        text: 'Nom et Prénom :   $candidateName',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 42,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(canvas, const Offset(80, 35));
  }

  static void _drawTable(Canvas canvas, List<structs.Session> sessions, double width, double headerHeight, double rowHeight) {
    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final redHeaderPaint = Paint()..color = const Color(0xFFB71C1C);
    final lightBgPaint = Paint()..color = const Color(0xFFF5F5F5);


    // Column widths
    const offset = 20.0;
    const double col1Width = 120; // Date
    const double col2Width = 150; // Séance
    const double col3Width = 300; // Acompte
    final tableWidth = col1Width + col2Width + col3Width;


    double startY = headerHeight + 20;

    // Split sessions into two columns
    final leftSessions = sessions.take((sessions.length / 2).ceil()).toList();
    final rightSessions = sessions.skip(leftSessions.length).toList();
    final maxRows = leftSessions.length > rightSessions.length ? leftSessions.length : rightSessions.length;

    // Draw table headers
    for (int col = 0; col < 2; col++) {
      final startX = col == 0 ? offset : tableWidth + (2 * offset);

      // Draw header cells with red background
      canvas.drawRect(
        Rect.fromLTWH(startX, startY, col1Width, rowHeight),
        redHeaderPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(startX + col1Width, startY, col2Width, rowHeight),
        redHeaderPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(startX + col1Width + col2Width, startY, col3Width, rowHeight),
        redHeaderPaint,
      );

      // Draw header borders
      canvas.drawRect(
        Rect.fromLTWH(startX, startY, tableWidth, rowHeight),
        borderPaint,
      );

      // Draw vertical lines in header
      canvas.drawLine(
        Offset(startX + col1Width, startY),
        Offset(startX + col1Width, startY + rowHeight),
        borderPaint,
      );
      canvas.drawLine(
        Offset(startX + col1Width + col2Width, startY),
        Offset(startX + col1Width + col2Width, startY + rowHeight),
        borderPaint,
      );

      // Header text
      _drawCenteredText(canvas, 'Date', startX, startY, col1Width, rowHeight, Colors.white, 24);
      _drawCenteredText(canvas, 'Séance', startX + col1Width, startY, col2Width, rowHeight, Colors.white, 24);
      _drawCenteredText(canvas, 'Acompte', startX + col1Width + col2Width, startY, col3Width, rowHeight, Colors.white, 24);
    }
    for (int i = 0; i < maxRows; i++) {
      final rowY = startY + (i + 1) * rowHeight;

      // Left column
      if (i < leftSessions.length) {
        final session = leftSessions[i];
        _drawSessionRow(canvas, session, 20.0, rowY, col1Width, col2Width, col3Width, rowHeight, borderPaint, lightBgPaint, i);
      }

      // Right column
      if (i < rightSessions.length) {
        final session = rightSessions[i];
        _drawSessionRow(canvas, session, tableWidth + 2 * offset, rowY, col1Width, col2Width, col3Width, rowHeight, borderPaint, lightBgPaint, i);
      }
    }
  }

  static void _drawSessionRow(Canvas canvas, structs.Session session, double startX, double y,
      double col1Width, double col2Width, double col3Width, double rowHeight,
      Paint borderPaint, Paint lightBgPaint, int index) {

    // Alternate background color
    if (index % 2 == 1) {
      canvas.drawRect(
        Rect.fromLTWH(startX, y, col1Width + col2Width + col3Width, rowHeight),
        lightBgPaint,
      );
    }

    // Draw cell borders
    canvas.drawRect(
      Rect.fromLTWH(startX, y, col1Width + col2Width + col3Width, rowHeight),
      borderPaint,
    );
    canvas.drawLine(
      Offset(startX + col1Width, y),
      Offset(startX + col1Width, y + rowHeight),
      borderPaint,
    );
    canvas.drawLine(
      Offset(startX + col1Width + col2Width, y),
      Offset(startX + col1Width + col2Width, y + rowHeight),
      borderPaint,
    );

    // Date
    final dateStr = DateFormat('dd/MM/yy').format(session.date);
    _drawCenteredText(canvas, dateStr, startX, y, col1Width, rowHeight, Colors.black, 20);

    // Time
    final timeStr = '${session.startTime} - ${session.endTime}';
    _drawCenteredText(canvas, timeStr, startX + col1Width, y, col2Width, rowHeight, Colors.black, 20);

    // Payment status with check/uncheck or amount
    if (session.paymentNote.isNotEmpty) {
      // Divide the column: 80px for check/amount, 220px for note
      const double checkWidth = 80.0;
      const double noteWidth = 220.0;
      final checkX = startX + col1Width + col2Width;
      final noteX = checkX + checkWidth;

      if (session.paymentAmount > 0) {
        // Draw amount in the left part
        final amountStr = '${session.paymentAmount.toStringAsFixed(0)} TND';
        _drawCenteredText(canvas, amountStr, checkX, y, checkWidth, rowHeight,
            const Color(0xFF1B5E20), 22, bold: true);
      } else {
        // Draw check/uncheck mark in the left part
        final isPaid = session.paymentStatus == 'paid';
        final centerX = checkX + checkWidth / 2;
        final centerY = y + rowHeight / 2;

        if (isPaid) {
          _drawCheckMark(canvas, centerX, centerY);
        } else {
          _drawCrossMark(canvas, centerX, centerY);
        }
      }

      // Draw note in the right part (can span 2 lines)
      final notePainter = TextPainter(
        text: TextSpan(
          text: session.paymentNote,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 16,
            fontStyle: FontStyle.italic,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        maxLines: 2,
        ellipsis: '...',
      );
      notePainter.layout(maxWidth: noteWidth - 10);
      
      // Center vertically
      final noteY = y + (rowHeight - notePainter.height) / 2;
      notePainter.paint(canvas, Offset(noteX + 5, noteY));
    } else if (session.paymentAmount > 0) {
      // No note: draw amount centered in full column
      final amountStr = '${session.paymentAmount.toStringAsFixed(0)} TND';
      _drawCenteredText(canvas, amountStr, startX + col1Width + col2Width, y, col3Width, rowHeight,
          const Color(0xFF1B5E20), 20, bold: true);
    } else {
      // No note and no amount: draw check/uncheck mark centered
      final isPaid = session.paymentStatus == 'paid';
      final centerX = startX + col1Width + col2Width + col3Width / 2;
      final centerY = y + rowHeight / 2;

      if (isPaid) {
        _drawCheckMark(canvas, centerX, centerY);
      } else {
        _drawCrossMark(canvas, centerX, centerY);
      }
    }
  }

  static void _drawCenteredText(Canvas canvas, String text, double x, double y,
      double width, double height, Color color, double fontSize, {bool bold = false}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();

    final offsetX = x + (width - textPainter.width) / 2;
    final offsetY = y + (height - textPainter.height) / 2;

    textPainter.paint(canvas, Offset(offsetX, offsetY));
  }

  static void _drawCheckMark(Canvas canvas, double centerX, double centerY) {
    final paint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(centerX - 12, centerY);
    path.lineTo(centerX - 4, centerY + 8);
    path.lineTo(centerX + 12, centerY - 8);

    canvas.drawPath(path, paint);
  }

  static void _drawCrossMark(Canvas canvas, double centerX, double centerY) {
    final paint = Paint()
      ..color = const Color(0xFFE91E63)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(centerX - 10, centerY - 10),
      Offset(centerX + 10, centerY + 10),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + 10, centerY - 10),
      Offset(centerX - 10, centerY + 10),
      paint,
    );
  }

  static Future<void> _shareViaWhatsApp({
    required BuildContext context,
    required String filePath,
    String? phoneNumber,
  }) async {
    try {

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        // Try to open WhatsApp directly with the phone number
        String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
        if (!cleanPhone.startsWith('+')) {
          cleanPhone = '+$cleanPhone';
        }

        await SharePlus.instance.share(
            ShareParams(
            files: [XFile(filePath)],
            text: 'Planning des séances 📅',
            previewThumbnail: XFile(filePath)
          )
        );
        // Then try to open WhatsApp (this might not work on all platforms)
        final whatsappUrl = 'https://wa.me/$cleanPhone';
        final uri = Uri.parse(whatsappUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Just share without specific contact
        await SharePlus.instance.share(
          ShareParams(
              files: [XFile(filePath)],
              text: 'Planning des séances 📅',
              previewThumbnail: XFile(filePath)
          )
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }
}

class InstructorScheduleImageGenerator {
  static Future<void> generateAndShare({
    required BuildContext context,
    required structs.User instructor,
    required List<structs.Session> sessions,
  }) async {
    try {
      // Generate the image
      final imageBytes = await _generateInstructorScheduleImage(
        instructorName: instructor.displayName,
        instructorPhone: instructor.phoneNumber,
        sessions: sessions,
      );

      // Save to download directory using DownloadManager
      final fileName = 'instructor_schedule_${instructor.uid}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.png';
      final filePath = await DownloadManager.saveFile(fileName, imageBytes);

      // Share via WhatsApp
      await _shareViaWhatsApp(
        context: context,
        filePath: filePath,
        phoneNumber: instructor.phoneNumber,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  static Future<Uint8List> _generateInstructorScheduleImage({
    required String instructorName,
    required String instructorPhone,
    required List<structs.Session> sessions,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const maxSessions = 25;
    final limitedSessions = sessions.length > maxSessions ? sessions.sublist(0, maxSessions) : sessions;

    // Image dimensions - single column layout
    const double width = 620;
    const double rowHeight = 60.0;
    const double headerHeight = 120.0;
    final double totalHeight = headerHeight * 2 + (limitedSessions.length * rowHeight) + 80;

    // Background
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, totalHeight), paint);

    // Draw header with instructor info
    _drawInstructorHeader(canvas, instructorName, instructorPhone, width, headerHeight);

    // Draw table
    _drawInstructorTable(canvas, limitedSessions, width, headerHeight, rowHeight);

    // Convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), totalHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  static void _drawInstructorHeader(Canvas canvas, String instructorName, String instructorPhone, double width, double headerHeight) {
    // White background
    final headerPaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, headerHeight), headerPaint);

    // Instructor name
    final namePainter = TextPainter(
      text: TextSpan(
        text: 'Moniteur: $instructorName',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    namePainter.layout();
    namePainter.paint(canvas, const Offset(40, 25));

    // Instructor phone
    final phonePainter = TextPainter(
      text: TextSpan(
        text: 'Téléphone: $instructorPhone',
        style: const TextStyle(
          color: Color(0xFF666666),
          fontSize: 24,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    phonePainter.layout();
    phonePainter.paint(canvas, const Offset(40, 70));
  }

  static void _drawInstructorTable(Canvas canvas, List<structs.Session> sessions, double width, double headerHeight, double rowHeight) {
    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final redHeaderPaint = Paint()..color = const Color(0xFFB71C1C);
    final lightBgPaint = Paint()..color = const Color(0xFFF5F5F5);

    // Column widths for single column layout
    const double offset = 20.0;
    const double col1Width = 120; // Date
    const double col2Width = 150; // Séance
    const double col3Width = 290; // Note
    final double tableWidth = col1Width + col2Width + col3Width;

    double startY = headerHeight + 20;

    // Draw table header
    canvas.drawRect(
      Rect.fromLTWH(offset, startY, col1Width, rowHeight),
      redHeaderPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(offset + col1Width, startY, col2Width, rowHeight),
      redHeaderPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(offset + col1Width + col2Width, startY, col3Width, rowHeight),
      redHeaderPaint,
    );

    // Draw header borders
    canvas.drawRect(
      Rect.fromLTWH(offset, startY, tableWidth, rowHeight),
      borderPaint,
    );

    // Draw vertical lines in header
    canvas.drawLine(
      Offset(offset + col1Width, startY),
      Offset(offset + col1Width, startY + rowHeight),
      borderPaint,
    );
    canvas.drawLine(
      Offset(offset + col1Width + col2Width, startY),
      Offset(offset + col1Width + col2Width, startY + rowHeight),
      borderPaint,
    );

    // Header text
    _drawCenteredText(canvas, 'Date', offset, startY, col1Width, rowHeight, Colors.white, 24);
    _drawCenteredText(canvas, 'Séance', offset + col1Width, startY, col2Width, rowHeight, Colors.white, 24);
    _drawCenteredText(canvas, 'Note', offset + col1Width + col2Width, startY, col3Width, rowHeight, Colors.white, 24);

    // Draw session rows
    for (int i = 0; i < sessions.length; i++) {
      final rowY = startY + (i + 1) * rowHeight;
      final session = sessions[i];
      _drawInstructorSessionRow(canvas, session, offset, rowY, col1Width, col2Width, col3Width, rowHeight, borderPaint, lightBgPaint, i);
    }
  }

  static void _drawInstructorSessionRow(Canvas canvas, structs.Session session, double startX, double y,
      double col1Width, double col2Width, double col3Width, double rowHeight,
      Paint borderPaint, Paint lightBgPaint, int index) {

    // Alternate background color
    if (index % 2 == 1) {
      canvas.drawRect(
        Rect.fromLTWH(startX, y, col1Width + col2Width + col3Width, rowHeight),
        lightBgPaint,
      );
    }

    // Draw cell borders
    canvas.drawRect(
      Rect.fromLTWH(startX, y, col1Width + col2Width + col3Width, rowHeight),
      borderPaint,
    );
    canvas.drawLine(
      Offset(startX + col1Width, y),
      Offset(startX + col1Width, y + rowHeight),
      borderPaint,
    );
    canvas.drawLine(
      Offset(startX + col1Width + col2Width, y),
      Offset(startX + col1Width + col2Width, y + rowHeight),
      borderPaint,
    );

    // Date
    final dateStr = DateFormat('dd/MM/yy').format(session.date);
    _drawCenteredText(canvas, dateStr, startX, y, col1Width, rowHeight, Colors.black, 20);

    // Time
    final timeStr = '${session.startTime} - ${session.endTime}';
    _drawCenteredText(canvas, timeStr, startX + col1Width, y, col2Width, rowHeight, Colors.black, 20);

    // Note
    final note = session.note.isNotEmpty ? session.note : '-';
    _drawLeftAlignedText(canvas, note, startX + col1Width + col2Width, y, col3Width, rowHeight, const Color(0xFF666666), 18);
  }

  static void _drawCenteredText(Canvas canvas, String text, double x, double y,
      double width, double height, Color color, double fontSize, {bool bold = false}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();

    final offsetX = x + (width - textPainter.width) / 2;
    final offsetY = y + (height - textPainter.height) / 2;

    textPainter.paint(canvas, Offset(offsetX, offsetY));
  }

  static void _drawLeftAlignedText(Canvas canvas, String text, double x, double y,
      double width, double height, Color color, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    );
    textPainter.layout(maxWidth: width - 10);

    final offsetY = y + (height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(x + 5, offsetY));
  }

  static const String _scheduleShareText = 'Emploi du temps 📅';

  static Future<void> _shareViaWhatsApp({
    required BuildContext context,
    required String filePath,
    String? phoneNumber,
  }) async {
    try {
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        // Try to open WhatsApp directly with the phone number
        String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
        if (!cleanPhone.startsWith('+')) {
          cleanPhone = '+$cleanPhone';
        }

        await SharePlus.instance.share(
            ShareParams(
            files: [XFile(filePath)],
            text: _scheduleShareText,
            previewThumbnail: XFile(filePath)
          )
        );
        // Then try to open WhatsApp (this might not work on all platforms)
        final whatsappUrl = 'https://wa.me/$cleanPhone';
        final uri = Uri.parse(whatsappUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Just share without specific contact
        await SharePlus.instance.share(
          ShareParams(
              files: [XFile(filePath)],
              text: _scheduleShareText,
              previewThumbnail: XFile(filePath)
          )
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }
}
