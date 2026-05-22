import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class WebAudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final int durationSeconds;
  final Color activeColor;
  final Color inactiveColor;

  const WebAudioPlayerWidget({
    super.key,
    required this.audioUrl,
    required this.durationSeconds,
    this.activeColor = const Color(0xFF4facfe),
    this.inactiveColor = Colors.grey,
  });

  @override
  State<WebAudioPlayerWidget> createState() => _WebAudioPlayerWidgetState();
}

class _WebAudioPlayerWidgetState extends State<WebAudioPlayerWidget> {
  final _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  double _progress = 0.0;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  void _initAudio() {
    _audioPlayer.setSourceUrl(widget.audioUrl);
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isLoading = false;
          if (state == PlayerState.completed) {
            _progress = 0.0;
            _position = Duration.zero;
          }
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          _position = p;
          if (_duration.inMilliseconds > 0) {
            _progress = p.inMilliseconds / _duration.inMilliseconds;
          }
        });
      }
    });
  }

  void _togglePlay() async {
    setState(() => _isLoading = true);
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.audioUrl));
    }
  }

  void _seekTo(double value) async {
    if (_duration.inMilliseconds > 0) {
      final position = value * _duration.inMilliseconds;
      await _audioPlayer.seek(Duration(milliseconds: position.toInt()));
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final displaySeconds = _isPlaying || _position.inMilliseconds > 0
        ? _position
        : Duration(seconds: widget.durationSeconds);
        
    final isWhiteBg = widget.activeColor.value == 0xFFFFFFFF;
    final iconColor = isWhiteBg ? const Color(0xFF667EEA) : Colors.white;

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.activeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.activeColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.activeColor,
                shape: BoxShape.circle,
              ),
              child: _isLoading && !_isPlaying
                  ? SizedBox(
                      width: 20, height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: iconColor),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: iconColor,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 20,
                  child: SliderTheme(
                    data: SliderThemeData(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      trackHeight: 4,
                      activeTrackColor: widget.activeColor,
                      inactiveTrackColor: widget.inactiveColor.withOpacity(0.3),
                      thumbColor: widget.activeColor,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: _progress.clamp(0.0, 1.0),
                      onChanged: _seekTo,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _formatTime(displaySeconds),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: widget.activeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

