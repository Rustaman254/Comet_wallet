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
  
  bool _isBalanceVisible = true;

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
                        height: 220, // Slightly increased height for larger font
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
                                        padding: const EdgeInsets.all(24), // Increased padding
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
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Total Balance',
                                                      style: GoogleFonts.poppins(
                                                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w400,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          _isBalanceVisible = !_isBalanceVisible;
                                                        });
                                                        VibrationService.lightImpact();
                                                      },
                                                      child: Icon(
                                                        _isBalanceVisible 
                                                            ? Icons.visibility_outlined 
                                                            : Icons.visibility_off_outlined,
                                                        color: Colors.white70,
                                                        size: 18,
                                                      ),
                                                    ),
                                                  ],
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
                                            const SizedBox(height: 16),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.baseline,
                                              textBaseline: TextBaseline.alphabetic,
                                              children: [
                                                Text(
                                                  balance['currency']!,
                                                  style: GoogleFonts.poppins(
                                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.9),
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _isBalanceVisible ? balance['amount']! : '••••••',
                                                  style: GoogleFonts.poppins(
                                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                                    fontSize: 48, // Significantly bigger font
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: -1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Spacer(),
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 0),
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
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w400,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        balance['date']!,
                                                        style: GoogleFonts.poppins(
                                                          color: Theme.of(context).textTheme.bodyMedium?.color,
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          balance['change']!,
                                                          style: GoogleFonts.poppins(
                                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Icon(
                                                          Icons.trending_up_outlined,
                                                          color: buttonGreen,
                                                          size: 16,
                                                        ),
                                                      ],
                                                    ),
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
                      
                      // Adaptive Summary Pills (Income, Expense, etc.)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          children: [
                            _buildInfoCard(Icons.arrow_downward, 'Income', 'KES 0.00'),
                            const SizedBox(width: 12),
                            _buildInfoCard(Icons.arrow_upward, 'Expense', 'KES 0.00'),
                            const SizedBox(width: 12),
                            _buildInfoCard(Icons.pending_actions, 'Pending', 'KES 0.00'),
                            const SizedBox(width: 12),
                            _buildInfoCard(Icons.task_alt, 'Completed', 'KES 0.00'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 8), // Reduced spacing
                      
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
                                'See All',
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(50), // Fully rounded / pill shape
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Hug content
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).textTheme.bodyMedium?.color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 18, // Increased size
                  fontWeight: FontWeight.w900, // Extra bold
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        child: Center(
          heightFactor: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(40), // Pill shape
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Fit content
              children: [
                _buildNavItem(0, Icons.home),
                const SizedBox(width: 8),
                _buildNavItem(1, Icons.credit_card),
                const SizedBox(width: 8),
                _buildNavItem(2, Icons.pie_chart_outline),
                const SizedBox(width: 8),
                _buildNavItem(3, Icons.settings_outlined),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
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
      child: Container(
        padding: const EdgeInsets.all(16), // Comfortable click space
        decoration: BoxDecoration(
          color: isSelected ? buttonGreen.withValues(alpha: 0.1) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? buttonGreen 
                  : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              size: 24,
            ),
            if (isSelected && index == 0) // Optional indicator for Home
               Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: buttonGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
