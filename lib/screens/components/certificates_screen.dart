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
    final progress = badge.daysRequired == 0
        ? 1.0
        : (userDays / badge.daysRequired).clamp(0.0, 1.0);
    final certTitle = _getCertTitle(lang);
    final congratsText = _getCongratsText(lang, isUnlocked, name);
    final motivationQuote = _getMotivationQuote(lang, isUnlocked);
    final awardedTo = _getAwardedToText(lang);
    final daysText = _getDaysText(badge, lang);

    final remainingDays = (badge.daysRequired - userDays).clamp(0, 5000);
    final targetDate = DateTime.now().add(Duration(days: remainingDays));
    final targetDateStr = '${targetDate.day.toString().padLeft(2, '0')}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.year}';

    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.45,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: displayColor.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isUnlocked
                  ? [const Color(0xFFFFFCF2), const Color(0xFFF5E6C8)]
                  : [Colors.grey.shade200, Colors.grey.shade300],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isUnlocked ? const Color(0xFFD4AF37) : Colors.grey,
              width: 3,
            ),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: isUnlocked ? const Color(0xFFD4AF37) : Colors.grey,
                    size: 54,
                  ),
                  if (!isUnlocked)
                    const Positioned(
                      right: -2,
                      top: -2,
                      child: Icon(
                        Icons.lock,
                        color: Colors.grey,
                        size: 22,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: lang.getTextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3E2723),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  userName,
                  textAlign: TextAlign.center,
                  style: lang.getTextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF5D4037),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                lang.currentLanguage == AppLanguage.arabic
                    ? 'مقدمة بكل فخر من منصة لا أبرح'
                    : lang.currentLanguage == AppLanguage.kurdish
                        ? 'بە شانازییەوە پێشکەشکراوە لەلایەن پلاتفۆرمی لا أبرح'
                        : 'Proudly presented by La Abruh Platform',
                textAlign: TextAlign.center,
                style: lang.getTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6D4C41),
                ),
              ),

              const SizedBox(height: 18),

              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(displayColor),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                '${(progress * 100).floor()}%',
                style: lang.getTextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: displayColor,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                isUnlocked
                    ? (lang.currentLanguage == AppLanguage.arabic
                        ? 'تم فتح هذه الشهادة بنجاح'
                        : lang.currentLanguage == AppLanguage.kurdish
                            ? 'ئەم بڕوانامەیە کراوەتەوە'
                            : 'Certificate unlocked successfully')
                    : (lang.currentLanguage == AppLanguage.arabic
                        ? '$remainingDays يوم متبقي للحصول عليها'
                        : lang.currentLanguage == AppLanguage.kurdish
                            ? '$remainingDays ڕۆژ ماوە بۆ کردنەوەی'
                            : '$remainingDays days remaining to unlock'),
                textAlign: TextAlign.center,
                style: lang.getTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5D4037),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: displayColor.withOpacity(0.25),
                  ),
                ),
                child: Text(
                  _getMotivationalMessage(lang, isUnlocked, badge.daysRequired),
                  textAlign: TextAlign.center,
                  style: lang.getTextStyle(
                    fontSize: 14,
                    height: 1.7,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4E342E),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                '${badge.daysRequired}',
                style: lang.getTextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFD4AF37),
                ),
              ),
              Text(
                lang.currentLanguage == AppLanguage.arabic
                    ? 'يوم من التعافي'
                    : lang.currentLanguage == AppLanguage.kurdish
                        ? 'ڕۆژی چاکبوونەوە'
                        : 'Recovery Days',
                style: lang.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6D4C41),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    targetDateStr,
                    style: lang.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5D4037),
                    ),
                  ),
                  Icon(
                    Icons.verified,
                    color: isUnlocked ? const Color(0xFF14B8A6) : Colors.grey,
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMotivationalMessage(LanguageService lang, bool unlocked, int daysRequired) {
    final unique = {
      1: 'البداية دائماً هي أصعب جزء في أي رحلة تغيير.\nلكن اختيارك للمقاومة اليوم يعني أنك بدأت تستعيد السيطرة على نفسك.\nهذه الخطوة الصغيرة قد تغيّر حياتك بالكامل.',
      7: 'أسبوع كامل من الصبر والانتصار على الرغبات ليس أمراً عادياً.\nعقلك وجسدك بدآ الآن بالشعور بالتحسن الحقيقي والاستقرار.\nأنت تثبت كل يوم أنك أقوى مما كنت تتخيل.',
      14: 'أربعة عشر يوماً من الثبات تعني أنك تجاوزت مرحلة خطيرة من التعلق القديم.\nأصبحت ترى الأمور بوضوح أكبر وتستعيد احترامك لنفسك.\nكل يوم جديد يثبت أنك قادر على الاستمرار حتى النهاية.',
      30: 'ثلاثون يوماً من الالتزام تعني أنك صنعت فرقاً حقيقياً في حياتك.\nلقد تجاوزت أياماً صعبة ولحظات ضعف لكنك لم تستسلم.\nهذه الشهادة دليل على أن التغيير ممكن عندما تصدق نفسك.',
      40: 'أربعون يوماً من الصبر صنعت في داخلك قوة لم تكن تشعر بها من قبل.\nبدأت العادات القديمة تفقد تأثيرها وسيطرتها عليك تدريجياً.\nاستمر بنفس الروح، فأنت تبني حياة جديدة بالكامل.',
      60: 'ستون يوماً من المقاومة تعني أنك أصبحت أقرب إلى الحرية الحقيقية.\nلقد تجاوزت اختبارات كثيرة وأثبت أن إرادتك أقوى من أي رغبة عابرة.\nهذه المرحلة بداية الاستقرار النفسي الحقيقي.',
      75: 'خمسة وسبعون يوماً من الالتزام ليست مجرد فترة زمنية، بل قصة انتصار كاملة.\nأنت اليوم أقوى فكراً وأكثر هدوءاً وثقةً بنفسك من أي وقت مضى.\nكل ما عشته من تعب أصبح الآن دليلاً على قوتك.',
      90: 'الوصول إلى تسعين يوماً هو انتصار استثنائي لا يصل إليه إلا أصحاب الإرادة الحقيقية.\nلقد انتصرت على عادات كانت تسرق وقتك وطاقتك وسلامك الداخلي.\nاليوم تبدأ مرحلة جديدة أكثر صفاءً وقوةً وثقةً بنفسك.',
      100: 'مئة يوم من الصمود تعني أنك لم تعد الشخص نفسه الذي بدأ الرحلة.\nلقد تعلمت كيف تواجه نفسك وتنتصر على نقاط ضعفك بصبر وشجاعة.\nهذه الشهادة تخلّد رحلة عظيمة صنعتها بنفسك.',
      125: 'وصولك إلى مئة وخمسة وعشرين يوماً دليل على أنك تجاوزت مرحلة الاعتماد القديمة.\nأصبحت أكثر هدوءاً في قراراتك وأكثر ثقة بنفسك في مواجهة الضغوط.\nهذا الإنجاز يعكس قوة داخلية نادرة لا يمتلكها الجميع.',
      150: 'مئة وخمسون يوماً من الثبات ليست مجرد إنجاز عابر بل أسلوب حياة جديد.\nلقد بدأت ترى نفسك بصورة مختلفة مليئة بالقوة والاحترام الذاتي.\nكل يوم إضافي الآن يرسّخ انتصارك الحقيقي.',
      175: 'عند هذا المستوى تبدأ النتائج العميقة بالظهور في شخصيتك وحياتك اليومية.\nأنت لم تعد تحارب فقط بل أصبحت تقود نفسك بثقة ونضج.\nهذه الشهادة شهادة على تطورك العقلي والنفسي.',
      200: 'مئتا يوم من الصبر والإرادة تعني أنك قطعت رحلة استثنائية بكل المقاييس.\nالكثيرون يتمنون الوصول إلى هذه المرحلة لكن القليل فقط يثبت حتى النهاية.\nأنت اليوم مثال حي على أن التغيير الحقيقي ممكن.',
      225: 'كل يوم من هذه الرحلة الطويلة أضاف قوة جديدة إلى روحك وشخصيتك.\nلقد صنعت توازناً داخلياً بدأ ينعكس على حياتك وعلاقاتك ومستقبلك.\nاستمر لأنك أصبحت أقرب من أي وقت مضى إلى النسخة الأفضل منك.',
      250: 'ربع ألف يوم من الالتزام يعني أنك تجاوزت حدود العادة القديمة بالكامل تقريباً.\nأنت اليوم أقوى في السيطرة على نفسك وأكثر وعياً بقيمة وقتك وحياتك.\nهذه الشهادة تليق بشخص اختار الانتصار كل يوم.',
      275: 'في هذه المرحلة لم تعد المقاومة مجرد واجب بل أصبحت جزءاً من هويتك الجديدة.\nلقد صنعت داخلك سلاماً واستقراراً لم يكن موجوداً في الماضي.\nكل لحظة تعب عشتها تحولت الآن إلى مصدر فخر حقيقي.',
      300: 'ثلاثمئة يوم من الثبات تعني أنك صنعت قصة نجاح نادرة يصعب تكرارها.\nلقد أثبت لنفسك قبل الجميع أن الإرادة قادرة على إعادة بناء الإنسان بالكامل.\nهذه الشهادة تحمل قيمة عظيمة لأنها تمثل انتصاراً طويل الأمد.',
      350: 'كل ما وصلت إليه اليوم هو نتيجة مئات القرارات الصحيحة التي اتخذتها بصبر.\nأنت الآن تملك خبرة حقيقية في التحكم بنفسك وتجاوز الإغراءات.\nهذا المستوى لا يصل إليه إلا أصحاب العزيمة الكبيرة.',
      400: 'أربعمئة يوم من الالتزام تعني أنك أصبحت شخصاً جديداً فعلاً.\nلم يعد الماضي يتحكم بك كما كان من قبل، بل أصبحت أنت من يقود حياتك.\nهذه الشهادة رمز لمرحلة مليئة بالنضج والقوة.',
      450: 'مع كل يوم إضافي تثبت أن النجاح الحقيقي يحتاج إلى صبر طويل ونفس قوي.\nلقد تجاوزت اختبارات كثيرة وخرجت منها أكثر حكمة وثباتاً.\nأنت اليوم مصدر إلهام لكل من يبحث عن التغيير.',
      500: 'خمسمئة يوم من الصمود ليست مجرد رحلة تعافٍ بل رحلة إعادة بناء كاملة للنفس.\nأصبحت أكثر إدراكاً لقيمتك وأكثر قدرة على حماية سلامك الداخلي.\nهذه الشهادة تخلّد نصف ألف يوم من الانتصار المستمر.',
      600: 'ست مئة يوم من الثبات تعني أنك وصلت إلى مستوى نادر من التحكم والوعي الذاتي.\nلقد صنعت فارقاً عميقاً في حياتك وأثبت أن الاستمرار يصنع المعجزات.\nهذا الإنجاز سيبقى علامة فارقة في رحلتك الشخصية.',
      700: 'سبعمئة يوم من الالتزام تكشف عن شخصية صلبة لا تنكسر بسهولة.\nأنت اليوم أقرب إلى السلام الداخلي والاستقرار الحقيقي أكثر من أي وقت مضى.\nهذه المرحلة تمثل قمة من قمم القوة النفسية.',
      800: 'ثمانمئة يوم من النجاح المستمر تعني أنك أصبحت قدوة حقيقية في الصبر والانضباط.\nلقد انتصرت على نفسك مرات لا تُحصى واخترت مستقبلك بوعي كامل.\nهذه الشهادة تروي قصة بطل حقيقي.',
      900: 'تسعمئة يوم من الثبات تعني أنك بنيت حياة جديدة بالكامل بعيداً عن الماضي.\nلقد أصبحت أكثر قوةً ونضجاً وقدرةً على مواجهة تحديات الحياة بثقة.\nهذا الإنجاز الاستثنائي يستحق كل الفخر والاحترام.',
      1000: 'ألف يوم من الإرادة والصبر والانتصار تعني أنك وصلت إلى مرحلة عظيمة جداً.\nلقد أثبت أن الإنسان قادر على تغيير حياته بالكامل مهما كان ماضيه صعباً.\nهذه الشهادة ليست مجرد تكريم، بل تاريخ كامل من القوة والانتصار.',
    };

    final text = unique[daysRequired] ??
        'كل شهادة هنا تمثل مرحلة مختلفة من قوتك ونضجك الداخلي.\nأنت لا تجمع الأيام فقط، بل تبني شخصية جديدة أكثر وعياً وثباتاً.\nاستمر لأن كل خطوة تخطوها اليوم ستصنع مستقبلاً تفتخر به غداً.';
    return text;
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
