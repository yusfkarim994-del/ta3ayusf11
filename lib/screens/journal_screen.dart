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

    // Load journal entries
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

    // Localized strings
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF071A22),
                      const Color(0xFF102B35),
                      const Color(0xFF081216)
                    ]
                  : [
                      const Color(0xFFFFFBF4),
                      const Color(0xFFF2FFFC),
                      const Color(0xFFEAF5FF)
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withOpacity(0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                lang.isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : Colors.black87,
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
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF172A2F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: lang.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF607478),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.10) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => _showMoodStats(lang, isDark),
              icon: const Icon(Icons.insights_rounded, color: Colors.teal),
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
        final title = lang.currentLanguage == AppLanguage.arabic
            ? 'اكتب لتفهم نفسك لا لتحاكمها'
            : lang.currentLanguage == AppLanguage.kurdish
                ? 'بنووسە بۆ تێگەیشتن لە خۆت، نەک دادگاییکردن'
                : 'Write to understand yourself';
        final subtitle = total == 0
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
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF0F766E), const Color(0xFF1E293B)]
                  : [const Color(0xFF0D9488), const Color(0xFF38BDF8)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D9488).withOpacity(0.25),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.24)),
                ),
                child: Center(
                    child: Text(latestMood.emoji,
                        style: const TextStyle(fontSize: 34))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todayText,
                      style: lang.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: lang.getTextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: lang.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.78),
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
          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _startWriting,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: Text(
          label,
          style: lang.getTextStyle(
              color: Colors.white, fontWeight: FontWeight.w800),
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
          // Mood selector
          _buildMoodSelector(lang, isDark, languageCode),
          const SizedBox(height: 24),
          // Writing area
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _selectedMood.color.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _selectedMood.color.withOpacity(0.1),
                  blurRadius: 34,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 340),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 18,
                        right: lang.isRTL ? null : 18,
                        left: lang.isRTL ? 18 : null,
                        child: Icon(Icons.format_quote_rounded,
                            size: 44,
                            color: _selectedMood.color.withOpacity(0.14)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: TextField(
                          controller: _contentController,
                          maxLines: null,
                          minLines: 12,
                          style: lang.getTextStyle(
                            fontSize: 16,
                            height: 1.9,
                            color:
                                isDark ? Colors.white : const Color(0xFF263238),
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF122129).withOpacity(0.70)
                                : const Color(0xFFF8FAFC),
                            hintText: writeHint,
                            hintStyle: lang.getTextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white38
                                  : const Color(0xFF78909C),
                            ),
                            contentPadding: const EdgeInsets.all(20),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _cancelWriting,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    cancelText,
                    style: lang.getTextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        _selectedMood.color,
                        _selectedMood.color.withOpacity(0.7)
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _selectedMood.color.withOpacity(0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _saveEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_rounded, color: Colors.white),
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
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF172A2F),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: JournalMood.values.length,
            itemBuilder: (context, index) {
              final mood = JournalMood.values[index];
              final isSelected = mood == _selectedMood;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = mood),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(colors: [
                            mood.color.withOpacity(0.24),
                            mood.color.withOpacity(0.08)
                          ])
                        : null,
                    color: isSelected
                        ? null
                        : isDark
                            ? Colors.white.withOpacity(0.07)
                            : Colors.white.withOpacity(0.94),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? mood.color
                          : (isDark ? Colors.white10 : const Color(0xFFE0F2EF)),
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: mood.color.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        mood.emoji,
                        style: TextStyle(fontSize: isSelected ? 32 : 28),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mood.getName(languageCode),
                        style: lang.getTextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w900 : FontWeight.w700,
                          color: isSelected
                              ? mood.color
                              : (isDark ? Colors.white60 : Colors.black54),
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
                  padding: const EdgeInsets.all(34),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Colors.white.withOpacity(0.11),
                              Colors.white.withOpacity(0.03)
                            ]
                          : [Colors.white, const Color(0xFFE0F7FA)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withOpacity(0.16),
                        blurRadius: 34,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 60,
                    color: isDark ? Colors.white38 : const Color(0xFF0D9488),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  noEntriesText,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.07)
            : Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE0F2EF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withOpacity(isDark ? 0.08 : 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF38BDF8)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.local_library_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: lang.getTextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF172A2F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: lang.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white60 : const Color(0xFF607478),
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
            ? Colors.white.withOpacity(0.07)
            : Colors.white.withOpacity(0.92),
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
              color: const Color(0xFF38BDF8).withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child:
                const Icon(Icons.lightbulb_rounded, color: Color(0xFF0284C7)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: lang.getTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : const Color(0xFF31524D),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    entry.mood.color.withOpacity(0.18),
                    Colors.white.withOpacity(0.06)
                  ]
                : [Colors.white, entry.mood.color.withOpacity(0.10)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: entry.mood.color.withOpacity(0.28),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: entry.mood.color.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: entry.mood.color.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(entry.mood.emoji,
                              style: const TextStyle(fontSize: 23)),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 8,
                        height: 52,
                        decoration: BoxDecoration(
                          color: entry.mood.color,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    journalService.formatDate(entry.createdAt, languageCode),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: lang.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: entry.mood.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.mood.getName(languageCode),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: lang.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white70 : const Color(0xFF526D68),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Text(
                      entry.content,
                      maxLines: 7,
                      overflow: TextOverflow.ellipsis,
                      style: lang.getTextStyle(
                        fontSize: 13,
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withOpacity(0.84)
                            : const Color(0xFF263238),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.menu_book_rounded,
                          size: 16, color: entry.mood.color),
                      const SizedBox(width: 6),
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
                            fontWeight: FontWeight.w900,
                            color: entry.mood.color,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(lang.currentLanguage == AppLanguage.arabic
                                    ? 'تعديل'
                                    : lang.currentLanguage ==
                                            AppLanguage.kurdish
                                        ? 'دەستکاری'
                                        : 'Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_rounded,
                                    size: 20, color: Colors.red),
                                const SizedBox(width: 8),
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
                ],
              ),
            ),
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF071A22), const Color(0xFF102B35)]
                  : [Colors.white, const Color(0xFFF2FFFC)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      entry.mood.color,
                      entry.mood.color.withOpacity(0.68)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: entry.mood.color.withOpacity(0.24),
                      blurRadius: 26,
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
                        color: Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(22),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: Center(
                          child: Text(entry.mood.emoji,
                              style: const TextStyle(fontSize: 32))),
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
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${journalService.formatDate(entry.createdAt, languageCode)} • ${journalService.formatTime(entry.createdAt)}',
                            style: lang.getTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon:
                          const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.07)
                          : Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFFE0F2EF)),
                    ),
                    child: Text(
                      entry.content,
                      style: lang.getTextStyle(
                        fontSize: 17,
                        height: 1.95,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withOpacity(0.9)
                            : const Color(0xFF263238),
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
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteEntry(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [Colors.white, const Color(0xFFF8F9FF)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header with icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withOpacity(0.3),
                        blurRadius: 15,
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

            // Total entries count
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
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, top: 16, bottom: 120),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: count > 0
                                ? mood.color.withOpacity(0.3)
                                : Colors.transparent,
                            width: 1,
                          ),
                          boxShadow: count > 0
                              ? [
                                  BoxShadow(
                                    color: mood.color.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            // Emoji icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: mood.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                mood.emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Name and progress bar
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
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
                                              count > 0 ? 0.2 : 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$count',
                                          style: TextStyle(
                                            fontSize: 14,
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
                                  // Progress bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: percentage,
                                      backgroundColor: isDark
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.2),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        count > 0
                                            ? mood.color
                                            : Colors.grey.withOpacity(0.3),
                                      ),
                                      minHeight: 8,
                                    ),
                                  ),
                                  if (count > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(percentage * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black38,
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
