# Quick Reference - Logging System

## Quick Start

### Import
```dart
import 'package:comet_wallet/services/logger_service.dart';
```

## Common Logging Tasks

### 1. Log User Registration
```dart
AppLogger.logUserRegistration({
  'email': 'user@example.com',
  'first_name': 'John',
  'last_name': 'Doe',
  'phone_number': '+254712345678',
});
```
**Output**: `[SUCCESS] User registration completed`

### 2. Log KYC Submission
```dart
AppLogger.logKYCSubmission({
  'KYC': {
    'userID': 12,
    'ID_document': 'https://...',
    'ID_document_back': 'https://...',
    'KRA_document': 'https://...',
    'profile_photo': 'https://...',
    'proof_of_address': 'https://...',
  }
});
```
**Output**: `[SUCCESS] KYC submission completed`

### 3. Log KYC Image Upload
```dart
AppLogger.logKYCImageUpload(
  imageType: 'ID_Front',
  imageUrl: 'https://images.cradlevoices.com/uploads/...',
  fileSizeBytes: 1024000,
  uploadDuration: Duration(seconds: 5),
);
```
**Output**: `[INFO] KYC image uploaded: ID_Front`

### 4. Log User Profile
```dart
AppLogger.logUserProfile({
  'id': 123,
  'email': 'user@example.com',
  'kyc_status': 'verified',
  'account_balance': 5000.00,
});
```
**Output**: `[INFO] User profile loaded`

### 5. Log API Request
```dart
AppLogger.logAPIRequest(
  endpoint: 'https://api.yeshara.network/api/v1/users/login',
  method: 'POST',
  body: {'email': 'user@example.com', 'password': 'xxx'},
);
```
**Output**: `[DEBUG] POST https://api.yeshara.network/api/v1/users/login`

### 6. Log API Response
```dart
AppLogger.logAPIResponse(
  endpoint: 'https://api.yeshara.network/api/v1/users/login',
  method: 'POST',
  statusCode: 200,
  duration: Duration(milliseconds: 1500),
  response: {'success': true},
);
```
**Output**: `[SUCCESS] POST /api/v1/users/login - Status: 200`

## Log Levels

| Level | Usage | Example |
|-------|-------|---------|
| **INFO** | General information | `AppLogger.info(LogTags.auth, 'User logged in')` |
| **DEBUG** | Debug details | `AppLogger.debug(LogTags.api, 'Request sent')` |
| **WARNING** | Warnings | `AppLogger.warning(LogTags.storage, 'Low space')` |
| **ERROR** | Errors | `AppLogger.error(LogTags.api, 'Request failed', data: {...})` |
| **SUCCESS** | Success | `AppLogger.success(LogTags.kyc, 'KYC submitted')` |

## Log Tags

```dart
LogTags.auth          // Authentication
LogTags.kyc           // KYC
LogTags.payment       // Payments
LogTags.transaction   // Transactions
LogTags.navigation    // Navigation
LogTags.api           // API calls
LogTags.database      // Database
LogTags.camera        // Camera
LogTags.storage       // Storage
LogTags.validation    // Validation
```

## Sensitive Data

**Automatically Redacted:**
- password
- pin
- secret
- token
- api_key
- credit_card
- ssn
- cvv

## Example: Complete Flow

```dart
// User Registration
AppLogger.logUserRegistration({
  'email': 'john@example.com',
  'first_name': 'John',
  'last_name': 'Doe',
  'phone_number': '+254712345678',
});

// User Profile Loaded
AppLogger.logUserProfile({
  'id': 123,
  'email': 'john@example.com',
  'kyc_status': 'pending',
});

// KYC Image Uploads
AppLogger.logKYCImageUpload(
  imageType: 'ID_Front',
  imageUrl: 'https://...',
  fileSizeBytes: 1024000,
  uploadDuration: Duration(seconds: 3),
);

// KYC Submission
AppLogger.logKYCSubmission({
  'KYC': {
    'userID': 123,
    'ID_document': 'https://...',
    // ... other fields
  }
});
```

## Console Output Format

```
[TIMESTAMP] [LEVEL] [TAG] MESSAGE
  Data: 
    key1: value1
    key2: value2
```

### Example:
```
[2024-01-06 10:15:30.123] [SUCCESS] [USER_REGISTRATION] User registration completed
  Data: 
    email: john@example.com
    first_name: John
    last_name: Doe
    phone_number: +254712345678
```

## Viewing Logs

**Terminal:**
```bash
flutter run
```

**IDE Console:**
- Android Studio: View → Tool Windows → Logcat
- VS Code: View → Debug Console
- Xcode: View → Debug Area

## Best Practices

1. ✅ Use appropriate log levels
2. ✅ Include relevant context data
3. ✅ Use proper tags from LogTags
4. ✅ Log important lifecycle events
5. ✅ Track API request/response pairs
6. ✅ Include durations for performance analysis

## Error with Context

```dart
try {
  // operation
} catch (e, stackTrace) {
  AppLogger.error(
    LogTags.kyc,
    'KYC submission failed',
    data: {'user_id': userId},
    stackTrace: stackTrace,
  );
}
```

## Navigation Logging

```dart
AppLogger.logNavigation(
  from: 'LoginScreen',
  to: 'HomeScreen',
  arguments: {'user_id': 123},
);
```

---

For complete documentation, see: `LOGGING_DOCUMENTATION.md`
