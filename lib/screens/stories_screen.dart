import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/stories_service.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> with TickerProviderStateMixin {
  final _storiesService = StoriesService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;
  bool _isChangingStory = false;

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
    await _storiesService.loadStories();
    setState(() => _isLoading = false);
    _fadeController.forward();
  }

  void _nextStory() async {
    if (_storiesService.totalStories > 1 && !_isChangingStory) {
      setState(() => _isChangingStory = true);
      _fadeController.reverse();
      
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        _storiesService.nextStory();
        setState(() => _isChangingStory = false);
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
    final story = _storiesService.currentStory;

    // Get story text based on language
    String storyText = '';
    if (story != null) {
      switch (lang.currentLanguage) {
        case AppLanguage.arabic:
          storyText = story.textAr;
          break;
        case AppLanguage.kurdish:
          storyText = story.textKu.isNotEmpty ? story.textKu : story.textAr;
          break;
        case AppLanguage.english:
          storyText = story.textEn.isNotEmpty ? story.textEn : story.textAr;
          break;
      }
    }

    // Title text
    String titleText;
    String subtitleText;
    String nextText;
    switch (lang.currentLanguage) {
      case AppLanguage.arabic:
        titleText = 'جرعة إيمانية';
        subtitleText = 'من أقوال السلف الصالح';
        nextText = 'التالي';
        break;
      case AppLanguage.kurdish:
        titleText = 'دۆزی ئیمانی';
        subtitleText = 'لە قسەکانی سەلەفی ساڵح';
        nextText = 'دواتر';
        break;
      case AppLanguage.english:
        titleText = 'Faith Dose';
        subtitleText = 'From the Words of the Righteous Predecessors';
        nextText = 'Next';
        break;
    }

    // Islamic colors
    const islamicGreen = Color(0xFF0D6B4E);
    const islamicGold = Color(0xFFD4AF37);

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
                                color: isDark ? Colors.white.withOpacity(0.1) : islamicGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? islamicGold.withOpacity(0.3) : islamicGreen.withOpacity(0.3),
                                ),
                              ),
                              child: Icon(
                                lang.isRTL ? Icons.arrow_forward : Icons.arrow_back,
                                color: isDark ? islamicGold : islamicGreen,
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
                                color: isDark ? islamicGold : islamicGreen,
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
                                        color: isDark ? islamicGold : islamicGreen,
                                      ),
                                    ),
                                  ),
                                  
                                  // Content card - fills remaining space
                                  Expanded(
                                    child: _isChangingStory
                                      ? Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF2a2a3e) : const Color(0xFFFAF3E0),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isDark ? islamicGold.withOpacity(0.3) : islamicGreen.withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: isDark ? islamicGold : islamicGreen,
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
                                                color: isDark ? islamicGold.withOpacity(0.3) : islamicGreen.withOpacity(0.2),
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
                                                    storyText.isEmpty ? '...' : storyText,
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
                                  if (_storiesService.totalStories > 1)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: GestureDetector(
                                        onTap: _nextStory,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: isDark
                                                  ? [islamicGold.shade700, islamicGold.shade900]
                                                  : [islamicGreen, islamicGreen.withOpacity(0.8)],
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
    const islamicGold = Color(0xFFD4AF37);
    const islamicGreen = Color(0xFF0D6B4E);
    
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
                isDark ? islamicGold.withOpacity(0.5) : islamicGreen.withOpacity(0.3),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(
          Icons.auto_stories,
          size: 16,
          color: isDark ? islamicGold.withOpacity(0.5) : islamicGreen.withOpacity(0.4),
        ),
        const SizedBox(width: 10),
        Container(
          width: 50,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDark ? islamicGold.withOpacity(0.5) : islamicGreen.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerDecoration(bool isDark, bool isLeft) {
    const islamicGold = Color(0xFFD4AF37);
    const islamicGreen = Color(0xFF0D6B4E);
    
    return Transform.rotate(
      angle: isLeft ? 0 : 3.14159,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? islamicGold.withOpacity(0.3) : islamicGreen.withOpacity(0.3),
              width: 2,
            ),
            left: BorderSide(
              color: isDark ? islamicGold.withOpacity(0.3) : islamicGreen.withOpacity(0.3),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

// Extension to add shade to Color
extension ColorShade on Color {
  Color get shade700 => Color.fromARGB(alpha, (red * 0.7).round(), (green * 0.7).round(), (blue * 0.7).round());
  Color get shade900 => Color.fromARGB(alpha, (red * 0.5).round(), (green * 0.5).round(), (blue * 0.5).round());
}
