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
    final colorScheme = theme.colorScheme;

    final imageUrl = _profile?['is_profile_image'];
    ImageProvider<Object>? imageProvider;

    if (_pickedImage != null) {
      imageProvider = FileImage(_pickedImage!);
    } else if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      imageProvider = NetworkImage(imageUrl);
    } else {
      imageProvider = null;
    }

    return Card(
      color: colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 200,
                height: 250,
                color: colorScheme.primary.withOpacity(0.2),
                child: imageProvider != null
                    ? Image(
                        image: imageProvider,
                        width: 200,
                        height: 250,
                        fit: BoxFit.cover,
                      )
                    : Icon(Icons.person,
                        size: 60, color: colorScheme.onSurface),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profile?['name'] ?? '-',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Name
                  _buildDetailItem(
                      "Register No", _profile?['reg_no'] ?? '-', colorScheme),
                  const SizedBox(height: 8),

                  _buildDetailItem(
                      "Mobile", _profile?['mobile'] ?? '-', colorScheme),
                  const SizedBox(height: 8),

                  _buildDetailItem(
                      "Email", _profile?['email'] ?? '-', colorScheme),
                  const SizedBox(height: 8),

                  _buildDetailItem(
                      "State", _profile?['is_state_name'] ?? '-', colorScheme),
                  const SizedBox(height: 8),

                  _buildDetailItem("District",
                      _profile?['is_district_name'] ?? '-', colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // Widget _buildProfileHeader(ThemeData theme) {
  //   final imageUrl = _profile?['is_profile_image'];
  //   ImageProvider<Object>? imageProvider;

  //   if (_pickedImage != null) {
  //     imageProvider = FileImage(_pickedImage!);
  //   } else if (imageUrl != null && imageUrl.toString().isNotEmpty) {
  //     imageProvider = NetworkImage(imageUrl);
  //   } else {
  //     imageProvider = null;
  //   }

  //   return Column(
  //     children: [
  //       CircleAvatar(
  //         radius: 60,
  //         backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
  //         backgroundImage: imageProvider,
  //         child:
  //             imageProvider == null ? const Icon(Icons.person, size: 60) : null,
  //       ),
  //       const SizedBox(height: 10),
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           // TextButton.icon(
  //           //   onPressed: _pickImage,
  //           //   icon: const Icon(Icons.photo_camera),
  //           //   label: const Text('Change'),
  //           // ),
  //           // if (imageUrl != null && imageUrl.toString().isNotEmpty)
  //           //   TextButton.icon(
  //           //     onPressed: _deleteImage,
  //           //     icon: const Icon(Icons.delete, color: Colors.red),
  //           //     label: const Text('Remove'),
  //           //   ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
      ],
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
