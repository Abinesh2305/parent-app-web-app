import 'package:flutter/material.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';
import 'package:school_dashboard/services/survey_service.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  bool loading = true;
  bool submitting = false;
  List<dynamic> surveys = [];
  int page = 0;
  bool hasMore = true;

  static const int limit = 10; // backend limit

  @override
  void initState() {
    super.initState();
    loadSurveys();
  }

  Future<void> loadSurveys({bool refresh = false}) async {
    if (refresh) {
      surveys.clear();
      page = 0;
      hasMore = true;
    }

    if (!hasMore) return;

    setState(() => loading = true);

    final res = await SurveyService().fetchSurveys(page: page);

    setState(() => loading = false);

    if (res == null) return;

    if (res['status'] == 1) {
      List list = res['data'];

      if (list.length < limit) {
        hasMore = false;
      }

      setState(() {
        surveys.addAll(list);
        page += limit;
      });
    }
  }

  Future<void> submitSurvey(int surveyId, int option) async {
    setState(() => submitting = true);

    final res = await SurveyService().submitSurvey(
      surveyId: surveyId,
      respondId: option,
    );

    setState(() => submitting = false);

    if (res != null && res['status'] == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'])),
      );
      loadSurveys(refresh: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?['message'] ?? "Failed")),
      );
    }
  }

  bool isExpired(String expiry) {
    try {
      final exp = DateTime.parse(expiry);
      return exp.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.surveys)),
      body: RefreshIndicator(
        onRefresh: () => loadSurveys(refresh: true),
        child: loading && surveys.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : surveys.isEmpty
                ? Center(
                    child: Text(
                      t.noSurveys,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: surveys.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == surveys.length) {
                        loadSurveys();
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final s = surveys[index];
                      final int surveyId = s['id'];
                      final int selected = s['respond_id'] ?? 0;
                      final bool expired = isExpired(s['expiry_date']);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      s['survey_question'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Expiry: ${s['expiry_date']}",
                                style: TextStyle(
                                  color: expired ? Colors.red : cs.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (expired)
                                const Text(
                                  "Survey expired",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    for (int i = 1; i <= 4; i++)
                                      if (s["survey_option$i"] != null &&
                                          s["survey_option$i"]
                                              .toString()
                                              .trim()
                                              .isNotEmpty)
                                        RadioListTile<int>(
                                          value: i,
                                          groupValue: selected,
                                          onChanged: selected == 0 &&
                                                  !submitting
                                              ? (v) => submitSurvey(surveyId, i)
                                              : null,
                                          title: Text(s["survey_option$i"]),
                                        ),
                                  ],
                                ),
                              if (selected != 0 && !expired)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    t.alreadyResponded,
                                    style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
