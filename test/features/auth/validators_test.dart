import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/features/auth/utils/validators.dart';

void main() {
  group('Email Validation', () {
    test('accepts valid email formats', () {
      final validEmails = [
        'test@example.com',
        'user.name@domain.org',
        'user+tag@example.co.uk',
        'firstname.lastname@company.com',
        'email@subdomain.domain.com',
        'user123@test.io',
      ];

      for (final email in validEmails) {
        final result = AuthValidators.validateEmail(email);
        expect(result.isValid, isTrue, reason: '$email should be valid');
      }
    });

    test('rejects invalid email formats', () {
      final invalidEmails = [
        'plainaddress',
        '@missinglocal.com',
        'missing@.com',
        'missing.domain@',
        'spaces in@email.com',
      ];

      for (final email in invalidEmails) {
        final result = AuthValidators.validateEmail(email);
        expect(result.isValid, isFalse, reason: '$email should be invalid');
      }
    });

    test('rejects null and empty emails', () {
      expect(AuthValidators.validateEmail(null).isValid, isFalse);
      expect(AuthValidators.validateEmail('').isValid, isFalse);
      expect(AuthValidators.validateEmail('   ').isValid, isFalse);
    });

    /// **Feature: multimodal-ai-assistant, Property 1: Email and Password Validation**
    /// **Validates: Requirements 1.2**
    test('property: valid emails always have @ and domain (100 iterations)', () {
      final random = Random(42);
      final domains = ['example.com', 'test.org', 'company.io', 'mail.co.uk'];
      final chars = 'abcdefghijklmnopqrstuvwxyz0123456789';

      for (var i = 0; i < 100; i++) {
        // Generate random local part
        final localLength = 3 + random.nextInt(10);
        final localPart = String.fromCharCodes(
          List.generate(localLength, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
        );

        // Create valid email
        final domain = domains[random.nextInt(domains.length)];
        final email = '$localPart@$domain';

        final result = AuthValidators.validateEmail(email);
        expect(result.isValid, isTrue, reason: 'Generated email $email should be valid');
      }
    });

    /// **Feature: multimodal-ai-assistant, Property 1: Email and Password Validation**
    /// **Validates: Requirements 1.2**
    test('property: emails without @ are always invalid (100 iterations)', () {
      final random = Random(42);
      final chars = 'abcdefghijklmnopqrstuvwxyz0123456789.';

      for (var i = 0; i < 100; i++) {
        // Generate random string without @
        final length = 5 + random.nextInt(20);
        final invalidEmail = String.fromCharCodes(
          List.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
        );

        // Ensure no @ symbol
        if (!invalidEmail.contains('@')) {
          final result = AuthValidators.validateEmail(invalidEmail);
          expect(result.isValid, isFalse,
              reason: 'Email without @ ($invalidEmail) should be invalid');
        }
      }
    });
  });

  group('Password Validation', () {
    test('accepts valid passwords', () {
      final validPasswords = [
        'password1',
        'Password123',
        'myP4ssword',
        'secure1pass',
        'Test1234',
        'a1234567',
        '1234567a',
      ];

      for (final password in validPasswords) {
        final result = AuthValidators.validatePassword(password);
        expect(result.isValid, isTrue, reason: '$password should be valid');
      }
    });

    test('rejects passwords without numbers', () {
      final noNumberPasswords = [
        'password',
        'abcdefgh',
        'NoNumbers',
      ];

      for (final password in noNumberPasswords) {
        final result = AuthValidators.validatePassword(password);
        expect(result.isValid, isFalse,
            reason: '$password should be invalid (no number)');
        expect(result.errorMessage, contains('number'));
      }
    });

    test('rejects passwords without letters', () {
      final noLetterPasswords = [
        '12345678',
        '99999999',
      ];

      for (final password in noLetterPasswords) {
        final result = AuthValidators.validatePassword(password);
        expect(result.isValid, isFalse,
            reason: '$password should be invalid (no letter)');
        expect(result.errorMessage, contains('letter'));
      }
    });

    test('rejects passwords shorter than 8 characters', () {
      final shortPasswords = [
        'pass1',
        'a1b2c3',
        'short1',
      ];

      for (final password in shortPasswords) {
        final result = AuthValidators.validatePassword(password);
        expect(result.isValid, isFalse,
            reason: '$password should be invalid (too short)');
        expect(result.errorMessage, contains('8'));
      }
    });

    test('rejects null and empty passwords', () {
      expect(AuthValidators.validatePassword(null).isValid, isFalse);
      expect(AuthValidators.validatePassword('').isValid, isFalse);
    });

    /// **Feature: multimodal-ai-assistant, Property 1: Email and Password Validation**
    /// **Validates: Requirements 1.2**
    test('property: passwords with letter+number+8chars are valid (100 iterations)', () {
      final random = Random(42);
      final letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
      final numbers = '0123456789';

      for (var i = 0; i < 100; i++) {
        // Generate password with guaranteed letter, number, and length >= 8
        final letterCount = 1 + random.nextInt(5);
        final numberCount = 1 + random.nextInt(3);
        final extraCount = 8 - letterCount - numberCount;
        final extra = extraCount > 0 ? extraCount : 0;

        final passwordChars = <String>[];

        // Add letters
        for (var j = 0; j < letterCount; j++) {
          passwordChars.add(letters[random.nextInt(letters.length)]);
        }

        // Add numbers
        for (var j = 0; j < numberCount; j++) {
          passwordChars.add(numbers[random.nextInt(numbers.length)]);
        }

        // Add extra characters to reach minimum length
        for (var j = 0; j < extra; j++) {
          final allChars = letters + numbers;
          passwordChars.add(allChars[random.nextInt(allChars.length)]);
        }

        // Shuffle
        passwordChars.shuffle(random);
        final password = passwordChars.join();

        final result = AuthValidators.validatePassword(password);
        expect(result.isValid, isTrue,
            reason: 'Password $password should be valid (has letter, number, length >= 8)');
      }
    });

    /// **Feature: multimodal-ai-assistant, Property 1: Email and Password Validation**
    /// **Validates: Requirements 1.2**
    test('property: passwords under 8 chars are always invalid (100 iterations)', () {
      final random = Random(42);
      final chars = 'abcdefghijklmnopqrstuvwxyz0123456789';

      for (var i = 0; i < 100; i++) {
        // Generate password with length 1-7
        final length = 1 + random.nextInt(7);
        final password = String.fromCharCodes(
          List.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
        );

        final result = AuthValidators.validatePassword(password);
        expect(result.isValid, isFalse,
            reason: 'Password $password (length $length) should be invalid');
      }
    });
  });

  group('Password Confirmation', () {
    test('accepts matching passwords', () {
      final result = AuthValidators.validatePasswordConfirmation(
        'password123',
        'password123',
      );
      expect(result.isValid, isTrue);
    });

    test('rejects non-matching passwords', () {
      final result = AuthValidators.validatePasswordConfirmation(
        'password123',
        'different456',
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('match'));
    });

    test('rejects empty confirmation', () {
      final result = AuthValidators.validatePasswordConfirmation(
        'password123',
        '',
      );
      expect(result.isValid, isFalse);
    });
  });

  group('Helper Methods', () {
    test('isValidEmail returns boolean', () {
      expect(AuthValidators.isValidEmail('test@example.com'), isTrue);
      expect(AuthValidators.isValidEmail('invalid'), isFalse);
    });

    test('isValidPassword returns boolean', () {
      expect(AuthValidators.isValidPassword('password1'), isTrue);
      expect(AuthValidators.isValidPassword('short'), isFalse);
    });
  });
}
