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
import 'services/force_update_service.dart';
import 'dart:convert';

// Global navigator key for navigation even when app is not in foreground
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background FCM handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final box = await Hive.openBox('settings');
  // box.put('pending_fcm', message.data); // store only data
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Hive.openBox('settings');

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Local notification setup
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

  var box = Hive.box('settings');
  String savedTheme = box.get('themeMode', defaultValue: 'system');
  String savedLanguage = box.get('language', defaultValue: 'en');

  runApp(MyApp(savedTheme: savedTheme, savedLanguage: savedLanguage));
}

/// Shared logic to switch user and open notification tab
Future<void> _handleUserAndNavigate(RemoteMessage? message) async {
  final box = Hive.box('settings');

  final targetUserId = message?.data['target_user_id'];
  final postId = message?.data['post_id'];

  // Switch account if required
  if (targetUserId != null) {
    final linkedUsers = box.get('linked_users', defaultValue: []);
    final mainUser = box.get('user');

    List<dynamic> allUsers = [];
    if (mainUser != null) allUsers.add(mainUser);
    allUsers.addAll(linkedUsers);

    // 1. Try to find user locally
    var targetUser = allUsers.firstWhere(
      (u) => u['id'].toString() == targetUserId.toString(),
      orElse: () => null,
    );

    // 2. If not found -> fetch from server
    if (targetUserId != null) {
      final linkedUsers = box.get('linked_users', defaultValue: []);
      final mainUser = box.get('user');

      List<dynamic> allUsers = [];
      if (mainUser != null) allUsers.add(mainUser);
      allUsers.addAll(linkedUsers);

      print("ALL USERS = ${allUsers.map((u) => u['id']).toList()}");
      print("TARGET USER = $targetUserId");

      var targetUser = allUsers.firstWhere(
        (u) => u['id'].toString() == targetUserId.toString(),
        orElse: () => null,
      );

      if (targetUser == null) {
        print("TARGET NOT FOUND. Cannot switch.");
      } else {
        await box.put('token', targetUser['api_token']);
        await box.put('user', targetUser);

        await navigatorKey.currentState?.context
            .findAncestorStateOfType<_MainNavigationScreenState>()
            ?.resetFcmSubscriptions();

        print("SWITCHED TO USER ${targetUser['id']}");
      }
    }

    // 3. If still null -> cannot switch
    if (targetUser != null) {
      await box.put('token', targetUser['api_token']);
      await box.put('user', targetUser);

      // Refresh FCM topics
      await navigatorKey.currentState?.context
          .findAncestorStateOfType<_MainNavigationScreenState>()
          ?.resetFcmSubscriptions();
    }
  }

  // Decide where to navigate
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
    return ThemeMode.light; // fallback, NEVER return system
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

    // update UI
    setState(() {
      _locale = Locale(newLang);
    });

    // save locally
    box.put('language', newLang);

    // update user in Hive
    final user = box.get('user');
    if (user != null) {
      user['language'] = newLang;
      box.put('user', user);
    }

    // update DB
    try {
      await DioClient.dio.post(
        'update-language',
        data: {
          'user_id': user?['id'],
          'language': newLang,
        },
      );
    } catch (_) {}

    // refresh entire app to apply new language
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (_) => LaunchDecider(
          onToggleTheme: _toggleTheme,
          onToggleLanguage: _toggleLanguage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'School Dashboard',
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
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ForceUpdateService.checkForUpdate(); // Trigger here only
    });
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('settings');
    return box.get('user') != null && box.get('token') != null
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

    // _checkPendingFCM();

    // ForceUpdateService.checkForUpdate(); // Google Force Update

    // _subscribeToAllScholarTopics();

    resetFcmSubscriptions();

    if (widget.openNotificationTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notificationClickHandler();
      });
    } else if (widget.openLeaveTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _leaveClickHandler();
      });
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

  // Future<void> _checkPendingFCM() async {
  //   final box = Hive.box('settings');
  //   final data = box.get('pending_fcm');

  //   if (data != null) {
  //     box.delete('pending_fcm');

  //     await _handleUserAndNavigate(
  //       RemoteMessage(data: Map<String, dynamic>.from(data)),
  //     );
  //   }
  // }

  Future<void> _checkInitialMessage() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final msg = await FirebaseMessaging.instance.getInitialMessage();
    if (msg != null) {
      await _handleNotificationClick(msg);
    }
  }

  Future<void> _handleNotificationClick(RemoteMessage message) async {
    await _handleUserAndNavigate(message);
  }

  Future<void> resetFcmSubscriptions() async {
    final fcm = FirebaseMessaging.instance;

    final box = Hive.box('settings');
    final mainUser = box.get('user');
    List<dynamic> linkedUsers = box.get('linked_users', defaultValue: []);

    final allUsers = <Map<String, dynamic>>[];
    if (mainUser != null) allUsers.add(mainUser);
    for (var u in linkedUsers) {
      if (u is Map<String, dynamic>) allUsers.add(u);
    }

    final uniqueUsers = {for (var u in allUsers) u['id']: u}.values.toList();

    // Unsubscribe everything first
    final schoolId = mainUser['school_college_id'];
    await fcm.unsubscribeFromTopic("School_Scholars_$schoolId");

    for (var u in uniqueUsers) {
      await fcm.unsubscribeFromTopic("Scholar_${u['id']}");
      await fcm
          .unsubscribeFromTopic("Section_${u['userdetails']['section_id']}");
      await fcm.unsubscribeFromTopic("Group_${u['userdetails']['group_code']}");
    }

    // Subscribe clean once
    if (schoolId != null) {
      await fcm.subscribeToTopic("School_Scholars_$schoolId");
    }

    for (var u in uniqueUsers) {
      await fcm.subscribeToTopic("Scholar_${u['id']}");
      await fcm.subscribeToTopic("Section_${u['userdetails']['section_id']}");
      await fcm.subscribeToTopic("Group_${u['userdetails']['group_code']}");
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
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _leaveClickHandler() {
    setState(() => _currentIndex = 6);
    _pageController.jumpToPage(6);
  }

  void _logoutUser() async {
    final box = Hive.box('settings');
    final user = box.get('user');
    final fcm = await FirebaseMessaging.instance.getToken();
    if (user == null) return;

    try {
      await DioClient.dio.post('logout', data: {
        'user_id': user['id'],
        'fcm_token': fcm ?? '',
        'device_id': 'device_001',
        'device_type': 'ANDROID',
      });
    } catch (e) {
      print("Logout error: $e");
    }

    box.clear();
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
    List<dynamic> scholars = box.get('linked_users', defaultValue: []);
    final currentUser = box.get('user');
    String? selectedUserId = currentUser?['id']?.toString();

    // Fetch from server if not cached
    if (scholars.isEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      scholars = await UserService().getMobileScholars();
      Navigator.pop(context); // close loading dialog

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
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
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

                    // List of Students
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: scholars.length,
                        itemBuilder: (context, index) {
                          final s = scholars[index];
                          final id = s['id']?.toString();
                          final isSelected = id == selectedUserId;
                          final profileImage = s['is_profile_image'] ??
                              "https://www.clasteqsms.com/multischool/public/image/default.png";

                          return RadioListTile<String>(
                            value: id ?? '',
                            groupValue: selectedUserId,
                            onChanged: (value) async {
                              if (value == null) return;

                              setDialogState(() {
                                selectedUserId = value;
                              });

                              // write token first, then user to avoid watcher race
                              await box.put('token', s['api_token']);
                              await box.put('user', s);

                              List<dynamic> linkedUsers =
                                  box.get('linked_users', defaultValue: []);
                              if (!linkedUsers.any((u) => u['id'] == s['id'])) {
                                linkedUsers.add(s);
                                await box.put('linked_users', linkedUsers);
                              }

                              Navigator.pop(dialogContext); // close dialog
                              setState(() {}); // refresh main UI

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text("Switched to ${s['name']}")),
                              );

                              resetFcmSubscriptions();
                            },
                            title: Text(s['name'] ?? "Unknown"),
                            subtitle: Text(
                              "Class: ${s['userdetails']['is_class_name'] ?? ''} • "
                              "Section: ${s['userdetails']['is_section_name'] ?? ''}",
                            ),
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

                    // Close button
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
          setState(() {
            _currentIndex = index;
          });
          _pageController.jumpToPage(index);
        },
      ),
      // index 0 (default)
      const HomeworkScreen(), // index 1
      const NotificationScreen(), // index 2
      MenuScreen(onLogout: _logoutUser), // index 3
      const AttendanceScreen(), // index 4
      const FeesScreen(), // index 5
      const LeaveScreen(), // 6
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
          language: Hive.box('settings').get('language', defaultValue: 'en'),
          onSwitch: _showUserSwitcher,
          onProfileTap: () => _onNavigate(0),
          // onLogout: _logoutUser,
          onTranslate: widget.onToggleLanguage,
          onToggleTheme: widget.onToggleTheme, // ADDED
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
        // floatingActionButton: FloatingActionButton(
        //   mini: true,
        //   onPressed: widget.onToggleTheme,
        //   child: Icon(
        //     Theme.of(context).brightness == Brightness.light
        //         ? Icons.dark_mode
        //         : Icons.light_mode,
        //   ),
        // ),
      ),
    );
  }

  Widget _placeholder(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80),
          const SizedBox(height: 12),
          Text(title),
        ],
      ),
    );
  }
}
