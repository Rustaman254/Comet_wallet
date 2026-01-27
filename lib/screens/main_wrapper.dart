import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';
import 'home_screen.dart';
import 'my_cards_screen.dart';
import 'transactions_screen.dart';
import 'settings_screen.dart';

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

class MainWrapperState extends State<MainWrapper> {
  late int _currentIndex;
  
  final List<Widget> _pages = [
    const HomeScreen(),
    const MyCardsScreen(),
    const TransactionsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
