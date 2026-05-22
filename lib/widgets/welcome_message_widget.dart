import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomeMessageWidget extends StatefulWidget {
  final Widget child;

  const WelcomeMessageWidget({super.key, required this.child});

  @override
  State<WelcomeMessageWidget> createState() => _WelcomeMessageWidgetState();
}

class _WelcomeMessageWidgetState extends State<WelcomeMessageWidget>
    with SingleTickerProviderStateMixin {
  bool _showMessage = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _hideTimer;
  int _currentMessageIndex = 0;

  final List<Map<String, String>> _messages = [
    {'title': 'تطبيق ختمة', 'subtitle': 'رفيقك الإيماني', 'body': 'قرآن كريم بأصوات ٢٤٠ قارئ\nمواقيت الصلاة والأذكار اليومية\nأحاديث نبوية وتفسير القرآن'},
    {'title': 'ختمة', 'subtitle': 'القرآن الكريم', 'body': 'استمع وتلاوة بأجمل الأصوات\nالسديس والشريم والمنشاوي\nتفسير ابن كثير والسعدي'},
    {'title': 'ختمة', 'subtitle': 'أذكار وأدعية', 'body': 'أذكار الصباح والمساء\nأدعية من القرآن والسنة\nتنبيهات ذكية لتذكيرك'},
    {'title': 'ختمة', 'subtitle': 'مواقيت الصلاة', 'body': 'مواقيت دقيقة لموقعك\nأذان تلقائي وتنبيهات\nاتجاه القبلة بدقة عالية'},
    {'title': 'تطبيق ختمة', 'subtitle': 'شامل ومجاني', 'body': 'كل ما يحتاجه المسلم\nفي تطبيق واحد مجاني\nبدون إعلانات مزعجة'},
    {'title': 'ختمة', 'subtitle': 'تابع ختمتك', 'body': 'متابعة تقدمك في القراءة\nإحصائيات وتذكيرات يومية\nحمّله الآن واختم القرآن'},
    {'title': 'ختمة', 'subtitle': 'أحاديث نبوية', 'body': 'أحاديث صحيحة يومية\nمع الشرح والتخريج\nمن صحيح البخاري ومسلم'},
    {'title': 'ختمة', 'subtitle': 'عدّاد التسبيح', 'body': 'سبّح واذكر الله بسهولة\nعدّاد ذكي مع الإحصائيات\nأهداف يومية للتسبيح'},
  ];

  @override
  void initState() {
    super.initState();
    _loadMessageIndex();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _animationController.forward();
    
    _hideTimer = Timer(const Duration(seconds: 15), () {
      _hideMessage();
    });
  }

  Future<void> _loadMessageIndex() async {
    final prefs = await SharedPreferences.getInstance();
    int lastIndex = prefs.getInt('welcome_message_index') ?? -1;
    
    int newIndex;
    do {
      newIndex = Random().nextInt(_messages.length);
    } while (newIndex == lastIndex && _messages.length > 1);
    
    await prefs.setInt('welcome_message_index', newIndex);
    
    if (mounted) {
      setState(() {
        _currentMessageIndex = newIndex;
      });
    }
  }

  Future<void> _hideMessage() async {
    await _animationController.reverse();
    if (mounted) {
      setState(() {
        _showMessage = false;
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showMessage)
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: GestureDetector(
                onTap: _hideMessage,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        color: Colors.black.withOpacity(0.75 * _fadeAnimation.value),
                        child: Center(
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: _buildMessageCard(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageCard() {
    final message = _messages[_currentMessageIndex];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D4F2B).withOpacity(0.6),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/khatmah_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0D4F2B), Color(0xFF062A17), Color(0xFF041C0F)],
                    ),
                  ),
                ),
              ),
            ),
            // Dark overlay for readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top decorative dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDot(6),
                      const SizedBox(width: 6),
                      _buildDot(4),
                      const SizedBox(width: 6),
                      _buildDot(8),
                      const SizedBox(width: 6),
                      _buildDot(4),
                      const SizedBox(width: 6),
                      _buildDot(6),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Khatmah Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B5E20).withOpacity(0.5),
                          blurRadius: 25,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/khatmah_logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                            ),
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 50),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // App Title
                  Text(
                    message['title']!,
                    style: const TextStyle(
                      fontSize: 32, // Increased from 28
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Cairo',
                      letterSpacing: 1.2,
                      decoration: TextDecoration.none, // Just to be safe
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  
                  // Subtitle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      message['subtitle']!,
                      style: TextStyle(
                        fontSize: 18, // Increased from 15
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.95),
                        fontFamily: 'Cairo',
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Body text
                  Text(
                    message['body']!,
                    style: const TextStyle(
                      fontSize: 18, // Increased from 15
                      color: Colors.white,
                      fontFamily: 'Cairo',
                      height: 1.8,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // Stars + Free badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...List.generate(5, (i) => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 1),
                        child: Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 24), // Increased from 20
                      )),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.5)),
                        ),
                        child: const Text(
                          'مجاني',
                          style: TextStyle(
                            fontSize: 14, // Increased from 12
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF81C784),
                            fontFamily: 'Cairo',
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Download Button
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.khatmah.quran.yusf.app');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18), // Increased from 16
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B5E20).withOpacity(0.5),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download_rounded, color: Colors.white, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'حمّل التطبيق مجاناً',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20, // Increased from 18
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Close button
                  GestureDetector(
                    onTap: _hideMessage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.7), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'إغلاق',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 15, // Increased from 13
                              fontFamily: 'Cairo',
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  // Progress bar
                  SizedBox(
                    width: 80,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 0.0),
                      duration: const Duration(seconds: 15),
                      builder: (context, value, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 3,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.3),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
      ),
    );
  }
}
