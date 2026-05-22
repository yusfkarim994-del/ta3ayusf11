import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';
import '../services/library_service.dart';
import '../services/language_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PdfReaderScreen extends StatefulWidget {
  final Book book;
  final String localPdfPath;

  const PdfReaderScreen({super.key, required this.book, required this.localPdfPath});

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  PDFViewController? _pdfViewController;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  bool _isLoadingProgress = true;
  String _errorMessage = '';
  late bool _isNightMode;
  
  void _showGoToPageDialog() {
    final lang = Provider.of<LanguageService>(context, listen: false);
    final TextEditingController pageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _isNightMode ? const Color(0xFF1A1A2E) : Colors.white,
          title: Text(
            lang.currentLanguage == AppLanguage.kurdish ? 'بچۆ بۆ لاپەڕە' : (lang.currentLanguage == AppLanguage.arabic ? 'الذهاب إلى صفحة' : 'Go to Page'),
            style: lang.getTextStyle(color: _isNightMode ? Colors.white : Colors.black87),
          ),
          content: TextField(
            controller: pageController,
            keyboardType: TextInputType.number,
            style: lang.getTextStyle(color: _isNightMode ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: '1 - $_totalPages',
              hintStyle: lang.getTextStyle(color: Colors.grey),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                lang.currentLanguage == AppLanguage.kurdish ? 'پاشگەزبوونەوە' : (lang.currentLanguage == AppLanguage.arabic ? 'إلغاء' : 'Cancel'),
                style: lang.getTextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                final input = int.tryParse(pageController.text) ?? 0;
                if (input >= 1 && input <= _totalPages) {
                  _pdfViewController?.setPage(input - 1); // 0-indexed internally
                }
                Navigator.pop(context);
              },
              child: Text(
                lang.currentLanguage == AppLanguage.kurdish ? 'بچۆ' : (lang.currentLanguage == AppLanguage.arabic ? 'ذهاب' : 'Go'),
                style: lang.getTextStyle(color: const Color(0xFF667EEA)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Use the global theme setting as the initial state for the reader's view
    _isNightMode = Provider.of<LanguageService>(context, listen: false).isDarkMode;
    _initializeReader();
  }

  Future<void> _initializeReader() async {
    final libraryService = Provider.of<LibraryService>(context, listen: false);
    final lang = Provider.of<LanguageService>(context, listen: false);
    
    // getReadingProgress from sharedPrefs
    try {
      final file = File(widget.localPdfPath);
      if (!await file.exists()) {
        if (mounted) setState(() => _errorMessage = lang.currentLanguage == AppLanguage.kurdish ? 'کتێبەکە نەدۆزرایەوە، تکایە دووبارە دایبەزێنە' : 'Book not found, please download again');
        return;
      }
      if (await file.length() == 0) {
        if (mounted) setState(() => _errorMessage = lang.currentLanguage == AppLanguage.kurdish ? 'فایلی کتێبەکە تێکچووە، تکایە دووبارە دایبەزێنە' : 'Book file is corrupted, please download again');
        return;
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Error access: $e');
      return;
    }

    // getReadingProgress from sharedPrefs
    final lastPage = await libraryService.getReadingProgress(widget.book.id);
    
    // Load night mode setting for THIS specific book
    final prefs = await SharedPreferences.getInstance();
    final specificNightMode = prefs.getBool('night_mode_${widget.book.id}');
    
    if (mounted) {
      setState(() {
        if (specificNightMode != null) {
          _isNightMode = specificNightMode;
        }
        _currentPage = lastPage == 1 ? 0 : lastPage; 
        _isLoadingProgress = false;
        _isReady = false; // Reset ready state to show spinner while PDFView initializes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final libraryService = Provider.of<LibraryService>(context, listen: false);

    return Directionality(
      textDirection: lang.textDirection, // Keep app UI direction
      child: Scaffold(
        backgroundColor: _isNightMode ? const Color(0xFF0F0F1E) : Colors.grey[100],
        appBar: AppBar(
          backgroundColor: _isNightMode ? const Color(0xFF1A1A2E) : Colors.white,
          elevation: 2,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              lang.isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
              color: _isNightMode ? Colors.white : Colors.black87,
            ),
          ),
          title: Text(
            widget.book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: lang.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _isNightMode ? Colors.white : Colors.black87,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.find_in_page_outlined,
                color: _isNightMode ? Colors.white : Colors.black87,
              ),
              onPressed: _showGoToPageDialog,
            ),
            // Night mode toggle inside the PDF viewer
            IconButton(
              icon: Icon(
                _isNightMode ? Icons.wb_sunny : Icons.nights_stay,
                color: _isNightMode ? Colors.white : Colors.black87,
              ),
              onPressed: () async {
                setState(() {
                  _isNightMode = !_isNightMode;
                });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('night_mode_${widget.book.id}', _isNightMode);
              },
            ),
          ],
        ),
        body: _isLoadingProgress 
          ? Center(child: CircularProgressIndicator(color: const Color(0xFF667EEA)))
          : Stack(
          children: [
            if (_errorMessage.isEmpty)
              Directionality(
                // PDFView should be forced to LTR so the swipe direction works consistently with standard PDFs
                textDirection: TextDirection.ltr,
                child: PDFView(
                  key: ValueKey(_isNightMode), // Extremely important: forces PDFView to rebuild when night mode changes
                  filePath: widget.localPdfPath,
                  enableSwipe: true,
                  swipeHorizontal: true,
                  autoSpacing: false,
                  pageFling: true,
                  pageSnap: true,
                  defaultPage: _currentPage,
                  fitPolicy: FitPolicy.BOTH,
                  nightMode: _isNightMode,
                  onRender: (pages) {
                    setState(() {
                      _totalPages = pages ?? 0;
                      _isReady = true;
                    });
                  },
                  onError: (error) {
                    setState(() {
                      _errorMessage = lang.currentLanguage == AppLanguage.kurdish ? 'هەڵە لە کردنەوەی کتێب: $error' : 'Error opening book: $error';
                    });
                    debugPrint('PDF View Error: $error');
                  },
                  onPageError: (page, error) {
                    setState(() {
                      _errorMessage = '$page: ${error.toString()}';
                    });
                    debugPrint('PDF Page Error: $page: $error');
                  },
                  onViewCreated: (PDFViewController pdfViewController) {
                    _pdfViewController = pdfViewController;
                  },
                  onPageChanged: (int? page, int? total) {
                    if (page != null) {
                      setState(() {
                        _currentPage = page;
                      });
                      libraryService.saveReadingProgress(widget.book.id, page, total ?? _totalPages);
                    }
                  },
                ),
              ),

            // Loading state
            if (!_isReady && _errorMessage.isEmpty)
              Center(
                child: CircularProgressIndicator(color: const Color(0xFF667EEA)),
              ),
              
            // Error state
            if (_errorMessage.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: lang.getTextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: Text(lang.cancel, style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),

            // Page indicator pill overlay
            if (_isReady && _totalPages > 0)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      lang.currentLanguage == AppLanguage.kurdish 
                          ? 'پەڕە ${_currentPage + 1} لە $_totalPages' 
                          : lang.currentLanguage == AppLanguage.arabic
                              ? 'صفحة ${_currentPage + 1} من $_totalPages'
                              : 'Page ${_currentPage + 1} of $_totalPages',
                      style: lang.getTextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
