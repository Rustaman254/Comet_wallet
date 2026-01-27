import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../services/token_service.dart';
import '../utils/input_decoration.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isEditing = false;
  DateTime _birthDate = DateTime(2000, 9, 28);
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await TokenService.getUserName();
    final email = await TokenService.getUserEmail();
    final phone = await TokenService.getPhoneNumber();
    // In a real app, we'd fetch location and birthDate from the profile API
    
    if (mounted) {
      setState(() {
        _nameController.text = name ?? 'User';
        _emailController.text = email ?? '';
        _phoneController.text = phone ?? '';
        _locationController.text = 'Nairobi, Kenya';
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: buttonGreen,
              onPrimary: Colors.white,
              surface: cardBackground,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
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
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    Text(
                      _isEditing ? 'Edit Profile' : 'Personal Information',
                      style: TextStyle(fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isEditing = !_isEditing;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _isEditing 
                              ? Colors.red.withOpacity(0.1)
                              : buttonGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isEditing ? Icons.close : Icons.edit_outlined,
                          color: _isEditing ? Colors.red : buttonGreen,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Avatar
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/user_avatar.png'),
                          fit: BoxFit.cover,
                        ),
                        color: Colors.grey[800],
                      ),
                      child: const Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _nameController.text,
                      style: TextStyle(fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    _buildField('Full Name', _nameController, Icons.person_outline),
                    const SizedBox(height: 24),
                    _buildField('Email Address', _emailController, Icons.email_outlined),
                    const SizedBox(height: 24),
                    _buildField('Phone Number', _phoneController, Icons.phone_outlined),
                    const SizedBox(height: 24),
                    _buildField('Location', _locationController, Icons.location_on_outlined),
                    const SizedBox(height: 24),
                    _buildBirthDateField(),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Implement save logic here
                        setState(() => _isEditing = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save Changes',
                        style: TextStyle(fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon) {
    if (!_isEditing) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white30, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontFamily: 'Outfit',
                  color: Colors.white30,
                  fontSize: 12,
                ),
              ),
              Text(
                controller.text,
                style: TextStyle(fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Outfit',
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          style: TextStyle(fontFamily: 'Outfit',color: Colors.white, fontSize: 16),
          decoration: buildUnderlineInputDecoration(
            context: context,
            label: '',
            hintText: 'Enter $label',
            prefixIcon: Icon(icon, color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildBirthDateField() {
    final dateStr = DateFormat('dd MMM yyyy').format(_birthDate);
    
    if (!_isEditing) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cake_outlined, color: Colors.white30, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Birth Date',
                style: TextStyle(fontFamily: 'Outfit',
                  color: Colors.white30,
                  fontSize: 12,
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Birth Date',
          style: TextStyle(fontFamily: 'Outfit',
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: AbsorbPointer(
            child: TextFormField(
              decoration: buildUnderlineInputDecoration(
                context: context,
                label: '',
                hintText: dateStr,
                prefixIcon: const Icon(Icons.cake_outlined, color: Colors.white70),
                suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
