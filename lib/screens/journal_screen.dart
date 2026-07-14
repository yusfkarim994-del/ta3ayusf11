import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../services/journal_service.dart';
import '../services/language_service.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _contentController = TextEditingController();
  JournalMood _selectedMood = JournalMood.neutral;
  bool _isWriting = false;
  String? _editingId;

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
      Provider.of<JournalService>(context, listen: false).loadEntries();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _startWriting() {
    setState(() {
      _isWriting = true;
      _editingId = null;
      _contentController.clear();
      _selectedMood = JournalMood.neutral;
    });
  }

  void _startEditing(JournalEntry entry) {
    setState(() {
      _isWriting = true;
      _editingId = entry.id;
      _contentController.text = entry.content;
      _selectedMood = entry.mood;
    });
  }

  void _cancelWriting() {
    setState(() {
      _isWriting = false;
      _editingId = null;
      _contentController.clear();
    });
  }

  Future<void> _saveEntry() async {
    if (_contentController.text.trim().isEmpty) return;

    final journalService = Provider.of<JournalService>(context, listen: false);

    if (_editingId != null) {
      await journalService.updateEntry(
          _editingId!, _contentController.text.trim(), _selectedMood);
    } else {
      await journalService.addEntry(
          _contentController.text.trim(), _selectedMood);
    }

    _cancelWriting();
  }

  Future<void> _deleteEntry(String id) async {
    final journalService = Provider.of<JournalService>(context, listen: false);
    await journalService.deleteEntry(id);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = lang.isDarkMode;

    String title,
        writeHint,
        saveText,
        cancelText,
        noEntriesText,
        deleteConfirmText,
        todayText;

    switch (lang.currentLanguage) {
      case AppLanguage.arabic:
        title = 'يومياتي';
        writeHint = 'اكتب مشاعرك وأفكارك هنا...';
        saveText = 'حفظ';
        cancelText = 'إلغاء';
        noEntriesText = 'لم تكتب أي يوميات بعد\nابدأ بكتابة مشاعرك اليوم';
        deleteConfirmText = 'هل أنت متأكد من الحذف؟';
        todayText = 'اليوم';
        break;
      case AppLanguage.kurdish:
        title = 'ڕۆژنامەکەم';
        writeHint = 'هەستەکان و بیرکردنەوەکانت لێرە بنووسە...';
        saveText = 'پاشەکەوتکردن';
        cancelText = 'پاشگەزبوونەوە';
        noEntriesText =
            'هێشتا هیچ ڕۆژنامەیەکت نەنووسیوە\nئەمڕۆ دەستبکە بە نووسینی هەستەکانت';
        deleteConfirmText = 'دڵنیایت لە سڕینەوە؟';
        todayText = 'ئەمڕۆ';
        break;
      case AppLanguage.english:
        title = 'My Journal';
        writeHint = 'Write your feelings and thoughts here...';
        saveText = 'Save';
        cancelText = 'Cancel';
        noEntriesText =
            'You haven\'t written any journal entries yet\nStart writing your feelings today';
        deleteConfirmText = 'Are you sure you want to delete?';
        todayText = 'Today';
        break;
    }

    final languageCode = lang.currentLanguage == AppLanguage.arabic
        ? 'arabic'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'kurdish'
            : 'english';

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
                      const Color(0xFF071A22),
                      const Color(0xFF0E232D),
                      const Color(0xFF081216),
                    ]
                  : [
                      const Color(0xFFF8FDF9),
                      const Color(0xFFF1F9F6),
                      const Color(0xFFF5FAFE),
                    ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(lang, isDark, title),
                  if (!_isWriting) _buildJournalHero(lang, isDark, todayText),
                  Expanded(
                    child: _isWriting
                        ? _buildWritingView(lang, isDark, writeHint, saveText,
                            cancelText, languageCode)
                        : _buildJournalList(lang, isDark, noEntriesText,
                            languageCode, deleteConfirmText),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: !_isWriting ? _buildFAB(lang, isDark) : null,
      ),
    );
  }

  Widget _buildHeader(LanguageService lang, bool isDark, String title) {
    final subtitle = lang.currentLanguage == AppLanguage.arabic
        ? 'مساحة هادئة لتفريغ قلبك كل يوم'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'شوێنێکی ئارام بۆ نووسینی هەستەکانت'
            : 'A calm space for your thoughts';

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
            onTap: () => _showMoodStats(lang, isDark),
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
              child: Icon(
                Icons.insights_rounded,
                color: const Color(0xFF059669),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalHero(
      LanguageService lang, bool isDark, String todayText) {
    return Consumer<JournalService>(
      builder: (context, journalService, child) {
        final entries = journalService.sortedEntries;
        final total = entries.length;
        final latestMood =
            entries.isNotEmpty ? entries.first.mood : JournalMood.neutral;
        final heroTitle = lang.currentLanguage == AppLanguage.arabic
            ? 'اكتب لتفهم نفسك لا لتحاكمها'
            : lang.currentLanguage == AppLanguage.kurdish
                ? 'بنووسە بۆ تێگەیشتن لە خۆت، نەک دادگاییکردن'
                : 'Write to understand yourself';
        final heroSubtitle = total == 0
            ? (lang.currentLanguage == AppLanguage.arabic
                ? 'ابدأ بأول سطر اليوم'
                : lang.currentLanguage == AppLanguage.kurdish
                    ? 'ئەمڕۆ بە یەکەم دێڕ دەست پێبکە'
                    : 'Start with one line today')
            : (lang.currentLanguage == AppLanguage.arabic
                ? '$total يومية محفوظة'
                : lang.currentLanguage == AppLanguage.kurdish
                    ? '$total ڕۆژنامە پاشەکەوتکراوە'
                    : '$total saved entries');

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 4, 20, 14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF0F766E).withOpacity(0.85), const Color(0xFF1E293B)]
                  : [
                      const Color(0xFF059669),
                      const Color(0xFF10B981),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withOpacity(0.3),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Center(
                  child: Text(latestMood.emoji,
                      style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todayText.toUpperCase(),
                      style: lang.getTextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.65),
                      ).copyWith(letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      heroTitle,
                      style: lang.getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      heroSubtitle,
                      style: lang.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFAB(LanguageService lang, bool isDark) {
    final label = lang.currentLanguage == AppLanguage.arabic
        ? 'اكتب'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'بنووسە'
            : 'Write';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _startWriting,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
        label: Text(
          label,
          style: lang.getTextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildWritingView(LanguageService lang, bool isDark, String writeHint,
      String saveText, String cancelText, String languageCode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMoodSelector(lang, isDark, languageCode),
          const SizedBox(height: 24),
          // Writing area
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: _selectedMood.color.withOpacity(isDark ? 0.25 : 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _selectedMood.color.withOpacity(isDark ? 0.08 : 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Stack(
                children: [
                  Positioned(
                    top: 16,
                    right: lang.isRTL ? null : 18,
                    left: lang.isRTL ? 18 : null,
                    child: Icon(
                      Icons.format_quote_rounded,
                      size: 40,
                      color: _selectedMood.color.withOpacity(0.1),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      minLines: 12,
                      style: lang.getTextStyle(
                        fontSize: 16,
                        height: 1.85,
                        color:
                            isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0D1B21).withOpacity(0.6)
                            : const Color(0xFFF8FAFC),
                        hintText: writeHint,
                        hintStyle: lang.getTextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.white30
                              : const Color(0xFF94A3B8),
                        ),
                        contentPadding: const EdgeInsets.all(18),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _cancelWriting,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cancelText,
                        style: lang.getTextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _saveEntry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _selectedMood.color,
                          _selectedMood.color.withOpacity(0.75),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: _selectedMood.color.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_rounded,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          saveText,
                          style: lang.getTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector(
      LanguageService lang, bool isDark, String languageCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.currentLanguage == AppLanguage.arabic
              ? 'كيف تشعر الآن؟'
              : lang.currentLanguage == AppLanguage.kurdish
                  ? 'ئێستا چۆن هەستت پێ دەکەیت؟'
                  : 'How are you feeling?',
          style: lang.getTextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF064E3B),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: JournalMood.values.length,
            itemBuilder: (context, index) {
              final mood = JournalMood.values[index];
              final isSelected = mood == _selectedMood;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = mood),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(right: 10),
                  width: isSelected ? 82 : 72,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              mood.color.withOpacity(0.2),
                              mood.color.withOpacity(0.08),
                            ],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected
                          ? mood.color
                          : (isDark
                              ? Colors.white.withOpacity(0.08)
                              : const Color(0xFFE2E8F0)),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: mood.color.withOpacity(0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        mood.emoji,
                        style: TextStyle(
                          fontSize: isSelected ? 30 : 26,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        mood.getName(languageCode),
                        style: lang.getTextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? mood.color
                              : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildJournalList(LanguageService lang, bool isDark,
      String noEntriesText, String languageCode, String deleteConfirmText) {
    return Consumer<JournalService>(
      builder: (context, journalService, child) {
        final entries = journalService.sortedEntries;

        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.03),
                            ]
                          : [
                              Colors.white,
                              const Color(0xFFECFDF5),
                            ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withOpacity(0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 56,
                    color: isDark
                        ? Colors.white30
                        : const Color(0xFF059669),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  noEntriesText,
                  textAlign: TextAlign.center,
                  style: lang.getTextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF94A3B8),
                    height: 1.7,
                  ),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 3 : 2;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildReflectionPrompt(lang, isDark),
                        _buildLibraryShelfHeader(lang, isDark, entries.length),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = entries[index];
                        return _buildJournalCard(lang, isDark, entry,
                            languageCode, deleteConfirmText, journalService);
                      },
                      childCount: entries.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      childAspectRatio: columns == 3 ? 0.82 : 0.72,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLibraryShelfHeader(
      LanguageService lang, bool isDark, int entriesCount) {
    final title = lang.currentLanguage == AppLanguage.arabic
        ? 'مكتبتي الخاصة'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'کتێبخانەی تایبەتیم'
            : 'My Private Library';
    final subtitle = lang.currentLanguage == AppLanguage.arabic
        ? '$entriesCount ملاحظة محفوظة ككتب صغيرة'
        : lang.currentLanguage == AppLanguage.kurdish
            ? '$entriesCount نووسراوە وەک کتێبی بچووک پارێزراوە'
            : '$entriesCount notes saved as small books';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : const Color(0xFFD1FAE5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(isDark ? 0.06 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF059669), Color(0xFF10B981)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_library_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: lang.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF064E3B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: lang.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReflectionPrompt(LanguageService lang, bool isDark) {
    final text = lang.currentLanguage == AppLanguage.arabic
        ? 'سؤال اليوم: ما الشيء الصغير الذي ساعدك على الثبات؟'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'پرسیاری ئەمڕۆ: کام شتی بچووک یارمەتیدایت بۆ پابەندبوون؟'
            : 'Today: what small thing helped you stay steady?';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : const Color(0xFFD1FAE5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF0EA5E9).withOpacity(0.2),
                        const Color(0xFF0EA5E9).withOpacity(0.08),
                      ]
                    : [
                        const Color(0xFF0EA5E9).withOpacity(0.12),
                        const Color(0xFF0EA5E9).withOpacity(0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Color(0xFF0EA5E9),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: lang.getTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF0F766E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalCard(
      LanguageService lang,
      bool isDark,
      JournalEntry entry,
      String languageCode,
      String deleteConfirmText,
      JournalService journalService) {
    return GestureDetector(
      onTap: () =>
          _showFullEntry(lang, isDark, entry, languageCode, journalService),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF102028) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? entry.mood.color.withOpacity(0.15)
                : entry.mood.color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: entry.mood.color.withOpacity(isDark ? 0.08 : 0.06),
              blurRadius: 20,
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
                        entry.mood.color,
                        entry.mood.color.withOpacity(0.4),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                entry.mood.color.withOpacity(0.18),
                                entry.mood.color.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(entry.mood.emoji,
                                style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.more_horiz_rounded,
                              size: 18,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded,
                                      size: 18,
                                      color: isDark ? Colors.white70 : Colors.black54),
                                  const SizedBox(width: 10),
                                  Text(
                                    lang.currentLanguage == AppLanguage.arabic
                                        ? 'تعديل'
                                        : lang.currentLanguage ==
                                                AppLanguage.kurdish
                                            ? 'دەستکاری'
                                            : 'Edit',
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_rounded,
                                      size: 18, color: Colors.red),
                                  const SizedBox(width: 10),
                                  Text(
                                    lang.currentLanguage == AppLanguage.arabic
                                        ? 'حذف'
                                        : lang.currentLanguage ==
                                                AppLanguage.kurdish
                                            ? 'سڕینەوە'
                                            : 'Delete',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _startEditing(entry);
                            } else if (value == 'delete') {
                              _showDeleteConfirmation(
                                  entry.id, deleteConfirmText, lang, isDark);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      journalService.formatDate(entry.createdAt, languageCode),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: lang.getTextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: entry.mood.color.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.mood.getName(languageCode),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: lang.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Text(
                        entry.content,
                        maxLines: 7,
                        overflow: TextOverflow.ellipsis,
                        style: lang.getTextStyle(
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withOpacity(0.75)
                              : const Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: entry.mood.color.withOpacity(0.7),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            lang.currentLanguage == AppLanguage.arabic
                                ? 'افتح اليومية'
                                : lang.currentLanguage == AppLanguage.kurdish
                                    ? 'ڕۆژنامەکە بکەرەوە'
                                    : 'Open entry',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: lang.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: entry.mood.color.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullEntry(LanguageService lang, bool isDark, JournalEntry entry,
      String languageCode, JournalService journalService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.58,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF071A22), const Color(0xFF0E232D)]
                  : [Colors.white, const Color(0xFFF0FDF9)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              // Header card
              Container(
                margin: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      entry.mood.color,
                      entry.mood.color.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: entry.mood.color.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(entry.mood.emoji,
                            style: const TextStyle(fontSize: 30)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.mood.getName(languageCode),
                            style: lang.getTextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${journalService.formatDate(entry.createdAt, languageCode)} • ${journalService.formatTime(entry.createdAt)}',
                            style: lang.getTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.07)
                            : const Color(0xFFD1FAE5),
                      ),
                    ),
                    child: Text(
                      entry.content,
                      style: lang.getTextStyle(
                        fontSize: 17,
                        height: 1.9,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withOpacity(0.88)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
      String id, String confirmText, LanguageService lang, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF102028) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          confirmText,
          style: lang.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              lang.currentLanguage == AppLanguage.arabic
                  ? 'إلغاء'
                  : lang.currentLanguage == AppLanguage.kurdish
                      ? 'پاشگەزبوونەوە'
                      : 'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteEntry(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              lang.currentLanguage == AppLanguage.arabic
                  ? 'حذف'
                  : lang.currentLanguage == AppLanguage.kurdish
                      ? 'سڕینەوە'
                      : 'Delete',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoodStats(LanguageService lang, bool isDark) {
    final journalService = Provider.of<JournalService>(context, listen: false);
    final stats = journalService.getMoodStats();
    final totalEntries = stats.values.fold(0, (sum, count) => sum + count);
    final languageCode = lang.currentLanguage == AppLanguage.arabic
        ? 'arabic'
        : lang.currentLanguage == AppLanguage.kurdish
            ? 'kurdish'
            : 'english';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF102028), const Color(0xFF0E1F28)]
                : [Colors.white, const Color(0xFFF0FDF9)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.insights_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  lang.currentLanguage == AppLanguage.arabic
                      ? 'إحصائيات المشاعر'
                      : lang.currentLanguage == AppLanguage.kurdish
                          ? 'ئامارەکانی هەست'
                          : 'Mood Statistics',
                  style: lang.getTextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              lang.currentLanguage == AppLanguage.arabic
                  ? 'مجموع: $totalEntries يومية'
                  : lang.currentLanguage == AppLanguage.kurdish
                      ? 'کۆی گشتی: $totalEntries ڕۆژنامە'
                      : 'Total: $totalEntries entries',
              style: lang.getTextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            const SizedBox(height: 24),
            if (stats.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.sentiment_neutral_rounded,
                      size: 60,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      lang.currentLanguage == AppLanguage.arabic
                          ? 'لا توجد بيانات بعد'
                          : lang.currentLanguage == AppLanguage.kurdish
                              ? 'هێشتا داتا نییە'
                              : 'No data yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: JournalMood.values.map((mood) {
                      final count = stats[mood] ?? 0;
                      final percentage =
                          totalEntries > 0 ? (count / totalEntries) : 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: count > 0
                                ? mood.color.withOpacity(0.25)
                                : (isDark
                                    ? Colors.white.withOpacity(0.06)
                                    : const Color(0xFFE2E8F0)),
                          ),
                          boxShadow: count > 0
                              ? [
                                  BoxShadow(
                                    color: mood.color.withOpacity(0.08),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    mood.color.withOpacity(0.18),
                                    mood.color.withOpacity(0.06),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(mood.emoji,
                                  style: const TextStyle(fontSize: 26)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        mood.getName(languageCode),
                                        style: lang.getTextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: count > 0
                                              ? (isDark
                                                  ? Colors.white
                                                  : Colors.black87)
                                              : (isDark
                                                  ? Colors.white38
                                                  : Colors.black26),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: mood.color.withOpacity(
                                              count > 0 ? 0.18 : 0.08),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$count',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: count > 0
                                                ? mood.color
                                                : (isDark
                                                    ? Colors.white24
                                                    : Colors.black26),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: percentage,
                                      backgroundColor: isDark
                                          ? Colors.white.withOpacity(0.08)
                                          : const Color(0xFFE2E8F0),
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        count > 0
                                            ? mood.color
                                            : Colors.grey.withOpacity(0.3),
                                      ),
                                      minHeight: 7,
                                    ),
                                  ),
                                  if (count > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(percentage * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white38
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
