import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/homework_screen.dart';
import 'screens/fees_screen.dart';
import 'screens/leave_screen.dart';

import 'widgets/top_nav_bar.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/student_switch_dialog.dart';

import 'services/dio_client.dart';
import 'services/user_service.dart';

import 'navigation/navigation_scope.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/* ======================= MAIN ======================= */

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  await Hive.initFlutter();

  await Future.wait([
    Hive.openBox('settings'),
    Hive.openBox('pending_reads'),
    Hive.openBox('pending_reads_homework'),
  ]);

  final box = Hive.box('settings');

  runApp(
    MyApp(
      savedTheme: box.get('themeMode', defaultValue: 'light'),
      savedLanguage: box.get('language', defaultValue: 'en'),
    ),
  );
}

/* ======================= MOBILE FRAME ======================= */

class MobileFrame extends StatelessWidget {
  final Widget child;
  const MobileFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    const maxMobileWidth = 360.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: const Color(0xFFE5E5E5),
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxMobileWidth,
              minHeight: constraints.maxHeight,
            ),
            child: Material(
              elevation: 8,
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(child: child),
            ),
          ),
        );
      },
    );
  }
}

/* ======================= APP ROOT ======================= */

class MyApp extends StatefulWidget {
  final String savedTheme;
  final String savedLanguage;

  const MyApp({
    super.key,
    required this.savedTheme,
    required this.savedLanguage,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _themeMode =
        widget.savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    _locale = Locale(widget.savedLanguage);
  }

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    Hive.box('settings').put('themeMode', _themeMode.name);
  }

  void _toggleLanguage() async {
    final box = Hive.box('settings');
    final current = box.get('language', defaultValue: 'en');
    final newLang = current == 'en' ? 'ta' : 'en';

    setState(() => _locale = Locale(newLang));
    box.put('language', newLang);

    final rawUser = box.get('user');
    final user = rawUser is Map ? Map<String, dynamic>.from(rawUser) : null;

    if (user != null) {
      try {
        await DioClient.dio.post(
          'update-language',
          data: {
            'user_id': user['id'],
            'language': newLang,
          },
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: kIsWeb
          ? 'School Parent App'
          : dotenv.env['APP_NAME'] ?? 'School Parent App',

      theme: AppTheme.lightTheme.copyWith(
        visualDensity: VisualDensity.comfortable,
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        visualDensity: VisualDensity.comfortable,
      ),

      themeMode: _themeMode,
      locale: _locale,

      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: MobileFrame(child: child!),
        );
      },

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ta')],

      home: LaunchDecider(
        onToggleTheme: _toggleTheme,
        onToggleLanguage: _toggleLanguage,
      ),
    );
  }
}

/* ======================= LAUNCH DECIDER ======================= */

class LaunchDecider extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  const LaunchDecider({
    super.key,
    required this.onToggleTheme,
    required this.onToggleLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final rawUser = Hive.box('settings').get('user');
    final user = rawUser is Map ? Map<String, dynamic>.from(rawUser) : null;

    return user != null
        ? MainNavigationScreen(
            onToggleTheme: onToggleTheme,
            onToggleLanguage: onToggleLanguage,
          )
        : LoginScreen(
            onToggleTheme: onToggleTheme,
            onToggleLanguage: onToggleLanguage,
          );
  }
}

/* ======================= MAIN NAVIGATION ======================= */

class MainNavigationScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  const MainNavigationScreen({
    super.key,
    required this.onToggleTheme,
    required this.onToggleLanguage,
  });

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  DateTime? _lastPressed;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavigate(int index) {
    if (_currentIndex == index) return;

    setState(() => _currentIndex = index);

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _logout() async {
    await Hive.box('settings').clear();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          onToggleTheme: widget.onToggleTheme,
          onToggleLanguage: widget.onToggleLanguage,
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('settings');

    final rawUser = box.get('user');
    final user =
        rawUser is Map ? Map<String, dynamic>.from(rawUser) : null;

    final student = box.get('current_student');
    final studentName = student is Map ? student['name'] ?? 'Student' : 'Student';

    final screens = [
      HomeScreen(user: user, onTabChange: _onNavigate),
      const HomeworkScreen(),
      const NotificationScreen(),
      MenuScreen(onLogout: _logout),
      const AttendanceScreen(),
      const FeesScreen(),
      const LeaveScreen(),
    ];

    return NavigationScope(
      goToTab: _onNavigate,
      child: WillPopScope(
        onWillPop: () async {
          if (kIsWeb) return true;

          final now = DateTime.now();
          if (_lastPressed == null ||
              now.difference(_lastPressed!) >
                  const Duration(seconds: 2)) {
            _lastPressed = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Press back again to exit')),
            );
            return false;
          }
          return true;
        },
        child: Scaffold(
          appBar: TopNavBar(
            studentName: studentName,
            language: box.get('language', defaultValue: 'en'),
            onSwitch: () async {
              final users =
                  await UserService().getMobileScholars();
              if (!mounted) return;

              if (users.isNotEmpty) {
                showStudentSwitchDialog(
                  context: context,
                  students: users,
                  goHome: () => _onNavigate(0),
                );
              }
            },
            onProfileTap: () => _onNavigate(0),
            onTranslate: widget.onToggleLanguage,
            onToggleTheme: widget.onToggleTheme,
          ),
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: screens,
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onNavigate,
          ),
        ),
      ),
    );
  }
}
