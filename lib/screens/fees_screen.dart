import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/fees_service.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _feesSummary;
  List<dynamic>? _transactions;
  bool _loading = true;
  final _batch = DateTime.now().year.toString();
  late Box settingsBox;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settings');
    _tabController = TabController(length: 2, vsync: this);
    _loadFees();

    // Listen for user switch in Hive (just like NotificationScreen)
    settingsBox.watch(key: 'user').listen((event) async {
      // Wait a short moment for token update to complete
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _loadFees();
    });
  }

  Future<void> _loadFees() async {
    setState(() => _loading = true);

    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');

      // If user switch is mid-progress, wait a bit
      if (user == null || token == null) {
        print("User or token not ready yet. Retrying...");
        await Future.delayed(const Duration(milliseconds: 400));
        return _loadFees();
      }

      // Small extra delay to let Dio interceptor refresh
      await Future.delayed(const Duration(milliseconds: 150));

      final summary = await FeesService().getScholarFeesPayments(_batch);
      final txn = await FeesService().getScholarFeesTransactions(_batch);

      setState(() {
        _feesSummary = summary;
        _transactions = txn?['data'];
      });
    } catch (e) {
      print("Fees fetch error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fees Details"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Summary"),
            Tab(text: "Transactions"),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(colorScheme),
                _buildTransactionsTab(colorScheme),
              ],
            ),
    );
  }

  Widget _buildSummaryTab(ColorScheme colorScheme) {
    if (_feesSummary == null) {
      return const Center(child: Text("No data found."));
    }

    final data = _feesSummary?['data'] ?? {};
    final total = _feesSummary?['total'] ?? {};

    return RefreshIndicator(
      onRefresh: _loadFees,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(AppLocalizations.of(context)!.overdueFees,
              data['overdue_fees'], Colors.red),
          _buildSection(AppLocalizations.of(context)!.dueFees, data['due_fees'],
              Colors.orange),
          _buildSection(AppLocalizations.of(context)!.pendingFees,
              data['pending_fees'], Colors.blueGrey),
          const SizedBox(height: 20),
          _buildTotalCard(total, colorScheme),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic>? list, Color color) {
    if (list == null || list.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        ...list.map((item) {
          final feeItem = item['fee_item'] ?? {};
          final itemName = feeItem['item_name'] ?? 'Unnamed Item';
          final categoryName =
              feeItem['is_category_name'] ?? 'Unknown Category';

          final totalAmount = item['amount'] ?? 0;
          final balanceAmount = item['balance_amount'] ?? 0;
          final paidAmount = item['total_paid'] ?? 0;
          final concessionAmount = item['concession_amount'] ?? 0;
          final dueDays = item['due_days'] ?? 0;
          final dueDate = item['is_due_date'] ?? '-';

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Category: $categoryName",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.feeAmount + ":"),
                      Text("₹$totalAmount",
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.balanceAmount + ":"),
                      Text("₹$balanceAmount",
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.paidAmount + ":"),
                      Text("₹$paidAmount",
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          AppLocalizations.of(context)!.concessionAmount + ":"),
                      Text("₹$concessionAmount",
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.overdueIn + ":"),
                      Text("$dueDays days",
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      AppLocalizations.of(context)!.dueDate + ": $dueDate",
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTotalCard(Map total, ColorScheme colorScheme) {
    final totalAmount = total['total_amount'] ?? 0;
    final paidAmount = total['paid_amount'] ?? 0;
    final balanceAmount = total['balance_amount'] ?? 0;
    final concessionAmount = total['concession_amount'] ?? 0;

    return Card(
      color: colorScheme.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.overallSummary,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Fees:"),
                Text("₹$totalAmount",
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Paid Amount:"),
                Text("₹$paidAmount",
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Balance Amount:"),
                Text("₹$balanceAmount",
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Concession Amount:"),
                Text("₹$concessionAmount",
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalItem(String label, dynamic value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text("₹${value ?? 0}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTransactionsTab(ColorScheme colorScheme) {
    if (_transactions == null || _transactions!.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context)!.noTransactionsFound));
    }

    return RefreshIndicator(
      onRefresh: _loadFees,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions!.length,
        itemBuilder: (context, index) {
          final txn = _transactions![index];

          // Direct flat keys from your API response
          final categoryName = txn['name'] ?? 'Unknown Category';
          final itemName = txn['item_name'] ?? '-';
          final paymentDate = txn['is_paid_date'] ?? txn['paid_date'] ?? '-';
          final creatorName = txn['creator_name'] ?? '-';
          final amountPaid = txn['amount_paid'] ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text(categoryName),
              subtitle: Text(
                "Date: $paymentDate\nItem: $itemName\nBy: $creatorName",
              ),
              trailing: Text(
                "₹$amountPaid",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
