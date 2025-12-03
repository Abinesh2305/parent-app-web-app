import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';
import 'package:school_dashboard/services/attendance_service.dart';
import 'package:school_dashboard/screens/exam_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final void Function(int)? onTabChange;

  const HomeScreen({super.key, this.user, this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double attendancePercent = 0.0;
  String todayStatus = "";
  bool _loading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkUserAndReload();
  }

  void _checkUserAndReload() {
    final box = Hive.box('settings');
    final user = box.get('user');
    final newUserId = user?['id']?.toString();
    if (newUserId != _currentUserId) {
      _loadAttendanceData();
    }
  }

  Future<void> _loadAttendanceData() async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      if (user == null) return;

      final now = DateTime.now();
      final monthYear = "${now.year}-${now.month.toString().padLeft(2, '0')}";

      final data = await AttendanceService().getAttendance(monthYear);

      if (!mounted) return; // <-- IMPORTANT

      if (data != null) {
        final today = _formatDate(now);
        String status = '';

        if ((data['student_present_approved'] ?? []).contains(today)) {
          status = 'Present';
        } else if ((data['student_leaves'] ?? []).contains(today)) {
          status = 'Leave';
        } else if ((data['leave_days'] ?? []).contains(today)) {
          status = 'Holiday';
        } else if ((data['holidays'] ?? [])
            .any((h) => h['holiday_date'] == today)) {
          status = 'Holiday';
        } else {
          status = 'Absent';
        }

        if (!mounted) return;
        setState(() {
          todayStatus = status;
          attendancePercent =
              double.tryParse(data['att_percentage'].toString()) ?? 0.0;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final settingsBox = Hive.box('settings');
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder(
              valueListenable:
                  settingsBox.listenable(keys: ['user', 'pf_img_cb']),
              builder: (context, Box box, _) {
                final data = box.get('user', defaultValue: {}) as Map;
                final userDetails = data['userdetails'] ?? {};

                final String name = data['name']?.toString() ?? "Unknown";
                final String admissionNo =
                    data['admission_no']?.toString() ?? "N/A";
                final String mobile = data['mobile']?.toString() ?? "N/A";
                final String className =
                    userDetails['is_class_name']?.toString() ?? "N/A";
                final String section =
                    userDetails['is_section_name']?.toString() ?? "N/A";

                final int cb = box.get('pf_img_cb', defaultValue: 0) as int;

                final String rawImageUrl = (data['is_profile_image'] ??
                        "https://www.clasteqsms.com/multischool/public/image/default.png")
                    .toString();

                final String profileImage = "$rawImageUrl?cb=$cb";

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Card(
                        color: colorScheme.primary.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  profileImage,
                                  key: ValueKey(profileImage),
                                  width: 200,
                                  height: 250,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 200,
                                      height: 200,
                                      color:
                                          colorScheme.primary.withOpacity(0.2),
                                      child: Icon(
                                        Icons.person,
                                        size: 60,
                                        color: colorScheme.onSurface,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailItem(
                                        t.classLabel, className, colorScheme),
                                    const SizedBox(height: 8),
                                    _buildDetailItem(
                                        t.sectionLabel, section, colorScheme),
                                    const SizedBox(height: 8),
                                    _buildDetailItem(t.admissionNoLabel,
                                        admissionNo, colorScheme),
                                    const SizedBox(height: 8),
                                    _buildDetailItem(
                                        t.contactLabel, mobile, colorScheme),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        color: colorScheme.primary.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                t.attendanceTitle,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        t.todayStatus,
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(todayStatus),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _getStatusText(todayStatus, t),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        t.attendancePercentage,
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          "${attendancePercent.toStringAsFixed(1)}%",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMenuButton(
                        t.todayAlerts,
                        colorScheme,
                        onTap: () {
                          widget.onTabChange?.call(2);
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMenuButton(
                        t.exams,
                        colorScheme,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ExamScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMenuButton(
                        t.feeDetails,
                        colorScheme,
                        onTap: () {
                          widget.onTabChange?.call(5);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Absent':
        return Colors.orange;
      case 'Holiday':
        return Colors.blue;
      case 'Leave':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status, AppLocalizations t) {
    switch (status) {
      case 'Present':
        return t.present;
      case 'Absent':
        return t.leave;
      case 'Holiday':
        return t.holiday;
      case 'Leave':
        return t.absent;
      default:
        return '-';
    }
  }

  Widget _buildDetailItem(String label, String value, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton(
    String title,
    ColorScheme colorScheme, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
