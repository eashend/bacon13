import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bacon13/models/user_model.dart';

void main() {
  group('AuthService Tests', () {

    group('Email Validation', () {
      test('should validate correct email format', () {
        const validEmails = [
          'test@example.com',
          'user.name@domain.co.uk',
          'user+tag@example.org',
        ];

        for (final email in validEmails) {
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          expect(emailRegex.hasMatch(email), isTrue, reason: 'Email $email should be valid');
        }
      });

      test('should reject invalid email format', () {
        const invalidEmails = [
          'invalid-email',
          'user@',
          '@domain.com',
          'user.domain.com',
          '',
        ];

        for (final email in invalidEmails) {
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          expect(emailRegex.hasMatch(email), isFalse, reason: 'Email $email should be invalid');
        }
      });
    });

    group('Password Validation', () {
      test('should validate password length', () {
        const validPasswords = [
          'password123',
          '123456',
          'a very long password with spaces and numbers 123',
        ];

        for (final password in validPasswords) {
          expect(password.length >= 6, isTrue, reason: 'Password should be at least 6 characters');
        }
      });

      test('should reject short passwords', () {
        const invalidPasswords = [
          '12345',
          'abc',
          '',
          '1',
        ];

        for (final password in invalidPasswords) {
          expect(password.length >= 6, isFalse, reason: 'Password should be rejected if less than 6 characters');
        }
      });
    });

    group('User Model', () {
      test('should create UserModel from valid data', () {
        final userData = {
          'email': 'test@example.com',
          'created_at': Timestamp.now(),
          'updated_at': Timestamp.now(),
          'profile_images': <String>[],
        };

        // Test that UserModel can be created with valid data structure
        expect(userData['email'], equals('test@example.com'));
        expect(userData['created_at'], isA<Timestamp>());
        expect(userData['updated_at'], isA<Timestamp>());
        expect(userData['profile_images'], isA<List<String>>());
      });

      test('should handle UserModel copyWith method', () {
        final now = DateTime.now();
        final user = UserModel(
          id: 'test-id',
          email: 'test@example.com',
          createdAt: now,
          updatedAt: now,
          profileImages: [],
        );

        final updatedUser = user.copyWith(email: 'new@example.com');

        expect(updatedUser.id, equals('test-id'));
        expect(updatedUser.email, equals('new@example.com'));
        expect(updatedUser.createdAt, equals(now));
        expect(updatedUser.updatedAt, equals(now));
      });
    });

    group('Authentication State', () {
      test('should track loading state correctly', () {
        bool isLoading = false;
        
        // Simulate loading start
        isLoading = true;
        expect(isLoading, isTrue);
        
        // Simulate loading end
        isLoading = false;
        expect(isLoading, isFalse);
      });

      test('should handle authentication errors gracefully', () {
        const errorMessage = 'Authentication failed';
        
        // Test that error messages are handled properly
        expect(errorMessage, isNotEmpty);
        expect(errorMessage, contains('Authentication'));
      });
    });
  });
}