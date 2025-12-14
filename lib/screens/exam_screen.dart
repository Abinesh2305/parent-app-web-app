import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/exam_service.dart';
import 'exam_result_screen.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';


class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final ExamService _service = ExamService();

  bool _loading = true;
  List<dynamic> _examList = [];
  List<dynamic> _timetable = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    loadAll();
  }

  Future<void> loadAll() async {
    setState(() => _loading = true);

    final list = await _service.getExamList();
    final tt = await _service.getExamTimetable(0);

    List<dynamic> timetableList = [];
    if (tt != null && tt.isNotEmpty) {
      final first = tt.first;
      timetableList = (first is Map && first["timetable"] is List)
          ? first["timetable"]
          : tt;
    }

    if (!mounted) return;

    setState(() {
      _examList = list ?? [];
      _timetable = timetableList;
      _loading = false;
    });
  }

  String fmt(String? date) {
    if (date == null || date.isEmpty) return "-";
    try {
      return DateFormat("dd MMM yyyy").format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.exams), // localized
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                buildTimetable(cs),
                buildResultList(cs),
              ],
            ),
    );
  }

  // ---------------- TIMETABLE TAB ----------------
  Widget buildTimetable(ColorScheme cs) {
    final t = AppLocalizations.of(context)!;

    if (_timetable.isEmpty) {
      return Center(
        child: Text(
          t.noTimetable, // localized
          style: TextStyle(color: cs.onSurface),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // HEADER ROW
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      t.subject, // EN/TN
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      t.dateLabel, // EN/TN
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      t.session, // EN/TN (added below)
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(color: cs.onSurface.withOpacity(0.3), height: 1),

              // ROWS
              ..._timetable.map((item) {
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            item["subject_name"] ?? "",
                            style: TextStyle(fontSize: 15, color: cs.onSurface),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            fmt(item["date"]),
                            style: TextStyle(fontSize: 15, color: cs.onSurface),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            item["session"] ?? "",
                            style: TextStyle(fontSize: 15, color: cs.onSurface),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: cs.onSurface.withOpacity(0.15), height: 1),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- RESULT TAB ----------------
  Widget buildResultList(ColorScheme cs) {
    if (_examList.isEmpty) {
      return Center(
        child: Text(
          "No exams available",
          style: TextStyle(color: cs.onSurface),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadAll,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: _examList.length,
        itemBuilder: (context, i) {
          final exam = _examList[i];

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
                        exam["exam_name"],
                        style: const TextStyle(
                          fontSize: 16,
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
      ),
    );
  }
}
