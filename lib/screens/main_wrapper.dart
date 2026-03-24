import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';
import 'home_screen.dart';
import 'transactions_screen.dart';
import 'orders_page.dart';
import 'more_options_screen.dart';
import 'verify_pin_screen.dart';
import '../services/session_service.dart';
import '../services/logger_service.dart';

class MainWrapper extends StatefulWidget {
  final int initialIndex;
  
  const MainWrapper({super.key, this.initialIndex = 0});

  @override
  State<MainWrapper> createState() => MainWrapperState();
  
  // Static access to change tab from anywhere
  static MainWrapperState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainWrapperState>();
  }
}

class MainWrapperState extends State<MainWrapper> with WidgetsBindingObserver {
  late int _currentIndex;
  
  final List<Widget> _pages = [
    const HomeScreen(),
    // Cards screen removed
    const TransactionsScreen(),
    const OrdersPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize session service
    SessionService.initialize(
      onSessionExpired: _handleSessionExpired,
    );
    
    // Record initial activity
    SessionService.recordActivity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SessionService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    AppLogger.debug(
      LogTags.auth,
      'App lifecycle state changed',
      data: {'state': state.toString()},
    );
    
    if (state == AppLifecycleState.paused) {
      // App went to background
      SessionService.pause();
    } else if (state == AppLifecycleState.resumed) {
      // Only lock if backgrounded for more than the grace period (to allow for biometric prompts)
      if (SessionService.shouldLockAfterBackground()) {
        _handleSessionExpired();
      } else {
        // Otherwise, just resume session tracking
        SessionService.resume();
      }
    }
  }

  void _handleSessionExpired() {
    if (!mounted) return;
    
    AppLogger.info(
      LogTags.auth,
      'Redirecting to PIN verification due to session expiry',
    );
    
    // Navigate to PIN verification screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const VerifyPinScreen(nextScreen: MainWrapper()),
      ),
      (route) => false,
    );
  }

  void onTabChanged(int index) {
    if (index == 3) {
      _showMoreOptions();
      return;
    }
    setState(() {
      _currentIndex = index;
    });
    
    // Record activity on tab change
    SessionService.recordActivity();
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MoreOptionsScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Record activity on any tap
      onTap: () => SessionService.recordActivity(),
      behavior: HitTestBehavior.translucent,
      child: NotificationListener<ScrollNotification>(
        // Record activity on any scroll
        onNotification: (ScrollNotification notification) {
          SessionService.recordActivity();
          return false; // Allow the notification to continue bubbling
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          // We use IndexedStack to preserve state of each tab
          body: Stack(
            children: [
              IndexedStack(
                index: _currentIndex,
                children: _pages,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CustomBottomNav(
                  currentIndex: _currentIndex,
                  onTap: onTabChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
