import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../utils/responsive_utils.dart';
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
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'wallet_topup_screen.dart';
import 'transactions_screen.dart';
import '../services/toast_service.dart';
import '../models/transaction.dart';
import '../services/wallet_service.dart';
import '../services/wallet_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  late PageController _balancePageController;
  int _currentBalancePage = 0;
  bool _isLoading = true;
  
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  int _pendingCount = 0;
  int _completedCount = 0;
  
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    _balancePageController = PageController();
    _balancePageController.addListener(_onBalancePageChanged);
    _loadCachedUserData();
    _fetchUserProfile();
    // Initial data fetch handled by Provider or here
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WalletProvider.instance.fetchData();
    });
  }

  void _calculateSummaries(List<Transaction> transactions) {
    double income = 0.0;
    double expense = 0.0;
    int pending = 0;
    int completed = 0;

    for (var tx in transactions) {
      // Categorize by type
      if (tx.transactionType.contains('topup') || 
          tx.transactionType.contains('receive') ||
          tx.transactionType.contains('deposit')) {
        income += tx.amount;
      } else if (tx.transactionType.contains('send') || 
                 tx.transactionType.contains('transfer') ||
                 tx.transactionType.contains('withdraw') ||
                 tx.transactionType.contains('buy')) {
        expense += tx.amount;
      }

      // Categorize by status
      if (tx.status.toLowerCase() == 'pending') {
        pending++;
      } else if (tx.status.toLowerCase() == 'completed' || 
                 tx.status.toLowerCase() == 'success') {
        completed++;
      }
    }

    _totalIncome = income;
    _totalExpense = expense;
    _pendingCount = pending;
    _completedCount = completed;
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
    // Don't set global loading here as it affects the whole screen
    
    try {
      final profile = await AuthService.getUserProfile();
      if (mounted) {
        setState(() {
          if (profile != null) {
            _userProfile = profile;
          }
           _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('HomeScreen: Error fetching profile: $e');
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

  @override
  void dispose() {
    _scrollController.dispose();
    _balancePageController.dispose();
    super.dispose();
  }

  String getInitials(String name) {
    List<String> nameParts = name.trim().split(' ');
    String initials = '';

    if (nameParts.isNotEmpty) {
      initials = nameParts[0][0].toUpperCase();
      if (nameParts.length > 1) {
        initials += nameParts[nameParts.length - 1][0].toUpperCase();
      }
    }
    return initials;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: true,
        bottom: true,
        child: AnimatedBuilder(
          animation: WalletProvider.instance,
          builder: (context, child) {
            final provider = WalletProvider.instance;
            
            // Recalculate summaries when provider updates
            _calculateSummaries(provider.transactions);

            return Column(
              children: [
                // FIXED HEADER - Does not scroll
                Column(
                  children: [
                    SizedBox(height: 20.h),
                    // Header with profile, search, and QR code
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
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
                                  width: 50.r,
                                  height: 50.r,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    // remove red border to match clean login avatar
                                    color: Colors.grey[800],
                                  ),
                                  child: Center(
                                    child: Text(
                                      getInitials(_userProfile?.name ?? 'User'),
                                      style: TextStyle(
                                        fontFamily: 'Satoshi',
                                        color: Colors.white,
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 2.w,
                                  child: Container(
                                    width: 12.r,
                                    height: 12.r,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      // remove outer white border
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
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
                                  style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    color: Colors.grey[400],
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  _userProfile?.name ?? 'Anwar Sadatt',
                                  style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    color: Colors.white,
                                    fontSize: 21.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Search button
                          Container(
                            width: 40.r,
                            height: 40.r,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.search_outlined,
                              color: Colors.white,
                              size: 20.r,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          // QR code button with Badge
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const QRScanScreen(),
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                Container(
                                  width: 40.r,
                                  height: 40.r,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.qr_code_scanner_outlined,
                                    color: Colors.white,
                                    size: 20.r,
                                  ),
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10.r),
                                      // remove border to keep badge flat
                                    ),
                                    child: Text(
                                      'Coming Soon',
                                      style: TextStyle(
                                        fontFamily: 'Satoshi',
                                        color: Colors.white,
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    // Action buttons - FIXED - Non-scrollable
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildActionButton(
                            Icons.arrow_upward_outlined,
                            'Send',
                            () => _showSendOptions(context),
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
                            () => _showMoreOptions(context),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await Future.wait([
                        _fetchUserProfile(),
                        WalletProvider.instance.fetchData(),
                      ]);
                    },
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
                            height: 220.h,
                            child: provider.isLoading && provider.balances.isEmpty
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: buttonGreen,
                                    ),
                                  )
                                : (provider.balances.isEmpty
                                    ? Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 24.w,
                                        ),
                                        child: _buildEmptyBalanceCard(),
                                      )
                                    : PageView(
                                        controller: _balancePageController,
                                        children: provider.balances
                                            .map((balance) {
                                          return Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 24.w,
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.all(24.r),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    darkGreen,
                                                    darkGreen.withValues(
                                                        alpha: 0.8),
                                                    lightGreen.withValues(
                                                        alpha: 0.3),
                                                  ],
                                                ),
                                                // remove border to keep it clean
                                                borderRadius:
                                                    BorderRadius.circular(20.r),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            'Total Balance',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Satoshi',
                                                              color: Colors
                                                                  .white70,
                                                              fontSize: 13.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                            ),
                                                          ),
                                                          SizedBox(width: 8.w),
                                                          GestureDetector(
                                                            onTap: () {
                                                              setState(() {
                                                                _isBalanceVisible =
                                                                    !_isBalanceVisible;
                                                              });
                                                              VibrationService
                                                                  .lightImpact();
                                                            },
                                                            child: Icon(
                                                              _isBalanceVisible
                                                                  ? Icons
                                                                      .visibility_outlined
                                                                  : Icons
                                                                      .visibility_off_outlined,
                                                              color:
                                                                  Colors.white70,
                                                              size: 18.r,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Container(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                          horizontal: 12.w,
                                                          vertical: 6.h,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white
                                                              .withValues(
                                                                  alpha: 0.2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            20.r,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          balance['currency'] ??
                                                              'KES',
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Satoshi',
                                                            color: Colors.white,
                                                            fontSize: 12.sp,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 16.h),
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.baseline,
                                                    textBaseline:
                                                        TextBaseline.alphabetic,
                                                    children: [
                                                      Text(
                                                        balance['currency'] ??
                                                            'KES',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'Satoshi',
                                                          color: Colors.white70,
                                                          fontSize: 20.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      SizedBox(width: 8.w),
                                                      Text(
                                                        _isBalanceVisible
                                                            ? (balance['amount']
                                                                    ?.toString() ??
                                                                '0.00')
                                                            : '••••••',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'Satoshi',
                                                          color: Colors.white,
                                                          fontSize: 48.sp,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          letterSpacing: -1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const Spacer(),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 0),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'Date',
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Satoshi',
                                                                color: Colors
                                                                    .white70,
                                                                fontSize: 12.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                                height: 2.h),
                                                            Text(
                                                              balance['date'] ??
                                                                  'Today',
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Satoshi',
                                                                color:
                                                                    Colors.white,
                                                                fontSize: 14.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Container(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                            horizontal: 10.w,
                                                            vertical: 4.h,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white
                                                                .withValues(
                                                                    alpha: 0.15),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.r),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Text(
                                                                balance['change'] ??
                                                                    '+0.00',
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      'Satoshi',
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize:
                                                                      14.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  width: 4.w),
                                                              Icon(
                                                                Icons
                                                                    .trending_up_outlined,
                                                                color:
                                                                    buttonGreen,
                                                                size: 16.r,
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
                                      )),
                          ),
                          SizedBox(height: 12.h),
                          // Page indicators for balance cards
                          if (provider.balances.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                  provider.balances.length, (index) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 3.w),
                                  child: _buildPageIndicator(
                                      index == _currentBalancePage),
                                );
                              }),
                            ),
                          SizedBox(height: 24.h),
                          
                          // Adaptive Summary Pills (Income, Expense, etc.)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding:
                                EdgeInsets.symmetric(horizontal: 24.w),
                            child: Row(
                              children: [
                                _buildInfoCard(
                                  Icons.arrow_downward, 
                                  'Income', 
                                  'KES ${NumberFormat("#,##0.00").format(_totalIncome)}',
                                ),
                                SizedBox(width: 12.w),
                                _buildInfoCard(
                                  Icons.arrow_upward, 
                                  'Expense', 
                                  'KES ${NumberFormat("#,##0.00").format(_totalExpense)}',
                                ),
                                SizedBox(width: 12.w),
                                _buildInfoCard(
                                  Icons.pending_actions, 
                                  'Pending', 
                                  '${_pendingCount} Txns',
                                ),
                                SizedBox(width: 12.w),
                                _buildInfoCard(
                                  Icons.task_alt, 
                                  'Completed', 
                                  '${_completedCount} Txns',
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: 8.h),
                          
                          // Transaction section
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Transaction',
                                  style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    VibrationService.lightImpact();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const TransactionsScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'See All',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      color: buttonGreen,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Transaction list
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: _buildTransactionList(
                                provider.transactions),
                          ),
                          SizedBox(height: 24.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
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
      width: isActive ? 24.w : 8.w,
      height: 8.h,
      decoration: BoxDecoration(
        color: isActive ? buttonGreen : Colors.grey[600],
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        VibrationService.selectionClick();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 60.r,
            height: 60.r,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28.r,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Satoshi',
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(50.r),
        // removed border
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: buttonGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: buttonGreen, size: 16.r),
          ),
          SizedBox(width: 8.w),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.grey[400],
                  fontSize: 10.sp,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBalanceCard() {
    return Container(
      padding: EdgeInsets.all(20.r),
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
        // remove border
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.white70,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'KES',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'KES',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.white70,
                  fontSize: 25.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '0.00',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.white,
                  fontSize: 35.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Top up to start transacting',
            style: TextStyle(
              fontFamily: 'Satoshi',
              color: Colors.white70,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<Transaction> transactions) {
    final recentTransactions = transactions.take(5).toList();

    if (recentTransactions.isEmpty) {
      return Column(
        children: [
          Icon(Icons.history_outlined,
              size: 48.r, color: Colors.grey[600]),
          SizedBox(height: 12.h),
          Text(
            'No recent transactions',
            style: TextStyle(
              fontFamily: 'Satoshi',
              color: Colors.grey[600],
              fontSize: 16.sp,
            ),
          ),
        ],
      );
    }

    return Column(
      children: recentTransactions.map((transaction) {
        return Padding(
          padding: EdgeInsets.only(bottom: 16.0.h),
          child: _buildTransactionItemFromModel(transaction),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionItemFromModel(Transaction transaction) {
    Color statusColor;
    IconData iconData;
    Color iconColor;

    switch (transaction.status.toLowerCase()) {
      case 'complete':
        statusColor = buttonGreen;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'failed':
      default:
        statusColor = Colors.red;
        break;
    }

    switch (transaction.transactionType.toLowerCase()) {
      case 'wallet_topup':
        iconData = Icons.add_circle_outline;
        iconColor = Colors.blue;
        break;
      case 'send_money':
        iconData = Icons.send_outlined;
        iconColor = Colors.orange;
        break;
      case 'payment_link':
        iconData = Icons.link;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.swap_horiz;
        iconColor = Colors.grey;
    }

    return Row(
      children: [
        Container(
          width: 50.r,
          height: 50.r,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconData,
            color: iconColor,
            size: 24.r,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatTransactionType(transaction.transactionType),
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  Text(
                    transaction.phoneNumber.isNotEmpty
                        ? transaction.phoneNumber
                        : 'N/A',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: Colors.white70,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    width: 4.r,
                    height: 4.r,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    transaction.status.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: statusColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Text(
          'KES ${transaction.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontFamily: 'Satoshi',
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatTransactionType(String type) {
    return type
        .split('_')
        .map(
          (word) =>
              word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  Widget _buildTransactionItem(String phone, String date, String amount) {
    return Row(
      children: [
        Container(
          width: 50.r,
          height: 50.r,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_outline,
            color: Colors.white,
            size: 24.r,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                phone,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                date,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontFamily: 'Satoshi',
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
