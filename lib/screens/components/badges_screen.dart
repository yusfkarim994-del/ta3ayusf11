import 'package:flutter/material.dart';
import '../../services/language_service.dart';
import '../../services/badges_service.dart';

/// Badges screen showing all available badges and their unlock status
class BadgesScreen extends StatelessWidget {
  final int userDays;

  const BadgesScreen({
    super.key,
    required this.userDays,
  });

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService();
    final isDark = lang.isDarkMode;
    final allBadges = BadgesService.allBadges;
    final earnedBadges = BadgesService.getEarnedBadges(userDays);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0a1628) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                shape: BoxShape.circle,
              ),
              child: Image.asset('assets/images/icon_popup_badges.png', width: 28, height: 28, fit: BoxFit.contain),
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
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: allBadges.length,
        itemBuilder: (context, index) => _buildBadgeCard(allBadges[index], lang, isDark),
      ),
    );
  }

  String _getTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish:
        return 'ئۆسمەکان';
      case AppLanguage.arabic:
        return 'الأوسمة';
      case AppLanguage.english:
        return 'Badges';
    }
  }

  String _getDaysText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.kurdish:
        return 'ڕۆژ';
      case AppLanguage.arabic:
        return 'يوم';
      case AppLanguage.english:
        return 'days';
    }
  }

  Widget _buildBadgeCard(AchievementBadge badge, LanguageService lang, bool isDark) {
    final isUnlocked = userDays >= badge.daysRequired;
    final name = _getBadgeName(badge, lang);
    final displayColor = isUnlocked ? badge.color : Colors.grey;
    final progress = badge.daysRequired == 0
        ? 1.0
        : (userDays / badge.daysRequired).clamp(0.0, 1.0);
    final remainingDays = (badge.daysRequired - userDays).clamp(0, badge.daysRequired);
    final unlockDate = DateTime.now().add(Duration(days: remainingDays));

    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [displayColor.withOpacity(0.2), displayColor.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: displayColor.withOpacity(0.5), width: 2),
          boxShadow: isUnlocked
              ? [BoxShadow(color: displayColor.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: isUnlocked
                        ? [BoxShadow(color: displayColor.withOpacity(0.3), blurRadius: 12, spreadRadius: 1)]
                        : [],
                  ),
                  child: Image.asset(
                    'assets/images/badge_level_${badge.level}.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ),
                if (!isUnlocked)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
                      child: const Icon(Icons.lock, color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 54,
                  height: 54,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(displayColor),
                  ),
                ),
                Text(
                  '${(progress * 100).floor()}%',
                  style: lang.getTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: displayColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              name,
              style: lang.getTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: displayColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${badge.daysRequired} ${_getDaysText(lang)}',
                style: lang.getTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: displayColor),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              isUnlocked
                  ? (lang.currentLanguage == AppLanguage.arabic
                      ? 'أنت تتقدم بقوة وثبات'
                      : lang.currentLanguage == AppLanguage.kurdish
                          ? 'بەهێزی و جێگیری بەردەوام بە'
                          : 'You are progressing with strength')
                  : (lang.currentLanguage == AppLanguage.arabic
                      ? '$remainingDays يوم متبقي'
                      : lang.currentLanguage == AppLanguage.kurdish
                          ? '$remainingDays ڕۆژ ماوە'
                          : '$remainingDays days left'),
              textAlign: TextAlign.center,
              style: lang.getTextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${unlockDate.day}/${unlockDate.month}/${unlockDate.year}',
              style: lang.getTextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: displayColor,
              ),
            ),
          ],
        ),
      ),
    );
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
