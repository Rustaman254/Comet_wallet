import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import 'my_cards_screen.dart';
import 'send_options_screen.dart';
import 'qr_scan_screen.dart';
import 'more_options_screen.dart';
import 'receive_money_screen.dart';
import 'withdraw_money_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final PageController _balancePageController = PageController();
  final PageController _cardsPageController = PageController();
  int _currentBalancePage = 0;
  int _currentCardPage = 0;

  final List<Map<String, String>> _balances = [
    {
      'currency': 'USD',
      'amount': '4562.00',
      'date': '24.03.26',
      'change': '+1.03',
    },
    {
      'currency': 'KES',
      'amount': '650,000',
      'date': '24.03.26',
      'change': '+150',
    },
    {
      'currency': 'EUR',
      'amount': '4,200',
      'date': '24.03.26',
      'change': '+5.20',
    },
  ];

  @override
  void initState() {
    super.initState();
    _balancePageController.addListener(_onBalancePageChanged);
    _cardsPageController.addListener(_onCardPageChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _balancePageController.dispose();
    _cardsPageController.dispose();
    _balancePageController.removeListener(_onBalancePageChanged);
    _cardsPageController.removeListener(_onCardPageChanged);
    super.dispose();
  }

  void _onBalancePageChanged() {
    if (_balancePageController.page != null) {
      setState(() {
        _currentBalancePage = _balancePageController.page!.round();
      });
    }
  }

  void _onCardPageChanged() {
    if (_cardsPageController.page != null) {
      setState(() {
        _currentCardPage = _cardsPageController.page!.round();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // FIXED HEADER - Does not scroll
            Column(
              children: [
                const SizedBox(height: 20),
                // Header with profile, search, and QR code
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      // Profile picture
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          color: Colors.grey[800],
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Welcome text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              'Tanya Myroniuk',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Search button
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.search_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // QR code button
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const QRScanScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.qr_code,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Action buttons - FIXED
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        Icons.arrow_upward_outlined,
                        'Send',
                        () {
                          _showSendOptions(context);
                        },
                      ),
                      _buildActionButton(
                        Icons.arrow_downward_outlined,
                        'Receive',
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ReceiveMoneyScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionButton(
                        Icons.monetization_on_outlined,
                        'Withdraw',
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const WithdrawMoneyScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionButton(
                        Icons.more_horiz,
                        'More',
                        () {
                          _showMoreOptions(context);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
            // SCROLLABLE CONTENT
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Total Balance Card - Scrollable
                    SizedBox(
                      height: 200,
                      child: PageView(
                        controller: _balancePageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentBalancePage = index;
                          });
                        },
                        children: _balances.map((balance) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    darkGreen,
                                    darkGreen.withValues(alpha: 0.8),
                                    lightGreen.withValues(alpha: 0.3),
                                  ],
                                ),
                                border: Border.all(color: cardBorder, width: 1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Balance',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          balance['currency']!,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        balance['currency']!,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 25,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        balance['amount']!,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 35,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Date',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white70,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              balance['date']!,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              balance['change']!,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.trending_up_outlined,
                                              color: buttonGreen,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Page indicators for balance
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_balances.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _buildPageIndicator(
                            index == _currentBalancePage,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    // Info Cards - Scrollable with 4 cards
                    SizedBox(
                      height: 120,
                      child: PageView.builder(
                        controller: _cardsPageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentCardPage = index;
                          });
                        },
                        itemCount: 2,
                        itemBuilder: (context, pageIndex) {
                          final cards = [
                            {
                              'icon': Icons.account_balance_wallet_outlined,
                              'title': 'Today You Spent',
                              'value': '\$ 123.00',
                            },
                            {
                              'icon': Icons.access_time_outlined,
                              'title': 'Payment Status',
                              'value': 'KES 1,500 pending',
                            },
                            {
                              'icon': Icons.trending_up_outlined,
                              'title': 'Monthly Savings',
                              'value': '\$ 2,450',
                            },
                            {
                              'icon': Icons.credit_card_outlined,
                              'title': 'Active Cards',
                              'value': '3 Cards',
                            },
                          ];

                          int startIndex = pageIndex * 2;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    padding: const EdgeInsets.all(4),
                                    child: _buildInfoCard(
                                      cards[startIndex]['icon'] as IconData,
                                      cards[startIndex]['title'] as String,
                                      cards[startIndex]['value'] as String,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    padding: const EdgeInsets.all(4),
                                    child: _buildInfoCard(
                                      cards[startIndex + 1]['icon'] as IconData,
                                      cards[startIndex + 1]['title'] as String,
                                      cards[startIndex + 1]['value'] as String,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Page indicators for cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(2, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _buildPageIndicator(index == _currentCardPage),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    // Transaction section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Transaction',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'Sell All',
                              style: GoogleFonts.poppins(
                                color: buttonGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Transaction list
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          _buildTransactionItem(
                            '+2547 12 345 678',
                            'Jan 28, 2026. 7:46 PM',
                            '-\$5,99',
                          ),
                          const SizedBox(height: 16),
                          _buildTransactionItem(
                            '+2547 10 123 444',
                            'Jan 29, 2026. 9:46 PM',
                            '-\$12,99',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  void _showSendOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SendOptionsScreen(),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const MoreOptionsScreen(),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String phone, String date, String amount) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_outline,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                phone,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
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

  Widget _buildPageIndicator(bool isActive) {
    return Container(
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? buttonGreen : Colors.grey[600],
        borderRadius: BorderRadius.circular(4),
      ),
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
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyCardsScreen()),
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StatisticsScreen()),
            );
          } else if (index == 3) {
            Navigator.of(context).push(
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
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        items: [
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.home),
                if (_currentIndex == 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: buttonGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'My Cards',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            label: 'Statistics',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
