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
        phaseColor = const Color(0xFF4DB6AC); // Teal
        phaseIcon = Icons.cloud;
        break;
      case 'hold':
        phaseText = holdText;
        phaseColor = const Color(0xFFFFB74D); // Amber
        phaseIcon = Icons.lens;
        break;
      case 'exhale':
        phaseText = exhaleText;
        phaseColor = const Color(0xFF81C784); // Green
        phaseIcon = Icons.opacity;
        break;
      default:
        phaseText = readyText;
        phaseColor = const Color(0xFF9575CD); // Purple
        phaseIcon = Icons.local_florist;
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
                      const Color(0xFF081116)
                    ]
                  : [
                      const Color(0xFFF2FFFB),
                      const Color(0xFFF8FBFF),
                      const Color(0xFFFFF7EC)
                    ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
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
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Icon(
                            lang.isRTL
                                ? Icons.arrow_forward_rounded
                                : Icons.arrow_back_rounded,
                            color: isDark ? Colors.white70 : Colors.grey[700],
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
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF12312E),
                              ),
                            ),
                            Text(
                              subtitle,
                              style: lang.getTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF607478),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                _buildBreathingHero(
                  lang,
                  isDark,
                  cycleText,
                  guidanceText,
                  phaseColor,
                ),

                // Main Circle
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
                              // Outer glow rings
                              if (!_isRunning) ...[
                                Container(
                                  width: 290,
                                  height: 290,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: phaseColor
                                          .withOpacity(glowOpacity * 0.3),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 320,
                                  height: 320,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: phaseColor
                                          .withOpacity(glowOpacity * 0.15),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ],

                              Container(
                                width: 350,
                                height: 350,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      phaseColor.withOpacity(0.08),
                                      phaseColor.withOpacity(0.03),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 292,
                                height: 292,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: phaseColor.withOpacity(0.18),
                                    width: 10,
                                  ),
                                ),
                              ),

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
                                  width: 230,
                                  height: 230,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.98),
                                        phaseColor.withOpacity(0.92),
                                        phaseColor.withOpacity(0.64),
                                        phaseColor.withOpacity(0.34),
                                      ],
                                      stops: const [0.0, 0.34, 0.72, 1.0],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: phaseColor.withOpacity(0.4),
                                        blurRadius: 40,
                                        spreadRadius: 8,
                                      ),
                                      BoxShadow(
                                        color: phaseColor.withOpacity(0.2),
                                        blurRadius: 60,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.22),
                                          width: 2),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          phaseIcon,
                                          size: 58,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          phaseText,
                                          style: lang.getTextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _isRunning
                                              ? '$_phaseSecondsRemaining s'
                                              : cycleText,
                                          style: lang.getTextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                Colors.white.withOpacity(0.82),
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

                // Instructions Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color:
                            isDark ? Colors.white10 : const Color(0xFFE0F2EF)),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPhaseIndicator(inhaleText, '5s',
                          const Color(0xFF4DB6AC), lang, isDark),
                      Container(
                          width: 1,
                          height: 40,
                          color: isDark ? Colors.white12 : Colors.grey[200]),
                      _buildPhaseIndicator(holdText, '7s',
                          const Color(0xFFFFB74D), lang, isDark),
                      Container(
                          width: 1,
                          height: 40,
                          color: isDark ? Colors.white12 : Colors.grey[200]),
                      _buildPhaseIndicator(exhaleText, '8s',
                          const Color(0xFF81C784), lang, isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Start/Stop Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: GestureDetector(
                    onTap: _isRunning ? _stopExercise : _startExercise,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isRunning
                              ? [
                                  const Color(0xFFEF5350),
                                  const Color(0xFFE53935)
                                ]
                              : [
                                  const Color(0xFF4DB6AC),
                                  const Color(0xFF26A69A)
                                ],
                        ),
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRunning
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFF26A69A))
                                .withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isRunning
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 24,
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
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0F766E), const Color(0xFF123047)]
              : [const Color(0xFF0D9488), const Color(0xFF38BDF8)],
        ),
        boxShadow: [
          BoxShadow(
            color: phaseColor.withOpacity(0.24),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            child: const Icon(Icons.air_rounded, color: Colors.white, size: 31),
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
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  guidanceText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: lang.getTextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.78),
                  ),
                ),
              ],
            ),
          ),
          if (_isRunning) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.17),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '0:${_secondsRemaining.toString().padLeft(2, '0')}',
                style: lang.getTextStyle(
                  fontSize: 15,
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              time,
              style: lang.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
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
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
