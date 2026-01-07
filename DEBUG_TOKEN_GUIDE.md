# Token Authentication Debugging Guide

## Issue
User reports: "I logged in but when I try to topup I get the exception that I am not authenticated."

This means the token is not being retrieved during wallet top-up, even though login succeeded.

## What Was Changed
We added comprehensive debug logging and a diagnostics utility to track the token flow:

### 1. Enhanced Logging in `auth_service.dart`
- Logs token extraction from response: `token_exists`, `token_length`
- Logs token save to TokenService with user details
- Verifies token was saved by retrieving it: `token_saved`, `token_match`
- Added diagnostics after successful login

### 2. Enhanced Logging in `wallet_service.dart`
- Logs token retrieval status before API call
- Shows: `token_exists`, `token_empty`, `token_length`
- Enhanced error message if token missing

### 3. New `token_service.dart` Debug Method
- Added `debugTokenData()` method that returns:
  - `token_exists`: Whether token is stored
  - `token_not_empty`: Whether token has content
  - `token_length`: Length of stored token
  - `token_preview`: First 20 chars of token for verification
  - `is_authenticated`: Overall auth status

### 4. New `debug_utils.dart`
- `printTokenStatus()`: Shows all stored token data
- `verifyTokenForWallet()`: Checks if token is accessible during wallet operations
- `runFullDiagnostics()`: Complete token flow verification

## How to Test

### Step 1: Enable Debug Logging
The debug logging is already enabled. When you run the app, logs will show in the console.

### Step 2: Run the App
```bash
cd /path/to/comet_wallet
flutter run -v  # -v flag shows all logs
```

### Step 3: Test Login Flow
1. Open the app
2. Navigate to login screen
3. Enter valid credentials
4. **WATCH THE CONSOLE** for these messages:

**Expected Console Output After Successful Login:**
```
[AUTH] Token extraction from response
       - token_exists: true
       - token_length: 456 (or similar large number)
       - user_id: <user-id>
       - phone: <phone-number>

[AUTH] Authentication token saved to TokenService
       - user_id: <user-id>
       - phone: <phone-number>

[AUTH] Token verification after save
       - token_saved: true
       - token_match: true

[AUTH] User login successful

╔════════════════════════════════════════╗
║  COMET WALLET - TOKEN DIAGNOSTICS  ║
╚════════════════════════════════════════╝

[DEBUG] Token Debug Info: {
  'token_exists': true,
  'token_not_empty': true,
  'token_length': 456,
  'token_preview': 'eyJhbGciOiJIUzI1NiI...',
  'is_authenticated': true
}

[DEBUG] User Data: {
  'token': 'eyJhbGciOiJIUzI1NiI...',
  'user_id': '<user-id>',
  'email': '<email>',
  'phone_number': '<phone>'
}

[DEBUG] Is Authenticated: true
```

### Step 4: Test Wallet Top-Up
1. After successful login, navigate to wallet top-up screen
2. Enter phone number, amount, and currency
3. Tap "Top Up" button
4. **WATCH THE CONSOLE** for these messages:

**Expected Console Output Before API Call:**
```
[PAYMENT] Token retrieval for wallet top-up
          - token_exists: true
          - token_empty: false
          - token_length: 456

[PAYMENT] Wallet top-up initiated
          - phone_number: <phone>
          - amount: <amount>
          - currency: <currency>

[API] POST /wallet/topup
      Headers: Authorization: Bearer eyJhbGciOiJIUzI1NiI...
      Body: {"phone_number": "<phone>", "amount": <amount>, "currency": "<currency>"}

[PAYMENT] ✓ Wallet top-up completed successfully
```

**If you get "NOT AUTHENTICATED" error, console will show:**
```
[PAYMENT] Token retrieval for wallet top-up
          - token_exists: FALSE or EMPTY
          - token_empty: true
          - token_length: 0

[ERROR] [PAYMENT] No authentication token available
        - token_null: true
        - token_empty: true
```

## What to Look For

### Success Indicators
- ✅ `token_exists: true` in diagnostics
- ✅ `token_length` > 100 (JWT tokens are long)
- ✅ `is_authenticated: true`
- ✅ Both `token_saved` and `token_match` are true
- ✅ Token preview starts with "eyJ" (JWT format)

### Failure Indicators
- ❌ `token_exists: false`
- ❌ `token_length: 0`
- ❌ `is_authenticated: false`
- ❌ `token_saved: false` or `token_match: false`
- ❌ Error message about no authentication token

## Possible Issues & Solutions

### Issue 1: Token Not Extracted from Response
**Sign:** `token_exists: false` in auth logs
**Cause:** Login response structure different than expected
**Solution:** 
1. Check console for: "Token not found in login response"
2. Look for: `response_keys: [...]`
3. Report the actual keys back - the response structure may have changed

### Issue 2: Token Saved but Can't Retrieve
**Sign:** `token_saved: true` but `token_exists: false` in wallet service
**Cause:** SharedPreferences issue or async timing
**Solution:**
1. Check for Android/iOS permission issues
2. Ensure app has storage permissions
3. Try reinstalling the app: `flutter clean && flutter run`

### Issue 3: Token Expires Too Quickly
**Sign:** Login works, but after a few seconds token becomes invalid
**Cause:** Token TTL (time-to-live) is very short
**Solution:**
1. Check token expiration time (JWT tokens have `exp` claim)
2. May need to implement token refresh mechanism

### Issue 4: Multiple Logins Overwriting Token
**Sign:** Second login works, but first user's wallet top-up fails
**Cause:** Each login overwrites the token for all users
**Solution:**
1. This is expected behavior for single-device app
2. User should not be logged in as multiple users simultaneously

## Direct Testing Command

If you want to test the token status without going through the whole flow, you can call the diagnostics directly by adding this to any screen's init method:

```dart
import '../utils/debug_utils.dart';

@override
void initState() {
  super.initState();
  DebugUtils.runFullDiagnostics(); // Prints token status to console
}
```

## Log Levels Explained

- **[DEBUG]** - Detailed diagnostic information
- **[INFO]** - General information about flow
- **[SUCCESS]** - Operation completed successfully  
- **[ERROR]** - Something went wrong
- **[API]** - API request/response details

## Next Steps After Testing

1. Run the test flow described above
2. **Copy the console output**
3. Share the output showing:
   - Token extraction phase
   - Token save verification
   - Wallet top-up token retrieval
4. Based on logs, we can identify the exact failure point

## File Locations for Reference

- Auth service logs: `lib/services/auth_service.dart` (lines 140-180)
- Wallet service logs: `lib/services/wallet_service.dart` (lines 18-40)
- Token service: `lib/services/token_service.dart` (lines 100-115)
- Debug utilities: `lib/utils/debug_utils.dart`
- Logger: `lib/services/logger_service.dart`
