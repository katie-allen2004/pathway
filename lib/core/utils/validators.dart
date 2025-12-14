// The typedef defines a function signature for a validator. 
// It takes a String? (the input value) and returns a String? (the error message, or null if valid).
typedef FieldValidator = String? Function(String? value);

class AppValidators {
  // =========================================================
  // 1. Basic Empty Check
  // =========================================================
  static String? isNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName cannot be empty.';
    }
    return null;
  }

  // =========================================================
  // 2. Email Validation
  // Uses a common regex pattern for basic email format validation.
  // =========================================================
  static String? isValidEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required.';
    }
    // A simple, common email regex pattern
    final bool emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(value);

    if (!emailValid) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  // =========================================================
  // 3. Password Validation
  // Checks for a minimum length. (You can add complexity checks later).
  // =========================================================
  static String? isValidPassword(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters long.';
    }
    return null;
  }

  // =========================================================
  // 4. Password Confirmation Check
  // Compares the confirmation field against the original password field.
  // =========================================================
  static String? isConfirmedPassword(String? confirmValue, String originalPassword) {
    if (confirmValue == null || confirmValue.isEmpty) {
      return 'Please confirm your password.';
    }
    if (confirmValue != originalPassword) {
      return 'Passwords do not match.';
    }
    return null;
  }
}