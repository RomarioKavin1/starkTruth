import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient client;

  Future<void> initialize() async {
    await dotenv.load();
    await Supabase.initialize(
      url: "https://qweqeisblbwskwxhlstg.supabase.co",
      anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3ZXFlaXNibGJ3c2t3eGhsc3RnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgxODY1NjIsImV4cCI6MjA2Mzc2MjU2Mn0.3WrxN88VMb4Y41kd8ZOWY6SsZAEM5c-LYqJ51XmTRY4",
    );
    var anon=dotenv.env['SUPABASE_ANON_KEY']??"";
    print(dotenv.env['SUPABASE_URL']  );
    print("key  ");
    print(anon);
    client = Supabase.instance.client;
  }

  // User Profile Operations
  Future<Map<String, dynamic>?> getUserProfile(String walletAddress) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('wallet_address', walletAddress)
          .single();
      return response;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // No rows found
        return null;
      }
      rethrow;
    }
  }

  Future<void> createUserProfile(String walletAddress) async {
    await client.from('profiles').insert({
      'wallet_address': walletAddress,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Feed Operations
  Future<List<Map<String, dynamic>>> getFeed() async {
    final response = await client
        .from('posts')
        .select('*, profiles(*)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // User Videos Operations
  Future<List<Map<String, dynamic>>> getUserVideos(String walletAddress) async {
    final response = await client
        .from('posts')
        .select()
        .eq('wallet_address', walletAddress)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Post Operations
  Future<void> createPost({
    required String walletAddress,
    required String videoUrl,
    required String encryptedContent,
  }) async {
    await client.from('posts').insert({
      'wallet_address': walletAddress,
      'video_url': videoUrl,
      'encrypted_content': encryptedContent,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Video Storage
  Future<String> uploadVideo(String filePath, String fileName) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    await client.storage
        .from('videos')
        .uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));
    return client.storage.from('videos').getPublicUrl(fileName);
  }

  // Encrypt video using external API
  Future<File> encryptVideo(File videoFile, String description) async {
    final uri = Uri.parse('http://10.0.2.2:5000/encrypt'); // TODO: Replace with your actual API URL
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('video', videoFile.path))
      ..fields['text'] = description;

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final jsonResp = json.decode(respStr);
      final mp4Base64 = jsonResp['mp4'];
      final mp4Filename = jsonResp['mp4_filename'] ?? 'encrypted.mp4';

      // Save the encrypted video to a temp file
      final bytes = base64Decode(mp4Base64);
      final tempDir = Directory.systemTemp;
      final encryptedFile = File('${tempDir.path}/$mp4Filename');
      await encryptedFile.writeAsBytes(bytes);
      return encryptedFile;
    } else {
      throw Exception('Failed to encrypt video');
    }
  }

  // Like a post (by id)
  Future<void> likePost(String postId) async {
    // Get current likes
    final response = await client
        .from('posts')
        .select('likes')
        .eq('id', postId)
        .single();
    final currentLikes = (response['likes'] ?? 0) as int;
    await client
        .from('posts')
        .update({'likes': currentLikes + 1})
        .eq('id', postId);
  }

  // Add a comment to a post
  Future<void> addComment(String postId, String comment, String walletAddress) async {
    await client.from('comments').insert({
      'post_id': postId,
      'wallet_address': walletAddress,
      'comment': comment,
      'created_at': DateTime.now().toIso8601String(),
    });
    // Get current comments count
    final response = await client
        .from('posts')
        .select('comments')
        .eq('id', postId)
        .single();
    final currentComments = (response['comments'] ?? 0) as int;
    await client
        .from('posts')
        .update({'comments': currentComments + 1})
        .eq('id', postId);
  }

  // Fetch comments for a post
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    final response = await client
        .from('comments')
        .select('*, profiles!inner(wallet_address, id)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }
} 