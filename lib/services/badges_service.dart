import 'package:flutter/material.dart';

/// Achievement badge milestone definitions
class AchievementBadge {
  final int daysRequired;
  final String nameEn;
  final String nameAr;
  final String nameKu;
  final IconData icon;
  final Color color;
  final String level;

  const AchievementBadge({
    required this.daysRequired,
    required this.nameEn,
    required this.nameAr,
    required this.nameKu,
    required this.icon,
    required this.color,
    required this.level,
  });
}

class BadgesService {
  static List<AchievementBadge>? _badgesCache;
  
  static List<AchievementBadge> get _badges {
    _badgesCache ??= _buildBadges();
    return _badgesCache!;
  }
  
  static List<AchievementBadge> _buildBadges() {
    final List<AchievementBadge> badges = [
      // Early milestones with unique inspiring icons
      const AchievementBadge(daysRequired: 1, nameEn: 'First Step', nameAr: 'الخطوة الأولى', nameKu: 'هەنگاوی یەکەم', icon: Icons.directions_walk, color: Color(0xFF4CAF50), level: 'beginner'),
      const AchievementBadge(daysRequired: 7, nameEn: 'Week Warrior', nameAr: 'محارب الأسبوع', nameKu: 'پاڵەوانی هەفتە', icon: Icons.shield, color: Color(0xFF8BC34A), level: 'beginner'),
      const AchievementBadge(daysRequired: 14, nameEn: 'Rising Star', nameAr: 'النجم الصاعد', nameKu: 'ئەستێرەی بەرزبوو', icon: Icons.trending_up, color: Color(0xFFCDDC39), level: 'beginner'),
      const AchievementBadge(daysRequired: 30, nameEn: 'Month Champion', nameAr: 'بطل الشهر', nameKu: 'پاڵەوانی مانگ', icon: Icons.emoji_events, color: Color(0xFFFF9800), level: 'intermediate'),
      const AchievementBadge(daysRequired: 40, nameEn: 'Brave Heart', nameAr: 'القلب الشجاع', nameKu: 'دڵی ئازا', icon: Icons.favorite, color: Color(0xFFFF5722), level: 'intermediate'),
      const AchievementBadge(daysRequired: 60, nameEn: 'Strong Will', nameAr: 'الإرادة القوية', nameKu: 'ویستی بەهێز', icon: Icons.fitness_center, color: Color(0xFFE91E63), level: 'intermediate'),
      const AchievementBadge(daysRequired: 75, nameEn: 'Mighty Heart', nameAr: 'القلب المتين', nameKu: 'دڵی پڕهێز', icon: Icons.bolt, color: Color(0xFF9C27B0), level: 'advanced'),
      const AchievementBadge(daysRequired: 90, nameEn: 'True Hero', nameAr: 'البطل الحقيقي', nameKu: 'پاڵەوانی ڕاستەقینە', icon: Icons.military_tech, color: Color(0xFF673AB7), level: 'advanced'),
      const AchievementBadge(daysRequired: 100, nameEn: 'Century Legend', nameAr: 'أسطورة المئة', nameKu: 'ئەفسانەی سەد ڕۆژ', icon: Icons.workspace_premium, color: Color(0xFF3F51B5), level: 'advanced'),
    ];
    
    // Additional milestones with unique names from 125 to 1000
    final additionalMilestones = [
      AchievementBadge(daysRequired: 125, nameEn: 'Noble Fighter', nameAr: 'المقاتل النبيل', nameKu: 'جەنگاوەری ئازا', icon: Icons.nights_stay, color: const Color(0xFF2196F3), level: 'advanced'),
      AchievementBadge(daysRequired: 150, nameEn: 'Iron Will', nameAr: 'إرادة حديدية', nameKu: 'ویستی ئاسنین', icon: Icons.psychology, color: const Color(0xFF03A9F4), level: 'advanced'),
      AchievementBadge(daysRequired: 175, nameEn: 'Rising Strong', nameAr: 'النهوض القوي', nameKu: 'هەستانەوەی بەهێز', icon: Icons.whatshot, color: const Color(0xFF00BCD4), level: 'master'),
      AchievementBadge(daysRequired: 200, nameEn: 'Double Century', nameAr: 'مئتان يوم', nameKu: 'دوو سەد ڕۆژ', icon: Icons.star_border, color: const Color(0xFF009688), level: 'master'),
      AchievementBadge(daysRequired: 225, nameEn: 'Self Guardian', nameAr: 'حارس النفس', nameKu: 'پاسەوانی خۆ', icon: Icons.security, color: const Color(0xFF4CAF50), level: 'master'),
      AchievementBadge(daysRequired: 250, nameEn: 'Unstoppable', nameAr: 'لا يُوقَف', nameKu: 'ڕاگیرنەکراو', icon: Icons.speed, color: const Color(0xFF8BC34A), level: 'master'),
      AchievementBadge(daysRequired: 275, nameEn: 'Inner Peace', nameAr: 'السلام الداخلي', nameKu: 'ئاشتی ناوخۆ', icon: Icons.self_improvement, color: const Color(0xFFCDDC39), level: 'master'),
      AchievementBadge(daysRequired: 300, nameEn: 'Steadfast', nameAr: 'الثابت', nameKu: 'جێگیر', icon: Icons.local_fire_department, color: const Color(0xFFFFEB3B), level: 'master'),
      AchievementBadge(daysRequired: 325, nameEn: 'Mountain Strong', nameAr: 'قوي كالجبل', nameKu: 'بەهێزی چیا', icon: Icons.warning, color: const Color(0xFFFFC107), level: 'legend'),
      AchievementBadge(daysRequired: 350, nameEn: 'Champion Elite', nameAr: 'بطل النخبة', nameKu: 'پاڵەوانی لووتکە', icon: Icons.stars, color: const Color(0xFFFF9800), level: 'legend'),
      AchievementBadge(daysRequired: 375, nameEn: 'Warrior King', nameAr: 'ملك المحاربين', nameKu: 'پاشای جەنگاوەران', icon: Icons.home_work, color: const Color(0xFFFF5722), level: 'legend'),
      AchievementBadge(daysRequired: 400, nameEn: 'Legendary', nameAr: 'أسطوري', nameKu: 'ئەفسانەیی', icon: Icons.auto_awesome, color: const Color(0xFFE91E63), level: 'legend'),
      AchievementBadge(daysRequired: 425, nameEn: 'Pure Heart', nameAr: 'القلب الطاهر', nameKu: 'دڵی پاک', icon: Icons.brightness_7, color: const Color(0xFF9C27B0), level: 'legend'),
      AchievementBadge(daysRequired: 450, nameEn: 'Invincible', nameAr: 'لا يُقهَر', nameKu: 'شکستنەهێنراو', icon: Icons.shield, color: const Color(0xFF673AB7), level: 'legend'),
      AchievementBadge(daysRequired: 475, nameEn: 'Eternal Flame', nameAr: 'الشعلة الأبدية', nameKu: 'گڕی هەتاهەتایی', icon: Icons.local_fire_department, color: const Color(0xFF3F51B5), level: 'legend'),
      AchievementBadge(daysRequired: 500, nameEn: 'Half Millennium', nameAr: 'نصف الألف', nameKu: 'نیوە هەزار', icon: Icons.star, color: const Color(0xFF2196F3), level: 'legend'),
      AchievementBadge(daysRequired: 550, nameEn: 'Straight Path', nameAr: 'الطريق القويم', nameKu: 'ڕێگای ڕاست', icon: Icons.alt_route, color: const Color(0xFF00BCD4), level: 'legend'),
      AchievementBadge(daysRequired: 600, nameEn: 'Blessed Heart', nameAr: 'القلب المبارك', nameKu: 'دڵی پیرۆز', icon: Icons.all_inclusive, color: const Color(0xFF009688), level: 'legend'),
      AchievementBadge(daysRequired: 650, nameEn: 'Galaxy Champion', nameAr: 'بطل المجرة', nameKu: 'پاڵەوانی گەڵەستێرە', icon: Icons.blur_circular, color: const Color(0xFF4CAF50), level: 'legend'),
      AchievementBadge(daysRequired: 700, nameEn: 'Cosmic Hero', nameAr: 'بطل كوني', nameKu: 'پاڵەوانی گەردوون', icon: Icons.public, color: const Color(0xFF8BC34A), level: 'legend'),
      AchievementBadge(daysRequired: 750, nameEn: 'Diamond Will', nameAr: 'الإرادة الماسية', nameKu: 'ویستی ئەڵماس', icon: Icons.brightness_high, color: const Color(0xFFCDDC39), level: 'legend'),
      AchievementBadge(daysRequired: 800, nameEn: 'Grand Champion', nameAr: 'البطل الأكبر', nameKu: 'پاڵەوانی گەورە', icon: Icons.workspace_premium, color: const Color(0xFFFFD700), level: 'legend'),
      AchievementBadge(daysRequired: 850, nameEn: 'Eternal Champion', nameAr: 'البطل الأبدي', nameKu: 'پاڵەوانی هەتاهەتا', icon: Icons.emoji_events, color: const Color(0xFFFFB300), level: 'legend'),
      AchievementBadge(daysRequired: 900, nameEn: 'Living Legend', nameAr: 'أسطورة حية', nameKu: 'ئەفسانەی زیندوو', icon: Icons.auto_awesome, color: const Color(0xFFFF8F00), level: 'legend'),
      AchievementBadge(daysRequired: 950, nameEn: 'Elevated', nameAr: 'المرتقي', nameKu: 'بەرزبوو', icon: Icons.brightness_5, color: const Color(0xFFFF6D00), level: 'legend'),
      AchievementBadge(daysRequired: 1000, nameEn: 'The Millennium', nameAr: 'الألفية', nameKu: 'هەزارساڵە', icon: Icons.star, color: const Color(0xFFFFD700), level: 'legend'),
    ];
    badges.addAll(additionalMilestones);
    
    return badges;
  }

  static IconData _getIconForDays(int days) {
    if (days >= 750) return Icons.diamond;
    if (days >= 500) return Icons.auto_awesome;
    if (days >= 300) return Icons.local_fire_department;
    return Icons.workspace_premium;
  }

  static Color _getColorForDays(int days) {
    if (days >= 1000) return const Color(0xFFFFD700); // Gold
    if (days >= 750) return const Color(0xFFE040FB); // Purple
    if (days >= 500) return const Color(0xFF00BCD4); // Cyan
    if (days >= 300) return const Color(0xFF2196F3); // Blue
    return const Color(0xFF3F51B5); // Indigo
  }

  static String _getLevelForDays(int days) {
    if (days >= 500) return 'legend';
    if (days >= 200) return 'master';
    if (days >= 100) return 'advanced';
    if (days >= 30) return 'intermediate';
    return 'beginner';
  }

  static List<AchievementBadge> get allBadges => _badges;

  /// Get all badges that a user has earned
  static List<AchievementBadge> getEarnedBadges(int totalDays) {
    return _badges.where((badge) => totalDays >= badge.daysRequired).toList();
  }

  /// Get the highest badge a user has earned
  static AchievementBadge? getHighestBadge(int totalDays) {
    final earned = getEarnedBadges(totalDays);
    if (earned.isEmpty) return null;
    return earned.last; // Last one is highest since list is sorted by days
  }

  /// Get next badge to earn
  static AchievementBadge? getNextBadge(int totalDays) {
    for (var badge in _badges) {
      if (badge.daysRequired > totalDays) {
        return badge;
      }
    }
    return null;
  }

  /// Get days remaining until next badge
  static int daysUntilNextBadge(int totalDays) {
    final next = getNextBadge(totalDays);
    if (next == null) return 0;
    return next.daysRequired - totalDays;
  }

  /// Get certificate title based on days
  static String getCertificateTitle(int days, String language) {
    final badge = _badges.lastWhere(
      (b) => b.daysRequired <= days,
      orElse: () => _badges.first,
    );
    
    switch (language) {
      case 'ar':
        return 'شهادة إنجاز - ${badge.nameAr}';
      case 'ku':
        return 'بڕوانامەی سەرکەوتن - ${badge.nameKu}';
      default:
        return 'Achievement Certificate - ${badge.nameEn}';
    }
  }
}
