import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../main.dart'; // Import main.dart to access MyApp
import 'home_screen.dart';
import 'profile_screen.dart';
import '../services/vibration_service.dart';
import '../services/token_service.dart';
import 'sign_in_screen.dart';
import '../services/logger_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _vibrationEnabled = true;
  bool _biometricsEnabled = false;
  int _currentIndex = 3;

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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20
                        ),
                      ),
                    ),
                    Text(
                    'Settings',
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    ),
                     GestureDetector(
                        onTap: () => _showLogoutDialog(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 20
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // General Section
               _buildSectionHeader('General'),
              _buildSimpleListTile(
                  'Language',
                  trailing: Text(
                      'English',
                      style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                      ),
                  ),
                  onTap: () {}
              ),
              _buildDivider(),
              _buildSimpleListTile('My Profile', onTap: () {
                   Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
              }),
              _buildDivider(),
              _buildSimpleListTile('Contact Us', onTap: () {}),

              const SizedBox(height: 32),

              // Security Section
               _buildSectionHeader('Security'),
              _buildSimpleListTile('Change Password', onTap: () {}),
               _buildDivider(),
              _buildSimpleListTile('Privacy Policy', onTap: () {}),

              const SizedBox(height: 32),

              // Data/Preferences (Simulated from "Choose what data you share with us" in image context)
              _buildSectionHeader('Choose what data you share with us'),
              _buildSwitchTile(
                  'Dark Mode',
                  MyApp.themeNotifier.value == ThemeMode.dark,
                  (val) async {
                    VibrationService.selectionClick();
                    MyApp.themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                    setState(() {}); // specific rebuild for this switch visual
                  },
              ),
              const Divider(color: Colors.white10),
              _buildSwitchTile(
                  'Biometric',
                  _biometricsEnabled,
                  (val) {
                      VibrationService.selectionClick();
                      setState(() {
                          _biometricsEnabled = val;
                      });
                  }
              ),
               _buildDivider(),
                _buildSwitchTile(
                  'Vibration',
                  _vibrationEnabled,
                  (val) async {
                      await VibrationService.selectionClick();
                      await VibrationService.setEnabled(val);
                      setState(() {
                          _vibrationEnabled = val;
                      });
                  }
               ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSectionHeader(String title) {
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                  title,
                  style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                  ),
              ),
          ),
      );
  }

  Widget _buildSimpleListTile(String title, {Widget? trailing, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14, // Requested size
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: trailing ?? Icon(
          Icons.arrow_forward_ios,
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          size: 14, // Slightly smaller to match text
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
       return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          title: Text(
              title,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
              ),
          ),
          trailing: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: buttonGreen, // Visible in both
              activeTrackColor: buttonGreen.withOpacity(0.3),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
      );
  }

  Widget _buildDivider() {
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Divider(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
          ),
      );
  }



  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.white70,
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
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else {
            setState(() {
              _currentIndex = index;
            });
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'My Cards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
