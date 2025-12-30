import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';
import 'package:school_dashboard/services/homework_service.dart';
import '../widgets/image_preview.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final HomeworkService _service = HomeworkService();

  DateTime _selectedDate = DateTime.now(); // ✅ FIXED (not final)
  bool _loading = false;
  List<Map<String, dynamic>> _homeworks = [];
  late Box settingsBox;
  late StreamSubscription _studentSub; // ✅ prevent dispose crash

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settings');
    _loadHomeworks();

    // ✅ LISTEN TO STUDENT SWITCH SAFELY
    _studentSub = settingsBox.watch(key: 'current_student').listen((_) {
      if (mounted) _loadHomeworks();
    });
  }

  @override
  void dispose() {
    _studentSub.cancel(); // ✅ CRITICAL FIX
    super.dispose();
  }

  /* ================= DATE PICKER ================= */

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // no future homework
    );

    if (picked == null || !mounted) return;

    setState(() => _selectedDate = picked);
    _loadHomeworks();
  }

  /* ================= LOAD HOMEWORK ================= */

  Future<void> _loadHomeworks() async {
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      final data = await _service.getHomeworks(date: _selectedDate);

      if (!mounted) return;

      final safe = <Map<String, dynamic>>[];

      for (final item in data) {
        if (item is Map<String, dynamic>) {
          safe.add(item);
        }
      }

      setState(() => _homeworks = safe);
    } catch (e) {
      if (mounted) _showNetworkMessage();
      debugPrint("[Homework] Load error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ================= ACKNOWLEDGE ================= */

  Future<void> _acknowledgeNow() async {
    try {
      for (final hw in _homeworks) {
        if (hw['ack_required'] == 1 &&
            hw['ack_status'] != 'ACKNOWLEDGED') {
          await _service.acknowledge(hw['main_ref_no']);
        }
      }

      await _loadHomeworks();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Acknowledged successfully")),
      );
    } catch (_) {
      _showNetworkMessage();
    }
  }

  /* ================= HELPERS ================= */

  void _showNetworkMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text("Your internet is slow or unavailable. Please try again."),
      ),
    );
  }

  bool _isImage(String url) {
    final u = url.toLowerCase();
    return u.endsWith('.jpg') ||
        u.endsWith('.jpeg') ||
        u.endsWith('.png') ||
        u.endsWith('.webp');
  }

  List<String> _collectAttachments() {
    final files = <String>{};

    for (final hw in _homeworks) {
      final raw = hw['attachments'];
      if (raw is List) {
        for (final f in raw) {
          if (f is String && f.isNotEmpty) files.add(f);
        }
      }
    }
    return files.toList();
  }

  /* ================= DOWNLOAD ================= */

  Future<void> _downloadFile(String url) async {
    if (kIsWeb) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    try {
      await Dio().get(url);
    } catch (_) {}
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final date = DateFormat('dd MMM, yyyy').format(_selectedDate);
    final attachments = _collectAttachments();

    final anyAck =
        _homeworks.any((h) => h['ack_required'] == 1);
    final allAckDone = anyAck &&
        _homeworks
            .where((h) => h['ack_required'] == 1)
            .every((h) => h['ack_status'] == 'ACKNOWLEDGED');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ DATE HEADER WITH CALENDAR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _loading ? null : _pickDate,
                )
              ],
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _homeworks.isEmpty
                      ? Center(child: Text(t.noHomework))
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              Table(
                                border: TableBorder.all(
                                  color: Colors.grey.shade300,
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(1),
                                  1: FlexColumnWidth(2),
                                },
                                children: [
                                  TableRow(children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        t.subject,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        t.description,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ]),
                                  ..._homeworks.map((hw) {
                                    return TableRow(children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                            hw['subject']?.toString() ?? ''),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                            hw['description']?.toString() ??
                                                ''),
                                      ),
                                    ]);
                                  }),
                                ],
                              ),

                              const SizedBox(height: 16),

                              if (anyAck)
                                allAckDone
                                    ? const Text(
                                        "Acknowledged",
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: _acknowledgeNow,
                                        child: const Text("Acknowledge"),
                                      ),

                              if (attachments.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  children: attachments.map((f) {
                                    final isImg = _isImage(f);
                                    return InkWell(
                                      onTap: () => isImg
                                          ? ImagePreview.show(context, f)
                                          : _downloadFile(f),
                                      child: isImg
                                          ? Image.network(
                                              f,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (_, __, ___) =>
                                                      const Icon(
                                                          Icons.broken_image),
                                            )
                                          : const Icon(
                                              Icons.insert_drive_file),
                                    );
                                  }).toList(),
                                )
                              ]
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
