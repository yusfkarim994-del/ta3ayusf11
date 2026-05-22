import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class DownloadService {
  static final Dio _dio = Dio();

  /// Gets the directory path where we save the books locally
  static Future<String> _getSaveDir() async {
    Directory directory;
    if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      // Use application support directory for internal hidden saving
      directory = await getApplicationSupportDirectory(); 
    }
    final path = '${directory.path}/books_library';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  /// Gets the exact local file path for a specific book ID
  static Future<String> getLocalBookPath(String bookId) async {
    final saveDir = await _getSaveDir();
    return '$saveDir/$bookId.pdf';
  }

  /// Checking if the book exists offline and is not empty
  static Future<bool> isBookDownloaded(String bookId) async {
    try {
      final filePath = await getLocalBookPath(bookId);
      final file = File(filePath);
      return await file.exists() && await file.length() > 0;
    } catch (e) {
      debugPrint('Error checking download status: $e');
      return false;
    }
  }

  /// Delete book from device
  static Future<void> deleteBookOffline(String bookId) async {
    try {
      final filePath = await getLocalBookPath(bookId);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting local book: $e');
    }
  }

  /// Scrape mediafire page to extract the direct PDF link
  static Future<String> getDirectMediafireLink(String url) async {
    if (!url.toLowerCase().contains('mediafire.com')) return url;
    try {
      debugPrint('Scraping Mediafire link: $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        // Mediafire uses id="downloadButton" for the download anchor tag
        var dlButton = document.getElementById('downloadButton');
        if (dlButton != null) {
          String? directLink = dlButton.attributes['href'];
          if (directLink != null && directLink.isNotEmpty) {
            debugPrint('Found direct link: $directLink');
            return directLink;
          }
        }
      }
    } catch (e) {
      debugPrint('Error resolving MediaFire direct link: $e');
    }
    return url; // fallback to the original link if scraping fails
  }

  /// Download the book saving it with its ID. `onProgress` triggers dynamically.
  static Future<bool> downloadBook({
    required String downloadUrl,
    required String bookId,
    required Function(double progress) onProgress,
  }) async {
    String savePath = '';
    try {
      // 1. Resolve direct link if mediafire
      String directLink = await getDirectMediafireLink(downloadUrl);
      
      // Auto-encode URL if needed
      if (!directLink.contains('%') && directLink.contains(' ')) {
        directLink = Uri.encodeFull(directLink);
      }
      
      // 2. Prepare local save path
      savePath = await getLocalBookPath(bookId);

      // 3. Download the file using Dio
      await _dio.download(
        directLink,
        savePath,
        options: Options(
          followRedirects: true,
          responseType: ResponseType.bytes,
          validateStatus: (status) => status != null && status < 400,
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = received / total;
            onProgress(progress);
          }
        },
      );
      
      // 4. Verify if it's a valid PDF (must start with %PDF)
      final file = File(savePath);
      if (await file.exists()) {
        if (await file.length() < 100) {
          await file.delete();
          return false;
        }
        final randomAccessFile = await file.open(mode: FileMode.read);
        final bytes = await randomAccessFile.read(4);
        await randomAccessFile.close();
        final String header = String.fromCharCodes(bytes);
        if (header != '%PDF') {
          debugPrint('Invalid PDF Downloaded. It is likely an HTML page: $header');
          await file.delete();
          return false;
        }
      } else {
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error downloading book: $e');
      // Clean up incomplete file if any error happens
      if (savePath.isNotEmpty) {
        final file = File(savePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      return false;
    }
  }
}
