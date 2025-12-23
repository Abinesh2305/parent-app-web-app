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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (!Hive.isBoxOpen('settings')) {
      await Hive.openBox('settings');
    }

    settingsBox = Hive.box('settings');
    await _loadAttendance();

    settingsBox.watch(key: 'user').listen((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _loadAttendance();
    });
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime? _safeParse(String? v) {
    if (v == null || v.isEmpty) return null;
    try {
      return _normalize(DateTime.parse(v));
    } catch (_) {
      return null;
    }
  }

  /* ================= LOAD ATTENDANCE ================= */

  Future<void> _loadAttendance() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = settingsBox.get('user');
      final token = settingsBox.get('token');
      if (user == null || token == null) {
        setState(() => _isLoading = false);
        return;
      }

      final monthYear =
          "${_focusedDay.year}-${_focusedDay.month.toString().padLeft(2, '0')}";

      final data = await _attendanceService.getAttendance(monthYear);
      if (data == null) throw Exception();

      final Map<DateTime, String> status = {};
      final Map<DateTime, String> desc = {};

      for (final e in (data['approved_leave_details'] ?? [])) {
        final d = _safeParse(e['date']);
        if (d != null) {
          status[d] = 'Leave';
          if (e['reason'] != null) desc[d] = e['reason'];
        }
      }

      for (final e in (data['holidays'] ?? [])) {
        final d = _safeParse(e['holiday_date']);
        if (d != null) {
          status[d] ??= 'Holiday';
          if (e['holiday_description'] != null) {
            desc[d] ??= e['holiday_description'];
          }
        }
      }

      for (final v in (data['student_present_approved'] ?? [])) {
        final d = _safeParse(v.toString());
        if (d != null) status[d] ??= 'Present';
      }

      for (final v in (data['student_absents'] ?? [])) {
        final d = _safeParse(v.toString());
        if (d != null) status[d] ??= 'Absent';
      }

      if (!mounted) return;

      setState(() {
        _statusMap = status;
        _descriptionMap = desc;

        totalDays = data['noof_working_days'] ?? 0;
        absentDays = data['combined_absent_count'] ?? 0;
        presentDays = data['present_days'] ?? 0;
        leaveDays = data['student_leave_count'] ?? 0;
        attendancePercentage =
            double.tryParse(data['att_percentage'].toString()) ?? 0.0;

        _selectedDay ??= _focusedDay;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load attendance')),
      );
    }
  }

  /* ================= BUILD ================= */

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2030),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) =>
                  _selectedDay != null && isSameDay(d, _selectedDay),
              onDaySelected: (d, f) {
                setState(() {
                  _selectedDay = d;
                  _focusedDay = f;
                });
              },
              onPageChanged: (f) async {
                _focusedDay = f;
                await _loadAttendance();
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (c, d, _) => _cell(c, d),
                selectedBuilder: (c, d, _) => _cell(c, d, selected: true),
                todayBuilder: (c, d, _) => _cell(c, d, today: true),
              ),
            ),
            const SizedBox(height: 16),
            _summary(t),
            _selectedInfo(t),
          ],
        ),
      ),
    );
  }

  /* ================= CELL ================= */

  Widget _cell(BuildContext c, DateTime d,
      {bool selected = false, bool today = false}) {
    final status = _statusMap[_normalize(d)];

    Color bg = Colors.grey.shade300;
    if (status == 'Present') bg = Colors.green.shade300;
    if (status == 'Absent') bg = Colors.red.shade300;
    if (status == 'Leave') bg = Colors.orange.shade300;
    if (status == 'Holiday') bg = Colors.blue.shade300;

    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: selected
            ? Border.all(color: Theme.of(c).colorScheme.primary, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        "${d.day}",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  /* ================= SUMMARY ================= */

  Widget _summary(AppLocalizations t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _item(t.workingDays, totalDays),
            _item(t.present, presentDays),
            _item(t.absent, absentDays),
            _item(
                t.attendancePercentage,
                "${attendancePercentage.toStringAsFixed(1)}%"),
          ],
        ),
      ),
    );
  }

  Widget _item(String label, dynamic v) {
    return Column(
      children: [
        Text(v.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _selectedInfo(AppLocalizations t) {
    if (_selectedDay == null) return const SizedBox.shrink();

    final key = _normalize(_selectedDay!);
    final status = _statusMap[key];
    final desc = _descriptionMap[key];

    if (status != 'Leave' && status != 'Holiday') return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status!,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (desc != null) ...[
              const SizedBox(height: 8),
              Text(desc),
            ]
          ],
        ),
      ),
    );
  }
}
