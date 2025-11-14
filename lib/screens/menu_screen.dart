import 'package:flutter/material.dart';
import '../main.dart';
import '../main.dart' show MainNavigationScreen;
import '../screens/exam_screen.dart';
import '../screens/leave_screen.dart';
import '../screens/profile_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  static const List<Map<String, dynamic>> menuItems = [
    {'icon': Icons.person_outline, 'label': 'Profile'},
    {'icon': Icons.campaign_outlined, 'label': 'Announcements'},
    {'icon': Icons.calendar_today_outlined, 'label': 'Leave Management'},
    {'icon': Icons.fact_check_outlined, 'label': 'Exams'},
    {'icon': Icons.currency_rupee, 'label': 'Fees'},
    {'icon': Icons.book_outlined, 'label': 'Homework'},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return _buildMenuItem(
              icon: item['icon'],
              label: item['label'],
              colorScheme: colorScheme,
              onTap: () {
                switch (item['label']) {
                  case 'Profile':
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                    break;

                  case 'Announcements':
                    navigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => MainNavigationScreen(
                          onToggleTheme: () {},
                          onToggleLanguage: () {},
                          openNotificationTab: true,
                        ),
                      ),
                      (route) => false,
                    );
                    break;

                  case 'Leave Management':
                    navigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => MainNavigationScreen(
                          onToggleTheme: () {},
                          onToggleLanguage: () {},
                          openLeaveTab: true,
                        ),
                      ),
                      (route) => false,
                    );
                    break;

                  case 'Exams':
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ExamScreen(),
                      ),
                    );
                    break;

                  case 'Fees':
                    navigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => MainNavigationScreen(
                          onToggleTheme: () {},
                          onToggleLanguage: () {},
                          openFeesTab: true,
                        ),
                      ),
                      (route) => false,
                    );
                    break;

                  case 'Homework':
                    navigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => MainNavigationScreen(
                          onToggleTheme: () {},
                          onToggleLanguage: () {},
                          openHomeworkTab: true,
                        ),
                      ),
                      (route) => false,
                    );
                    break;

                  default:
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item['label']} tapped')),
                    );
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
