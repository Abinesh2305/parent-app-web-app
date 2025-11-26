import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'forgot_password_screen.dart';
import 'change_password_screen.dart';
import 'package:school_dashboard/services/home_service.dart';

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
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool rememberMe = false;
  bool isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    emailController.text = box.get('saved_email', defaultValue: '');
    passwordController.text = box.get('saved_password', defaultValue: '');
    rememberMe = emailController.text.isNotEmpty;
  }

  void _login() async {
    final t = AppLocalizations.of(context)!;

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.emptyFieldError)),
      );
      return;
    }

    setState(() => isLoading = true);

    final response = await _authService.login(
      emailController.text,
      passwordController.text,
    );

    setState(() => isLoading = false);

    if (response['forcePasswordChange'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChangePasswordScreen(
            userId: response['userId'],
            apiToken: response['apiToken'],
          ),
        ),
      );
      return;
    }

    if (response['success']) {
      if (rememberMe) {
        var box = Hive.box('settings');
        box.put('saved_email', emailController.text);
        box.put('saved_password', passwordController.text);
      }

      // IMPORTANT: Sync topics + save topics_subscribed in DB
      await HomeService.syncHomeContents();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainNavigationScreen(
            onToggleTheme: widget.onToggleTheme,
            onToggleLanguage: widget.onToggleLanguage,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? t.loginFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/school_logo.jpeg',
                  height: 80,
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  t.signInTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  t.signInSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurface.withOpacity(0.6)),
                ),
                const SizedBox(height: 35),

                // Mobile field
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: t.mobileLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password field
                TextField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: t.passwordLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Remember me + Forgot password (now flexible)
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              Checkbox(
                                value: rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    rememberMe = value ?? false;
                                  });
                                },
                              ),
                              Flexible(
                                child: Text(
                                  t.rememberMe,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen()),
                              );
                            },
                            child: Text(t.forgotPassword),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 30),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : Text(
                            t.nextButton,
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
