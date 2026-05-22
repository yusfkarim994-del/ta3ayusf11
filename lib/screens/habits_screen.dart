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

class _HabitsScreenState extends State<HabitsScreen> with TickerProviderStateMixin {
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
                  ? [const Color(0xFF0F0F1E), const Color(0xFF1A1A2E), const Color(0xFF0F0F1E)]
                  : [const Color(0xFFFAFBFF), const Color(0xFFF0F4FF), const Color(0xFFE8EDFF)],
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
              backgroundColor: const Color(0xFF667EEA),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      ),
    );
  }

  Widget _buildHeader(LanguageService lang, bool isDark, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                lang.isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: lang.getTextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ),
          // Statistics Button
          IconButton(
            onPressed: () => _showStatisticsSheet(lang, isDark),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF667EEA)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(LanguageService lang, bool isDark, String languageCode) {
    return Consumer<HabitsService>(
      builder: (context, habitsService, child) {
        final completed = habitsService.getTodayCompletedCount();
        final total = habitsService.getTotalHabitsCount();
        final progress = habitsService.getTodayProgress();

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

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF667EEA),
                const Color(0xFF764BA2),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667EEA).withOpacity(0.4),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          progressText,
                          style: lang.getTextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: lang.getTextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar(bool isDark, String addHabitsText, String myHabitsText) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_showAddHabits ? const Color(0xFF667EEA) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  myHabitsText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: !_showAddHabits ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _showAddHabits ? const Color(0xFF667EEA) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  addHabitsText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _showAddHabits ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHabits(LanguageService lang, bool isDark, String languageCode) {
    return Consumer<HabitsService>(
      builder: (context, habitsService, child) {
        final userHabits = habitsService.userHabits;

        if (userHabits.isEmpty) {
          return _buildEmptyState(lang, isDark, languageCode);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
          itemCount: userHabits.length,
          itemBuilder: (context, index) {
            final userHabit = userHabits[index];
            final habitInfo = habitsService.getHabitDefinition(userHabit.habitId);
            
            if (habitInfo == null) return const SizedBox.shrink();
            
            return _buildUserHabitCard(lang, isDark, languageCode, userHabit, habitInfo, habitsService);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(LanguageService lang, bool isDark, String languageCode) {
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
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  blurRadius: 30,
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

  Widget _buildUserHabitCard(LanguageService lang, bool isDark, String languageCode, UserHabit userHabit, HabitItem habitInfo, HabitsService habitsService) {
    final isCompleted = userHabit.isCompletedToday();
    
    String streakText = languageCode == 'arabic' 
        ? '${userHabit.currentStreak} يوم متتالي' 
        : languageCode == 'kurdish' 
            ? '${userHabit.currentStreak} ڕۆژ دوامدار' 
            : '${userHabit.currentStreak} day streak';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? habitInfo.color.withOpacity(0.5) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted 
                ? habitInfo.color.withOpacity(0.15)
                : Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => habitsService.toggleHabitCompletion(userHabit.habitId),
          onLongPress: () => _showDeleteDialog(lang, isDark, userHabit.habitId, habitInfo, habitsService),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Emoji with animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? habitInfo.color.withOpacity(0.2)
                        : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    habitInfo.emoji,
                    style: TextStyle(fontSize: isCompleted ? 28 : 24),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habitInfo.getName(languageCode),
                        style: lang.getTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ).copyWith(
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 14,
                            color: userHabit.currentStreak > 0 ? Colors.orange : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            streakText,
                            style: lang.getTextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted ? habitInfo.color : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCompleted ? habitInfo.color : (isDark ? Colors.white24 : Colors.black12),
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitsGrid(LanguageService lang, bool isDark, String languageCode) {
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

              return GridView.builder(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: habits.length,
                itemBuilder: (context, index) {
                  final habit = habits[index];
                  final isAdded = habitsService.isHabitAdded(habit.id);
                  
                  return _buildHabitGridItem(lang, isDark, languageCode, habit, isAdded, habitsService);
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
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 120),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          
          String name = category == 'all'
              ? (languageCode == 'arabic' ? 'الكل' : languageCode == 'kurdish' ? 'هەموو' : 'All')
              : HabitsList.getCategoryName(category, languageCode);

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF667EEA) : (isDark ? Colors.white.withOpacity(0.1) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF667EEA) : Colors.transparent,
                ),
              ),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHabitGridItem(LanguageService lang, bool isDark, String languageCode, HabitItem habit, bool isAdded, HabitsService habitsService) {
    return GestureDetector(
      onTap: () {
        if (isAdded) {
          habitsService.removeHabit(habit.id);
        } else {
          habitsService.addHabit(habit.id);
        }
      },
      onLongPress: habit.isCustom 
        ? () => _showDeleteCustomHabitDialog(lang, isDark, habit, habitsService)
        : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isAdded 
              ? habit.color.withOpacity(0.15)
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAdded ? habit.color : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isAdded 
                  ? habit.color.withOpacity(0.2)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              habit.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                habit.getName(languageCode),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: lang.getTextStyle(
                  fontSize: 9,
                  fontWeight: isAdded ? FontWeight.bold : FontWeight.normal,
                  color: isAdded ? habit.color : (isDark ? Colors.white70 : Colors.black54),
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

  void _showDeleteDialog(LanguageService lang, bool isDark, String habitId, HabitItem habitInfo, HabitsService habitsService) {
    final languageCode = lang.currentLanguage == AppLanguage.arabic 
        ? 'arabic' : lang.currentLanguage == AppLanguage.kurdish ? 'kurdish' : 'english';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
           languageCode == 'arabic' ? 'إزالة من عاداتي؟' : languageCode == 'kurdish' ? 'لابردن لە ڕەوشتەکانم؟' : 'Remove from My Habits?',
           style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          habitInfo.getName(languageCode),
          style: lang.getTextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white60 : Colors.black45)),
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
  
  void _showDeleteCustomHabitDialog(LanguageService lang, bool isDark, HabitItem habitInfo, HabitsService habitsService) {
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
          style: lang.getTextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white60 : Colors.black45)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    labelText: habitNameLabel,
                    labelStyle: lang.getTextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF667EEA)),
                    ),
                  ),
                  style: lang.getTextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
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
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
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
                          onTap: () => setDialogState(() => selectedEmoji = emoji),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFF667EEA).withOpacity(0.3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected 
                                  ? Border.all(color: const Color(0xFF667EEA), width: 2)
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
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                    items: HabitsList.categories.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        HabitsList.getCategoryName(c, lang.currentLanguage == AppLanguage.arabic 
                            ? 'arabic' 
                            : lang.currentLanguage == AppLanguage.kurdish 
                                ? 'kurdish' 
                                : 'english'),
                        style: lang.getTextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedCategory = val!),
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
                backgroundColor: const Color(0xFF667EEA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  Provider.of<HabitsService>(context, listen: false).createCustomHabit(
                    nameController.text, 
                    selectedEmoji, 
                    Colors.purple,
                    selectedCategory
                  );
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
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 24),
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
                          child: _buildOverallStatCard(lang, isDark, Icons.check_circle_rounded, '$totalCompletions', totalCompletionsText, const Color(0xFF4CAF50)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOverallStatCard(lang, isDark, Icons.local_fire_department_rounded, '$bestStreak', bestStreakText, const Color(0xFFFF9800)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOverallStatCard(lang, isDark, Icons.list_alt_rounded, '$totalHabits', activeHabitsText, const Color(0xFF667EEA)),
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
                        Icon(Icons.insights_rounded, color: isDark ? Colors.white70 : Colors.black54, size: 20),
                        const SizedBox(width: 8),
                        Text(perHabitStatsText, style: lang.getTextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
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
                                Icon(Icons.hourglass_empty_rounded, size: 48, color: isDark ? Colors.white24 : Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  lang.currentLanguage == AppLanguage.arabic ? 'لا توجد عادات مضافة' : lang.currentLanguage == AppLanguage.kurdish ? 'هیچ ڕەوشتێک زیادنەکراوە' : 'No habits added yet',
                                  style: lang.getTextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.grey),
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
                              final habitDef = habitsService.getHabitDefinition(userHabit.habitId);
                              if (habitDef == null) return const SizedBox();
                              
                              final completions = userHabit.completedDates.length;
                              final currentStreak = userHabit.currentStreak;
                              final best = userHabit.bestStreak;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: habitDef.color.withOpacity(0.3), width: 1),
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
                                      child: Center(child: Text(habitDef.emoji, style: const TextStyle(fontSize: 24))),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // Name & Stats
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(habitDef.getName(languageCode), style: lang.getTextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.check_circle_outline, size: 14, color: const Color(0xFF4CAF50)),
                                              const SizedBox(width: 4),
                                              Text('$completions $timesText', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
                                              const SizedBox(width: 12),
                                              Icon(Icons.local_fire_department, size: 14, color: const Color(0xFFFF9800)),
                                              const SizedBox(width: 4),
                                              Text('$currentStreak/$best $daysText', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Best Streak Badge
                                    if (best > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.emoji_events, color: Colors.white, size: 14),
                                            const SizedBox(width: 4),
                                            Text('$best', style: lang.getTextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
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
  
  Widget _buildOverallStatCard(LanguageService lang, bool isDark, IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.15) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: isDark ? null : [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: lang.getTextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: lang.getTextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54), textAlign: TextAlign.center, maxLines: 2),
        ],
      ),
    );
  }
}
