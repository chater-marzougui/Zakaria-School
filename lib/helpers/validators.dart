/// Validation utilities for form fields
class Validators {
  // Regular expression for validating CIN (8 digits)
  static final RegExp _cinRegex = RegExp(r'^\d+$');
  // Regular expression for removing non-digit characters
  static final RegExp _nonDigitRegex = RegExp(r'\D');
  
  /// Validates phone number format
  /// Returns error message if invalid, null if valid
  static String? validatePhone(String? value, {required String errorMessage}) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage;
    }
    // Basic phone validation (at least 8 digits)
    if (value.replaceAll(_nonDigitRegex, '').length < 8) {
      return errorMessage;
    }
    return null;
  }

  /// Validates CIN (National ID) format
  /// Returns error message if invalid, null if valid
  /// CIN is optional, so empty values are valid
  static String? validateCIN(String? value, {required String errorMessage}) {
    if (value != null && value.isNotEmpty) {
      if (value.length != 8 || !_cinRegex.hasMatch(value)) {
        return errorMessage;
      }
    }
    return null;
  }

  /// Validates required text field
  /// Returns error message if empty, null if valid
  static String? validateRequired(String? value, {required String errorMessage}) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage;
    }
    return null;
  }
}
