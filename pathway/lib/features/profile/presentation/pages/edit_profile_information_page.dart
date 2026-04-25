import 'package:flutter/material.dart';
import 'package:pathway/core/theme/theme.dart';
import 'package:pathway/core/widgets/widgets.dart';
import 'package:pathway/features/profile/data/profile_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:pathway/core/services/accessibility_controller.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();

  }

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final _profileRepo = ProfileRepository();

  final Map<String, bool> _tags = {
    'Wheelchair user': false,
    'Deaf': false,
    'Hard of hearing': false,
    'Blind / low vision': false,
    'Neurodivergent': false,
  };

  XFile? _profileImage;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadProfilePhoto();
    _loadAccessibilityTags();
  }

  Future<void> _loadProfileData() async {
    final displayName = await _profileRepo.getDisplayName();
    if (mounted) {
      setState(() {
        _nameCtrl.text = displayName ?? '';
      });
    }
  }

  Future<void> _loadProfilePhoto() async {
    final url = await _profileRepo.getProfilePictureUrl();
    if (mounted && url != null) {
      setState(() {
        _profileImage = XFile(url);
      });
    }
  }

  Future<void> _loadAccessibilityTags() async {
    final tags = await _profileRepo.getUserAccessibilityTags();
    if (mounted && tags != null) {
      setState(() {
        for (final tag in _tags.keys) {
          _tags[tag] = tags.contains(tag);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    setState(() => _profileImage = file);
  }

  ImageProvider? _avatarProvider() {
    if (_profileImage == null) return null;
    if (kIsWeb) {
      return NetworkImage(_profileImage!.path);
    }

    if (_profileImage!.path.startsWith('http')) {
      return NetworkImage(_profileImage!.path);
    }

    return FileImage(File(_profileImage!.path));
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

      await _profileRepo.updateProfile(
        displayName: _nameCtrl.text.trim(),
        photo: _profileImage,
        tags: selectedTags,
        currentPassword: _currentPasswordCtrl.text,
        newPassword: _newPasswordCtrl.text,
      );

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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    final cardColor = a11y.highContrast ? Colors.white : cs.surface;
    final cardBorderColor = a11y.highContrast
      ? Colors.black
      : cs.outline.withValues(alpha: 0.18);

    final helperColor = a11y.highContrast
      ? Colors.black
      : cs.onSurface.withValues(alpha: 0.72);

    final titleColor = a11y.highContrast ? Colors.black : cs.onSurface;

    return Scaffold(
      appBar: PathwayAppBar(
        height: 100,
        centertitle: false,
        title: Padding(
          padding: EdgeInsets.only(top: 2),
          child: Text(
            'Edit profile information',  
            style: theme.appBarTheme.titleTextStyle,                 
            ),
          ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.page,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: a11y.highContrast
                          ? Colors.white
                          : cs.surfaceContainerHighest,
                      backgroundImage: _avatarProvider(),
                      child: _avatarProvider() == null
                          ? Icon(
                              Icons.person_rounded,
                              size: 44,
                              color: a11y.highContrast
                                  ? Colors.black
                                  : cs.onSurface.withValues(alpha: 0.7),
                            )
                          : null,
                    ),
                    Material(
                      shape: const CircleBorder(),
                      color: a11y.highContrast ? Colors.black : cs.primary,
                      child: IconButton(
                        icon: Icon(
                          Icons.camera_alt_rounded, 
                          color: a11y.highContrast ? Colors.white : cs.onPrimary, 
                          size: 18
                        ),
                        onPressed: _isSaving ? null : _pickProfilePhoto,
                        tooltip: 'Change profile photo',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Card(
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  side: BorderSide(
                    color: cardBorderColor,
                    width: a11y.highContrast ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Name',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                        ),
                        validator: (v) => _validateRequired(v, 'Display name'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  side: BorderSide(
                    color: cardBorderColor,
                    width: a11y.highContrast ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _currentPasswordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Current password',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newPasswordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New password (minimum 8 characters)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPasswordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm new password',
                        ),
                        validator: _validatePasswordConfirm,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Leave password fields blank to keep your current password',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: helperColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  side: BorderSide(
                    color: cardBorderColor,
                    width: a11y.highContrast ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accessibility tags',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.entries.map((entry) {
                          final label = entry.key;
                          final selected = entry.value;

                          final selectedColor = a11y.highContrast
                            ? Colors.black
                            : cs.primary;

                          final unselectedBorder = a11y.highContrast
                            ? Colors.black
                            : cs.primary.withValues(alpha: 0.35);

                          final unselectedBackground = a11y.highContrast
                            ? Colors.white
                            : cs.surface;

                          final unselectedText = a11y.highContrast
                            ? Colors.black
                            : cs.onSurface;

                          return FilterChip(
                            label: Text(label),
                            selected: selected,
                            selectedColor: selectedColor,
                            checkmarkColor: 
                              a11y.highContrast ? Colors.white : cs.onPrimary,
                            backgroundColor: unselectedBackground,
                            side: BorderSide(
                              color: selected ? selectedColor : unselectedBorder,
                              width: a11y.highContrast ? 1.5 : 1,
                            ),
                            labelStyle: theme.textTheme.bodySmall?.copyWith(
                              color: selected
                                ? (a11y.highContrast
                                  ? Colors.white
                                  : cs.primary)
                                : unselectedText,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: _isSaving
                              ? null
                              : (v) => setState(() => _tags[label] = v),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 8),
                      Text(
                        'Choose what you\'re comfortable sharing.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: helperColor,
                      ),
                      ),
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
                    backgroundColor:
                        a11y.highContrast ? Colors.black : cs.primary,
                    foregroundColor:
                        a11y.highContrast ? Colors.white : cs.onPrimary,
                  ),
                  child: _isSaving
                    ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: a11y.highContrast
                                ? Colors.white
                                : cs.onPrimary,
                        ),
                    )
                    : Text(
                        'Save changes', 
                        style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: a11y.highContrast
                                ? Colors.white
                                : cs.onPrimary,
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
}
