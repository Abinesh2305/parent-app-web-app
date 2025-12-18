import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

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

  DateTime _selectedDate = DateTime.now();
  bool _loading = false;
  List<dynamic> _homeworks = [];
  late Box settingsBox;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settings');
    _ensurePendingBoxOpen().then((_) {
      _loadHomeworks();
      // start hourly sync after ensuring pending box is open
      _startHourlySync();
    });

    settingsBox.watch(key: 'user').listen((_) {
      if (mounted) _loadHomeworks();
    });
  }

  Future<void> _ensurePendingBoxOpen() async {
    if (!Hive.isBoxOpen('pending_reads_homework')) {
      try {
        await Hive.openBox('pending_reads_homework');
      } catch (e) {
        debugPrint("Failed to open pending_reads_homework box: $e");
      }
    }
  }

  void _startHourlySync() {
    // Cancel existing timer if any
    _syncTimer?.cancel();
    // Sync pending reads every 60 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 60), (_) {
      _syncPendingHomeworkReads();
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHomeworks() async {
    if (!mounted) return;

    setState(() => _loading = true);
    try {
      final data = await _service.getHomeworks(date: _selectedDate);
      if (!mounted) return;

      setState(() => _homeworks = data);

      // Normalize read_status casing and immediately save locally for UNREAD items
      for (final hw in data) {
        final readStatus =
            (hw["read_status"] ?? "UNREAD").toString().toUpperCase();
        hw["read_status"] = readStatus;

        if (readStatus == "UNREAD") {
          // Save locally (do not call server now) — mimic notifications behavior
          _saveReadLocally(
              hw["main_ref_no"]?.toString() ?? hw["id"]?.toString() ?? "");
          // Update local UI state to show as READ immediately
          hw["read_status"] = "READ";
        }
      }

      setState(() => _homeworks = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading homeworks: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _saveReadLocally(String ref) {
    if (ref.isEmpty) return;
    try {
      final box = Hive.box('pending_reads_homework');
      // Use ISO8601 timestamp for clarity
      box.put(ref, DateTime.now().toIso8601String());
      debugPrint("[Homework] Saved pending read locally: $ref");
    } catch (e) {
      debugPrint("[Homework] Failed saving pending read locally: $e");
    }
  }

  Future<void> _syncPendingHomeworkReads() async {
    try {
      final box = Hive.box('pending_reads_homework');
      if (box.isEmpty) return;

      final pending = Map<String, dynamic>.from(box.toMap());
      final homeworkIds = pending.keys.toList();

      debugPrint("[Homework] Syncing ${homeworkIds.length} items...");

      final ok = await _service.batchMarkAsRead(homeworkIds);

      if (ok) {
        await box.clear();
        await _loadHomeworks();
        debugPrint("[Homework] Sync success (batch)");
      } else {
        debugPrint("[Homework] Sync failed");
      }
    } catch (e) {
      debugPrint("[Homework] Sync error: $e");
    }
  }

  Future<void> _openDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadHomeworks();
    }
  }

  void _changeDate(bool next) {
    setState(() {
      _selectedDate = next
          ? _selectedDate.add(const Duration(days: 1))
          : _selectedDate.subtract(const Duration(days: 1));
    });
    _loadHomeworks();
  }

  bool _isImage(String url) {
    final u = url.toLowerCase();
    return u.endsWith('.jpg') ||
        u.endsWith('.jpeg') ||
        u.endsWith('.png') ||
        u.endsWith('.gif') ||
        u.endsWith('.webp');
  }

  List<String> _collectAllAttachments() {
    final seen = <String>{};
    final result = <String>[];

    for (final hw in _homeworks) {
      final attachments = (hw['attachments'] as List?) ?? [];
      for (final a in attachments) {
        if (a is String && a.isNotEmpty && seen.add(a)) {
          result.add(a);
        }
      }
    }
    return result;
  }

  /// ✅ FIXED DOWNLOAD METHOD (NULL SAFE)
  Future<void> _downloadFile(BuildContext context, String url) async {
    try {
      Directory? dir;

      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage not available")),
        );
        return;
      }

      final fileName = url.split('/').last;
      final filePath = "${dir.path}/$fileName";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Downloading $fileName")),
      );

      await Dio().download(url, filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Saved in: ${dir.path}")),
      );

      await OpenFilex.open(filePath);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "504 Your internet connection is slow, please try again",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final formattedDate =
        DateFormat('dd MMM, yyyy').format(_selectedDate);

    final allAttachments = _collectAllAttachments();

    final bool anyRequiresAck =
        _homeworks.any((h) => h["ack_required"] == 1);

    final bool allAckDone = _homeworks.isNotEmpty &&
        _homeworks
            .where((h) => h["ack_required"] == 1)
            .every((h) => h["ack_status"] == "ACKNOWLEDGED");

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _openDatePicker,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeDate(false),
                  ),
                  Icon(Icons.calendar_today,
                      color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeDate(true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _homeworks.isEmpty
                      ? Center(child: Text(t.noHomework))
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Table(
                                  border: TableBorder.all(
                                      color: Colors.grey.shade300),
                                  columnWidths: const {
                                    0: FlexColumnWidth(1),
                                    1: FlexColumnWidth(2),
                                  },
                                  children: [
                                    TableRow(
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary
                                            .withOpacity(0.1),
                                      ),
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.all(8),
                                          child: Text(
                                            t.subject,
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.bold),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.all(8),
                                          child: Text(
                                            t.description,
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ..._homeworks.map(
                                      (hw) => TableRow(
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.all(8),
                                            child:
                                                Text(hw['subject'] ?? ''),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.all(8),
                                            child: Text(
                                                hw['description'] ?? ''),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (anyRequiresAck)
                                allAckDone
                                    ? const Text(
                                        "Acknowledged",
                                        style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold),
                                      )
                                    : ElevatedButton(
                                        onPressed: () async {
                                          for (final hw in _homeworks) {
                                            if (hw["ack_required"] == 1) {
                                              await _service.acknowledge(
                                                  hw["main_ref_no"]);
                                            }
                                          }
                                          _loadHomeworks();
                                        },
                                        child:
                                            const Text("Acknowledge"),
                                      ),

                              if (allAttachments.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  t.attachments,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: allAttachments.map((file) {
                                    final isImage = _isImage(file);
                                    final fileName =
                                        file.split('/').last;

                                    return InkWell(
                                      onTap: () {
                                        if (isImage) {
                                          ImagePreview.show(
                                              context, file);
                                        } else {
                                          _downloadFile(context, file);
                                        }
                                      },
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          isImage
                                              ? Image.network(
                                                  file,
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                )
                                              : const Icon(
                                                  Icons.insert_drive_file,
                                                  size: 48,
                                                ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            width: 80,
                                            child: Text(
                                              fileName,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
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
