import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

/// Cross-platform audio recorder
class WebAudioRecorder {
  final _audioRecorder = Record();
  bool _isRecording = false;
  DateTime? _recordingStartTime;
  String? _tempPath;

  bool get isRecording => _isRecording;
  
  int get recordingDurationSeconds {
    if (_recordingStartTime == null) return 0;
    return DateTime.now().difference(_recordingStartTime!).inSeconds;
  }

  Future<String?> startRecording() async {
    try {
      // Explicitly request microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return "Microphone permission is required to record voice messages.";
      }

      if (await _audioRecorder.hasPermission()) {
        if (!kIsWeb) {
          final dir = await getTemporaryDirectory();
          _tempPath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        } else {
          _tempPath = null; // Let the web package handle the blob
        }

        await _audioRecorder.start(
          encoder: AudioEncoder.aacLc,
          path: _tempPath,
        );
        _isRecording = true;
        _recordingStartTime = DateTime.now();
        return null; // completely successful
      } else {
        return "Record package could not verify microphone access.";
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
      return "Recorder Error: ${e.toString()}";
    }
  }

  Future<Uint8List?> stopRecording() async {
    if (!_isRecording) return null;
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      _recordingStartTime = null;
      if (path != null) {
        if (kIsWeb) {
          final response = await http.get(Uri.parse(path));
          return response.bodyBytes;
        } else {
          final file = File(path);
          return await file.readAsBytes();
        }
      }
    } catch (e) {
      debugPrint('Error stopping: $e');
    }
    return null;
  }

  void cancelRecording() async {
    if (_isRecording) {
      await _audioRecorder.stop();
      _isRecording = false;
    }
    _recordingStartTime = null;
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}

