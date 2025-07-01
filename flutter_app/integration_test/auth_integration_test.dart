import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bacon13/main.dart' as app;
import 'package:bacon13/services/auth_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Firebase Authentication Integration Tests', () {
    late FirebaseAuth auth;
    late FirebaseFirestore firestore;
    late AuthService authService;

    setUpAll(() async {
      // Initialize Firebase
      await Firebase.initializeApp();
      
      // Connect to Firebase Emulator
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      
      auth = FirebaseAuth.instance;
      firestore = FirebaseFirestore.instance;
      authService = AuthService();
    });

    setUp(() async {
      // Clear any existing auth state
      if (auth.currentUser != null) {
        await auth.signOut();
      }
      
      // Clear Firestore test data
      try {
        await firestore.clearPersistence();
      } catch (e) {
        // Ignore if already cleared
      }
    });

    testWidgets('should create new user and login with Firebase emulator', (WidgetTester tester) async {
      // Test data
      const testEmail = 'integration.test@example.com';
      const testPassword = 'integrationTest123';
      
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Step 1: Navigate to registration (assuming we start on login screen)
      // You may need to adjust these based on your actual UI
      final registerButton = find.text('Create Account');
      if (registerButton.evaluate().isNotEmpty) {
        await tester.tap(registerButton);
        await tester.pumpAndSettle();
      }

      // Step 2: Fill in registration form
      await tester.enterText(find.byKey(const Key('email_field')), testEmail);
      await tester.enterText(find.byKey(const Key('password_field')), testPassword);
      
      // If there's a confirm password field
      final confirmPasswordField = find.byKey(const Key('confirm_password_field'));
      if (confirmPasswordField.evaluate().isNotEmpty) {
        await tester.enterText(confirmPasswordField, testPassword);
      }

      // Step 3: Submit registration
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify user is registered and logged in
      expect(auth.currentUser, isNotNull);
      expect(auth.currentUser!.email, equals(testEmail));

      // Verify user profile was created in Firestore
      final userDoc = await firestore.collection('users').doc(auth.currentUser!.uid).get();
      expect(userDoc.exists, isTrue);
      expect(userDoc.data()!['email'], equals(testEmail));

      final firstUserId = auth.currentUser!.uid;

      // Step 4: Sign out
      // Find and tap logout/sign out button (adjust based on your UI)
      final signOutButton = find.text('Sign Out');
      if (signOutButton.evaluate().isNotEmpty) {
        await tester.tap(signOutButton);
        await tester.pumpAndSettle();
      } else {
        // Programmatically sign out if no UI button
        await authService.signOut();
        await tester.pumpAndSettle();
      }

      // Verify user is signed out
      expect(auth.currentUser, isNull);

      // Step 5: Navigate back to login and sign in with same credentials
      await tester.enterText(find.byKey(const Key('email_field')), testEmail);
      await tester.enterText(find.byKey(const Key('password_field')), testPassword);
      
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify user is logged back in with same ID
      expect(auth.currentUser, isNotNull);
      expect(auth.currentUser!.email, equals(testEmail));
      expect(auth.currentUser!.uid, equals(firstUserId));

      print('✅ Complete registration and login flow with Firebase emulator completed successfully');
    });

    testWidgets('should handle authentication errors with Firebase emulator', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Test invalid email registration
      const invalidEmail = 'not-an-email';
      const validPassword = 'validPassword123';

      // Navigate to registration if needed
      final registerButton = find.text('Create Account');
      if (registerButton.evaluate().isNotEmpty) {
        await tester.tap(registerButton);
        await tester.pumpAndSettle();
      }

      // Fill invalid email
      await tester.enterText(find.byKey(const Key('email_field')), invalidEmail);
      await tester.enterText(find.byKey(const Key('password_field')), validPassword);

      // Submit and expect error
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should show error message (adjust based on your error display)
      expect(find.textContaining('email'), findsOneWidget);
      
      print('✅ Invalid email error handling with Firebase emulator completed successfully');
    });

    testWidgets('should handle weak password with Firebase emulator', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      const validEmail = 'weakpass.test@example.com';
      const weakPassword = '123'; // Too short for Firebase

      // Navigate to registration if needed
      final registerButton = find.text('Create Account');
      if (registerButton.evaluate().isNotEmpty) {
        await tester.tap(registerButton);
        await tester.pumpAndSettle();
      }

      // Fill weak password
      await tester.enterText(find.byKey(const Key('email_field')), validEmail);
      await tester.enterText(find.byKey(const Key('password_field')), weakPassword);

      // Submit and expect error
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should show weak password error
      expect(find.textContaining('weak'), findsOneWidget);
      
      print('✅ Weak password error handling with Firebase emulator completed successfully');
    });

    testWidgets('should handle duplicate user registration with Firebase emulator', (WidgetTester tester) async {
      const testEmail = 'duplicate.test@example.com';
      const testPassword = 'duplicateTest123';

      // Launch the app  
      app.main();
      await tester.pumpAndSettle();

      // Step 1: Register user first time
      final registerButton = find.text('Create Account');
      if (registerButton.evaluate().isNotEmpty) {
        await tester.tap(registerButton);
        await tester.pumpAndSettle();
      }

      await tester.enterText(find.byKey(const Key('email_field')), testEmail);
      await tester.enterText(find.byKey(const Key('password_field')), testPassword);
      
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify first registration succeeded
      expect(auth.currentUser, isNotNull);
      expect(auth.currentUser!.email, equals(testEmail));

      // Step 2: Sign out
      await authService.signOut();
      await tester.pumpAndSettle();

      // Step 3: Try to register same user again
      final registerButton2 = find.text('Create Account');
      if (registerButton2.evaluate().isNotEmpty) {
        await tester.tap(registerButton2);
        await tester.pumpAndSettle();
      }

      await tester.enterText(find.byKey(const Key('email_field')), testEmail);
      await tester.enterText(find.byKey(const Key('password_field')), testPassword);
      
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should show duplicate email error
      expect(find.textContaining('already'), findsOneWidget);
      
      print('✅ Duplicate registration error handling with Firebase emulator completed successfully');
    });

    testWidgets('should persist user data in Firestore with Firebase emulator', (WidgetTester tester) async {
      const testEmail = 'firestore.test@example.com';
      const testPassword = 'firestoreTest123';

      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Register new user
      final registerButton = find.text('Create Account');
      if (registerButton.evaluate().isNotEmpty) {
        await tester.tap(registerButton);
        await tester.pumpAndSettle();
      }

      await tester.enterText(find.byKey(const Key('email_field')), testEmail);
      await tester.enterText(find.byKey(const Key('password_field')), testPassword);
      
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify user exists in Firestore
      final userId = auth.currentUser!.uid;
      final userDoc = await firestore.collection('users').doc(userId).get();
      
      expect(userDoc.exists, isTrue);
      
      final userData = userDoc.data()!;
      expect(userData['email'], equals(testEmail));
      expect(userData['created_at'], isA<Timestamp>());
      expect(userData['updated_at'], isA<Timestamp>());
      expect(userData['profile_images'], isA<List>());

      print('✅ Firestore user data persistence with Firebase emulator completed successfully');
    });

    testWidgets('should handle wrong password login with Firebase emulator', (WidgetTester tester) async {
      const testEmail = 'wrongpass.test@example.com';
      const correctPassword = 'correctPassword123';
      const wrongPassword = 'wrongPassword456';

      // First register a user
      await authService.createUserWithEmailAndPassword(testEmail, correctPassword);
      await authService.signOut();

      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Try to login with wrong password
      await tester.enterText(find.byKey(const Key('email_field')), testEmail);
      await tester.enterText(find.byKey(const Key('password_field')), wrongPassword);
      
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should show wrong password error
      expect(find.textContaining('password'), findsOneWidget);
      expect(auth.currentUser, isNull);

      // Verify correct password still works
      await tester.enterText(find.byKey(const Key('email_field')), testEmail);
      await tester.enterText(find.byKey(const Key('password_field')), correctPassword);
      
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(auth.currentUser, isNotNull);
      expect(auth.currentUser!.email, equals(testEmail));

      print('✅ Wrong password error handling with Firebase emulator completed successfully');
    });
  });
}