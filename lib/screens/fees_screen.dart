import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import '../services/fees_service.dart';
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

  /* ================= INIT ================= */

  Future<void> _init() async {
    if (await _checkInternet()) {
      _loadFees();
    } else {
      setState(() => _loading = false);
    }

    settingsBox.watch(key: 'user').listen((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted && await _checkInternet()) {
        _loadFees();
      }
    });
  }

  /* ================= INTERNET CHECK ================= */

  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup("google.com")
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      _snack("Your internet is slow or unavailable. Please try again.");
      return false;
    }
  }

  /* ================= LOAD FEES ================= */

  Future<void> _loadFees() async {
    setState(() => _loading = true);

    if (!await _checkInternet()) {
      setState(() => _loading = false);
      return;
    }

    try {
      final summary = await FeesService().getScholarFeesPayments(_batch);
      final txn = await FeesService().getScholarFeesTransactions(_batch);

      if (!mounted) return;

      setState(() {
        _feesSummary = summary;
        _transactions = txn?['data'];
      });
    } catch (_) {
      _snack("Unable to load fees. Please try again.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ================= BANK DETAILS ================= */

  Future<void> _showBankDetails() async {
    if (!await _checkInternet()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final banks = await FeesService().getBanksList();

      if (!mounted) return;
      Navigator.pop(context);

      if (banks.isEmpty) {
        _snack("Bank details not available");
        return;
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Bank Details"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: banks.length,
              itemBuilder: (_, i) => _bankCard(banks[i]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE"),
            )
          ],
        ),
      );
    } catch (_) {
      if (mounted) Navigator.pop(context);
      _snack("Unable to load bank details");
    }
  }

  /* ================= BANK CARD ================= */

  Widget _bankCard(Map<String, dynamic> b) {
    final qrUrl = b['is_qr_code_image'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              b['bank_name'] ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            _bankRow("Account Holder", b['account_holder_name']),
            _bankRow("Account No", b['account_no'], copyable: true),
            _bankRow("Branch", b['branch_name']),
            _bankRow("IFSC", b['ifsc_code'], copyable: true),
            _bankRow("UPI ID", b['upi_id']),

            /// 🔥 SHOW QR BUTTON
            if (qrUrl != null && qrUrl.toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code),
                  label: const Text("Show QR Code"),
                  onPressed: () => _viewQrImage(qrUrl),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /* ================= QR VIEWER ================= */

  void _viewQrImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const CircularProgressIndicator(color: Colors.white);
                  },
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            )
          ],
        ),
      ),
    );
  }

  /* ================= UI HELPERS ================= */

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _bankRow(String label, dynamic value, {bool copyable = false}) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: copyable
          ? () {
              Clipboard.setData(
                ClipboardData(text: value.toString()),
              );
              _snack("$label copied");
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                "$label:",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: Text(value.toString())),
                  if (copyable)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.copy, size: 16, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ================= BUILD ================= */

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.feesDetailsTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _showBankDetails,
              icon: const Icon(Icons.account_balance, size: 18),
              label: Text(
                t.acdetails,
                style: const TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
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
                _buildSummaryTab(cs),
                _buildTransactionsTab(),
              ],
            ),
    );
  }

  /* ================= SUMMARY TAB ================= */

  Widget _buildSummaryTab(ColorScheme cs) {
    if (_feesSummary == null) {
      return const Center(child: Text("No data found"));
    }

    final data = _feesSummary?['data'] ?? {};
    final total = _feesSummary?['total'] ?? {};

    return RefreshIndicator(
      onRefresh: _loadFees,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection("Overdue Fees", data['overdue_fees'], Colors.red),
          _buildSection("Due Fees", data['due_fees'], Colors.orange),
          _buildSection("Pending Fees", data['pending_fees'], Colors.blueGrey),
          const SizedBox(height: 20),
          _buildTotalCard(total, cs),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic>? list, Color color) {
    if (list == null || list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 8),
        ...list.map((item) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['fee_item']?['item_name'] ?? '',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  _row("Amount", "₹${item['amount']}"),
                  _row("Paid", "₹${item['total_paid']}"),
                  _row("Balance", "₹${item['balance_amount']}"),
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
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTotalCard(Map total, ColorScheme cs) {
    return Card(
      color: cs.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Overall Summary",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _row("Total", "₹${total['total_amount']}"),
            _row("Paid", "₹${total['paid_amount']}"),
            _row("Balance", "₹${total['balance_amount']}"),
          ],
        ),
      ),
    );
  }

  /* ================= TRANSACTIONS TAB ================= */

  Widget _buildTransactionsTab() {
    if (_transactions == null || _transactions!.isEmpty) {
      return const Center(child: Text("No transactions found"));
    }

    return RefreshIndicator(
      onRefresh: _loadFees,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions!.length,
        itemBuilder: (_, index) {
          final txn = _transactions![index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text(txn['name'] ?? ''),
              subtitle:
                  Text("Date: ${txn['paid_date']}\nItem: ${txn['item_name']}"),
              trailing: Text(
                "₹${txn['amount_paid']}",
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}
