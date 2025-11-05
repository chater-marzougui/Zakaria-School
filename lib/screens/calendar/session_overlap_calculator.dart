import '../../models/structs.dart' as structs;
import '../../helpers/time_utils.dart';

class SessionOverlap {
  final int columnIndex;
  final int totalColumns;

  SessionOverlap({
    required this.columnIndex,
    required this.totalColumns,
  });
}

class SessionOverlapCalculator {
  /// Calculate overlap information for all sessions
  /// This determines how to position sessions side-by-side when they overlap
  static List<SessionOverlap> calculateOverlaps(List<structs.Session> sessions) {
    if (sessions.isEmpty) return [];
    
    // Sort sessions by start time
    final sortedSessions = List<structs.Session>.from(sessions)
      ..sort((a, b) {
        final aStart = TimeUtils.timeToMinutes(a.startTime);
        final bStart = TimeUtils.timeToMinutes(b.startTime);
        return aStart.compareTo(bStart);
      });
    
    final overlaps = <SessionOverlap>[];
    final groups = <List<int>>[];
    
    // Group overlapping sessions
    for (int i = 0; i < sortedSessions.length; i++) {
      final currentSession = sortedSessions[i];
      final currentStart = TimeUtils.timeToMinutes(currentSession.startTime);
      final currentEnd = TimeUtils.timeToMinutes(currentSession.endTime);
      
      // Find which group this session belongs to
      int? groupIndex;
      for (int g = 0; g < groups.length; g++) {
        bool overlapsWithGroup = false;
        
        for (int memberIndex in groups[g]) {
          final member = sortedSessions[memberIndex];
          final memberStart = TimeUtils.timeToMinutes(member.startTime);
          final memberEnd = TimeUtils.timeToMinutes(member.endTime);
          
          // Check if sessions overlap (even partially)
          if (_doSessionsOverlap(currentStart, currentEnd, memberStart, memberEnd)) {
            overlapsWithGroup = true;
            break;
          }
        }
        
        if (overlapsWithGroup) {
          groupIndex = g;
          break;
        }
      }
      
      // Add to existing group or create new one
      if (groupIndex != null) {
        groups[groupIndex].add(i);
      } else {
        groups.add([i]);
      }
    }
    
    // Calculate column positions for each session
    for (int i = 0; i < sortedSessions.length; i++) {
      // Find which group this session belongs to
      int groupIndex = 0;
      int positionInGroup = 0;
      int groupSize = 1;
      
      for (int g = 0; g < groups.length; g++) {
        if (groups[g].contains(i)) {
          groupIndex = g;
          positionInGroup = groups[g].indexOf(i);
          groupSize = groups[g].length;
          break;
        }
      }
      
      overlaps.add(SessionOverlap(
        columnIndex: positionInGroup,
        totalColumns: groupSize,
      ));
    }
    
    // Map back to original order
    final result = List<SessionOverlap>.filled(sessions.length, SessionOverlap(columnIndex: 0, totalColumns: 1));
    for (int i = 0; i < sortedSessions.length; i++) {
      final originalIndex = sessions.indexOf(sortedSessions[i]);
      result[originalIndex] = overlaps[i];
    }
    
    return result;
  }
  
  static bool _doSessionsOverlap(int start1, int end1, int start2, int end2) {
    // Sessions overlap if one starts before the other ends
    return (start1 < end2 && start2 < end1);
  }
}