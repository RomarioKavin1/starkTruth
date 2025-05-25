
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final SupabaseClient _supabase;
  final String _bucketName;

  StorageService({
    required SupabaseClient supabase,
    String bucketName = 'uploads',
  })  : _supabase = supabase,
        _bucketName = bucketName;

  /// Upload a file to Supabase Storage
  /// Returns the public URL of the uploaded file
  Future<String> uploadFile({
    required File file,
    String? customPath,
    Map<String, String>? metadata,
  }) async {
    try {
      final fileName = path.basename(file.path);
      final fileExt = path.extension(fileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';
      
      // Construct the storage path
      final storagePath = customPath != null 
          ? '$customPath/$uniqueFileName'
          : uniqueFileName;

      // Upload the file
      final response = await _supabase
          .storage
          .from(_bucketName)
          .upload(
            storagePath,
            file,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              metadata: metadata,
            ),
          );

      // Get the public URL
      final publicUrl = _supabase
          .storage
          .from(_bucketName)
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Delete a file from Supabase Storage
  Future<void> deleteFile(String filePath) async {
    try {
      await _supabase
          .storage
          .from(_bucketName)
          .remove([filePath]);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Get a signed URL for a file (temporary access)
  Future<String> getSignedUrl(String filePath, {int expiresIn = 3600}) async {
    try {
      final response = await _supabase
          .storage
          .from(_bucketName)
          .createSignedUrl(filePath, expiresIn);
      
      return response;
    } catch (e) {
      throw Exception('Failed to get signed URL: $e');
    }
  }

  /// List files in a directory
  Future<List<FileObject>> listFiles({String? directory}) async {
    try {
      final response = await _supabase
          .storage
          .from(_bucketName)
          .list(path: directory);
      
      return response;
    } catch (e) {
      throw Exception('Failed to list files: $e');
    }
  }
} 