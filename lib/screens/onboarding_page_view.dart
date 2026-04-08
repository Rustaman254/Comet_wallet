import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screens.dart';
import '../services/token_service.dart';
import 'sign_in_screen.dart';
import 'verify_pin_screen.dart';

class OnboardingPageView extends StatefulWidget {
  const OnboardingPageView({super.key});

  @override
  State<OnboardingPageView> createState() => _OnboardingPageViewState();
}

class _OnboardingPageViewState extends State<OnboardingPageView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<OverscrollNotification>(
      onNotification: (overscroll) {
        if (overscroll.overscroll > 0 && _currentPage == 3) {
          _completeOnboarding();
        }
        return false;
      },
      child: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          OnboardingScreen1(onNext: _nextPage, currentPage: _currentPage),
          OnboardingScreen2(onNext: _nextPage, currentPage: _currentPage),
          OnboardingScreen3(onNext: _nextPage, currentPage: _currentPage),
          OnboardingScreen4(onNext: _nextPage, currentPage: _currentPage),
        ],
      ),
    );
  }
}
