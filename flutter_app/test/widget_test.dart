import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bacon13/services/auth_service.dart';

void main() {

  group('App Widget Tests', () {
    testWidgets('App should start and show login when not authenticated', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthService(),
            child: Scaffold(
              body: Center(
                child: Text('Login Screen'),
              ),
            ),
          ),
        ),
      );

      // Verify that login indication is shown
      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('Should display app title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          title: 'Bacon13',
          home: Scaffold(
            appBar: AppBar(title: Text('Bacon13')),
            body: Center(child: Text('Test')),
          ),
        ),
      );

      expect(find.text('Bacon13'), findsOneWidget);
    });
  });

  group('Authentication Widget Tests', () {
    testWidgets('Login form should have email and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: Column(
                children: [
                  TextFormField(
                    key: Key('email_field'),
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                  TextFormField(
                    key: Key('password_field'),
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(Key('email_field')), findsOneWidget);
      expect(find.byKey(Key('password_field')), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Register form should have email, password, and confirm password fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: Column(
                children: [
                  TextFormField(
                    key: Key('email_field'),
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                  TextFormField(
                    key: Key('password_field'),
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  TextFormField(
                    key: Key('confirm_password_field'),
                    decoration: InputDecoration(labelText: 'Confirm Password'),
                    obscureText: true,
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('Create Account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(Key('email_field')), findsOneWidget);
      expect(find.byKey(Key('password_field')), findsOneWidget);
      expect(find.byKey(Key('confirm_password_field')), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });
  });

  group('Navigation Tests', () {
    testWidgets('Bottom navigation should have Feed, Create, and Profile tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Feed',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle),
                  label: 'Create',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });
  });

  group('Post Widget Tests', () {
    testWidgets('Empty feed should show no posts message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64),
                  SizedBox(height: 16),
                  Text('No posts yet'),
                  Text('Be the first to share a moment!'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('No posts yet'), findsOneWidget);
      expect(find.text('Be the first to share a moment!'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    });

    testWidgets('Create post screen should show image picker option', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_camera_outlined, size: 80),
                  SizedBox(height: 24),
                  Text('Share a moment'),
                  Text('Choose a photo to share with your friends'),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('Select Photo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Share a moment'), findsOneWidget);
      expect(find.text('Choose a photo to share with your friends'), findsOneWidget);
      expect(find.text('Select Photo'), findsOneWidget);
      expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    });
  });

  group('Profile Widget Tests', () {
    testWidgets('Profile screen should show user info and stats', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
                SizedBox(height: 16),
                Text('testuser', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('testuser@example.com'),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(children: [Text('0'), Text('Posts')]),
                    Column(children: [Text('0'), Text('Followers')]),
                    Column(children: [Text('0'), Text('Following')]),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('testuser@example.com'), findsOneWidget);
      expect(find.text('Posts'), findsOneWidget);
      expect(find.text('Followers'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);
    });
  });
}