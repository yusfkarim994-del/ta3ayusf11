import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/language_service.dart';
import '../../services/badges_service.dart';

class CertificatesScreen extends StatelessWidget {
  final int userDays;
  final String userName;
  final DateTime? startDate;

  const CertificatesScreen({
    super.key,
    required this.userDays,
    required this.userName,
    this.startDate,
  });

  static const Color gold = Color(0xFFD4AF37);
  static const Color darkBrown = Color(0xFF3E2723);
  static const Color mediumBrown = Color(0xFF5D4037);
  static const Color lightBrown = Color(0xFF8D6E63);

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService();
    final isDark = lang.isDarkMode;
    final allBadges = BadgesService.allBadges;
    final earnedBadges = BadgesService.getEarnedBadges(userDays);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0a1628) : const Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1a2a4a) : const Color(0xFFF5F5DC),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF4CAF50)]),
                shape: BoxShape.circle,
              ),
              child: Image.asset('assets/images/graduation_cap.png', width: 28, height: 28, fit: BoxFit.contain),
            ),
            const SizedBox(width: 12),
            Text(
              _getTitle(lang),
              style: lang.getTextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${earnedBadges.length}/${allBadges.length}',
              style: lang.getTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: allBadges.length,
        itemBuilder: (context, index) => _buildCertificate(allBadges[index], lang, isDark),
      ),
    );
  }

  String _getTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish: return 'بڕوانامەکان';
      case AppLanguage.arabic: return 'الشهادات';
      case AppLanguage.english: return 'Certificates';
    }
  }

  Widget _buildCertificate(AchievementBadge badge, LanguageService lang, bool isDark) {
    final isUnlocked = userDays >= badge.daysRequired;
    final name = _getBadgeName(badge, lang);
    final displayColor = isUnlocked ? badge.color : Colors.grey;
    final progress = badge.daysRequired == 0 ? 1.0 : (userDays / badge.daysRequired).clamp(0.0, 1.0);
    final remainingDays = (badge.daysRequired - userDays).clamp(0, 5000);

    final certTitle = _getCertTitle(lang);
    final congratsText = _getCongratsText(lang, isUnlocked, name);
    final motivationQuote = _getMotivationQuote(lang, isUnlocked);
    final awardedTo = _getAwardedToText(lang);
    final daysText = _getDaysText(badge, lang);

    final now = DateTime.now();
    final targetDate = isUnlocked
        ? now.subtract(Duration(days: userDays - badge.daysRequired))
        : now.add(Duration(days: remainingDays));
    final targetDateStr = '${targetDate.day.toString().padLeft(2, '0')}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.year}';

    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.45,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: displayColor.withOpacity(0.2),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isUnlocked
                  ? [const Color(0xFFFFFCF2), const Color(0xFFF5E6C8), const Color(0xFFFFF8E1)]
                  : [Colors.grey.shade200, Colors.grey.shade300],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Outer decorative border
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUnlocked ? gold.withOpacity(0.6) : Colors.grey.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
              ),
              // Inner decorative border
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUnlocked ? gold.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
              ),
              // Corner ornaments
              ..._buildCornerStars(isUnlocked),
              // Main content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Top star decoration
                    _buildStarRow(isUnlocked),

                    const SizedBox(height: 8),

                    // Platform name
                    Text(
                      'منصة لا أبرح',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? darkBrown : Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Decorative line
                    Container(
                      width: 120,
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, gold, Colors.transparent],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Certificate badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [displayColor, displayColor.withOpacity(0.75)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: displayColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        certTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Trophy icon with glow
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isUnlocked)
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: gold.withOpacity(0.1),
                              boxShadow: [
                                BoxShadow(
                                  color: gold.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        Icon(
                          Icons.workspace_premium_rounded,
                          color: isUnlocked ? gold : Colors.grey,
                          size: isUnlocked ? 60 : 50,
                        ),
                        if (!isUnlocked)
                          const Positioned(
                            right: 0,
                            top: 0,
                            child: Icon(Icons.lock, color: Colors.grey, size: 20),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Star row
                    _buildStarRow(isUnlocked),

                    const SizedBox(height: 8),

                    // Badge name
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? darkBrown : Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Congrats text
                    Text(
                      congratsText,
                      textAlign: TextAlign.center,
                      style: lang.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isUnlocked ? lightBrown : Colors.grey,
                        height: 1.6,
                      ),
                    ),

                    if (motivationQuote.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: gold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: gold.withOpacity(0.3)),
                        ),
                        child: Text(
                          motivationQuote,
                          textAlign: TextAlign.center,
                          style: lang.getTextStyle(
                            fontSize: 12,
                            color: gold,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Motivational message
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isUnlocked ? Colors.white.withOpacity(0.55) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isUnlocked ? displayColor.withOpacity(0.2) : Colors.grey.withOpacity(0.15),
                        ),
                      ),
                      child: Text(
                        _getMotivationalMessage(lang, isUnlocked, badge.daysRequired),
                        textAlign: TextAlign.center,
                        style: lang.getTextStyle(
                          fontSize: 12,
                          height: 1.7,
                          fontWeight: FontWeight.w600,
                          color: isUnlocked ? const Color(0xFF4E342E) : Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Decorative divider
                    Row(
                      children: [
                        Expanded(child: Container(height: 1, color: gold.withOpacity(0.3))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.star, size: 10, color: gold.withOpacity(0.6)),
                        ),
                        Expanded(child: Container(height: 1, color: gold.withOpacity(0.3))),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Awarded to text
                    Text(
                      awardedTo,
                      style: lang.getTextStyle(
                        fontSize: 13,
                        color: isUnlocked ? lightBrown : Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // User name
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: gold.withOpacity(0.5), width: 2),
                        ),
                      ),
                      child: Text(
                        userName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? mediumBrown : Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Wax seal
                    if (isUnlocked) _buildWaxSeal(),

                    const SizedBox(height: 10),

                    // Days text
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: displayColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: displayColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        daysText,
                        style: lang.getTextStyle(
                          fontSize: 13,
                          color: isUnlocked ? displayColor : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(displayColor),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Progress text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(progress * 100).floor()}%',
                          style: lang.getTextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: displayColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isUnlocked
                              ? (lang.currentLanguage == AppLanguage.arabic
                                  ? 'تم فتح الشهادة'
                                  : lang.currentLanguage == AppLanguage.kurdish
                                      ? 'بڕوانامەکراوە'
                                      : 'Certificate Unlocked')
                              : '$remainingDays ${lang.currentLanguage == AppLanguage.arabic ? 'يوم متبقي' : lang.currentLanguage == AppLanguage.kurdish ? 'ڕۆژ ماوە' : 'days remaining'}',
                          style: lang.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: lightBrown,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Date
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: displayColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: displayColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        targetDateStr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: displayColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Signature
                    _buildSignature(isUnlocked, lang),

                    const SizedBox(height: 10),

                    // Bottom stars
                    _buildStarRow(isUnlocked),

                    const SizedBox(height: 4),

                    // Platform text
                    Text(
                      _getPlatformText(lang),
                      textAlign: TextAlign.center,
                      style: lang.getTextStyle(
                        fontSize: 10,
                        color: isUnlocked ? lightBrown.withOpacity(0.6) : Colors.grey.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
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

  Widget _buildStarRow(bool isUnlocked) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Icon(
          Icons.star_rounded,
          color: isUnlocked ? gold.withOpacity(0.8) : Colors.grey.withOpacity(0.4),
          size: 16,
        ),
      )),
    );
  }

  Widget _buildWaxSeal() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF8B0000), Color(0xFF5C0000)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: gold.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: gold.withOpacity(0.4), width: 2),
      ),
      child: Center(
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Center(
            child: Icon(
              Icons.workspace_premium,
              color: const Color(0xFFF5E6C8),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignature(bool isUnlocked, LanguageService lang) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 1,
          color: isUnlocked ? gold.withOpacity(0.4) : Colors.grey.withOpacity(0.3),
        ),
        const SizedBox(height: 8),
        Text(
          'La Abrah',
          style: GoogleFonts.dancingScript(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isUnlocked ? darkBrown : Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          lang.currentLanguage == AppLanguage.arabic
              ? 'الإدارة العامة'
              : lang.currentLanguage == AppLanguage.kurdish
                  ? 'بەڕێوەبەرایەتی گشتی'
                  : 'General Management',
          style: lang.getTextStyle(
            fontSize: 10,
            color: isUnlocked ? lightBrown.withOpacity(0.7) : Colors.grey.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCornerStars(bool isUnlocked) {
    final color = isUnlocked ? gold.withOpacity(0.3) : Colors.grey.withOpacity(0.2);
    return [
      Positioned(top: 16, left: 16, child: Icon(Icons.star, size: 18, color: color)),
      Positioned(top: 16, right: 16, child: Icon(Icons.star, size: 18, color: color)),
      Positioned(bottom: 16, left: 16, child: Icon(Icons.star, size: 18, color: color)),
      Positioned(bottom: 16, right: 16, child: Icon(Icons.star, size: 18, color: color)),
    ];
  }

  String _getCertTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish: return 'بڕوانامەی سەرکەوتن';
      case AppLanguage.arabic: return 'شهادة الإنجاز';
      case AppLanguage.english: return 'Certificate of Achievement';
    }
  }

  String _getCongratsText(LanguageService lang, bool isUnlocked, String name) {
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish:
        return isUnlocked
            ? '🎉 پیرۆزە و هەزار پیرۆز! 🎉\nتۆ بە ئیرادەی پۆڵاینت و بەهێزی دڵت\nگەیشتیت بە ئاستی "$name"\nئەمە دەستکەوتێکی گەورەیە!'
            : 'تۆ هێشتا نەگەیشتوویتە\n"$name"\nبەڵام ڕێگاکەت ڕاستە!';
      case AppLanguage.arabic:
        return isUnlocked
            ? '🎉 مبارك! ألف مبارك! 🎉\nبإرادتك الحديدية وقوة عزيمتك\nوصلت إلى مستوى "$name"\nهذا إنجاز عظيم!'
            : 'لم تصل بعد إلى\n"$name"\nلكنك على الطريق الصحيح!';
      case AppLanguage.english:
        return isUnlocked
            ? '🎉 Congratulations! 🎉\nWith your iron will and determination\nyou have reached "$name"\nThis is a great achievement!'
            : 'You have not yet reached\n"$name"\nbut you are on the right path!';
    }
  }

  String _getMotivationQuote(LanguageService lang, bool isUnlocked) {
    if (!isUnlocked) return '';
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish:
        return '✨ كُلُّ نَفسٍ ذَائِقَةُ الْمَوْتِ ✨\nبەردەوام بە لەسەر ڕێگای چاکبوونەوە!';
      case AppLanguage.arabic:
        return '✨ وَمَن جَاهَدَ فَإِنَّمَا يُجَاهِدُ لِنَفْسِهِ ✨\nاستمر على طريق التعافي!';
      case AppLanguage.english:
        return '✨ Keep going on the path of recovery! ✨';
    }
  }

  String _getAwardedToText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish: return 'ئەم بڕوانامەی شانازییە دەدرێت بە:';
      case AppLanguage.arabic: return 'تُمنح هذه الشهادة الفخرية إلى:';
      case AppLanguage.english: return 'This honorary certificate is awarded to:';
    }
  }

  String _getDaysText(AchievementBadge badge, LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish: return '${badge.daysRequired} ڕۆژی چاکبوونەوە';
      case AppLanguage.arabic: return '${badge.daysRequired} يوم من التعافي';
      case AppLanguage.english: return '${badge.daysRequired} Days of Recovery';
    }
  }

  String _getMotivationalMessage(LanguageService lang, bool isUnlocked, int daysRequired) {
    if (!isUnlocked) {
      switch (lang.currentLanguage) {
        case AppLanguage.kurdish: return 'بەردەوام بە بۆ بەدەستهێنانی ئەم بڕوانامەیە';
        case AppLanguage.arabic: return 'استمر للحصول على هذه الشهادة';
        case AppLanguage.english: return 'Keep going to earn this certificate';
      }
    }
    final messages = {
      1: lang.currentLanguage == AppLanguage.arabic
          ? 'البداية دائماً هي أصعب جزء في أي رحلة تغيير.\nلكن اختيارك للمقاومة اليوم يعني أنك بدأت تستعيد السيطرة على نفسك.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'دەستپێکردن هەمیشە سەختترین بەشە لە هەر گەشتێک.\nبەڵام هەڵبژاردنی تو بۆ بەرگری ئەمڕۆ واتایە دەستی پێکردت بە کۆنترۆڵکردنی خۆت.'
              : 'Starting is always the hardest part.\nBut choosing to resist today means you are regaining control.',
      7: lang.currentLanguage == AppLanguage.arabic
          ? 'أسبوع كامل من الصبر والانتصار على الرغبات.\nعقلك وجسدك بدآ الآن بالشعور بالتحسن.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'هەفتەیەکی تەواو لە شوێندان و سەرکەوتن لەسەر خوازەکان.\nمێغ و جەستەکەت ئێستا دەستی پێکرد بە هەستکردن بە باشتر بوون.'
              : 'A full week of patience and overcoming urges.\nYour mind and body are now starting to feel better.',
      14: lang.currentLanguage == AppLanguage.arabic
          ? 'أربعة عشر يوماً من الثبات تعني أنك تجاوزت مرحلة خطيرة.\nأصبحت ترى الأمور بوضوح أكبر.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'ڕۆژی 14 لە جێگڕان واتایە تۆ تێپەڕیتەوە بەردەوامەیەکی مەترسیدار.\nئێستا دەتەوێت شتەکان ببینیت بە ڕوونی زیاتر.'
              : '14 days of steadiness means you passed a dangerous stage.\nYou now see things more clearly.',
      30: lang.currentLanguage == AppLanguage.arabic
          ? 'ثلاثون يوماً من الالتزام تعني أنك صنعت فرقاً حقيقياً في حياتك.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'ڕۆژی 30 لە پابەندبوون واتایە جیاوازییەکی ڕاستەقینەت کردووە لە ژیانت.'
              : '30 days of commitment means you made a real difference in your life.',
      40: lang.currentLanguage == AppLanguage.arabic
          ? 'أربعون يوماً من الصبر صنعت في داخلك قوة لم تكن تشعر بها من قبل.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'ڕۆژی 40 لە شوێندان توانایەکی نوێت دروستکرد لە ناخەکەت.'
              : '40 days of patience built a strength inside you that you never felt before.',
      60: lang.currentLanguage == AppLanguage.arabic
          ? 'ستون يوماً من المقاومة تعني أنك أصبحت أقرب إلى الحرية الحقيقية.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'ڕۆژی 60 لە بەرگری واتایە تۆ نزیکتریت بە ئازادیی ڕاستەقینە.'
              : '60 days of resistance means you are closer to true freedom.',
      75: lang.currentLanguage == AppLanguage.arabic
          ? 'خمسة وسبعون يوماً من الالتزام ليست مجرد فترة زمنية بل قصة انتصار كاملة.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'ڕۆژی 75 لە پابەندبوون تەنها کات نییە بلکە چیرۆکی سەرکەوتنی تەواوە.'
              : '75 days of commitment is not just a time period but a complete victory story.',
      90: lang.currentLanguage == AppLanguage.arabic
          ? 'الوصول إلى تسعين يوماً هو انتصار استثنائي لا يصل إليه إلا أصحاب الإرادة الحقيقية.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'گەیشتن بۆ ڕۆژی 90 سەرکەوتنێکی تایبەتە کە تەنها ڕەنەدەرانی ڕادەبەستێت.'
              : 'Reaching 90 days is an exceptional victory only for those with real willpower.',
      100: lang.currentLanguage == AppLanguage.arabic
          ? 'مئة يوم من الصمود تعني أنك لم تعد الشخص نفسه الذي بدأ الرحلة.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'ڕۆژی 100 لە بەرپەرچبوون واتایە تۆ کەسی هەمان شێوە نییت کە گەشتەکەی دەستی پێکرد.'
              : '100 days of endurance means you are no longer the same person who started.',
      125: lang.currentLanguage == AppLanguage.arabic
          ? 'وصولك إلى مئة وخمسة وعشرين يوماً دليل على أنك تجاوزت مرحلة الاعتماد القديمة.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'گەیشتن بۆ ڕۆژی 125 دڵیلی ئەوەیە تۆ تێپەڕیتەوە بەردەوامی کۆن.'
              : 'Reaching 125 days proves you passed the old dependency stage.',
      150: lang.currentLanguage == AppLanguage.arabic
          ? 'مئة وخمسون يوماً من الثبات ليست مجرد إنجاز عابر بل أسلوب حياة جديد.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'ڕۆژی 150 لە جێگڕان تەنها دەستکەوتێکی ناواش نییە بلکە شێوازی نوێی ژیانە.'
              : '150 days of steadiness is not just a passing achievement but a new lifestyle.',
      175: lang.currentLanguage == AppLanguage.arabic
          ? 'عند هذا المستوى تبدأ النتائج العميقة بالظهور في شخصيتك وحياتك اليومية.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'لەم ئاستە دەستی دەکەیت بە ئاشکراکردنی ئەنجامە گەورەکان لە کەسییەت و ژیانی ڕۆژانەکەت.'
              : 'At this level, deep results start appearing in your personality and daily life.',
      200: lang.currentLanguage == AppLanguage.arabic
          ? 'مئتا يوم من الصبر والإرادة تعني أنك قطعت رحلة استثنائية بكل المقاييس.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'ڕۆژی 200 لە شوێندان و ڕادە واتایە تۆ گەشتێکی تایبەت قطعت بە هەموو پێوانەکان.'
              : '200 days of patience and willpower means you traveled an exceptional journey.',
      225: lang.currentLanguage == AppLanguage.arabic
          ? 'كل يوم من هذه الرحلة الطويلة أضاف قوة جديدة إلى روحك وشخصيتك.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'هەر ڕۆژێک لەم گەشتە درێژە توانایەکی نوێ زیادکرد بۆ روان و کەسییەتکەت.'
              : 'Every day of this long journey added new strength to your soul and personality.',
      250: lang.currentLanguage == AppLanguage.arabic
          ? 'ربع ألف يوم من الالتزام يعني أنك تجاوزت حدود العادة القديمة بالكامل تقريباً.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'ڕۆژی 250 لە پابەندبوون واتایە تۆ تێپەڕیتەوە هەموو سنوورەکانی ڕەوشتی کۆن تەواو.'
              : '250 days of commitment means you almost completely surpassed old habits.',
      275: lang.currentLanguage == AppLanguage.arabic
          ? 'في هذه المرحلة لم تعد المقاومة مجرد واجب بل أصبحت جزءاً من هويتك الجديدة.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'لەم قۆناغە تەنها بەرگری ئەرک نییە بلکە بەشێکی هەیەتی نوێت بووە.'
              : 'At this stage, resistance is no longer a duty but part of your new identity.',
      300: lang.currentLanguage == AppLanguage.arabic
          ? 'ثلاثمئة يوم من الثبات تعني أنك صنعت قصة نجاح نادرة يصعب تكرارها.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'ڕۆژی 300 لە جێگڕان واتایە چیرۆکی سەرکەوتنێکی نایابت دروستکردووە.'
              : '300 days of steadiness means you created a rare success story.',
      350: lang.currentLanguage == AppLanguage.arabic
          ? 'كل ما وصلت إليه اليوم هو نتيجة مئات القرارات الصحيحة التي اتخذتها بصبر.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'هەموو ئەوەی ئێستا گەیشتوویت ئەنجامی سەدان بڕیاری ڕاستن کە بە شوێندان هەڵبژیاردوون.'
              : 'Everything you reached today is the result of hundreds of right decisions.',
      400: lang.currentLanguage == AppLanguage.arabic
          ? 'أربعمئة يوم من الالتزام تعني أنك أصبحت شخصاً جديداً فعلاً.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'ڕۆژی 400 لە پابەندبوون واتایە تۆ بە راستی کەسی نوێ بوویت.'
              : '400 days of commitment means you truly became a new person.',
      450: lang.currentLanguage == AppLanguage.arabic
          ? 'مع كل يوم إضافي تثبت أن النجاح الحقيقي يحتاج إلى صبر طويل ونفس قوي.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'بە هەر ڕۆژێکی زیاتر دەپرۆڤەیت ئەوەی سەرکەوتنی ڕاستەقینە پێویستی بە شوێندانی درێژ و دڵی بەهێز هەیە.'
              : 'With every extra day, you prove that real success needs long patience and strong will.',
      500: lang.currentLanguage == AppLanguage.arabic
          ? 'خمسمئة يوم من الصمود ليست مجرد رحلة تعافٍ بل رحلة إعادة بناء كاملة للنفس.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'ڕۆژی 500 لە بەرپەرچبوون تەنها گەشتی چاکبوونەوە نییە بلکە گەشتی دروستکردنەوەی تەواوی دڵ.'
              : '500 days of endurance is not just a recovery journey but a complete rebuilding of the soul.',
      600: lang.currentLanguage == AppLanguage.arabic
          ? 'ست مئة يوم من الثبات تعني أنك وصلت إلى مستوى نادر من التحكم والوعي الذاتي.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'ڕۆژی 600 لە جێگڕان واتایە گەیشتیت بۆ ئاستێکی نایاب لە کۆنترۆڵ و ئاگایی خۆت.'
              : '600 days of steadiness means you reached a rare level of self-control.',
      700: lang.currentLanguage == AppLanguage.arabic
          ? 'سبعمئة يوم من الالتزام تكشف عن شخصية صلبة لا تنكسر بسهولة.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'ڕۆژی 700 لە پابەندبوون کەسییەکی بەهێز ئاشکرا دەکات کە بە ئاسانی ناکەرێت.'
              : '700 days of commitment reveals a strong personality that cannot be easily broken.',
      800: lang.currentLanguage == AppLanguage.arabic
          ? 'ثمانمئة يوم من النجاح المستمر تعني أنك أصبحت قدوة حقيقية في الصبر والانضباط.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'ڕۆژی 800 لە سەرکەوتنی بەردەوام واتایە تۆ بوویت نموونەیەکی ڕاستەقینەی شوێندان و ڕێکخستن.'
              : '800 days of continuous success means you became a real role model.',
      900: lang.currentLanguage == AppLanguage.arabic
          ? 'تسعمئة يوم من الثبات تعني أنك بنيت حياة جديدة بالكامل بعيداً عن الماضي.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'ڕۆژی 900 لە جێگڕان واتایە ژیانێکی نوێی تەواو دروستکردووە بە دووری لە ڕابردوو.'
              : '900 days of steadiness means you built a completely new life away from the past.',
      1000: lang.currentLanguage == AppLanguage.arabic
          ? 'ألف يوم من الإرادة والصبر والانتصار تعني أنك وصلت إلى مرحلة عظيمة جداً.'
          : lang.currentLanguage == AppLanguage.kurdish
              ? 'ڕۆژی 1000 لە ڕادە و شوێندان و سەرکەوتن واتایە گەیشتیت بۆ قۆناغێکی زۆر گەورە.'
              : '1000 days of willpower, patience and victory means you reached a very great stage.',
    };
    return messages[daysRequired] ??
        (lang.currentLanguage == AppLanguage.arabic
            ? 'كل شهادة هنا تمثل مرحلة مختلفة من قوتك ونضجك الداخلي.'
            : lang.currentLanguage == AppLanguage.kurdish
                ? 'هەر بڕوانامەیەک لێرە نموونەیەکی جیاواکی توانا و بالغانی ناوخۆکەت ئەمێنێت.'
                : 'Each certificate here represents a different stage of your strength and maturity.');
  }

  String _getPlatformText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish: return 'ئەم بڕوانامەیە لەلایەن پلاتفۆرمی لا أبرح دراوە';
      case AppLanguage.arabic: return 'هذه الشهادة صادرة من منصة لا أبرح';
      case AppLanguage.english: return 'This certificate is issued by La Abrah Platform';
    }
  }

  String _getBadgeName(AchievementBadge badge, LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish: return badge.nameKu;
      case AppLanguage.arabic: return badge.nameAr;
      case AppLanguage.english: return badge.nameEn;
    }
  }
}
