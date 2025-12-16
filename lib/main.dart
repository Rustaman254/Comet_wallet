import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/colors.dart';
import 'screens/onboarding_page_view.dart';
import 'screens/sign_in_screen.dart';
import 'screens/verify_pin_screen.dart';

void main() {
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
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
            textTheme: GoogleFonts.poppinsTextTheme().apply(
              bodyColor: lightTextPrimary,
              displayColor: lightTextPrimary,
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
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
            textTheme: GoogleFonts.poppinsTextTheme().apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
          ),
          home: const OnboardingWrapper(),
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
    final isSignedUp = prefs.getBool('isSignedUp') ?? false;
    
    if (mounted) {
      if (isFirstTime) {
        setState(() {
          _isFirstTime = true;
          _isLoading = false;
        });
      } else if (!isSignedUp) {
         // User has seen onboarding but not signed up -> Go to Sign In
         Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SignInScreen()),
        );
      } else {
        // User is signed up -> Go to Verify Pin
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const VerifyPinScreen()),
        );
      }
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
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
        backgroundColor: const Color(0xFF122022), // darkBackground
        body: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Container (replicated from splash_screen.dart design)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF39CA4D).withValues(alpha: 0.1), // buttonGreen
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF39CA4D).withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.wallet,
                            size: 50,
                            color: Color(0xFF39CA4D),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Comet Wallet',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your Money, Your Way',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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
      // Direct navigation to VerifyPinScreen or SignInScreen based on logic
      // The original code went to VerifyPinScreen, let's keep that but maybe wrap it 
      // or just return it. 
      return const VerifyPinScreen();
    }
  }
}
