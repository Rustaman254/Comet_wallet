# Comet Wallet - Complete Documentation

A comprehensive Flutter wallet application with user authentication, KYC verification, and wallet top-up functionality.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Authentication System](#authentication-system)
4. [Logging System](#logging-system)
5. [Wallet Top-up Feature](#wallet-top-up-feature)
6. [Installation & Setup](#installation--setup)
7. [Known Issues & Fixes](#known-issues--fixes)
8. [Testing Guide](#testing-guide)
9. [API Integration](#api-integration)
10. [Troubleshooting](#troubleshooting)

---

## Project Overview

The Comet Wallet is a mobile wallet application that allows users to:
- ✅ Register and create accounts
- ✅ Complete KYC (Know Your Customer) verification
- ✅ Top-up wallet balance
- ✅ Perform transactions
- ✅ View transaction history
- ✅ Manage account settings

**Tech Stack:**
- **Framework:** Flutter 3.x
- **Language:** Dart
- **Storage:** SharedPreferences
- **HTTP Client:** http package
- **UI:** Material Design 3
- **Theme:** Light/Dark mode support

---

## Architecture

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── constants/
│   ├── api_constants.dart    # API endpoints
│   ├── colors.dart           # Color palette
│   └── strings.dart          # App strings
├── screens/
│   ├── sign_in_screen.dart
│   ├── sign_up_screen.dart
│   ├── home_screen.dart
│   ├── wallet_topup_screen.dart
│   ├── kyc_screen.dart
│   └── auth_debug_screen.dart (DEBUG)
├── services/
│   ├── auth_service.dart      # Authentication logic
│   ├── token_service.dart     # Token storage/retrieval
│   ├── wallet_service.dart    # Wallet operations
│   ├── kyc_service.dart       # KYC operations
│   ├── logger_service.dart    # Logging system
│   └── toast_service.dart     # Toast notifications
├── utils/
│   ├── input_decoration.dart  # Input field styling
│   └── debug_utils.dart       # Debug utilities
└── widgets/
    └── [Reusable widgets]
```

---

## Authentication System

### Overview

The authentication system handles user login, registration, token management, and session persistence.

### Authentication Flow

```
┌─────────────────┐
│  Sign In Screen │
│  (email/pass)   │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────┐
│  AuthService.login()            │
│  ✓ POST /users/login            │
│  ✓ Extract token (root level)   │
│  ✓ Extract user data            │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│  TokenService.saveUserData()    │
│  ✓ Save token                   │
│  ✓ Save user ID                 │
│  ✓ Save email                   │
│  ✓ Save phone number            │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│  Home Screen (Protected)        │
│  Check: isAuthenticated()       │
└─────────────────────────────────┘
```

### Services

#### TokenService (`lib/services/token_service.dart`)

**Stores authentication data in SharedPreferences:**

| Key | Value | Type |
|-----|-------|------|
| `auth_token` | JWT token | String |
| `user_id` | User ID | String |
| `user_email` | Email | String |
| `phone_number` | Phone | String |

**Methods:**

```dart
// Check authentication
bool isAuth = await TokenService.isAuthenticated();

// Get token
String? token = await TokenService.getToken();

// Save user data
await TokenService.saveUserData(
  token: 'jwt_token',
  userId: '123',
  email: 'user@example.com',
  phoneNumber: '+254712345678',
);

// Get all user data
Map<String, String?> data = await TokenService.getUserData();

// Logout - clears all
await TokenService.logout();
```

#### AuthService (`lib/services/auth_service.dart`)

**Handles API communication for authentication:**

```dart
// User login
final response = await AuthService.login(
  email: 'user@example.com',
  password: 'password123',
);

// User registration
final response = await AuthService.register(
  email: 'user@example.com',
  password: 'password123',
  firstName: 'John',
  lastName: 'Doe',
  phoneNumber: '+254712345678',
);
```

**Login Response Format:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 80,
    "email": "user@example.com",
    "phone": "0700294421",
    "name": "John Doe",
    "kyc_verified": false,
    "is_account_activated": false,
    "activation_fee_paid": false,
    "status": "active",
    "role": {
      "id": 8,
      "name": "Blogger",
      "permissions": "create,read,update,delete"
    }
  }
}
```

### Token Management

**Token Extraction:**
- Extracted from `response['token']` (root level)
- Saved to SharedPreferences immediately
- Retrieved for each API request

**Authorization Header:**
```
Authorization: Bearer {token}
```

---

## Logging System

### Overview

Comprehensive logging system for debugging and monitoring all application activities.

### Log Levels

| Level | Use Case | Example |
|-------|----------|---------|
| INFO | General information | User logged in |
| DEBUG | Detailed debug info | Token extraction details |
| WARNING | Potential issues | Low storage space |
| ERROR | Error events | API request failed |
| SUCCESS | Successful operations | Payment completed |

### Log Tags

```dart
LogTags.auth          // Authentication operations
LogTags.kyc           // KYC operations
LogTags.payment       // Payment/wallet operations
LogTags.transaction   // Transaction operations
LogTags.api           // API calls
LogTags.database      // Database operations
LogTags.storage       // Storage operations
LogTags.camera        // Camera operations
LogTags.validation    // Validation operations
LogTags.navigation    // Navigation events
```

### Usage Examples

**Login Logging:**
```dart
AppLogger.info(
  LogTags.auth,
  'User login successful',
  data: {
    'email': email,
    'timestamp': DateTime.now().toIso8601String(),
  },
);
```

**API Request/Response:**
```dart
// Request
AppLogger.logAPIRequest(
  endpoint: ApiConstants.loginEndpoint,
  method: 'POST',
  body: requestBody,
);

// Response
AppLogger.logAPIResponse(
  endpoint: ApiConstants.loginEndpoint,
  method: 'POST',
  statusCode: 200,
  duration: duration,
  response: jsonResponse,
);
```

**KYC Operations:**
```dart
AppLogger.logKYCSubmission({
  'userID': 123,
  'ID_document': 'https://...',
  'profile_photo': 'https://...',
});

AppLogger.logKYCImageUpload(
  imageType: 'ID_Front',
  imageUrl: 'https://...',
  fileSizeBytes: 1024000,
  uploadDuration: Duration(seconds: 5),
);
```

**User Registration:**
```dart
AppLogger.logUserRegistration({
  'email': email,
  'first_name': firstName,
  'last_name': lastName,
  'phone_number': phoneNumber,
  'timestamp': DateTime.now().toIso8601String(),
});
```

### Console Output Format

```
[2024-01-07 10:15:30.123] [SUCCESS] [AUTH] User login successful
  Data: 
    email: user@example.com
    timestamp: 2024-01-07T10:15:30.123456Z
```

### Sensitive Data Protection

The logger automatically redacts sensitive information:

**Redacted Keys:**
- password, pin, secret
- token, apikey, api_key
- privatekey, private_key
- authorization, authtoken, auth_token
- ssn, socialSecurityNumber
- creditCard, credit_card
- cvv, cvc
- accountNumber, account_number
- routingNumber, routing_number

**Example:**
```dart
AppLogger.info('AUTH', 'Login', data: {
  'email': 'user@example.com',
  'password': 'secret123',  // Will be redacted
});
// Output: password: ***REDACTED***
```

---

## Wallet Top-up Feature

### Overview

Allows authenticated users to top-up their wallet balance.

### Top-up Flow

```
Wallet Top-up Screen
    ↓
Enter: Phone, Amount, Currency
    ↓
WalletService.topupWallet()
    ↓
Get token from TokenService
    ↓
Create request with Authorization header
    ↓
POST /wallet/topup
    ↓
Backend validates token
    ↓
Return transaction ID or error
```

### Implementation

**WalletService (`lib/services/wallet_service.dart`):**

```dart
// Top-up wallet
final response = await WalletService.topupWallet(
  phoneNumber: '0710000000',
  amount: 100.0,
  currency: 'KES',
);

// Get wallet balance
final balance = await WalletService.getWalletBalance();

// Get transaction history
final transactions = await WalletService.getTransactionHistory();
```

**Request Format:**
```json
{
  "phone_number": "254710000000",
  "amount": 100.0,
  "currency": "KES"
}
```

**Success Response:**
```json
{
  "status": "success",
  "message": "Top-up payment initiated successfully",
  "transaction_id": "mPk8l4ZI7guffg==",
  "phone_number": "254710000000",
  "amount": 100.0,
  "currency": "KES"
}
```

**Error Responses:**

401 - Invalid Token:
```json
{
  "error": "Unauthorized",
  "message": "Invalid or expired token"
}
```

403 - Not Authorized:
```json
{
  "error": "Forbidden",
  "message": "User not permitted to access this resource"
}
```

### UI Components

**wallet_topup_screen.dart:**
- Phone number input
- Amount input
- Currency selector (KES, USD, etc.)
- Submit button
- Loading indicator
- Error/success messages

---

## Installation & Setup

### Prerequisites

- Flutter 3.0+
- Dart 2.17+
- Android SDK 21+
- iOS 11.0+

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  shared_preferences: ^2.2.0
  google_fonts: ^6.0.0
  mobile_scanner: ^3.0.0
  path_provider: ^2.0.0
  intl: ^0.19.0
  camera: ^0.10.0
```

### Installation Steps

1. **Clone repository:**
```bash
git clone <repository_url>
cd comet_wallet
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Run the app:**
```bash
flutter run
```

4. **Build APK:**
```bash
flutter build apk --release
```

### Configuration

**API Configuration (`lib/constants/api_constants.dart`):**
```dart
class ApiConstants {
  static const String baseUrl = 'https://api.yeshara.network/api/v1';
  static const String loginEndpoint = '$baseUrl/users/login';
  static const String registerEndpoint = '$baseUrl/users/create';
  static const String walletTopupEndpoint = '$baseUrl/wallet/topup';
  static const String kycCreateEndpoint = '$baseUrl/kyc/create';
}
```

---

## Known Issues & Fixes

### Issue: "User not authenticated" on wallet top-up

**Symptoms:**
- User logs in successfully
- Token is saved
- Wallet top-up returns 401/403 error

**Root Causes:**
1. Token not being extracted from response correctly
2. Token not being stored in SharedPreferences
3. Token not being retrieved for API call
4. Backend not accepting "Bearer" format

**Fixes Applied:**

1. **Enhanced token extraction** in `auth_service.dart`:
   - Now extracts email from response (not input)
   - Better validation of token presence
   - Improved error logging

2. **Improved wallet service logging** in `wallet_service.dart`:
   - Token preview logged (first 50 chars)
   - Authorization header format logged
   - Distinction between 401 (invalid token) and 403 (not authorized)

3. **Added debug screen** (`auth_debug_screen.dart`):
   - Shows authentication status
   - Displays token information
   - Test wallet top-up button
   - Logout functionality

### How to Use Debug Screen

1. **Add route to main.dart:**
```dart
// In home screen menu or settings
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const AuthDebugScreen()),
);
```

2. **Test authentication:**
   - View token status
   - Check token length
   - View user data

3. **Test wallet top-up:**
   - Click "Test Wallet Top-up Call"
   - See exact error response
   - Share logs with backend team

---

## Testing Guide

### Manual Testing

**1. Registration Flow:**
```
1. Open app
2. Go to Sign Up
3. Enter: Email, Password, First Name, Last Name, Phone
4. Verify: Token received and saved
5. Check: Can navigate to home screen
```

**2. Login Flow:**
```
1. Go to Sign In
2. Enter: Email, Password
3. Verify: Token received
4. Verify: User data saved
5. Check: Can access home screen
```

**3. Wallet Top-up Flow:**
```
1. Login successfully
2. Go to Wallet Top-up
3. Enter: Phone (0710000000), Amount (1), Currency (KES)
4. Click Top-up
5. Verify: Success message or error
6. Check: Transaction logged
```

**4. KYC Flow:**
```
1. Login successfully
2. Go to KYC
3. Upload: ID Front, ID Back, KRA, Photo, Proof of Address
4. Submit KYC
5. Verify: Success response
6. Check: Logs show submission
```

### Debug Testing

**Using Debug Screen:**
```
1. Login
2. Open AuthDebugScreen
3. Check: "Authentication Status" = Authenticated ✅
4. Check: Token exists and not empty
5. Check: User data present
6. Click: "Test Wallet Top-up"
7. See: Exact error response
8. Share: Debug info with backend team
```

### Test Accounts

| Email | Password | Purpose |
|-------|----------|---------|
| test@example.com | Test@123 | Testing |
| kyc@example.com | Kyc@123 | KYC testing |
| payment@example.com | Pay@123 | Payment testing |

---

## API Integration

### Base URL
```
https://api.yeshara.network/api/v1
```

### Endpoints

#### 1. User Login
```
POST /users/login
Headers:
  Content-Type: application/json

Body:
{
  "email": "user@example.com",
  "password": "password123"
}

Response: 200 OK
{
  "token": "eyJhbGciOi...",
  "user": { ... }
}
```

#### 2. User Registration
```
POST /users/create
Headers:
  Content-Type: application/json

Body:
{
  "email": "user@example.com",
  "password": "password123",
  "firstName": "John",
  "lastName": "Doe",
  "phoneNumber": "+254712345678"
}

Response: 200 OK / 201 Created
{ ... }
```

#### 3. Wallet Top-up
```
POST /wallet/topup
Headers:
  Content-Type: application/json
  Authorization: Bearer {token}

Body:
{
  "phone_number": "254710000000",
  "amount": 100.0,
  "currency": "KES"
}

Response: 200 OK
{
  "status": "success",
  "transaction_id": "mPk8l4ZI7guffg==",
  "amount": 100.0,
  "currency": "KES"
}
```

#### 4. Get Wallet Balance
```
GET /wallet/balance
Headers:
  Authorization: Bearer {token}

Response: 200 OK
{
  "balance": 5000.00,
  "currency": "KES"
}
```

#### 5. Get Transaction History
```
GET /wallet/transactions
Headers:
  Authorization: Bearer {token}

Response: 200 OK
{
  "transactions": [
    {
      "id": 1,
      "type": "topup",
      "amount": 100.0,
      "currency": "KES",
      "date": "2024-01-07T10:15:30Z"
    }
  ]
}
```

#### 6. KYC Submission
```
POST /kyc/create
Headers:
  Content-Type: application/json
  Authorization: Bearer {token}

Body:
{
  "KYC": {
    "userID": 123,
    "ID_document": "https://...",
    "ID_document_back": "https://...",
    "KRA_document": "https://...",
    "profile_photo": "https://...",
    "proof_of_address": "https://..."
  }
}

Response: 200 OK
{ ... }
```

---

## Troubleshooting

### Common Issues & Solutions

#### 1. "Unable to locate SDK"
```bash
flutter config --android-sdk /path/to/android/sdk
```

#### 2. "Plugin not found"
```bash
flutter pub get
flutter pub upgrade
```

#### 3. "Build failure - Java version"
Update Java to version 11+

#### 4. "Gradle sync failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

#### 5. "Token not being saved"
**Check:**
1. Login response includes `token` field
2. TokenService.saveUserData() is called
3. SharedPreferences is initialized
4. No exceptions in console

**Debug:**
```dart
// In AuthService
final savedToken = await TokenService.getToken();
print('Token saved: ${savedToken != null}');
print('Token length: ${savedToken?.length}');
```

#### 6. "Wallet top-up returns 401"
**Check:**
1. Token exists: `AppLogger` shows token_length > 0
2. Token format: Should be "Bearer {token}"
3. Token expired: Check backend token expiration
4. User permissions: Check backend user role

**Debug:**
Open AuthDebugScreen and check:
- Authentication Status ✅
- Token Exists ✅
- Token Length > 0 ✅
- Click Test Wallet Top-up to see exact error

#### 7. "App crashes on top-up"
**Check:**
1. Phone number format: Must include country code
2. Amount format: Must be valid double
3. Currency support: Check backend supported currencies
4. Network connectivity: Must have internet access

**Console Output:**
```
Look for: [ERROR] [PAYMENT] Wallet top-up error
Check: 'error' field in logs
```

#### 8. "KYC images not uploading"
**Check:**
1. Image file size < 5MB each
2. Image format: JPG/PNG only
3. All 5 images uploaded
4. Token valid (not expired)

#### 9. "Theme not switching between light/dark"
**Check:**
1. `MyApp.themeNotifier` is being used
2. `Theme.of(context)` used in screens
3. Colors defined in `colors.dart`

**Force theme change:**
```dart
// In settings screen
MyApp.themeNotifier.value = 
  MyApp.themeNotifier.value == ThemeMode.dark 
    ? ThemeMode.light 
    : ThemeMode.dark;
```

#### 10. "SharedPreferences not persisting data"
**Check:**
1. App has storage permissions
2. Device has sufficient storage
3. SharedPreferences initialized before use

**Force clear:**
```dart
await SharedPreferences.getInstance().then((prefs) {
  prefs.clear();
});
```

### Debug Mode

**Enable detailed logging:**
```bash
flutter run -v
```

**Check device logs:**
```bash
flutter logs
```

**Open dev tools:**
```bash
flutter pub global activate devtools
devtools
```

---

## Performance Optimization

### Best Practices

1. **Use image caching:**
```dart
Image.network(
  url,
  cacheWidth: 400,
  cacheHeight: 400,
)
```

2. **Lazy load lists:**
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

3. **Avoid rebuilds:**
```dart
const SizedBox(width: 10)  // Const widgets not rebuilt
```

4. **Use async/await properly:**
```dart
final token = await TokenService.getToken();
if (token != null) {
  // Use token
}
```

---

## Future Enhancements

- [ ] Biometric authentication
- [ ] Transaction confirmation via SMS/Email
- [ ] Multi-currency support
- [ ] In-app chat support
- [ ] Transaction scheduling
- [ ] Bill payment integration
- [ ] Offline mode support
- [ ] Enhanced analytics

---

## Support & Contact

For issues, questions, or contributions:
- **Email:** support@comet.com
- **GitHub Issues:** [Repository Issues]
- **Documentation:** See `README.md`

---

## License

This project is licensed under the MIT License.

---

**Last Updated:** January 7, 2026  
**Version:** 1.0.0  
**Status:** Production Ready
