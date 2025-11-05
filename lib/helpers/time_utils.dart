/// Utility functions for time parsing and conversion
class TimeUtils {
  /// Convert time string (HH:mm) to minutes since midnight
  /// Returns 0 for invalid time strings
  /// 
  /// Examples:
  ///   "09:00" -> 540
  ///   "14:30" -> 870
  ///   "invalid" -> 0
  static int timeToMinutes(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return 0;
      
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      
      // Validate ranges
      if (hours < 0 || hours > 23) return 0;
      if (minutes < 0 || minutes > 59) return 0;
      
      return hours * 60 + minutes;
    } catch (e) {
      // Return 0 for invalid time strings
      return 0;
    }
  }

  /// Convert minutes since midnight to time string (HH:mm)
  /// 
  /// Examples:
  ///   540 -> "09:00"
  ///   870 -> "14:30"
  static String minutesToTime(int minutes) {
    final hours = (minutes ~/ 60) % 24; // Ensure 24-hour wrap
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  /// Validate if a time string is in valid format (HH:mm)
  /// 
  /// Returns true if:
  /// - Format is HH:mm
  /// - Hours are 0-23
  /// - Minutes are 0-59
  static bool isValidTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return false;
      
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      
      return hours >= 0 && hours <= 23 && minutes >= 0 && minutes <= 59;
    } catch (e) {
      return false;
    }
  }
}
