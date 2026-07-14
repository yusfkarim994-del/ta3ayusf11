import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;

  Timer? _timer;
  int _secondsRemaining = 60;
  int _phaseSecondsRemaining = 0;
  bool _isRunning = false;
  String _currentPhase = 'ready';
  double _breathScale = 0.82;

  final int _inhaleSeconds = 5;
  final int _holdSeconds = 7;
  final int _exhaleSeconds = 8;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: false);

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
  }

  void _startExercise() {
    _timer?.cancel();
    setState(() {
      _isRunning = true;
      _secondsRemaining = 60;
      _currentPhase = 'inhale';
      _phaseSecondsRemaining = _inhaleSeconds;
      _breathScale = 1.08;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isRunning) return;

      if (_secondsRemaining <= 1) {
        _stopExercise();
        return;
      }

      setState(() {
        _secondsRemaining--;
        _phaseSecondsRemaining--;

        if (_phaseSecondsRemaining <= 0) {
          _advancePhase();
        }
      });
    });
  }

  void _advancePhase() {
    switch (_currentPhase) {
      case 'inhale':
        _currentPhase = 'hold';
        _phaseSecondsRemaining = _holdSeconds;
        _breathScale = 1.08;
        break;
      case 'hold':
        _currentPhase = 'exhale';
        _phaseSecondsRemaining = _exhaleSeconds;
        _breathScale = 0.68;
        break;
      case 'exhale':
      default:
        _currentPhase = 'inhale';
        _phaseSecondsRemaining = _inhaleSeconds;
        _breathScale = 1.08;
        break;
    }
  }

  void _stopExercise() {
    _timer?.cancel();
    if (!mounted) return;

    setState(() {
      _isRunning = false;
      _currentPhase = 'ready';
      _phaseSecondsRemaining = 0;
      _breathScale = 0.82;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = lang.isDarkMode;

    String title,
        subtitle,
        startText,
        stopText,
        inhaleText,
        holdText,
        exhaleText,
        readyText,
        guidanceText,
        cycleText;
    switch (lang.currentLanguage) {
      case AppLanguage.arabic:
        title = 'تمرين التنفس';
        subtitle = 'استرخِ وتنفس بعمق';
        startText = 'ابدأ التمرين';
        stopText = 'إيقاف';
        inhaleText = 'شهيق';
        holdText = 'احبس';
        exhaleText = 'زفير';
        readyText = 'اضغط للبدء';
        guidanceText = 'اتبع حركة الدائرة وخذ نفسا هادئا بدون استعجال';
        cycleText = 'نمط 5 - 7 - 8';
        break;
      case AppLanguage.kurdish:
        title = 'ڕاهێنانی هەناسەدان';
        subtitle = 'ئارام بە و بە قوڵی هەناسە بدە';
        startText = 'دەستپێکردن';
        stopText = 'وەستان';
        inhaleText = 'هەناسە بکێشەوە';
        holdText = 'بیگرە';
        exhaleText = 'هەناسە بدەرەوە';
        readyText = 'کلیک بکە بۆ دەستپێکردن';
        guidanceText = 'شوێنی جووڵەی بازنەکە بکەوە و بە ئارامی هەناسە بدە';
        cycleText = 'شێوازی 5 - 7 - 8';
        break;
      case AppLanguage.english:
        title = 'Breathing Exercise';
        subtitle = 'Relax and breathe deeply';
        startText = 'Start Exercise';
        stopText = 'Stop';
        inhaleText = 'Inhale';
        holdText = 'Hold';
        exhaleText = 'Exhale';
        readyText = 'Tap to start';
        guidanceText = 'Follow the circle and breathe gently without rushing';
        cycleText = '5 - 7 - 8 pattern';
        break;
    }

    String phaseText;
    Color phaseColor;
    IconData phaseIcon;
    switch (_currentPhase) {
      case 'inhale':
        phaseText = inhaleText;
        phaseColor = const Color(0xFF4DB6AC);
        phaseIcon = Icons.air_rounded;
        break;
      case 'hold':
        phaseText = holdText;
        phaseColor = const Color(0xFFFFB74D);
        phaseIcon = Icons.pause_circle_rounded;
        break;
      case 'exhale':
        phaseText = exhaleText;
        phaseColor = const Color(0xFF81C784);
        phaseIcon = Icons.waves_rounded;
        break;
      default:
        phaseText = readyText;
        phaseColor = const Color(0xFF9575CD);
        phaseIcon = Icons.spa_rounded;
    }

    return Directionality(
      textDirection: lang.textDirection,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF071A22),
                      const Color(0xFF0B2530),
                      const Color(0xFF081116),
                    ]
                  : [
                      const Color(0xFFF0FDF9),
                      const Color(0xFFF5FFFE),
                      const Color(0xFFECFDF5),
                    ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _stopExercise();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Icon(
                            lang.isRTL
                                ? Icons.arrow_forward_rounded
                                : Icons.arrow_back_rounded,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: lang.getTextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF064E3B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: lang.getTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Hero Info Card
                _buildBreathingHero(
                  lang,
                  isDark,
                  cycleText,
                  guidanceText,
                  phaseColor,
                  inhaleText,
                  holdText,
                  exhaleText,
                ),

                // Main Breathing Circle
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        final glowOpacity = _glowAnimation.value;

                        return GestureDetector(
                          onTap: _isRunning ? _stopExercise : _startExercise,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Ripple rings when running
                              if (_isRunning) ...[
                                AnimatedBuilder(
                                  animation: _rippleAnimation,
                                  builder: (context, _) {
                                    return Opacity(
                                      opacity: (1 - _rippleAnimation.value) * 0.3,
                                      child: Transform.scale(
                                        scale: 0.8 + _rippleAnimation.value * 0.6,
                                        child: Container(
                                          width: 320,
                                          height: 320,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: phaseColor.withOpacity(0.4),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],

                              // Outer glow rings when idle
                              if (!_isRunning) ...[
                                Container(
                                  width: 300,
                                  height: 300,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: phaseColor
                                          .withOpacity(glowOpacity * 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 330,
                                  height: 330,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: phaseColor
                                          .withOpacity(glowOpacity * 0.12),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ],

                              // Background glow
                              Container(
                                width: 360,
                                height: 360,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      phaseColor.withOpacity(0.1),
                                      phaseColor.withOpacity(0.04),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),

                              // Track circle
                              Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: phaseColor.withOpacity(0.2),
                                    width: 8,
                                  ),
                                ),
                              ),

                              // Main breathing circle
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(end: _breathScale),
                                duration: Duration(
                                  seconds: _currentPhase == 'exhale'
                                      ? _exhaleSeconds
                                      : _currentPhase == 'inhale'
                                          ? _inhaleSeconds
                                          : 1,
                                ),
                                curve: Curves.easeInOutCubic,
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.white.withOpacity(isDark ? 0.12 : 0.98),
                                        phaseColor.withOpacity(isDark ? 0.85 : 0.88),
                                        phaseColor.withOpacity(isDark ? 0.55 : 0.6),
                                        phaseColor.withOpacity(isDark ? 0.25 : 0.3),
                                      ],
                                      stops: const [0.0, 0.3, 0.7, 1.0],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: phaseColor.withOpacity(0.35),
                                        blurRadius: 40,
                                        spreadRadius: 6,
                                      ),
                                      BoxShadow(
                                        color: phaseColor.withOpacity(0.15),
                                        blurRadius: 70,
                                        spreadRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          phaseIcon,
                                          size: 52,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          phaseText,
                                          style: lang.getTextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _isRunning
                                              ? '$_phaseSecondsRemaining s'
                                              : cycleText,
                                          style: lang.getTextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white
                                                .withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Phase Indicators Card
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : const Color(0xFFD1FAE5),
                      width: 1,
                    ),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPhaseIndicator(
                          inhaleText, '5s', const Color(0xFF4DB6AC), lang, isDark),
                      Container(
                        width: 1,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              isDark ? Colors.white12 : Colors.grey[300]!,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      _buildPhaseIndicator(
                          holdText, '7s', const Color(0xFFFFB74D), lang, isDark),
                      Container(
                        width: 1,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              isDark ? Colors.white12 : Colors.grey[300]!,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      _buildPhaseIndicator(
                          exhaleText, '8s', const Color(0xFF81C784), lang, isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Start/Stop Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: _isRunning ? _stopExercise : _startExercise,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isRunning
                                ? [
                                    const Color(0xFFEF5350),
                                    const Color(0xFFE53935),
                                  ]
                                : [
                                    const Color(0xFF059669),
                                    const Color(0xFF10B981),
                                    const Color(0xFF34D399),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (_isRunning
                                      ? const Color(0xFFE53935)
                                      : const Color(0xFF059669))
                                  .withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isRunning
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isRunning ? stopText : startText,
                              style: lang.getTextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreathingHero(
    LanguageService lang,
    bool isDark,
    String cycleText,
    String guidanceText,
    Color phaseColor,
    String inhaleText,
    String holdText,
    String exhaleText,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 4, 22, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0F766E).withOpacity(0.8), const Color(0xFF123047)]
              : [
                  const Color(0xFF059669),
                  const Color(0xFF10B981),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(Icons.spa_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cycleText,
                  style: lang.getTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  guidanceText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: lang.getTextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          if (_isRunning) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              child: Text(
                '0:${_secondsRemaining.toString().padLeft(2, '0')}',
                style: lang.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator(String label, String time, Color color,
      LanguageService lang, bool isDark) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(isDark ? 0.25 : 0.15),
                color.withOpacity(isDark ? 0.1 : 0.08),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(isDark ? 0.3 : 0.2),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              time,
              style: lang.getTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: lang.getTextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
