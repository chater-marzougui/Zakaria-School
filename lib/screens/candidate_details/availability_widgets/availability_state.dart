import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../models/structs.dart' as structs;

/// Manages the availability state and data operations
class AvailabilityState extends ChangeNotifier {
  final String candidateId;
  Map<String, List<structs.TimeSlot>> _workingAvailability;
  bool _hasChanges = false;

  AvailabilityState({
    required this.candidateId,
    required Map<String, List<structs.TimeSlot>> initialAvailability,
  }) : _workingAvailability = _deepCopyAvailability(initialAvailability);

  Map<String, List<structs.TimeSlot>> get availability => _workingAvailability;
  bool get hasChanges => _hasChanges;

  static Map<String, List<structs.TimeSlot>> _deepCopyAvailability(
      Map<String, List<structs.TimeSlot>> original) {
    final copy = <String, List<structs.TimeSlot>>{};
    original.forEach((key, value) {
      copy[key] = value
          .map((slot) => structs.TimeSlot(
                startTime: slot.startTime,
                endTime: slot.endTime,
              ))
          .toList();
    });
    return copy;
  }

  /// Reload data from Firestore
  Future<void> reloadFromFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('candidates')
          .doc(candidateId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data == null) return;

        Map<String, List<structs.TimeSlot>> availability = {};

        if (data['availability'] != null && data['availability'] is Map) {
          final availabilityData = data['availability'] as Map<String, dynamic>;
          availabilityData.forEach((day, slots) {
            if (slots is List) {
              availability[day] = slots
                  .map((slot) {
                    if (slot is Map<String, dynamic>) {
                      return structs.TimeSlot.fromMap(slot);
                    }
                    return null;
                  })
                  .whereType<structs.TimeSlot>()
                  .toList();
            }
          });
        }

        _workingAvailability = availability;
        _hasChanges = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to reload candidate data: $e');
    }
  }

  /// Save changes to Firestore
  Future<void> saveChanges() async {
    Map<String, dynamic> availabilityMap = {};
    _workingAvailability.forEach((day, slots) {
      availabilityMap[day] = slots.map((slot) => slot.toMap()).toList();
    });

    await FirebaseFirestore.instance
        .collection('candidates')
        .doc(candidateId)
        .update({'availability': availabilityMap});

    _hasChanges = false;
    notifyListeners();
  }

  /// Add or merge a time slot
  void addTimeSlot(String dayKey, String startTime, String endTime) {
    final startMinutes = _timeStringToMinutes(startTime);
    final endMinutes = _timeStringToMinutes(endTime);
    _mergeSlots(dayKey, startMinutes, endMinutes);
    _hasChanges = true;
    notifyListeners();
  }

  /// Remove a time slot
  void removeTimeSlot(String dayKey, structs.TimeSlot slot) {
    _workingAvailability[dayKey]?.removeWhere(
        (s) => s.startTime == slot.startTime && s.endTime == slot.endTime);
    if (_workingAvailability[dayKey]?.isEmpty ?? false) {
      _workingAvailability.remove(dayKey);
    }
    _hasChanges = true;
    notifyListeners();
  }

  /// Move a time slot
  void moveTimeSlot(String fromDayKey, structs.TimeSlot slot, String toDayKey,
      int newStartMinutes) {
    final startMinutes = _timeStringToMinutes(slot.startTime);
    final endMinutes = _timeStringToMinutes(slot.endTime);
    final duration = endMinutes - startMinutes;
    final newEndMinutes = newStartMinutes + duration;

    // Ensure the slot stays within bounds
    if (newStartMinutes < 8 * 60 || newEndMinutes > 20 * 60) {
      return;
    }

    // Remove from old location
    _workingAvailability[fromDayKey]?.removeWhere(
        (s) => s.startTime == slot.startTime && s.endTime == slot.endTime);
    if (_workingAvailability[fromDayKey]?.isEmpty ?? false) {
      _workingAvailability.remove(fromDayKey);
    }

    // Add to new location (with merging)
    _mergeSlots(toDayKey, newStartMinutes, newEndMinutes);
    _hasChanges = true;
    notifyListeners();
  }

  /// Merge overlapping or touching slots
  void _mergeSlots(String dayKey, int startMinutes, int endMinutes) {
    final slots = _workingAvailability[dayKey] ?? [];
    final toRemove = <structs.TimeSlot>[];
    int mergedStart = startMinutes;
    int mergedEnd = endMinutes;

    for (var slot in slots) {
      final slotStart = _timeStringToMinutes(slot.startTime);
      final slotEnd = _timeStringToMinutes(slot.endTime);

      if (mergedStart <= slotEnd && mergedEnd >= slotStart) {
        mergedStart = mergedStart < slotStart ? mergedStart : slotStart;
        mergedEnd = mergedEnd > slotEnd ? mergedEnd : slotEnd;
        toRemove.add(slot);
      }
    }

    // Remove old slots
    for (var slot in toRemove) {
      _workingAvailability[dayKey]?.removeWhere(
          (s) => s.startTime == slot.startTime && s.endTime == slot.endTime);
    }

    // Add merged slot
    if (!_workingAvailability.containsKey(dayKey)) {
      _workingAvailability[dayKey] = [];
    }
    _workingAvailability[dayKey]!.add(
      structs.TimeSlot(
        startTime: _minutesToTimeString(mergedStart),
        endTime: _minutesToTimeString(mergedEnd),
      ),
    );
  }

  /// Snap minutes to 15-minute intervals
  int snapToQuarterHour(int minutes) {
    return (minutes / 15).round() * 15;
  }

  String _minutesToTimeString(int minutes) {
    final hours = (minutes ~/ 60).clamp(0, 23);
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  int _timeStringToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
