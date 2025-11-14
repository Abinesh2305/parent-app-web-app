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
import 'package:school_dashboard/l10n/app_localizations.dart';

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

    // Reload homework when user switches
    settingsBox.watch(key: 'user').listen((_) {
      if (mounted) _loadHomeworks();
    });
  }

  Future<void> _loadHomeworks() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getHomeworks(date: _selectedDate);
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

  void _changeDate(bool next) {
    setState(() {
      _selectedDate = next
          ? _selectedDate.add(const Duration(days: 1))
          : _selectedDate.subtract(const Duration(days: 1));
    });
    _loadHomeworks();
  }

  // Combine all attachments into a single list
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
    final t = AppLocalizations.of(context)!;

    try {
      if (Platform.isAndroid) {
        int sdkInt =
            int.tryParse(Platform.version.split('(').first.trim()) ?? 33;

        if (sdkInt >= 33) {
          Map<Permission, PermissionStatus> statuses = await [
            Permission.photos,
            Permission.videos,
            Permission.audio,
          ].request();

          if (statuses.values.any((status) => status.isDenied)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.mediaPermissionReq)),
            );
            return;
          }
        } else {
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
            if (!status.isGranted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.storagePermissionReq)),
              );
              return;
            }
          }
        }
      }

      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.cannotAccessFolder)),
        );
        return;
      }

      final fileName = url.split('/').last;
      final filePath = "${dir.path}/$fileName";
      final dio = Dio();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${t.downloading} $fileName...")),
      );

      await dio.download(url, filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${t.savedTo}: ${dir.path}")),
      );

      await OpenFilex.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${t.downloadFailed}: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final formattedDate = DateFormat('dd MMM, yyyy').format(_selectedDate);
    final allAttachments = _collectAllAttachments();
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date navigation
            Row(
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
            const SizedBox(height: 16),

            // Content
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
                                    // Table header
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

                                    // Table rows
                                    ..._homeworks.map((hw) {
                                      return TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(hw['subject'] ?? ''),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(hw['description'] ??
                                                t.noDetails),
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Show attachments together
                              if (allAttachments.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.attachments,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: allAttachments.map((file) {
                                        final isPdf =
                                            file.toLowerCase().endsWith('.pdf');
                                        final fileName = file.split('/').last;

                                        return InkWell(
                                          onTap: () =>
                                              _downloadFile(context, file),
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
