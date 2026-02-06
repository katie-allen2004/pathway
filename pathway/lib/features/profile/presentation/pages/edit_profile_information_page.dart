import 'package:flutter/material.dart';
import 'package:pathway/core/theme/app_theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();

  }

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  final Map<String, bool> _tags = {
    'Wheelchair user': false,
    'Deaf': false,
    'Hard of hearing': false,
    'Blind / low vision': false,
    'Neurodivergent': false,
  };

  ImageProvider? _profileImage;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // TODO: preload from user profile
    // ex:
    // _firstNameCtrl.text = profile.firstName;
    // _lastNameCtrl.text = profile.lastName;
    // _profileImage = NetworkImage(profile.avatarUrl);
    _firstNameCtrl.text = 'John';
    _lastNameCtrl.text = 'Doe';
    _profileImage = const AssetImage('');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    // TODO: wire this with image_picker later
    // final picker = ImagePicker();
    // final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    // if (file == null) return;
    // setState(() => _profileImage = FileImage(File(file.path)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TODO: add image picker')),
    );
  }

  String? _validateRequired(String? v, String field) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  String? _validatePasswordConfirm(String? v) {
    if (_newPasswordCtrl.text.trim().isEmpty &&
        _confirmPasswordCtrl.text.trim().isEmpty) {
          return null;
        }
    if (_newPasswordCtrl.text.trim().length < 8) {
      return 'New password must be at least 8 characters';
    }
    if (_confirmPasswordCtrl.text.trim() != _newPasswordCtrl.text.trim()) {
      return 'Passwords do not match';
    }
    if (_currentPasswordCtrl.text.trim().isEmpty) {
      return 'Enter your current password to change it';
    }
    return null;
  }

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _isSaving = true);

    try {
      final selectedTags = _tags.entries
      .where((e) => e.value)
      .map((e) => e.key)
      .toList();

      // TODO: call API
      // await profileService.updateProfile(
      // firstName: _firstNameCtrl.text.trim(),
      // lastName: _lastNameCtrl.text.trim(),
      // tags: selectedTags,
      // // photo: ...,
      // );
      //
      // if (_newPasswordCtrl.text.trim().isNotEmpty) {
      //  await profileService.changePassword(
      //    currentPassword: _currentPasswordCtrl.text.trim(),
      //    newPassword: _newPasswordCtrl.text.trim(),
      //  );
      // }

      await Future.delayed(const Duration(milliseconds: 400)); // remove ltr

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.of(context).pop(true);
    } catch(e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PathwayAppBar(
        height: 100,
        centertitle: false,
        title: Padding(
          padding: EdgeInsets.only(top: 2),
          child: Text(
                    'Edit profile information',
                    
                  ),
            ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundImage: _profileImage,
                    ),
                    Material(
                      shape: const CircleBorder(),
                      color: const Color.fromARGB(255, 76, 89, 185),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                        onPressed: _isSaving ? null : _pickProfilePhoto,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Name', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _firstNameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => _validateRequired(v, 'First name'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lastNameCtrl,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Last name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => _validateRequired(v, 'Last name'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Password', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _currentPasswordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Current password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newPasswordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New password (minimum 8 characters)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPasswordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm new password',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validatePasswordConfirm,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Leave password fields blank to keep your current password',
                        style: TextStyle(fontSize: 12, color: Colors.black54),

                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Accessibility tags', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.entries.map((entry) {
                          final label = entry.key;
                          final selected = entry.value;
                          return FilterChip(
                            label: Text(label),
                            selected: selected,
                            onSelected: _isSaving
                              ? null
                              : (v) => setState(() => _tags[label] = v),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 8),
                      const Text(
                        'Choose what youre comfortable sharing.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      )
                    ],
                  ),
                ),
              ),


              const SizedBox(height: 20),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 76, 89, 185),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Save changes', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
