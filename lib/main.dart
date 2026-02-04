import 'package:flutter/material.dart';
import 'package:smile_id/smile_id.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'constants/colors.dart';
import 'screens/onboarding_page_view.dart';
import 'screens/sign_in_screen.dart';
import 'screens/verify_pin_screen.dart';
import 'screens/main_wrapper.dart';
import 'services/token_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SmileID with error handling
  try {
    SmileID.initialize(
      useSandbox: true,
      enableCrashReporting: true,
    );
  } catch (e) {
    // Log error but don't crash the app
    print('SmileID initialization warning: $e');
    // App will continue to work, KYC features may be limited
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return ScreenUtilInit(
          designSize: const Size(393, 852), 
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              title: 'Comet Wallet',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: lightBackground,
            cardColor: lightCardBackground,
            colorScheme: ColorScheme.fromSeed(
              seedColor: buttonGreen,
              brightness: Brightness.light,
              surface: lightCardBackground,
              outline: lightBorder,
            ),
            useMaterial3: true,
            fontFamily: 'Satoshi',
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
            textTheme: TextTheme(
              displayLarge: const TextStyle(fontFamily: 'Satoshi', fontSize: 32, fontWeight: FontWeight.bold, color: lightTextPrimary),
              displayMedium: const TextStyle(fontFamily: 'Satoshi', fontSize: 28, fontWeight: FontWeight.bold, color: lightTextPrimary),
              displaySmall: const TextStyle(fontFamily: 'Satoshi', fontSize: 24, fontWeight: FontWeight.bold, color: lightTextPrimary),
              headlineMedium: const TextStyle(fontFamily: 'Satoshi', fontSize: 20, fontWeight: FontWeight.w600, color: lightTextPrimary),
              headlineSmall: const TextStyle(fontFamily: 'Satoshi', fontSize: 18, fontWeight: FontWeight.w600, color: lightTextPrimary),
              titleLarge: const TextStyle(fontFamily: 'Satoshi', fontSize: 16, fontWeight: FontWeight.w600, color: lightTextPrimary),
              titleMedium: const TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w500, color: lightTextPrimary),
              bodyLarge: const TextStyle(fontFamily: 'Satoshi', fontSize: 16, fontWeight: FontWeight.w400, color: lightTextPrimary),
              bodyMedium: const TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w400, color: lightTextPrimary),
              bodySmall: const TextStyle(fontFamily: 'Satoshi', fontSize: 12, fontWeight: FontWeight.w400, color: lightTextSecondary),
              labelLarge: const TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w500, color: lightTextPrimary),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: darkBackground,
            cardColor: cardBackground,
            colorScheme: ColorScheme.fromSeed(
              seedColor: buttonGreen,
              brightness: Brightness.dark,
              surface: cardBackground,
              outline: cardBorder,
            ),
            useMaterial3: true,
            fontFamily: 'Satoshi',
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
            textTheme: TextTheme(
              displayLarge: const TextStyle(fontFamily: 'Satoshi', fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              displayMedium: const TextStyle(fontFamily: 'Satoshi', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              displaySmall: const TextStyle(fontFamily: 'Satoshi', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              headlineMedium: const TextStyle(fontFamily: 'Satoshi', fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
              headlineSmall: const TextStyle(fontFamily: 'Satoshi', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
              titleLarge: const TextStyle(fontFamily: 'Satoshi', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              titleMedium: const TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
              bodyLarge: const TextStyle(fontFamily: 'Satoshi', fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),
              bodyMedium: const TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white),
              bodySmall: const TextStyle(fontFamily: 'Satoshi', fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white70),
              labelLarge: const TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ),
          home: const OnboardingWrapper(),
            );
          },
        );
      },
    );
  }
}

class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isFirstTime = true;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    // Artificial delay for splash effect
    await Future.delayed(const Duration(milliseconds: 2000));
    
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;
    
    // Check if user is authenticated (has a valid token)
    final isAuthenticated = await TokenService.isAuthenticated();
    
    if (mounted) {
      if (isFirstTime) {
        setState(() {
          _isFirstTime = true;
          _isLoading = false;
        });
      } else if (isAuthenticated) {
        // User is logged in, verify PIN first
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const VerifyPinScreen()),
        );
      } else {
        // User is not logged in, go to sign in screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SignInScreen()),
        );
      }
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    
    if (mounted) {
      // After onboarding completes, check if user is authenticated
      final isAuthenticated = await TokenService.isAuthenticated();
      final nextScreen = isAuthenticated ? const VerifyPinScreen() : const SignInScreen();
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar to white
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF122023),
        body: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: 1,
                  child: Image.asset(
                    'assets/images/Logo.png',
                    width: MediaQuery.of(context).size.width * 0.4,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    if (_isFirstTime) {
      return OnboardingPageView(onComplete: _completeOnboarding);
    } else {
      return const VerifyPinScreen();
    }
  }
}
