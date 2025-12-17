import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'widgets/top_nav_bar.dart';
import 'widgets/bottom_nav_bar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/dio_client.dart';
import 'services/user_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';
import 'screens/notification_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/homework_screen.dart';
import 'screens/fees_screen.dart';
import 'screens/leave_screen.dart';
import 'dart:convert';
import 'package:in_app_update/in_app_update.dart';
import 'package:school_dashboard/services/fcm_helper.dart';
import 'package:school_dashboard/services/home_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Global navigator key for navigation even when app is not in foreground
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background FCM handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await Hive.openBox('settings');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();

  await Future.wait([
    Hive.openBox('settings'),
    Hive.openBox('pending_reads'),
    Hive.openBox('pending_reads_homework'),
  ]);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  const androidSettings =
      AndroidInitializationSettings('@drawable/notification_icon');

  const initSettings = InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload != null) {
        final data = jsonDecode(response.payload!);
        final fakeMessage =
            RemoteMessage(data: Map<String, dynamic>.from(data));
        await _handleUserAndNavigate(fakeMessage);
      }
    },
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final box = Hive.box('settings');
  String savedTheme = box.get('themeMode', defaultValue: 'system');
  String savedLanguage = box.get('language', defaultValue: 'en');

  runApp(SplashWrapper(
    savedTheme: savedTheme,
    savedLanguage: savedLanguage,
  ));
}

/// Shared logic to switch user and open notification tab
Future<void> _handleUserAndNavigate(RemoteMessage? message) async {
  final box = Hive.box('settings');

  final targetUserId = message?.data['target_user_id'];

  if (targetUserId != null) {
    final linkedUsers = box.get('linked_users', defaultValue: []);
    final mainUser = box.get('user');

    List allUsers = [];
    if (mainUser != null) allUsers.add(mainUser);
    allUsers.addAll(linkedUsers);

    var targetUser = allUsers.firstWhere(
      (u) => u['id'].toString() == targetUserId.toString(),
      orElse: () => null,
    );

    if (targetUser != null) {
      await box.put('token', targetUser['api_token']);
      await box.put('user', targetUser);

      await navigatorKey.currentState?.context
          .findAncestorStateOfType<_MainNavigationScreenState>()
          ?.resetFcmSubscriptions();
    }
  }

  bool openHomework = false;
  bool openNotification = false;

  final msgType = message?.data['type']?.toString();
  final navigate = message?.data['navigate']?.toString();

  if (msgType == "5" || navigate == "homework") {
    openHomework = true;
  } else {
    openNotification = true;
  }

  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => MainNavigationScreen(
        onToggleTheme: () {},
        onToggleLanguage: () {},
        openHomeworkTab: openHomework,
        openNotificationTab: openNotification,
      ),
    ),
    (route) => false,
  );
}

class SplashWrapper extends StatelessWidget {
  final String savedTheme;
  final String savedLanguage;

  const SplashWrapper({
    super.key,
    required this.savedTheme,
    required this.savedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return MyApp(
      savedTheme: savedTheme,
      savedLanguage: savedLanguage,
    );
  }
}

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
    _themeMode = _getThemeFromHive(widget.savedTheme);
    _locale = Locale(widget.savedLanguage);
  }

  ThemeMode _getThemeFromHive(String theme) {
    if (theme == 'light') return ThemeMode.light;
    if (theme == 'dark') return ThemeMode.dark;
    return ThemeMode.light;
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    Hive.box('settings').put('themeMode', mode.name);
  }

  void _toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _setThemeMode(ThemeMode.dark);
    } else {
      _setThemeMode(ThemeMode.light);
    }
  }

  void _toggleLanguage() async {
    final box = Hive.box('settings');
    String current = box.get('language', defaultValue: 'en');
    String newLang = current == 'en' ? 'ta' : 'en';

    setState(() => _locale = Locale(newLang));
    box.put('language', newLang);

    final user = box.get('user');
    if (user != null) {
      user['language'] = newLang;
      box.put('user', user);
    }

    try {
      await DioClient.dio.post(
        'update-language',
        data: {'user_id': user?['id'], 'language': newLang},
      );
    } catch (_) {}

    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (_) => LaunchDecider(
            onToggleTheme: _toggleTheme, onToggleLanguage: _toggleLanguage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: dotenv.env['APP_NAME'] ?? 'School Parent App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      locale: _locale,
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

class LaunchDecider extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  const LaunchDecider({
    super.key,
    required this.onToggleTheme,
    required this.onToggleLanguage,
  });

  @override
  State<LaunchDecider> createState() => _LaunchDeciderState();
}

class _LaunchDeciderState extends State<LaunchDecider> {
  bool waitingForUpdate = true;

  @override
  void initState() {
    super.initState();
    _handleVersionReset();
    final box = Hive.box('settings');
    final alreadyRequested = box.get('updateRequested', defaultValue: false);

    if (!alreadyRequested) {
      _checkGoogleUpdate();
    } else {
      setState(() => waitingForUpdate = false);
    }
  }

  Future<void> _handleVersionReset() async {
    final box = Hive.box('settings');
    final storedVersion = box.get('lastVersion', defaultValue: '0');

    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    if (currentVersion != storedVersion) {
      await box.put('updateRequested', false);
      await box.put('lastVersion', currentVersion);
    }
  }

  Future<void> _checkGoogleUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.immediateUpdateAllowed) {
        final box = Hive.box('settings');
        await box.put('updateRequested', true);

        final result = await InAppUpdate.performImmediateUpdate();

        if (result == AppUpdateResult.success) {
          setState(() => waitingForUpdate = false);
        }
      } else {
        setState(() => waitingForUpdate = false);
      }
    } catch (_) {
      setState(() => waitingForUpdate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (waitingForUpdate) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final box = Hive.box('settings');

    return box.get('user') != null
        ? MainNavigationScreen(
            onToggleTheme: widget.onToggleTheme,
            onToggleLanguage: widget.onToggleLanguage,
          )
        : LoginScreen(
            onToggleTheme: widget.onToggleTheme,
            onToggleLanguage: widget.onToggleLanguage,
          );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;
  final bool openNotificationTab;
  final bool openLeaveTab;
  final bool openFeesTab;
  final bool openHomeworkTab;
  final bool openAttendanceTab;

  const MainNavigationScreen({
    super.key,
    required this.onToggleTheme,
    required this.onToggleLanguage,
    this.openNotificationTab = false,
    this.openLeaveTab = false,
    this.openFeesTab = false,
    this.openHomeworkTab = false,
    this.openAttendanceTab = false,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentIndex = 0;
  DateTime? _lastPressedTime;

  @override
  void initState() {
    super.initState();

    resetFcmSubscriptions();

    if (widget.openNotificationTab) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _notificationClickHandler());
    } else if (widget.openLeaveTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _leaveClickHandler());
    } else if (widget.openFeesTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _currentIndex = 5);
        _pageController.jumpToPage(5);
      });
    } else if (widget.openHomeworkTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _currentIndex = 1);
        _pageController.jumpToPage(1);
      });
    } else if (widget.openAttendanceTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _currentIndex = 4);
        _pageController.jumpToPage(4);
      });
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final senderName = message.data['sender_name'] ?? '';
      final title = message.data['title'] ?? 'Notification';
      final body = message.data['body'] ?? '';
      final displayTitle =
          senderName.isNotEmpty ? "$senderName – $title" : title;

      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@drawable/notification_icon',
      );

      const platformDetails = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        0,
        displayTitle,
        body,
        platformDetails,
        payload: jsonEncode(message.data),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);
    _checkInitialMessage();
  }

  Future<void> _checkInitialMessage() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final msg = await FirebaseMessaging.instance.getInitialMessage();
    if (msg != null) await _handleNotificationClick(msg);
  }

  Future<void> _handleNotificationClick(RemoteMessage message) async {
    await _handleUserAndNavigate(message);
  }

  Future<void> resetFcmSubscriptions() async {
    final box = Hive.box('settings');
    final mainUser = box.get('user');
    final linkedUsers = box.get('linked_users', defaultValue: []);

    if (mainUser == null) return;

    final schoolId = mainUser['school_college_id'];

    final users = <Map<String, dynamic>>[];
    users.add(Map<String, dynamic>.from(mainUser));
    for (var u in linkedUsers) {
      if (u is Map) users.add(Map<String, dynamic>.from(u));
    }

    final uniqueUsers = {for (var u in users) u['id']: u}.values.toList();

    await FirebaseMessaging.instance
        .unsubscribeFromTopic("School_Scholars_$schoolId");

    for (var u in uniqueUsers) {
      final uid = u['id'];
      final details = (u['userdetails'] ?? {}) as Map;

      final sectionId = details['section_id'] ??
          details['is_section_id'] ??
          details['is_section_name'] ??
          0;

      await FirebaseMessaging.instance.unsubscribeFromTopic("Scholar_$uid");
      await FirebaseMessaging.instance
          .unsubscribeFromTopic("Section_$sectionId");

      final groups = u['groups'] ?? [];
      for (var g in groups) {
        final gid = g['id'];
        if (gid != null) {
          await FirebaseMessaging.instance.unsubscribeFromTopic("Group_$gid");
        }
      }
    }

    await safeSubscribe("School_Scholars_$schoolId");

    for (var u in uniqueUsers) {
      final uid = u['id'];
      final details = (u['userdetails'] ?? {}) as Map;

      final sectionId = details['section_id'] ??
          details['is_section_id'] ??
          details['is_section_name'] ??
          0;

      await safeSubscribe("Scholar_$uid");
      await safeSubscribe("Section_$sectionId");

      final groups = u['groups'] ?? [];
      for (var g in groups) {
        final gid = g['id'];
        if (gid != null) await safeSubscribe("Group_$gid");
      }
    }
  }

  void _notificationClickHandler() {
    setState(() => _currentIndex = 2);
    _pageController.jumpToPage(2);
  }

  void _feesClickHandler() {
    setState(() => _currentIndex = 5);
    _pageController.jumpToPage(5);
  }

  void _homeworkClickHandler() {
    setState(() => _currentIndex = 1);
    _pageController.jumpToPage(1);
  }

  void _onNavigate(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _leaveClickHandler() {
    setState(() => _currentIndex = 6);
    _pageController.jumpToPage(6);
  }

  void _logoutUser() async {
    final box = Hive.box('settings');
    final firstLaunch = box.get('is_first_launch', defaultValue: false);

    final user = box.get('user');
    final fcm = await FirebaseMessaging.instance.getToken();
    if (user != null) {
      try {
        await DioClient.dio.post('logout', data: {
          'user_id': user['id'],
          'fcm_token': fcm ?? '',
          'device_id': 'device_001',
          'device_type': 'ANDROID',
        });
      } catch (_) {}
    }

    await box.clear();
    await box.put('is_first_launch', firstLaunch);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          onToggleTheme: widget.onToggleTheme,
          onToggleLanguage: widget.onToggleLanguage,
        ),
      ),
      (route) => false,
    );
  }

  void _showUserSwitcher() async {
    final box = Hive.box('settings');
    List scholars = box.get('linked_users', defaultValue: []);
    final currentUser = box.get('user');
    String? selectedUserId = currentUser?['id']?.toString();

    if (scholars.isEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      scholars = await UserService().getMobileScholars();
      Navigator.pop(context);

      if (scholars.isNotEmpty) {
        await box.put('linked_users', scholars);
      }
    }

    if (scholars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No linked accounts found')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      child: Text(
                        'Switch Student',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: scholars.length,
                        itemBuilder: (context, index) {
                          final s = scholars[index];
                          final id = s['id']?.toString();
                          final profileImage = s['is_profile_image'] ??
                              "https://www.clasteqsms.com/multischool/public/image/default.png";

                          return RadioListTile<String>(
                            value: id ?? '',
                            groupValue: selectedUserId,
                            onChanged: (value) async {
                              if (value == null) return;

                              setDialogState(() => selectedUserId = value);

                              await box.put('token', s['api_token']);
                              await box.put('user', s);

                              List linkedUsers =
                                  box.get('linked_users', defaultValue: []);
                              if (!linkedUsers.any((u) => u['id'] == s['id'])) {
                                linkedUsers.add(s);
                                await box.put('linked_users', linkedUsers);
                              }

                              Navigator.pop(dialogContext);
                              setState(() {});

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text("Switched to ${s['name']}")),
                              );

                              resetFcmSubscriptions();
                              HomeService.syncHomeContents();
                            },
                            title: Text(s['name'] ?? "Unknown"),
                            subtitle: Text(
                                "Class: ${s['userdetails']['is_class_name'] ?? ''} • Section: ${s['userdetails']['is_section_name'] ?? ''}"),
                            secondary: CircleAvatar(
                              radius: 22,
                              backgroundImage: NetworkImage(profileImage),
                              backgroundColor: Colors.grey.shade300,
                            ),
                            activeColor: Theme.of(context).colorScheme.primary,
                            controlAffinity: ListTileControlAffinity.trailing,
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text(
                          "Close",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('settings');
    final rawUser = box.get('user');
    final Map<String, dynamic>? user =
        rawUser != null ? Map<String, dynamic>.from(rawUser) : null;
    final studentName = user?['name'] ?? "Student";

    final screens = [
      HomeScreen(
        user: user,
        onTabChange: (index) {
          setState(() => _currentIndex = index);
          _pageController.jumpToPage(index);
        },
      ),
      const HomeworkScreen(),
      const NotificationScreen(),
      MenuScreen(onLogout: _logoutUser),
      const AttendanceScreen(),
      const FeesScreen(),
      const LeaveScreen(),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false;
        }
        final now = DateTime.now();
        if (_lastPressedTime == null ||
            now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
          _lastPressedTime = now;
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
          onSwitch: _showUserSwitcher,
          onProfileTap: () => _onNavigate(0),
          onTranslate: widget.onToggleLanguage,
          onToggleTheme: widget.onToggleTheme,
        ),
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: screens,
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onNavigate,
        ),
      ),
    );
  }
}
