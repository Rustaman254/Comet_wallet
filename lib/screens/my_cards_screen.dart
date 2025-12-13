import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import 'home_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';

class MyCardsScreen extends StatefulWidget {
  const MyCardsScreen({super.key});

  @override
  State<MyCardsScreen> createState() => _MyCardsScreenState();
}

class _MyCardsScreenState extends State<MyCardsScreen> {
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  final double _spendingLimit = 8545.0;
  int _currentCardIndex = 0;
  String _selectedCardType = 'Virtual'; // Virtual or Gift

  // Sample cards - users can have multiple cards of the same type
  final List<Map<String, dynamic>> _allCards = [
    {
      'type': 'Virtual',
      'number': '4562  1122  4595  7852',
      'name': 'Aimal Naseem',
      'expiry': '24/2000',
      'cvv': '6986',
    },
    {
      'type': 'Virtual',
      'number': '5234  8765  3421  9087',
      'name': 'Aimal Naseem',
      'expiry': '12/2025',
      'cvv': '123',
    },
    {
      'type': 'Gift',
      'number': '6011  2345  6789  0123',
      'name': 'Gift Card',
      'expiry': '06/2026',
      'cvv': '456',
    },
    {
      'type': 'Gift',
      'number': '3782  8224  6310  005',
      'name': 'Holiday Gift',
      'expiry': '09/2027',
      'cvv': '789',
    },
  ];

  List<Map<String, dynamic>> get _filteredCards {
    return _allCards.where((card) => card['type'] == _selectedCardType).toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    Text(
                      'My Cards',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // TODO: Navigate to add card screen
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Card Type Toggle - Connected buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    // Virtual Card Button (Left)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCardType = 'Virtual';
                            _currentCardIndex = 0;
                            _pageController.jumpToPage(0);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedCardType == 'Virtual'
                                ? buttonGreen
                                : cardBackground,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                            border: Border.all(
                              color: _selectedCardType == 'Virtual'
                                  ? buttonGreen
                                  : cardBorder,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Virtual',
                            style: GoogleFonts.poppins(
                              color: _selectedCardType == 'Virtual'
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 14,
                              fontWeight: _selectedCardType == 'Virtual'
                                  ? FontWeight.bold
                                  : FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    // Gift Card Button (Right)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCardType = 'Gift';
                            _currentCardIndex = 0;
                            _pageController.jumpToPage(0);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedCardType == 'Gift'
                                ? buttonGreen
                                : cardBackground,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            border: Border.all(
                              color: _selectedCardType == 'Gift'
                                  ? buttonGreen
                                  : cardBorder,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Gift',
                            style: GoogleFonts.poppins(
                              color: _selectedCardType == 'Gift'
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 14,
                              fontWeight: _selectedCardType == 'Gift'
                                  ? FontWeight.bold
                                  : FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Credit Card with PageView
              SizedBox(
                height: 220,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentCardIndex = index;
                    });
                  },
                  itemCount: _filteredCards.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _buildCard(_filteredCards[index]),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Page indicators - same style as home screen
              if (_filteredCards.length > 1)
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      _filteredCards.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentCardIndex == index
                              ? buttonGreen
                              : Colors.grey[600],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 40),
              // Transactions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    _buildTransactionItem(
                      Icons.apple,
                      'Apple Store',
                      'Entertainment',
                      '- \$5,99',
                      Colors.white,
                    ),
                    const SizedBox(height: 20),
                    _buildTransactionItem(
                      Icons.music_note,
                      'Spotify',
                      'Music',
                      '- \$12,99',
                      buttonGreen,
                    ),
                    const SizedBox(height: 20),
                    _buildTransactionItem(
                      Icons.shopping_cart_outlined,
                      'Grocery',
                      'Shopping',
                      '- \$ 88',
                      Colors.pinkAccent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Monthly Spending Limit
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly spending limit',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1F15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amount: \$${_spendingLimit.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _spendingLimit / 10000,
                              backgroundColor: const Color(0xFF1A2E20),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(buttonGreen),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '\$0',
                                style: GoogleFonts.poppins(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '\$${_spendingLimit.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  color: buttonGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '\$10,000',
                                style: GoogleFonts.poppins(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCard(Map<String, dynamic> card) {
    final cardType = card['type'] as String;

    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: _getCardGradient(cardType),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // World map pattern for virtual cards using the uploaded image
          if (cardType == 'Virtual')
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Opacity(
                  opacity: 0.15,
                  child: Image.asset(
                    'assets/images/world_map.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          // Card content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Yellow chip icon
                  Container(
                    width: 50,
                    height: 35,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.credit_card,
                      color: Color(0xFF8B7500),
                      size: 20,
                    ),
                  ),
                  const Icon(
                    Icons.contactless_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ],
              ),
              const Spacer(),
              // Card Number - fontSize 20
              Text(
                card['number'],
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cardholder Name - fontSize 16
                  Text(
                    card['name'],
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      // Expiry
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VALID THRU',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            card['expiry'],
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // CVV
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CVV',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            card['cvv'],
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Mastercard Logo
                      Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEB001B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(-10, 0),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF79E1B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'mastercard',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  LinearGradient _getCardGradient(String cardType) {
    switch (cardType) {
      case 'Virtual':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A5F),
            Color(0xFF2C5F8D),
            Color(0xFF1A2F4A),
          ],
        );
      case 'Gift':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B3A8B),
            Color(0xFFB24FB2),
            Color(0xFF6B2D6B),
          ],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D5F3F),
            Color(0xFF1E4A2F),
            Color(0xFF1A3D28),
          ],
        );
    }
  }

  Widget _buildTransactionItem(
    IconData icon,
    String title,
    String subtitle,
    String amount,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const StatisticsScreen()),
            );
          } else if (index == 3) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: buttonGreen,
        unselectedItemColor: Colors.white70,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 24),
            activeIcon: Icon(Icons.home, size: 24),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_outlined, size: 24),
            activeIcon: Icon(Icons.credit_card, size: 24),
            label: 'My Cards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline, size: 24),
            activeIcon: Icon(Icons.pie_chart, size: 24),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined, size: 24),
            activeIcon: Icon(Icons.settings, size: 24),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
