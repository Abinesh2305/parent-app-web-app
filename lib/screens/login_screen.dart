import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';

import '../services/auth_service.dart';
import '../main.dart';
import 'forgot_password_screen.dart';
import 'change_password_screen.dart';
import 'splash_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  const LoginScreen({
    super.key,
    required this.onToggleTheme,
    required this.onToggleLanguage,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');

    _emailController.text = box.get('saved_email', defaultValue: '');
    _passwordController.text = box.get('saved_password', defaultValue: '');
    _rememberMe = _emailController.text.isNotEmpty;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================= LOGIN =================

  Future<void> _login() async {
    final t = AppLocalizations.of(context)!;

    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnack(t.emptyFieldError);
      return;
    }

    setState(() => _isLoading = true);

    final response = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    // 🔹 Force password change
    if (response['forcePasswordChange'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangePasswordScreen(
            userId: response['userId'],
            apiToken: response['apiToken'],
          ),
        ),
      );
      return;
    }

    // 🔹 Login success
    if (response['success'] == true) {
      final box = Hive.box('settings');

      if (_rememberMe) {
        box.put('saved_email', _emailController.text);
        box.put('saved_password', _passwordController.text);
      } else {
        box.delete('saved_email');
        box.delete('saved_password');
      }

      final bool isFirstLaunch =
          box.get('is_first_launch', defaultValue: true);

      if (isFirstLaunch) {
        await box.put('is_first_launch', false);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainNavigationScreen(
              onToggleTheme: widget.onToggleTheme,
              onToggleLanguage: widget.onToggleLanguage,
            ),
          ),
        );
      }
      return;
    }

    // 🔹 Login failed (SAFE)
    final message = response is Map && response.containsKey('message')
        ? response['message'].toString()
        : t.loginFailed;

    _showSnack(message);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: colors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(28, 24, 28, bottomInset + 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              Image.asset('assets/school_logo.jpeg', height: 80),
              const SizedBox(height: 20),

              Text(
                t.signInTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                t.signInSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 35),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: t.mobileLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: t.passwordLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (v) =>
                        setState(() => _rememberMe = v ?? false),
                  ),
                  Expanded(
                    child: Text(
                      t.rememberMe,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(t.forgotPassword),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          t.nextButton,
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
