import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class DecryptService {
  final String _serverUrl;

  DecryptService({String? serverUrl}) : _serverUrl = dotenv.env['SERVER_URL']!;

  Future<String> decryptVideo(File videoFile) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_serverUrl/decrypt'),
      );

      // Add video file to request
      request.files.add(
        await http.MultipartFile.fromPath('video', videoFile.path),
      );

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['stego_data'] ?? data['border_data'];
      } else {
        throw Exception('Failed to decrypt video: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error decrypting video: $e');
    }
  }
}
