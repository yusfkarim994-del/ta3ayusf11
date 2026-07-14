import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService();
    final isDark = lang.isDarkMode;
    final allBadges = BadgesService.allBadges;
    final earnedBadges = BadgesService.getEarnedBadges(userDays);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF071A22) : const Color(0xFFF8F5EE),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF071A22) : const Color(0xFFF8F5EE),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
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
        title: Text(
          _getTitle(lang),
          style: lang.getTextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF3E2723),
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${earnedBadges.length}/${allBadges.length}',
              style: lang.getTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: allBadges.length,
        itemBuilder: (context, index) {
          final badge = allBadges[index];
          final isUnlocked = userDays >= badge.daysRequired;
          return _buildCertificate(badge, lang, isDark, isUnlocked);
        },
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

  Widget _buildCertificate(AchievementBadge badge, LanguageService lang, bool isDark, bool isUnlocked) {
    final name = _getBadgeName(badge, lang);
    final displayColor = isUnlocked ? badge.color : Colors.grey;
    final progress = badge.daysRequired == 0 ? 1.0 : (userDays / badge.daysRequired).clamp(0.0, 1.0);
    final remaining = (badge.daysRequired - userDays).clamp(0, 9999);

    final now = DateTime.now();
    final targetDate = isUnlocked
        ? now.subtract(Duration(days: userDays - badge.daysRequired))
        : now.add(Duration(days: remaining));
    final dateStr = '${targetDate.day.toString().padLeft(2, '0')}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.year}';

    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.4,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF102028) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isUnlocked
                ? gold.withOpacity(0.6)
                : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? gold.withOpacity(0.12)
                  : (isDark ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.04)),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top accent bar
            Container(
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isUnlocked
                      ? [gold, gold.withOpacity(0.4)]
                      : [Colors.grey.shade400, Colors.grey.shade300],
                ),
              ),
            ),

            // Platform name
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isUnlocked ? gold.withOpacity(0.2) : Colors.grey.withOpacity(0.15),
                  ),
                ),
              ),
              child: Text(
                'منصة لا أبرح',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white70 : const Color(0xFF6D4C41),
                  letterSpacing: 1,
                ),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                children: [
                  // Trophy icon
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isUnlocked)
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: gold.withOpacity(0.1),
                          ),
                        ),
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: isUnlocked ? gold : Colors.grey,
                        size: isUnlocked ? 52 : 44,
                      ),
                      if (!isUnlocked)
                        const Positioned(
                          right: 0,
                          top: 0,
                          child: Icon(Icons.lock, color: Colors.grey, size: 18),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Badge name
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF3E2723),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Days required
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: displayColor.withOpacity(isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${badge.daysRequired} ${_getDaysLabel(lang)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: displayColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // User name
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: gold.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Text(
                      userName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF5D4037),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Short description
                  Text(
                    _getShortDescription(lang, isUnlocked),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : const Color(0xFF8D6E63),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(displayColor),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Status text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(progress * 100).floor()}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: displayColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isUnlocked
                            ? _getUnlockedText(lang)
                            : '$remaining ${_getRemainingLabel(lang)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : const Color(0xFF6D4C41),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Date
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: displayColor.withOpacity(isDark ? 0.1 : 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: displayColor.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: displayColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        Icons.star_rounded,
                        color: gold.withOpacity(0.8),
                        size: 16,
                      ),
                    )),
                  ),

                  const SizedBox(height: 10),

                  // Platform text
                  Text(
                    _getPlatformText(lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white30 : const Color(0xFF8D6E63).withOpacity(0.6),
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

  String _getDaysLabel(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish: return 'ڕۆژی چاکبوونەوە';
      case AppLanguage.arabic: return 'يوم تعافي';
      case AppLanguage.english: return 'Recovery Days';
    }
  }

  String _getShortDescription(LanguageService lang, bool isUnlocked) {
    if (!isUnlocked) {
      switch (lang.currentLanguage) {
        case AppLanguage.kurdish: return 'بەردەوام بە بۆ بەدەستهێنانی ئەم بڕوانامەیە';
        case AppLanguage.arabic: return 'استمر للحصول على هذه الشهادة';
        case AppLanguage.english: return 'Keep going to earn this certificate';
      }
    }
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish: return 'پیرۆزە! بە ئیرادە و بەهێزی ئەم بڕوانامەیە بەدەستهێناوە';
      case AppLanguage.arabic: return 'تهانيناً! حصلت على هذه الشهادة بإرادتك';
      case AppLanguage.english: return 'Congratulations! You earned this with your willpower';
    }
  }

  String _getUnlockedText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish: return 'کراوەتەوە';
      case AppLanguage.arabic: return 'تم الفتح';
      case AppLanguage.english: return 'Unlocked';
    }
  }

  String _getRemainingLabel(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish: return 'ڕۆژ ماوە';
      case AppLanguage.arabic: return 'يوم متبقية';
      case AppLanguage.english: return 'days remaining';
    }
  }

  String _getPlatformText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish: return 'بڕوانامەی فەرمی لەلایەن پلاتفۆرمی لاإبرح';
      case AppLanguage.arabic: return 'شهادة رسمية من منصة لا أبرح';
      case AppLanguage.english: return 'Official certificate by La Abrah';
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
