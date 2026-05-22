import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

enum UploadFileType { image, pdf, audio }

class UploadResult {
  final bool success;
  final String? url;
  final String? error;

  UploadResult({required this.success, this.url, this.error});
}

/// AWS Signature v4 for Cloudflare R2
class R2Signer {
  final String accessKey;
  final String secretKey;
  final String region;
  final String service;

  R2Signer({
    required this.accessKey,
    required this.secretKey,
    this.region = 'auto',
    this.service = 's3',
  });

  Map<String, String> signRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required Uint8List payload,
  }) {
    final now = DateTime.now().toUtc();
    final dateStamp = _formatDate(now);
    final amzDate = _formatAmzDate(now);

    // Add required headers
    final signedHeaders = Map<String, String>.from(headers);
    signedHeaders['x-amz-date'] = amzDate;
    signedHeaders['x-amz-content-sha256'] = _hexEncode(sha256.convert(payload).bytes);
    signedHeaders['host'] = uri.host;

    // Create canonical request
    final canonicalHeaders = _getCanonicalHeaders(signedHeaders);
    final signedHeadersList = _getSignedHeadersList(signedHeaders);
    
    final canonicalRequest = [
      method,
      uri.path,
      uri.query,
      canonicalHeaders,
      '',
      signedHeadersList,
      signedHeaders['x-amz-content-sha256']!,
    ].join('\n');

    // Create string to sign
    final credentialScope = '$dateStamp/$region/$service/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      _hexEncode(sha256.convert(utf8.encode(canonicalRequest)).bytes),
    ].join('\n');

    // Calculate signature
    final signingKey = _getSignatureKey(secretKey, dateStamp, region, service);
    final signature = _hexEncode(Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).bytes);

    // Create authorization header
    final authorization = 'AWS4-HMAC-SHA256 Credential=$accessKey/$credentialScope, '
        'SignedHeaders=$signedHeadersList, Signature=$signature';

    signedHeaders['Authorization'] = authorization;
    return signedHeaders;
  }

  String _formatDate(DateTime dt) => 
      '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';

  String _formatAmzDate(DateTime dt) => 
      '${_formatDate(dt)}T${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}${dt.second.toString().padLeft(2, '0')}Z';

  String _getCanonicalHeaders(Map<String, String> headers) {
    final sortedKeys = headers.keys.map((k) => k.toLowerCase()).toList()..sort();
    return sortedKeys.map((k) => '$k:${headers.entries.firstWhere((e) => e.key.toLowerCase() == k).value.trim()}').join('\n');
  }

  String _getSignedHeadersList(Map<String, String> headers) {
    final sortedKeys = headers.keys.map((k) => k.toLowerCase()).toList()..sort();
    return sortedKeys.join(';');
  }

  List<int> _getSignatureKey(String key, String dateStamp, String region, String service) {
    final kDate = Hmac(sha256, utf8.encode('AWS4$key')).convert(utf8.encode(dateStamp)).bytes;
    final kRegion = Hmac(sha256, kDate).convert(utf8.encode(region)).bytes;
    final kService = Hmac(sha256, kRegion).convert(utf8.encode(service)).bytes;
    return Hmac(sha256, kService).convert(utf8.encode('aws4_request')).bytes;
  }

  String _hexEncode(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

class UploadService {
  // Cloudflare R2 Configuration
  static const String _endPoint = '7c89b13a3804e7e74371b0d7af933b54.r2.cloudflarestorage.com';
  static const String _accessKey = '7d7b4651ff418c11d22b1060e4597da2';
  static const String _secretKey = '1d26ad535f9fcef7d8cb55c5546fc7bd6015304311751b0ff5f35b9fa44f4d2d';
  static const String _bucketName = 'yusf';

  // Public URL base for Cloudflare R2
  static const String _publicUrlBase = 'https://pub-97d42e49218f4a3087b8d7bfa65201f9.r2.dev';

  static final R2Signer _signer = R2Signer(
    accessKey: _accessKey,
    secretKey: _secretKey,
    region: 'auto',
  );

  // Max file sizes
  static const int maxImageSize = 32 * 1024 * 1024; // 32MB
  static const int maxOtherSize = 200 * 1024 * 1024; // 200MB

  // Supported types
  static const List<String> supportedImageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
  static const List<String> supportedPdfTypes = ['pdf'];
  static const List<String> supportedAudioTypes = ['mp3', 'wav', 'ogg', 'm4a', 'aac'];

  /// Validates file before upload
  static String? validateFile(Uint8List bytes, String filename, UploadFileType type) {
    final extension = filename.split('.').last.toLowerCase();
    
    switch (type) {
      case UploadFileType.image:
        if (!supportedImageTypes.contains(extension)) {
          return 'Unsupported image format. Supported: ${supportedImageTypes.join(", ")}';
        }
        if (bytes.length > maxImageSize) {
          return 'Image too large. Max size: 32MB';
        }
        break;
      case UploadFileType.pdf:
        if (!supportedPdfTypes.contains(extension)) {
          return 'Unsupported file format. Only PDF files are allowed.';
        }
        if (bytes.length > maxOtherSize) {
          return 'PDF too large. Max size: 200MB';
        }
        break;
      case UploadFileType.audio:
        if (!supportedAudioTypes.contains(extension)) {
          return 'Unsupported audio format. Supported: ${supportedAudioTypes.join(", ")}';
        }
        if (bytes.length > maxOtherSize) {
          return 'Audio file too large. Max size: 200MB';
        }
        break;
    }
    return null;
  }

  /// Get content type from filename
  static String _getContentType(String filename, UploadFileType type) {
    final extension = filename.split('.').last.toLowerCase();
    
    switch (type) {
      case UploadFileType.image:
        switch (extension) {
          case 'png': return 'image/png';
          case 'gif': return 'image/gif';
          case 'webp': return 'image/webp';
          case 'bmp': return 'image/bmp';
          default: return 'image/jpeg';
        }
      case UploadFileType.pdf:
        return 'application/pdf';
      case UploadFileType.audio:
        switch (extension) {
          case 'mp3': return 'audio/mpeg';
          case 'wav': return 'audio/wav';
          case 'ogg': return 'audio/ogg';
          case 'm4a': return 'audio/mp4';
          case 'aac': return 'audio/aac';
          default: return 'audio/mpeg';
        }
    }
  }

  /// Get folder name for file type
  static String _getFolderName(UploadFileType type) {
    switch (type) {
      case UploadFileType.image:
        return 'images';
      case UploadFileType.pdf:
        return 'pdfs';
      case UploadFileType.audio:
        return 'audio';
    }
  }

  /// Upload file bytes to Cloudflare R2
  static Future<UploadResult> _uploadToR2(Uint8List bytes, String filename, UploadFileType type) async {
    try {
      // Sanitize filename
      String sanitizedFileName = filename.replaceAll(RegExp(r'\s+'), '_');
      final folder = _getFolderName(type);
      final String objectName = '$folder/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
      
      debugPrint('Uploading to Cloudflare R2: $objectName');

      final uri = Uri.https(_endPoint, '/$_bucketName/$objectName');
      final contentType = _getContentType(filename, type);

      final headers = {
        'Content-Type': contentType,
        'Content-Length': bytes.length.toString(),
      };

      final signedHeaders = _signer.signRequest(
        method: 'PUT',
        uri: uri,
        headers: headers,
        payload: bytes,
      );

      final response = await http.put(
        uri,
        headers: signedHeaders,
        body: bytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final publicUrl = '$_publicUrlBase/$objectName';
        debugPrint('Upload successful: $publicUrl');
        return UploadResult(success: true, url: publicUrl);
      } else {
        debugPrint('R2 Upload failed: ${response.statusCode} - ${response.body}');
        return UploadResult(success: false, error: 'Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('R2 Upload error: $e');
      return UploadResult(success: false, error: e.toString());
    }
  }

  /// Upload profile image
  static Future<UploadResult> uploadProfileImage(Uint8List bytes, String filename) {
    return _uploadToR2(bytes, filename, UploadFileType.image);
  }

  /// Upload book/PDF
  static Future<UploadResult> uploadBook(Uint8List bytes, String filename) {
    return _uploadToR2(bytes, filename, UploadFileType.pdf);
  }

  /// Upload audio file
  static Future<UploadResult> uploadAudio(Uint8List bytes, String filename) {
    return _uploadToR2(bytes, filename, UploadFileType.audio);
  }
}
