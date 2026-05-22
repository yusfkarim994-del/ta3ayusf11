import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../services/tracking_service.dart';
import '../services/language_service.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  DateTime _selectedMonth = DateTime.now();

  // Colors for each status
  static const Color successColor = Color(0xFF4CAF50);
  static const Color slipColor = Color(0xFFFFC107);
  static const Color relapseColor = Color(0xFFF44336);
  static const Color unknownColor = Color(0xFF9E9E9E);

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
      Provider.of<TrackingService>(context, listen: false).loadRecords();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getStatusColor(DayStatus status) {
    switch (status) {
      case DayStatus.success:
        return successColor;
      case DayStatus.slip:
        return slipColor;
      case DayStatus.relapse:
        return relapseColor;
      case DayStatus.unknown:
        return unknownColor;
    }
  }

  IconData _getStatusIcon(DayStatus status) {
    switch (status) {
      case DayStatus.success:
        return Icons.check_circle_rounded;
      case DayStatus.slip:
        return Icons.warning_rounded;
      case DayStatus.relapse:
        return Icons.heart_broken_rounded;
      case DayStatus.unknown:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = lang.isDarkMode;
    
    // Localized strings
    String title = lang.currentLanguage == AppLanguage.arabic 
        ? 'المتابعة' 
        : lang.currentLanguage == AppLanguage.kurdish 
            ? 'بەدواداچوون' 
            : 'Tracking';

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
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 120),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _buildSummaryCards(lang, isDark),
                          const SizedBox(height: 24),
                          _buildCalendar(lang, isDark),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: _buildRecordButton(lang, isDark),
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
        ],
      ),
    );
  }

  Widget _buildSummaryCards(LanguageService lang, bool isDark) {
    return Consumer<TrackingService>(
      builder: (context, trackingService, child) {
        // Localized labels
        String successLabel = lang.currentLanguage == AppLanguage.arabic 
            ? 'نجاح' 
            : lang.currentLanguage == AppLanguage.kurdish 
                ? 'سەرکەوتن' 
                : 'Success';
        String slipLabel = lang.currentLanguage == AppLanguage.arabic 
            ? 'زلة' 
            : lang.currentLanguage == AppLanguage.kurdish 
                ? 'زەلە' 
                : 'Slip';
        String relapseLabel = lang.currentLanguage == AppLanguage.arabic 
            ? 'انتكاسة' 
            : lang.currentLanguage == AppLanguage.kurdish 
                ? 'شکست' 
                : 'Relapse';
        String unknownLabel = lang.currentLanguage == AppLanguage.arabic 
            ? 'غائب' 
            : lang.currentLanguage == AppLanguage.kurdish 
                ? 'نادیار' 
                : 'Unknown';

        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                lang, isDark,
                icon: Icons.check_circle_rounded,
                count: trackingService.getSuccessCount(),
                label: successLabel,
                color: successColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryCard(
                lang, isDark,
                icon: Icons.warning_rounded,
                count: trackingService.getSlipCount(),
                label: slipLabel,
                color: slipColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryCard(
                lang, isDark,
                icon: Icons.heart_broken_rounded,
                count: trackingService.getRelapseCount(),
                label: relapseLabel,
                color: relapseColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryCard(
                lang, isDark,
                icon: Icons.help_outline_rounded,
                count: trackingService.getUnknownCount(),
                label: unknownLabel,
                color: unknownColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    LanguageService lang, 
    bool isDark, {
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.15) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: lang.getTextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: lang.getTextStyle(
              fontSize: 11,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(LanguageService lang, bool isDark) {
    return Consumer<TrackingService>(
      builder: (context, trackingService, child) {
        // Month names
        final monthNames = lang.currentLanguage == AppLanguage.arabic
            ? ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']
            : lang.currentLanguage == AppLanguage.kurdish
                ? ['کانوونی دووەم', 'شوبات', 'ئازار', 'نیسان', 'ئایار', 'حوزەیران', 'تەمووز', 'ئاب', 'ئەیلوول', 'تشرینی یەکەم', 'تشرینی دووەم', 'کانوونی یەکەم']
                : ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

        // Day names
        final dayNames = lang.currentLanguage == AppLanguage.arabic
            ? ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س']
            : lang.currentLanguage == AppLanguage.kurdish
                ? ['ی', 'د', 'س', 'چ', 'پ', 'ه', 'ش']
                : ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

        final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
        final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
        final startingWeekday = firstDayOfMonth.weekday % 7;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Month navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                      });
                    },
                    icon: Icon(
                      lang.isRTL ? Icons.chevron_right : Icons.chevron_left,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    '${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                    style: lang.getTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                      });
                    },
                    icon: Icon(
                      lang.isRTL ? Icons.chevron_left : Icons.chevron_right,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Day headers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: dayNames.map((day) => SizedBox(
                  width: 36,
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: lang.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 12),
              // Calendar grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: 42, // 6 weeks max
                itemBuilder: (context, index) {
                  final dayNumber = index - startingWeekday + 1;
                  
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox();
                  }
                  
                  final date = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);
                  final status = trackingService.getDayStatus(date);
                  final isToday = _isToday(date);
                  final isFuture = date.isAfter(DateTime.now());
                  
                  return GestureDetector(
                    onTap: isFuture ? null : () => _showDayStatusDialog(date, status, lang, isDark),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isFuture 
                            ? Colors.transparent
                            : _getStatusColor(status).withOpacity(status == DayStatus.unknown ? 0.1 : 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: isToday 
                            ? Border.all(color: const Color(0xFF667EEA), width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          dayNumber.toString(),
                          style: lang.getTextStyle(
                            fontSize: 14,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isFuture
                                ? (isDark ? Colors.white24 : Colors.black26)
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Legend
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildLegendItem(successColor, lang.currentLanguage == AppLanguage.arabic ? 'نجاح' : lang.currentLanguage == AppLanguage.kurdish ? 'سەرکەوتن' : 'Success', lang, isDark),
                  _buildLegendItem(slipColor, lang.currentLanguage == AppLanguage.arabic ? 'زلة' : lang.currentLanguage == AppLanguage.kurdish ? 'زەلە' : 'Slip', lang, isDark),
                  _buildLegendItem(relapseColor, lang.currentLanguage == AppLanguage.arabic ? 'انتكاسة' : lang.currentLanguage == AppLanguage.kurdish ? 'شکست' : 'Relapse', lang, isDark),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label, LanguageService lang, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: lang.getTextStyle(
            fontSize: 11,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Widget _buildRecordButton(LanguageService lang, bool isDark) {
    return Consumer<TrackingService>(
      builder: (context, trackingService, child) {
        final isRecorded = trackingService.isTodayRecorded();
        
        return FloatingActionButton.extended(
          onPressed: () => _showStatusModal(lang, isDark),
          backgroundColor: isRecorded ? successColor : const Color(0xFF667EEA),
          icon: Icon(
            isRecorded ? Icons.check : Icons.add,
            color: Colors.white,
          ),
          label: Text(
            lang.currentLanguage == AppLanguage.arabic 
                ? (isRecorded ? 'تم التسجيل' : 'سجّل اليوم')
                : lang.currentLanguage == AppLanguage.kurdish 
                    ? (isRecorded ? 'تۆمارکرا' : 'ئەمڕۆ تۆماربکە')
                    : (isRecorded ? 'Recorded' : 'Record Today'),
            style: lang.getTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  void _showStatusModal(LanguageService lang, bool isDark) {
    _showDayStatusDialog(DateTime.now(), DayStatus.unknown, lang, isDark);
  }

  void _showDayStatusDialog(DateTime date, DayStatus currentStatus, LanguageService lang, bool isDark) {
    // Question text
    String questionText = lang.currentLanguage == AppLanguage.arabic 
        ? 'كيف كان يومك؟'
        : lang.currentLanguage == AppLanguage.kurdish 
            ? 'ڕۆژەکەت چۆن بوو؟'
            : 'How was your day?';

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: lang.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF667EEA),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Question
                Text(
                  questionText,
                  style: lang.getTextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                // Status buttons
                _buildStatusButton(
                  lang, isDark, date,
                  status: DayStatus.success,
                  label: lang.currentLanguage == AppLanguage.arabic ? 'نجاح' : lang.currentLanguage == AppLanguage.kurdish ? 'سەرکەوتن' : 'Success',
                  icon: Icons.check_circle_rounded,
                  color: successColor,
                  isSelected: currentStatus == DayStatus.success,
                ),
                const SizedBox(height: 12),
                _buildStatusButton(
                  lang, isDark, date,
                  status: DayStatus.slip,
                  label: lang.currentLanguage == AppLanguage.arabic ? 'زلة' : lang.currentLanguage == AppLanguage.kurdish ? 'زەلە' : 'Slip',
                  icon: Icons.warning_rounded,
                  color: slipColor,
                  isSelected: currentStatus == DayStatus.slip,
                ),
                const SizedBox(height: 12),
                _buildStatusButton(
                  lang, isDark, date,
                  status: DayStatus.relapse,
                  label: lang.currentLanguage == AppLanguage.arabic ? 'انتكاسة' : lang.currentLanguage == AppLanguage.kurdish ? 'شکست' : 'Relapse',
                  icon: Icons.heart_broken_rounded,
                  color: relapseColor,
                  isSelected: currentStatus == DayStatus.relapse,
                ),
                const SizedBox(height: 20),
                // Cancel button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    lang.currentLanguage == AppLanguage.arabic ? 'إلغاء' : lang.currentLanguage == AppLanguage.kurdish ? 'پاشگەزبوونەوە' : 'Cancel',
                    style: lang.getTextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.black45,
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

  Widget _buildStatusButton(
    LanguageService lang,
    bool isDark,
    DateTime date, {
    required DayStatus status,
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        await Provider.of<TrackingService>(context, listen: false)
            .setDayStatus(date, status);
        if (mounted) Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(isSelected ? 1.0 : 0.4),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: lang.getTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
