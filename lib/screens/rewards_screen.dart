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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.rewards)),
      body: loading && items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(child: Text(t.noRewards))
              : RefreshIndicator(
                  onRefresh: () => loadRewards(refresh: true),
                  child: ListView.builder(
                    itemCount: items.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == items.length) {
                        loadRewards();
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final r = items[i];

                      return Card(
                        margin: const EdgeInsets.all(12),
                        child: ListTile(
                          title: Text(r['remark_type'] ?? ''),
                          subtitle: Text(r['remark_description'] ?? ''),
                          trailing: Text(
                            r['created_at'] != null
                                ? r['created_at'].toString().split(" ")[0]
                                : "",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
