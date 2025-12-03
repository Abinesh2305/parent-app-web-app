import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';
import 'package:school_dashboard/services/homework_service.dart';
import 'package:open_filex/open_filex.dart';
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

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settings');
    _loadHomeworks();

    settingsBox.watch(key: 'user').listen((_) {
      if (mounted) _loadHomeworks();
    });
  }

  Future<void> _loadHomeworks() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await _service.getHomeworks(date: _selectedDate);
      if (!mounted) return;
      setState(() => _homeworks = data);

      for (final hw in data) {
        if (hw["read_status"] == "UNREAD") {
          await _service.markAsRead(hw["main_ref_no"]);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading homeworks: $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openDatePicker() async {
    final DateTime? picked = await showDatePicker(
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

  // Identify images
  bool _isImage(String url) {
    final u = url.toLowerCase();
    return u.endsWith('.jpg') ||
        u.endsWith('.jpeg') ||
        u.endsWith('.png') ||
        u.endsWith('.gif') ||
        u.endsWith('.webp');
  }

  // Collect all unique attachments
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
          const SnackBar(content: Text("Cannot access storage")),
        );
        return;
      }

      final fileName = url.split('/').last;
      final filePath = "${dir.path}/$fileName";

      final dio = Dio();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Downloading $fileName")),
      );

      await dio.download(url, filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Saved in: ${dir.path}")),
      );

      await OpenFilex.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final formattedDate = DateFormat('dd MMM, yyyy').format(_selectedDate);
    final allAttachments = _collectAllAttachments();
    final t = AppLocalizations.of(context)!;

    final bool anyRequiresAck = _homeworks.any((h) => h["ack_required"] == 1);

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
                  Icon(Icons.calendar_today, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
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
                      ? Center(
                          child: Text(
                            t.noHomework,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                                child: Table(
                                  border: TableBorder.all(
                                      color: Colors.grey.shade400),
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
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            t.subject,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            t.description,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ..._homeworks.map((hw) {
                                      return TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(hw['subject'] ?? ''),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child:
                                                Text(hw['description'] ?? ''),
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (anyRequiresAck)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: allAckDone
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 14),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.green.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "Acknowledged",
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
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
                                          child: Text("Acknowledge"),
                                        ),
                                ),
                              if (allAttachments.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.attachments,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: allAttachments.map((file) {
                                        final isImage = _isImage(file);
                                        final isPdf =
                                            file.toLowerCase().endsWith('.pdf');
                                        final fileName = file.split('/').last;

                                        return InkWell(
                                          onTap: () {
                                            if (isImage) {
                                              ImagePreview.show(context, file);
                                            } else {
                                              _downloadFile(context, file);
                                            }
                                          },
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              isPdf
                                                  ? Container(
                                                      width: 80,
                                                      height: 80,
                                                      color:
                                                          Colors.grey.shade200,
                                                      child: const Icon(
                                                        Icons.picture_as_pdf,
                                                        size: 40,
                                                        color: Colors.red,
                                                      ),
                                                    )
                                                  : ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      child: Image.network(
                                                        file,
                                                        width: 80,
                                                        height: 80,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context,
                                                                error,
                                                                stackTrace) =>
                                                            Container(
                                                          width: 80,
                                                          height: 80,
                                                          color: Colors
                                                              .grey.shade300,
                                                          child: const Icon(Icons
                                                              .broken_image),
                                                        ),
                                                      ),
                                                    ),
                                              const SizedBox(height: 4),
                                              Text(
                                                fileName,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
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
