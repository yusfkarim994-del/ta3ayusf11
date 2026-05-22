import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/tips_service.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> with TickerProviderStateMixin {
  final _tipsService = TipsService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;
  bool _isChangingTip = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _loadData();
  }

  Future<void> _loadData() async {
    await _tipsService.loadTips();
    setState(() => _isLoading = false);
    _fadeController.forward();
  }

  void _nextTip() async {
    if (_tipsService.totalTips > 1 && !_isChangingTip) {
      // Start loading animation
      setState(() => _isChangingTip = true);
      _fadeController.reverse();
      
      // Wait 5 seconds
      await Future.delayed(const Duration(seconds: 5));
      
      if (mounted) {
        _tipsService.nextTip();
        setState(() => _isChangingTip = false);
        _fadeController.forward();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = lang.isDarkMode;
    final tip = _tipsService.currentTip;

    // Get tip text based on language
    String tipText = '';
    if (tip != null) {
      switch (lang.currentLanguage) {
        case AppLanguage.arabic:
          tipText = tip.textAr;
          break;
        case AppLanguage.kurdish:
          tipText = tip.textKu.isNotEmpty ? tip.textKu : tip.textAr;
          break;
        case AppLanguage.english:
          tipText = tip.textEn.isNotEmpty ? tip.textEn : tip.textAr;
          break;
      }
    }

    // Title text
    String titleText;
    String nextText;
    switch (lang.currentLanguage) {
      case AppLanguage.arabic:
        titleText = 'نصيحة لك';
        nextText = 'التالي';
        break;
      case AppLanguage.kurdish:
        titleText = 'نەسیحەت بۆ تۆ';
        nextText = 'دواتر';
        break;
      case AppLanguage.english:
        titleText = 'Advice for you';
        nextText = 'Next';
        break;
    }

    return Directionality(
      textDirection: lang.textDirection,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          // Vintage paper-like background
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF1a1a2e), const Color(0xFF16213e), const Color(0xFF0f0f23)]
                  : [const Color(0xFFF5E6D3), const Color(0xFFE8D4B8), const Color(0xFFD4C4A8)],
            ),
          ),
          child: Stack(
            children: [
              // Vintage texture overlay
              Positioned.fill(
                child: Opacity(
                  opacity: 0.05,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: const AssetImage('assets/images/nature_bg.png'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          isDark ? Colors.white : Colors.brown,
                          BlendMode.modulate,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Decorative corners
              Positioned(
                top: 40,
                left: 20,
                child: _buildCornerDecoration(isDark, true),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: _buildCornerDecoration(isDark, false),
              ),
              
              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Header with back button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.1) : Colors.brown.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? Colors.amber.withOpacity(0.3) : Colors.brown.withOpacity(0.3),
                                ),
                              ),
                              child: Icon(
                                lang.isRTL ? Icons.arrow_forward : Icons.arrow_back,
                                color: isDark ? Colors.amber : Colors.brown[700],
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Main content area - maximized for mobile
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: isDark ? Colors.amber : Colors.brown,
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                              child: Column(
                                children: [
                                  // Compact title
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      titleText,
                                      style: TextStyle(
                                        fontFamily: lang.currentLanguage == AppLanguage.english ? 'Georgia' : null,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.amber.shade200 : Colors.brown[800],
                                      ),
                                    ),
                                  ),
                                  
                                  // Content card - fills remaining space
                                  Expanded(
                                    child: _isChangingTip
                                      ? Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF2a2a3e) : const Color(0xFFFAF3E0),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isDark ? Colors.amber.withOpacity(0.3) : Colors.brown.withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: isDark ? Colors.amber : Colors.brown,
                                            ),
                                          ),
                                        )
                                      : FadeTransition(
                                          opacity: _fadeAnimation,
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF2a2a3e) : const Color(0xFFFAF3E0),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isDark ? Colors.amber.withOpacity(0.3) : Colors.brown.withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Scrollbar(
                                                thumbVisibility: true,
                                                thickness: 4,
                                                radius: const Radius.circular(10),
                                                child: SingleChildScrollView(
                                                  padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
                                                  physics: const BouncingScrollPhysics(),
                                                  child: Text(
                                                    tipText.isEmpty ? '...' : tipText,
                                                    textAlign: TextAlign.center,
                                                    style: lang.getTextStyle(
                                                      fontSize: 18,
                                                      height: 1.8,
                                                      fontWeight: FontWeight.w500,
                                                      color: isDark ? Colors.white.withOpacity(0.9) : Colors.brown[900],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                  ),
                                  
                                  // Compact next button
                                  if (_tipsService.totalTips > 1)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: GestureDetector(
                                        onTap: _nextTip,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: isDark
                                                  ? [Colors.amber.shade700, Colors.amber.shade900]
                                                  : [Colors.brown.shade400, Colors.brown.shade600],
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            nextText,
                                            style: lang.getTextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
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
    );
  }

  Widget _buildOrnament(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 50,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                isDark ? Colors.amber.withOpacity(0.5) : Colors.brown.withOpacity(0.3),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(
          Icons.star,
          size: 16,
          color: isDark ? Colors.amber.withOpacity(0.5) : Colors.brown.withOpacity(0.4),
        ),
        const SizedBox(width: 10),
        Container(
          width: 50,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDark ? Colors.amber.withOpacity(0.5) : Colors.brown.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerDecoration(bool isDark, bool isLeft) {
    return Transform.rotate(
      angle: isLeft ? 0 : 3.14159,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.amber.withOpacity(0.3) : Colors.brown.withOpacity(0.3),
              width: 2,
            ),
            left: BorderSide(
              color: isDark ? Colors.amber.withOpacity(0.3) : Colors.brown.withOpacity(0.3),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
