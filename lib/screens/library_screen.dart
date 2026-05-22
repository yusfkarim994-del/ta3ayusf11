import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/library_service.dart';
import '../services/language_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'pdf_reader_screen.dart';
import 'components/book_card_item.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedCategory = 'all';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

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
      Provider.of<LibraryService>(context, listen: false).loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
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
        ? 'المكتبة' 
        : lang.currentLanguage == AppLanguage.kurdish 
            ? 'کتێبخانە' 
            : 'Library';
    String allText = lang.currentLanguage == AppLanguage.arabic 
        ? 'الكل' 
        : lang.currentLanguage == AppLanguage.kurdish 
            ? 'هەموو' 
            : 'All';
    String noBooksText = lang.currentLanguage == AppLanguage.arabic 
        ? 'لا توجد كتب' 
        : lang.currentLanguage == AppLanguage.kurdish 
            ? 'هیچ کتێبێک نییە' 
            : 'No books available';
    String favoritesText = lang.currentLanguage == AppLanguage.arabic 
        ? 'المفضلة' 
        : lang.currentLanguage == AppLanguage.kurdish 
            ? 'دڵخوازەکان' 
            : 'Favorites';

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
                  _buildCategoryTabs(lang, isDark, languageCode, allText, favoritesText),
                  Expanded(
                    child: _buildBookGrid(lang, isDark, languageCode, noBooksText),
                  ),
                ],
              ),
            ),
          ),
        ),
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
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: lang.currentLanguage == AppLanguage.kurdish
                          ? 'گەڕان...'
                          : (lang.currentLanguage == AppLanguage.arabic ? 'بحث...' : 'Search...'),
                      hintStyle: lang.getTextStyle(color: (isDark ? Colors.white : Colors.black87).withOpacity(0.5)),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() {}),
                  )
                : Text(
                    title,
                    style: lang.getTextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
          ),
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(LanguageService lang, bool isDark, String languageCode, String allText, String favoritesText) {
    return Consumer<LibraryService>(
      builder: (context, libraryService, child) {
        final categories = libraryService.categories;
        
        return Container(
          height: 50,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            children: [
              _buildCategoryChip('all', allText, isDark, lang),
              _buildCategoryChip('favorites', favoritesText, isDark, lang),
              ...categories.map((cat) => _buildCategoryChip(
                cat.id, 
                cat.getName(languageCode), 
                isDark, 
                lang,
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String id, String name, bool isDark, LanguageService lang) {
    final isSelected = _selectedCategory == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF667EEA)
              : isDark ? Colors.white.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF667EEA).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Text(
          name,
          style: lang.getTextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildBookGrid(LanguageService lang, bool isDark, String languageCode, String noBooksText) {
    return Consumer<LibraryService>(
      builder: (context, libraryService, child) {
        // Only show full-screen loader if we have NO data at all
        if (libraryService.isLoading && libraryService.books.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF667EEA)),
          );
        }

        var books = libraryService.getBooksForCategory(_selectedCategory);
        
        // Handle virtual 'favorites' category
        if (_selectedCategory == 'favorites') {
          books = libraryService.books.where((b) => libraryService.isFavorite(b.id)).toList();
        }

        if (_isSearching && _searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          books = books.where((b) => b.title.toLowerCase().contains(query) || b.author.toLowerCase().contains(query)).toList();
        }

        if (books.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_books_outlined,
                  size: 80,
                  color: isDark ? Colors.white24 : Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  noBooksText,
                  style: lang.getTextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white54 : Colors.black38,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.55, // Taller cards for bigger covers
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return BookCardItem(
              book: book,
              lang: lang,
              isDark: isDark,
              libraryService: libraryService,
            );
          },
        );
      },
    );
  }

  // Note: Book Card logic has been moved to components/book_card_item.dart

}
