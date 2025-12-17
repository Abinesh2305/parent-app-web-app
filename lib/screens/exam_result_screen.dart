import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';
import '../services/exam_service.dart';

class ExamResultScreen extends StatefulWidget {
  final int examId;
  final String examName;

  const ExamResultScreen({
    super.key,
    required this.examId,
    required this.examName,
  });

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  final service = ExamService();
  bool loading = true;

  List<Map<String, dynamic>> marks = [];

  @override
  void initState() {
    super.initState();
    loadResult();
  }

  Future<void> loadResult() async {
    setState(() => loading = true);

    final res = await service.getExamResult(widget.examId);

    setState(() {
      marks = (res ?? []).cast<Map<String, dynamic>>();
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

    final cleaned = marks.map((m) {
      final subject = m["subject_name"] ?? m["subject"] ?? "";
      final maxMarks = m["max_marks"] ?? m["total"] ?? m["total_marks"] ?? 0;
      final obtained = m["obtained_marks"] ?? m["marks"];

      final isAbsent =
          (m["is_absent"] == 1) || obtained == null || (m["absent"] == 1);

      return {
        "subject": subject,
        "max": maxMarks,
        "obt": isAbsent ? "AB" : obtained.toString(),
        "isAbsent": isAbsent,
        "rank": m["rank"]?.toString() ?? "-",
      };
    }).toList();

    int totalMax = 0;
    int totalObt = 0;

    for (var m in cleaned) {
      final dynamic rawMax = m["max"];

      final int max = rawMax is int
          ? rawMax
          : rawMax is double
              ? rawMax.toInt()
              : int.tryParse(rawMax.toString()) ?? 0;

      totalMax += max;

      if (!m["isAbsent"]) {
        totalObt += int.tryParse(m["obt"].toString()) ?? 0;
      }
    }

    final percentage = (totalMax == 0) ? 0.0 : (totalObt / totalMax * 100);

    final status =
        percentage < 35 || cleaned.any((m) => m["isAbsent"]) ? "Fail" : "Pass";

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examName),
        backgroundColor: cs.surface,
        iconTheme: IconThemeData(color: cs.onSurface),
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : marks.isEmpty
              ? Center(child: Text(t.noResult))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Top Score Circle
                      _buildTopCircle(totalObt, totalMax, cs, t),

                      const SizedBox(height: 20),

                      // Marks Table
                      Card(
                        color: cs.surface,
                        margin: const EdgeInsets.all(16),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          children: [
                            _buildHeader(cs, t),
                            const Divider(height: 1),
                            ...cleaned.map((m) => _buildRow(m, cs)),
                            const Divider(height: 1),
                            _buildTotalRow(totalObt, totalMax, cs, t),
                          ],
                        ),
                      ),

                      // Result + Percentage
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _box(
                                t.result,
                                status,
                                status == "Pass" ? Colors.green : Colors.red,
                                cs,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _box(
                                t.percentage,
                                "${percentage.toStringAsFixed(1)}%",
                                cs.primary,
                                cs,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTopCircle(
      int obtained, int max, ColorScheme cs, AppLocalizations t) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 28),
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: cs.primary,
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$obtained",
                style: TextStyle(
                  fontSize: 36,
                  color: cs.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${t.outOf} $max",
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onPrimary.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.yellow.shade700,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Icon(Icons.star, color: Colors.white, size: 26),
        ),
      ],
    );
  }

  Widget _buildHeader(ColorScheme cs, AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 4,
              child: Text(t.subject,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: cs.onSurface))),
          Expanded(
              flex: 3,
              child: Text(t.mark,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: cs.onSurface))),
          Expanded(
              flex: 2,
              child: Text(t.rank,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: cs.onSurface))),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> m, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(m["subject"], style: TextStyle(color: cs.onSurface)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              "${m["obt"]}/${m["max"]}",
              style: TextStyle(
                color: m["isAbsent"] ? Colors.red : cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              m["rank"],
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
      int obtained, int max, ColorScheme cs, AppLocalizations t) {
    return Container(
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(t.total,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: cs.onSurface)),
          ),
          Expanded(
            flex: 3,
            child: Text("$obtained / $max",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: cs.onSurface)),
          ),
          const Expanded(flex: 2, child: Text("-")),
        ],
      ),
    );
  }

  Widget _box(String title, String value, Color valueColor, ColorScheme cs) {
    return Card(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: cs.onSurface)),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                color: valueColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
