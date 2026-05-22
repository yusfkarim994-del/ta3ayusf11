import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/assessment_service.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final AssessmentService _assessmentService = AssessmentService();
  int _currentQuestionIndex = 0;
  int _currentPage = 0; // 0 = questions, 1 = result, 2 = history
  AssessmentResult? _result;
  bool _isLoading = true;
  
  // Store answers locally in state
  Map<String, int> _answers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _assessmentService.loadResults();
    setState(() {
      _isLoading = false;
    });
  }

  void _selectAnswer(String questionId, int optionIndex) {
    setState(() {
      _answers[questionId] = optionIndex;
    });
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < AssessmentService.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Future<void> _submitAndShowResult() async {
    // Calculate score directly here
    int totalScore = 0;
    int maxScore = 0;
    
    for (final question in AssessmentService.questions) {
      final maxOptionScore = question.options.map((o) => o.score).reduce((a, b) => a > b ? a : b);
      maxScore += maxOptionScore;
      final selectedIndex = _answers[question.id];
      if (selectedIndex != null && selectedIndex < question.options.length) {
        totalScore += question.options[selectedIndex].score;
      }
    }

    final percentage = maxScore > 0 ? (totalScore / maxScore) * 100 : 0.0;
    int level;
    if (percentage <= 10) {
      level = 1;
    } else if (percentage <= 20) {
      level = 2;
    } else if (percentage <= 35) {
      level = 3;
    } else if (percentage <= 50) {
      level = 4;
    } else if (percentage <= 65) {
      level = 5;
    } else if (percentage <= 80) {
      level = 6;
    } else {
      level = 7;
    }

    final result = AssessmentResult(
      date: DateTime.now(),
      totalScore: totalScore,
      maxScore: maxScore,
      level: level,
      answers: Map.from(_answers),
    );

    // Save result to history
    await _assessmentService.saveResult(result);
    
    // Reload to get updated history
    await _assessmentService.loadResults();

    // Show result immediately
    setState(() {
      _result = result;
      _currentPage = 1; // Go to result page
    });
  }

  void _startNewAssessment() {
    setState(() {
      _answers = {};
      _currentQuestionIndex = 0;
      _result = null;
      _currentPage = 0;
    });
  }

  void _showHistory() {
    setState(() {
      _currentPage = 2;
    });
  }

  void _showQuestions() {
    setState(() {
      _currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = lang.isDarkMode;

    return Directionality(
      textDirection: lang.textDirection,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0a1628) : const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _getTitle(lang),
            style: lang.getTextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          actions: [
            if (_currentPage != 2)
              IconButton(
                icon: Icon(Icons.history, color: isDark ? Colors.white70 : Colors.black54),
                onPressed: _showHistory,
              ),
            if (_currentPage == 2)
              IconButton(
                icon: Icon(Icons.quiz, color: isDark ? Colors.white70 : Colors.black54),
                onPressed: _showQuestions,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _currentPage == 0
                ? _buildQuestionView(lang, isDark)
                : _currentPage == 1
                    ? _buildResultView(lang, isDark)
                    : _buildHistoryView(lang, isDark),
      ),
    );
  }

  Widget _buildQuestionView(LanguageService lang, bool isDark) {
    final questions = AssessmentService.questions;
    final question = questions[_currentQuestionIndex];
    final selectedIndex = _answers[question.id];
    final isLastQuestion = _currentQuestionIndex == questions.length - 1;
    final hasAnswer = selectedIndex != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1a2a4a) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_getQuestionText(lang)} ${_currentQuestionIndex + 1}/${questions.length}',
                      style: lang.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF667eea),
                      ),
                    ),
                    Text(
                      '${((_currentQuestionIndex + 1) / questions.length * 100).toInt()}%',
                      style: lang.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF667eea),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / questions.length,
                    backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Question card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  _getQuestionTextByLanguage(question, lang),
                  style: lang.getTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Options
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = selectedIndex == index;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _selectAnswer(question.id, index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isSelected 
                        ? const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)])
                        : null,
                    color: isSelected ? null : (isDark ? const Color(0xFF1a2a4a) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : (isDark ? Colors.white24 : Colors.grey.shade300),
                      width: 2,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ] : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.2) : (isDark ? Colors.white12 : Colors.grey.shade100),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: lang.getTextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _getOptionTextByLanguage(option, lang),
                          style: lang.getTextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Colors.white, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
          
          const SizedBox(height: 24),
          
          // Navigation buttons
          Row(
            children: [
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _goToPreviousQuestion,
                    icon: Icon(lang.isRTL ? Icons.arrow_forward : Icons.arrow_back),
                    label: Text(_getPreviousText(lang)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              if (_currentQuestionIndex > 0) const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasAnswer 
                      ? (isLastQuestion ? _submitAndShowResult : _goToNextQuestion)
                      : null,
                  icon: Icon(isLastQuestion 
                      ? Icons.check_circle 
                      : (lang.isRTL ? Icons.arrow_back : Icons.arrow_forward)),
                  label: Text(isLastQuestion ? _getSubmitText(lang) : _getNextText(lang)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLastQuestion ? Colors.green : const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark ? Colors.white12 : Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(LanguageService lang, bool isDark) {
    if (_result == null) {
      return Center(
        child: Text(
          'No result available',
          style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black),
        ),
      );
    }
    
    final result = _result!;
    final levelColor = _assessmentService.getLevelColor(result.level);
    final levelIcon = _assessmentService.getLevelIcon(result.level);
    final langCode = lang.currentLanguage == AppLanguage.arabic ? 'ar' 
        : lang.currentLanguage == AppLanguage.kurdish ? 'ku' : 'en';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
      child: Column(
        children: [
          // Level indicator (1-7)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [levelColor, levelColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: levelColor.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(levelIcon, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 20),
                Text(
                  _getYourLevelText(lang),
                  style: lang.getTextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${result.level}',
                      style: lang.getTextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      ' / 7',
                      style: lang.getTextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _assessmentService.getLevelName(result.level, langCode),
                    style: lang.getTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Level scale visualization
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1a2a4a) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getLevelsScaleText(lang),
                  style: lang.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(7, (index) {
                    final level = index + 1;
                    final isCurrentLevel = result.level == level;
                    final lColor = _assessmentService.getLevelColor(level);
                    
                    return Expanded(
                      child: Container(
                        height: isCurrentLevel ? 50 : 40,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: lColor.withOpacity(isCurrentLevel ? 1 : 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: isCurrentLevel ? Border.all(color: Colors.white, width: 3) : null,
                          boxShadow: isCurrentLevel ? [
                            BoxShadow(color: lColor.withOpacity(0.5), blurRadius: 10),
                          ] : null,
                        ),
                        child: Center(
                          child: Text(
                            '$level',
                            style: lang.getTextStyle(
                              fontSize: isCurrentLevel ? 18 : 14,
                              fontWeight: FontWeight.bold,
                              color: isCurrentLevel ? Colors.white : (isDark ? Colors.white54 : Colors.black45),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Level description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1a2a4a) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: levelColor.withOpacity(0.3), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: levelColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.info_outline, color: levelColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getLevelDescriptionTitle(lang),
                      style: lang.getTextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _assessmentService.getLevelDescription(result.level, langCode),
                  style: lang.getTextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recommendation card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                    ? [const Color(0xFF2d3a5a), const Color(0xFF1a2a4a)]
                    : [Colors.blue.shade50, Colors.white],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lightbulb_outline, color: Color(0xFF667eea), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getRecommendationTitle(lang),
                      style: lang.getTextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _assessmentService.getRecommendation(result.level, langCode),
                  style: lang.getTextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                // Motivational message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: Color(0xFF4CAF50), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getMotivationalText(lang),
                          style: lang.getTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home_rounded),
                  label: Text(_getBackToHomeText(lang)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
                    side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startNewAssessment,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(_getRetakeText(lang)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView(LanguageService lang, bool isDark) {
    final results = _assessmentService.results;
    final langCode = lang.currentLanguage == AppLanguage.arabic ? 'ar' 
        : lang.currentLanguage == AppLanguage.kurdish ? 'ku' : 'en';

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 80,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _getNoHistoryText(lang),
              style: lang.getTextStyle(
                fontSize: 18,
                color: isDark ? Colors.white54 : Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startNewAssessment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_getStartFirstAssessmentText(lang)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        final levelColor = _assessmentService.getLevelColor(result.level);
        final levelIcon = _assessmentService.getLevelIcon(result.level);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a2a4a) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: levelColor.withOpacity(0.3), width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [levelColor, levelColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${result.level}',
                      style: lang.getTextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '/7',
                      style: lang.getTextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _assessmentService.getLevelName(result.level, langCode),
                      style: lang.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: levelColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(result.date, lang),
                      style: lang.getTextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                onPressed: () => _showDeleteConfirmation(context, index, lang, isDark),
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 24),
                tooltip: lang.currentLanguage == AppLanguage.arabic ? 'حذف' 
                    : lang.currentLanguage == AppLanguage.kurdish ? 'سڕینەوە' : 'Delete',
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, int index, LanguageService lang, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          lang.currentLanguage == AppLanguage.arabic ? 'تأكيد الحذف'
              : lang.currentLanguage == AppLanguage.kurdish ? 'دڵنیابوونەوە' : 'Confirm Delete',
          style: lang.getTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          lang.currentLanguage == AppLanguage.arabic ? 'هل أنت متأكد من حذف هذا التقييم؟'
              : lang.currentLanguage == AppLanguage.kurdish ? 'دڵنیایت لە سڕینەوەی ئەم هەڵسەنگاندنە؟' 
              : 'Are you sure you want to delete this assessment?',
          style: lang.getTextStyle(
            fontSize: 15,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              lang.currentLanguage == AppLanguage.arabic ? 'إلغاء'
                  : lang.currentLanguage == AppLanguage.kurdish ? 'پاشگەزبوونەوە' : 'Cancel',
              style: lang.getTextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _assessmentService.deleteResult(index);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              lang.currentLanguage == AppLanguage.arabic ? 'حذف'
                  : lang.currentLanguage == AppLanguage.kurdish ? 'سڕینەوە' : 'Delete',
              style: lang.getTextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for translations
  String _getTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'اعرف مستواك الإدماني';
      case AppLanguage.kurdish: return 'مستوای ئیدمانت بزانە';
      case AppLanguage.english: return 'Know Your Addiction Level';
    }
  }

  String _getQuestionText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'السؤال';
      case AppLanguage.kurdish: return 'پرسیار';
      case AppLanguage.english: return 'Question';
    }
  }

  String _getQuestionTextByLanguage(AssessmentQuestion question, LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return question.textAr;
      case AppLanguage.kurdish: return question.textKu;
      case AppLanguage.english: return question.textEn;
    }
  }

  String _getOptionTextByLanguage(AssessmentOption option, LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return option.textAr;
      case AppLanguage.kurdish: return option.textKu;
      case AppLanguage.english: return option.textEn;
    }
  }

  String _getNextText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'التالي';
      case AppLanguage.kurdish: return 'دواتر';
      case AppLanguage.english: return 'Next';
    }
  }

  String _getPreviousText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'السابق';
      case AppLanguage.kurdish: return 'پێشتر';
      case AppLanguage.english: return 'Previous';
    }
  }

  String _getSubmitText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'اعرف مستواي';
      case AppLanguage.kurdish: return 'ئاستەکەم بزانە';
      case AppLanguage.english: return 'Show My Level';
    }
  }

  String _getYourLevelText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'مستواك الإدماني';
      case AppLanguage.kurdish: return 'ئاستی ئیدمانیت';
      case AppLanguage.english: return 'Your Addiction Level';
    }
  }

  String _getLevelsScaleText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'مقياس المستويات السبعة';
      case AppLanguage.kurdish: return 'پێوەری حەوت ئاست';
      case AppLanguage.english: return '7-Level Scale';
    }
  }

  String _getLevelDescriptionTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'وصف مستواك';
      case AppLanguage.kurdish: return 'وەسفی ئاستەکەت';
      case AppLanguage.english: return 'Level Description';
    }
  }

  String _getRecommendationTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'التوصية';
      case AppLanguage.kurdish: return 'ڕاسپاردە';
      case AppLanguage.english: return 'Recommendation';
    }
  }

  String _getMotivationalText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'التعافي ممكن وليس مستحيلاً. مهما كان مستواك، النتائج تستحق!';
      case AppLanguage.kurdish: return 'چاکبوونەوە دەکرێت و نەمانە نییە. هەرچەندە ئاستەکەت چی بێت، ئەنجامەکان شایستەن!';
      case AppLanguage.english: return 'Recovery is possible, not impossible. Whatever your level, the results are worth it!';
    }
  }

  String _getBackToHomeText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'الرئيسية';
      case AppLanguage.kurdish: return 'ماڵەوە';
      case AppLanguage.english: return 'Home';
    }
  }

  String _getRetakeText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إعادة التقييم';
      case AppLanguage.kurdish: return 'دووبارەکردنەوە';
      case AppLanguage.english: return 'Retake';
    }
  }

  String _getNoHistoryText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'لا يوجد سجل تقييمات';
      case AppLanguage.kurdish: return 'هیچ هەڵسەنگاندنێک نییە';
      case AppLanguage.english: return 'No assessment history';
    }
  }

  String _getStartFirstAssessmentText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'ابدأ أول تقييم';
      case AppLanguage.kurdish: return 'یەکەم هەڵسەنگاندن دەستپێبکە';
      case AppLanguage.english: return 'Start First Assessment';
    }
  }

  String _formatDate(DateTime date, LanguageService lang) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year - $hour:$minute';
  }
}
