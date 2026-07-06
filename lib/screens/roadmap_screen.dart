import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/roadmap_service.dart';
import '../services/timer_service.dart';
import '../services/language_service.dart';
import 'package:provider/provider.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  final RoadmapService _roadmapService = RoadmapService();
  final RecoveryTimerService _timerService = RecoveryTimerService();
  late ScrollController _scrollController;
  bool _isLoading = true;
  bool _showConfetti = false;
  int? _celebratingStage;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadData();
  }

  Future<void> _loadData() async {
    await _timerService.loadStartDate();
    await _roadmapService.loadData();

    // Load persisted "last seen unlocked count" so popup only shows once
    final prefs = await SharedPreferences.getInstance();
    final lastSeenUnlocked = prefs.getInt('roadmap_last_seen_unlocked') ?? 0;

    final days = _timerService.totalDays;
    _roadmapService.updateRecoveryDays(days);

    // Check if a new stage was unlocked since last seen
    final newUnlockedCount = _roadmapService.getUnlockedStagesCount();
    if (newUnlockedCount > lastSeenUnlocked && lastSeenUnlocked > 0) {
      // Save the new count so we don't show again
      await prefs.setInt('roadmap_last_seen_unlocked', newUnlockedCount);
      // Find the newly unlocked stage
      final newStage = RoadmapService.stages[newUnlockedCount - 1];
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showStageUnlockDialog(newStage);
      });
    } else if (lastSeenUnlocked == 0) {
      // First time: just save current count, don't show popup
      await prefs.setInt('roadmap_last_seen_unlocked', newUnlockedCount);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToCurrentStage();
    }
  }

  void _scrollToCurrentStage() {
    final currentStage = _roadmapService.getCurrentStage();
    // Account for stats card height + items before current stage
    final scrollOffset = 160.0 + (currentStage - 1) * 220.0;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          scrollOffset.clamp(0, _scrollController.position.maxScrollExtent),
        );
      }
    });
  }

  void _triggerConfetti(int stageNumber) {
    setState(() {
      _showConfetti = true;
      _celebratingStage = stageNumber;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showConfetti = false;
          _celebratingStage = null;
        });
      }
    });
  }

  void _showStageUnlockDialog(RecoveryStage stage) {
    final lang = Provider.of<LanguageService>(context, listen: false);
    final l = _getLang(lang);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, a1, a2) => const SizedBox(),
      transitionBuilder: (ctx, a1, a2, child) {
        final curve = Curves.elasticOut.transform(a1.value);
        return Transform.scale(
          scale: curve,
          child: Opacity(
            opacity: a1.value,
            child: AlertDialog(
              backgroundColor: const Color(0xFF0d1a30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [stage.color, stage.color.withOpacity(0.5)]),
                      boxShadow: [BoxShadow(color: stage.color.withOpacity(0.4), blurRadius: 24)],
                    ),
                    child: Center(child: Text(stage.emoji, style: const TextStyle(fontSize: 36))),
                  ),
                  const SizedBox(height: 16),
                  Text('🎊', style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    _t(lang, 'تم فتح مرحلة جديدة!', 'قۆناغێکی نوێ کرایەوە!', 'New Stage Unlocked!'),
                    style: lang.getTextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stage.getName(l),
                    style: lang.getTextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: stage.color),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stage.getDescription(l),
                    style: lang.getTextStyle(fontSize: 12, color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [stage.color, stage.color.withOpacity(0.7)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _t(lang, 'رائع!', 'زۆر باشە!', 'Awesome!'),
                        style: lang.getTextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _showUncheckConfirm(LanguageService lang) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0d1a30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _t(lang, 'تأكيد الإلغاء', 'دڵنیاکردنەوە', 'Confirm Uncheck'),
          style: lang.getTextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Text(
          _t(lang, 'هل تريد إلغاء إتمام هذه المهمة؟', 'دەتەوێت ئەم ئەرکە لاببەیت؟', 'Do you want to uncheck this task?'),
          style: lang.getTextStyle(fontSize: 13, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t(lang, 'لا', 'نەخێر', 'No'),
              style: lang.getTextStyle(fontSize: 13, color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t(lang, 'نعم', 'بەڵێ', 'Yes'),
              style: lang.getTextStyle(fontSize: 13, color: const Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getLang(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'ar';
      case AppLanguage.kurdish: return 'ku';
      case AppLanguage.english: return 'en';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = lang.isDarkMode;

    return Directionality(
      textDirection: lang.textDirection,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF0a1628), const Color(0xFF0d1f3c), const Color(0xFF0a1628)]
                  : [const Color(0xFFe8f0ff), const Color(0xFFd0e0f5), const Color(0xFFe8f0ff)],
            ),
          ),
          child: DefaultTextStyle(
            style: const TextStyle(decoration: TextDecoration.none),
            child: Stack(
              children: [
                // Subtle decorative circles
                Positioned(
                  top: -60, right: -40,
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        const Color(0xFF0D9488).withOpacity(isDark ? 0.08 : 0.12), Colors.transparent,
                      ]),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 100, left: -80,
                  child: Container(
                    width: 250, height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        const Color(0xFF0F766E).withOpacity(isDark ? 0.06 : 0.1), Colors.transparent,
                      ]),
                    ),
                  ),
                ),
                // Main content
                SafeArea(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: isDark ? const Color(0xFF0D9488) : const Color(0xFF4a6cf7)))
                      : Column(
                          children: [
                            _buildHeader(lang),
                            Expanded(child: _buildRoadmap(lang)),
                          ],
                        ),
                ),
                // Confetti overlay
                if (_showConfetti) _ConfettiOverlay(stageNumber: _celebratingStage ?? 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(LanguageService lang) {
    final isDark = lang.isDarkMode;
    String title;
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: title = 'خارطة التعافي'; break;
      case AppLanguage.kurdish: title = 'نەخشەی چاکبوونەوە'; break;
      case AppLanguage.english: title = 'Recovery Roadmap'; break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white70 : Colors.black87, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: lang.getTextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
          ),
          _buildDaysCircle(),
        ],
      ),
    );
  }

  Widget _buildDaysCircle() {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
        ),
        boxShadow: [BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.25), blurRadius: 16, spreadRadius: 2)],
      ),
      child: Center(
        child: Text(
          '${_roadmapService.currentRecoveryDays}',
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
        ),
      ),
    );
  }

  Widget _buildRoadmap(LanguageService lang) {
    final l = _getLang(lang);
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 6, bottom: 120),
      children: [
        // Stats card
        _buildStatsCard(lang),
        const SizedBox(height: 10),
        // Weekly progress chart
        _buildWeeklyChart(lang),
        const SizedBox(height: 10),
        // Next stage countdown
        _buildNextStageCountdown(lang, l),
        const SizedBox(height: 12),
        // Stage list
        ...RoadmapService.stages.asMap().entries.map((entry) {
          final index = entry.key;
          final stage = entry.value;
          final isUnlocked = _roadmapService.isStageUnlocked(stage.stageNumber);
          final isCompleted = _roadmapService.isStageCompleted(stage.stageNumber);
          final isCurrent = _roadmapService.getCurrentStage() == stage.stageNumber;
          final stageProgress = _roadmapService.getStageProgress(stage.stageNumber);

          return Column(
            children: [
              if (index > 0) _buildConnectionLine(isUnlocked, isCompleted, lang),
              _buildStageCard(stage, isUnlocked, isCompleted, isCurrent, stageProgress, lang, l),
            ],
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  // ──────── STATS CARD ────────
  Widget _buildStatsCard(LanguageService lang) {
    final isDark = lang.isDarkMode;
    final completedStages = _roadmapService.getCompletedStagesCount();
    final unlockedStages = _roadmapService.getUnlockedStagesCount();
    final completedTasks = _roadmapService.getCompletedTasksCount();
    final totalTasks = _roadmapService.getTotalTasksCount();
    final progress = _roadmapService.getOverallProgress();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.95),
            isDark ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.6),
          ],
        ),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_t(lang, 'التقدم الإجمالي', 'پێشکەوتنی گشتی', 'Overall Progress'),
                style: lang.getTextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${(progress * 100).toInt()}%',
                  style: GoogleFonts.cairo(color: const Color(0xFF0D9488), fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(height: 6, decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(8))),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)]),
                      boxShadow: [BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.4), blurRadius: 6)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _buildStatItem(
                Icons.flag_outlined, const Color(0xFF4CAF50),
                '$completedStages/${ RoadmapService.stages.length}',
                _t(lang, 'مراحل', 'قۆناغ', 'Stages'), lang,
              ),
              Container(width: 1, height: 36, color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.08)),
              _buildStatItem(
                Icons.check_circle_outline, const Color(0xFF0D9488),
                '$completedTasks/$totalTasks',
                _t(lang, 'مهمة', 'ئەرک', 'Tasks'), lang,
              ),
              Container(width: 1, height: 36, color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.08)),
              _buildStatItem(
                Icons.lock_open, const Color(0xFFFFB300),
                '$unlockedStages',
                _t(lang, 'مفتوح', 'کراوە', 'Open'), lang,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String value, String label, LanguageService lang) {
    final isDark = lang.isDarkMode;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: lang.getTextStyle(fontSize: 10, color: isDark ? Colors.white.withOpacity(0.4) : Colors.black45)),
        ],
      ),
    );
  }

  // ──────── WEEKLY PROGRESS CHART ────────
  Widget _buildWeeklyChart(LanguageService lang) {
    final isDark = lang.isDarkMode;
    final completedTasks = _roadmapService.getCompletedTasksCount();
    final totalTasks = _roadmapService.getTotalTasksCount();
    final days = _roadmapService.currentRecoveryDays;

    // Generate mock weekly data based on completed tasks
    final weekData = <double>[];
    final rng = math.Random(completedTasks);
    final avgPerDay = totalTasks > 0 ? (completedTasks / math.max(days, 1)).clamp(0.0, 5.0) : 0.0;
    for (int i = 0; i < 7; i++) {
      if (i < days % 7 || days >= 7) {
        weekData.add((avgPerDay + rng.nextDouble() * 2 - 0.5).clamp(0.0, 5.0));
      } else {
        weekData.add(0);
      }
    }
    final maxVal = weekData.reduce(math.max).clamp(1.0, 10.0);

    final dayLabelsAr = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
    final dayLabelsKu = ['ش', 'ی', 'دوو', 'سێ', 'چو', 'پ', 'هە'];
    final dayLabelsEn = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    List<String> dayLabels;
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: dayLabels = dayLabelsAr; break;
      case AppLanguage.kurdish: dayLabels = dayLabelsKu; break;
      case AppLanguage.english: dayLabels = dayLabelsEn; break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: isDark 
              ? [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.02)] 
              : [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.6)],
        ),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: const Color(0xFF0D9488), size: 18),
              const SizedBox(width: 8),
              Text(
                _t(lang, 'التقدم الأسبوعي', 'پێشکەوتنی هەفتانە', 'Weekly Progress'),
                style: lang.getTextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white.withOpacity(0.8) : Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 90,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final barHeight = maxVal > 0 ? (weekData[i] / maxVal) * 50 : 0.0;
                  final isToday = i == (DateTime.now().weekday % 7);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 400 + i * 60),
                          width: 22,
                          height: barHeight.clamp(4.0, 50.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter, end: Alignment.topCenter,
                              colors: isToday
                                  ? [const Color(0xFF0D9488), const Color(0xFF0F766E)]
                                  : [const Color(0xFF0D9488).withOpacity(isDark ? 0.4 : 0.25), const Color(0xFF0F766E).withOpacity(isDark ? 0.2 : 0.15)],
                            ),
                            boxShadow: isToday
                                ? [BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.3), blurRadius: 6)]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayLabels[i],
                          style: lang.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isToday ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white.withOpacity(0.6) : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────── NEXT STAGE COUNTDOWN ────────
  Widget _buildNextStageCountdown(LanguageService lang, String l) {
    final isDark = lang.isDarkMode;
    final nextStage = _roadmapService.getNextLockedStage();
    if (nextStage == null) {
      // All stages unlocked
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF4CAF50).withOpacity(isDark ? 0.08 : 0.12),
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(isDark ? 0.15 : 0.3)),
        ),
        child: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _t(lang, 'جميع المراحل مفتوحة! أنت بطل حقيقي', 'هەموو قۆناغەکان کراوەن! تۆ پاڵەوانێکی ڕاستەقینەیت', 'All stages unlocked! You are a true champion'),
                style: lang.getTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4CAF50)),
              ),
            ),
          ],
        ),
      );
    }

    final daysRemaining = _roadmapService.getDaysToNextStage();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: nextStage.color.withOpacity(isDark ? 0.06 : 0.1),
        border: Border.all(color: nextStage.color.withOpacity(isDark ? 0.12 : 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: nextStage.color.withOpacity(isDark ? 0.12 : 0.18),
            ),
            child: const Center(
              child: Text('⏳', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t(lang,
                    '$daysRemaining يوم لفتح "${nextStage.getName(l)}"',
                    '$daysRemaining ڕۆژ بۆ کردنەوەی "${nextStage.getName(l)}"',
                    '$daysRemaining days to unlock "${nextStage.getName(l)}"',
                  ),
                  style: lang.getTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white.withOpacity(0.8) : Colors.black87),
                ),
                const SizedBox(height: 4),
                // Mini progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: 1.0 - (daysRemaining / nextStage.requiredDays).clamp(0.0, 1.0),
                    minHeight: 3,
                    backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                    valueColor: AlwaysStoppedAnimation(nextStage.color.withOpacity(isDark ? 0.6 : 0.8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionLine(bool isUnlocked, bool isPreviousCompleted, LanguageService lang) {
    final isDark = lang.isDarkMode;
    return Container(
      width: 2, height: 28,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: isPreviousCompleted
              ? [const Color(0xFF4CAF50).withOpacity(0.6), const Color(0xFF4CAF50).withOpacity(0.2)]
              : isUnlocked
                  ? [const Color(0xFF0D9488).withOpacity(0.5), const Color(0xFF0D9488).withOpacity(0.15)]
                  : [
                      isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.1),
                      isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03)
                    ],
        ),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildStageCard(
    RecoveryStage stage, bool isUnlocked, bool isCompleted,
    bool isCurrent, double progress, LanguageService lang, String l,
  ) {
    final isDark = lang.isDarkMode;
    return GestureDetector(
        onTap: isUnlocked ? () => _showStageDetail(stage, lang) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: isUnlocked
                ? (isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.85))
                : (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)),
            border: Border.all(
              color: isCurrent
                  ? stage.color.withOpacity(isDark ? 0.5 : 0.7)
                  : isCompleted
                      ? const Color(0xFF4CAF50).withOpacity(isDark ? 0.3 : 0.5)
                      : isUnlocked
                          ? (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06))
                          : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
              width: isCurrent ? 1.5 : 1,
            ),
            boxShadow: isCurrent
                ? [BoxShadow(color: stage.color.withOpacity(isDark ? 0.15 : 0.1), blurRadius: 20, offset: const Offset(0, 4))]
                : (isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))]),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildStageCircle(stage, isUnlocked, isCompleted, isCurrent, lang),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(stage.getName(l),
                                style: lang.getTextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                                  color: isUnlocked
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : (isDark ? Colors.white.withOpacity(0.3) : Colors.black26))),
                            ),
                            if (isCompleted) _buildBadgePill(stage, lang, l),
                            if (isCurrent && !isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: stage.color.withOpacity(isDark ? 0.15 : 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(_t(lang, 'الحالي', 'ئێستا', 'Current'),
                                  style: lang.getTextStyle(fontSize: 10, color: stage.color, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(stage.getDescription(l),
                          style: lang.getTextStyle(fontSize: 11,
                            color: isUnlocked
                                ? (isDark ? Colors.white.withOpacity(0.5) : Colors.black54)
                                : (isDark ? Colors.white.withOpacity(0.2) : Colors.black26))),
                        // Unlock date
                        if (_timerService.startDate != null) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(Icons.calendar_today_rounded,
                              color: isUnlocked
                                  ? stage.color.withOpacity(isDark ? 0.5 : 0.7)
                                  : (isDark ? Colors.white.withOpacity(0.15) : Colors.black26),
                              size: 12),
                            const SizedBox(width: 5),
                            Text(
                              _getStageDate(stage, lang),
                              style: lang.getTextStyle(fontSize: 10,
                                color: isUnlocked
                                    ? stage.color.withOpacity(isDark ? 0.6 : 0.8)
                                    : (isDark ? Colors.white.withOpacity(0.2) : Colors.black38)),
                            ),
                          ]),
                        ],
                        if (isUnlocked && !isCompleted) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress, minHeight: 3,
                                  backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                                  valueColor: AlwaysStoppedAnimation(stage.color.withOpacity(isDark ? 0.7 : 0.9)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${(progress * 100).toInt()}%',
                              style: lang.getTextStyle(fontSize: 10, color: isDark ? Colors.white.withOpacity(0.4) : Colors.black45)),
                          ]),
                        ],
                        if (!isUnlocked) ...[
                          const SizedBox(height: 6),
                          Row(children: [
                            Icon(Icons.lock_outline, color: isDark ? Colors.white.withOpacity(0.2) : Colors.black38, size: 13),
                            const SizedBox(width: 4),
                            Text(_getLockedText(stage.requiredDays, lang),
                              style: lang.getTextStyle(fontSize: 10, color: isDark ? Colors.white.withOpacity(0.2) : Colors.black38)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                  if (isUnlocked) Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(Icons.chevron_right, color: isDark ? Colors.white.withOpacity(0.2) : Colors.black38, size: 20),
                  ),
                ],
              ),
              // Motivational quote for current stage
              if (isCurrent && isUnlocked) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: stage.color.withOpacity(isDark ? 0.06 : 0.08),
                    border: isDark ? null : Border.all(color: stage.color.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      const Text('💬', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _roadmapService.getStageQuote(stage.stageNumber, l),
                          style: lang.getTextStyle(fontSize: 11, color: isDark ? Colors.white.withOpacity(0.6) : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
    );
  }

  // ──────── BADGE PILL ────────
  Widget _buildBadgePill(RecoveryStage stage, LanguageService lang, String l) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFFFFD700).withOpacity(0.2),
          const Color(0xFFFFA000).withOpacity(0.1),
        ]),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_roadmapService.getBadgeEmoji(stage.stageNumber), style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(_roadmapService.getBadgeName(stage.stageNumber, l),
            style: lang.getTextStyle(fontSize: 9, color: const Color(0xFFFFD700), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStageCircle(RecoveryStage stage, bool isUnlocked, bool isCompleted, bool isCurrent, LanguageService lang) {
    final isDark = lang.isDarkMode;
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isCompleted
            ? const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)])
            : isUnlocked
                ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [stage.color, stage.color.withOpacity(0.6)])
                : null,
        color: isUnlocked ? null : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        border: !isUnlocked ? Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)) : null,
        boxShadow: isCurrent
            ? [BoxShadow(color: stage.color.withOpacity(0.3), blurRadius: 12, spreadRadius: 1)]
            : isCompleted
                ? [BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.3), blurRadius: 8)]
                : null,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 22)
            : isUnlocked
                ? Text(stage.emoji, style: const TextStyle(fontSize: 22))
                : Icon(Icons.lock_outline, color: isDark ? Colors.white.withOpacity(0.2) : Colors.black38, size: 20),
      ),
    );
  }

  void _showStageDetail(RecoveryStage stage, LanguageService lang) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, a1, a2) => const SizedBox(),
      transitionBuilder: (ctx, a1, a2, child) {
        final slideUp = Tween(begin: const Offset(0, 0.3), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic))
            .evaluate(a1);
        final fade = CurveTween(curve: Curves.easeIn).evaluate(a1);
        return SlideTransition(
          position: AlwaysStoppedAnimation(slideUp),
          child: FadeTransition(
            opacity: AlwaysStoppedAnimation(fade),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _StageDetailSheet(
                stage: stage,
                roadmapService: _roadmapService,
                lang: lang,
                langCode: _getLang(lang),
                onTaskToggled: () {
                  setState(() {});
                  // Check if stage just became completed
                  if (_roadmapService.isStageCompleted(stage.stageNumber)) {
                    _triggerConfetti(stage.stageNumber);
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  String _getLockedText(int requiredDays, LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'يُفتح بعد $requiredDays يوم';
      case AppLanguage.kurdish: return 'دوای $requiredDays ڕۆژ کراوە دەبێت';
      case AppLanguage.english: return 'Unlocks after $requiredDays days';
    }
  }

  String _getStageDate(RecoveryStage stage, LanguageService lang) {
    final startDate = _timerService.startDate!;
    final unlockDate = startDate.add(Duration(days: stage.requiredDays));
    final day = unlockDate.day.toString().padLeft(2, '0');
    final month = unlockDate.month.toString().padLeft(2, '0');
    final year = unlockDate.year;
    final dateStr = year < 2024 ? '---' : '$day/$month/$year';
    final isUnlocked = _roadmapService.isStageUnlocked(stage.stageNumber);
    switch (lang.currentLanguage) {
      case AppLanguage.arabic:
        return isUnlocked ? '📅 تم الفتح: $dateStr' : '📅 يُفتح في: $dateStr';
      case AppLanguage.kurdish:
        return isUnlocked ? '📅 کرایەوە: $dateStr' : '📅 دەکرێتەوە: $dateStr';
      case AppLanguage.english:
        return isUnlocked ? '📅 Unlocked: $dateStr' : '📅 Unlocks: $dateStr';
    }
  }

  String _t(LanguageService lang, String ar, String ku, String en) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return ar;
      case AppLanguage.kurdish: return ku;
      case AppLanguage.english: return en;
    }
  }
}

// ═══════════════════════════════════════════════════════
// CONFETTI OVERLAY
// ═══════════════════════════════════════════════════════
class _ConfettiOverlay extends StatefulWidget {
  final int stageNumber;
  const _ConfettiOverlay({required this.stageNumber});

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ConfettiParticle> _particles;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..forward();
    _particles = List.generate(50, (_) => _ConfettiParticle(
      x: _random.nextDouble(),
      y: -_random.nextDouble() * 0.3,
      speed: 0.3 + _random.nextDouble() * 0.7,
      wobble: _random.nextDouble() * 2 * math.pi,
      size: 4 + _random.nextDouble() * 8,
      color: [
        const Color(0xFFFFD700), const Color(0xFFFF6B6B), const Color(0xFF4CAF50),
        const Color(0xFF0D9488), const Color(0xFFFF9800), const Color(0xFF9C27B0),
        const Color(0xFF14B8A6), const Color(0xFF0D9488),
      ][_random.nextInt(8)],
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return IgnorePointer(
          child: Stack(
            children: [
              // Dark overlay that fades
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3 * (1 - _controller.value)),
                ),
              ),
              // Celebration text
              if (_controller.value < 0.7)
                Center(
                  child: Opacity(
                    opacity: (1 - _controller.value / 0.7).clamp(0, 1),
                    child: Transform.scale(
                      scale: 0.8 + _controller.value * 0.5,
                      child: Text('🎉', style: TextStyle(fontSize: 60 + _controller.value * 20)),
                    ),
                  ),
                ),
              // Particles
              ...(_particles.map((p) {
                final progress = _controller.value;
                final y = p.y + progress * p.speed * 1.5;
                final x = p.x + math.sin(progress * 6 + p.wobble) * 0.05;
                final opacity = (1 - progress).clamp(0.0, 1.0);
                return Positioned(
                  left: x * MediaQuery.of(context).size.width,
                  top: y * MediaQuery.of(context).size.height,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.rotate(
                      angle: progress * 4 + p.wobble,
                      child: Container(
                        width: p.size, height: p.size,
                        decoration: BoxDecoration(
                          color: p.color,
                          borderRadius: BorderRadius.circular(p.size > 8 ? 2 : 0),
                        ),
                      ),
                    ),
                  ),
                );
              })),
            ],
          ),
        );
      },
    );
  }
}

class _ConfettiParticle {
  final double x, y, speed, wobble, size;
  final Color color;
  const _ConfettiParticle({
    required this.x, required this.y, required this.speed,
    required this.wobble, required this.size, required this.color,
  });
}

// ═══════════════════════════════════════════════════════
// STAGE DETAIL SHEET
// ═══════════════════════════════════════════════════════
class _StageDetailSheet extends StatefulWidget {
  final RecoveryStage stage;
  final RoadmapService roadmapService;
  final LanguageService lang;
  final String langCode;
  final VoidCallback onTaskToggled;

  const _StageDetailSheet({
    required this.stage, required this.roadmapService,
    required this.lang, required this.langCode, required this.onTaskToggled,
  });

  @override
  State<_StageDetailSheet> createState() => _StageDetailSheetState();
}

class _StageDetailSheetState extends State<_StageDetailSheet> with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.roadmapService.getStageProgress(widget.stage.stageNumber);
    final l = widget.langCode;
    final completedCount = widget.stage.tasks.where((t) => widget.roadmapService.isTaskCompleted(t.id)).length;
    final isCompleted = widget.roadmapService.isStageCompleted(widget.stage.stageNumber);

    return Material(
      type: MaterialType.transparency,
      child: Directionality(
        textDirection: widget.lang.textDirection,
        child: DraggableScrollableSheet(
        initialChildSize: 0.78,
        maxChildSize: 0.94,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          return FadeTransition(
            opacity: _fadeIn,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                color: const Color(0xFF0d1a30),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, -10))],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: Stack(
                  children: [
                    // Top glow
                    Positioned(
                      top: -50, left: 0, right: 0,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(center: Alignment.topCenter, radius: 1.2,
                            colors: [widget.stage.color.withOpacity(0.12), Colors.transparent]),
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Handle
                          Center(child: Container(
                            width: 40, height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(2)),
                          )),

                          // Header card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white.withOpacity(0.04),
                              border: Border.all(color: widget.stage.color.withOpacity(0.15)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 60, height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                                          colors: [widget.stage.color, widget.stage.color.withOpacity(0.5)]),
                                        boxShadow: [BoxShadow(color: widget.stage.color.withOpacity(0.3), blurRadius: 16, spreadRadius: 1)],
                                      ),
                                      child: Center(child: Text(widget.stage.emoji, style: const TextStyle(fontSize: 28))),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${_t('المرحلة', 'قۆناغی', 'Stage')} ${widget.stage.stageNumber}',
                                            style: widget.lang.getTextStyle(fontSize: 12, color: widget.stage.color.withOpacity(0.8), fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(widget.stage.getName(l),
                                            style: widget.lang.getTextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Text('$completedCount/${widget.stage.tasks.length} ${_t('مهام', 'ئەرک', 'tasks')}',
                                      style: widget.lang.getTextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                                    const Spacer(),
                                    Text('${(progress * 100).toInt()}%',
                                      style: GoogleFonts.cairo(color: widget.stage.color, fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(value: progress, minHeight: 5,
                                    backgroundColor: Colors.white.withOpacity(0.06),
                                    valueColor: AlwaysStoppedAnimation(widget.stage.color)),
                                ),
                              ],
                            ),
                          ),

                          // Badge card (if completed)
                          if (isCompleted) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(colors: [
                                  const Color(0xFFFFD700).withOpacity(0.08),
                                  const Color(0xFFFFA000).withOpacity(0.04),
                                ]),
                                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.15)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFFFD700).withOpacity(0.15),
                                      border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                                    ),
                                    child: Center(child: Text(
                                      widget.roadmapService.getBadgeEmoji(widget.stage.stageNumber),
                                      style: const TextStyle(fontSize: 24),
                                    )),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_t('🏅 حصلت على وسام', '🏅 بادجت بەدەستهێنا', '🏅 Badge earned!'),
                                          style: widget.lang.getTextStyle(fontSize: 11, color: const Color(0xFFFFD700).withOpacity(0.8))),
                                        Text(widget.roadmapService.getBadgeName(widget.stage.stageNumber, l),
                                          style: widget.lang.getTextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFFFD700))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Quote card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: widget.stage.color.withOpacity(0.04),
                              border: Border.all(color: widget.stage.color.withOpacity(0.08)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('💬', style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    widget.roadmapService.getStageQuote(widget.stage.stageNumber, l),
                                    style: widget.lang.getTextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6), height: 1.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Advice card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: widget.stage.color.withOpacity(0.06),
                              border: Border.all(color: widget.stage.color.withOpacity(0.1)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(color: widget.stage.color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
                                  child: Icon(Icons.lightbulb_outline, color: widget.stage.color, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(widget.stage.getAdvice(l),
                                    style: widget.lang.getTextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7), height: 1.6)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Tasks
                          Text(_t('المهام', 'ئەرکەکان', 'Tasks'),
                            style: widget.lang.getTextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 14),

                          ...widget.stage.tasks.asMap().entries.map(
                            (entry) => _buildTaskItem(entry.value, l, entry.key),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
    );
  }

  Widget _buildTaskItem(StageTask task, String l, int index) {
    final isCompleted = widget.roadmapService.isTaskCompleted(task.id);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 80)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 15 * (1 - value)), child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () async {
            final isCurrentlyDone = widget.roadmapService.isTaskCompleted(task.id);
            // If unchecking, ask for confirmation
            if (isCurrentlyDone) {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF0d1a30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text(
                    _t('تأكيد الإلغاء', 'دڵنیاکردنەوە', 'Confirm Uncheck'),
                    style: widget.lang.getTextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  content: Text(
                    _t('هل تريد إلغاء إتمام هذه المهمة؟', 'دەتەوێت ئەم ئەرکە لاببەیت؟', 'Do you want to uncheck this task?'),
                    style: widget.lang.getTextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(_t('لا', 'نەخێر', 'No'),
                        style: widget.lang.getTextStyle(fontSize: 13, color: Colors.white54)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(_t('نعم', 'بەڵێ', 'Yes'),
                        style: widget.lang.getTextStyle(fontSize: 13, color: const Color(0xFFFF6B6B))),
                    ),
                  ],
                ),
              );
              if (confirm != true) return;
            }
            await widget.roadmapService.toggleTask(task.id);
            setState(() {});
            widget.onTaskToggled();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isCompleted ? widget.stage.color.withOpacity(0.08) : Colors.white.withOpacity(0.03),
              border: Border.all(color: isCompleted ? widget.stage.color.withOpacity(0.2) : Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? widget.stage.color : Colors.transparent,
                    border: Border.all(color: isCompleted ? widget.stage.color : Colors.white.withOpacity(0.2), width: 2),
                    boxShadow: isCompleted ? [BoxShadow(color: widget.stage.color.withOpacity(0.3), blurRadius: 8)] : null,
                  ),
                  child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                ),
                const SizedBox(width: 12),
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: widget.stage.color.withOpacity(isCompleted ? 0.12 : 0.06),
                  ),
                  child: Icon(task.icon, color: isCompleted ? widget.stage.color : Colors.white.withOpacity(0.35), size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.getTitle(l),
                        style: widget.lang.getTextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: isCompleted ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.7),
                        ).copyWith(
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.white.withOpacity(0.3),
                        )),
                      const SizedBox(height: 2),
                      Text(task.getDescription(l),
                        style: widget.lang.getTextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35))),
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

  String _t(String ar, String ku, String en) {
    switch (widget.lang.currentLanguage) {
      case AppLanguage.arabic: return ar;
      case AppLanguage.kurdish: return ku;
      case AppLanguage.english: return en;
    }
  }
}
