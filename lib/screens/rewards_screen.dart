import 'package:flutter/material.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';
import '../services/rewards_service.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  List<dynamic> items = [];
  bool loading = true;
  int page = 0;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    loadRewards();
  }

  Future<void> loadRewards({bool refresh = false}) async {
    if (refresh) {
      items.clear();
      page = 0;
      hasMore = true;
    }

    if (!hasMore) return;

    setState(() => loading = true);

    final res = await RewardsService().getRewards(page: page);

    setState(() => loading = false);

    if (res == null) return;

    if (res['status'] == 1) {
      final data = res['data'];
      if (data.length < 20) hasMore = false;

      setState(() {
        items.addAll(data);
        page += 20;
      });
    }
  }

  Color badgeColor(String type, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (type == "REWARD") {
      return isDark ? Colors.green.shade800 : Colors.green.shade100;
    } else if (type == "REMARK") {
      return isDark ? Colors.orange.shade800 : Colors.orange.shade100;
    } else {
      return isDark ? Colors.red.shade800 : Colors.red.shade100;
    }
  }

  Color badgeTextColor(String type, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (type == "REWARD") {
      return isDark ? Colors.green.shade200 : Colors.green.shade900;
    } else if (type == "REMARK") {
      return isDark ? Colors.orange.shade200 : Colors.orange.shade900;
    } else {
      return isDark ? Colors.red.shade200 : Colors.red.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.rewards),
        backgroundColor: cs.surface,
        elevation: 1,
      ),
      body: loading && items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(
                  child: Text(
                    t.noRewards,
                    style: TextStyle(fontSize: 16, color: cs.onSurface),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => loadRewards(refresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == items.length) {
                        loadRewards();
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final r = items[i];
                      final remarkType = r['remark_type'] ?? '';
                      final description = r['remark_description'] ?? '';
                      final postedBy = r['posted_user']?['name'] ?? '';
                      final createdAt = r['created_at'] ?? '';

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? cs.surfaceContainerHighest.withOpacity(0.35)
                              : cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.outline.withOpacity(0.3),
                          ),
                          boxShadow: [
                            if (!isDark)
                              const BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Badge Row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor(remarkType, context),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    remarkType,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          badgeTextColor(remarkType, context),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  createdAt,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Icon(Icons.person,
                                    size: 16,
                                    color: cs.onSurface.withOpacity(0.6)),
                                const SizedBox(width: 6),
                                Text(
                                  postedBy,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: cs.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
