import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../constants/colors.dart';
import '../services/vibration_service.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'English';

  final List<Map<String, String>> _languages = [
    {'name': 'English', 'code': 'en', 'flag': '🇺🇸'},
    {'name': 'Swahili', 'code': 'sw', 'flag': '🇰🇪'},
    {'name': 'French', 'code': 'fr', 'flag': '🇫🇷'},
    {'name': 'Spanish', 'code': 'es', 'flag': '🇪🇸'},
    {'name': 'German', 'code': 'de', 'flag': '🇩🇪'},
    {'name': 'Chinese', 'code': 'zh', 'flag': '🇨🇳'},
    {'name': 'Arabic', 'code': 'ar', 'flag': '🇸🇦'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : lightPrimaryText,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Language',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: isDark ? Colors.white : lightPrimaryText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: _languages.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final language = _languages[index];
            final isSelected = _selectedLanguage == language['name'];

            return GestureDetector(
              onTap: () {
                VibrationService.selectionClick();
                setState(() {
                  _selectedLanguage = language['name']!;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryBrandColor.withValues(alpha: 0.1)
                      : (isDark ? darkSurface : lightCardBackground),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? primaryBrandColor
                        : (isDark ? darkBorder : lightBorder),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      language['flag']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      language['name']!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: isDark ? Colors.white : lightPrimaryText,
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: primaryBrandColor,
                        size: 24,
                      )
                    else
                      Icon(
                        Icons.circle_outlined,
                        color: isDark ? Colors.white24 : lightBorder,
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
