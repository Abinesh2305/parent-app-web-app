import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';
import '../services/exam_service.dart';
import 'exam_result_screen.dart';

class ExamDetailScreen extends StatefulWidget {
  final int examId;
  final String examName;

  const ExamDetailScreen({
    super.key,
    required this.examId,
    required this.examName,
  });

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final service = ExamService();

  bool loading = true;
  List<dynamic> timetable = [];
  List<dynamic> examList = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    final tt = await service.getExamTimetable(widget.examId);
    final list = await service.getExamList();

    List<dynamic> ttList = [];
    if (tt != null && tt.isNotEmpty) {
      final first = tt.first;
      ttList = (first is Map && first["timetable"] is List)
          ? first["timetable"]
          : tt;
    }

    setState(() {
      timetable = ttList;
      examList = list ?? [];
      loading = false;
    });
  }

  String fmt(String? d) {
    if (d == null || d.isEmpty) return "-";
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examName),
        backgroundColor: cs.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: cs.onSurface),
        bottom: TabBar(
          controller: _tab,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurface.withOpacity(0.7),
          indicatorColor: cs.primary,
          tabs: [
            Tab(text: t.examTimetable),
            Tab(text: t.examResult),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                buildTimetable(context, t, cs),
                buildResultList(context, t, cs),
              ],
            ),
    );
  }

  // ---------------- TIMETABLE TAB ----------------
  Widget buildTimetable(
      BuildContext context, AppLocalizations t, ColorScheme cs) {
    if (timetable.isEmpty) {
      return Center(
        child: Text(t.noTimetable, style: TextStyle(color: cs.onSurface)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(cs.surfaceContainerHighest),
        columns: [
          DataColumn(label: Text(t.subject)),
          DataColumn(label: Text(t.dateLabel)),
          const DataColumn(label: Text("Session")),
          const DataColumn(label: Text("Syllabus")),
        ],
        rows: timetable.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item["subject_name"] ?? "")),
              DataCell(Text(fmt(item["date"]))),
              DataCell(Text(item["session"] ?? "")),
              DataCell(Text(item["syllabus"] ?? "")),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ---------------- RESULT TAB ----------------
  Widget buildResultList(
      BuildContext context, AppLocalizations t, ColorScheme cs) {
    if (examList.isEmpty) {
      return Center(
        child: Text(t.noResult, style: TextStyle(color: cs.onSurface)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: examList.length,
      itemBuilder: (context, i) {
        final exam = examList[i];

        return Card(
          color: cs.surface,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExamResultScreen(
                    examId: exam["id"],
                    examName: exam["exam_name"],
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      exam["exam_name"] ?? "",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
