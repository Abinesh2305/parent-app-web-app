import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/exam_service.dart';

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
  List<Map<String, dynamic>> marks = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    final tt = await service.getExamTimetable(widget.examId);
    final res = await service.getExamResult(widget.examId);

    List<dynamic> ttList = [];
    if (tt != null && tt.isNotEmpty) {
      final first = tt.first;
      if (first is Map && first["timetable"] is List) {
        ttList = first["timetable"];
      } else {
        ttList = tt;
      }
    }

    setState(() {
      timetable = ttList;
      marks = res ?? [];
      loading = false;
    });
  }

  String fmtDate(String? d) {
    if (d == null || d.isEmpty) return "-";
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examName),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: "Timetable"),
            Tab(text: "Result"),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                buildTimetable(),
                buildResult(),
              ],
            ),
    );
  }

  // Timetable Tab
  Widget buildTimetable() {
    if (timetable.isEmpty) {
      return const Center(child: Text("No timetable available"));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: timetable.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final t = timetable[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_month),
            title: Text(t["subject_name"] ?? ""),
            subtitle: Text(
              "Date: ${fmtDate(t["date"])}\n"
              "Session: ${t["session"] ?? ""}\n"
              "${(t["syllabus"] ?? "")}",
            ),
          ),
        );
      },
    );
  }

  // Result Tab
  Widget buildResult() {
    if (marks.isEmpty) {
      return const Center(child: Text("No results available"));
    }

    // Convert and clean marks
    final cleaned = marks.map((m) {
      final subject = m["subject_name"] ?? m["subject"] ?? "";

      final maxMarks = m["max_marks"] ?? m["total"] ?? m["total_marks"] ?? 0;
      final obtained =
          m["obtained_marks"] ?? m["marks"] ?? m["obtained"] ?? null;

      final isAbsent =
          (m["is_absent"] == 1) || obtained == null || (m["absent"] == 1);

      final rank = m["rank"] ?? "-";

      return {
        "subject": subject,
        "maxMarks": maxMarks,
        "obtained": isAbsent ? "AB" : obtained.toString(),
        "rank": rank.toString(),
        "isAbsent": isAbsent,
      };
    }).toList();

    int totalMax = 0;
    int totalObtained = 0;

    for (var m in cleaned) {
      final raw = m["maxMarks"];
      final int max = raw is int
          ? raw
          : (raw is double ? raw.toInt() : int.tryParse(raw.toString()) ?? 0);

      totalMax += max;

      if (!m["isAbsent"]) {
        totalObtained += int.tryParse(m["obtained"].toString()) ?? 0;
      }
    }

    final double percentage =
        totalMax == 0 ? 0.0 : (totalObtained / totalMax * 100);

    final resultStatus =
        cleaned.any((m) => m["isAbsent"]) || percentage < 35 ? "Fail" : "Pass";

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          buildTopScoreCircle(totalObtained, totalMax),
          SizedBox(height: 20),

          // Student Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: const [
                  Text(
                    "RAMA",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text("Class I - A"),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Marks Table like screenshot
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                buildHeaderRow(),
                const Divider(height: 1),
                ...cleaned.map((m) => buildMarkRow(m)),
                const Divider(height: 1),
                buildTotalRow(totalObtained, totalMax),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Result + Percentage
          Row(
            children: [
              Expanded(child: buildResultBox(resultStatus)),
              const SizedBox(width: 12),
              Expanded(child: buildPercentageBox(percentage)),
            ],
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Remark: $resultStatus",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget buildTopScoreCircle(int obtained, int max) {
    return Center(
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Circle
          Container(
            margin: const EdgeInsets.only(top: 28),
            padding: const EdgeInsets.all(24),
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.teal.shade600,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$obtained",
                  style: const TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "OUT OF $max",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                )
              ],
            ),
          ),

          // Star on top
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.yellow.shade700,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.star,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: const [
          Expanded(
              flex: 4,
              child: Text("Subject",
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 3,
              child:
                  Text("Mark", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child:
                  Text("Rank", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget buildMarkRow(Map<String, dynamic> m) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(m["subject"])),
          Expanded(
            flex: 3,
            child: Text(
              "${m["obtained"]}/${m["maxMarks"]}",
              style: TextStyle(
                color: m["isAbsent"] ? Colors.red : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
              flex: 2, child: Text(m["rank"], textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget buildTotalRow(int obtained, int max) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          const Expanded(
              flex: 4,
              child:
                  Text("Total", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 3,
              child: Text("$obtained / $max",
                  style: TextStyle(fontWeight: FontWeight.bold))),
          const Expanded(flex: 2, child: Text("-")),
        ],
      ),
    );
  }

  Widget buildResultBox(String status) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Result", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              status,
              style: TextStyle(
                fontSize: 18,
                color: status == "Pass" ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildPercentageBox(double percentage) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Percentage",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              "${percentage.toStringAsFixed(1)}%",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }

  String titleCase(String s) {
    return s
        .replaceAll("_", " ")
        .split(" ")
        .map((w) => w.isEmpty ? "" : w[0].toUpperCase() + w.substring(1))
        .join(" ");
  }
}
