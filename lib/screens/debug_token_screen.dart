import 'package:flutter/material.dart';
import '../services/token_service.dart';
import '../services/logger_service.dart';
import '../utils/debug_utils.dart';

/// Debug Token Status Screen - For troubleshooting authentication issues
class DebugTokenScreen extends StatefulWidget {
  const DebugTokenScreen({Key? key}) : super(key: key);

  @override
  State<DebugTokenScreen> createState() => _DebugTokenScreenState();
}

class _DebugTokenScreenState extends State<DebugTokenScreen> {
  Map<String, dynamic> tokenStatus = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshTokenStatus();
  }

  Future<void> _refreshTokenStatus() async {
    setState(() => isLoading = true);

    try {
      final debugInfo = await TokenService.debugTokenData();
      final userData = await TokenService.getUserData();

      setState(() {
        tokenStatus = {
          ...debugInfo,
          'user_data': userData,
        };
      });

      AppLogger.info('DEBUG', 'Token status refreshed');
    } catch (e) {
      AppLogger.error('DEBUG', 'Error refreshing token status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _runFullDiagnostics() async {
    AppLogger.info('DEBUG', 'Starting full diagnostics...');
    await DebugUtils.runFullDiagnostics();
    await _refreshTokenStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diagnostics complete - check console')),
      );
    }
  }

  Future<void> _testWalletTokenAccess() async {
    AppLogger.info('DEBUG', 'Testing wallet token access...');
    await DebugUtils.verifyTokenForWallet();
    await _refreshTokenStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet token test complete - check console')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Token Debug Info'),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Authentication Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildStatusItem(
                            'Token Exists',
                            tokenStatus['token_exists']?.toString() ?? 'N/A',
                            tokenStatus['token_exists'] == true,
                          ),
                          _buildStatusItem(
                            'Token Not Empty',
                            tokenStatus['token_not_empty']?.toString() ?? 'N/A',
                            tokenStatus['token_not_empty'] == true,
                          ),
                          _buildStatusItem(
                            'Is Authenticated',
                            tokenStatus['is_authenticated']?.toString() ?? 'N/A',
                            tokenStatus['is_authenticated'] == true,
                          ),
                          _buildStatusItem(
                            'Token Length',
                            tokenStatus['token_length']?.toString() ?? 'N/A',
                            tokenStatus['token_length'] != null && tokenStatus['token_length'] > 100,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Token Preview
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Token Preview',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              tokenStatus['token_preview']?.toString() ?? 'No token',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User Data
                  if (tokenStatus['user_data'] != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stored User Data',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...(tokenStatus['user_data'] as Map<String, dynamic>)
                                .entries
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          e.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          e.value?.toString() ?? 'null',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _refreshTokenStatus,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Status'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _runFullDiagnostics,
                      icon: const Icon(Icons.bug_report),
                      label: const Text('Run Full Diagnostics'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _testWalletTokenAccess,
                      icon: const Icon(Icons.wallet),
                      label: const Text('Test Wallet Token Access'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: const Text(
                      '💡 Tip: Check the console output (flutter logs) for detailed debugging information.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusItem(String label, String value, bool isSuccess) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.cancel,
                color: isSuccess ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
