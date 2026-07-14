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
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              if (!isDark)
                BoxShadow(
                  color: const Color(0xFF0D9488).withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                Builder(
                  builder: (context) {
                    final bgPath = timerService.backgroundImagePath;
                    if (bgPath.startsWith('data:')) {
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
                // Gradient overlay for better readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.transparent,
                        Colors.black.withOpacity(0.15),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
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
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: GestureDetector(
                              onTap: widget.onSettingsTap,
                              child: Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.settings_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
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
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                size: 52,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4facfe).withOpacity(0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () =>
                                    timerService.resetTimer().then((_) => setState(() {})),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4facfe),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  lang.startRecovery,
                                  style: lang.getTextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            // Top row: Months, Days, Hours
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildTimeUnit(
                                    timerService.months,
                                    lang.months,
                                    lang,
                                    const Color(0xFF4facfe),
                                    12),
                                _buildTimeSeparator(),
                                _buildTimeUnit(
                                    timerService.days,
                                    lang.days,
                                    lang,
                                    const Color(0xFF00f2fe),
                                    30),
                                _buildTimeSeparator(),
                                _buildTimeUnit(
                                    timerService.hours,
                                    lang.hours,
                                    lang,
                                    const Color(0xFF43e97b),
                                    24),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Bottom row: Minutes, Seconds
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildTimeUnit(
                                    timerService.minutes,
                                    lang.minutesStr,
                                    lang,
                                    const Color(0xFFfa709a),
                                    60),
                                const SizedBox(width: 28),
                                _buildTimeSeparator(),
                                const SizedBox(width: 28),
                                _buildTimeUnit(
                                    timerService.seconds,
                                    lang.secondsStr,
                                    lang,
                                    const Color(0xFFffd700),
                                    60),
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
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeUnit(
    int value,
    String label,
    LanguageService lang,
    Color accentColor,
    int maxValue,
  ) {
    final fillPercent = (value / maxValue).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 76,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Liquid fill
                if (fillPercent > 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 14.0 + (fillPercent * (100.0 - 14.0)),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accentColor.withOpacity(0.9),
                            accentColor.withOpacity(0.65),
                            accentColor.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),

                // Glass shine effect
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.18),
                          Colors.transparent,
                        ],
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
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                            Shadow(
                              color: accentColor.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 0),
                            ),
                          ],
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
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
