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
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _loadData();
  }

  Future<void> _loadData() async {
    await _tipsService.loadTips();
    setState(() => _isLoading = false);
    _fadeController.forward();
  }

  void _nextTip() async {
    if (_tipsService.totalTips > 1 && !_isChangingTip) {
      setState(() => _isChangingTip = true);
      _fadeController.reverse();

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

    String titleText;
    String nextText;
    String subtitleText;
    String rescueText;
    String breatheText;
    switch (lang.currentLanguage) {
      case AppLanguage.arabic:
        titleText = 'هل تشعر برغبة شديدة؟';
        subtitleText = 'توقف لحظة. اقرأ النصيحة، تنفس، ثم خذ خطوة صغيرة آمنة.';
        rescueText = 'خطة إنقاذ سريعة';
        breatheText = 'تنفس 10 مرات ببطء';
        nextText = 'التالي';
        break;
      case AppLanguage.kurdish:
        titleText = 'ئارەزوویەکی بەهێزت هەیە؟';
        subtitleText =
            'ساتێک بوەستە. ئامۆژگارییەکە بخوێنەوە، هەناسە بدە، پاشان هەنگاوێکی بچووک بنێ.';
        rescueText = 'پلانی فریاگوزاری خێرا';
        breatheText = '10 جار بە هێواشی هەناسە بدە';
        nextText = 'دواتر';
        break;
      case AppLanguage.english:
        titleText = 'Feeling a strong urge?';
        subtitleText =
            'Pause for a moment. Read, breathe, then take one safe step.';
        rescueText = 'Quick rescue plan';
        breatheText = 'Take 10 slow breaths';
        nextText = 'Next';
        break;
    }

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
                      const Color(0xFF160B12),
                      const Color(0xFF2A1020),
                      const Color(0xFF071A22)
                    ]
                  : [
                      const Color(0xFFFFF1F2),
                      const Color(0xFFFFFBEB),
                      const Color(0xFFF0FDFA)
                    ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -90,
                right: -70,
                child: _buildGlowOrb(
                    const Color(0xFFFF4757), isDark ? 0.18 : 0.16, 250),
              ),
              Positioned(
                bottom: -110,
                left: -80,
                child: _buildGlowOrb(
                    const Color(0xFF0D9488), isDark ? 0.13 : 0.14, 280),
              ),
              Positioned(
                top: 130,
                left: 24,
                child: _buildSmallSpark(isDark, const Color(0xFFF59E0B)),
              ),
              Positioned(
                top: 210,
                right: 36,
                child: _buildSmallSpark(isDark, const Color(0xFFFF4757)),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(lang, isDark, titleText, subtitleText),
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFFFF4757),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                              child: Column(
                                children: [
                                  _buildRescueStrip(
                                      lang, isDark, rescueText, breatheText),
                                  const SizedBox(height: 18),
                                  Expanded(
                                    child: _isChangingTip
                                        ? _buildLoadingCard(isDark)
                                        : FadeTransition(
                                            opacity: _fadeAnimation,
                                            child: _buildTipCard(
                                              lang,
                                              isDark,
                                              tipText.isEmpty ? '...' : tipText,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_tipsService.totalTips > 1)
                                    _buildNextButton(lang, isDark, nextText),
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

  Widget _buildSmallSpark(bool isDark, Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.55 : 0.36),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.25), blurRadius: 18, spreadRadius: 7),
        ],
      ),
    );
  }

  Widget _buildHeader(
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
                    color: isDark ? Colors.white10 : const Color(0xFFFFCDD2)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4757)
                        .withOpacity(isDark ? 0.14 : 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                lang.isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : const Color(0xFF7F1D1D),
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
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF7F1D1D),
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
                    color: isDark ? Colors.white60 : const Color(0xFF7A4E52),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRescueStrip(
      LanguageService lang, bool isDark, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFFFF4757).withOpacity(0.36),
                  const Color(0xFF0D9488).withOpacity(0.24)
                ]
              : [const Color(0xFFFF4757), const Color(0xFFF97316)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4757).withOpacity(0.24),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Icon(Icons.health_and_safety_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: lang.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: lang.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFFFD7DA)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF4757)),
      ),
    );
  }

  Widget _buildTipCard(LanguageService lang, bool isDark, String tipText) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFFFD7DA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4757).withOpacity(isDark ? 0.10 : 0.12),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned(
              top: 20,
              right: lang.isRTL ? null : 20,
              left: lang.isRTL ? 20 : null,
              child: Icon(
                Icons.format_quote_rounded,
                size: 58,
                color:
                    const Color(0xFFFF4757).withOpacity(isDark ? 0.16 : 0.11),
              ),
            ),
            Scrollbar(
              thumbVisibility: true,
              thickness: 4,
              radius: const Radius.circular(10),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 130),
                physics: const BouncingScrollPhysics(),
                child: Text(
                  tipText,
                  textAlign: TextAlign.center,
                  style: lang.getTextStyle(
                    fontSize: 20,
                    height: 1.85,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? Colors.white.withOpacity(0.92)
                        : const Color(0xFF351016),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.20)
                      : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_rounded,
                        color: Color(0xFFFF4757), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      lang.currentLanguage == AppLanguage.arabic
                          ? 'انتظر 90 ثانية قبل أي قرار'
                          : lang.currentLanguage == AppLanguage.kurdish
                              ? '90 چرکە چاوەڕێبە پێش هەر بڕیارێک'
                              : 'Wait 90 seconds before any decision',
                      style: lang.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color:
                            isDark ? Colors.white70 : const Color(0xFF7F1D1D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton(LanguageService lang, bool isDark, String nextText) {
    return GestureDetector(
      onTap: _nextTip,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFF4757), Color(0xFF0D9488)]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4757).withOpacity(0.24),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              nextText,
              style: lang.getTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
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
                isDark
                    ? Colors.amber.withOpacity(0.5)
                    : Colors.brown.withOpacity(0.3),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(
          Icons.star,
          size: 16,
          color: isDark
              ? Colors.amber.withOpacity(0.5)
              : Colors.brown.withOpacity(0.4),
        ),
        const SizedBox(width: 10),
        Container(
          width: 50,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDark
                    ? Colors.amber.withOpacity(0.5)
                    : Colors.brown.withOpacity(0.3),
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
              color: isDark
                  ? Colors.amber.withOpacity(0.3)
                  : Colors.brown.withOpacity(0.3),
              width: 2,
            ),
            left: BorderSide(
              color: isDark
                  ? Colors.amber.withOpacity(0.3)
                  : Colors.brown.withOpacity(0.3),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
