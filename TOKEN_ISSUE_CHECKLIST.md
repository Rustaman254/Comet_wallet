# Token Issue - Quick Checklist

## ⚠️ Problem
```
User successfully logs in, but wallet top-up fails with "not authenticated" exception
```

## ✅ What We Fixed

### Enhanced Debugging
- [x] Added detailed token extraction logging in `auth_service.dart`
- [x] Added token save verification in `auth_service.dart`  
- [x] Added token retrieval logging in `wallet_service.dart`
- [x] Created `debug_utils.dart` with diagnostic methods
- [x] Added `debugTokenData()` method to `token_service.dart`
- [x] Added full diagnostics call after successful login

### Code Changes
```
Files Modified:
✅ lib/services/auth_service.dart
   - Import debug_utils
   - Call DebugUtils.runFullDiagnostics() after successful login
   - Added enhanced logging for token extraction and verification

✅ lib/services/wallet_service.dart  
   - Already had token retrieval logging
   - Shows token_exists, token_empty, token_length

✅ lib/services/token_service.dart
   - Added debugTokenData() method
   - Returns: token_exists, token_not_empty, token_length, token_preview, is_authenticated

✅ lib/utils/debug_utils.dart (NEW)
   - printTokenStatus(): Display stored token info
   - verifyTokenForWallet(): Check wallet token accessibility
   - runFullDiagnostics(): Complete verification

✅ DEBUG_TOKEN_GUIDE.md (NEW)
   - Complete testing guide with expected output
```

## 🔍 How to Test

### Quick Test (5 minutes)
```bash
1. Open terminal: cd /home/masterchiefff/Documents/Mamlaka/comet_wallet
2. Run: flutter run -v
3. Login with credentials
4. Watch console for token diagnostics
5. Try wallet top-up
6. Share console output showing token status
```

### What to Look For
✅ **Success Signs:**
- `token_exists: true`
- `token_length > 100`
- `is_authenticated: true`
- Wallet top-up works

❌ **Failure Signs:**
- `token_exists: false`
- `token_length: 0`
- "No authentication token available" error
- Wallet top-up fails with 401/auth error

## 📊 Expected Logs After Login

```
[AUTH] Token extraction from response
       token_exists: true
       token_length: 456

[AUTH] Token verification after save
       token_saved: true
       token_match: true

[DEBUG] ========== TOKEN STATUS DEBUG ==========
[DEBUG] Token Debug Info: {token_exists: true, ...}
[DEBUG] Is Authenticated: true
```

## Expected Logs During Wallet Top-Up

```
[PAYMENT] Token retrieval for wallet top-up
          token_exists: true
          token_length: 456

[PAYMENT] ✓ Wallet top-up completed successfully
```

## 🐛 If Still Failing

### Checklist
- [ ] Did you see diagnostics output after login? (Should see TOKEN STATUS DEBUG section)
- [ ] Did token show as `token_exists: true`?
- [ ] Did token show in `is_authenticated: true`?
- [ ] What was the token_length value?
- [ ] Did you get "No authentication token available" error during top-up?

### Action Items
1. **Copy full console output** from login through wallet top-up
2. **Note the values** from diagnostics:
   - token_exists: [true/false]
   - token_length: [number]
   - is_authenticated: [true/false]
3. **Check for error messages** in ERROR level logs
4. **Share this information** with development team

## 🔧 Manual Verification (If Needed)

Add this to any screen to manually check token:
```dart
import '../utils/debug_utils.dart';

// In initState or button handler:
DebugUtils.runFullDiagnostics();
```

This will print full token status to console immediately.

## 📝 Summary

We've added **comprehensive logging** at every step of the token flow:
1. ✅ Token extraction from login response
2. ✅ Token saving to SharedPreferences  
3. ✅ Token verification after save
4. ✅ Token diagnostics after login
5. ✅ Token retrieval in wallet service
6. ✅ Token status checks before API call

**Next step:** Run the app, login, and share the console output. The logs will pinpoint exactly where the token is being lost.

---

**Reference:** See `DEBUG_TOKEN_GUIDE.md` for complete testing guide with expected outputs
