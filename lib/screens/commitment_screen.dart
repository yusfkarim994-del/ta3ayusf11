import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/commitment_service.dart';
import '../services/auth_service.dart';

class CommitmentScreen extends StatefulWidget {
  const CommitmentScreen({super.key});

  @override
  State<CommitmentScreen> createState() => _CommitmentScreenState();
}

class _CommitmentScreenState extends State<CommitmentScreen>
    with TickerProviderStateMixin {
  final _commitmentService = CommitmentService();
  final _authService = AuthService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;
  bool _isWritingMode = false;
  final TextEditingController _letterController = TextEditingController();
  bool _isAutoSaving = false;

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
    await _commitmentService.loadLetters();
    setState(() => _isLoading = false);
    _fadeController.forward();
  }

  String _getUserName(LanguageService lang) {
    final user = _authService.currentUser;
    if (user == null) return lang.guest;
    if (user.isAnonymous) return lang.guest;
    return user.displayName ?? user.email?.split('@').first ?? lang.guest;
  }

  void _saveLetter(LanguageService lang) async {
    if (_letterController.text.trim().isEmpty) return;

    if (_isAutoSaving) return;
    _isAutoSaving = true;

    final success = await _commitmentService.addLetter(
      _letterController.text.trim(),
      _getUserName(lang),
    );

    if (success && mounted) {
      setState(() {
        _isWritingMode = false;
        _letterController.clear();
        _isAutoSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.currentLanguage == AppLanguage.arabic
                ? 'تم حفظ رسالتك بنجاح!'
                : lang.currentLanguage == AppLanguage.kurdish
                    ? 'نامەکەت پاشەکەوت کرا!'
                    : 'Your letter was saved!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _isAutoSaving = false;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _letterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = lang.isDarkMode;

    // Colors
    const purpleColor = Color(0xFF0F766E);
    const amberColor = Color(0xFFF59E0B);

    // Translations
    String titleText;
    String subtitleText;
    String writeNewText;
    String saveText;
    String cancelText;
    String placeholderText;
    String noLettersText;
    String signatureText;

    switch (lang.currentLanguage) {
      case AppLanguage.arabic:
        titleText = 'وثيقة الالتزام';
        subtitleText = 'رسائلك لنفسك المستقبلية';
        writeNewText = 'اكتب رسالة جديدة';
        saveText = 'حفظ الرسالة';
        cancelText = 'إلغاء';
        placeholderText =
            'اكتب رسالتك هنا...\n\nتذكر أن هذه الرسالة لنفسك المستقبلية. اكتب ما تريد أن تذكر نفسك به في لحظات الضعف...';
        noLettersText =
            'لم تكتب أي رسائل بعد\nاضغط على الزر أدناه لكتابة رسالتك الأولى';
        signatureText = 'بتوقيع';
        break;
      case AppLanguage.kurdish:
        titleText = 'بەڵێننامەی پابەندبوون';
        subtitleText = 'نامەکانت بۆ داهاتووی خۆت';
        writeNewText = 'نامەی نوێ بنووسە';
        saveText = 'پاشەکەوتی نامە';
        cancelText = 'پەشیمانبوونەوە';
        placeholderText =
            'نامەکەت لێرە بنووسە...\n\nبیرت بێت ئەم نامەیە بۆ داهاتووی خۆتە. ئەوەی دەتەوێت لە کاتی لاوازییدا بیرت بێتەوە بینووسە...';
        noLettersText =
            'هێشتا هیچ نامەیەکت نەنووسیوە\nکلیک لە دوگمەی خوارەوە بکە بۆ نووسینی یەکەم نامە';
        signatureText = 'بە واژۆی';
        break;
      case AppLanguage.english:
        titleText = 'Commitment Document';
        subtitleText = 'Letters to Your Future Self';
        writeNewText = 'Write a New Letter';
        saveText = 'Save Letter';
        cancelText = 'Cancel';
        placeholderText =
            'Write your letter here...\n\nRemember, this letter is for your future self. Write what you want to remember during moments of weakness...';
        noLettersText =
            'You haven\'t written any letters yet\nTap the button below to write your first letter';
        signatureText = 'Signed by';
        break;
    }

    final letter = _commitmentService.currentLetter;

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
                      const Color(0xFF051614),
                      const Color(0xFF102A27),
                      const Color(0xFF111827)
                    ]
                  : [
                      const Color(0xFFF4FFFB),
                      const Color(0xFFFFF7E8),
                      const Color(0xFFEAF3FF)
                    ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -70,
                left: -60,
                child: _buildSoftOrb(
                    isDark ? amberColor : const Color(0xFF0D9488),
                    isDark ? 0.14 : 0.16,
                    230),
              ),
              Positioned(
                bottom: -90,
                right: -70,
                child: _buildSoftOrb(
                    const Color(0xFF38BDF8), isDark ? 0.10 : 0.14, 260),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildModernHeader(lang, isDark, titleText, subtitleText),

                    // Main content - maximized for mobile
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                  color: isDark ? amberColor : purpleColor))
                          : Padding(
                              padding: const EdgeInsets.only(
                                  left: 8, right: 8, bottom: 8),
                              child: Column(
                                children: [
                                  // Content area - fills remaining space
                                  Expanded(
                                    child: _isWritingMode
                                        ? _buildModernWritingMode(
                                            lang,
                                            isDark,
                                            placeholderText,
                                            saveText,
                                            cancelText)
                                        : _buildModernViewMode(
                                            lang,
                                            isDark,
                                            letter,
                                            noLettersText,
                                            signatureText),
                                  ),

                                  const SizedBox(height: 8),

                                  // Write new button
                                  if (!_isWritingMode)
                                    GestureDetector(
                                      onTap: () =>
                                          setState(() => _isWritingMode = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 32, vertical: 14),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: isDark
                                                ? [
                                                    amberColor,
                                                    amberColor.withOpacity(0.7)
                                                  ]
                                                : [
                                                    purpleColor,
                                                    purpleColor.withOpacity(0.8)
                                                  ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isDark
                                                      ? amberColor
                                                      : purpleColor)
                                                  .withOpacity(0.4),
                                              blurRadius: 15,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.edit_rounded,
                                                color: Colors.white, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              writeNewText,
                                              style: lang.getTextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 16),
                                  _buildOrnament(isDark),
                                  const SizedBox(height: 16),
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

  Widget _buildSoftOrb(Color color, double opacity, double size) {
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
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
                lang.isRTL ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
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
                    color: isDark ? Colors.white : const Color(0xFF064E3B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: lang.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFFF59E0B)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildModernWritingMode(LanguageService lang, bool isDark,
      String placeholder, String saveText, String cancelText) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE0F2EF)),
            boxShadow: [
              BoxShadow(
                color:
                    const Color(0xFF0F766E).withOpacity(isDark ? 0.12 : 0.14),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF0F766E), const Color(0xFF1F2937)]
                          : [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.edit_note_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          lang.currentLanguage == AppLanguage.arabic
                              ? 'اكتب وعدا واضحا لنفسك'
                              : lang.currentLanguage == AppLanguage.kurdish
                                  ? 'بەڵێنێکی ڕوون بۆ خۆت بنووسە'
                                  : 'Write a clear promise to yourself',
                          style: lang.getTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _letterController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: lang.getTextStyle(
                      fontSize: 16,
                      height: 1.9,
                      color: isDark ? Colors.white : const Color(0xFF263238),
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF14232A).withOpacity(0.72)
                          : const Color(0xFFF8FAFC),
                      hintText: placeholder,
                      hintStyle: lang.getTextStyle(
                        fontSize: 14,
                        height: 1.7,
                        color:
                            isDark ? Colors.white38 : const Color(0xFF78909C),
                      ),
                      contentPadding: const EdgeInsets.all(24),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      if (value.trim().length > 20 && !_isAutoSaving) {
                        Future.delayed(const Duration(milliseconds: 700), () {
                          if (!mounted) return;

                          if (_isWritingMode &&
                              _letterController.text.trim() == value.trim() &&
                              value.trim().isNotEmpty) {
                            _saveLetter(lang);
                          }
                        });
                      }
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withOpacity(0.16)
                        : const Color(0xFFF8FAFC),
                    border: Border(
                        top: BorderSide(
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() {
                            _isWritingMode = false;
                            _letterController.clear();
                          }),
                          child: Text(cancelText,
                              style: lang.getTextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF64748B))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isAutoSaving ? null : () => _saveLetter(lang),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                          icon: Icon(
                            _isAutoSaving
                                ? Icons.sync_rounded
                                : Icons.save_rounded,
                            color: Colors.white,
                          ),
                          label: Text(saveText,
                              style: lang.getTextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900)),
                        ),
                      ),
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

  Widget _buildModernViewMode(LanguageService lang, bool isDark,
      CommitmentLetter? letter, String noLettersText, String signatureText) {
    if (letter == null) {
      return _buildCommitmentEmpty(lang, isDark, noLettersText);
    }

    final languageCode = lang.currentLanguage == AppLanguage.arabic
        ? 'arabic'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'kurdish'
            : 'english';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE0F2EF)),
            boxShadow: [
              BoxShadow(
                color:
                    const Color(0xFF0F766E).withOpacity(isDark ? 0.12 : 0.14),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF0D9488), Color(0xFFF59E0B)]),
                  ),
                  child: Row(
                    children: [
                      _buildWaxSeal(isDark, letter.userName),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _commitmentService.formatDate(
                                  letter.createdAt, languageCode),
                              style: lang.getTextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withOpacity(0.78)),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${signatureText} ${letter.userName}',
                              style: lang.getTextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(26),
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      letter.content,
                      style: lang.getTextStyle(
                        fontSize: 17,
                        height: 1.95,
                        color: isDark
                            ? Colors.white.withOpacity(0.92)
                            : const Color(0xFF263238),
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

  Widget _buildCommitmentEmpty(
      LanguageService lang, bool isDark, String noLettersText) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE0F2EF)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFFF59E0B)]),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.edit_document,
                  color: Colors.white, size: 42),
            ),
            const SizedBox(height: 20),
            Text(
              noLettersText,
              textAlign: TextAlign.center,
              style: lang.getTextStyle(
                fontSize: 15,
                height: 1.7,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF526D68),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerOrnament(bool isDark,
      {required bool top, required bool left}) {
    final goldColor =
        isDark ? const Color(0xFFFFD54F) : const Color(0xFFC5A059);
    return Positioned(
      top: top ? 12 : null,
      bottom: top ? null : 12,
      left: left ? 12 : null,
      right: left ? null : 12,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          border: Border(
            top: top
                ? BorderSide(color: goldColor.withOpacity(0.85), width: 2)
                : BorderSide.none,
            bottom: top
                ? BorderSide.none
                : BorderSide(color: goldColor.withOpacity(0.85), width: 2),
            left: left
                ? BorderSide(color: goldColor.withOpacity(0.85), width: 2)
                : BorderSide.none,
            right: left
                ? BorderSide.none
                : BorderSide(color: goldColor.withOpacity(0.85), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildWaxSeal(bool isDark, String name) {
    final sealColor =
        isDark ? const Color(0xFFB71C1C) : const Color(0xFF8B0000);
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : 'V';

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Ribbon behind seal
        Positioned(
          bottom: -15,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: -0.15,
                child: Container(
                  width: 10,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFFFFD54F).withOpacity(0.7)
                        : const Color(0xFFC5A059),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(2),
                      bottomRight: Radius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Transform.rotate(
                angle: 0.15,
                child: Container(
                  width: 10,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFFFFD54F).withOpacity(0.5)
                        : const Color(0xFFB8860B),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(2),
                      bottomRight: Radius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Seal container
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: sealColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? const Color(0xFFFFD54F).withOpacity(0.3)
                  : const Color(0xFFC5A059).withOpacity(0.4),
              width: 1.5,
            ),
            gradient: RadialGradient(
              colors: [
                sealColor,
                sealColor.withRed(sealColor.red - 25),
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF5E6C8),
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWritingMode(LanguageService lang, bool isDark,
      String placeholder, String saveText, String cancelText) {
    // Vintage colors
    const inkBrown = Color(0xFF2C1A10);
    const waxSeal = Color(0xFF8B0000);
    const candleGlow = Color(0xFFFFD54F);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? candleGlow.withOpacity(0.4)
                    : const Color(0xFFC5A059).withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.6 : 0.3),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  // Parchment paper background using CustomPainter
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ParchmentPaperPainter(isDark: isDark),
                    ),
                  ),

                  // Semi-transparent parchment protection overlay (refined for gorgeous high-contrast programmatically generated background texture)
                  Positioned.fill(
                    child: Container(
                      color: isDark
                          ? const Color(0xFF160E06).withOpacity(0.72)
                          : const Color(0xFFFCF7EE).withOpacity(0.15),
                    ),
                  ),

                  // Elegant Inner Gold Frame
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                (isDark ? candleGlow : const Color(0xFFC5A059))
                                    .withOpacity(0.35),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),

                  // Corner Ornaments
                  _buildCornerOrnament(isDark, top: true, left: true),
                  _buildCornerOrnament(isDark, top: true, left: false),
                  _buildCornerOrnament(isDark, top: false, left: true),
                  _buildCornerOrnament(isDark, top: false, left: false),

                  // Quill pen decoration icon
                  Positioned(
                    top: 20,
                    right: lang.isRTL ? null : 20,
                    left: lang.isRTL ? 20 : null,
                    child: Icon(
                      Icons.edit_note,
                      size: 32,
                      color: isDark
                          ? candleGlow.withOpacity(0.4)
                          : const Color(0xFFC5A059).withOpacity(0.5),
                    ),
                  ),

                  // Content
                  Positioned.fill(
                    child: Column(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _letterController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: lang.getTextStyle(
                              fontSize: 17,
                              height: 1.8,
                              color:
                                  isDark ? const Color(0xFFFFF1D6) : inkBrown,
                            ),
                            decoration: InputDecoration(
                              hintText: placeholder,
                              hintStyle: lang.getTextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white30
                                    : inkBrown.withOpacity(0.4),
                              ),
                              contentPadding:
                                  const EdgeInsets.fromLTRB(28, 50, 28, 20),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        // Bottom bar with action buttons
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withOpacity(0.4)
                                : const Color(0xFFC5A059).withOpacity(0.08),
                            border: Border(
                              top: BorderSide(
                                color: isDark
                                    ? candleGlow.withOpacity(0.2)
                                    : const Color(0xFFC5A059).withOpacity(0.2),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => setState(() {
                                  _isWritingMode = false;
                                  _letterController.clear();
                                }),
                                child: Text(
                                  cancelText,
                                  style: lang.getTextStyle(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () => _saveLetter(lang),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isDark ? candleGlow : waxSeal,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 28, vertical: 12),
                                  elevation: 4,
                                  shadowColor: (isDark ? candleGlow : waxSeal)
                                      .withOpacity(0.3),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.save_rounded,
                                        size: 18,
                                        color: isDark
                                            ? const Color(0xFF2C1A10)
                                            : Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      saveText,
                                      style: lang.getTextStyle(
                                        color: isDark
                                            ? const Color(0xFF2C1A10)
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewMode(LanguageService lang, bool isDark,
      CommitmentLetter? letter, String noLettersText, String signatureText) {
    // Vintage colors
    const inkBrown = Color(0xFF2C1A10);
    const candleGlow = Color(0xFFFFD54F);

    if (letter == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFC5A059).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mail_outline_rounded,
                size: 64,
                color: isDark
                    ? candleGlow.withOpacity(0.7)
                    : const Color(0xFFC5A059),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              noLettersText,
              textAlign: TextAlign.center,
              style: lang.getTextStyle(
                fontSize: 15,
                color: isDark ? Colors.white60 : inkBrown.withOpacity(0.7),
                height: 1.6,
              ),
            ),
          ],
        ),
      );
    }

    final languageCode = lang.currentLanguage == AppLanguage.arabic
        ? 'arabic'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'kurdish'
            : 'english';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? candleGlow.withOpacity(0.4)
                    : const Color(0xFFC5A059).withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.6 : 0.3),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  // Parchment paper background using CustomPainter
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ParchmentPaperPainter(isDark: isDark),
                    ),
                  ),

                  // Semi-transparent parchment protection overlay (refined for gorgeous high-contrast programmatically generated background texture)
                  Positioned.fill(
                    child: Container(
                      color: isDark
                          ? const Color(0xFF160E06).withOpacity(0.72)
                          : const Color(0xFFFCF7EE).withOpacity(0.15),
                    ),
                  ),

                  // Elegant Inner Gold Frame
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                (isDark ? candleGlow : const Color(0xFFC5A059))
                                    .withOpacity(0.35),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),

                  // Corner Ornaments
                  _buildCornerOrnament(isDark, top: true, left: true),
                  _buildCornerOrnament(isDark, top: true, left: false),
                  _buildCornerOrnament(isDark, top: false, left: true),
                  _buildCornerOrnament(isDark, top: false, left: false),

                  // Content Column
                  Positioned.fill(
                    child: Column(
                      children: [
                        // Date header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withOpacity(0.3)
                                : const Color(0xFFC5A059).withOpacity(0.08),
                            border: Border(
                              bottom: BorderSide(
                                color: isDark
                                    ? candleGlow.withOpacity(0.15)
                                    : const Color(0xFFC5A059).withOpacity(0.2),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: isDark
                                    ? candleGlow
                                    : const Color(0xFFC5A059),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _commitmentService.formatDate(
                                    letter.createdAt, languageCode),
                                style: lang.getTextStyle(
                                  fontSize: 14,
                                  color: isDark ? candleGlow : inkBrown,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Letter content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 30),
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              letter.content,
                              style: lang.getTextStyle(
                                fontSize: 17,
                                height: 1.9,
                                color:
                                    isDark ? const Color(0xFFFFF1D6) : inkBrown,
                              ),
                            ),
                          ),
                        ),

                        // Signature section with realistic wax seal stamp
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withOpacity(0.3)
                                : const Color(0xFFC5A059).withOpacity(0.06),
                            border: Border(
                              top: BorderSide(
                                color: isDark
                                    ? candleGlow.withOpacity(0.15)
                                    : const Color(0xFFC5A059).withOpacity(0.15),
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Decorative elegant scroll separator
                              Container(
                                width: 80,
                                height: 1,
                                color: isDark
                                    ? candleGlow.withOpacity(0.3)
                                    : const Color(0xFFC5A059).withOpacity(0.4),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                signatureText,
                                style: lang.getTextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white38
                                      : inkBrown.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildWaxSeal(isDark, letter.userName),
                                  const SizedBox(width: 16),
                                  Text(
                                    letter.userName,
                                    style: lang.getTextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? candleGlow : inkBrown,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrnament(bool isDark) {
    const purpleColor = Color(0xFF6A1B9A);
    const amberColor = Color(0xFFFFB300);

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
                    ? amberColor.withOpacity(0.5)
                    : purpleColor.withOpacity(0.3),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(
          Icons.edit_document,
          size: 16,
          color: isDark
              ? amberColor.withOpacity(0.5)
              : purpleColor.withOpacity(0.4),
        ),
        const SizedBox(width: 10),
        Container(
          width: 50,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDark
                    ? amberColor.withOpacity(0.5)
                    : purpleColor.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerDecoration(bool isDark, bool isLeft) {
    const purpleColor = Color(0xFF6A1B9A);
    const amberColor = Color(0xFFFFB300);

    return Transform.rotate(
      angle: isLeft ? 0 : 3.14159,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark
                  ? amberColor.withOpacity(0.3)
                  : purpleColor.withOpacity(0.3),
              width: 2,
            ),
            left: BorderSide(
              color: isDark
                  ? amberColor.withOpacity(0.3)
                  : purpleColor.withOpacity(0.3),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

// Parchment paper painter - creates aged paper with burnt/torn edges
class ParchmentPaperPainter extends CustomPainter {
  final bool isDark;

  ParchmentPaperPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Solid base paper color
    final basePaint = Paint()
      ..color = isDark ? const Color(0xFF1E140B) : const Color(0xFFFAF2DC);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // Burnt edge colors
    final edgeColor =
        isDark ? const Color(0xFF1A0F05) : const Color(0xFF5D4037);

    final outerBurnColor =
        isDark ? const Color(0xFF0D0705) : const Color(0xFF3E2723);

    // Create multiple layers for realistic burnt edge effect

    // Outer darkest edge (burnt)
    final outerEdgePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          outerBurnColor.withOpacity(0.6),
          Colors.transparent,
          Colors.transparent,
          outerBurnColor.withOpacity(0.6),
        ],
        stops: const [0.0, 0.08, 0.92, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), outerEdgePaint);

    // Top edge burnt gradient
    final topEdgePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          outerBurnColor.withOpacity(0.7),
          edgeColor.withOpacity(0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.05, 0.15],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.15), topEdgePaint);

    // Bottom edge burnt gradient
    final bottomEdgePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          outerBurnColor.withOpacity(0.7),
          edgeColor.withOpacity(0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.05, 0.15],
      ).createShader(
          Rect.fromLTWH(0, size.height * 0.85, size.width, size.height * 0.15));

    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.85, size.width, size.height * 0.15),
        bottomEdgePaint);

    // Add inner shadow/vignette for depth
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          Colors.transparent,
          edgeColor.withOpacity(isDark ? 0.2 : 0.12),
        ],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);

    // Subtle texture spots (aged paper stains)
    final stainPaint = Paint()
      ..color = edgeColor.withOpacity(isDark ? 0.08 : 0.05);

    // Random-looking spots for aged effect
    canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.2), 25, stainPaint);
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.75), 20, stainPaint);
    canvas.drawCircle(
        Offset(size.width * 0.3, size.height * 0.85), 18, stainPaint);
    canvas.drawCircle(
        Offset(size.width * 0.7, size.height * 0.15), 22, stainPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
