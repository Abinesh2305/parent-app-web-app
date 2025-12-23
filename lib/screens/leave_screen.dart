import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/leave_service.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String _leaveType = 'FULL DAY';
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  // ---------- AUDIO (UPLOAD ONLY) ----------
  String? _audioPath;          // mobile
  Uint8List? _audioBytes;      // web
  String? _audioFileName;

  bool _loading = false;

  List<dynamic> _pendingLeaves = [];
  late Box settingsBox;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settings');
    _loadUnapprovedLeaves();

    settingsBox.watch(key: 'user').listen((event) async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _loadUnapprovedLeaves();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // ================= LOAD LEAVES =================

  Future<void> _loadUnapprovedLeaves() async {
    setState(() => _loading = true);

    final box = Hive.box('settings');
    final user = box.get('user');
    final token = box.get('token');

    if (user == null || token == null) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) return _loadUnapprovedLeaves();
    }

    final res = await LeaveService().getUnapprovedLeaves();

    if (res != null && res['status'] == 1) {
      _pendingLeaves = res['data'];
    } else {
      _pendingLeaves = [];
    }

    setState(() => _loading = false);
  }

  // ================= PICK AUDIO =================

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
      withData: true, // required for web
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;

      setState(() {
        _audioFileName = file.name;
        _audioBytes = file.bytes; // web
        _audioPath = file.path;   // mobile (can be null on web)
      });
    }
  }

  void _removeAudio() {
    setState(() {
      _audioFileName = null;
      _audioBytes = null;
      _audioPath = null;
    });
  }

  // ================= APPLY LEAVE =================

  Future<void> _applyLeave() async {
    final t = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final leaveStart = DateFormat('yyyy-MM-dd').format(_fromDate);
    final leaveEnd = _leaveType == 'MORE THAN ONE DAY'
        ? DateFormat('yyyy-MM-dd').format(_toDate)
        : null;

    final res = await LeaveService().applyLeave(
      leaveReason: _reasonController.text,
      leaveDate: leaveStart,
      leaveType: _leaveType,
      leaveEndDate: leaveEnd,
      audioPath: _audioPath,
      audioBytes: _audioBytes,
      audioFileName: _audioFileName,
    );

    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res?['message'] ?? t.somethingWentWrong)),
    );

    if (res?['status'] == 1) {
      _reasonController.clear();
      _audioPath = null;
      _audioBytes = null;
      _audioFileName = null;
      _leaveType = 'FULL DAY';
      _loadUnapprovedLeaves();
    }
  }

  // ================= CANCEL LEAVE =================

  Future<void> _cancelLeave(int id) async {
    final t = AppLocalizations.of(context)!;

    setState(() => _loading = true);
    final res = await LeaveService().cancelLeave(id);
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res?['message'] ?? t.errorCancellingLeave)),
    );

    if (res?['status'] == 1) _loadUnapprovedLeaves();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.leaveManagement)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUnapprovedLeaves,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildApplyForm(colorScheme, t),
                    const SizedBox(height: 24),
                    Text(
                      t.pendingLeaves,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_pendingLeaves.isEmpty)
                      Center(child: Text(t.noPendingLeaves)),
                    ..._pendingLeaves.map(
                      (l) => Card(
                        child: ListTile(
                          title: Text(
                            "${t.from}: ${l['leave_date_format'] ?? l['leave_date']}"
                            "${l['leave_enddate_format'] != null ? '\n${t.to}: ${l['leave_enddate_format']}' : ''}",
                          ),
                          subtitle: Text(
                            "${l['leave_reason'] ?? ''}\n${t.leaveType}: ${l['leave_type']}",
                          ),
                          trailing: TextButton(
                            onPressed: () => _cancelLeave(l['id']),
                            child: Text(
                              t.cancelLeave,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ================= APPLY FORM =================

  Widget _buildApplyForm(ColorScheme colorScheme, AppLocalizations t) {
    return Form(
      key: _formKey,
      child: Card(
        margin: const EdgeInsets.only(bottom: 20),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.applyForLeave,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _leaveType,
                decoration: InputDecoration(labelText: t.leaveType),
                items: const [
                  'FULL DAY',
                  'HALF MORNING',
                  'HALF AFTERNOON',
                  'MORE THAN ONE DAY'
                ]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _leaveType = v ?? 'FULL DAY'),
              ),

              const SizedBox(height: 12),

              if (_leaveType == 'MORE THAN ONE DAY') ...[
                _dateRow(t.from, _fromDate, true, colorScheme),
                _dateRow(t.to, _toDate, false, colorScheme),
              ] else
                _dateRow(t.date, _fromDate, true, colorScheme),

              const SizedBox(height: 12),

              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(labelText: t.reason),
                validator: (v) => v == null || v.isEmpty ? t.enterReason : null,
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickAudioFile,
                    icon: const Icon(Icons.upload_file),
                    label: Text(t.uploadAudio),
                  ),
                  const SizedBox(width: 10),
                  if (_audioFileName != null)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.audiotrack, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _audioFileName!,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: _removeAudio,
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _applyLeave,
                icon: const Icon(Icons.send),
                label: Text(t.submitLeave),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateRow(
    String label,
    DateTime date,
    bool isFrom,
    ColorScheme scheme,
  ) {
    return Row(
      children: [
        Text("$label: "),
        TextButton(
          onPressed: () => _pickDate(isFrom: isFrom),
          child: Text(
            DateFormat('dd MMM yyyy').format(date),
            style: TextStyle(color: scheme.primary),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 90)),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_toDate.isBefore(_fromDate)) _toDate = _fromDate;
        } else {
          _toDate = picked;
        }
      });
    }
  }
}
