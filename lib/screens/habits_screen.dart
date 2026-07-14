import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../services/habits_service.dart';
import '../services/language_service.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedCategory = 'all';
  bool _showAddHabits = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HabitsService>(context, listen: false).loadHabits();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = lang.isDarkMode;

    final languageCode = lang.currentLanguage == AppLanguage.arabic
        ? 'arabic'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'kurdish'
            : 'english';

    // Localized strings
    String title = lang.currentLanguage == AppLanguage.arabic
        ? 'العادات'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'ڕەوشتەکان'
            : 'Habits';

    String addHabitsText = lang.currentLanguage == AppLanguage.arabic
        ? 'إضافة عادات'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'زیادکردنی ڕەوشت'
            : 'Add Habits';

    String myHabitsText = lang.currentLanguage == AppLanguage.arabic
        ? 'عاداتي'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'ڕەوشتەکانم'
            : 'My Habits';

    return Directionality(
      textDirection: lang.textDirection,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF061A18),
                      const Color(0xFF102A27),
                      const Color(0xFF071312)
                    ]
                  : [
                      const Color(0xFFF1FFFC),
                      const Color(0xFFF7FAF2),
                      const Color(0xFFFFF7E8)
                    ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(lang, isDark, title),
                  _buildProgressCard(lang, isDark, languageCode),
                  _buildTabBar(isDark, addHabitsText, myHabitsText),
                  Expanded(
                    child: _showAddHabits
                        ? _buildHabitsGrid(lang, isDark, languageCode)
                        : _buildUserHabits(lang, isDark, languageCode),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: _showAddHabits
            ? FloatingActionButton(
                onPressed: () => _showAddCustomHabitDialog(lang, isDark),
                backgroundColor: const Color(0xFF0D9488),
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
      ),
    );
  }

  Widget _buildHeader(LanguageService lang, bool isDark, String title) {
    final subtitle = lang.currentLanguage == AppLanguage.arabic
        ? 'خطوات صغيرة تصنع تعافيا كبيرا'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'هەنگاوی بچووک، گۆڕانی گەورە دروست دەکات'
            : 'Small steps build lasting recovery';

    return Container(
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
          GestureDetector(
            onTap: () => _showStatisticsSheet(lang, isDark),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF059669).withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: Color(0xFF059669),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
      LanguageService lang, bool isDark, String languageCode) {
    return Consumer<HabitsService>(
      builder: (context, habitsService, child) {
        final completed = habitsService.getTodayCompletedCount();
        final total = habitsService.getTotalHabitsCount();
        final progress = habitsService.getTodayProgress();
        final bestStreak = habitsService.getBestStreakOverall();

        String progressText = languageCode == 'arabic'
            ? 'أكملت $completed من $total عادات اليوم'
            : languageCode == 'kurdish'
                ? 'ئەمڕۆ $completed لە $total ڕەوشتت تەواوکرد'
                : 'Completed $completed of $total habits today';

        if (total == 0) {
          progressText = languageCode == 'arabic'
              ? 'أضف عاداتك الأولى!'
              : languageCode == 'kurdish'
                  ? 'یەکەم ڕەوشتەکەت زیادبکە!'
                  : 'Add your first habit!';
        }

        final todayLabel = languageCode == 'arabic'
            ? 'اليوم'
            : languageCode == 'kurdish'
                ? 'ئەمڕۆ'
                : 'Today';
        final completedLabel = languageCode == 'arabic'
            ? 'مكتملة'
            : languageCode == 'kurdish'
                ? 'تەواو'
                : 'Done';
        final activeLabel = languageCode == 'arabic'
            ? 'نشطة'
            : languageCode == 'kurdish'
                ? 'چالاک'
                : 'Active';
        final streakLabel = languageCode == 'arabic'
            ? 'أفضل سلسلة'
            : languageCode == 'kurdish'
                ? 'باشترین زنجیرە'
                : 'Best streak';

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color:
                    const Color(0xFF0F766E).withOpacity(isDark ? 0.28 : 0.22),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                const Color(0xFF104E48),
                                const Color(0xFF0F766E),
                                const Color(0xFF1F2937)
                              ]
                            : [
                                const Color(0xFF0D9488),
                                const Color(0xFF14B8A6),
                                const Color(0xFFF59E0B)
                              ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -36,
                  right: -22,
                  child: _buildGlowCircle(110, Colors.white.withOpacity(0.16)),
                ),
                Positioned(
                  bottom: -52,
                  left: -26,
                  child: _buildGlowCircle(140, Colors.white.withOpacity(0.10)),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.22)),
                            ),
                            child: const Icon(Icons.spa_rounded,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.16),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    todayLabel,
                                    style: lang.getTextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  progressText,
                                  style: lang.getTextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: lang.getTextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildProgressMetric(lang, Icons.check_circle_rounded,
                              '$completed', completedLabel),
                          const SizedBox(width: 10),
                          _buildProgressMetric(
                              lang,
                              Icons.track_changes_rounded,
                              '$total',
                              activeLabel),
                          const SizedBox(width: 10),
                          _buildProgressMetric(
                              lang,
                              Icons.local_fire_department_rounded,
                              '$bestStreak',
                              streakLabel),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlowCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _buildProgressMetric(
      LanguageService lang, IconData icon, String value, String label) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '$value $label',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: lang.getTextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

  Widget _buildTabBar(bool isDark, String addHabitsText, String myHabitsText) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE0F2EF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withOpacity(isDark ? 0.08 : 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showAddHabits = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: !_showAddHabits
                      ? const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF0F766E)])
                      : null,
                  color: !_showAddHabits ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: !_showAddHabits
                      ? [
                          BoxShadow(
                              color: const Color(0xFF0D9488).withOpacity(0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 5))
                        ]
                      : null,
                ),
                child: Text(
                  myHabitsText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: !_showAddHabits
                        ? Colors.white
                        : (isDark ? Colors.white60 : const Color(0xFF53736E)),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showAddHabits = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: _showAddHabits
                      ? const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF0F766E)])
                      : null,
                  color: _showAddHabits ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _showAddHabits
                      ? [
                          BoxShadow(
                              color: const Color(0xFF0D9488).withOpacity(0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 5))
                        ]
                      : null,
                ),
                child: Text(
                  addHabitsText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _showAddHabits
                        ? Colors.white
                        : (isDark ? Colors.white60 : const Color(0xFF53736E)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHabits(
      LanguageService lang, bool isDark, String languageCode) {
    return Consumer<HabitsService>(
      builder: (context, habitsService, child) {
        final userHabits = habitsService.userHabits;

        if (userHabits.isEmpty) {
          return _buildEmptyState(lang, isDark, languageCode);
        }

        return ListView.builder(
          padding:
              const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
          itemCount: userHabits.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildMomentumStrip(
                  lang, isDark, languageCode, habitsService);
            }

            final userHabit = userHabits[index - 1];
            final habitInfo =
                habitsService.getHabitDefinition(userHabit.habitId);

            if (habitInfo == null) return const SizedBox.shrink();

            return _buildUserHabitCard(lang, isDark, languageCode, userHabit,
                habitInfo, habitsService);
          },
        );
      },
    );
  }

  Widget _buildMomentumStrip(LanguageService lang, bool isDark,
      String languageCode, HabitsService habitsService) {
    final completed = habitsService.getTodayCompletedCount();
    final total = habitsService.getTotalHabitsCount();
    final message = completed == total && total > 0
        ? (languageCode == 'arabic'
            ? 'رائع، أنهيت كل عادات اليوم'
            : languageCode == 'kurdish'
                ? 'نایابە، هەموو ڕەوشتەکانی ئەمڕۆت تەواوکرد'
                : 'Excellent, all habits are complete')
        : (languageCode == 'arabic'
            ? 'اختر عادة واحدة الآن وابدأ بها'
            : languageCode == 'kurdish'
                ? 'ئێستا یەک ڕەوشت هەڵبژێرە و دەست پێبکە'
                : 'Pick one habit now and start');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.07)
            : Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE0F2EF)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withOpacity(0.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Color(0xFF0D9488)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: lang.getTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF31524D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      LanguageService lang, bool isDark, String languageCode) {
    String emptyText = languageCode == 'arabic'
        ? 'لم تضف أي عادات بعد\nاضغط على "إضافة عادات" للبدء'
        : languageCode == 'kurdish'
            ? 'هێشتا هیچ ڕەوشتێکت زیاد نەکردووە\nکلیک لەسەر "زیادکردنی ڕەوشت" بۆ دەستپێکردن'
            : 'You haven\'t added any habits yet\nTap "Add Habits" to get started';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.10),
                        Colors.white.withOpacity(0.03)
                      ]
                    : [Colors.white, const Color(0xFFE6FFFA)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withOpacity(0.18),
                  blurRadius: 34,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: const Text('🎯', style: TextStyle(fontSize: 50)),
          ),
          const SizedBox(height: 24),
          Text(
            emptyText,
            textAlign: TextAlign.center,
            style: lang.getTextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black45,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHabitCard(
      LanguageService lang,
      bool isDark,
      String languageCode,
      UserHabit userHabit,
      HabitItem habitInfo,
      HabitsService habitsService) {
    final isCompleted = userHabit.isCompletedToday();

    String streakText = languageCode == 'arabic'
        ? '${userHabit.currentStreak} يوم متتالي'
        : languageCode == 'kurdish'
            ? '${userHabit.currentStreak} ڕۆژ دوامدار'
            : '${userHabit.currentStreak} day streak';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102028) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCompleted
              ? habitInfo.color.withOpacity(0.4)
              : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? habitInfo.color.withOpacity(0.12)
                : const Color(0xFF059669).withOpacity(isDark ? 0.04 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Top accent line
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      habitInfo.color.withOpacity(isCompleted ? 0.8 : 0.3),
                      habitInfo.color.withOpacity(isCompleted ? 0.4 : 0.1),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => habitsService.toggleHabitCompletion(userHabit.habitId),
                onLongPress: () => _showDeleteDialog(
                    lang, isDark, userHabit.habitId, habitInfo, habitsService),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: isCompleted
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    habitInfo.color.withOpacity(0.2),
                                    habitInfo.color.withOpacity(0.08),
                                  ],
                                )
                              : null,
                          color: isCompleted
                              ? null
                              : (isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: habitInfo.color.withOpacity(isCompleted ? 0.3 : 0.08),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            habitInfo.emoji,
                            style: TextStyle(fontSize: isCompleted ? 28 : 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habitInfo.getName(languageCode),
                              style: lang
                                  .getTextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF064E3B),
                                  )
                                  .copyWith(
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (userHabit.currentStreak > 0
                                            ? Colors.orange
                                            : Colors.grey)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.local_fire_department_rounded,
                                        size: 13,
                                        color: userHabit.currentStreak > 0
                                            ? Colors.orange
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        streakText,
                                        style: lang.getTextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white54
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildHabitWeekDots(userHabit, habitInfo, isDark),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: isCompleted
                              ? LinearGradient(colors: [
                                  habitInfo.color,
                                  habitInfo.color.withOpacity(0.7),
                                ])
                              : null,
                          color: isCompleted ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCompleted
                                ? habitInfo.color
                                : (isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 22)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitWeekDots(
      UserHabit userHabit, HabitItem habitInfo, bool isDark) {
    final today = DateTime.now();

    return Row(
      children: List.generate(7, (index) {
        final date = today.subtract(Duration(days: 6 - index));
        final isDone = userHabit.completedDates.any((d) =>
            d.year == date.year && d.month == date.month && d.day == date.day);
        final isToday = index == 6;

        return Expanded(
          child: Container(
            height: 7,
            margin: EdgeInsetsDirectional.only(end: index == 6 ? 0 : 5),
            decoration: BoxDecoration(
              gradient: isDone
                  ? LinearGradient(colors: [
                      habitInfo.color,
                      habitInfo.color.withOpacity(0.65)
                    ])
                  : null,
              color: isDone
                  ? null
                  : (isDark
                      ? Colors.white.withOpacity(0.10)
                      : const Color(0xFFE8F4F2)),
              borderRadius: BorderRadius.circular(999),
              border: isToday
                  ? Border.all(
                      color: habitInfo.color.withOpacity(0.55), width: 1)
                  : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHabitsGrid(
      LanguageService lang, bool isDark, String languageCode) {
    return Column(
      children: [
        // Category filter
        _buildCategoryFilter(isDark, languageCode),
        // Grid
        Expanded(
          child: Consumer<HabitsService>(
            builder: (context, habitsService, child) {
              List<HabitItem> habits = _selectedCategory == 'all'
                  ? habitsService.allAvailableHabits
                  : habitsService.getHabitsByCategory(_selectedCategory);

              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 700 ? 5 : 3;

                  return GridView.builder(
                    padding: const EdgeInsets.only(
                        left: 20, right: 20, top: 20, bottom: 120),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      childAspectRatio: 0.86,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      final isAdded = habitsService.isHabitAdded(habit.id);

                      return _buildHabitGridItem(lang, isDark, languageCode,
                          habit, isAdded, habitsService);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(bool isDark, String languageCode) {
    final categories = ['all', ...HabitsList.categories];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          String name = category == 'all'
              ? (languageCode == 'arabic'
                  ? 'الكل'
                  : languageCode == 'kurdish'
                      ? 'هەموو'
                      : 'All')
              : HabitsList.getCategoryName(category, languageCode);

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF0D9488), Color(0xFF0F766E)])
                    : null,
                color: isSelected
                    ? null
                    : (isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white.withOpacity(0.92)),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0D9488)
                      : (isDark ? Colors.white10 : const Color(0xFFE0F2EF)),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: const Color(0xFF0D9488).withOpacity(0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 6))
                      ]
                    : null,
              ),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : const Color(0xFF53736E)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHabitGridItem(
      LanguageService lang,
      bool isDark,
      String languageCode,
      HabitItem habit,
      bool isAdded,
      HabitsService habitsService) {
    return GestureDetector(
      onTap: () {
        if (isAdded) {
          habitsService.removeHabit(habit.id);
        } else {
          habitsService.addHabit(habit.id);
        }
      },
      onLongPress: habit.isCustom
          ? () =>
              _showDeleteCustomHabitDialog(lang, isDark, habit, habitsService)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isAdded
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    habit.color.withOpacity(0.22),
                    habit.color.withOpacity(0.08)
                  ],
                )
              : null,
          color: isAdded
              ? null
              : (isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.92)),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isAdded
                ? habit.color
                : (isDark ? Colors.white10 : const Color(0xFFE8F4F2)),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isAdded
                  ? habit.color.withOpacity(0.22)
                  : const Color(0xFF0F766E).withOpacity(isDark ? 0.05 : 0.07),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              habit.emoji,
              style: const TextStyle(fontSize: 30),
            ),
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Text(
                habit.getName(languageCode),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: lang.getTextStyle(
                  fontSize: 9,
                  fontWeight: isAdded ? FontWeight.w900 : FontWeight.w700,
                  color: isAdded
                      ? habit.color
                      : (isDark ? Colors.white70 : const Color(0xFF49615D)),
                ),
              ),
            ),
            if (isAdded)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.check_circle, size: 14, color: habit.color),
              ),
          ],
        ),
      ),
    );
  }

  // --- Dialogs ---

  void _showDeleteDialog(LanguageService lang, bool isDark, String habitId,
      HabitItem habitInfo, HabitsService habitsService) {
    final languageCode = lang.currentLanguage == AppLanguage.arabic
        ? 'arabic'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'kurdish'
            : 'english';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          languageCode == 'arabic'
              ? 'إزالة من عاداتي؟'
              : languageCode == 'kurdish'
                  ? 'لابردن لە ڕەوشتەکانم؟'
                  : 'Remove from My Habits?',
          style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          habitInfo.getName(languageCode),
          style: lang.getTextStyle(
              color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style:
                    TextStyle(color: isDark ? Colors.white60 : Colors.black45)),
          ),
          ElevatedButton(
            onPressed: () {
              habitsService.removeHabit(habitId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteCustomHabitDialog(LanguageService lang, bool isDark,
      HabitItem habitInfo, HabitsService habitsService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Custom Habit?',
          style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          'This will permanently delete "${habitInfo.nameEnglish}"',
          style: lang.getTextStyle(
              color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style:
                    TextStyle(color: isDark ? Colors.white60 : Colors.black45)),
          ),
          ElevatedButton(
            onPressed: () {
              habitsService.deleteCustomHabitDefinition(habitInfo.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddCustomHabitDialog(LanguageService lang, bool isDark) {
    final nameController = TextEditingController();
    String selectedEmoji = '💪';
    String selectedCategory = 'health';

    // Available emojis for habits - Islamic/family-friendly emojis (60+ emojis)
    final List<String> availableEmojis = [
      // Face & Emotion Emojis
      '😊', '😌', '🥰', '😇', '🤗', '😃', '😄', '🙂', '😎', '🤩',
      '😤', '💪', '🫡', '🥳', '😍', '🤓', '😏', '🤔', '🧐', '😶',
      // Golden Leaf & Nature
      '🍂', '🍁', '🌿', '🌱', '🌾', '🌻', '🌸', '🌺', '🌷', '🌼',
      '🍀', '🌴', '🌳', '🌲', '🪴', '🌵', '🌹', '💐', '🌊', '⭐',
      // Health & Fitness
      '🏃', '🚶', '🏊', '🚴', '🧘', '😴', '💧', '🏋️', '⚽', '🏀',
      // Spiritual & Islamic
      '🕌', '📿', '🤲', '📖', '🌙', '☪️', '✨', '🕋', '🌟',
      // Learning & Productivity
      '📚', '✏️', '🎓', '💼', '📝', '🧠', '💡', '🎯', '📊', '🖊️',
      // Health & Food
      '🍎', '🥗', '🥛', '🍵', '🚭', '🦷', '🚿', '🧹', '🥦', '🍇',
      // Family & Social & Celebration
      '👨‍👩‍👧‍👦', '📞', '🤝', '🏠', '❤️', '💚', '🎉', '🏆', '🎁', '💎',
    ];

    // Localized strings
    String dialogTitle = lang.currentLanguage == AppLanguage.arabic
        ? 'عادة جديدة'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'ڕەوشتی نوێ'
            : 'New Habit';
    String habitNameLabel = lang.currentLanguage == AppLanguage.arabic
        ? 'اسم العادة'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'ناوی ڕەوشت'
            : 'Habit Name';
    String selectEmojiLabel = lang.currentLanguage == AppLanguage.arabic
        ? 'اختر الرمز'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'ئیمۆجی هەڵبژێرە'
            : 'Select Emoji';
    String selectCategoryLabel = lang.currentLanguage == AppLanguage.arabic
        ? 'اختر الفئة'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'پۆل هەڵبژێرە'
            : 'Select Category';
    String cancelText = lang.currentLanguage == AppLanguage.arabic
        ? 'إلغاء'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'پاشگەزبوونەوە'
            : 'Cancel';
    String createText = lang.currentLanguage == AppLanguage.arabic
        ? 'إنشاء'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'دروستکردن'
            : 'Create';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            dialogTitle,
            style: lang.getTextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Habit Name Input
                TextField(
                  controller: nameController,
                  textDirection: lang.textDirection,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF122129).withOpacity(0.72)
                        : const Color(0xFFF8FAFC),
                    labelText: habitNameLabel,
                    labelStyle: lang.getTextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0D9488)),
                    ),
                  ),
                  style: lang.getTextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 20),

                // Emoji Selection Label
                Text(
                  selectEmojiLabel,
                  style: lang.getTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),

                // Emoji Grid - using Wrap instead of GridView
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableEmojis.map((emoji) {
                        final isSelected = emoji == selectedEmoji;
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedEmoji = emoji),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0D9488).withOpacity(0.3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(
                                      color: const Color(0xFF0D9488), width: 2)
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Category Selection Label
                Text(
                  selectCategoryLabel,
                  style: lang.getTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),

                // Category Dropdown
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor:
                        isDark ? const Color(0xFF1A1A2E) : Colors.white,
                    items: HabitsList.categories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                HabitsList.getCategoryName(
                                    c,
                                    lang.currentLanguage == AppLanguage.arabic
                                        ? 'arabic'
                                        : lang.currentLanguage ==
                                                AppLanguage.kurdish
                                            ? 'kurdish'
                                            : 'english'),
                                style: lang.getTextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedCategory = val!),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                cancelText,
                style: lang.getTextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  Provider.of<HabitsService>(context, listen: false)
                      .createCustomHabit(nameController.text, selectedEmoji,
                          Colors.teal, selectedCategory);
                  Navigator.pop(context);
                }
              },
              child: Text(
                createText,
                style: lang.getTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatisticsSheet(LanguageService lang, bool isDark) {
    // Localized strings
    String titleText = lang.currentLanguage == AppLanguage.arabic
        ? 'إحصائيات العادات'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'ئاماری ڕەوشتەکان'
            : 'Habits Statistics';
    String totalCompletionsText = lang.currentLanguage == AppLanguage.arabic
        ? 'إجمالي الإنجازات'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'کۆی تەواوکردن'
            : 'Total Completions';
    String bestStreakText = lang.currentLanguage == AppLanguage.arabic
        ? 'أفضل سلسلة'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'باشترین زنجیرە'
            : 'Best Streak';
    String activeHabitsText = lang.currentLanguage == AppLanguage.arabic
        ? 'عادات نشطة'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'ڕەوشتە چالاکەکان'
            : 'Active Habits';
    String perHabitStatsText = lang.currentLanguage == AppLanguage.arabic
        ? 'إحصائيات كل عادة'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'ئاماری هەر ڕەوشتێک'
            : 'Per Habit Stats';
    String timesText = lang.currentLanguage == AppLanguage.arabic
        ? 'مرة'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'جار'
            : 'times';
    String daysText = lang.currentLanguage == AppLanguage.arabic
        ? 'يوم'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'ڕۆژ'
            : 'days';

    final languageCode = lang.currentLanguage == AppLanguage.arabic
        ? 'arabic'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'kurdish'
            : 'english';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Consumer<HabitsService>(
            builder: (context, habitsService, child) {
              final totalCompletions = habitsService.getTotalCompletions();
              final bestStreak = habitsService.getBestStreakOverall();
              final totalHabits = habitsService.getTotalHabitsCount();
              final userHabits = habitsService.userHabits;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.bar_chart_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          titleText,
                          style: lang.getTextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Overall Stats Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildOverallStatCard(
                              lang,
                              isDark,
                              Icons.check_circle_rounded,
                              '$totalCompletions',
                              totalCompletionsText,
                              const Color(0xFF4CAF50)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOverallStatCard(
                              lang,
                              isDark,
                              Icons.local_fire_department_rounded,
                              '$bestStreak',
                              bestStreakText,
                              const Color(0xFFFF9800)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOverallStatCard(
                              lang,
                              isDark,
                              Icons.list_alt_rounded,
                              '$totalHabits',
                              activeHabitsText,
                              const Color(0xFF0D9488)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Per Habit Stats Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.insights_rounded,
                            color: isDark ? Colors.white70 : Colors.black54,
                            size: 20),
                        const SizedBox(width: 8),
                        Text(perHabitStatsText,
                            style: lang.getTextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark ? Colors.white70 : Colors.black54)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Per Habit Stats List
                  Flexible(
                    child: userHabits.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.hourglass_empty_rounded,
                                    size: 48,
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  lang.currentLanguage == AppLanguage.arabic
                                      ? 'لا توجد عادات مضافة'
                                      : lang.currentLanguage ==
                                              AppLanguage.kurdish
                                          ? 'هیچ ڕەوشتێک زیادنەکراوە'
                                          : 'No habits added yet',
                                  style: lang.getTextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: userHabits.length,
                            itemBuilder: (context, index) {
                              final userHabit = userHabits[index];
                              final habitDef = habitsService
                                  .getHabitDefinition(userHabit.habitId);
                              if (habitDef == null) return const SizedBox();

                              final completions =
                                  userHabit.completedDates.length;
                              final currentStreak = userHabit.currentStreak;
                              final best = userHabit.bestStreak;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: habitDef.color.withOpacity(0.3),
                                      width: 1),
                                ),
                                child: Row(
                                  children: [
                                    // Emoji
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: habitDef.color.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                          child: Text(habitDef.emoji,
                                              style: const TextStyle(
                                                  fontSize: 24))),
                                    ),
                                    const SizedBox(width: 12),

                                    // Name & Stats
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(habitDef.getName(languageCode),
                                              style: lang.getTextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black)),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.check_circle_outline,
                                                  size: 14,
                                                  color:
                                                      const Color(0xFF4CAF50)),
                                              const SizedBox(width: 4),
                                              Text('$completions $timesText',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: isDark
                                                          ? Colors.white60
                                                          : Colors.black54)),
                                              const SizedBox(width: 12),
                                              Icon(Icons.local_fire_department,
                                                  size: 14,
                                                  color:
                                                      const Color(0xFFFF9800)),
                                              const SizedBox(width: 4),
                                              Text(
                                                  '$currentStreak/$best $daysText',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: isDark
                                                          ? Colors.white60
                                                          : Colors.black54)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Best Streak Badge
                                    if (best > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFFFD700),
                                                Color(0xFFFFA500)
                                              ]),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.emoji_events,
                                                color: Colors.white, size: 14),
                                            const SizedBox(width: 4),
                                            Text('$best',
                                                style: lang.getTextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOverallStatCard(LanguageService lang, bool isDark, IconData icon,
      String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.15) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: lang.getTextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: lang.getTextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white60 : Colors.black54),
              textAlign: TextAlign.center,
              maxLines: 2),
        ],
      ),
    );
  }
}
