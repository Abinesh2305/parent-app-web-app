import 'package:flutter/material.dart';
import 'package:school_dashboard/services/change_password_service.dart';
import '../main.dart';
import '../services/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

class ChangePasswordScreen extends StatefulWidget {
  final int userId;
  final String apiToken;

  const ChangePasswordScreen({
    super.key,
    required this.userId,
    required this.apiToken,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final ChangePasswordService _service = ChangePasswordService();

  bool isPasswordVisible = false;
  bool isConfirmVisible = false;
  bool isLoading = false;

  Future<void> _updatePassword() async {
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter all fields")));
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => isLoading = true);

    final response = await _service.changePassword(
      userId: widget.userId,
      apiToken: widget.apiToken,
      newPassword: newPass,
    );

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response['message'] ?? 'Something went wrong')),
    );

    if (response['status'] == 1) {
      final box = Hive.box('settings');

      // 1. Refresh user from backend
      final profileRes = await DioClient.dio.post(
        'profile_details',
        data: {
          'user_id': widget.userId,
          'api_token': widget.apiToken,
        },
        options: Options(headers: {'x-api-key': widget.apiToken}),
      );

      if (profileRes.data != null && profileRes.data['status'] == 1) {
        final userData = profileRes.data['data'];

        // 2. Save updated user + token in Hive
        await box.put('user', userData);
        await box.put('token', userData['api_token']);
      }

      // 3. Navigate cleanly to Home screen (as this correct user)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainNavigationScreen(
            onToggleTheme: () {},
            onToggleLanguage: () {},
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colors.onSurface,
        title: const Text(
          'Set New Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: colors.primary),
                const SizedBox(height: 24),
                Text(
                  "Create New Password",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Your app requires setting a new password for first-time login.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 36),
                TextField(
                  controller: newPasswordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "New Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: colors.surfaceContainerHighest.withOpacity(0.3),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.primary, width: 1.2),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: colors.onSurface.withOpacity(0.7),
                      ),
                      onPressed: () => setState(
                          () => isPasswordVisible = !isPasswordVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: !isConfirmVisible,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: colors.surfaceContainerHighest.withOpacity(0.3),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.primary, width: 1.2),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isConfirmVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: colors.onSurface.withOpacity(0.7),
                      ),
                      onPressed: () =>
                          setState(() => isConfirmVisible = !isConfirmVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Update Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Back",
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
