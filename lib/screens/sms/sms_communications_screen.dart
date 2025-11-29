import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:school_dashboard/services/sms_service.dart';
import 'package:school_dashboard/services/notification_service.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';

class SmsCommunicationsScreen extends StatefulWidget {
  const SmsCommunicationsScreen({super.key});

  @override
  State<SmsCommunicationsScreen> createState() =>
      _SmsCommunicationsScreenState();
}

class _SmsCommunicationsScreenState extends State<SmsCommunicationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _smsList = [];
  List<dynamic> _filteredList = [];

  bool _loading = true;

  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  dynamic _selectedCategory;
  String _selectedType = "All";

  late Box settingsBox;

  final FlutterTts _flutterTts = FlutterTts();
  String _currentReadText = "";
  bool _isPaused = false;
  bool _isSpeaking = false;
  String _activeWord = "";
  ScrollController _readScroll = ScrollController();

  @override
  void initState() {
    super.initState();

    settingsBox = Hive.box('settings');
    _loadSMS();

    _flutterTts.setProgressHandler((text, start, end, word) {
      setState(() => _activeWord = word);
      _autoScrollToWord(word);
    });

    settingsBox.watch(key: 'user').listen((_) {
      if (mounted) _loadSMS();
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _searchController.dispose();
    super.dispose();
  }

  void _autoScrollToWord(String word) {
    if (word.isEmpty) return;
    final content = _currentReadText;

    final index = content.indexOf(word);
    if (index == -1) return;

    double ratio = index / content.length;
    double offset = ratio * _readScroll.position.maxScrollExtent;

    _readScroll.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _readAloud(String text) async {
    _currentReadText = text;
    _isPaused = false;

    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setPitch(1.0);

    setState(() => _isSpeaking = true);

    await _flutterTts.speak(text);
  }

  Future<void> _pauseReading() async {
    var result = await _flutterTts.pause();
    if (result == 1) {
      setState(() {
        _isPaused = true;
        _isSpeaking = false;
      });
    }
  }

  Future<void> _resumeReading() async {
    await _readAloud(_currentReadText);
  }

  Future<void> _stopReading() async {
    await _flutterTts.stop();
    setState(() {
      _isPaused = false;
      _isSpeaking = false;
    });
  }

  Future<void> _restartReading() async {
    await _flutterTts.stop();
    await _readAloud(_currentReadText);
  }

  Future<void> _loadSMS() async {
    setState(() => _loading = true);

    try {
      final data = await SmsService().getSMSCommunications();

      setState(() {
        _smsList = data;
        _filteredList = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load SMS: $e")),
      );
    }
  }

  void _filterSearch(String query) {
    final filtered = _smsList.where((n) {
      final title = (n['title'] ?? '').toString().toLowerCase();
      final category = (n['post_category'] ?? '').toString().toLowerCase();
      final message =
          html_parser.parse(n['message'] ?? '').body?.text.toLowerCase() ?? '';

      return title.contains(query.toLowerCase()) ||
          category.contains(query.toLowerCase()) ||
          message.contains(query.toLowerCase());
    }).toList();

    setState(() => _filteredList = filtered);
  }

  TextSpan _buildHighlightedText(String fullText) {
    final words = fullText.split(" ");

    return TextSpan(
      children: words.map((w) {
        final isActive =
            w.trim().toLowerCase() == _activeWord.trim().toLowerCase();

        return TextSpan(
          text: "$w ",
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? Colors.blue : Colors.black,
          ),
        );
      }).toList(),
    );
  }

  Color _getDefaultBgColor(String type) {
    switch (type.toLowerCase()) {
      case "attendance":
        return Colors.amber.shade200;

      case "birthday":
      case "birthday wish":
        return Colors.pink.shade200;

      default:
        return Colors.blue.shade200;
    }
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.smsTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surfaceContainerHighest
                                .withOpacity(0.3)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterSearch,
                        decoration: InputDecoration(
                          hintText: t.searchNotifications,
                          prefixIcon: const Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: _openFilterModal,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadSMS,
                      child: _filteredList.isEmpty
                          ? const Center(child: Text("No SMS Found"))
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredList.length,
                              itemBuilder: (context, index) {
                                final n = _filteredList[index];
                                return _buildSmsCard(n, colorScheme);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFilterModal() async {
    DateTime? fromDate = _selectedFromDate;
    DateTime? toDate = _selectedToDate;
    dynamic selectedCategory = _selectedCategory;
    String selectedType = _selectedType;

    final t = AppLocalizations.of(context)!;

    List<dynamic> categories = [];
    bool loading = true;
    String? errorMessage;

    try {
      categories = await NotificationService().getCategories();
      loading = false;

      if (selectedCategory != null) {
        final match = categories.where(
            (cat) => cat['id'].toString() == selectedCategory['id'].toString());

        selectedCategory = match.isNotEmpty ? match.first : null;
      }
    } catch (e) {
      loading = false;
      errorMessage = e.toString();
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            if (!loading && selectedCategory != null) {
              final match = categories.where((cat) =>
                  cat['id'].toString() == selectedCategory['id'].toString());
              selectedCategory = match.isNotEmpty ? match.first : null;
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      t.filterNotification,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text(t.fromDate),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fromDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setModalState(() => fromDate = picked);
                        }
                      },
                      child: _buildDateBox(isDark, colorScheme, fromDate, t),
                    ),
                    const SizedBox(height: 20),
                    Text(t.toDate),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: toDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setModalState(() => toDate = picked);
                        }
                      },
                      child: _buildDateBox(isDark, colorScheme, toDate, t),
                    ),
                    const SizedBox(height: 20),
                    Text(t.category),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<dynamic>(
                          value: selectedCategory,
                          isExpanded: true,
                          hint: Text(
                            loading
                                ? "Loading categories..."
                                : errorMessage ?? "Select category",
                          ),
                          onChanged: loading
                              ? null
                              : (value) =>
                                  setModalState(() => selectedCategory = value),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text("All")),
                            ...categories.map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat['name'] ?? "Unnamed"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(t.type),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedType,
                          isExpanded: true,
                          onChanged: (value) => setModalState(
                              () => selectedType = value ?? "All"),
                          items: const [
                            DropdownMenuItem(value: "All", child: Text("All")),
                            DropdownMenuItem(
                                value: "SMS Communication",
                                child: Text("SMS Communication")),
                            DropdownMenuItem(
                                value: "Attendance", child: Text("Attendance")),
                            DropdownMenuItem(
                                value: "Birthday Wish",
                                child: Text("Birthday Wish")),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                _selectedFromDate = null;
                                _selectedToDate = null;
                                _selectedCategory = null;
                                _selectedType = "All";
                              });
                              _loadSMS();
                            },
                            child: Text(t.clearFilter),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            child: Text(t.applyFilter),
                            onPressed: () async {
                              Navigator.pop(context);
                              setState(() {
                                _selectedFromDate = fromDate;
                                _selectedToDate = toDate;
                                _selectedCategory = selectedCategory;
                                _selectedType = selectedType;
                              });
                              await _applyFilter();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(t.cancel),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDateBox(
    bool isDark,
    ColorScheme colorScheme,
    DateTime? date,
    AppLocalizations t,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? Colors.grey[800] : Colors.grey[200],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            date != null
                ? "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}"
                : t.selectDate,
          ),
          const Icon(Icons.calendar_today, size: 18),
        ],
      ),
    );
  }

  Future<void> _applyFilter() async {
    setState(() => _loading = true);

    try {
      final data = await SmsService().getSMSCommunications(
        fromDate: _selectedFromDate,
        toDate: _selectedToDate,
        category: _selectedCategory,
        type: _selectedType == "All" ? "" : _selectedType,
        search: _searchController.text.trim(),
      );

      setState(() {
        _smsList = data;
        _filteredList = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _buildSmsCard(dynamic n, ColorScheme colorScheme) {
    final title = n['title'] ?? 'Untitled';
    final rawMsg = n['message'] ?? '';
    final message = html_parser.parse(rawMsg).body?.text.trim() ?? '';
    final category = n['post_category'] ?? 'General';
    final smsType = n['sms_type'] ?? 'SMS Communication';

    final categoryTextColor =
        n['is_category_text_color'] != null && n['is_category_text_color'] != ""
            ? _hexToColor(n['is_category_text_color'])
            : Colors.black;

    final bgImage = n['post_theme']?['is_image'];
    final bgColor =
        bgImage == null ? _getDefaultBgColor(smsType) : Colors.transparent;

    final formattedTime = n['is_notify_datetime'] ?? '';

    return VisibilityDetector(
      key: Key("sms_${n['id']}"),
      onVisibilityChanged: (info) {},
      child: Card(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryTextColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: categoryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 340,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  image: bgImage != null
                      ? DecorationImage(
                          image: NetworkImage(bgImage),
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        )
                      : null,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      16, bgImage != null ? 100 : 16, 16, 16),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _readScroll,
                          physics: const BouncingScrollPhysics(),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: _buildHighlightedText(message),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.volume_up),
                            onPressed: () => _readAloud(message),
                          ),
                          IconButton(
                            icon: const Icon(Icons.pause),
                            onPressed: _isSpeaking ? _pauseReading : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: _isPaused ? _resumeReading : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.stop),
                            onPressed:
                                _isSpeaking || _isPaused ? _stopReading : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _currentReadText.isNotEmpty
                                ? _restartReading
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
