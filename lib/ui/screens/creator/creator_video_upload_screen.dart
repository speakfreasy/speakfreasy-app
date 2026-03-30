import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme.dart';
import '../../../core/session/session_provider.dart';
import '../../../data/upload_service.dart';
import '../../../data/video_repository.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';

class CreatorVideoUploadScreen extends ConsumerStatefulWidget {
  const CreatorVideoUploadScreen({super.key});

  @override
  ConsumerState<CreatorVideoUploadScreen> createState() => _CreatorVideoUploadScreenState();
}

class _CreatorVideoUploadScreenState extends ConsumerState<CreatorVideoUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  XFile? _videoFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _videoFile = pickedFile;
        _errorMessage = null;
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (!_formKey.currentState!.validate() || _videoFile == null) {
      setState(() {
        _errorMessage = 'Please select a video and fill in all fields';
      });
      return;
    }

    final session = ref.read(sessionProvider);
    if (session.creatorHallId == null) {
      setState(() {
        _errorMessage = 'No hall found for creator';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    String? supabaseVideoId;

    try {
      final uploadService = ref.read(uploadServiceProvider);
      final videoRepo = ref.read(videoRepositoryProvider);

      // Step 1: Get TUS credentials from edge function (also creates Bunny entry)
      final uploadPrep = await uploadService.prepareVideoUpload(title, session.creatorHallId!);

      // Step 2: Create the Supabase video record with status 'uploading'
      final video = await videoRepo.createVideoRecord(
        hallId: session.creatorHallId!,
        title: title,
        description: description.isEmpty ? null : description,
        bunnyVideoId: uploadPrep.bunnyVideoId,
        bunnyLibraryId: uploadPrep.libraryId,
      );
      supabaseVideoId = video['id'] as String;

      // Step 3: Upload video to Bunny Stream via TUS
      await uploadService.uploadVideoToBunny(
        videoFile: _videoFile!,
        uploadPrep: uploadPrep,
        title: title,
        onProgress: (progress) {
          if (mounted) setState(() => _uploadProgress = progress);
        },
      );

      // Step 4: Mark video as published
      await videoRepo.updateVideoStatus(supabaseVideoId, 'published');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      // Clean up the Supabase record if upload failed after it was created
      if (supabaseVideoId != null) {
        try {
          await ref
              .read(videoRepositoryProvider)
              .updateVideoStatus(supabaseVideoId, 'uploading');
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _errorMessage = 'Upload failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SFColors.black,
      appBar: AppBar(
        title: const Text('Upload Video'),
        backgroundColor: SFColors.charcoal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isUploading ? null : () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SFColors.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SFColors.error),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: SFColors.error),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Video Picker
              SFCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Video File',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (_videoFile != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: SFColors.charcoal,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.video_file, color: SFColors.gold),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _videoFile!.name,
                                style: Theme.of(context).textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SFButton(
                      label: _videoFile == null ? 'Select Video' : 'Change Video',
                      onPressed: _isUploading ? null : _pickVideo,
                      variant: SFButtonVariant.secondary,
                      icon: Icons.video_library,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Video Details
              SFCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Video Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter video title',
                      ),
                      enabled: !_isUploading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter video description',
                      ),
                      maxLines: 4,
                      enabled: !_isUploading,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Upload Progress
              if (_isUploading) ...[
                SFCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uploading...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: SFColors.charcoal,
                        valueColor: const AlwaysStoppedAnimation<Color>(SFColors.gold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_uploadProgress * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Upload Button
              SFButton(
                label: 'Upload Video',
                onPressed: _isUploading ? null : _uploadVideo,
                isLoading: _isUploading,
                icon: Icons.upload,
              ),

              const SizedBox(height: 16),

              // Info Card
              SFCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: SFColors.gold, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Video Upload Info',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Videos are hosted on Bunny.net CDN\n'
                      '• Supported formats: MP4, MOV, AVI\n'
                      '• Maximum file size: 5GB\n'
                      '• Processing may take a few minutes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SFColors.creamMuted,
                      ),
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
