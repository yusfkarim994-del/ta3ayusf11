import 'package:flutter/material.dart';
import '../../services/language_service.dart';
import '../../services/badges_service.dart';

/// Certificates screen showing achievement certificates for earned badges
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

  static const Color islamicGold = Color(0xFFD4AF37);

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
                gradient: LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF4CAF50)]),
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
              color: const Color(0xFF4CAF50).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${earnedBadges.length}/${allBadges.length}',
              style: lang.getTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4CAF50),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: allBadges.length,
        itemBuilder: (context, index) => _buildCertificateCard(allBadges[index], lang, isDark),
      ),
    );
  }

  String _getTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish:
        return 'بڕوانامەکان';
      case AppLanguage.arabic:
        return 'الشهادات';
      case AppLanguage.english:
        return 'Certificates';
    }
  }

  Widget _buildCertificateCard(AchievementBadge badge, LanguageService lang, bool isDark) {
    final isUnlocked = userDays >= badge.daysRequired;
    final name = _getBadgeName(badge, lang);
    final displayColor = isUnlocked ? badge.color : Colors.grey;

    final certTitle = _getCertTitle(lang);
    final congratsText = _getCongratsText(lang, isUnlocked, name);
    final motivationQuote = _getMotivationQuote(lang, isUnlocked);
    final awardedTo = _getAwardedToText(lang);
    final daysText = _getDaysText(badge, lang);

    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.45,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1a2a4a), const Color(0xFF0d1a2d)]
                : [Colors.white, const Color(0xFFFFFDF5)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnlocked ? islamicGold : displayColor.withOpacity(0.4),
            width: 3,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(color: islamicGold.withOpacity(0.25), blurRadius: 25, offset: const Offset(0, 10)),
                  BoxShadow(color: displayColor.withOpacity(0.15), blurRadius: 15, spreadRadius: 2),
                ]
              : [],
        ),
        child: Stack(
          children: [
            // Corner decorations
            ..._buildCornerDecorations(isUnlocked),
            // Main Content
            Column(
              children: [
                _buildCertificateHeader(certTitle, isUnlocked, displayColor, lang),
                _buildCertificateBody(
                  congratsText: congratsText,
                  motivationQuote: motivationQuote,
                  awardedTo: awardedTo,
                  daysText: daysText,
                  name: name,
                  badge: badge,
                  isUnlocked: isUnlocked,
                  displayColor: displayColor,
                  isDark: isDark,
                  lang: lang,
                ),
                _buildCertificateFooter(displayColor, isDark, lang, daysRequired: badge.daysRequired),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerDecorations(bool isUnlocked) {
    final color = (isUnlocked ? islamicGold : Colors.grey).withOpacity(0.4);
    return [
      Positioned(top: 8, left: 8, child: Icon(Icons.star, size: 20, color: color)),
      Positioned(top: 8, right: 8, child: Icon(Icons.star, size: 20, color: color)),
      Positioned(bottom: 8, left: 8, child: Icon(Icons.star, size: 20, color: color)),
      Positioned(bottom: 8, right: 8, child: Icon(Icons.star, size: 20, color: color)),
    ];
  }

  Widget _buildCertificateHeader(String certTitle, bool isUnlocked, Color displayColor, LanguageService lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUnlocked
              ? [islamicGold.withOpacity(0.9), displayColor, displayColor.withOpacity(0.8)]
              : [Colors.grey.shade600, Colors.grey],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.white.withOpacity(0.7), size: 16),
              const SizedBox(width: 8),
              const Icon(Icons.star, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Icon(Icons.star, color: Colors.white.withOpacity(0.7), size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                ),
              ),
              const Icon(Icons.workspace_premium, color: Colors.white, size: 50),
              if (!isUnlocked)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.lock, color: Colors.white, size: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            certTitle,
            style: lang.getTextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [const Shadow(color: Colors.black26, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateBody({
    required String congratsText,
    required String motivationQuote,
    required String awardedTo,
    required String daysText,
    required String name,
    required AchievementBadge badge,
    required bool isUnlocked,
    required Color displayColor,
    required bool isDark,
    required LanguageService lang,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        children: [
          Text(
            congratsText,
            style: lang.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? displayColor : (isDark ? Colors.white54 : Colors.black45),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          if (motivationQuote.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: islamicGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: islamicGold.withOpacity(0.3)),
              ),
              child: Text(
                motivationQuote,
                style: lang.getTextStyle(fontSize: 13, color: islamicGold, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Decorative divider
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.transparent, displayColor.withOpacity(0.5)]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.star, size: 14, color: displayColor.withOpacity(0.6)),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [displayColor.withOpacity(0.5), Colors.transparent]),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(awardedTo, style: lang.getTextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.black45)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [displayColor.withOpacity(0.2), displayColor.withOpacity(0.08)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: displayColor.withOpacity(0.4), width: 2),
            ),
            child: Text(
              userName,
              style: lang.getTextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: isUnlocked ? [BoxShadow(color: displayColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)] : [],
            ),
            child: Image.asset(
              'assets/images/badge_level_${badge.level}.png',
              width: 70,
              height: 70,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 14),
          Text(name, style: lang.getTextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: displayColor)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: displayColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              daysText,
              style: lang.getTextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w500),
            ),
          ),
          if (startDate != null) ...[
            const SizedBox(height: 8),
            Builder(builder: (_) {
              final unlockDate = startDate!.add(Duration(days: badge.daysRequired));
              final dateStr = '${unlockDate.day.toString().padLeft(2, '0')}/${unlockDate.month.toString().padLeft(2, '0')}/${unlockDate.year}';
              return Text(
                '📅 $dateStr',
                style: lang.getTextStyle(fontSize: 12, color: displayColor.withOpacity(0.6), fontWeight: FontWeight.w500),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCertificateFooter(Color displayColor, bool isDark, LanguageService lang, {int? daysRequired}) {
    String? dateStr;
    if (startDate != null && daysRequired != null) {
      final unlockDate = startDate!.add(Duration(days: daysRequired));
      dateStr = '${unlockDate.day.toString().padLeft(2, '0')}/${unlockDate.month.toString().padLeft(2, '0')}/${unlockDate.year}';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: displayColor.withOpacity(0.08),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(17)),
        border: Border(top: BorderSide(color: displayColor.withOpacity(0.2))),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 2,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.transparent, displayColor, Colors.transparent]),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          if (dateStr != null) ...[
            Text(
              '📅 $dateStr',
              style: lang.getTextStyle(fontSize: 12, color: displayColor.withOpacity(0.7), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user, size: 16, color: displayColor.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(
                _getPlatformText(lang),
                style: lang.getTextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods for translations
  String _getCertTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish:
        return 'بڕوانامەی سەرکەوتن';
      case AppLanguage.arabic:
        return 'شهادة الإنجاز';
      case AppLanguage.english:
        return 'Certificate of Achievement';
    }
  }

  String _getCongratsText(LanguageService lang, bool isUnlocked, String name) {
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish:
        return isUnlocked
            ? '🎉 پیرۆزە و هەزار پیرۆز! 🎉\n\nتۆ بە ئیرادەی پۆڵاینت و بەهێزی دڵت\nگەیشتیت بە ئاستی "$name"\n\nئەمە دەستکەوتێکی گەورەیە!'
            : 'تۆ هێشتا نەگەیشتوویتە\n"$name"\nبەڵام ڕێگاکەت ڕاستە!';
      case AppLanguage.arabic:
        return isUnlocked
            ? '🎉 مبارك! ألف مبارك! 🎉\n\nبإرادتك الحديدية وقوة عزيمتك\nوصلت إلى مستوى "$name"\n\nهذا إنجاز عظيم!'
            : 'لم تصل بعد إلى\n"$name"\nلكنك على الطريق الصحيح!';
      case AppLanguage.english:
        return isUnlocked
            ? '🎉 Congratulations! 🎉\n\nWith your iron will and determination\nyou have reached "$name"\n\nThis is a great achievement!'
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
      case AppLanguage.kurdish:
        return 'ئەم بڕوانامەی شانازییە دەدرێت بە:';
      case AppLanguage.arabic:
        return 'تُمنح هذه الشهادة الفخرية إلى:';
      case AppLanguage.english:
        return 'This honorary certificate is awarded to:';
    }
  }

  String _getDaysText(AchievementBadge badge, LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish:
        return '${badge.daysRequired} ڕۆژی چاکبوونەوە';
      case AppLanguage.arabic:
        return '${badge.daysRequired} يوم من التعافي';
      case AppLanguage.english:
        return '${badge.daysRequired} Days of Recovery';
    }
  }

  String _getPlatformText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish:
        return 'ئەم بڕوانامەیە لەلایەن پلاتفۆرمی لا أبرح دراوە';
      case AppLanguage.arabic:
        return 'هذه الشهادة صادرة من منصة لا أبرح';
      case AppLanguage.english:
        return 'This certificate is issued by La Abrah Platform';
    }
  }

  String _getBadgeName(AchievementBadge badge, LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish:
        return badge.nameKu;
      case AppLanguage.arabic:
        return badge.nameAr;
      case AppLanguage.english:
        return badge.nameEn;
    }
  }
}
