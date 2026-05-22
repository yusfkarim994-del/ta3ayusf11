import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _glowController;
  late Animation<double> _breathAnimation;
  late Animation<double> _glowAnimation;
  
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _isRunning = false;
  String _currentPhase = 'ready';
  
  final int _inhaleSeconds = 5;
  final int _holdSeconds = 7;
  final int _exhaleSeconds = 8;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _breathAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void _startExercise() {
    setState(() {
      _isRunning = true;
      _secondsRemaining = 60;
      _currentPhase = 'inhale';
    });
    _startBreathCycle();
    _startTimer();
  }

  void _startBreathCycle() {
    setState(() => _currentPhase = 'inhale');
    _breathController.duration = Duration(seconds: _inhaleSeconds);
    _breathController.forward().then((_) {
      if (!_isRunning) return;
      
      setState(() => _currentPhase = 'hold');
      Future.delayed(Duration(seconds: _holdSeconds), () {
        if (!_isRunning) return;
        
        setState(() => _currentPhase = 'exhale');
        _breathController.duration = Duration(seconds: _exhaleSeconds);
        _breathController.reverse().then((_) {
          if (!_isRunning) return;
          _startBreathCycle();
        });
      });
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _stopExercise();
      }
    });
  }

  void _stopExercise() {
    _timer?.cancel();
    _breathController.stop();
    setState(() {
      _isRunning = false;
      _currentPhase = 'ready';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = lang.isDarkMode;

    String title, subtitle, startText, stopText, inhaleText, holdText, exhaleText, readyText;
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
                  ? [const Color(0xFF1A1A2E), const Color(0xFF16213E), const Color(0xFF0F3460)]
                  : [const Color(0xFFFAFAFA), const Color(0xFFF5F5F5), const Color(0xFFECEFF1)],
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
                            color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: isDark ? null : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            lang.isRTL ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
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
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.grey[800],
                              ),
                            ),
                            Text(
                              subtitle,
                              style: lang.getTextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white54 : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Timer
                if (_isRunning)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: isDark ? null : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Text(
                      '0:${_secondsRemaining.toString().padLeft(2, '0')}',
                      style: lang.getTextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                  ),
                
                // Main Circle
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _isRunning ? _breathAnimation : _glowAnimation,
                      builder: (context, child) {
                        final scale = _isRunning ? _breathAnimation.value : 0.85;
                        final glowOpacity = _glowAnimation.value;
                        
                        return GestureDetector(
                          onTap: _isRunning ? _stopExercise : _startExercise,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer glow rings
                              if (!_isRunning) ...[
                                Container(
                                  width: 280,
                                  height: 280,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: phaseColor.withOpacity(glowOpacity * 0.3),
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
                                      color: phaseColor.withOpacity(glowOpacity * 0.15),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ],
                              
                              // Main breathing circle
                              Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        phaseColor.withOpacity(0.9),
                                        phaseColor.withOpacity(0.6),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: phaseColor.withOpacity(0.4),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                      BoxShadow(
                                        color: phaseColor.withOpacity(0.2),
                                        blurRadius: 60,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        phaseIcon,
                                        size: 56,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        phaseText,
                                        style: lang.getTextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
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
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: isDark ? null : [
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
                      _buildPhaseIndicator(inhaleText, '5s', const Color(0xFF4DB6AC), lang, isDark),
                      Container(width: 1, height: 40, color: isDark ? Colors.white12 : Colors.grey[200]),
                      _buildPhaseIndicator(holdText, '7s', const Color(0xFFFFB74D), lang, isDark),
                      Container(width: 1, height: 40, color: isDark ? Colors.white12 : Colors.grey[200]),
                      _buildPhaseIndicator(exhaleText, '8s', const Color(0xFF81C784), lang, isDark),
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
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isRunning
                              ? [const Color(0xFFEF5350), const Color(0xFFE53935)]
                              : [const Color(0xFF4DB6AC), const Color(0xFF26A69A)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRunning ? const Color(0xFFE53935) : const Color(0xFF26A69A)).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
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

  Widget _buildPhaseIndicator(String label, String time, Color color, LanguageService lang, bool isDark) {
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
