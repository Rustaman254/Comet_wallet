# Logging System Documentation

## Overview

The Comet Wallet application includes a comprehensive logging system that tracks all important events, API calls, KYC submissions, user registrations, and error handling. All logs are visible in the terminal/console during development.

## Logger Service Architecture

### Main Components

1. **AppLogger** - Main logging singleton
2. **LogLevel** - Log level constants (INFO, DEBUG, WARNING, ERROR, SUCCESS)
3. **LogTags** - Predefined tags for different modules

## Log Levels

### INFO
General informational messages about app operations.
```dart
AppLogger.info(LogTags.auth, 'User logged in', data: {'email': 'user@example.com'});
```

### DEBUG
Detailed debug information (only visible in debug mode).
```dart
AppLogger.debug(LogTags.kyc, 'Starting image upload', data: {'file_path': '/path/to/image'});
```

### WARNING
Warning messages for potentially problematic situations.
```dart
AppLogger.warning(LogTags.storage, 'Low storage space', data: {'available_mb': 100});
```

### ERROR
Error messages with full error context.
```dart
AppLogger.error(
  LogTags.api,
  'API request failed',
  data: {'status_code': 500},
  stackTrace: stackTrace,
);
```

### SUCCESS
Messages for successful completion of operations.
```dart
AppLogger.success(LogTags.kyc, 'KYC submission completed', data: {'user_id': 123});
```

## Log Tags

Pre-defined tags for different modules:

- `LogTags.auth` - Authentication operations
- `LogTags.kyc` - KYC operations
- `LogTags.payment` - Payment operations
- `LogTags.transaction` - Transaction operations
- `LogTags.navigation` - Navigation events
- `LogTags.api` - API calls
- `LogTags.database` - Database operations
- `LogTags.camera` - Camera operations
- `LogTags.storage` - Storage operations
- `LogTags.validation` - Validation operations

## Usage Examples

### User Registration Logging

When a user registers, the following logs are created:

```dart
// In AuthService.register()
AppLogger.logUserRegistration({
  'email': email,
  'first_name': firstName,
  'last_name': lastName,
  'phone_number': phoneNumber,
  'timestamp': DateTime.now().toIso8601String(),
});
```

**Console Output:**
```
[2024-01-06 10:15:30.123] [SUCCESS] [USER_REGISTRATION] User registration completed
  Data: 
    email: user@example.com
    first_name: John
    last_name: Doe
    phone_number: +254712345678
    timestamp: 2024-01-06T10:15:30.123456Z
```

### KYC Image Upload Logging

When images are uploaded during KYC:

```dart
// In KYCService.uploadImage()
AppLogger.logKYCImageUpload(
  imageType: 'ID_Front',
  imageUrl: 'https://images.cradlevoices.com/uploads/...',
  fileSizeBytes: 1024000,
  uploadDuration: Duration(seconds: 5),
);
```

**Console Output:**
```
[2024-01-06 10:16:45.567] [INFO] [KYC_IMAGE_UPLOAD] KYC image uploaded: ID_Front
  Data: 
    type: ID_Front
    url: https://images.cradlevoices.com/uploads/1738562610_41434c2f1a.webp
    file_size_kb: 1000.00
    upload_duration_ms: 5000
```

### KYC Submission Logging

When KYC data is submitted:

```dart
// In KYCService.submitKYC()
AppLogger.logKYCSubmission({
  'KYC': {
    'userID': 12,
    'ID_document': 'https://images.cradlevoices.com/uploads/...',
    'ID_document_back': 'https://images.cradlevoices.com/uploads/...',
    'KRA_document': 'https://images.cradlevoices.com/uploads/...',
    'profile_photo': 'https://images.cradlevoices.com/uploads/...',
    'proof_of_address': 'https://images.cradlevoices.com/uploads/...',
  }
});
```

**Console Output:**
```
[2024-01-06 10:18:22.890] [SUCCESS] [KYC_SUBMISSION] KYC submission completed
  Data: 
    KYC:
      userID: 12
      ID_document: https://images.cradlevoices.com/uploads/...
      ID_document_back: https://images.cradlevoices.com/uploads/...
      KRA_document: https://images.cradlevoices.com/uploads/...
      profile_photo: https://images.cradlevoices.com/uploads/...
      proof_of_address: https://images.cradlevoices.com/uploads/...
```

### User Profile Logging

When user profile is loaded:

```dart
// In AuthService.loadUserProfile()
AppLogger.logUserProfile({
  'id': 123,
  'email': 'user@example.com',
  'first_name': 'John',
  'last_name': 'Doe',
  'phone_number': '+254712345678',
  'kyc_status': 'verified',
  'account_balance': 5000.00,
  'created_at': '2024-01-01T00:00:00Z',
});
```

**Console Output:**
```
[2024-01-06 10:20:00.123] [INFO] [USER_PROFILE] User profile loaded
  Data: 
    id: 123
    email: user@example.com
    first_name: John
    last_name: Doe
    phone_number: +254712345678
    kyc_status: verified
    account_balance: 5000.00
    created_at: 2024-01-01T00:00:00Z
```

### API Request/Response Logging

#### Request:
```dart
AppLogger.logAPIRequest(
  endpoint: ApiConstants.loginEndpoint,
  method: 'POST',
  body: requestBody,
);
```

**Console Output:**
```
[2024-01-06 10:15:15.456] [DEBUG] [API_REQUEST] POST https://api.yeshara.network/api/v1/users/login
  Data: 
    endpoint: https://api.yeshara.network/api/v1/users/login
    method: POST
    body: 
      email: user@example.com
      password: ***REDACTED***
```

#### Response:
```dart
AppLogger.logAPIResponse(
  endpoint: ApiConstants.loginEndpoint,
  method: 'POST',
  statusCode: 200,
  duration: Duration(milliseconds: 1500),
  response: jsonResponse,
);
```

**Console Output:**
```
[2024-01-06 10:15:16.956] [SUCCESS] [API_RESPONSE] POST https://api.yeshara.network/api/v1/users/login - Status: 200
  Data: 
    endpoint: https://api.yeshara.network/api/v1/users/login
    status_code: 200
    duration_ms: 1500
    response: {...}
```

## Sensitive Data Protection

The logger automatically redacts sensitive information:

### Redacted Keys:
- `password`
- `pin`
- `secret`
- `token`
- `apikey` / `api_key`
- `privatekey` / `private_key`
- `authorization`
- `authtoken` / `auth_token`
- `ssn` / `socialSecurityNumber`
- `creditCard` / `credit_card`
- `cvv` / `cvc`
- `accountNumber` / `account_number`
- `routingNumber` / `routing_number`

### Example:
```dart
AppLogger.info('AUTH', 'Login attempt', data: {
  'email': 'user@example.com',
  'password': 'mypassword123',  // Will be redacted
});
```

**Console Output:**
```
[2024-01-06 10:15:30.123] [INFO] [AUTH] Login attempt
  Data: 
    email: user@example.com
    password: ***REDACTED***
```

## Error Logging

### Basic Error:
```dart
try {
  // operation
} catch (e) {
  AppLogger.error(
    LogTags.api,
    'API call failed',
    data: {'error': e.toString()},
  );
}
```

### Error with Full Context:
```dart
try {
  // operation
} catch (e, stackTrace) {
  AppLogger.logErrorWithContext(
    tag: LogTags.kyc,
    message: 'KYC submission failed',
    error: e,
    stackTrace: stackTrace,
    context: {
      'user_id': userId,
      'attempt': 1,
    },
  );
}
```

**Console Output:**
```
[2024-01-06 10:18:00.789] [ERROR] [KYC] Error occurred
  Data: 
    message: KYC submission failed
    error: SocketException: Connection refused
    user_id: 123
    attempt: 1
Stack Trace: #0 _KYCState._submitKYC
#1 _KYCState.build.<anonymous closure>
...
```

## Navigation Logging

```dart
AppLogger.logNavigation(
  from: 'LoginScreen',
  to: 'HomeScreen',
  arguments: {'user_id': 123},
);
```

**Console Output:**
```
[2024-01-06 10:15:45.123] [DEBUG] [NAVIGATION] Navigate from LoginScreen to HomeScreen
  Data: 
    from: LoginScreen
    to: HomeScreen
    arguments: 
      user_id: 123
```

## App Lifecycle Logging

```dart
// In main.dart or state managers
AppLogger.logAppLifecycle('App launched');
AppLogger.logAppLifecycle('App paused');
AppLogger.logAppLifecycle('App resumed');
AppLogger.logAppLifecycle('App detached');
```

**Console Output:**
```
[2024-01-06 10:00:00.000] [INFO] [APP_LIFECYCLE] App launched
  Data: 
    event: App launched
    timestamp: 2024-01-06T10:00:00.000000Z
```

## Log Output Format

```
[TIMESTAMP] [LEVEL] [TAG] MESSAGE
  Data: 
    key1: value1
    key2: value2
    ...
```

### Example Full Log:
```
[2024-01-06 10:15:30.123] [SUCCESS] [USER_REGISTRATION] User registration completed
  Data: 
    email: user@example.com
    first_name: John
    last_name: Doe
    phone_number: +254712345678
    timestamp: 2024-01-06T10:15:30.123456Z
```

## Viewing Logs

### In Terminal/Console:
Logs are printed to stdout and visible in the Flutter debug console:
```bash
flutter run
```

### In IDE:
- **Android Studio**: View → Tool Windows → Logcat
- **VS Code**: View → Debug Console
- **Xcode**: View → Debug Area

### Long String Handling:
Strings longer than 100 characters are automatically truncated with "..." for readability:
```
[2024-01-06 10:15:30.123] [INFO] [API] Response received
  Data: 
    response_body: {"user":{"id":123,"email":"user@example.com","profile":"very long...
```

## Performance Considerations

- Logging is optimized for minimal performance impact
- Large data structures are handled efficiently
- Timestamps use millisecond precision
- Resource cleanup is automatic

## Best Practices

1. **Use appropriate log levels** - Don't log everything as INFO
2. **Include context** - Always provide relevant data with logs
3. **Use proper tags** - Choose descriptive tags from LogTags
4. **Avoid logging sensitive data** - The logger will redact, but avoid when possible
5. **Log start and end of operations** - For performance tracking
6. **Include duration for async operations** - Helps identify performance issues

## Integration in Services

All main services (Auth, KYC, Payment, etc.) are integrated with AppLogger:

- **AuthService**: Logs registration, login, profile loading
- **KYCService**: Logs image uploads, submissions, complete flow
- **Future services**: Payment, Transaction services should follow the same pattern

## Testing Logs

To verify logging is working correctly:

```dart
void main() {
  AppLogger.info(LogTags.auth, 'Logger initialized');
  AppLogger.debug(LogTags.api, 'Debug logging active');
  AppLogger.success(LogTags.kyc, 'All systems operational');
  runApp(const CometWallet());
}
```

Expected output:
```
[2024-01-06 10:00:00.123] [INFO] [AUTH] Logger initialized
[2024-01-06 10:00:00.124] [DEBUG] [API] Debug logging active
[2024-01-06 10:00:00.125] [SUCCESS] [KYC] All systems operational
```
