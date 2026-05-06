import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heroicons/heroicons.dart';
import '../../bloc/ticketing/ticketing_bloc.dart';
import '../../bloc/ticketing/ticketing_event.dart';
import '../../bloc/ticketing/ticketing_state.dart';
import '../../constants/colors.dart';
import '../../services/token_service.dart';
import '../../services/vibration_service.dart';
import '../../services/toast_service.dart';
import '../../widgets/primary_button.dart';
import 'my_tickets_screen.dart';

class CreateTicketScreen extends StatefulWidget {
  final bool isGuest;
  const CreateTicketScreen({super.key, this.isGuest = false});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;

  final List<String> _categories = [
    'Payment Issue',
    'Account Access',
    'KYC Help',
    'General Enquiry',
    'Other'
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitTicket() {
    if (_formKey.currentState!.validate()) {
      VibrationService.selectionClick();
      if (widget.isGuest) {
        context.read<TicketingBloc>().add(CreateGuestTicketRequested(
          userEmail: _emailController.text.trim(),
          issueDescription: _descriptionController.text.trim(),
          issueCategory: _selectedCategory,
        ));
      } else {
        context.read<TicketingBloc>().add(CreateTicketRequested(
          issueCategory: _selectedCategory,
          issueDescription: _descriptionController.text.trim(),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<TicketingBloc, TicketingState>(
      listener: (context, state) {
        if (state.status == TicketingStatus.success && state.successMessage != null) {
          ToastService().showSuccess(context, state.successMessage!);
          if (!widget.isGuest) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MyTicketsScreen()),
            );
          } else {
            Navigator.of(context).pop();
          }
        } else if (state.status == TicketingStatus.failure && state.errorMessage != null) {
          ToastService().showError(context, state.errorMessage!);
        }
      },
      child: Scaffold(
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
            'Create Support Ticket',
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How can we help?',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : lightPrimaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Describe your issue and we\'ll get back to you as soon as possible.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      color: isDark ? Colors.white70 : lightSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (widget.isGuest) ...[
                    _buildLabel('Email Address', isDark),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'Enter your email',
                      icon: HeroIcons.envelope,
                      isDark: isDark,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                  _buildLabel('Issue Category', isDark),
                  const SizedBox(height: 8),
                  _buildDropdown(isDark),
                  const SizedBox(height: 20),
                  _buildLabel('Description', isDark),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _descriptionController,
                    hint: widget.isGuest 
                        ? 'Describe your issue details...' 
                        : 'Describe your issue (optional)...',
                    icon: HeroIcons.documentText,
                    isDark: isDark,
                    maxLines: 5,
                    validator: widget.isGuest ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please provide a description';
                      }
                      return null;
                    } : null,
                  ),
                  const SizedBox(height: 40),
                  BlocBuilder<TicketingBloc, TicketingState>(
                    builder: (context, state) {
                      return PrimaryButton(
                        text: 'Submit Ticket',
                        onPressed: _submitTicket,
                        isLoading: state.status == TicketingStatus.loading,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : lightPrimaryText,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required HeroIcons icon,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        fontFamily: 'Outfit',
        color: isDark ? Colors.white : lightPrimaryText,
      ),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : lightTertiaryText,
          fontFamily: 'Outfit',
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: HeroIcon(
            icon,
            color: isDark ? Colors.white38 : lightTertiaryText,
            size: 20,
          ),
        ),
        filled: true,
        fillColor: isDark ? darkSurface : lightCardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? darkBorder : lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? darkBorder : lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: primaryBrandColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? darkSurface : lightCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? darkBorder : lightBorder,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          hint: Text(
            'Select category',
            style: TextStyle(
              color: isDark ? Colors.white38 : lightTertiaryText,
              fontFamily: 'Outfit',
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isDark ? Colors.white38 : lightTertiaryText,
          ),
          isExpanded: true,
          dropdownColor: isDark ? darkSurface : lightCardBackground,
          borderRadius: BorderRadius.circular(16),
          items: _categories.map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(
                category,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: isDark ? Colors.white : lightPrimaryText,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCategory = newValue;
            });
          },
        ),
      ),
    );
  }
}
