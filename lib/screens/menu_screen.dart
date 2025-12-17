import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';

import '../main.dart';
import '../screens/profile_screen.dart';
import '../screens/exam_screen.dart';
import '../screens/leave_screen.dart';
import '../screens/survey_screen.dart';
import '../screens/gallery_screen.dart';
import '../screens/rewards_screen.dart';
import '../screens/contacts_screen.dart';
import '../screens/placeholder_screen.dart';
import '../screens/sms/sms_communications_screen.dart';
import 'upload_document_screen.dart';
import '../screens/download_document_screen.dart';

class MenuScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const MenuScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isTamil = Localizations.localeOf(context).languageCode == 'ta';

    final List<Map<String, dynamic>> menuItems = [
      {'icon': Icons.person_outline, 'label': t.profile, 'action': 'profile'},
      {'icon': Icons.notifications_none, 'label': t.notifications, 'action': 'notifications'},
      {'icon': Icons.calendar_today_outlined, 'label': t.leaveManagement, 'action': 'leave'},
      {'icon': Icons.fact_check_outlined, 'label': t.exams, 'action': 'exams'},
      {'icon': Icons.currency_rupee, 'label': t.fees, 'action': 'fees'},
      {'icon': Icons.book_outlined, 'label': t.homework, 'action': 'homework'},
      {'icon': Icons.sms_outlined, 'label': t.sms, 'action': 'sms'},
      {'icon': Icons.calendar_month, 'label': t.attendance, 'action': 'attendance'},
      {'icon': Icons.poll_outlined, 'label': t.survey, 'action': 'survey'},
      {'icon': Icons.photo_library_outlined, 'label': t.gallery, 'action': 'gallery'},
      {'icon': Icons.workspace_premium_outlined, 'label': t.rewarsRemarkmenu, 'action': 'rewards'},
      {'icon': Icons.event_note_outlined, 'label': t.events, 'action': 'events'},
      {'icon': Icons.contact_phone_outlined, 'label': t.schoolContacts, 'action': 'contacts'},
      {'icon': Icons.upload_file, 'label': t.documents, 'action': 'upload_documents'},
      //{'icon': Icons.download, 'label': t.downloaddocuments, 'action': 'download_documents'},
    ];

    return Scaffold(
      appBar: AppBar(title: Text(t.menuTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: menuItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isTamil ? 0.63 : 0.85,
          ),
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return _buildMenuItem(
              icon: item['icon'],
              label: item['label'],
              colorScheme: cs,
              isTamil: isTamil,
              onTap: () => _handleMenuAction(context, item['action']),
            );
          },
        ),
      ),
    );
  }

  /* ================= MENU ACTION HANDLER ================= */

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'profile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(onLogout: onLogout),
          ),
        );
        break;

      case 'notifications':
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MainNavigationScreen(
              onToggleTheme: () {},
              onToggleLanguage: () {},
              openNotificationTab: true,
            ),
          ),
          (_) => false,
        );
        break;

      case 'leave':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveScreen()));
        break;

      case 'exams':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamScreen()));
        break;

      case 'fees':
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MainNavigationScreen(
              onToggleTheme: () {},
              onToggleLanguage: () {},
              openFeesTab: true,
            ),
          ),
          (_) => false,
        );
        break;

      case 'homework':
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MainNavigationScreen(
              onToggleTheme: () {},
              onToggleLanguage: () {},
              openHomeworkTab: true,
            ),
          ),
          (_) => false,
        );
        break;

      case 'attendance':
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MainNavigationScreen(
              onToggleTheme: () {},
              onToggleLanguage: () {},
              openAttendanceTab: true,
            ),
          ),
          (_) => false,
        );
        break;

      case 'survey':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SurveyScreen()));
        break;

      case 'gallery':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const GalleryScreen()));
        break;

      case 'rewards':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen()));
        break;

      case 'events':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'Events')),
        );
        break;

      case 'contacts':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen()));
        break;

      case 'sms':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SmsCommunicationsScreen()),
        );
        break;

      case 'upload_documents':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UploadDocumentScreen()),
        );
        break;

      case 'download_documents':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DownloadDocumentScreen()),
        );
        break;
    }
  }

  /* ================= MENU TILE ================= */

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
    required bool isTamil,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              AutoSizeText(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                minFontSize: isTamil ? 9 : 11,
                maxFontSize: isTamil ? 12 : 14,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
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
