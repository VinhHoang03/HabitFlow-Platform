import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/form_validators.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _avatarController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  String? _loadedUserId;

  @override
  void dispose() {
    _nameController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final profile = authProvider.profile;
    final profileUserId = profile?.userId ?? user?.uid;

    if (profileUserId != null && _loadedUserId != profileUserId) {
      _loadedUserId = profileUserId;
      _nameController.text =
          profile?.name ??
          user?.displayName ??
          user?.email?.split('@').first ??
          '';
      _avatarController.text = profile?.avatar ?? user?.photoURL ?? '';
    }

    final avatar = _avatarController.text.trim();
    final canPreviewAvatar = _isValidHttpUrl(avatar);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 56,
                            backgroundImage: canPreviewAvatar
                                ? NetworkImage(avatar)
                                : null,
                            child: canPreviewAvatar
                                ? null
                                : const Icon(Icons.person, size: 56),
                          ),
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: IconButton.filled(
                              tooltip: 'Upload avatar',
                              onPressed: authProvider.isLoading
                                  ? null
                                  : _showAvatarSourceSheet,
                              icon: const Icon(Icons.photo_camera_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: authProvider.isLoading
                          ? null
                          : _showAvatarSourceSheet,
                      icon: authProvider.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Chọn ảnh avatar'),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Tên hiển thị',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: FormValidators.displayName,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: user?.email ?? profile?.email ?? '',
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: authProvider.isLoading
                          ? null
                          : () => _saveProfile(authProvider),
                      icon: authProvider.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Lưu profile'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: authProvider.isLoading ? null : () => authProvider.logout(),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      icon: const Icon(Icons.logout),
                      label: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAvatarSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Thư viện ảnh'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    await _pickAndUploadAvatar(source);
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 768,
      imageQuality: 85,
    );

    if (image == null || !mounted) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final avatarUrl = await authProvider.uploadAvatarImage(image);

    if (!mounted) {
      return;
    }

    if (avatarUrl == null) {
      _showSnackBar(
        authProvider.profileErrorMessage ?? 'Không thể upload avatar.',
      );
      return;
    }

    setState(() {
      _avatarController.text = avatarUrl;
    });

    await _saveProfile(authProvider, showSuccessMessage: false);

    if (mounted) {
      _showSnackBar('Avatar đã được cập nhật.');
    }
  }

  Future<void> _saveProfile(
    AuthProvider authProvider, {
    bool showSuccessMessage = true,
  }) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final avatarError = FormValidators.avatarUrl(_avatarController.text);
    if (avatarError != null) {
      _showSnackBar(avatarError);
      return;
    }

    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      avatar: _avatarController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (showSuccessMessage || !success) {
      _showSnackBar(
        success
            ? 'Cập nhật profile thành công.'
            : authProvider.profileErrorMessage ?? 'Không thể cập nhật profile.',
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isValidHttpUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}
