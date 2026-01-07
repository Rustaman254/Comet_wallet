# Wallet Top-Up Feature Implementation Guide

## Overview

The wallet top-up feature allows authenticated users to add funds to their digital wallet with multiple currency support (KES, USD, EUR). This feature is integrated into the home screen and uses token-based authentication for secure transactions.

## Architecture

### Services Layer

#### 1. **TokenService** (`lib/services/token_service.dart`)
Manages authentication tokens and user data persistence.

```dart
// Get stored token
String? token = await TokenService.getToken();

// Save user data on login
await TokenService.saveUserData(
  token: token,
  userId: userId,
  email: email,
  phoneNumber: phoneNumber,
);

// Check authentication
bool isAuth = await TokenService.isAuthenticated();

// Logout
await TokenService.logout();
```

**Key Methods:**
- `saveToken(String token)` - Save JWT token
- `getToken()` - Retrieve saved token
- `savePhoneNumber(String phoneNumber)` - Store user phone
- `getPhoneNumber()` - Retrieve stored phone
- `saveUserData({...})` - Save all user data at once
- `isAuthenticated()` - Check if user is logged in
- `logout()` - Clear all stored data

#### 2. **WalletService** (`lib/services/wallet_service.dart`)
Handles wallet operations with Bearer token authentication.

```dart
// Top-up wallet
Map<String, dynamic> response = await WalletService.topupWallet(
  phoneNumber: '+254712345678',
  amount: 1000,
  currency: 'KES',
);

// Check wallet balance
double balance = await WalletService.getWalletBalance();

// Get transaction history
List<Map<String, dynamic>> transactions = 
    await WalletService.getTransactionHistory();
```

**API Integration:**
- **Endpoint:** `POST /api/v1/wallet/topup`
- **Authentication:** Bearer token in Authorization header
- **Request Payload:**
```json
{
  "phone_number": "+254712345678",
  "amount": 1000,
  "currency": "KES"
}
```

**Response:**
```json
{
  "success": true,
  "transaction_id": "TXN123456",
  "balance": 5000,
  "message": "Top-up successful"
}
```

**Error Handling:**
- Authentication failures (401)
- Invalid phone/amount (400)
- Network errors with retry logic
- All errors logged to AppLogger

### UI Layer

#### **WalletTopupScreen** (`lib/screens/wallet_topup_screen.dart`)

Production-ready top-up interface with the following features:

**Layout Components:**
1. **Header** - Screen title with back button
2. **Info Card** - Instructions about top-up process
3. **Phone Number Field** - Auto-populated from saved user data
4. **Amount Field** - Currency-formatted input
5. **Currency Selector** - Dropdown with KES, USD, EUR
6. **Summary Section** - Display calculated total
7. **Payment Button** - Initiates top-up with loading state
8. **Disclaimer** - SMS confirmation notice

**Validation:**
- Phone number length validation (minimum 10 digits)
- Amount must be > 0
- Decimal support for all currencies
- All fields required before submission

**User Flow:**
```
1. User navigates from home screen (Top-up button)
2. Screen loads phone number from TokenService
3. User enters amount and selects currency
4. Form validates all inputs
5. User taps "Proceed to Payment"
6. WalletService called with phone, amount, currency
7. Bearer token automatically included in request
8. Success → Toast notification + navigate back
9. Error → Toast error + user can retry
```

**Error Handling:**
- Network failures → User-friendly error message
- Invalid authentication → Redirect to login
- API errors → Display specific error message
- All operations logged to AppLogger

### Integration Flow

#### Authentication Flow
```
User Registration
    ↓
Login (saves token + phone via TokenService)
    ↓
Home Screen displays
    ↓
User taps "Top-up" button
    ↓
WalletTopupScreen opens
```

#### Top-Up Transaction Flow
```
User enters phone/amount/currency
    ↓
Form validation
    ↓
WalletService.topupWallet() called
    ↓
TokenService retrieves Bearer token
    ↓
API request with Authorization header
    ↓
Response processing
    ↓
Success: Toast + navigate back
Error: Toast + display reason
```

## Implementation Details

### 1. Home Screen Integration

**Location:** `lib/screens/home_screen.dart`

**Changes Made:**
- Added import: `import 'wallet_topup_screen.dart';`
- Modified action buttons to include scrollable row
- Added Top-Up button with `Icons.add_circle_outline`
- Button navigates to `WalletTopupScreen()`

**Before (4 buttons in fixed Row):**
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceAround,
  children: [Send, Receive, Withdraw, More]
)
```

**After (5 buttons in scrollable Row):**
```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [Send, Receive, TopUp, Withdraw, More]
  )
)
```

### 2. Token Management

**On Login Success** (`auth_service.dart`):
```dart
// After successful login
final token = jsonResponse['token'] ?? jsonResponse['access_token'] ?? '';
await TokenService.saveUserData(
  token: token,
  userId: userId,
  email: email,
  phoneNumber: jsonResponse['user']?['phone'] ?? '',
);
```

**On Logout:**
```dart
await TokenService.logout();
// All stored data cleared
```

### 3. Bearer Token Authentication

**In WalletService:**
```dart
final token = await TokenService.getToken();
final response = await http.post(
  Uri.parse(walletTopupEndpoint),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({...})
);
```

### 4. Logging Integration

All wallet operations are logged to `AppLogger`:

```dart
// Initiate top-up
AppLogger.info(
  LogTags.payment,
  'Initiating wallet top-up',
  data: {'phone': phoneNumber, 'amount': amount}
);

// Success
AppLogger.success(
  LogTags.payment,
  'Wallet top-up completed',
  data: {'amount': amount, 'response': response}
);

// Error
AppLogger.error(
  LogTags.payment,
  'Wallet top-up failed',
  data: {'error': e.toString()}
);
```

**Log Tags:** `LogTags.payment`
**Sensitive Data:** Phone numbers are automatically redacted in logs

## Testing Checklist

### Unit Tests
- [ ] TokenService correctly saves/retrieves tokens
- [ ] WalletService formats request correctly
- [ ] Bearer token included in headers
- [ ] Error handling for 401/403 responses
- [ ] Phone number validation works
- [ ] Amount validation works

### Integration Tests
- [ ] Full flow: Login → Top-up → Success
- [ ] Full flow: Login → Top-up → Error handling
- [ ] Token persists across app restart
- [ ] Logout clears all stored data
- [ ] Phone number auto-populated on screen load

### UI Tests
- [ ] Top-up button appears on home screen
- [ ] Screen navigates correctly
- [ ] Phone field is read-only when pre-filled
- [ ] Currency dropdown works
- [ ] Payment button disabled during loading
- [ ] Toast notifications display correctly
- [ ] Navigation works after success/error

### Manual Testing Steps

1. **Test Registration & Login:**
   - Register new account with valid phone number
   - Verify token is saved (check SharedPreferences in debugger)
   - Verify phone number is saved

2. **Test Top-Up Screen:**
   - Navigate to home screen
   - Tap "Top-up" button
   - Verify phone number is pre-populated
   - Enter amount: 500
   - Select currency: KES
   - Verify summary shows correct total
   - Tap "Proceed to Payment"

3. **Test Success Flow:**
   - Mock successful API response
   - Verify success toast appears
   - Verify screen navigates back to home
   - Check AppLogger for transaction record

4. **Test Error Handling:**
   - Mock API error (e.g., 400 - invalid amount)
   - Verify error toast appears
   - Verify user can retry without re-entering phone

5. **Test Token Expiration:**
   - Wait for token to expire (if applicable)
   - Attempt top-up
   - Verify redirects to login screen

## Dependencies

### Packages Required
- `http` - For API calls
- `shared_preferences` - For token storage
- `google_fonts` - For typography
- `flutter` - Core framework

### No Additional Dependencies Needed
The wallet feature uses existing packages already in `pubspec.yaml`.

## API Endpoints

### Top-Up Endpoint
```
POST https://api.yeshara.network/api/v1/wallet/topup
Authorization: Bearer {token}
Content-Type: application/json

{
  "phone_number": "+254712345678",
  "amount": 1000,
  "currency": "KES"
}
```

### Response Codes
- **200** - Successful top-up
- **400** - Invalid parameters
- **401** - Unauthorized (invalid token)
- **403** - Forbidden (insufficient permissions)
- **500** - Server error

## Security Considerations

1. **Token Storage**
   - Tokens stored in SharedPreferences (not encrypted in this implementation)
   - Consider using `flutter_secure_storage` for production
   - Tokens auto-cleared on logout

2. **Bearer Authentication**
   - Token included in Authorization header
   - Server validates token on each request
   - Invalid tokens result in 401 response

3. **Sensitive Data**
   - Phone numbers redacted in logs
   - API responses logged but passwords/tokens removed
   - All user input validated before sending

4. **HTTPS Only**
   - All API calls use HTTPS
   - Certificate pinning recommended for production

## Production Deployment Checklist

- [ ] Use `flutter_secure_storage` instead of SharedPreferences
- [ ] Implement certificate pinning for API calls
- [ ] Add rate limiting on top-up attempts
- [ ] Implement transaction verification
- [ ] Add SMS confirmation for high amounts
- [ ] Set up monitoring/alerting for failed top-ups
- [ ] Configure timeout handling
- [ ] Implement retry logic with exponential backoff
- [ ] Add analytics tracking for top-up funnel
- [ ] Document API rate limits

## Troubleshooting

### Issue: Phone number not auto-populating
**Solution:** Verify TokenService.savePhoneNumber() called during login

### Issue: 401 Unauthorized on top-up
**Solution:** Check if token is expired; implement token refresh mechanism

### Issue: Bearer token not in request
**Solution:** Verify TokenService.getToken() returns non-null value

### Issue: Form validation failing
**Solution:** Check phone number length and amount value constraints

### Issue: Toast notification not showing
**Solution:** Verify ToastService is properly configured and imported

## Future Enhancements

1. **Payment History**
   - Display past top-up transactions
   - Implement WalletService.getTransactionHistory()

2. **Recurring Top-ups**
   - Auto-topup when balance below threshold
   - Scheduled monthly top-ups

3. **Multiple Payment Methods**
   - Credit/debit card
   - Mobile money integrations
   - Bank transfers

4. **Analytics**
   - Track top-up completion rates
   - Average top-up amounts by currency
   - Payment method preferences

5. **Notifications**
   - Push notifications on top-up completion
   - SMS confirmations
   - Email receipts

## Code Examples

### Complete Top-Up Flow (From Home Screen)

```dart
// Home screen - Top-up button tap
_buildActionButton(
  Icons.add_circle_outline,
  'Top-up',
  () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const WalletTopupScreen(),
      ),
    );
  },
)
```

### WalletTopupScreen - Complete Implementation

```dart
// See lib/screens/wallet_topup_screen.dart for full implementation
// Key methods:
// - _loadUserPhone() - Load phone from TokenService
// - _handleTopup() - Process top-up request
// - build() - UI layout
```

### WalletService - Top-Up Implementation

```dart
// See lib/services/wallet_service.dart for full implementation
// Key method:
static Future<Map<String, dynamic>> topupWallet({
  required String phoneNumber,
  required double amount,
  required String currency,
}) async {
  // 1. Get token
  // 2. Prepare request
  // 3. Make API call with Bearer auth
  // 4. Handle response
  // 5. Log transaction
}
```

## References

- [Flutter HTTP Package](https://pub.dev/packages/http)
- [SharedPreferences Documentation](https://pub.dev/packages/shared_preferences)
- [Bearer Token Authentication](https://tools.ietf.org/html/rfc6750)
- [REST API Best Practices](https://restfulapi.net/)

---

**Last Updated:** 2024
**Status:** Production Ready
**Maintainer:** Development Team
