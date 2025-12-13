import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
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
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();

  String _leaveType = 'FULL DAY'; // unchanged
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  String? _audioPath;
  bool _recording = false;
  bool _playing = false;
  bool _loading = false;
  double _currentAmplitude = 0.0;

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

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

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
      setState(() => _pendingLeaves = res['data']);
    } else {
      setState(() => _pendingLeaves = []);
    }

    setState(() => _loading = false);
  }

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
      attachmentPath: _audioPath,
    );

    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?['message'] ?? t.somethingWentWrong)));

    if (res?['status'] == 1) {
      _reasonController.clear();
      _audioPath = null;
      _leaveType = 'FULL DAY';
      _loadUnapprovedLeaves();
    }
  }

  Future<void> _cancelLeave(int id) async {
    final t = AppLocalizations.of(context)!;

    setState(() => _loading = true);
    final res = await LeaveService().cancelLeave(id);
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?['message'] ?? t.errorCancellingLeave)));

    if (res?['status'] == 1) _loadUnapprovedLeaves();
  }

  Future<void> _toggleRecording() async {
    final t = AppLocalizations.of(context)!;

    if (_recording) {
      final path = await _audioRecorder.stop();
      setState(() {
        _recording = false;
        _audioPath = path;
        _currentAmplitude = 0.0;
      });
    } else {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final filePath =
            '${dir.path}/leave_${DateTime.now().millisecondsSinceEpoch}.mp3';

        await _audioRecorder.start(const RecordConfig(), path: filePath);

        _audioRecorder
            .onAmplitudeChanged(const Duration(milliseconds: 150))
            .listen((amp) {
          setState(() => _currentAmplitude = amp.current);
        });

        setState(() {
          _recording = true;
          _currentAmplitude = 0.0;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.microphonePermissionDenied)));
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_audioPath == null) return;

    if (_playing) {
      await _audioPlayer.pause();
      setState(() => _playing = false);
    } else {
      await _audioPlayer.play(DeviceFileSource(_audioPath!));
      setState(() => _playing = true);
    }
  }

  Future<void> _removeAudio() async {
    if (_playing) await _audioPlayer.stop();

    setState(() {
      _audioPath = null;
      _playing = false;
    });
  }

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
                    Text(t.pendingLeaves,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
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
              Text(t.applyForLeave,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _leaveType,
                decoration: InputDecoration(labelText: t.leaveType),
                items: [
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
                Row(
                  children: [
                    Text("${t.from}: "),
                    TextButton(
                      onPressed: () => _pickDate(isFrom: true),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(_fromDate),
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text("${t.to}: "),
                    TextButton(
                      onPressed: () => _pickDate(isFrom: false),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(_toDate),
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Text("${t.date}: "),
                    TextButton(
                      onPressed: () => _pickDate(isFrom: true),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(_fromDate),
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ],
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
                    onPressed: _toggleRecording,
                    icon: Icon(_recording ? Icons.stop : Icons.mic),
                    label: Text(_recording ? t.stopRecording : t.recordAudio),
                  ),
                  const SizedBox(width: 10),
                  if (_audioPath != null)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _playing ? Icons.pause_circle : Icons.play_circle,
                            size: 32,
                            color: colorScheme.primary,
                          ),
                          onPressed: _togglePlayback,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: _removeAudio,
                        ),
                      ],
                    ),
                ],
              ),
              if (_recording) ...[
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Text(t.recordingSpeakNow),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        height: 20,
                        width: (_currentAmplitude.abs() * 2).clamp(10, 300),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
