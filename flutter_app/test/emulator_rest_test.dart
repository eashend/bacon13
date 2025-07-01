import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  group('Firebase Emulator REST API Tests', () {
    const String authEmulatorUrl = 'http://localhost:9099';
    const String firestoreEmulatorUrl = 'http://localhost:8080';
    
    test('should connect to Firebase Auth emulator', () async {
      try {
        final response = await http.get(Uri.parse(authEmulatorUrl));
        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body);
        expect(data['authEmulator']['ready'], isTrue);
        
        print('✅ Firebase Auth emulator is running on port 9099');
        print('✅ Auth emulator response: ${response.body}');
      } catch (e) {
        fail('❌ Firebase Auth emulator connection failed: $e');
      }
    });

    test('should connect to Firestore emulator', () async {
      try {
        final response = await http.get(Uri.parse(firestoreEmulatorUrl));
        expect(response.statusCode, equals(200));
        expect(response.body.trim(), equals('Ok'));
        
        print('✅ Firestore emulator is running on port 8080');
        print('✅ Firestore emulator response: ${response.body}');
      } catch (e) {
        fail('❌ Firestore emulator connection failed: $e');
      }
    });

    test('should create user via Auth emulator REST API', () async {
      try {
        const String projectId = 'bacon13';
        const String apiKey = 'demo-api-key'; // Demo key for emulator
        
        final signUpUrl = Uri.parse(
          '$authEmulatorUrl/identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey'
        );
        
        final signUpResponse = await http.post(
          signUpUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': 'emulator.rest.test@example.com',
            'password': 'emulatorTest123',
            'returnSecureToken': true,
          }),
        );
        
        expect(signUpResponse.statusCode, equals(200));
        
        final signUpData = jsonDecode(signUpResponse.body);
        expect(signUpData['email'], equals('emulator.rest.test@example.com'));
        expect(signUpData['localId'], isNotNull);
        expect(signUpData['idToken'], isNotNull);
        
        print('✅ Successfully created user via Auth emulator REST API');
        print('✅ User ID: ${signUpData['localId']}');
        print('✅ Email: ${signUpData['email']}');
        
        // Test sign in with same credentials
        final signInUrl = Uri.parse(
          '$authEmulatorUrl/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey'
        );
        
        final signInResponse = await http.post(
          signInUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': 'emulator.rest.test@example.com',
            'password': 'emulatorTest123',
            'returnSecureToken': true,
          }),
        );
        
        expect(signInResponse.statusCode, equals(200));
        
        final signInData = jsonDecode(signInResponse.body);
        expect(signInData['email'], equals('emulator.rest.test@example.com'));
        expect(signInData['localId'], equals(signUpData['localId']));
        
        print('✅ Successfully signed in with same credentials');
        print('✅ Login user ID matches: ${signInData['localId']}');
        
      } catch (e) {
        fail('❌ Auth emulator REST API test failed: $e');
      }
    });

    test('should verify Firestore emulator is accessible', () async {
      try {
        const String projectId = 'bacon13';
        
        // Test Firestore connectivity with a simple query
        final listUrl = Uri.parse(
          '$firestoreEmulatorUrl/v1/projects/$projectId/databases/(default)/documents/test'
        );
        
        final listResponse = await http.get(listUrl);
        // 200 for existing docs, 404 for empty collection - both are valid
        expect([200, 404].contains(listResponse.statusCode), isTrue);
        
        print('✅ Firestore emulator is accessible');
        print('✅ Response status: ${listResponse.statusCode}');
        
        if (listResponse.statusCode == 200) {
          print('✅ Firestore returned documents list');
        } else {
          print('✅ Firestore collection is empty (expected for new setup)');
        }
        
      } catch (e) {
        fail('❌ Firestore emulator connectivity test failed: $e');
      }
    });

    test('should handle authentication errors via emulator', () async {
      try {
        const String projectId = 'bacon13';
        const String apiKey = 'demo-api-key';
        
        // Test invalid email
        final invalidEmailUrl = Uri.parse(
          '$authEmulatorUrl/identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey'
        );
        
        final invalidEmailResponse = await http.post(
          invalidEmailUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': 'not-an-email',
            'password': 'validPassword123',
            'returnSecureToken': true,
          }),
        );
        
        expect(invalidEmailResponse.statusCode, equals(400));
        
        final errorData = jsonDecode(invalidEmailResponse.body);
        expect(errorData['error']['message'], contains('INVALID_EMAIL'));
        
        print('✅ Successfully handled invalid email error');
        print('✅ Error message: ${errorData['error']['message']}');
        
        // Test weak password
        final weakPasswordResponse = await http.post(
          invalidEmailUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': 'weak.password.test@example.com',
            'password': '123',
            'returnSecureToken': true,
          }),
        );
        
        expect(weakPasswordResponse.statusCode, equals(400));
        
        final weakErrorData = jsonDecode(weakPasswordResponse.body);
        expect(weakErrorData['error']['message'], contains('WEAK_PASSWORD'));
        
        print('✅ Successfully handled weak password error');
        print('✅ Error message: ${weakErrorData['error']['message']}');
        
      } catch (e) {
        fail('❌ Authentication error handling test failed: $e');
      }
    });
  });
}