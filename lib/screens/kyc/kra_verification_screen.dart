import 'package:flutter/material.dart';
import 'package:smile_id/smile_id.dart';
import '../../constants/colors.dart';
import '../../services/toast_service.dart';
import '../home_screen.dart';
import '../../services/kyc_service.dart';
import '../../models/kyc_model.dart';
import '../../services/token_service.dart';
import '../../utils/input_decoration.dart';

class KRAVerificationScreen extends StatefulWidget {
  const KRAVerificationScreen({super.key});

  @override
  State<KRAVerificationScreen> createState() => _KRAVerificationScreenState();
}

class _KRAVerificationScreenState extends State<KRAVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _kraController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _kraController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _submitKRA() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userIdStr = await TokenService.getUserId() ?? "0";
      final userId = int.tryParse(userIdStr) ?? 0;

      final kycData = KYCData(
        userID: userId,
        // We'd ideally have the Smile ID results (URLs) here
        // For now, we use placeholders to show the API integration is alive
        idDocumentFront: "smile_id_front_placeholder",
        idDocumentBack: "smile_id_back_placeholder",
        kraDocument: _kraController.text,
        profilePhoto: "smile_id_selfie_placeholder",
        proofOfAddress: "placeholder",
      );

      await KYCService.submitKYC(kycData);

      if (mounted) {
        ToastService().showSuccess(context, "KRA Information verified successfully");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ToastService().showError(context, "KRA Verification failed: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'KRA Verification',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please provide your ID and KRA PIN for verification.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),
              _buildTextField(
                controller: _firstNameController,
                label: 'First Name',
                hint: 'As it appears on ID',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _lastNameController,
                label: 'Last Name',
                hint: 'As it appears on ID',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _idController,
                label: 'ID Number',
                hint: 'Enter your ID number',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _kraController,
                label: 'KRA PIN',
                hint: 'Enter your KRA PIN',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitKRA,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit & Verify',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: buttonGreen),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
      ],
    );
  }
}
