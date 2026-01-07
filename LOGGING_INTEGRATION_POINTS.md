# Logging System - Integration Points

This document shows exactly where and how to integrate the logging system into your existing screens and services.

## Integration Checklist

- [x] Logger service created
- [x] Auth service with logging created
- [x] KYC service updated with logging
- [x] Example screen created
- [ ] Integrate into SignUp screen
- [ ] Integrate into Login screen
- [ ] Integrate into KYC screens
- [ ] Integrate into Payment screens
- [ ] Add app lifecycle logging to main.dart

## 1. Main.dart - App Lifecycle

```dart
import 'package:comet_wallet/services/logger_service.dart';

void main() {
  // Log app initialization
  AppLogger.logAppLifecycle('App initialized');
  runApp(const CometWallet());
}

class CometWallet extends StatefulWidget {
  const CometWallet({super.key});

  @override
  State<CometWallet> createState() => _CometWalletState();
}

class _CometWalletState extends State<CometWallet> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppLogger.logAppLifecycle('App started');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        AppLogger.logAppLifecycle('App resumed');
        break;
      case AppLifecycleState.paused:
        AppLogger.logAppLifecycle('App paused');
        break;
      case AppLifecycleState.detached:
        AppLogger.logAppLifecycle('App detached');
        break;
      case AppLifecycleState.inactive:
        AppLogger.logAppLifecycle('App inactive');
        break;
      case AppLifecycleState.hidden:
        AppLogger.logAppLifecycle('App hidden');
        break;
    }
  }
}
```

## 2. Sign-Up Screen Integration

```dart
import 'package:comet_wallet/services/auth_service.dart';
import 'package:comet_wallet/services/logger_service.dart';

class SignUpScreen extends StatefulWidget {
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleSignUp() async {
    try {
      AppLogger.info(
        LogTags.auth,
        'Sign up initiated',
        data: {'email': _emailController.text},
      );

      final response = await AuthService.register(
        email: _emailController.text,
        password: _passwordController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phoneNumber: _phoneController.text,
      );

      if (mounted) {
        AppLogger.success(
          LogTags.auth,
          'User registration flow completed',
          data: {
            'email': _emailController.text,
            'response': response,
          },
        );

        // Navigate to next screen
        Navigator.of(context).pushReplacementNamed('/kyc-intro');
      }
    } catch (e) {
      AppLogger.error(
        LogTags.auth,
        'Sign up error',
        data: {
          'email': _emailController.text,
          'error': e.toString(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... your UI code
      floatingActionButton: FloatingActionButton(
        onPressed: _handleSignUp,
        child: const Icon(Icons.check),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

## 3. Login Screen Integration

```dart
import 'package:comet_wallet/services/auth_service.dart';
import 'package:comet_wallet/services/logger_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    try {
      AppLogger.info(
        LogTags.auth,
        'Login initiated',
        data: {'email': _emailController.text},
      );

      final response = await AuthService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (mounted) {
        // Log user profile after successful login
        AppLogger.logUserProfile({
          'email': _emailController.text,
          'login_time': DateTime.now().toIso8601String(),
          'device': 'mobile',
        });

        AppLogger.success(
          LogTags.auth,
          'User logged in successfully',
          data: {'email': _emailController.text},
        );

        // Navigate to home
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      AppLogger.error(
        LogTags.auth,
        'Login failed',
        data: {
          'email': _emailController.text,
          'error': e.toString(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... your UI code
      floatingActionButton: FloatingActionButton(
        onPressed: _handleLogin,
        child: const Icon(Icons.login),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

## 4. KYC ID Upload Screen Integration

The ID upload screen already has logging built in through KYCService. The logging is automatically done when:

```dart
// Inside id_upload_screen.dart _captureImage() method:
// Logs are automatically generated for:
// - Image capture
// - Image preview
// - Navigation to next step

// In the confirm step:
// Navigate to liveness check and logging is done automatically
```

## 5. KYC Liveness Check Screen Integration

The liveness check screen logs selfie captures:

```dart
// Inside liveness_check_screen.dart _takeSelfie() method:
// Logs are automatically generated for:
// - Camera initialization
// - Selfie capture
// - Navigation to home
```

## 6. Complete KYC Flow

```dart
import 'package:comet_wallet/services/kyc_service.dart';
import 'package:comet_wallet/services/logger_service.dart';

class CompleteKYCFlow {
  static Future<void> submitKYC({
    required int userId,
    required File idFrontFile,
    required File idBackFile,
    required File kraFile,
    required File profilePhotoFile,
    required File proofOfAddressFile,
  }) async {
    try {
      AppLogger.info(
        LogTags.kyc,
        'Starting complete KYC submission',
        data: {'user_id': userId},
      );

      // This automatically logs:
      // - All image uploads with durations
      // - Complete KYC submission
      // - All URLs
      final result = await KYCService.completeKYC(
        userID: userId,
        idFrontImage: idFrontFile,
        idBackImage: idBackFile,
        kraDocument: kraFile,
        profilePhoto: profilePhotoFile,
        proofOfAddress: proofOfAddressFile,
      );

      AppLogger.success(
        LogTags.kyc,
        'KYC flow completed successfully',
        data: {
          'user_id': userId,
          'result': result,
        },
      );

    } catch (e) {
      AppLogger.error(
        LogTags.kyc,
        'KYC flow failed',
        data: {
          'user_id': userId,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }
}
```

## 7. Payment Screen Integration (Example)

```dart
import 'package:comet_wallet/services/logger_service.dart';

class PaymentScreen extends StatefulWidget {
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Future<void> _processPayment(double amount, String recipient) async {
    try {
      AppLogger.info(
        LogTags.payment,
        'Payment initiated',
        data: {
          'amount': amount,
          'recipient': recipient,
        },
      );

      // Make payment API call
      // const response = await paymentService.pay(...);

      AppLogger.success(
        LogTags.payment,
        'Payment processed successfully',
        data: {
          'amount': amount,
          'recipient': recipient,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

    } catch (e) {
      AppLogger.error(
        LogTags.payment,
        'Payment processing failed',
        data: {
          'amount': amount,
          'recipient': recipient,
          'error': e.toString(),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... your UI
    );
  }
}
```

## 8. Custom Service Integration Pattern

```dart
import 'package:comet_wallet/services/logger_service.dart';

class MyCustomService {
  static Future<Map<String, dynamic>> myOperation({
    required String param1,
    required String param2,
  }) async {
    final startTime = DateTime.now();

    try {
      // Log operation start
      AppLogger.debug(
        LogTags.api,  // or your appropriate tag
        'Operation started',
        data: {
          'param1': param1,
          'param2': param2,
        },
      );

      // Do the operation
      // final result = await apiCall(...);

      final duration = DateTime.now().difference(startTime);

      // Log success
      AppLogger.success(
        LogTags.api,
        'Operation completed',
        data: {
          'param1': param1,
          'duration_ms': duration.inMilliseconds,
        },
      );

      // return result;

    } catch (e) {
      final duration = DateTime.now().difference(startTime);

      AppLogger.error(
        LogTags.api,
        'Operation failed',
        data: {
          'param1': param1,
          'error': e.toString(),
          'duration_ms': duration.inMilliseconds,
        },
      );
      rethrow;
    }
  }
}
```

## 9. Navigation Integration

```dart
import 'package:comet_wallet/services/logger_service.dart';

class NavigationHelper {
  static void navigateTo(BuildContext context, Widget screen, String screenName) {
    AppLogger.logNavigation(
      from: ModalRoute.of(context)?.settings.name ?? 'Unknown',
      to: screenName,
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static void navigateReplacementNamed(BuildContext context, String routeName) {
    AppLogger.logNavigation(
      from: ModalRoute.of(context)?.settings.name ?? 'Unknown',
      to: routeName,
    );

    Navigator.of(context).pushReplacementNamed(routeName);
  }
}
```

## Summary of Logging Points

| Location | Event | Logs |
|----------|-------|------|
| main.dart | App lifecycle | App start, pause, resume, detach |
| Sign-up screen | User registration | Email, name, phone, timestamp |
| Login screen | User authentication | Email, login time |
| KYC ID capture | Image uploads | File size, upload duration, URL |
| KYC submission | Complete flow | All image URLs, user ID, status |
| Payment screen | Transaction | Amount, recipient, timestamp |
| Navigation | Screen changes | From screen, to screen |
| API calls | Requests/Responses | Endpoint, method, status, duration |
| Errors | Exceptions | Error message, context, stack trace |

## Testing Integration

To test the logging:

1. Run: `flutter run`
2. Perform an operation (login, register, KYC, etc.)
3. Check the debug console for logs
4. Verify logs contain expected information
5. Verify sensitive data is redacted

---

**Status**: Ready for integration into all screens and services
