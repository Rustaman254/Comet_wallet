import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../services/vibration_service.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import '../services/token_service.dart';
import 'my_cards_screen.dart';
import 'send_options_screen.dart';
import 'qr_scan_screen.dart';
import 'more_options_screen.dart';
import 'receive_money_screen.dart';
import 'withdraw_money_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'wallet_topup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();
  late PageController _balancePageController;
  int _currentBalancePage = 0;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _balancePageController = PageController();
    _balancePageController.addListener(_onBalancePageChanged);
    _loadCachedUserData();
    _fetchUserProfile();
  }
  
  void _loadCachedUserData() async {
    final name = await TokenService.getUserName();
    if (mounted && name != null && name.isNotEmpty) {
      setState(() {
        // Create a partial profile with just the name for immediate display
        _userProfile = UserProfile(
          id: 0,
          name: name,
          email: '',
          phone: '',
          location: '',
          kycVerified: false,
          isAccountActivated: false,
          activationFeePaid: false,
          walletBalances: {},
          status: '',
        );
      });
    }
  }
  
  UserProfile? _userProfile;

  Future<void> _fetchUserProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final profile = await AuthService.getUserProfile();
      if (mounted) {
        setState(() {
          if (profile != null) {
            _userProfile = profile;
            _updateBalances(profile);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('HomeScreen: Error fetching profile: $e');
    }
  }

  void _updateBalances(UserProfile profile) {
    if (profile.walletBalances.isNotEmpty) {
      setState(() {
        profile.walletBalances.forEach((currency, amount) {
          // Find if we have this currency in our list
          final index = _balances.indexWhere((b) => b['currency'] == currency);
          
          if (index != -1) {
            // Update existing entry
            _balances[index]['amount'] = amount.toString();
          } else {
            // Add new entry
            _balances.add({
              'currency': currency,
              'amount': amount.toString(),
              'date': '24.03.26', // Use current date format
              'change': '+0.00',
            });
          }
        });
      });
    }
  }
  
  void _onBalancePageChanged() {
    if (_balancePageController.page != null) {
      final page = _balancePageController.page!.round();
      setState(() {
        _currentBalancePage = page;
      });
    }
  }


  List<Map<String, String>> _balances = [];

  @override
  void dispose() {
    _scrollController.dispose();
    _balancePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      // Profile picture - clickable
                      GestureDetector(
                        onTap: () {
                          VibrationService.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.red,
                                  width: 2
                                ),
                                color: Colors.grey[800],
                              ),
                              child: Icon(
                                Icons.person_outline,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                size: 30,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 2,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    width: 2
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),
                      // Welcome text - clickable
                      GestureDetector(
                        onTap: () {
                          VibrationService.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: GoogleFonts.poppins(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              _userProfile?.name ?? 'Anwar Sadatt',
                              style: GoogleFonts.poppins(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Search button
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_outlined,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
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
                          child: Icon(
                            Icons.qr_code,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Action buttons - FIXED - Scrollable
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      _buildActionButton(
                        Icons.arrow_upward_outlined,
                        'Send',
                        () {
                          _showSendOptions(context);
                        },
                      ),
                      const SizedBox(width: 20),
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
                      const SizedBox(width: 20),
                      _buildActionButton(
                        Icons.add_circle_outline,
                        'Top-up',
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const WalletTopupScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 20),
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
                      const SizedBox(width: 20),
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
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchUserProfile,
                color: buttonGreen,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Column(
                    children: [
                      // Total Balance Card - Scrollable with PageView
                      SizedBox(
                        height: 200,
                        child: _isLoading 
                          ? Center(child: CircularProgressIndicator(color: buttonGreen))
                          : (_balances.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                  child: _buildEmptyBalanceCard(),
                                )
                              : PageView(
                                  controller: _balancePageController,
                                  children: _balances.map((balance) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                      child: Container(
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
                                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
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
                                                      color: Theme.of(context).textTheme.bodyMedium?.color,
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
                                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                                    fontSize: 25,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  balance['amount']!,
                                                  style: GoogleFonts.poppins(
                                                    color: Theme.of(context).textTheme.bodyMedium?.color,
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
                                                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w400,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        balance['date']!,
                                                        style: GoogleFonts.poppins(
                                                          color: Theme.of(context).textTheme.bodyMedium?.color,
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
                                                          color: Theme.of(context).textTheme.bodyMedium?.color,
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
                                )
                            ),
                      ),
                      const SizedBox(height: 12),
                      // Page indicators for balance cards
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_balances.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: _buildPageIndicator(index == _currentBalancePage),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      // Info Cards - Scrollable with 4 cards
                      // Info Cards - Scrollable with ListView
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          itemCount: 4,
                          separatorBuilder: (context, index) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final cards = [
                              {
                                'icon': Icons.arrow_downward,
                                'title': 'Income',
                                'value': 'KES 0.00',
                              },
                              {
                                'icon': Icons.arrow_upward,
                                'title': 'Expense',
                                'value': 'KES 0.00',
                              },
                              {
                                'icon': Icons.pending_actions,
                                'title': 'Pending',
                                'value': 'KES 0.00',
                              },
                              {
                                'icon': Icons.task_alt,
                                'title': 'Completed',
                                'value': 'KES 0.00',
                              },
                            ];
                            
                            return SizedBox(
                                width: 160, // Fixed width for comfortable reading
                                child: _buildInfoCard(
                                  cards[index]['icon'] as IconData,
                                  cards[index]['title'] as String,
                                  cards[index]['value'] as String,
                                ),
                            );
                          }
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Removed indicators to match smooth scroll aesthetic
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
                                color: Theme.of(context).textTheme.bodyMedium?.color,
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
                            Icon(Icons.history_outlined, size: 48, color: Colors.grey[600]),
                            const SizedBox(height: 12),
                            Text(
                              'No recent transactions',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 16,
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

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        VibrationService.selectionClick();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).textTheme.bodyMedium?.color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Theme.of(context).textTheme.bodyMedium?.color,
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).textTheme.bodyMedium?.color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
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
              color: Theme.of(context).textTheme.bodyMedium?.color,
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

  Widget _buildEmptyBalanceCard() {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'KES',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'KES',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '0.00',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Top up to start transacting',
            style: GoogleFonts.poppins(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              fontSize: 14,
            ),
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
          child: Icon(
            Icons.person_outline,
            color: Theme.of(context).textTheme.bodyMedium?.color,
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
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
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
            color: Theme.of(context).textTheme.bodyMedium?.color,
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
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          VibrationService.lightImpact();
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
        unselectedItemColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
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
