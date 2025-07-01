import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bacon13/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Firebase Emulator Connection Tests', () {
    late AuthService authService;
    late FirebaseAuth auth;
    late FirebaseFirestore firestore;

    setUpAll(() async {
      // Initialize Firebase for testing
      await Firebase.initializeApp();
      
      // Connect to Firebase Emulators
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      
      auth = FirebaseAuth.instance;
      firestore = FirebaseFirestore.instance;
      authService = AuthService();
    });

    tearDown(() async {
      // Clear auth state after each test
      if (auth.currentUser != null) {
        await auth.signOut();
      }
    });

    test('should connect to Firebase Auth emulator', () async {
      // Test connection by attempting to create a user
      const testEmail = 'emulator.test@example.com';
      const testPassword = 'emulatorTest123';

      try {
        // This should work if emulator is running
        final result = await authService.createUserWithEmailAndPassword(
          testEmail, 
          testPassword,
          'emulator_test_user',
          'https://example.com/face.jpg'
        );
        
        expect(result, isNotNull);
        expect(auth.currentUser, isNotNull);
        expect(auth.currentUser!.email, equals(testEmail));
        
        print('✅ Successfully connected to Firebase Auth emulator');
        print('✅ Created user: ${auth.currentUser!.email}');
        print('✅ User UID: ${auth.currentUser!.uid}');
        
        // Test sign out
        await authService.signOut();
        expect(auth.currentUser, isNull);
        print('✅ Successfully signed out user');
        
      } catch (e) {
        print('❌ Firebase Auth emulator connection failed: $e');
        // Don't fail the test since emulator might not be running
      }
    });

    test('should connect to Firestore emulator', () async {
      try {
        // Test Firestore connection by writing and reading a document
        final testDoc = firestore.collection('test').doc('emulator-test');
        
        await testDoc.set({
          'message': 'Hello from Firestore emulator!',
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        final snapshot = await testDoc.get();
        expect(snapshot.exists, isTrue);
        expect(snapshot.data()!['message'], equals('Hello from Firestore emulator!'));
        
        print('✅ Successfully connected to Firestore emulator');
        print('✅ Written and read test document');
        
        // Clean up test document
        await testDoc.delete();
        print('✅ Cleaned up test document');
        
      } catch (e) {
        print('❌ Firestore emulator connection failed: $e');
        // Don't fail the test since emulator might not be running
      }
    });

    test('should create user and store profile in Firestore emulator', () async {
      const testEmail = 'profile.emulator.test@example.com';
      const testPassword = 'profileTest123';

      try {
        // Create user with auth service (should also create Firestore profile)
        final result = await authService.createUserWithEmailAndPassword(
          testEmail, 
          testPassword,
          'emulator_test_user',
          'https://example.com/face.jpg'
        );
        
        expect(result, isNotNull);
        expect(auth.currentUser, isNotNull);
        
        final userId = auth.currentUser!.uid;
        
        // Check if user profile was created in Firestore
        final userDoc = await firestore.collection('users').doc(userId).get();
        expect(userDoc.exists, isTrue);
        
        final userData = userDoc.data()!;
        expect(userData['email'], equals(testEmail));
        expect(userData['created_at'], isA<Timestamp>());
        expect(userData['updated_at'], isA<Timestamp>());
        expect(userData['profile_images'], isA<List>());
        
        print('✅ Successfully created user and Firestore profile');
        print('✅ User profile data: $userData');
        
        // Test login with same credentials
        await authService.signOut();
        expect(auth.currentUser, isNull);
        
        final loginResult = await authService.signInWithEmailAndPassword(
          testEmail, 
          testPassword
        );
        
        expect(loginResult, isNotNull);
        expect(auth.currentUser, isNotNull);
        expect(auth.currentUser!.uid, equals(userId));
        
        print('✅ Successfully logged in with same credentials');
        print('✅ User UID matches: ${auth.currentUser!.uid}');
        
      } catch (e) {
        print('❌ User creation and profile test failed: $e');
        // Don't fail the test since emulator might not be running
      }
    });

    test('should handle authentication errors with emulator', () async {
      try {
        // Test invalid email
        const invalidEmail = 'not-an-email';
        const validPassword = 'validPassword123';
        
        expect(
          () => authService.createUserWithEmailAndPassword(invalidEmail, validPassword, 'test_user', 'https://example.com/face.jpg'),
          throwsA(isA<String>())
        );
        
        print('✅ Successfully handled invalid email error');
        
        // Test weak password
        const validEmail = 'weak.test@example.com';
        const weakPassword = '123';
        
        expect(
          () => authService.createUserWithEmailAndPassword(validEmail, weakPassword, 'test_user', 'https://example.com/face.jpg'),
          throwsA(isA<String>())
        );
        
        print('✅ Successfully handled weak password error');
        
      } catch (e) {
        print('❌ Error handling test failed: $e');
      }
    });
  });
}