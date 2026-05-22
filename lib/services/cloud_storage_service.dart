import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class CloudStorageService {
  static const String baseUrl = 'https://mckxjaonicxqhugjiztv.supabase.co/functions/v1/storage-api';

  /// Upload audio bytes and return the public URL
  Future<String?> uploadAudioBytes(Uint8List audioBytes, String fileName) async {
    try {
      var uri = Uri.parse('$baseUrl/upload');
      var request = http.MultipartRequest('POST', uri);
      
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        audioBytes,
        filename: fileName,
      ));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = jsonDecode(responseData);
      
      if (data['success'] == true && data['data'] != null) {
        return data['data']['public_url'] as String?;
      }
      debugPrint('Upload failed: $responseData');
      return null;
    } catch (e) {
      debugPrint('Error uploading audio: $e');
      return null;
    }
  }

  /// Delete a file by ID
  Future<bool> deleteFile(String fileId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$fileId'));
      final data = jsonDecode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }
}
