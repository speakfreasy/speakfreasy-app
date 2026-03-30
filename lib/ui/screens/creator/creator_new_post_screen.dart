import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme.dart';
import '../../../data/post_repository.dart';
import '../../../data/upload_service.dart';
import '../../../core/session/session_provider.dart';

// Holds the post being edited — set before navigating, read in initState, then cleared.
// Using a provider avoids GoRouter's `extra` being dropped on router rebuilds.
final postBeingEditedProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

// Holds the hall ID to post to (set by subscribers before navigating).
// Creators leave this null and fall back to session.creatorHallId.
final hallBeingPostedToProvider = StateProvider<String?>((ref) => null);

class CreatorNewPostScreen extends ConsumerStatefulWidget {
  const CreatorNewPostScreen({super.key});

  @override
  ConsumerState<CreatorNewPostScreen> createState() => _CreatorNewPostScreenState();
}

class _CreatorNewPostScreenState extends ConsumerState<CreatorNewPostScreen> {
  final _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPinned = false;
  bool _isLoading = false;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Captured at init so they stay stable after we clear the providers
  Map<String, dynamic>? _editingPost;
  String? _hallId; // resolved once at init; used for both posting and image upload
  bool _isCreator = false;

  bool get _isEditing => _editingPost != null;

  @override
  void initState() {
    super.initState();

    _editingPost = ref.read(postBeingEditedProvider);
    final session = ref.read(sessionProvider);
    _isCreator = session.role == 'creator' || session.role == 'admin';

    // Resolve hall ID: subscriber sets hallBeingPostedToProvider; creators use their hall
    final overrideHallId = ref.read(hallBeingPostedToProvider);
    _hallId = overrideHallId ?? session.creatorHallId;

    if (_editingPost != null) {
      _bodyController.text = _editingPost!['body'] as String? ?? '';
      _isPinned = _editingPost!['pinned'] as bool? ?? false;
    }

    // Clear providers after reading so the next open starts fresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(postBeingEditedProvider.notifier).state = null;
      ref.read(hallBeingPostedToProvider.notifier).state = null;
    });
  }

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _post() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final postRepo = ref.read(postRepositoryProvider);

      if (_isEditing) {
        await postRepo.updatePost(
          postId: _editingPost!['id'] as String,
          body: _bodyController.text.trim(),
          pinned: _isPinned,
        );
      } else {
        if (_hallId == null) {
          throw Exception('No hall found — are you subscribed?');
        }

        // Upload image to Bunny Storage first (if one was selected)
        String? imageUrl;
        if (_selectedImage != null) {
          imageUrl = await ref
              .read(uploadServiceProvider)
              .uploadPostImage(_selectedImage!, _hallId!);
        }

        final post = await postRepo.createPost(
          hallId: _hallId!,
          scope: 'hall',
          body: _bodyController.text.trim(),
          pinned: _isPinned,
        );

        // Attach the image to the post via post_media
        if (imageUrl != null) {
          await postRepo.createPostMedia(
            postId: post['id'] as String,
            url: imageUrl,
          );
        }
      }

      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Post updated' : 'Post created')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: SFColors.black,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(_isEditing ? 'Edit Post' : 'New Post'),
        backgroundColor: SFColors.charcoal,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _post,
              style: ElevatedButton.styleFrom(
                backgroundColor: SFColors.gold,
                foregroundColor: SFColors.black,
                disabledBackgroundColor: SFColors.gold.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SFColors.black,
                      ),
                    )
                  : Text(
                      _isEditing ? 'Save' : 'Post',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Text area + image preview
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _bodyController,
                      autofocus: true,
                      maxLines: null,
                      minLines: 6,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: "What's on your mind?",
                        border: InputBorder.none,
                        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: SFColors.creamMuted,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter some content';
                        }
                        return null;
                      },
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Image.network(
                              _selectedImage!.path,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: SFColors.black.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: SFColors.cream,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Toolbar — sits just above the keyboard
            Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                decoration: BoxDecoration(
                  color: SFColors.charcoal,
                  border: Border(
                    top: BorderSide(color: SFColors.border, width: 1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image_outlined),
                      color: SFColors.gold,
                      tooltip: 'Add image',
                      onPressed: _pickImage,
                    ),
                    const Spacer(),
                    // Pin is a creator-only privilege
                    if (_isCreator)
                      IconButton(
                        icon: Icon(
                          _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        ),
                        color: _isPinned ? SFColors.gold : SFColors.creamMuted,
                        tooltip: _isPinned ? 'Unpin post' : 'Pin post',
                        onPressed: () => setState(() => _isPinned = !_isPinned),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
