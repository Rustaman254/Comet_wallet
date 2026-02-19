import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../services/token_service.dart';
import 'onboarding_page_view.dart';
import 'sign_in_screen.dart';
import 'home_screen.dart';
import 'verify_pin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
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
    _checkNavigation();
  }

  Future<void> _checkNavigation() async {
    // Wait for animation + artificial delay
    await Future.delayed(const Duration(milliseconds: 2000));
    
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;
    
    // Check if user is authenticated (has a valid token)
    final isAuthenticated = await TokenService.isAuthenticated();

    if (mounted) {
      Widget nextScreen;
      
      // Navigation logic:
      // 1. If first time: show onboarding
      // 2. If not first time and authenticated: show home
      // 3. Otherwise: show sign in
      if (isFirstTime) {
        nextScreen = const OnboardingPageView();
      } else if (isAuthenticated) {
        // User is logged in, verify PIN first
        nextScreen = const VerifyPinScreen();
      } else {
        // User is not logged in, go to sign in screen
        nextScreen = const SignInScreen();
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
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
    // Ensure clean status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: darkBackground,
      body: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Container
                      SizedBox(
                        width: 200, // Adjusted size for better visibility
                        height: 200,
                        child: Image.asset(
                          'assets/images/Logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Powered by",
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Image.asset(
                  'assets/images/Logo anzens_white.png',
                  height: 24,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "on ",
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                    SvgPicture.asset(
                      'assets/images/cardano_logo.svg',
                      height: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Cardano",
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
