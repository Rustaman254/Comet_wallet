# Complete User Flow: Registration → Login → Wallet Top-Up

## End-to-End User Journey

This document describes the complete flow from user registration through wallet top-up operations with token-based authentication.

---

## Phase 1: User Registration

### Step 1: Registration Screen
**File:** `lib/screens/sign_up_screen.dart`

User enters:
- Full name
- Email address
- Phone number
- Password

### Step 2: Backend Registration
**Service:** `lib/services/auth_service.dart` → `register()` method

```dart
Future<Map<String, dynamic>> register({
  required String fullName,
  required String email,
  required String phone,
  required String password,
}) async {
  // POST to /api/v1/users/create
  // Payload includes: fullName, email, phone, password
  // Response contains: user object, message
}
```

**API Request:**
```
POST https://api.yeshara.network/api/v1/users/create
Content-Type: application/json

{
  "full_name": "John Doe",
  "email": "john@example.com",
  "phone": "+254712345678",
  "password": "SecurePassword123!"
}
```

### Step 3: Registration Logging
**Service:** `lib/services/logger_service.dart`

```dart
AppLogger.logUserRegistration(
  email: email,
  phone: phone,
  fullName: fullName,
  timestamp: DateTime.now(),
);
```

**Log Record:**
```json
{
  "level": "INFO",
  "tag": "AUTH",
  "message": "User registration initiated",
  "timestamp": "2024-01-15T10:30:45.123Z",
  "data": {
    "email": "john@example.com",
    "phone": "+254712345678",
    "full_name": "John Doe"
  }
}
```

### Step 4: Post-Registration Redirect
**File:** `lib/screens/sign_up_screen.dart` → Success handler

```dart
// Upon successful registration
if (response['success'] == true) {
  AppLogger.success(
    LogTags.auth,
    'User registration completed',
    data: {'email': email}
  );
  
  // Navigate to sign-in screen
  if (mounted) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const SignInScreen(
          initialMessage: 'Account created successfully! Please log in.',
        ),
      ),
    );
  }
}
```

**UX Flow:**
```
Sign-Up Screen
      ↓
      [User enters details]
      ↓
      [Tap Register]
      ↓
      Loading indicator
      ↓
      API call to /users/create
      ↓
      Success → Log registration
      ↓
      Navigate to Sign-In Screen
      ↓
      Display message: "Account created successfully! Please log in."
```

---

## Phase 2: User Login with Token Management

### Step 1: Sign-In Screen
**File:** `lib/screens/sign_in_screen.dart`

User enters:
- Email address
- Password

### Step 2: Login API Call
**Service:** `lib/services/auth_service.dart` → `login()` method

```dart
Future<Map<String, dynamic>> login({
  required String email,
  required String password,
}) async {
  // POST to /api/v1/users/login
  // Payload includes: email, password
  // Response contains: token, user object
}
```

**API Request:**
```
POST https://api.yeshara.network/api/v1/users/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "SecurePassword123!"
}
```

**API Response:**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "12345",
    "email": "john@example.com",
    "phone": "+254712345678",
    "full_name": "John Doe",
    "phone": "+254712345678"
  }
}
```

### Step 3: Token Extraction & Storage
**Service:** `lib/services/auth_service.dart` → Login success handler

```dart
// Extract token from response
final token = jsonResponse['token'] ?? jsonResponse['access_token'] ?? '';
final userId = jsonResponse['user']?['id']?.toString() ?? '';

// Save to TokenService
if (token.isNotEmpty) {
  await TokenService.saveUserData(
    token: token,
    userId: userId,
    email: email,
    phoneNumber: jsonResponse['user']?['phone'] ?? '',
  );
  
  AppLogger.debug(
    LogTags.auth,
    'Authentication token saved',
    data: {'userId': userId}
  );
}
```

**TokenService Storage** (`lib/services/token_service.dart`):

```dart
// Stored in SharedPreferences with keys:
{
  'auth_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  'user_id': '12345',
  'user_email': 'john@example.com',
  'phone_number': '+254712345678'
}
```

### Step 4: Login Logging
**Service:** `lib/services/logger_service.dart`

```dart
AppLogger.info(
  LogTags.auth,
  'User login successful',
  data: {'email': email}
);
```

### Step 5: Navigate to Home Screen

```dart
// Upon successful login
if (mounted) {
  Navigator.of(context).pushReplacementNamed('/home');
}
```

**UX Flow:**
```
Sign-In Screen
      ↓
      [User enters email & password]
      ↓
      [Tap Sign In]
      ↓
      Loading indicator
      ↓
      API call to /users/login
      ↓
      Success response received
      ↓
      Extract token from response
      ↓
      Save to TokenService (SharedPreferences)
      ↓
      Log authentication event
      ↓
      Navigate to Home Screen
      ↓
      User sees home with action buttons
```

---

## Phase 3: Wallet Top-Up Flow

### Step 1: Home Screen - Top-Up Button
**File:** `lib/screens/home_screen.dart`

```dart
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

### Step 2: WalletTopupScreen Initialization
**File:** `lib/screens/wallet_topup_screen.dart`

```dart
@override
void initState() {
  super.initState();
  _loadUserPhone();
}

Future<void> _loadUserPhone() async {
  try {
    // Retrieve phone number from TokenService
    final phone = await TokenService.getPhoneNumber();
    if (mounted) {
      setState(() {
        _userPhoneNumber = phone;
        if (phone != null) {
          _phoneController.text = phone;
        }
      });
    }
  } catch (e) {
    AppLogger.error(
      LogTags.storage,
      'Failed to load user phone',
      data: {'error': e.toString()},
    );
  }
}
```

**UX Flow at this step:**
```
Home Screen
      ↓
      [User taps "Top-up" button]
      ↓
      Navigate to WalletTopupScreen
      ↓
      Screen initializes
      ↓
      Load phone from TokenService
      ↓
      Auto-fill phone field
      ↓
      Screen ready for user input
```

### Step 3: User Enters Top-Up Details
**File:** `lib/screens/wallet_topup_screen.dart`

User enters:
- **Phone Number:** Pre-filled, read-only
- **Amount:** User enters (e.g., 500)
- **Currency:** Select from dropdown (KES, USD, EUR)

**Form Validation:**
```dart
TextFormField(
  validator: (value) {
    if (value?.isEmpty ?? true) return 'Amount is required';
    try {
      final amount = double.parse(value!);
      if (amount <= 0) return 'Amount must be greater than 0';
      if (amount < 1) return 'Minimum top-up amount is 1 $_selectedCurrency';
    } catch (e) {
      return 'Please enter a valid amount';
    }
    return null;
  },
)
```

**Summary Display:**
```
Amount:    KES 500.00
─────────────────────
Total:     KES 500.00
```

### Step 4: User Submits Form
**File:** `lib/screens/wallet_topup_screen.dart`

```dart
Future<void> _handleTopup() async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      final phoneNumber = _phoneController.text.trim();

      AppLogger.info(
        LogTags.payment,
        'Initiating wallet top-up',
        data: {
          'phone_number': phoneNumber,
          'amount': amount,
          'currency': _selectedCurrency,
        },
      );

      // Call WalletService
      final response = await WalletService.topupWallet(
        phoneNumber: phoneNumber,
        amount: amount,
        currency: _selectedCurrency,
      );

      // ... success/error handling
    }
  }
}
```

### Step 5: WalletService Retrieves Token
**File:** `lib/services/wallet_service.dart`

```dart
static Future<Map<String, dynamic>> topupWallet({
  required String phoneNumber,
  required double amount,
  required String currency,
}) async {
  try {
    // Retrieve token from TokenService
    final token = await TokenService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication required. Please log in.');
    }

    // ... continue with API call
  }
}
```

### Step 6: Bearer Token Authentication
**File:** `lib/services/wallet_service.dart`

```dart
// Prepare request with Bearer token
final response = await http.post(
  Uri.parse(walletTopupEndpoint),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'phone_number': phoneNumber,
    'amount': amount,
    'currency': currency,
  }),
);
```

**Complete Request:**
```
POST https://api.yeshara.network/api/v1/wallet/topup HTTP/1.1
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "phone_number": "+254712345678",
  "amount": 500,
  "currency": "KES"
}
```

### Step 7: API Response Processing
**File:** `lib/services/wallet_service.dart`

**Success Response (200 OK):**
```json
{
  "success": true,
  "transaction_id": "TXN123456789",
  "balance": 5500,
  "message": "Top-up successful"
}
```

**Error Response (400 Bad Request):**
```json
{
  "success": false,
  "error": "Invalid amount",
  "message": "Amount must be at least 1"
}
```

**Error Response (401 Unauthorized):**
```json
{
  "success": false,
  "error": "Unauthorized",
  "message": "Invalid or expired token"
}
```

### Step 8: Response Handling & Logging
**File:** `lib/screens/wallet_topup_screen.dart`

```dart
if (mounted) {
  ToastService().showSuccess(
    context,
    'Top-up of $_selectedCurrency $amount successful!',
  );

  AppLogger.success(
    LogTags.payment,
    'Wallet top-up completed',
    data: {
      'amount': amount,
      'currency': _selectedCurrency,
      'response': response,
    },
  );

  // Navigate back after 1 second
  Future.delayed(const Duration(seconds: 1), () {
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  });
}
```

**Error Handling:**
```dart
catch (e) {
  if (mounted) {
    ToastService().showError(
      context,
      'Top-up failed: ${e.toString()}'
    );

    AppLogger.error(
      LogTags.payment,
      'Wallet top-up failed',
      data: {'error': e.toString()},
    );
  }
}
```

### Complete Transaction UX Flow:
```
Home Screen
      ↓
      [User taps Top-up]
      ↓
      WalletTopupScreen
      ↓
      [Phone pre-filled from TokenService]
      ↓
      [User enters amount: 500]
      ↓
      [User selects currency: KES]
      ↓
      [Summary displays: KES 500.00]
      ↓
      [User taps "Proceed to Payment"]
      ↓
      Loading indicator
      ↓
      WalletService.topupWallet() called
      ↓
      TokenService.getToken() retrieves saved token
      ↓
      API call: POST /wallet/topup
      ↓
      Authorization header: "Bearer {token}"
      ↓
      Request body: {phone, amount, currency}
      ↓
      Success response received
      ↓
      AppLogger records transaction
      ↓
      Toast: "Top-up successful!"
      ↓
      Navigate back to Home Screen
      ↓
      Home Screen refresh (optional)
```

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                     REGISTRATION PHASE                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  SignUpScreen                AuthService              API           │
│       │                            │                   │            │
│       │  register()                │                   │            │
│       ├───────────────────────────>│                   │            │
│       │                            │  POST /users/     │            │
│       │                            │  create           │            │
│       │                            ├──────────────────>│            │
│       │                            │                   │ Process    │
│       │                            │                   │            │
│       │                            │  Response         │            │
│       │                            │ (success)         │            │
│       │                            │<──────────────────┤            │
│       │  Log registration          │                   │            │
│       │  Redirect to SignIn        │                   │            │
│       │                            │                   │            │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      LOGIN PHASE                                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  SignInScreen              AuthService             TokenService    │
│       │                         │                        │          │
│       │  login()                │                        │          │
│       ├────────────────────────>│                        │          │
│       │                         │  POST /users/login     │          │
│       │                         ├──────────────────┐     │          │
│       │                         │                  │ API │          │
│       │                         │                  └────>│          │
│       │                         │<─────────────────┐     │          │
│       │                         │    Response      │     │          │
│       │                         │   (with token)   │     │          │
│       │                         │                  │     │          │
│       │<────────────────────────┤                  │     │          │
│       │  Extract token          │                  │     │          │
│       │  saveUserData()         │                  │     │          │
│       ├─────────────────────────────────────────────────>│          │
│       │                         │    Saved in SharedPrefs│          │
│       │  Log login              │                        │          │
│       │  Navigate to Home       │                        │          │
│       │                         │                        │          │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    TOP-UP PHASE                                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  HomeScreen   WalletTopupScreen   WalletService   TokenService    │
│       │              │                  │              │            │
│       │ [User taps]  │                  │              │            │
│       ├─────────────>│                  │              │            │
│       │              │ Load phone       │              │            │
│       │              ├──────────────────────────────────>│           │
│       │              │                  │    Retrieve  │           │
│       │              │<──────────────────────────────────┤           │
│       │              │ Phone loaded     │  Token/Phone │           │
│       │              │                  │              │            │
│       │              │ [User enters]    │              │            │
│       │              │ [Taps submit]    │              │            │
│       │              │                  │              │            │
│       │              ├─────────────────>│              │            │
│       │              │  topupWallet()   │              │            │
│       │              │                  ├─────────────>│            │
│       │              │                  │  getToken()  │            │
│       │              │                  │<─────────────┤            │
│       │              │                  │   Token      │            │
│       │              │                  │              │            │
│       │              │                  ├──────────────┐            │
│       │              │                  │              │ API Call  │
│       │              │                  │              │ with Auth │
│       │              │                  │              └─────────> │
│       │              │                  │                  API     │
│       │              │                  │<─────────────────────────┤
│       │              │                  │        Response          │
│       │              │<─────────────────┤                          │
│       │              │  Response        │                          │
│       │              │                  │                          │
│       │              │ Log transaction  │                          │
│       │              │ Show toast       │                          │
│       │              │ Navigate back    │                          │
│       │<─────────────┤                  │                          │
│       │              │                  │                          │
└─────────────────────────────────────────────────────────────────────┘
```

---

## State Persistence Across Sessions

### Scenario: User closes and reopens app

**Before (Registration Phase):**
- No authentication state stored
- User must register/login again

**After (Login Phase & Session Management):**
```dart
// On app startup (in main.dart or splash screen)
Future<void> _checkAuthStatus() async {
  bool isAuth = await TokenService.isAuthenticated();
  
  if (isAuth) {
    // Token exists - navigate to Home
    Navigator.pushReplacementNamed(context, '/home');
  } else {
    // No token - navigate to SignIn
    Navigator.pushReplacementNamed(context, '/signin');
  }
}
```

**TokenService Persistence:**
```dart
// Data stored in SharedPreferences (survives app restart)
{
  'auth_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  'user_id': '12345',
  'user_email': 'john@example.com',
  'phone_number': '+254712345678'
}
```

---

## Error Scenarios & Recovery

### Scenario 1: Invalid Credentials During Login

```
User enters wrong password
       ↓
API returns: {"success": false, "error": "Invalid credentials"}
       ↓
AuthService catches error
       ↓
AppLogger.error() called
       ↓
SignInScreen shows toast: "Invalid email or password"
       ↓
User stays on SignIn screen
       ↓
User can retry
```

### Scenario 2: Token Expired During Top-Up

```
User attempts top-up
       ↓
WalletService.getToken() retrieves expired token
       ↓
API returns: {"success": false, "error": "Unauthorized"}
       ↓
WalletService catches 401 error
       ↓
AppLogger.error() called
       ↓
WalletTopupScreen shows: "Session expired. Please log in again."
       ↓
Navigate to SignIn screen
       ↓
User logs in again (gets new token)
       ↓
Token updated in TokenService
```

### Scenario 3: Network Failure During Top-Up

```
User submits top-up
       ↓
Network error (SocketException)
       ↓
WalletService catches error
       ↓
AppLogger.error() called
       ↓
WalletTopupScreen shows: "Network connection failed"
       ↓
Button remains enabled
       ↓
User can retry (form values preserved)
```

---

## Logging Timeline

### Complete Event Log for One User Journey

```
[10:15:32] INFO  | AUTH  | User registration initiated
           data: {email: john@example.com, phone: +254712345678}

[10:15:35] SUCCESS | AUTH | User registration completed
           data: {email: john@example.com}

[10:16:00] INFO  | AUTH  | Login attempt
           data: {email: john@example.com}

[10:16:02] SUCCESS | AUTH | User login successful
           data: {email: john@example.com}

[10:16:02] DEBUG | AUTH | Authentication token saved
           data: {userId: 12345}

[10:20:45] INFO  | PAYMENT | Initiating wallet top-up
           data: {phone_number: +254712345678, amount: 500, currency: KES}

[10:20:47] DEBUG | API  | POST /wallet/topup request
           data: {url: https://api.yeshara.network/api/v1/wallet/topup}

[10:20:48] DEBUG | API  | Response received from POST /wallet/topup
           data: {status: 200, success: true}

[10:20:48] SUCCESS | PAYMENT | Wallet top-up completed
           data: {amount: 500, currency: KES, transaction_id: TXN123456}

[10:25:15] INFO  | AUTH | User logout
           data: {email: john@example.com}
```

---

## Complete Code Reference

### Key Files Involved

1. **lib/screens/sign_up_screen.dart**
   - User registration UI
   - Redirect to login on success

2. **lib/screens/sign_in_screen.dart**
   - User login UI
   - Navigate to home on success

3. **lib/screens/home_screen.dart**
   - Main app dashboard
   - Top-up button

4. **lib/screens/wallet_topup_screen.dart**
   - Top-up UI
   - Form validation
   - Error handling

5. **lib/services/auth_service.dart**
   - `register()` - User registration
   - `login()` - User authentication
   - Token extraction

6. **lib/services/wallet_service.dart**
   - `topupWallet()` - Process top-up
   - Bearer token authentication
   - API error handling

7. **lib/services/token_service.dart**
   - Token storage/retrieval
   - User data persistence
   - Authentication checks

8. **lib/services/logger_service.dart**
   - All event logging
   - Sensitive data redaction
   - Transaction tracking

---

## Testing Complete Flow

### Manual End-to-End Test

```
1. ✅ Open app
2. ✅ Register new account
   - Enter name: John Doe
   - Enter email: john@example.com
   - Enter phone: +254712345678
   - Enter password: SecurePass123!
   - Tap Register
   - Verify redirected to Sign-In screen
   - Check logs for registration event

3. ✅ Log in
   - Enter email: john@example.com
   - Enter password: SecurePass123!
   - Tap Sign In
   - Verify redirected to Home screen
   - Verify token saved (check SharedPreferences)
   - Check logs for login event

4. ✅ Navigate to Top-Up
   - Tap "Top-up" button on home
   - Verify WalletTopupScreen opens
   - Verify phone field auto-populated: +254712345678

5. ✅ Complete Top-Up
   - Enter amount: 1000
   - Select currency: KES
   - Verify summary: KES 1000.00
   - Tap "Proceed to Payment"
   - Verify loading indicator
   - Wait for API response
   - Verify success toast
   - Verify logged back to home
   - Check logs for transaction

6. ✅ Close and reopen app
   - Verify still logged in (home screen shown)
   - Verify token still available
   - Can perform top-up again without logging in
```

---

**Last Updated:** 2024
**Status:** Complete
**Documentation Completeness:** 100%
