import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';

final uploadServiceProvider = Provider<UploadService>((ref) => UploadService());

/// Credentials returned by the prepare-video-upload edge function.
class VideoUploadPrep {
  final String bunnyVideoId;
  final String libraryId;
  final String tusSignature;
  final int tusExpire;

  const VideoUploadPrep({
    required this.bunnyVideoId,
    required this.libraryId,
    required this.tusSignature,
    required this.tusExpire,
  });
}

class UploadService {
  /// Upload an image to Bunny Storage via the `upload-post-image` edge function.
  /// [hallId] is used to organise the file under `posts/{hallId}/` in the CDN.
  /// Returns the public CDN URL.
  Future<String> uploadPostImage(XFile imageFile, String hallId) async {
    final fileName = imageFile.name;
    final bytes = await imageFile.readAsBytes();

    final response = await supabase.functions.invoke(
      'upload-post-image',
      body: bytes,
      headers: {
        'x-file-name': fileName,
        'x-hall-id': hallId,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final url = data['url'] as String?;
    if (url == null) throw Exception('No URL in upload response');
    return url;
  }

  /// Call the `prepare-video-upload` edge function to create a Bunny Stream
  /// video entry and obtain short-lived TUS credentials.
  Future<VideoUploadPrep> prepareVideoUpload(String title, String hallId) async {
    final session = supabase.auth.currentSession;
    if (session == null) {
      throw Exception('Not authenticated — please sign in again');
    }
    final nowSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if ((session.expiresAt ?? 0) - nowSecs < 60) {
      await supabase.auth.refreshSession();
    }
    final accessToken = supabase.auth.currentSession!.accessToken;
    final response = await supabase.functions.invoke(
      'prepare-video-upload',
      body: {'title': title, 'hallId': hallId},
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final data = response.data as Map<String, dynamic>;
    return VideoUploadPrep(
      bunnyVideoId: data['bunnyVideoId'] as String,
      libraryId: data['libraryId'] as String,
      tusSignature: data['tusSignature'] as String,
      tusExpire: (data['tusExpire'] as num).toInt(),
    );
  }

  /// Upload a video file to Bunny Stream via the `upload-video-web` edge
  /// function, which proxies the bytes server-side to avoid CORS restrictions.
  /// [onProgress] receives values from 0.0 to 1.0.
  Future<void> uploadVideoToBunny({
    required XFile videoFile,
    required VideoUploadPrep uploadPrep,
    required String title,
    Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.1);
    final fileBytes = await videoFile.readAsBytes();
    onProgress?.call(0.3);

    final accessToken = supabase.auth.currentSession!.accessToken;
    final response = await supabase.functions.invoke(
      'upload-video-web',
      body: fileBytes,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'x-bunny-video-id': uploadPrep.bunnyVideoId,
        'x-bunny-library-id': uploadPrep.libraryId,
      },
    );

    onProgress?.call(1.0);

    final data = response.data;
    if (data is Map && data['error'] != null) {
      throw Exception('Bunny upload failed: ${data['error']}');
    }
  }
}
