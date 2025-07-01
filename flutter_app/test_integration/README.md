# Integration Tests with Firebase Emulator

This directory contains integration tests that run against the Firebase emulator suite.

## Prerequisites

1. **Install Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Java Runtime** (for Firestore emulator):
   ```bash
   # macOS
   brew install openjdk@11
   
   # Or install from Oracle/OpenJDK
   ```

## Running Integration Tests

### 1. Start Firebase Emulators

In the project root directory:

```bash
# Start all emulators
firebase emulators:start

# Or start specific emulators
firebase emulators:start --only auth,firestore
```

The emulators will start on:
- **Authentication**: http://localhost:9099
- **Firestore**: http://localhost:8080
- **Emulator UI**: http://localhost:4000

### 2. Run Integration Tests

In another terminal, from the `flutter_app` directory:

```bash
# Run all integration tests
flutter test integration_test/

# Run specific test file
flutter test integration_test/auth_integration_test.dart

# Run with device (for more realistic testing)
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/auth_integration_test.dart
```

## Test Scenarios Covered

### ✅ User Registration & Login Flow
- Create new user with Firebase Auth
- Verify user profile creation in Firestore
- Sign out and sign back in with same credentials
- Verify user ID consistency across sessions

### ✅ Error Handling
- Invalid email format during registration
- Weak password validation
- Duplicate user registration attempts
- Wrong password during login
- Non-existent user login attempts

### ✅ Data Persistence
- User profile creation in Firestore
- Data structure validation
- Timestamp handling
- Profile image array initialization

### ✅ Authentication State
- Sign in/sign out state changes
- Session persistence
- Loading states during operations

## Emulator Configuration

The tests automatically configure the Firebase SDKs to use local emulators:

```dart
// Connect to Firebase Emulator
await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
```

## Test Data Cleanup

Each test includes setup/teardown to:
- Clear authentication state
- Clear Firestore test data
- Ensure test isolation

## Debugging

1. **View Emulator UI**: http://localhost:4000
2. **Check Authentication**: View registered users in Auth emulator
3. **Inspect Firestore**: Browse collections and documents
4. **View Logs**: Check terminal output from emulator

## Running in CI/CD

For GitHub Actions or other CI systems:

```yaml
- name: Start Firebase Emulator
  run: |
    firebase emulators:start --only auth,firestore &
    sleep 10

- name: Run Integration Tests  
  run: |
    cd flutter_app
    flutter test integration_test/
```

## Troubleshooting

### Port Conflicts
If ports are in use, modify `firebase.json`:

```json
{
  "emulators": {
    "auth": {
      "port": 9199
    },
    "firestore": {
      "port": 8180
    }
  }
}
```

### Java Issues
Ensure Java 11+ is installed for Firestore emulator:

```bash
java -version
```

### Connection Issues
Verify emulators are running:

```bash
curl http://localhost:9099
curl http://localhost:8080
```