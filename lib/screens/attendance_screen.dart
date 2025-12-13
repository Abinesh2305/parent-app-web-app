import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
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
  DateTime? _selectedDay = DateTime.now();

  Map<DateTime, String> _statusMap = {};
  Map<DateTime, String> _descriptionMap = {};

  int totalDays = 0;
  int absentDays = 0;
  int leaveDays = 0;
  int presentDays = 0;

  double attendancePercentage = 0.0;

  bool _isLoading = true;

  final AttendanceService _attendanceService = AttendanceService();
  late Box settingsBox;

  // -------------------------------------------------------------
  // 🔥 UNIVERSAL INTERNET CHECK ADDED HERE
  // -------------------------------------------------------------
  Future<bool> _checkInternet(BuildContext context) async {
    try {
      final result = await InternetAddress.lookup("google.com")
          .timeout(const Duration(seconds: 3));

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Your internet is slow, please try again."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }
  // -------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      if (!Hive.isBoxOpen('settings')) {
        await Hive.openBox('settings');
      }

      settingsBox = Hive.box('settings');

      /// 🔥 CHECK INTERNET BEFORE LOADING DATA
      if (await _checkInternet(context)) {
        await _loadAttendance();
      } else {
        setState(() => _isLoading = false);
      }

      settingsBox.watch(key: 'user').listen((event) async {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          if (await _checkInternet(context)) {
            _loadAttendance();
          }
        }
      });
    });
  }

  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime? _parseDateSafe(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return _normalizeDate(DateTime.parse(value));
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);

    try {
      final user = settingsBox.get('user');
      final token = settingsBox.get('token');

      if (user == null || token == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 🔥 CHECK INTERNET BEFORE API CALL
      if (!await _checkInternet(context)) {
        setState(() => _isLoading = false);
        return;
      }

      final monthYear =
          "${_focusedDay.year}-${_focusedDay.month.toString().padLeft(2, '0')}";

      final data = await _attendanceService.getAttendance(monthYear);

      if (data == null) {
        setState(() => _isLoading = false);
        return;
      }

      final presentDates =
          (data['student_present_approved'] as List?)?.cast<dynamic>() ??
              <dynamic>[];

      final absentDates =
          (data['student_absents'] as List?)?.cast<dynamic>() ?? <dynamic>[];

      final holidaysRaw =
          (data['holidays'] as List?)?.cast<dynamic>() ?? <dynamic>[];

      final approvedLeaveDetailsRaw =
          (data['approved_leave_details'] as List?)?.cast<dynamic>() ??
              <dynamic>[];

      final Map<DateTime, String> statusMap = {};
      final Map<DateTime, String> descMap = {};

      for (final item in approvedLeaveDetailsRaw) {
        if (item is! Map) continue;
        final d = _parseDateSafe(item['date']?.toString());
        if (d == null) continue;

        final reason = item['reason']?.toString() ?? '';
        statusMap[d] = 'Leave';
        if (reason.isNotEmpty) descMap[d] = reason;
      }

      for (final item in holidaysRaw) {
        if (item is! Map) continue;

        final d = _parseDateSafe(item['holiday_date']?.toString());
        if (d == null) continue;

        final desc = item['holiday_description']?.toString() ?? '';

        if (statusMap[d] != 'Leave') {
          statusMap[d] = 'Holiday';
          if (desc.isNotEmpty && !descMap.containsKey(d)) {
            descMap[d] = desc;
          }
        }
      }

      for (final v in presentDates) {
        final d = _parseDateSafe(v.toString());
        if (d == null) continue;
        statusMap[d] ??= 'Present';
      }

      for (final v in absentDates) {
        final d = _parseDateSafe(v.toString());
        if (d == null) continue;
        statusMap[d] ??= 'Absent';
      }

      final workingDays = data['noof_working_days'] ?? 0;
      final absCount = data['combined_absent_count'] ?? 0;
      final presCount = data['present_days'] ?? 0;
      final leaveCount = data['student_leave_count'] ?? 0;

      final attPct = double.tryParse(data['att_percentage'].toString()) ?? 0.0;

      if (!mounted) return;

      setState(() {
        _statusMap = statusMap;
        _descriptionMap = descMap;

        totalDays = workingDays;
        absentDays = absCount;
        presentDays = presCount;
        leaveDays = leaveCount;
        attendancePercentage = attPct;

        if (_selectedDay == null ||
            _selectedDay!.year != _focusedDay.year ||
            _selectedDay!.month != _focusedDay.month) {
          _selectedDay = _focusedDay;
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppLocalizations.of(context)!;

    final locale = Localizations.localeOf(context).languageCode;
    final calendarLocale = locale == 'ta' ? 'ta_IN' : 'en_US';

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final backgroundCard =
        isDark ? cs.surfaceContainerHighest.withOpacity(0.3) : Colors.white;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                  selectedDayPredicate: (day) =>
                      _selectedDay != null && isSameDay(_selectedDay, day),
                  calendarFormat: CalendarFormat.month,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },

                  // 🔥 CHECK INTERNET WHEN CHANGING MONTH
                  onPageChanged: (focusedDay) async {
                    setState(() {
                      _focusedDay = focusedDay;
                      _isLoading = true;
                    });

                    if (await _checkInternet(context)) {
                      _loadAttendance();
                    } else {
                      setState(() => _isLoading = false);
                    }
                  },

                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    leftChevronIcon:
                        Icon(Icons.chevron_left, color: cs.primary),
                    rightChevronIcon:
                        Icon(Icons.chevron_right, color: cs.primary),
                  ),
                  calendarStyle: const CalendarStyle(
                    selectedDecoration:
                        BoxDecoration(color: Colors.transparent),
                    todayDecoration: BoxDecoration(color: Colors.transparent),
                    outsideDaysVisible: false,
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, date, _) {
                      return _buildCalendarCell(context, date, isDark);
                    },
                    selectedBuilder: (context, date, _) {
                      return _buildCalendarCell(
                        context,
                        date,
                        isDark,
                        selected: true,
                      );
                    },
                    todayBuilder: (context, date, _) {
                      final isSelected =
                          _selectedDay != null && isSameDay(_selectedDay, date);
                      return _buildCalendarCell(
                        context,
                        date,
                        isDark,
                        selected: isSelected,
                        today: true,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _legendItem(
                  label: t.present,
                  color: Colors.green.shade300,
                  textColor: Colors.green.shade900,
                ),
                _legendItem(
                  label: t.absent,
                  color: Colors.red.shade300,
                  textColor: Colors.red.shade900,
                ),
                _legendItem(
                  label: t.leave,
                  color: Colors.orange.shade300,
                  textColor: Colors.orange.shade900,
                ),
                _legendItem(
                  label: t.holiday,
                  color: Colors.blue.shade300,
                  textColor: Colors.blue.shade900,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryCard(t, cs),
            _buildSelectedDayInfo(t, cs),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCell(
    BuildContext context,
    DateTime date,
    bool isDark, {
    bool selected = false,
    bool today = false,
  }) {
    final cs = Theme.of(context).colorScheme;

    final key = _normalizeDate(date);
    final status = _statusMap[key];

    Color bg;
    Color textColor;

    switch (status) {
      case "Present":
        bg = isDark ? Colors.green.shade900 : Colors.green.shade100;
        textColor = isDark ? Colors.green.shade200 : Colors.green.shade900;
        break;
      case "Absent":
        bg = isDark ? Colors.red.shade900 : Colors.red.shade100;
        textColor = isDark ? Colors.red.shade200 : Colors.red.shade900;
        break;
      case "Leave":
        bg = isDark ? Colors.orange.shade900 : Colors.orange.shade100;
        textColor = isDark ? Colors.orange.shade200 : Colors.orange.shade900;
        break;
      case "Holiday":
        bg = isDark ? Colors.blue.shade900 : Colors.blue.shade100;
        textColor = isDark ? Colors.blue.shade200 : Colors.blue.shade900;
        break;
      default:
        bg = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
        textColor = isDark ? Colors.white70 : Colors.black87;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (selected)
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.primary, width: 2),
              ),
            ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
          ),
          if (today)
            Positioned(
              bottom: 5,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white : cs.primary,
                ),
              ),
            ),
          Positioned(
            top: 8,
            child: Text(
              "${date.day}",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _legendItem({
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(AppLocalizations t, ColorScheme cs) {
    return Card(
      elevation: 3,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _summaryItem(
                t.workingDays, totalDays.toString(), Colors.blue.shade700),
            _summaryItem(t.absent, absentDays.toString(), Colors.red.shade700),
            _summaryItem(
                t.present, presentDays.toString(), Colors.green.shade700),
            Flexible(
              child: _summaryItem(
                t.attendancePercentage,
                "${attendancePercentage.toStringAsFixed(1)}%",
                Colors.teal.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDayInfo(AppLocalizations t, ColorScheme cs) {
    if (_selectedDay == null) return const SizedBox.shrink();

    final key = _normalizeDate(_selectedDay!);
    final status = _statusMap[key];
    final desc = _descriptionMap[key];

    if (status != "Leave" && status != "Holiday") {
      return const SizedBox.shrink();
    }

    final label = status == "Leave" ? t.leave : t.holiday;

    return Card(
      elevation: 3,
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ),
            if (desc != null && desc.isNotEmpty) ...[
              const SizedBox(height: 22),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "${t.reason}:",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  desc,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
