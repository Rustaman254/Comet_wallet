import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:comet_wallet/screens/receive_money_screen.dart';
import 'package:comet_wallet/screens/withdraw_money_screen.dart';
import 'package:comet_wallet/screens/wallet_topup_screen.dart';
import 'package:comet_wallet/screens/settings_screen.dart';
import 'package:comet_wallet/screens/swap_screen.dart';
import 'profile_screen.dart';
import 'transactions_screen.dart';
import '../services/toast_service.dart';
import '../models/transaction.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';
import '../widgets/usda_logo.dart';
import '../utils/format_utils.dart';
import 'transaction_details_screen.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  final Set<String> _addedCurrencies = {};

  @override
  void initState() {
    super.initState();
    _balancePageController = PageController();
    _balancePageController.addListener(_onBalancePageChanged);
    _loadAddedCurrencies();
    _loadCachedUserData();
    _fetchUserProfile();
    // Data fetch is now handled by BLoC in main.dart
  }

  Future<void> _loadAddedCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    final added = prefs.getStringList('added_currencies') ?? [];
    if (mounted) {
      setState(() {
        _addedCurrencies.addAll(added);
      });
    }
  }

  Future<void> _saveAddedCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('added_currencies', _addedCurrencies.toList());
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
          walletBalances: [],
          cardanoAddress: '',
          balanceAda: 0.0,
          balanceUsda: 0.0,
          balanceUsdaRaw: 0,
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
  String _getLandmarkImage(String currency) {
    // Use world map for all currencies
    return 'assets/images/world_map.png';
  }

  Widget _getLandmarkWidget(String currency) {
    final assetPath = _getLandmarkImage(currency);
    if (assetPath.isNotEmpty) {
      return Opacity(
        opacity: 0.3, // Increased from 0.08 for better visibility
        child: Image.asset(
          assetPath,
          width: 180.r,
          height: 180.r,
          fit: BoxFit.contain,
        ),
      );
    }

    // Generic icons for other currencies
    HeroIcons icon;
    switch (currency.toUpperCase()) {
      case 'EUR':
        icon = HeroIcons.buildingLibrary;
        break;
      case 'GBP':
        icon = HeroIcons.buildingOffice;
        break;
      case 'ZAR':
        icon = HeroIcons.globeAlt;
        break;
      default:
        icon = HeroIcons.buildingLibrary;
    }

    return HeroIcon(
      icon,
      size: 150.r,
      color: Colors.white,
    );
  }

  void _showAddCurrencyDialog() {
    final List<String> availableCurrencies = [
      'KES', 'USD', 'USDA', 'UGX', 'TZS', 'RWF', 'EUR', 'GBP', 'ZAR'
    ];
    
    // Determine local currency same as in build method
    final localCurrency = _userProfile?.location.toUpperCase() == 'KENYA' ? 'KES' : 
                         (_userProfile?.location.toUpperCase() == 'UGANDA' ? 'UGX' : 
                         (_userProfile?.location.toUpperCase() == 'TANZANIA' ? 'TZS' : 
                         (_userProfile?.location.toUpperCase() == 'RWANDA' ? 'RWF' : 'KES')));

    // Currencies currently visible on dashboard
    final Set<String> visibleCurrencies = {
      localCurrency,
      'USDA',
      ..._addedCurrencies,
    };
    
    // Available currencies to add (those NOT visible)
    final List<String> toAdd = availableCurrencies.where((c) => !visibleCurrencies.contains(c)).toList();

    if (toAdd.isEmpty) {
      ToastService().showSuccess(context, 'You have all available currencies on your dashboard!');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: getCardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Currency',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: getTextColor(context),
                ),
              ),
              SizedBox(height: 16.h),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: toAdd.length,
                  separatorBuilder: (_, __) => Divider(color: getBorderColor(context)),
                  itemBuilder: (context, index) {
                    final currency = toAdd[index];
                    return ListTile(
                      leading: currency == 'USDA' 
                        ? const USDALogo(size: 32)
                        : Container(
                            width: 32.r,
                            height: 32.r,
                            alignment: Alignment.center,
                            child: Text(
                              USDALogo.getFlag(currency),
                              style: TextStyle(fontSize: 24.sp),
                            ),
                          ),
                      title: Text(
                        '${USDALogo.getFlag(currency)} ${currency == 'USDA' ? 'USDA (Cardano)' : currency}',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: getTextColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () async {
                        setState(() {
                          _addedCurrencies.add(currency);
                        });
                        await _saveAddedCurrencies();
                        if (!mounted) return;
                        Navigator.pop(context);
                        context.read<WalletBloc>().add(UpdateBalance(
                          currency: currency,
                          amount: 0.0,
                        ));
                        ToastService().showSuccess(context, '$currency added to your wallet');
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: true,
        bottom: true,
        child: BlocConsumer<WalletBloc, WalletState>(
          listener: (context, state) {
            // Handle errors with toast messages
            if (state is WalletError) {
              ToastService().showError(context, state.message);
            }
          },
          builder: (context, state) {
            // Extract data from state
            var rawBalances = state is WalletLoaded ? List<Map<String, dynamic>>.from(state.balances) : 
                           (state is WalletBalanceUpdated ? List<Map<String, dynamic>>.from(state.balances) : <Map<String, dynamic>>[]);
            
            // Filter balances: Only show Local, USDA, and manually added ones
            final localCurrency = _userProfile?.location.toUpperCase() == 'KENYA' ? 'KES' : 
                                 (_userProfile?.location.toUpperCase() == 'UGANDA' ? 'UGX' : 
                                 (_userProfile?.location.toUpperCase() == 'TANZANIA' ? 'TZS' : 
                                 (_userProfile?.location.toUpperCase() == 'RWANDA' ? 'RWF' : 'KES')));
            
            final balances = rawBalances.where((b) {
              final curr = b['currency']?.toString().toUpperCase() ?? '';
              return curr == localCurrency || curr == 'USDA' || _addedCurrencies.contains(curr);
            }).toList();
            
            balances.sort((a, b) {
              final currencyA = a['currency']?.toString() ?? '';
              final currencyB = b['currency']?.toString() ?? '';
              
              if (currencyA == localCurrency) return -1;
              if (currencyB == localCurrency) return 1;
              if (currencyA == 'USDA') return -1;
              if (currencyB == 'USDA') return 1;
              return currencyA.compareTo(currencyB);
            });

            final transactions = state is WalletLoaded ? state.transactions : 
                               (state is WalletBalanceUpdated ? state.transactions : <Transaction>[]);
            final isLoading = state is WalletLoading;
            
            // Calculate summaries from BLoC state
            if (state is WalletLoaded) {
              _totalIncome = state.totalIncome;
              _totalExpense = state.totalExpense;
              _pendingCount = state.pendingCount;
              _completedCount = state.completedCount;
            } else if (state is WalletBalanceUpdated) {
              _totalIncome = state.totalIncome;
              _totalExpense = state.totalExpense;
              _pendingCount = state.pendingCount;
              _completedCount = state.completedCount;
            }

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
                                    // Match login avatar style
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.grey[800] 
                                        : Colors.grey[300],
                                  ),
                                  child: Center(
                                    child: Text(
                                      getInitials(_userProfile?.name ?? 'User'),
                                      style: TextStyle(
                                        fontFamily: 'Satoshi',
                                        color: getTextColor(context),
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
                          // Welcome text removed

                          const Spacer(),
                          // Search button
                          // Search button removed as per request
                          /*
                          Container(
                            width: 40.r,
                            height: 40.r,
                            decoration: BoxDecoration(
                              color: getTextColor(context).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.search_outlined,
                              color: getTextColor(context),
                              size: 20.r,
                            ),
                          ),
                          */
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Coming Soon badge above the icon
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10.r),
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
                                SizedBox(height: 4.h),
                                // QR scan icon
                                Container(
                                  width: 40.r,
                                  height: 40.r,
                                  decoration: BoxDecoration(
                                    color: getTextColor(context).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.qr_code_scanner_outlined,
                                    color: getTextColor(context),
                                    size: 20.r,
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
                      // Action buttons - Scrollable to fit all
                    Padding(
                      padding: EdgeInsets.zero, // Removed padding here, added to SingleChildScrollView container
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                           padding: EdgeInsets.symmetric(horizontal: 24.w),
                           child: Row(
                            mainAxisAlignment: MainAxisAlignment.start, // Changed to start for scrollable
                            children: [
                              _buildActionButton(
                                Icons.arrow_upward_outlined,
                                'Send',
                                () => _showSendOptions(context),
                                backgroundColor: transactionSendColor,
                              ),
                              SizedBox(width: 16.w),
                              _buildActionButton(
                                Icons.arrow_downward_outlined,
                                'Withdraw',
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const WithdrawMoneyScreen(),
                                    ),
                                  );
                                },
                                backgroundColor: transactionReceiveColor,
                              ),
                              SizedBox(width: 16.w),
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
                                backgroundColor: transactionTopupColor,
                              ),
                              SizedBox(width: 16.w),
                              _buildActionButton(
                                Icons.swap_horiz_outlined,
                                'Swap',
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SwapScreen(),
                                    ),
                                  );
                                },
                                backgroundColor: transactionSwapColor,
                              ),
                              SizedBox(width: 16.w),
                              _buildActionButton(
                                Icons.more_horiz,
                                'More',
                                () => _showMoreOptions(context),
                                backgroundColor: transactionDefaultColor,
                              ),
                            ],
                          ),
                        ),
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
                      ]);
                      // Dispatch refresh event to BLoC
                      if (context.mounted) {
                        context.read<WalletBloc>().add(const RefreshWallet());
                      }
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
                            child: isLoading && balances.isEmpty
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: buttonGreen,
                                    ),
                                  )
                                : (balances.isEmpty
                                    ? Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 24.w,
                                        ),
                                        child: _buildEmptyBalanceCard(),
                                      )
                                    : PageView(
                                        controller: _balancePageController,
                                          children: [
                                            ...balances.map((balance) {
                                              final currency = balance['currency'] ?? '';
                                              print('DEBUG: Building card for currency: $currency'); // Debug print
                                              final isUSDA = currency == 'USDA';
                                              final balanceAmount = _isBalanceVisible
                                                  ? _formatAmount(double.tryParse(balance['amount']?.toString() ?? '0') ?? 0)
                                                  : '••••••';
                                              
                                          return Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 24.w,
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(20.r),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                        colors: Theme.of(context).brightness == Brightness.dark
                                                          ? [
                                                              darkGreen,
                                                              darkGreen.withValues(alpha: 0.8),
                                                              lightGreen.withValues(alpha: 0.3),
                                                            ]
                                                          : [
                                                              const Color(0xFF2563EB), // Bright blue
                                                              const Color(0xFF3B82F6), // Medium blue
                                                              const Color(0xFF60A5FA), // Light blue
                                                            ],
                                                      ),
                                                    ),
                                                    child: Stack(
                                                      children: [
                                                        // LANDMARK IMAGE - Background (Blended)
                                                        if (!isUSDA)
                                                          Positioned(
                                                            bottom: -20,
                                                            right: -20,
                                                            child: _getLandmarkWidget(currency),
                                                          ),
                                                        
                                                        // CONTENT
                                                        Padding(
                                                          padding: EdgeInsets.all(24.r),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              // TOP ROW: "Total Balance" and Level/Currency Pill
                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  Text(
                                                                    'Total Balance',
                                                                    style: TextStyle(
                                                                      fontFamily: 'Satoshi',
                                                                      color: Colors.white.withValues(alpha: 0.9),
                                                                      fontSize: 16.sp,
                                                                      fontWeight: FontWeight.bold,
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                                                    decoration: BoxDecoration(
                                                                      color: Colors.white.withValues(alpha: 0.2),
                                                                      borderRadius: BorderRadius.circular(20.r),
                                                                    ),
                                                                    child: Row(
                                                                      children: [
                                                                         Container(
                                                                            width: 20.r,
                                                                            height: 20.r,
                                                                            decoration: const BoxDecoration(
                                                                              shape: BoxShape.circle,
                                                                            ),
                                                                            clipBehavior: Clip.antiAlias,
                                                                            alignment: Alignment.center,
                                                                            child: isUSDA 
                                                                              ? const USDALogo(size: 20) 
                                                                              : Text(
                                                                                  USDALogo.getFlag(currency),
                                                                                  style: TextStyle(fontSize: 16.sp),
                                                                                ),
                                                                         ),
                                                                         SizedBox(width: 6.w),
                                                                         Text(
                                                                            currency,
                                                                            style: TextStyle(
                                                                              fontFamily: 'Satoshi',
                                                                              color: Colors.white,
                                                                              fontSize: 12.sp,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                         ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),

                                                              const Spacer(),

                                                              // MIDDLE ROW: Currency Symbol + Balance + Eye
                                                              Row(
                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                children: [
                                                                  Text(
                                                                    balance['symbol'] ?? (isUSDA ? '\$' : currency),
                                                                    style: TextStyle(
                                                                      fontFamily: 'Satoshi',
                                                                      color: Colors.white.withValues(alpha: 0.7),
                                                                      fontSize: 20.sp,
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                  SizedBox(width: 8.w),
                                                                  Text(
                                                                    balanceAmount,
                                                                    style: TextStyle(
                                                                      fontFamily: 'Satoshi',
                                                                      color: Colors.white,
                                                                      fontSize: 32.sp,
                                                                      fontWeight: FontWeight.bold,
                                                                      letterSpacing: -1,
                                                                    ),
                                                                  ),
                                                                   SizedBox(width: 12.w),
                                                                    GestureDetector(
                                                                      onTap: () {
                                                                        setState(() {
                                                                          _isBalanceVisible = !_isBalanceVisible;
                                                                        });
                                                                        VibrationService.lightImpact();
                                                                      },
                                                                      child: Container(
                                                                        padding: EdgeInsets.all(4.r),
                                                                        decoration: BoxDecoration(
                                                                          color: Colors.white.withValues(alpha: 0.1),
                                                                          shape: BoxShape.circle,
                                                                        ),
                                                                        child: Icon(
                                                                          _isBalanceVisible
                                                                              ? Icons.visibility_outlined
                                                                              : Icons.visibility_off_outlined,
                                                                          color: Colors.white,
                                                                          size: 16.sp,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),

                                                              const Spacer(),

                                                              // BOTTOM ROW: Context specific
                                                              if (isUSDA) ...[
                                                                 // Sponsored by Cardano
                                                                 Row(
                                                                   children: [
                                                                     // Cardano logo placeholder (can be replaced with actual PNG)
                                                                     Container(
                                                                       width: 20.r,
                                                                       height: 20.r,
                                                                       decoration: BoxDecoration(
                                                                         color: Colors.white,
                                                                         shape: BoxShape.circle,
                                                                       ),
                                                                       padding: EdgeInsets.all(4.r),
                                                                       child: SvgPicture.asset(
                                                                         'assets/images/cardano_logo.svg',
                                                                         width: 12.r,
                                                                         height: 12.r,
                                                                       ),
                                                                     ),
                                                                     SizedBox(width: 6.w),
                                                                     Text(
                                                                       'Powered by Cardano',
                                                                       style: TextStyle(
                                                                         fontFamily: 'Satoshi',
                                                                         color: Colors.white70,
                                                                         fontSize: 11.sp,
                                                                         fontWeight: FontWeight.w500,
                                                                       ),
                                                                     ),
                                                                   ],
                                                                 ),
                                                                 SizedBox(height: 12.h),
                                                                 Row(
                                                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                   children: [
                                                                     // Address Truncated
                                                                     Column(
                                                                       crossAxisAlignment: CrossAxisAlignment.start,
                                                                       children: [
                                                                         Text(
                                                                           'Cardano Address',
                                                                           style: TextStyle(
                                                                             fontFamily: 'Satoshi',
                                                                             color: Colors.white54,
                                                                             fontSize: 10.sp,
                                                                           ),
                                                                         ),
                                                                         SizedBox(height: 4.h),
                                                                         GestureDetector(
                                                                            onTap: () async {
                                                                              if (_userProfile?.cardanoAddress != null) {
                                                                                await Clipboard.setData(ClipboardData(text: _userProfile!.cardanoAddress));
                                                                                if (context.mounted) {
                                                                                  ToastService().showSuccess(context, 'Address copied');
                                                                                }
                                                                                VibrationService.lightImpact();
                                                                              }
                                                                            },
                                                                           child: Row(
                                                                             children: [
                                                                                Text(
                                                                                 _userProfile?.cardanoAddress != null && _userProfile!.cardanoAddress.length > 20
                                                                                     ? '${_userProfile!.cardanoAddress.substring(0, 10)}...${_userProfile!.cardanoAddress.substring(_userProfile!.cardanoAddress.length - 8)}'
                                                                                     : (_userProfile?.cardanoAddress ?? '...'),
                                                                                 style: TextStyle(
                                                                                   fontFamily: 'Satoshi',
                                                                                   color: Colors.white.withValues(alpha: 0.9),
                                                                                   fontSize: 13.sp,
                                                                                   fontWeight: FontWeight.w500,
                                                                                 ),
                                                                               ),
                                                                               SizedBox(width: 6.w),
                                                                               Icon(Icons.copy, color: Colors.white54, size: 12.sp),
                                                                             ],
                                                                           ),
                                                                         ),
                                                                       ],
                                                                     ),
                                                                     // Swap Button
                                                                     GestureDetector(
                                                                       onTap: () {
                                                                         Navigator.push(context, MaterialPageRoute(builder: (_) => const SwapScreen()));
                                                                       },
                                                                       child: Container(
                                                                         padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                                                                         decoration: BoxDecoration(
                                                                           color: Colors.white,
                                                                           borderRadius: BorderRadius.circular(24.r),
                                                                         ),
                                                                         child: Text(
                                                                           'Swap',
                                                                           style: TextStyle(
                                                                             fontFamily: 'Satoshi',
                                                                             color: Colors.black,
                                                                             fontSize: 14.sp,
                                                                             fontWeight: FontWeight.bold,
                                                                           ),
                                                                         ),
                                                                       ),
                                                                     ),
                                                                   ],
                                                                 )
                                                               ] else ...[ 
                                                                  // Date (Full formatted)
                                                                  Text(
                                                                    DateFormat('d MMMM yyyy').format(DateTime.now()), 
                                                                    style: TextStyle(
                                                                      fontFamily: 'Satoshi',
                                                                      color: Colors.white.withValues(alpha: 0.7),
                                                                      fontSize: 16.sp, 
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                               ],
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                            // ADD NEW CURRENCY CARD
                                            Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                                              child: GestureDetector(
                                                onTap: _showAddCurrencyDialog,
                                                child: Container(
                                                  padding: EdgeInsets.all(24.r),
                                                  decoration: BoxDecoration(
                                                    color: getCardColor(context),
                                                    borderRadius: BorderRadius.circular(20.r),
                                                    border: Border.all(
                                                      color: getBorderColor(context),
                                                      width: 2,
                                                      style: BorderStyle.solid,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Container(
                                                        padding: EdgeInsets.all(16.r),
                                                        decoration: BoxDecoration(
                                                          color: buttonGreen.withOpacity(0.1),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: Icon(
                                                          Icons.add_rounded,
                                                          color: buttonGreen,
                                                          size: 40.r,
                                                        ),
                                                      ),
                                                      SizedBox(height: 16.h),
                                                      Text(
                                                        'Add New Currency',
                                                        style: TextStyle(
                                                          fontFamily: 'Satoshi',
                                                          color: getTextColor(context),
                                                          fontSize: 18.sp,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      SizedBox(height: 8.h),
                                                      Text(
                                                        'Get a multi-currency wallet in seconds',
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          fontFamily: 'Satoshi',
                                                          color: getSecondaryTextColor(context),
                                                          fontSize: 14.sp,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                      )),
                          ),
                          SizedBox(height: 12.h),
                           // Page indicators for balance cards
                          if (balances.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                  balances.length + 1, (index) { // +1 for Add New card
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
                                    color: getTextColor(context),
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
                                transactions),
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
      IconData icon, String label, VoidCallback onTap, {Color? backgroundColor}) {
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
              color: backgroundColor ?? Colors.white.withValues(alpha: 0.1),
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
              color: getTextColor(context),
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
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white.withValues(alpha: 0.05) 
            : Colors.white,
        borderRadius: BorderRadius.circular(50.r),
        boxShadow: Theme.of(context).brightness == Brightness.dark 
            ? null 
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
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
                  color: getSecondaryTextColor(context),
                  fontSize: 10.sp,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: getTextColor(context),
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
          colors: Theme.of(context).brightness == Brightness.dark
            ? [
                darkGreen,
                darkGreen.withValues(alpha: 0.8),
                lightGreen.withValues(alpha: 0.3),
              ]
            : [
                const Color(0xFF2563EB), // Bright blue
                const Color(0xFF3B82F6), // Medium blue
                const Color(0xFF60A5FA), // Light blue
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
    final recentTransactions = transactions.take(6).toList();

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
      case 'success':
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
        iconColor = transactionTopupColor;
        break;
      case 'send_money':
      case 'transfer_usda':
        iconData = Icons.send_outlined;
        iconColor = transactionSendColor;
        break;
      case 'payment_link':
        iconData = Icons.link;
        iconColor = transactionSwapColor;
        break;
      default:
        iconData = Icons.swap_horiz;
        iconColor = getTransactionColor(transaction.transactionType);
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailsScreen(transaction: transaction),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 22.r,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTransactionType(transaction.transactionType),
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: getTextColor(context),
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Text(
                        transaction.phoneNumber.isNotEmpty
                            ? transaction.phoneNumber
                            : 'N/A',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: getSecondaryTextColor(context),
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Container(
                        width: 3.r,
                        height: 3.r,
                        decoration: BoxDecoration(
                          color: getTertiaryTextColor(context),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        transaction.status.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: statusColor,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (transaction.currency == 'USDA')
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: USDALogo(size: 14),
                      )
                    else
                      Text(
                        USDALogo.getFlag(transaction.currency),
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    SizedBox(width: 4.w),
                    Text(
                      FormatUtils.formatAmount(transaction.amount),
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: getTextColor(context),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  DateFormat('MMM dd').format(transaction.createdAt),
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    color: getTertiaryTextColor(context),
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTransactionType(String type) {
    String capitalizeWord(String word) {
      if (word.toUpperCase() == 'USDA') return 'USDA';
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }

    return type.split('_').map(capitalizeWord).join(' ');
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

  String _formatAmount(double amount) {
    if (amount % 1 == 0) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }
}
