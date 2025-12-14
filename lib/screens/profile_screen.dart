import 'dart:io';
import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _altMobileCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? _profile;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final res = await ProfileService().getProfileDetails();

    if (res != null && res['status'] == 1) {
      final data = res['data'];
      setState(() {
        _profile = data;
        _altMobileCtrl.text = data['mobile1'] ?? '';
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _updateAlternateMobile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final res = await ProfileService()
        .updateAlternateMobile(mobile1: _altMobileCtrl.text.trim());
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res?['message'] ?? 'Update failed')),
    );

    if (res?['status'] == 1) _loadProfile();
  }

  // ---------------- CHANGE PASSWORD ----------------

  void _showChangePasswordDialog() {
    final pass1 = TextEditingController();
    final pass2 = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Change Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pass1,
                obscureText: true,
                decoration: const InputDecoration(labelText: "New Password"),
              ),
              TextField(
                controller: pass2,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: "Confirm Password"),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Save"),
              onPressed: () async {
                final p1 = pass1.text.trim();
                final p2 = pass2.text.trim();

                if (p1.isEmpty || p2.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enter password")),
                  );
                  return;
                }
                if (p1 != p2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Passwords do not match")),
                  );
                  return;
                }

                Navigator.pop(context);

                final res = await ProfileService().changePassword(p1);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res?['message'] ?? "Failed")),
                );

                if (res?['status'] == 1) {
                  _loadProfile();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.profile)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileHeader(colorScheme),
                    const SizedBox(height: 16),

                    Card(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildReadOnlyInfo(colorScheme, t),
                      ),
                    ),

                    const SizedBox(height: 24),
                    _buildAlternateMobileForm(colorScheme, t),

                    const SizedBox(height: 24),

                    // Change Password Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _showChangePasswordDialog,
                        child: const Text(
                          "Change Password",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: widget.onLogout,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              t.logout,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(ColorScheme colorScheme) {
    final imageUrl = _profile?['is_profile_image'];
    ImageProvider<Object>? imageProvider;

    if (_pickedImage != null) {
      imageProvider = FileImage(_pickedImage!);
    } else if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      imageProvider = NetworkImage(imageUrl);
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? Icon(Icons.person, size: 60, color: colorScheme.onSurface)
              : null,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildReadOnlyInfo(ColorScheme colorScheme, AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoTile(t.name, _profile?['name'] ?? '-', colorScheme),
        _infoTile(t.registerNo, _profile?['reg_no'] ?? '-', colorScheme),
        _infoTile(t.mobile, _profile?['mobile'] ?? '-', colorScheme),
        _infoTile(t.email, _profile?['email'] ?? '—', colorScheme),
        _infoTile(t.state, _profile?['is_state_name'] ?? '-', colorScheme),
        _infoTile(
            t.district, _profile?['is_district_name'] ?? '-', colorScheme),
      ],
    );
  }

  Widget _infoTile(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternateMobileForm(
      ColorScheme colorScheme, AppLocalizations t) {
    return Card(
      color: colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _altMobileCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: t.alternateMobileNumber,
                  labelStyle:
                      TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                  prefixIcon: Icon(
                    Icons.phone_android,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return t.enterAlternateNumber;
                  if (v.length < 8 || v.length > 10) return t.enterValidNumber;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _saving ? null : _updateAlternateMobile,
                  icon: const Icon(Icons.save),
                  label: Text(_saving ? t.saving : t.updateAlternateMobile),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
