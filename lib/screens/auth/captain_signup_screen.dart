import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/primary_button.dart';
import '../../services/captain_auth_service.dart';
import 'captain_login_screen.dart';

class CaptainSignupScreen extends StatefulWidget {
  const CaptainSignupScreen({super.key});

  @override
  State<CaptainSignupScreen> createState() => _CaptainSignupScreenState();
}

class _CaptainSignupScreenState extends State<CaptainSignupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _licenseNumberController = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _vehicleNumberController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    setState(() => _errorMessage = null);

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    final vehicle = _vehicleNumberController.text.trim();
    final license = _licenseNumberController.text.trim();

    // Field-by-field validation
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Full Name is required.');
      return;
    }

    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number.');
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address (e.g. name@domain.com).');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters long.');
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = 'Password and Confirm Password do not match.');
      return;
    }

    if (vehicle.isEmpty) {
      setState(() => _errorMessage = 'Vehicle/Bike Number is required.');
      return;
    }

    if (license.isEmpty) {
      setState(() => _errorMessage = 'Driving License Number is required.');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));

    final result = await CaptainAuthService().registerCaptain(
      name: name,
      phone: cleanDigits,
      email: email,
      password: password,
      vehicleNumber: vehicle,
      licenseNumber: license,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration Successful! Please log in to start driving.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 4),
        ),
      );

      // Navigate to Captain Login screen with phone number prefilled
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CaptainLoginScreen(prefilledPhone: cleanDigits),
        ),
      );
    } else {
      setState(() => _errorMessage = result['message'] as String?);
    }
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppDimensions.space8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceDark,
            prefixIcon: Icon(icon, color: AppColors.primary),
            prefixText: prefixText,
            prefixStyle: const TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600),
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMutedDark),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: AppColors.textSecondaryDark,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(color: AppColors.borderDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(color: AppColors.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.space16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Captain Registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: AppDimensions.space16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.signupTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppDimensions.space6),
              const Text(
                AppStrings.signupSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(height: AppDimensions.space20),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: AppDimensions.space8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),
              ],

              _buildTextField(
                label: AppStrings.fullName,
                hint: 'e.g. Ramesh Reddy',
                controller: _nameController,
                icon: Icons.person_rounded,
              ),

              _buildTextField(
                label: AppStrings.phoneNumber,
                hint: '10-digit mobile number',
                controller: _phoneController,
                icon: Icons.phone_iphone_rounded,
                keyboardType: TextInputType.phone,
                prefixText: '+91 ',
              ),

              _buildTextField(
                label: AppStrings.email,
                hint: 'e.g. ramesh@quickride.com',
                controller: _emailController,
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),

              _buildTextField(
                label: AppStrings.password,
                hint: 'At least 6 characters',
                controller: _passwordController,
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                obscureText: _obscurePass,
                onToggleObscure: () => setState(() => _obscurePass = !_obscurePass),
              ),

              _buildTextField(
                label: AppStrings.confirmPassword,
                hint: 'Re-enter your password',
                controller: _confirmPasswordController,
                icon: Icons.lock_reset_rounded,
                isPassword: true,
                obscureText: _obscureConfirm,
                onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),

              _buildTextField(
                label: AppStrings.vehicleNumber,
                hint: 'e.g. KA-01-AB-1234',
                controller: _vehicleNumberController,
                icon: Icons.two_wheeler_rounded,
              ),

              _buildTextField(
                label: AppStrings.licenseNumber,
                hint: 'e.g. DL-0420110012345',
                controller: _licenseNumberController,
                icon: Icons.badge_rounded,
              ),

              const SizedBox(height: AppDimensions.space8),

              PrimaryButton(
                text: AppStrings.createAccountButton,
                onPressed: _handleCreateAccount,
                isLoading: _isLoading,
                icon: Icons.how_to_reg_rounded,
              ),

              const SizedBox(height: AppDimensions.space20),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      AppStrings.backToLoginPrompt,
                      style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        AppStrings.backToLogin,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space24),
            ],
          ),
        ),
      ),
    );
  }
}
