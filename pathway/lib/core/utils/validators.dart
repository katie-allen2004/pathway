typedef FieldValidator = String? Function(String? value);

class AppValidators {

  static String? isNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName cannot be empty.';
    }
    return null;
  }

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


  static String? isValidPassword(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters long.';
    }
    return null;
  }

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