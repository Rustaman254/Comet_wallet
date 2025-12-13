import 'package:flutter/material.dart';
import 'onboarding_screens.dart';

class OnboardingPageView extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPageView({super.key, required this.onComplete});

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

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
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
      ],
    );
  }
}
