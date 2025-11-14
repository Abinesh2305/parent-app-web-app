import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/leave_service.dart';

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

  String _leaveType = 'FULL DAY';
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

    // Listen for user switch and reload leaves
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

    // Safety: ensure data ready after user switch
    if (user == null || token == null) {
      print("User or token not ready yet. Retrying...");
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
      SnackBar(content: Text(res?['message'] ?? 'Something went wrong')),
    );

    if (res?['status'] == 1) {
      _reasonController.clear();
      _audioPath = null;
      _leaveType = 'FULL DAY';
      _loadUnapprovedLeaves();
    }
  }

  Future<void> _cancelLeave(int id) async {
    setState(() => _loading = true);
    final res = await LeaveService().cancelLeave(id);
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res?['message'] ?? 'Error cancelling leave')),
    );
    if (res?['status'] == 1) _loadUnapprovedLeaves();
  }

  Future<void> _toggleRecording() async {
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
          setState(() {
            _currentAmplitude = amp.current;
          });
        });

        setState(() {
          _recording = true;
          _currentAmplitude = 0.0;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Leave Management')),
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
                    _buildApplyForm(colorScheme),
                    const SizedBox(height: 24),
                    const Text('Pending Leaves',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_pendingLeaves.isEmpty)
                      const Center(child: Text('No pending leaves')),
                    ..._pendingLeaves.map((l) => Card(
                          child: ListTile(
                            title: Text(
                              "From: ${l['leave_date_format'] ?? l['leave_date']}"
                              "${l['leave_enddate_format'] != null ? '\nTo: ${l['leave_enddate_format']}' : ''}",
                            ),
                            subtitle: Text(
                              "${l['leave_reason'] ?? ''}\nType: ${l['leave_type']}",
                            ),
                            trailing: TextButton(
                              onPressed: () => _cancelLeave(l['id']),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildApplyForm(ColorScheme colorScheme) {
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
              const Text('Apply for Leave',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _leaveType,
                decoration: const InputDecoration(labelText: 'Leave Type'),
                items: [
                  'FULL DAY',
                  'HALF MORNING',
                  'HALF AFTERNOON',
                  'MORE THAN ONE DAY'
                ]
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _leaveType = v ?? 'FULL DAY'),
              ),
              const SizedBox(height: 12),

              if (_leaveType == 'MORE THAN ONE DAY') ...[
                Row(
                  children: [
                    const Text('From: '),
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
                    const Text('To: '),
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
                    const Text('Date: '),
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
                decoration: const InputDecoration(labelText: 'Reason'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter reason' : null,
              ),
              const SizedBox(height: 16),

              // Audio Recorder Section
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _toggleRecording,
                    icon: Icon(_recording ? Icons.stop : Icons.mic),
                    label: Text(_recording ? 'Stop Recording' : 'Record Audio'),
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
                      const Text('Recording... Speak now!'),
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
                label: const Text('Submit Leave'),
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
