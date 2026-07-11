import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/stories_service.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen>
    with TickerProviderStateMixin {
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
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _loadData();
  }

  Widget _buildGlowOrb(Color color, double opacity, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }

  Widget _buildModernHeader(
      LanguageService lang, bool isDark, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.10) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE0F2EF)),
              ),
              child: Icon(
                lang.isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : const Color(0xFF12312E),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: lang.getTextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF12312E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: lang.getTextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white60 : const Color(0xFF5B756F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaithHero(LanguageService lang, bool isDark) {
    final helperText = lang.currentLanguage == AppLanguage.arabic
        ? 'اقرأ ببطء، وخذ فكرة واحدة تطبقها اليوم.'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'بە هێواشی بخوێنەوە و یەک بیرۆکە بۆ ئەمڕۆ هەڵبژێرە.'
            : 'Read slowly and take one idea for today.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0F766E), const Color(0xFF1F2937)]
              : [const Color(0xFF0D9488), const Color(0xFFF59E0B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withOpacity(0.22),
            blurRadius: 28,
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
              border: Border.all(color: Colors.white.withOpacity(0.24)),
            ),
            child: const Icon(Icons.auto_stories_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              helperText,
              style: lang.getTextStyle(
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
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

      await Future.delayed(const Duration(seconds: 5));

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

    const islamicGreen = Color(0xFF0D9488);
    const islamicGold = Color(0xFFF59E0B);

    return Directionality(
      textDirection: lang.textDirection,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF071A22),
                      const Color(0xFF102A27),
                      const Color(0xFF111827)
                    ]
                  : [
                      const Color(0xFFF0FDFA),
                      const Color(0xFFFFFBEB),
                      const Color(0xFFEFF6FF)
                    ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -90,
                right: -70,
                child: _buildGlowOrb(islamicGold, isDark ? 0.16 : 0.14, 240),
              ),
              Positioned(
                bottom: -100,
                left: -80,
                child: _buildGlowOrb(islamicGreen, isDark ? 0.12 : 0.12, 260),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildModernHeader(lang, isDark, titleText, subtitleText),

                    // Main content area - maximized for mobile
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: isDark ? islamicGold : islamicGreen,
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.only(
                                  left: 8, right: 8, bottom: 8),
                              child: Column(
                                children: [
                                  _buildFaithHero(lang, isDark),
                                  const SizedBox(height: 16),

                                  // Content card - fills remaining space
                                  Expanded(
                                    child: _isChangingStory
                                        ? Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF2a2a3e)
                                                  : const Color(0xFFFAF3E0),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isDark
                                                    ? islamicGold
                                                        .withOpacity(0.3)
                                                    : islamicGreen
                                                        .withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color: isDark
                                                    ? islamicGold
                                                    : islamicGreen,
                                              ),
                                            ),
                                          )
                                        : FadeTransition(
                                            opacity: _fadeAnimation,
                                            child: Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.white
                                                        .withOpacity(0.08)
                                                    : Colors.white
                                                        .withOpacity(0.96),
                                                borderRadius:
                                                    BorderRadius.circular(32),
                                                border: Border.all(
                                                  color: isDark
                                                      ? Colors.white10
                                                      : const Color(0xFFE0F2EF),
                                                  width: 1,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(32),
                                                child: Scrollbar(
                                                  thumbVisibility: true,
                                                  thickness: 4,
                                                  radius:
                                                      const Radius.circular(10),
                                                  child: SingleChildScrollView(
                                                    padding: const EdgeInsets
                                                        .fromLTRB(
                                                        24, 34, 24, 120),
                                                    physics:
                                                        const BouncingScrollPhysics(),
                                                    child: Text(
                                                      storyText.isEmpty
                                                          ? '...'
                                                          : storyText,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: lang.getTextStyle(
                                                        fontSize: 20,
                                                        height: 1.9,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: isDark
                                                            ? Colors.white
                                                                .withOpacity(
                                                                    0.92)
                                                            : const Color(
                                                                0xFF1F2937),
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
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 16),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF0D9488),
                                                Color(0xFFF59E0B)
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(24),
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
                isDark
                    ? islamicGold.withOpacity(0.5)
                    : islamicGreen.withOpacity(0.3),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(
          Icons.auto_stories,
          size: 16,
          color: isDark
              ? islamicGold.withOpacity(0.5)
              : islamicGreen.withOpacity(0.4),
        ),
        const SizedBox(width: 10),
        Container(
          width: 50,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDark
                    ? islamicGold.withOpacity(0.5)
                    : islamicGreen.withOpacity(0.3),
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
              color: isDark
                  ? islamicGold.withOpacity(0.3)
                  : islamicGreen.withOpacity(0.3),
              width: 2,
            ),
            left: BorderSide(
              color: isDark
                  ? islamicGold.withOpacity(0.3)
                  : islamicGreen.withOpacity(0.3),
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
  Color get shade700 => Color.fromARGB(
      alpha, (red * 0.7).round(), (green * 0.7).round(), (blue * 0.7).round());
  Color get shade900 => Color.fromARGB(
      alpha, (red * 0.5).round(), (green * 0.5).round(), (blue * 0.5).round());
}
