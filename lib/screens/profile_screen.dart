import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      setState(() => _pickedImage = file);

      final res = await ProfileService().updateProfileImage(file);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?['message'] ?? 'Image upload failed')),
      );
      if (res?['status'] == 1) _loadProfile();
    }
  }

  Future<void> _deleteImage() async {
    final res = await ProfileService().deleteProfileImage();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res?['message'] ?? 'Delete failed')),
    );
    if (res?['status'] == 1) _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileHeader(theme),
                    const SizedBox(height: 16),
                    _buildReadOnlyInfo(),
                    const Divider(height: 32),
                    _buildAlternateMobileForm(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    final imageUrl = _profile?['is_profile_image'];
    ImageProvider<Object>? imageProvider;

    if (_pickedImage != null) {
      imageProvider = FileImage(_pickedImage!);
    } else if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      imageProvider = NetworkImage(imageUrl);
    } else {
      imageProvider = null;
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          backgroundImage: imageProvider,
          child:
              imageProvider == null ? const Icon(Icons.person, size: 60) : null,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TextButton.icon(
            //   onPressed: _pickImage,
            //   icon: const Icon(Icons.photo_camera),
            //   label: const Text('Change'),
            // ),
            // if (imageUrl != null && imageUrl.toString().isNotEmpty)
            //   TextButton.icon(
            //     onPressed: _deleteImage,
            //     icon: const Icon(Icons.delete, color: Colors.red),
            //     label: const Text('Remove'),
            //   ),
          ],
        ),
      ],
    );
  }

  Widget _buildReadOnlyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoTile('Name', _profile?['name'] ?? '-'),
        _infoTile('Register No', _profile?['reg_no'] ?? '-'),
        _infoTile('Mobile', _profile?['mobile'] ?? '-'),
        _infoTile('Email', _profile?['email'] ?? '—'),
        _infoTile('State', _profile?['is_state_name'] ?? '-'),
        _infoTile('District', _profile?['is_district_name'] ?? '-'),
      ],
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 130,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              child:
                  Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildAlternateMobileForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _altMobileCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Alternate Mobile Number',
              prefixIcon: Icon(Icons.phone_android),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter alternate number';
              if (v.length < 8 || v.length > 10) return 'Enter valid number';
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _saving ? null : _updateAlternateMobile,
            icon: const Icon(Icons.save),
            label: Text(_saving ? 'Saving...' : 'Update Alternate Mobile'),
          ),
        ],
      ),
    );
  }
}
