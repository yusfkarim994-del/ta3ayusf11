import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../services/library_service.dart';
import '../../services/language_service.dart';
import '../../services/download_service.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../pdf_reader_screen.dart';
import '../webview_screen.dart';

class BookCardItem extends StatefulWidget {
  final Book book;
  final LanguageService lang;
  final bool isDark;
  final LibraryService libraryService;

  const BookCardItem({
    super.key,
    required this.book,
    required this.lang,
    required this.isDark,
    required this.libraryService,
  });

  @override
  State<BookCardItem> createState() => _BookCardItemState();
}

class _BookCardItemState extends State<BookCardItem> {
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    if (kIsWeb) {
      if (mounted) setState(() => _isDownloaded = true);
      return;
    }
    final downloaded = await DownloadService.isBookDownloaded(widget.book.id);
    if (mounted) {
      setState(() => _isDownloaded = downloaded);
    }
  }

  Future<void> _startDownload() async {
    final url = widget.book.downloadUrl ?? widget.book.pdfUrl;
    if (url == null || url.isEmpty) return;

    if (kIsWeb) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isDownloading = true;
        _progress = 0.0;
      });
    }

    final success = await DownloadService.downloadBook(
      downloadUrl: url,
      bookId: widget.book.id,
      onProgress: (progress) {
        if (mounted) {
          setState(() => _progress = progress);
        }
      },
    );

    if (mounted) {
      setState(() {
        _isDownloading = false;
        _isDownloaded = success;
      });
      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? (widget.lang.currentLanguage == AppLanguage.kurdish ? 'داگرتن سەرکەوتوو بوو' : (widget.lang.currentLanguage == AppLanguage.arabic ? 'تم التحميل بنجاح' : 'Download successful'))
                : (widget.lang.currentLanguage == AppLanguage.kurdish ? 'هەڵە لە داگرتندا' : (widget.lang.currentLanguage == AppLanguage.arabic ? 'فشل التحميل' : 'Download failed')),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _openBook() async {
    if (kIsWeb) {
      final url = widget.book.downloadUrl ?? widget.book.pdfUrl;
      if (url == null || url.isEmpty) return;
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }
    final localPath = await DownloadService.getLocalBookPath(widget.book.id);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfReaderScreen(
            book: widget.book,
            localPdfPath: localPath,
          ),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover Image View
          Expanded(
            flex: 5,
            child: GestureDetector(
              onTap: () {
                if (_isDownloaded) {
                  _openBook();
                } else if (!_isDownloading) {
                  _startDownload();
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.15),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: widget.book.coverUrl != null && widget.book.coverUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: CachedNetworkImage(
                              imageUrl: widget.book.coverUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF667EEA)),
                              ),
                              errorWidget: (context, url, error) => _buildDefaultCover(),
                            ),
                          )
                        : _buildDefaultCover(),
                  ),
                  
                  // Progress UI Overlay
                  if (_isDownloading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(_progress * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: _progress,
                                  backgroundColor: Colors.white24,
                                  color: const Color(0xFF667EEA),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                  // Favorite Heart Icon
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Consumer<LibraryService>(
                      builder: (context, libraryService, child) {
                        final isFav = libraryService.isFavorite(widget.book.id);
                        return GestureDetector(
                          onTap: () => libraryService.toggleFavorite(widget.book.id),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border_rounded,
                              color: isFav ? Colors.redAccent : Colors.white,
                              size: 18,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Download Icon overlapping the image if not downloaded and not downloading
                  if (!_isDownloaded && !_isDownloading)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Action Buttons and Info (4 flex)
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: widget.lang.getTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? Colors.white : Colors.black87,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: widget.lang.getTextStyle(
                          fontSize: 11,
                          color: widget.isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Read / Download Button
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_isDownloaded) {
                          _openBook();
                        } else if (!_isDownloading) {
                          _startDownload();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: _isDownloaded 
                            ? const Color(0xFF4CAF50) // Green for read
                            : const Color(0xFF667EEA), // Purple for download
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isDownloading
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isDownloaded 
                              ? (widget.lang.currentLanguage == AppLanguage.kurdish ? 'خوێندنەوە' : (widget.lang.currentLanguage == AppLanguage.arabic ? 'قراءة' : 'Read'))
                              : (widget.lang.currentLanguage == AppLanguage.kurdish ? 'داگرتن' : (widget.lang.currentLanguage == AppLanguage.arabic ? 'تحميل' : 'Download')),
                            style: widget.lang.getTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Center(
      child: Icon(
        Icons.menu_book_rounded,
        size: 50,
        color: widget.isDark ? Colors.white24 : Colors.grey[300],
      ),
    );
  }
}
