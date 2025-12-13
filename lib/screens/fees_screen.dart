import 'dart:io';
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

    _init();
  }

  Future<void> _init() async {
    /// 🔥 internet check added here
    if (await _checkInternet(context)) {
      _loadFees();
    } else {
      setState(() => _loading = false);
    }

    settingsBox.watch(key: 'user').listen((event) async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted && await _checkInternet(context)) {
        _loadFees();
      }
    });
  }

  // -------------------------------------------------------------
  // 🔥 UNIVERSAL INTERNET CHECK
  // -------------------------------------------------------------
  Future<bool> _checkInternet(BuildContext context) async {
    try {
      final result = await InternetAddress.lookup("google.com")
          .timeout(const Duration(seconds: 3));

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Your internet is slow, please try again."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }
  // -------------------------------------------------------------

  Future<void> _loadFees() async {
    setState(() => _loading = true);

    /// 🔥 check internet before calling API
    if (!await _checkInternet(context)) {
      setState(() => _loading = false);
      return;
    }

    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');

      if (user == null || token == null) {
        await Future.delayed(const Duration(milliseconds: 400));
        return _loadFees();
      }

      await Future.delayed(const Duration(milliseconds: 150));

      final summary = await FeesService().getScholarFeesPayments(_batch);
      final txn = await FeesService().getScholarFeesTransactions(_batch);

      setState(() {
        _feesSummary = summary;
        _transactions = txn?['data'];
      });
    } catch (e) {
      print("Fees fetch error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Your internet is slow, please try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.feesDetailsTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t.feesSummaryTab),
            Tab(text: t.feesTransactionsTab),
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
        Text(title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 8),
        ...list.map((item) {
          final feeItem = item['fee_item'] ?? {};
          final itemName = feeItem['item_name'] ?? 'Unnamed Item';
          final categoryName = feeItem['is_category_name'] ?? 'Unknown Category';

          final totalAmount = item['amount'] ?? 0;
          final paidAmount = item['total_paid'] ?? 0;
          final concessionAmount = item['concession_amount'] ?? 0;
          final waiverAmount = item['waiver_amount'] ?? 0;
          final balanceAmount = item['balance_amount'] ?? 0;
          final dueDays = item['due_days'] ?? 0;
          final dueDate = item['is_due_date'] ?? '-';

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(itemName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Category: $categoryName",
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  _row(AppLocalizations.of(context)!.feeAmount, "₹$totalAmount"),
                  _row(AppLocalizations.of(context)!.paidAmount, "₹$paidAmount"),
                  _row(AppLocalizations.of(context)!.concessionAmount,
                      "₹$concessionAmount"),
                  _row(AppLocalizations.of(context)!.waiverAmount,
                      "₹$waiverAmount"),
                  _row(AppLocalizations.of(context)!.balanceAmount,
                      "₹$balanceAmount"),
                  _row(AppLocalizations.of(context)!.overdueIn, "$dueDays days"),
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

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("$label:"),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTotalCard(Map total, ColorScheme colorScheme) {
    final totalAmount = total['total_amount'] ?? 0;
    final paidAmount = total['paid_amount'] ?? 0;
    final concessionAmount = total['concession_amount'] ?? 0;
    final waiverAmount = total['waiver_amount'] ?? 0;
    final balanceAmount = total['balance_amount'] ?? 0;

    return Card(
      color: colorScheme.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.overallSummary,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _row("Total Fees", "₹$totalAmount"),
            _row("Paid Amount", "₹$paidAmount"),
            _row("Concession Amount", "₹$concessionAmount"),
            _row(AppLocalizations.of(context)!.waiverAmount, "₹$waiverAmount"),
            _row("Balance Amount", "₹$balanceAmount"),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab(ColorScheme colorScheme) {
    if (_transactions == null || _transactions!.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noTransactionsFound),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFees,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions!.length,
        itemBuilder: (context, index) {
          final txn = _transactions![index];

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
