import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme.dart';
import '../../../core/session/session_provider.dart';
import '../../../data/hall_repository.dart';
import '../../../data/storage_repository.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../hall_interior_screen.dart';
import '../halls_screen.dart';

/// Provider for hall data in settings screen
final hallSettingsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, hallId) async {
  final hallRepo = ref.read(hallRepositoryProvider);
  // We need to get hall by ID, but we only have getHallBySlug
  // For now, we'll invalidate when updating and refetch
  return null; // TODO: Add getHallById to repository
});

class HallSettingsScreen extends ConsumerStatefulWidget {
  final String hallId;
  final String slug;

  const HallSettingsScreen({
    super.key,
    required this.hallId,
    required this.slug,
  });

  @override
  ConsumerState<HallSettingsScreen> createState() => _HallSettingsScreenState();
}

class _HallSettingsScreenState extends ConsumerState<HallSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  bool _isUploadingBanner = false;
  String? _errorMessage;
  String? _successMessage;

  File? _avatarFile;
  File? _bannerFile;
  Uint8List? _avatarBytes;
  Uint8List? _bannerBytes;
  String? _currentAvatarUrl;
  String? _currentBannerUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadHallData() async {
    final hallRepo = ref.read(hallRepositoryProvider);
    final hall = await hallRepo.getHallBySlug(widget.slug);

    if (hall != null && mounted) {
      setState(() {
        _nameController.text = hall['name'] as String? ?? '';
        _bioController.text = hall['bio'] as String? ?? '';
        _descriptionController.text = hall['description'] as String? ?? '';
        _currentAvatarUrl = hall['avatar_url'] as String?;
        _currentBannerUrl = hall['banner_url'] as String?;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHallData();
  }

  Future<void> _pickImage(bool isAvatar) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: isAvatar ? 500 : 1920,
      maxHeight: isAvatar ? 500 : 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (isAvatar) {
          _avatarFile = kIsWeb ? null : File(pickedFile.path);
          _avatarBytes = bytes;
        } else {
          _bannerFile = kIsWeb ? null : File(pickedFile.path);
          _bannerBytes = bytes;
        }
      });
    }
  }

  Future<void> _uploadAvatar() async {
    if (_avatarBytes == null) return;

    final session = ref.read(sessionProvider);
    if (!session.isAuthenticated || session.userId == null) {
      setState(() => _errorMessage = 'You must be logged in to update the hall. Try signing out and back in, or refresh session.');
      return;
    }

    setState(() {
      _isUploadingAvatar = true;
      _errorMessage = null;
    });

    try {
      final storageRepo = ref.read(storageRepositoryProvider);
      final hallRepo = ref.read(hallRepositoryProvider);

      // Upload to storage (on web, we use bytes; on mobile, we use file)
      final avatarUrl = kIsWeb || _avatarFile == null
          ? await storageRepo.uploadHallAvatarBytes(widget.hallId, _avatarBytes!)
          : await storageRepo.uploadHallAvatar(widget.hallId, _avatarFile!);

      // Update database
      await hallRepo.updateHallAvatar(widget.hallId, avatarUrl);

      if (mounted) {
        setState(() {
          _successMessage = 'Avatar updated successfully!';
          _currentAvatarUrl = avatarUrl;
          _avatarFile = null;
          _avatarBytes = null;
        });
        // Invalidate providers to refresh UI elsewhere
        ref.invalidate(hallBySlugProvider(widget.slug));
        ref.invalidate(allHallsProvider);
        // Reload hall data
        await _loadHallData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to upload avatar: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _uploadBanner() async {
    if (_bannerBytes == null) return;

    final session = ref.read(sessionProvider);
    if (!session.isAuthenticated || session.userId == null) {
      setState(() => _errorMessage = 'You must be logged in to update the hall. Try signing out and back in, or refresh session.');
      return;
    }

    setState(() {
      _isUploadingBanner = true;
      _errorMessage = null;
    });

    try {
      final storageRepo = ref.read(storageRepositoryProvider);
      final hallRepo = ref.read(hallRepositoryProvider);

      // Upload to storage (on web, we use bytes; on mobile, we use file)
      final bannerUrl = kIsWeb || _bannerFile == null
          ? await storageRepo.uploadHallBannerBytes(widget.hallId, _bannerBytes!)
          : await storageRepo.uploadHallBanner(widget.hallId, _bannerFile!);

      // Update database
      await hallRepo.updateHallBanner(widget.hallId, bannerUrl);

      if (mounted) {
        setState(() {
          _successMessage = 'Banner updated successfully!';
          _currentBannerUrl = bannerUrl;
          _bannerFile = null;
          _bannerBytes = null;
        });
        // Invalidate providers to refresh UI elsewhere
        ref.invalidate(hallBySlugProvider(widget.slug));
        ref.invalidate(allHallsProvider);
        await _loadHallData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to upload banner: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingBanner = false;
        });
      }
    }
  }

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;

    final session = ref.read(sessionProvider);
    if (!session.isAuthenticated || session.userId == null) {
      setState(() => _errorMessage = 'You must be logged in to update the hall. Try signing out and back in, or refresh session.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final hallRepo = ref.read(hallRepositoryProvider);

      // Update hall details
      await hallRepo.updateHallDetails(
        hallId: widget.hallId,
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _successMessage = 'Hall details updated successfully!';
        });
        // Invalidate providers to refresh UI elsewhere
        ref.invalidate(hallBySlugProvider(widget.slug));
        ref.invalidate(allHallsProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update hall: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SFColors.black,
      appBar: AppBar(
        title: const Text('Hall Settings'),
        backgroundColor: SFColors.charcoal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success/Error Messages
              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SFColors.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SFColors.error),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: SFColors.error),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () async {
                          setState(() => _errorMessage = null);
                          ref.read(sessionProvider.notifier).refresh();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Session refreshed. Try uploading or saving again.')),
                            );
                          }
                        },
                        icon: const Icon(Icons.refresh, size: 18, color: SFColors.gold),
                        label: const Text('Refresh session & retry', style: TextStyle(color: SFColors.gold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Avatar Section
              SFCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hall Avatar',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: SFColors.charcoal,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SFColors.gold.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _avatarBytes != null
                            ? Image.memory(_avatarBytes!, fit: BoxFit.cover)
                            : _currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty
                                ? Image.network(
                                    _currentAvatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.image,
                                      color: SFColors.creamMuted,
                                      size: 40,
                                    ),
                                  )
                                : const Icon(
                                    Icons.image,
                                    color: SFColors.creamMuted,
                                    size: 40,
                                  ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SFButton(
                            label: 'Choose Image',
                            onPressed: () => _pickImage(true),
                            variant: SFButtonVariant.secondary,
                          ),
                        ),
                        if (_avatarBytes != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: SFButton(
                              label: 'Upload',
                              onPressed: _uploadAvatar,
                              isLoading: _isUploadingAvatar,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Banner Section
              SFCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hall Banner',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        color: SFColors.charcoal,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SFColors.gold.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _bannerBytes != null
                            ? Image.memory(_bannerBytes!, fit: BoxFit.cover)
                            : _currentBannerUrl != null && _currentBannerUrl!.isNotEmpty
                                ? Image.network(
                                    _currentBannerUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.panorama,
                                      color: SFColors.creamMuted,
                                      size: 40,
                                    ),
                                  )
                                : const Icon(
                                    Icons.panorama,
                                    color: SFColors.creamMuted,
                                    size: 40,
                                  ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SFButton(
                            label: 'Choose Image',
                            onPressed: () => _pickImage(false),
                            variant: SFButtonVariant.secondary,
                          ),
                        ),
                        if (_bannerBytes != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: SFButton(
                              label: 'Upload',
                              onPressed: _uploadBanner,
                              isLoading: _isUploadingBanner,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Details Section
              SFCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hall Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Hall Name',
                        hintText: 'The Jazz Lounge',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a hall name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Short Description',
                      ),
                      maxLength: 100,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Full Bio',
                      ),
                      maxLines: 4,
                      maxLength: 500,
                    ),
                    const SizedBox(height: 24),
                    SFButton(
                      label: 'Save Changes',
                      onPressed: _saveDetails,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
