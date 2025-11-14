import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';
import 'package:school_dashboard/services/attendance_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, String> _attendanceMap = {};
  List<Map<String, dynamic>> _leaveDetails = [];
  int totalDays = 0;
  int leaveDays = 0;
  int presentDays = 0;
  double attendancePercentage = 0.0;
  bool _isLoading = true;

  final AttendanceService _attendanceService = AttendanceService();
  late Box settingsBox;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      if (!Hive.isBoxOpen('settings')) {
        await Hive.openBox('settings');
      }

      settingsBox = Hive.box('settings');
      _loadAttendance();

      settingsBox.watch(key: 'user').listen((event) async {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) _loadAttendance();
      });
    });
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);

    try {
      final user = settingsBox.get('user');
      final token = settingsBox.get('token');

      if (user == null || token == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No active user found")),
        );
        return;
      }

      final monthYear =
          "${_focusedDay.year}-${_focusedDay.month.toString().padLeft(2, '0')}";
      final data = await _attendanceService.getAttendance(monthYear);

      if (data == null) {
        setState(() => _isLoading = false);
        return;
      }

      final presentDates = List<String>.from(data['student_present_approved']);
      final leaveDates = List<String>.from(data['student_leaves']);
      final holidays = List<Map<String, dynamic>>.from(data['holidays']);
      final leaveList =
          List<Map<String, dynamic>>.from(data['student_leaves_list']);

      final Map<DateTime, String> map = {};

      for (var date in presentDates) {
        map[DateTime.parse(date)] = 'Present';
      }
      for (var date in leaveDates) {
        map[DateTime.parse(date)] = 'Leave';
      }
      for (var h in holidays) {
        map[DateTime.parse(h['holiday_date'])] = 'Holiday';
      }

      final details = leaveList.map((item) {
        return {
          "date": item["leave_date"] ?? "",
          "reason": item["leave_reason"] ?? "-",
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _attendanceMap = map;
        _leaveDetails = details;
        totalDays = data['noof_working_days'] ?? 0;
        leaveDays = data['student_leaves_count'] ?? 0;
        presentDays = data['present_days'] ?? 0;
        attendancePercentage =
            double.tryParse(data['att_percentage'].toString()) ?? 0.0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load attendance: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final calendarLocale = localeCode == 'ta' ? 'ta_IN' : 'en_US';

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Color backgroundCard = isDark
        ? colorScheme.surfaceContainerHighest.withOpacity(0.4)
        : Colors.white;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CALENDAR
            Card(
              color: backgroundCard,
              elevation: 3,
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
              padding: const EdgeInsets.all(12),
              child: TableCalendar(
                locale: calendarLocale,
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: CalendarFormat.month,
                onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                },
                onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                  _isLoading = true;
                });
                _loadAttendance();
                },
                headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                leftChevronIcon:
                  Icon(Icons.chevron_left, color: colorScheme.primary),
                rightChevronIcon:
                  Icon(Icons.chevron_right, color: colorScheme.primary),
                ),
                // disable default selected/today decorations so our builders control visuals
                calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(color: Colors.transparent),
                todayDecoration: BoxDecoration(color: Colors.transparent),
                ),
                calendarBuilders: CalendarBuilders(
                // Default day builder that paints the status background
                defaultBuilder: (context, date, _) {
                  final dayKey = DateTime(date.year, date.month, date.day);
                  final status = _attendanceMap[dayKey];

                  Color? bgColor;
                  Color textColor = isDark ? Colors.white70 : Colors.black87;

                  switch (status) {
                  case 'Present':
                    bgColor = isDark
                      ? Colors.green.shade900.withOpacity(0.6)
                      : Colors.green.shade100;
                    textColor = isDark
                      ? Colors.greenAccent.shade100
                      : Colors.green.shade900;
                    break;
                  case 'Leave':
                    bgColor = isDark
                      ? Colors.orange.shade900.withOpacity(0.6)
                      : Colors.orange.shade100;
                    textColor = isDark
                      ? Colors.orangeAccent.shade100
                      : Colors.orange.shade900;
                    break;
                  case 'Holiday':
                    bgColor = isDark
                      ? Colors.blue.shade900.withOpacity(0.6)
                      : Colors.blue.shade100;
                    textColor = isDark
                      ? Colors.blueAccent.shade100
                      : Colors.blue.shade900;
                    break;
                  default:
                    bgColor = isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade300;
                    textColor = isDark ? Colors.white70 : Colors.black87;
                  }

                  return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${date.day}",
                    style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    ),
                  ),
                  );
                },
                // Selected day: show status background but add a visible ring (so the status color is not hidden)
                selectedBuilder: (context, date, _) {
                  final dayKey = DateTime(date.year, date.month, date.day);
                  final status = _attendanceMap[dayKey];

                  Color? bgColor;
                  Color textColor = isDark ? Colors.white70 : Colors.black87;

                  switch (status) {
                  case 'Present':
                    bgColor = isDark
                      ? Colors.green.shade900.withOpacity(0.6)
                      : Colors.green.shade100;
                    textColor = isDark
                      ? Colors.greenAccent.shade100
                      : Colors.green.shade900;
                    break;
                  case 'Leave':
                    bgColor = isDark
                      ? Colors.orange.shade900.withOpacity(0.6)
                      : Colors.orange.shade100;
                    textColor = isDark
                      ? Colors.orangeAccent.shade100
                      : Colors.orange.shade900;
                    break;
                  case 'Holiday':
                    bgColor = isDark
                      ? Colors.blue.shade900.withOpacity(0.6)
                      : Colors.blue.shade100;
                    textColor = isDark
                      ? Colors.blueAccent.shade100
                      : Colors.blue.shade900;
                    break;
                  default:
                    bgColor = isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade300;
                    textColor = isDark ? Colors.white70 : Colors.black87;
                  }

                  return Container(
                  margin: const EdgeInsets.all(4),
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                    // status colored circle (keeps status visible)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      ),
                    ),
                    // outer ring to indicate selection (uses primary color and is semi-transparent)
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.95),
                        width: 2.2,
                      ),
                      ),
                    ),
                    Text(
                      "${date.day}",
                      style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      ),
                    ),
                    ],
                  ),
                  );
                },
                // Today: ensure status color is visible and indicate "today" with a subtle dot/ring
                todayBuilder: (context, date, _) {
                  final dayKey = DateTime(date.year, date.month, date.day);
                  final status = _attendanceMap[dayKey];

                  Color? bgColor;
                  Color textColor = isDark ? Colors.white70 : Colors.black87;

                  switch (status) {
                  case 'Present':
                    bgColor = isDark
                      ? Colors.green.shade900.withOpacity(0.6)
                      : Colors.green.shade100;
                    textColor = isDark
                      ? Colors.greenAccent.shade100
                      : Colors.green.shade900;
                    break;
                  case 'Leave':
                    bgColor = isDark
                      ? Colors.orange.shade900.withOpacity(0.6)
                      : Colors.orange.shade100;
                    textColor = isDark
                      ? Colors.orangeAccent.shade100
                      : Colors.orange.shade900;
                    break;
                  case 'Holiday':
                    bgColor = isDark
                      ? Colors.blue.shade900.withOpacity(0.6)
                      : Colors.blue.shade100;
                    textColor = isDark
                      ? Colors.blueAccent.shade100
                      : Colors.blue.shade900;
                    break;
                  default:
                    bgColor = isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade300;
                    textColor = isDark ? Colors.white70 : Colors.black87;
                  }

                  return Container(
                  margin: const EdgeInsets.all(4),
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                    // status colored circle
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      ),
                    ),
                    // subtle inner dot indicating today (so it doesn't cover status)
                    Positioned(
                      bottom: 6,
                      child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      ),
                    ),
                    Text(
                      "${date.day}",
                      style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      ),
                    ),
                    ],
                  ),
                  );
                },
                ),
              ),
              ),
            ),

            // LEGEND (localized)
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(
                  color: isDark
                      ? Colors.green.shade900.withOpacity(0.6)
                      : Colors.green.shade100,
                  label: t.present,
                  textColor: isDark
                      ? Colors.greenAccent.shade100
                      : Colors.green.shade900,
                ),
                _buildLegendItem(
                  color: isDark
                      ? Colors.orange.shade900.withOpacity(0.6)
                      : Colors.orange.shade100,
                  label: t.absent,
                  textColor: isDark
                      ? Colors.orangeAccent.shade100
                      : Colors.orange.shade900,
                ),
                _buildLegendItem(
                  color: isDark
                      ? Colors.blue.shade900.withOpacity(0.6)
                      : Colors.blue.shade100,
                  label: t.holiday,
                  textColor: isDark
                      ? Colors.blueAccent.shade100
                      : Colors.blue.shade900,
                ),
                _buildLegendItem(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  label: t.leave,
                  textColor: isDark ? Colors.white70 : Colors.black87,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // LEAVE DETAILS
            // Text(
            //   t.leaveDetails,
            //   style: TextStyle(
            //     fontSize: 16,
            //     fontWeight: FontWeight.bold,
            //     color: colorScheme.onSurface,
            //   ),
            // ),
            // const SizedBox(height: 8),
            // Card(
            //   color: backgroundCard,
            //   elevation: 2,
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   child: DataTable(
            //     headingRowColor: MaterialStateProperty.all(
            //         colorScheme.primary.withOpacity(0.1)),
            //     dataTextStyle: TextStyle(color: colorScheme.onSurface),
            //     columns: [
            //       DataColumn(label: Text(t.dateLabel)),
            //       DataColumn(label: Text(t.reasonLabel)),
            //     ],
            //     rows: _leaveDetails
            //         .map(
            //           (item) => DataRow(
            //             cells: [
            //               DataCell(Text(item["date"] ?? "")),
            //               DataCell(Text(item["reason"] ?? "")),
            //             ],
            //           ),
            //         )
            //         .toList(),
            //   ),
            // ),

            const SizedBox(height: 24),

            // SUMMARY
            Text(
              t.summary,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: backgroundCard,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                        t.workingDays, totalDays.toString(), Colors.blue),
                    _buildSummaryItem(
                        t.leaves, leaveDays.toString(), Colors.orange),
                    _buildSummaryItem(
                        t.attendancePercentage,
                        "${attendancePercentage.toStringAsFixed(1)}%",
                        Colors.green),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required Color textColor,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
