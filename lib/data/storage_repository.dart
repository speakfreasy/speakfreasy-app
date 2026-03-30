import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository();
});

class StorageRepository {
  final SupabaseClient _supabase = supabase;

  /// Upload hall avatar image from File
  /// Returns the public URL of the uploaded image
  Future<String> uploadHallAvatar(String hallId, File imageFile) async {
    final fileName = '$hallId.jpg';
    final path = 'avatars/$fileName';

    // Upload to hall-images bucket
    await _supabase.storage.from('hall-images').upload(
          path,
          imageFile,
          fileOptions: const FileOptions(
            upsert: true, // Overwrite if exists
            contentType: 'image/jpeg',
          ),
        );

    // Get public URL
    final publicUrl = _supabase.storage.from('hall-images').getPublicUrl(path);

    return publicUrl;
  }

  /// Upload hall avatar image from bytes (for web)
  /// Returns the public URL of the uploaded image
  Future<String> uploadHallAvatarBytes(String hallId, Uint8List imageBytes) async {
    final fileName = '$hallId.jpg';
    final path = 'avatars/$fileName';

    // Upload to hall-images bucket
    await _supabase.storage.from('hall-images').uploadBinary(
          path,
          imageBytes,
          fileOptions: const FileOptions(
            upsert: true, // Overwrite if exists
            contentType: 'image/jpeg',
          ),
        );

    // Get public URL
    final publicUrl = _supabase.storage.from('hall-images').getPublicUrl(path);

    return publicUrl;
  }

  /// Upload hall banner image from File
  /// Returns the public URL of the uploaded image
  Future<String> uploadHallBanner(String hallId, File imageFile) async {
    final fileName = '$hallId.jpg';
    final path = 'banners/$fileName';

    // Upload to hall-images bucket
    await _supabase.storage.from('hall-images').upload(
          path,
          imageFile,
          fileOptions: const FileOptions(
            upsert: true, // Overwrite if exists
            contentType: 'image/jpeg',
          ),
        );

    // Get public URL
    final publicUrl = _supabase.storage.from('hall-images').getPublicUrl(path);

    return publicUrl;
  }

  /// Upload hall banner image from bytes (for web)
  /// Returns the public URL of the uploaded image
  Future<String> uploadHallBannerBytes(String hallId, Uint8List imageBytes) async {
    final fileName = '$hallId.jpg';
    final path = 'banners/$fileName';

    // Upload to hall-images bucket
    await _supabase.storage.from('hall-images').uploadBinary(
          path,
          imageBytes,
          fileOptions: const FileOptions(
            upsert: true, // Overwrite if exists
            contentType: 'image/jpeg',
          ),
        );

    // Get public URL
    final publicUrl = _supabase.storage.from('hall-images').getPublicUrl(path);

    return publicUrl;
  }

  /// Delete hall avatar
  Future<void> deleteHallAvatar(String hallId) async {
    final path = 'avatars/$hallId.jpg';
    await _supabase.storage.from('hall-images').remove([path]);
  }

  /// Delete hall banner
  Future<void> deleteHallBanner(String hallId) async {
    final path = 'banners/$hallId.jpg';
    await _supabase.storage.from('hall-images').remove([path]);
  }

  /// Upload profile avatar (for user profiles)
  Future<String> uploadProfileAvatar(String userId, File imageFile) async {
    final fileName = '$userId.jpg';
    final path = 'avatars/$fileName';

    await _supabase.storage.from('profile-images').upload(
          path,
          imageFile,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    final publicUrl = _supabase.storage.from('profile-images').getPublicUrl(path);

    return publicUrl;
  }
}
