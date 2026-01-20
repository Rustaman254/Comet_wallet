import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../services/token_service.dart';
import '../services/logger_service.dart';
import '../services/wallet_service.dart';

class AuthDebugScreen extends StatefulWidget {
  const AuthDebugScreen({super.key});

  @override
  State<AuthDebugScreen> createState() => _AuthDebugScreenState();
}

class _AuthDebugScreenState extends State<AuthDebugScreen> {
  Map<String, dynamic> authStatus = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    setState(() => isLoading = true);

    try {
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      final email = await TokenService.getUserEmail();
      final phoneNumber = await TokenService.getPhoneNumber();
      final isAuthenticated = await TokenService.isAuthenticated();

      setState(() {
        authStatus = {
          'is_authenticated': isAuthenticated,
          'token_exists': token != null,
          'token_empty': token?.isEmpty ?? true,
          'token_length': token?.length ?? 0,
          'token_preview': token != null 
              ? '${token.substring(0, 20)}...${token.substring(token.length - 10)}'
              : 'No token',
          'user_id': userId ?? 'Not found',
          'email': email ?? 'Not found',
          'phone_number': phoneNumber ?? 'Not found',
          'timestamp': DateTime.now().toIso8601String(),
        };
      });

      AppLogger.debug(
        LogTags.auth,
        'Auth Debug Status',
        data: authStatus,
      );
    } catch (e) {
      setState(() {
        authStatus = {'error': e.toString()};
      });
      AppLogger.error(LogTags.auth, 'Auth debug error', data: {'error': e.toString()});
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1a1a1a) : const Color(0xFFFAFAFA);
    final cardColor = isDark ? const Color(0xFF2a2a2a) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Authentication Debug',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: buttonGreen,
      ),
      backgroundColor: bgColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: buttonGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (authStatus['is_authenticated'] == true)
                            ? buttonGreen
                            : Colors.red.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Authentication Status',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 8,
                              backgroundColor:
                                  (authStatus['is_authenticated'] == true)
                                      ? buttonGreen
                                      : Colors.red,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              (authStatus['is_authenticated'] == true)
                                  ? 'Authenticated'
                                  : 'Not Authenticated',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Token Details
                  _buildDetailCard('Token Information', cardColor, textColor, [
                    _buildDetailRow('Token Exists', authStatus['token_exists'].toString(), textColor),
                    _buildDetailRow('Token Empty', authStatus['token_empty'].toString(), textColor),
                    _buildDetailRow('Token Length', '${authStatus['token_length']} chars', textColor),
                    _buildDetailRow('Token Preview', authStatus['token_preview'] ?? 'N/A', textColor, isCode: true),
                  ]),
                  const SizedBox(height: 16),

                  // User Details
                  _buildDetailCard('User Information', cardColor, textColor, [
                    _buildDetailRow('User ID', authStatus['user_id'] ?? 'N/A', textColor),
                    _buildDetailRow('Email', authStatus['email'] ?? 'N/A', textColor),
                    _buildDetailRow('Phone', authStatus['phone_number'] ?? 'N/A', textColor),
                  ]),
                  const SizedBox(height: 16),

                  // Error (if any)
                  if (authStatus['error'] != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.red, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Error',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            authStatus['error'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _checkAuthStatus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonGreen,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            'Refresh',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _clearAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.logout),
                          label: Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Test Top-up Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: authStatus['is_authenticated'] == true
                          ? _testTopup
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.payment),
                      label: Text(
                        'Test Wallet Top-up Call',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailCard(
    String title,
    Color cardColor,
    Color textColor,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor, {bool isCode = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isCode
                  ? GoogleFonts.robotoMono(
                      fontSize: 11,
                      color: buttonGreen,
                    )
                  : GoogleFonts.poppins(
                      fontSize: 12,
                      color: textColor,
                    ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAuth() async {
    await TokenService.logout();
    if (mounted) {
      _checkAuthStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
    }
  }

  Future<void> _testTopup() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Test Wallet Top-up',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will attempt a test wallet top-up with:\n'
          'Phone: 0710000000\n'
          'Amount: 1.00\n'
          'Currency: KES',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final response = await WalletService.topupWallet(
                  phoneNumber: '0710000000',
                  amount: 1.0,
                  currency: 'KES',
                );
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Test Result'),
                      content: Text(response.toString()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Test Failed'),
                      content: Text(e.toString()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: buttonGreen),
            child: const Text('Test'),
          ),
        ],
      ),
    );
  }
}
