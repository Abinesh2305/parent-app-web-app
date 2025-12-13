import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 8), () async {
      if (!mounted) return;

      final box = Hive.box('settings');
      final user = box.get('user');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => user == null
              ? LoginScreen(
                  onToggleTheme: () {},
                  onToggleLanguage: () {},
                )
              : MainNavigationScreen(
                  onToggleTheme: () {},
                  onToggleLanguage: () {},
                ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image.asset(
          'assets/clasteq_loading.gif',
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
