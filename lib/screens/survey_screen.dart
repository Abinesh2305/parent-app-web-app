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

  @override
  void initState() {
    super.initState();
    loadSurveys();
  }

  Future<void> loadSurveys({bool refresh = false}) async {
    if (refresh) {
      page = 0;
      surveys.clear();
      hasMore = true;
    }

    if (!hasMore) return;

    setState(() => loading = true);

    final res = await SurveyService().fetchSurveys(page: page);

    setState(() => loading = false);

    if (res == null) return;

    if (res['status'] == 1) {
      final list = res['data'];

      if (list.length < 20) {
        hasMore = false;
      }

      setState(() {
        surveys.addAll(list);
        page += 20;
      });
    }
  }

  Future<void> submitSurvey(int notifId, int option) async {
    setState(() => submitting = true);

    final res = await SurveyService().submitSurvey(
      postId: notifId,
      respondId: option,
    );

    setState(() => submitting = false);

    if (res != null && res['status'] == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "")),
      );
      loadSurveys(refresh: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?['message'] ?? "Failed")),
      );
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
                          fontSize: 16, fontWeight: FontWeight.w600),
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
                      final int notifId = s['notification_id'];
                      final int selected = s['notify_response'] ?? 0;

                      return Card(
                        margin: const EdgeInsets.all(12),
                        color: cs.primary.withOpacity(0.07),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['survey_question'] ?? "",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              for (int i = 1; i <= 4; i++)
                                if (s['survey_option$i'] != null &&
                                    s['survey_option$i']
                                        .toString()
                                        .trim()
                                        .isNotEmpty)
                                  RadioListTile<int>(
                                    value: i,
                                    groupValue: selected,
                                    onChanged: selected == 0 && !submitting
                                        ? (v) => submitSurvey(notifId, i)
                                        : null,
                                    activeColor: cs.primary,
                                    title: Text(s['survey_option$i']),
                                  ),
                              const SizedBox(height: 4),
                              if (selected != 0)
                                Text(
                                  t.alreadyResponded,
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
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
