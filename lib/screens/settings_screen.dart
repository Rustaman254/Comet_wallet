import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../constants/colors.dart';
import '../main.dart'; // Import main.dart to access MyApp
import 'home_screen.dart';
import 'profile_screen.dart';
import '../services/vibration_service.dart';
import '../services/token_service.dart';
import 'sign_in_screen.dart';
import '../services/logger_service.dart';
import '../utils/component_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _vibrationEnabled = true;
  bool _biometricsEnabled = false;


  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final vibrationEnabled = await VibrationService.isEnabled();
    setState(() {
      _vibrationEnabled = vibrationEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Modern Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.0),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: isDark ? Colors.white : lightTextPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showLogoutDialog(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: errorRed.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: HeroIcon(
                            HeroIcons.arrowRightStartOnRectangle,
                            color: errorRed,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // General Section
              _buildSectionHeader('General', isDark),
              _buildModernListTile(
                'Language',
                HeroIcons.language,
                trailing: Text(
                  'English',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: isDark ? Colors.white70 : lightSecondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                isDark: isDark,
                onTap: () {},
              ),
              _buildDivider(isDark),
              _buildModernListTile(
                'My Profile',
                HeroIcons.user,
                isDark: isDark,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
              _buildDivider(isDark),
              _buildModernListTile(
                'Contact Us',
                HeroIcons.envelope,
                isDark: isDark,
                onTap: () {},
              ),

              const SizedBox(height: 32),

              // Security Section
              _buildSectionHeader('Security', isDark),
              _buildModernListTile(
                'Change Password',
                HeroIcons.lockClosed,
                isDark: isDark,
                onTap: () {},
              ),
              _buildDivider(isDark),
              _buildModernListTile(
                'Privacy Policy',
                HeroIcons.shieldCheck,
                isDark: isDark,
                onTap: () {},
              ),

              const SizedBox(height: 32),

              // Preferences Section
              _buildSectionHeader('Preferences', isDark),
              _buildModernSwitchTile(
                'Dark Mode',
                HeroIcons.moon,
                MyApp.themeNotifier.value == ThemeMode.dark,
                (val) async {
                  VibrationService.selectionClick();
                  MyApp.themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                  setState(() {});
                },
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildModernSwitchTile(
                'Biometric',
                HeroIcons.faceSmile,
                _biometricsEnabled,
                (val) {
                  VibrationService.selectionClick();
                  setState(() {
                    _biometricsEnabled = val;
                  });
                },
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildModernSwitchTile(
                'Vibration',
                HeroIcons.rocketLaunch,
                _vibrationEnabled,
                (val) async {
                  await VibrationService.selectionClick();
                  await VibrationService.setEnabled(val);
                  setState(() {
                    _vibrationEnabled = val;
                  });
                },
                isDark: isDark,
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: isDark ? Colors.white70 : lightSecondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildModernListTile(
    String title,
    HeroIcons icon, {
    Widget? trailing,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: buttonGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: HeroIcon(
            icon,
            color: buttonGreen,
            size: 22,
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Outfit',
          color: isDark ? Colors.white : lightTextPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: trailing ?? HeroIcon(
        HeroIcons.chevronRight,
        color: isDark ? Colors.white30 : lightBorder,
        size: 18,
      ),
    );
  }

  Widget _buildModernSwitchTile(
    String title,
    HeroIcons icon,
    bool value,
    Function(bool) onChanged, {
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: buttonGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: HeroIcon(
            icon,
            color: buttonGreen,
            size: 22,
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Outfit',
          color: isDark ? Colors.white : lightTextPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: buttonGreen,
        activeTrackColor: buttonGreen.withValues(alpha: 0.3),
        inactiveThumbColor: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
        inactiveTrackColor: isDark ? Colors.grey.shade800 : lightBorder,
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Divider(
        color: isDark ? Colors.white10 : lightBorder,
        height: 1,
      ),
    );
  }



  void _showLogoutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? darkSurface : lightCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Logout',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: isDark ? Colors.white : lightTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: isDark ? Colors.white70 : lightSecondaryText,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: isDark ? Colors.white70 : lightSecondaryText,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Logout: clear all stored data
              await TokenService.logout();
              
              AppLogger.info(
                LogTags.auth,
                'User logged out',
              );
              
              // Navigate to SignInScreen
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(
              'Logout',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }


}
