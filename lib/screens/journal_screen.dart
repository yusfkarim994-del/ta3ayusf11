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

class _JournalScreenState extends State<JournalScreen> with TickerProviderStateMixin {
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
      await journalService.updateEntry(_editingId!, _contentController.text.trim(), _selectedMood);
    } else {
      await journalService.addEntry(_contentController.text.trim(), _selectedMood);
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
    String title, writeHint, saveText, cancelText, noEntriesText, deleteConfirmText, todayText;
    
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
        noEntriesText = 'هێشتا هیچ ڕۆژنامەیەکت نەنووسیوە\nئەمڕۆ دەستبکە بە نووسینی هەستەکانت';
        deleteConfirmText = 'دڵنیایت لە سڕینەوە؟';
        todayText = 'ئەمڕۆ';
        break;
      case AppLanguage.english:
        title = 'My Journal';
        writeHint = 'Write your feelings and thoughts here...';
        saveText = 'Save';
        cancelText = 'Cancel';
        noEntriesText = 'You haven\'t written any journal entries yet\nStart writing your feelings today';
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
                  ? [const Color(0xFF1A1A2E), const Color(0xFF16213E), const Color(0xFF0F0F23)]
                  : [const Color(0xFFF8F9FF), const Color(0xFFE8ECFF), const Color(0xFFD4DBFF)],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(lang, isDark, title),
                  Expanded(
                    child: _isWriting
                        ? _buildWritingView(lang, isDark, writeHint, saveText, cancelText, languageCode)
                        : _buildJournalList(lang, isDark, noEntriesText, languageCode, deleteConfirmText),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: !_isWriting ? _buildFAB(isDark) : null,
      ),
    );
  }

  Widget _buildHeader(LanguageService lang, bool isDark, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
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
          // Title with gradient
          Expanded(
            child: Text(
              title,
              style: lang.getTextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF2D3436),
              ),
            ),
          ),
          // Mood stats button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withOpacity(0.2),
                  Colors.blue.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _showMoodStats(lang, isDark),
              icon: const Icon(Icons.insights_rounded, color: Colors.purple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
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
        label: const Text('', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildWritingView(LanguageService lang, bool isDark, String writeHint, String saveText, String cancelText, String languageCode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mood selector
          _buildMoodSelector(lang, isDark, languageCode),
          const SizedBox(height: 24),
          // Writing area
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _selectedMood.color.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _selectedMood.color.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  constraints: const BoxConstraints(minHeight: 300),
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    minLines: 10,
                    style: lang.getTextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: writeHint,
                      hintStyle: lang.getTextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      border: InputBorder.none,
                    ),
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
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [_selectedMood.color, _selectedMood.color.withOpacity(0.7)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _selectedMood.color.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
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
                        borderRadius: BorderRadius.circular(16),
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

  Widget _buildMoodSelector(LanguageService lang, bool isDark, String languageCode) {
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
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? mood.color.withOpacity(0.2) 
                        : isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? mood.color : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: mood.color.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ] : null,
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
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? mood.color : (isDark ? Colors.white60 : Colors.black54),
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

  Widget _buildJournalList(LanguageService lang, bool isDark, String noEntriesText, String languageCode, String deleteConfirmText) {
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
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.book_outlined,
                    size: 60,
                    color: isDark ? Colors.white24 : Colors.black26,
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

        return ListView.builder(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _buildJournalCard(lang, isDark, entry, languageCode, deleteConfirmText, journalService);
          },
        );
      },
    );
  }

  Widget _buildJournalCard(LanguageService lang, bool isDark, JournalEntry entry, String languageCode, String deleteConfirmText, JournalService journalService) {
    return GestureDetector(
      onTap: () => _showFullEntry(lang, isDark, entry, languageCode, journalService),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: entry.mood.color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: entry.mood.color.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with mood and date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: entry.mood.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(entry.mood.emoji, style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.mood.getName(languageCode),
                              style: lang.getTextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: entry.mood.color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${journalService.formatDate(entry.createdAt, languageCode)} • ${journalService.formatTime(entry.createdAt)}',
                              style: lang.getTextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action buttons
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(lang.currentLanguage == AppLanguage.arabic ? 'تعديل' : lang.currentLanguage == AppLanguage.kurdish ? 'دەستکاری' : 'Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(
                                  lang.currentLanguage == AppLanguage.arabic ? 'حذف' : lang.currentLanguage == AppLanguage.kurdish ? 'سڕینەوە' : 'Delete',
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
                            _showDeleteConfirmation(entry.id, deleteConfirmText, lang, isDark);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Content - Preview
                  Text(
                    entry.content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: lang.getTextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: isDark ? Colors.white.withOpacity(0.8) : Colors.black87,
                    ),
                  ),
                  // Show "Read more" if content is long
                  if (entry.content.length > 150 || entry.content.split('\n').length > 4)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        lang.currentLanguage == AppLanguage.arabic 
                            ? 'اضغط للمزيد...' 
                            : lang.currentLanguage == AppLanguage.kurdish 
                                ? 'کلیک بکە بۆ زیاتر...' 
                                : 'Tap for more...',
                        style: lang.getTextStyle(
                          fontSize: 12,
                          color: entry.mood.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _showFullEntry(LanguageService lang, bool isDark, JournalEntry entry, String languageCode, JournalService journalService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
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
                        color: entry.mood.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(entry.mood.emoji, style: const TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.mood.getName(languageCode),
                            style: lang.getTextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: entry.mood.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${journalService.formatDate(entry.createdAt, languageCode)} • ${journalService.formatTime(entry.createdAt)}',
                            style: lang.getTextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              
              Divider(color: isDark ? Colors.white12 : Colors.grey[200], height: 1),
              
              // Full Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
                  child: Text(
                    entry.content,
                    style: lang.getTextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
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

  void _showDeleteConfirmation(String id, String confirmText, LanguageService lang, bool isDark) {
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
              lang.currentLanguage == AppLanguage.arabic ? 'إلغاء' : lang.currentLanguage == AppLanguage.kurdish ? 'پاشگەزبوونەوە' : 'Cancel',
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              lang.currentLanguage == AppLanguage.arabic ? 'حذف' : lang.currentLanguage == AppLanguage.kurdish ? 'سڕینەوە' : 'Delete',
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
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.insights_rounded, color: Colors.white, size: 24),
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
                      final percentage = totalEntries > 0 ? (count / totalEntries) : 0.0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
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
                          boxShadow: count > 0 ? [
                            BoxShadow(
                              color: mood.color.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ] : null,
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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        mood.getName(languageCode),
                                        style: lang.getTextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: count > 0 
                                              ? (isDark ? Colors.white : Colors.black87)
                                              : (isDark ? Colors.white38 : Colors.black26),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: mood.color.withOpacity(count > 0 ? 0.2 : 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$count',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: count > 0 
                                                ? mood.color 
                                                : (isDark ? Colors.white24 : Colors.black26),
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
                                        count > 0 ? mood.color : Colors.grey.withOpacity(0.3),
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
                                        color: isDark ? Colors.white38 : Colors.black38,
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
