# Security Configuration for Bacon13

## 🔒 Firebase Configuration Security

This project uses **environment variables** for all Firebase configuration to prevent secrets from being committed to git.

### ⚠️ CRITICAL SECURITY PRACTICES

1. **NEVER commit Firebase API keys to git**
2. **ALWAYS use environment variables for secrets**
3. **The `.env` file is gitignored and must never be committed**
4. **Use secure build and deployment scripts**

### 🛠️ Setup Process

#### 1. Copy Environment Template
```bash
cp .env.template .env
```

#### 2. Get Firebase Configuration
```bash
# Get your Firebase configuration
firebase apps:sdkconfig
```

#### 3. Fill in .env File
Edit `.env` with your real Firebase project configuration:
```bash
FIREBASE_API_KEY=AIzaSyB99as7K_bCTnGBoKk0U8w7T2P0Sk1S_dQ
FIREBASE_APP_ID=1:1035009518967:web:612a98dac7120aa76e0572
FIREBASE_MESSAGING_SENDER_ID=1035009518967
FIREBASE_PROJECT_ID=bacon13
FIREBASE_AUTH_DOMAIN=bacon13.firebaseapp.com
FIREBASE_STORAGE_BUCKET=bacon13.firebasestorage.app
```

### 🚀 Secure Building and Deployment

#### Build with Secrets
```bash
cd flutter_app
./build_with_secrets.sh web
```

#### Deploy Securely
```bash
./deploy_secure.sh bacon13 us-central1 prod
```

### 🔐 How It Works

1. **Flutter Configuration**: `firebase_options.dart` uses `String.fromEnvironment()` to load secrets
2. **Build Time**: Secrets are passed via `--dart-define` flags during build
3. **Runtime**: Flutter app receives configuration as compile-time constants
4. **No Exposure**: API keys never appear in source code or git history

### 📁 File Security

**Secured Files:**
- ✅ `.env` - gitignored, contains real secrets
- ✅ `firebase_options.dart` - uses environment variables
- ✅ Build scripts inject secrets at build time

**Safe Files:**
- ✅ `.env.template` - template with placeholder values
- ✅ `firebase_options_template.dart` - template with environment variable references

### 🚫 What NOT to Do

- ❌ Never commit `.env` files
- ❌ Never hardcode API keys in source code
- ❌ Never commit test files with real API keys
- ❌ Never push secrets to any git repository

### 🔍 Verification

Check that no secrets are committed:
```bash
# Search for API keys in git history
git log --all -p -S "AIzaSyB" -- '*.dart' '*.js' '*.json'

# Should return no results if properly secured
```

### 🆘 If Secrets Were Committed

1. **Immediately rotate all Firebase API keys** in Firebase Console
2. Remove sensitive files from git history:
   ```bash
   git filter-branch --index-filter 'git rm --cached --ignore-unmatch path/to/secret-file' HEAD
   ```
3. Force push the cleaned history
4. Update all team members to re-clone the repository

### 🔄 CI/CD Security

For automated deployments, store secrets in:
- GitHub Actions: Repository Secrets
- Cloud Build: Secret Manager
- Other CI: Encrypted environment variables

Never store secrets in CI configuration files that are committed to git.