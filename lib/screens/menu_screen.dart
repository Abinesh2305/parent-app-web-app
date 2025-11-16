import 'package:flutter/material.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';
import '../main.dart';
import '../main.dart' show MainNavigationScreen;
import '../screens/exam_screen.dart';
import '../screens/leave_screen.dart';
import '../screens/profile_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final List<Map<String, dynamic>> menuItems = [
      {'icon': Icons.person_outline, 'label': t.profile},
      {'icon': Icons.campaign_outlined, 'label': t.announcements},
      {'icon': Icons.calendar_today_outlined, 'label': t.leaveManagement},
      {'icon': Icons.fact_check_outlined, 'label': t.exams},
      {'icon': Icons.currency_rupee, 'label': t.fees},
      {'icon': Icons.book_outlined, 'label': t.homework},
      {'icon': Icons.how_to_reg_outlined, 'label': t.attendance},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.menuTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.78, // more height
          ),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final item = menuItems[index];

            return _buildMenuItem(
              icon: item['icon'],
              label: item['label'],
              colorScheme: cs,
              onTap: () {
                switch (item['label']) {
                  case var label when label == t.profile:
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                    break;

                  case var label when label == t.announcements:
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

                  case var label when label == t.leaveManagement:
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LeaveScreen(),
                      ),
                    );
                    break;

                  case var label when label == t.exams:
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ExamScreen(),
                      ),
                    );
                    break;

                  case var label when label == t.fees:
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

                  case var label when label == t.homework:
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

                  case var label when label == t.attendance:
                    navigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => MainNavigationScreen(
                          onToggleTheme: () {},
                          onToggleLanguage: () {},
                          openAttendanceTab: true,
                        ),
                      ),
                      (route) => false,
                    );
                    break;

                  default:
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(item['label'])),
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

              // WRAP text fully (NO overflow, NO ellipsis)
              SizedBox(
                width: double.infinity, // allows full wrapping
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
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
