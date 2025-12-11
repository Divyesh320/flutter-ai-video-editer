/// Validation result containing success status and error message
class ValidationResult {
  const ValidationResult.success()
      : isValid = true,
        errorMessage = null;

  const ValidationResult.failure(this.errorMessage) : isValid = false;

  final bool isValid;
  final String? errorMessage;
}

/// Email and password validators for authentication
class AuthValidators {
  /// RFC 5322 compliant email regex pattern
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
  );

  /// Password must have at least one letter
  static final _hasLetterRegex = RegExp(r'[a-zA-Z]');

  /// Password must have at least one number
  static final _hasNumberRegex = RegExp(r'[0-9]');

  /// Minimum password length
  static const _minPasswordLength = 8;

  /// Validates email format according to RFC 5322
  ///
  /// Returns [ValidationResult] with success or failure message
  static ValidationResult validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return const ValidationResult.failure('Email is required');
    }

    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) {
      return const ValidationResult.failure('Email is required');
    }

    if (!_emailRegex.hasMatch(trimmedEmail)) {
      return const ValidationResult.failure('Please enter a valid email address');
    }

    return const ValidationResult.success();
  }

  /// Validates password strength
  ///
  /// Requirements:
  /// - Minimum 8 characters
  /// - At least one letter
  /// - At least one number
  ///
  /// Returns [ValidationResult] with success or failure message
  static ValidationResult validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return const ValidationResult.failure('Password is required');
    }

    if (password.length < _minPasswordLength) {
      return const ValidationResult.failure(
        'Password must be at least $_minPasswordLength characters',
      );
    }

    if (!_hasLetterRegex.hasMatch(password)) {
      return const ValidationResult.failure(
        'Password must contain at least one letter',
      );
    }

    if (!_hasNumberRegex.hasMatch(password)) {
      return const ValidationResult.failure(
        'Password must contain at least one number',
      );
    }

    return const ValidationResult.success();
  }

  /// Validates password confirmation matches
  static ValidationResult validatePasswordConfirmation(
    String? password,
    String? confirmation,
  ) {
    if (confirmation == null || confirmation.isEmpty) {
      return const ValidationResult.failure('Please confirm your password');
    }

    if (password != confirmation) {
      return const ValidationResult.failure('Passwords do not match');
    }

    return const ValidationResult.success();
  }

  /// Checks if email format is valid (simple boolean check)
  static bool isValidEmail(String? email) {
    return validateEmail(email).isValid;
  }

  /// Checks if password meets requirements (simple boolean check)
  static bool isValidPassword(String? password) {
    return validatePassword(password).isValid;
  }
}
