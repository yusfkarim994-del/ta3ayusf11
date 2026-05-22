import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/timer_service.dart';
import '../services/language_service.dart';

/// Isolated timer widget that only rebuilds itself every second
/// This prevents the entire home screen from rebuilding on every tick
class RecoveryTimerWidget extends StatefulWidget {
  final RecoveryTimerService timerService;
  final LanguageService lang;
  final VoidCallback onSettingsTap;

  const RecoveryTimerWidget({
    super.key,
    required this.timerService,
    required this.lang,
    required this.onSettingsTap,
  });

  @override
  State<RecoveryTimerWidget> createState() => _RecoveryTimerWidgetState();
}

class _RecoveryTimerWidgetState extends State<RecoveryTimerWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      widget.timerService.tick();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final timerService = widget.timerService;
    final isDark = lang.isDarkMode;

    return AspectRatio(
      aspectRatio: 1.1,
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Builder(
                builder: (context) {
                  final bgPath = timerService.backgroundImagePath;
                  if (bgPath.startsWith('data:')) {
                    // Base64 data URI (user-uploaded image)
                    final dataStr = bgPath.split(',').last;
                    return Image.memory(
                      base64Decode(dataStr),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      filterQuality: FilterQuality.low,
                    );
                  } else {
                    return Image.asset(
                      bgPath,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                    );
                  }
                },
              ),
              // Timer content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Top Row - Settings button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: widget.onSettingsTap,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.settings_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    if (!timerService.hasStarted)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded, size: 50, color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => timerService.resetTimer().then((_) => setState(() {})),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4facfe),
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text(
                              lang.startRecovery,
                              style: lang.getTextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildTimeUnit(timerService.months, lang.months, lang, const Color(0xFF4facfe), 12),
                              _buildTimeSeparator(),
                              _buildTimeUnit(timerService.days, lang.days, lang, const Color(0xFF4facfe), 30),
                              _buildTimeSeparator(),
                              _buildTimeUnit(timerService.hours, lang.hours, lang, const Color(0xFF4facfe), 24),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTimeUnit(timerService.minutes, lang.minutesStr, lang, const Color(0xFF00f2fe), 60),
                              const SizedBox(width: 24),
                              _buildTimeSeparator(),
                              const SizedBox(width: 24),
                              _buildTimeUnit(timerService.seconds, lang.secondsStr, lang, const Color(0xFFffd700), 60),
                            ],
                          ),
                        ],
                      ),
                    
                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildTimeSeparator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeUnit(int value, String label, LanguageService lang, Color accentColor, int maxValue) {
    final fillPercent = (value / maxValue).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 96,
          decoration: BoxDecoration(
            // Simplified glass effect for better performance
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Simplified fill without complex gradient
                if (fillPercent > 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 12.0 + (fillPercent * (96.0 - 12.0)),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.7),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                      ),
                    ),
                  ),
                
                // Content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value.toString().padLeft(2, '0'),
                        style: lang.getTextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                            Shadow(
                              color: accentColor.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 0),
                            ),
                          ],
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          label,
                          style: lang.getTextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
