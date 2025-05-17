import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Sends the video file and text to the /encrypt endpoint.
/// Returns a Map with response data (e.g., mp4, mp4_filename) or throws on error.
Future<Map<String, dynamic>> sendVideoForEncryption({
  required File videoFile,
  required String text,
  required String apiUrl, // e.g., 'http://<server-ip>:<port>/encrypt'
}) async {
  final uri = Uri.parse(apiUrl);
  final request = http.MultipartRequest('POST', uri)
    ..fields['text'] = text
    ..files.add(await http.MultipartFile.fromPath('video', videoFile.path));

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    throw Exception('Failed to encrypt: \\${response.body}');
  }
}
