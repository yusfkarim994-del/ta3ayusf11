import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../services/partner_discovery_service.dart';
import '../services/language_service.dart';
import '../models/partner_post.dart';

class AccountabilityScreen extends StatefulWidget {
  const AccountabilityScreen({super.key});

  @override
  State<AccountabilityScreen> createState() => _AccountabilityScreenState();
}

class _AccountabilityScreenState extends State<AccountabilityScreen> {
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _selectedContactType = 'telegram'; 
  final List<String> _adminEmails = ['yusfkarim2001@gmail.com', 'yusfkarim1001@gmail.com'];

  // Pagination State
  final List<PartnerPost> _posts = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isSaving = false;
  static const int _batchSize = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialPosts();
    });
  }

  @override
  void dispose() {
    _contactController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore && _hasMore && !_isLoadingInitial) {
          _loadMorePosts();
        }
      }
    }
  }

  Future<void> _loadInitialPosts() async {
    final service = Provider.of<PartnerDiscoveryService>(context, listen: false);
    if (!mounted) return;
    
    setState(() {
      _isLoadingInitial = true;
      _posts.clear();
      _lastDocument = null;
      _hasMore = true;
    });

    try {
      final snapshot = await service.getDiscoveryPostsSnapshot(limit: _batchSize);
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        final newPosts = snapshot.docs.map((doc) => PartnerPost.fromFirestore(doc)).toList();
        if (mounted) {
          setState(() {
            _posts.addAll(newPosts);
            _hasMore = snapshot.docs.length == _batchSize;
          });
        }
      } else {
        if (mounted) setState(() => _hasMore = false);
      }
    } catch (e) {
      debugPrint('Error loading initial posts: $e');
    } finally {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;

    final service = Provider.of<PartnerDiscoveryService>(context, listen: false);
    setState(() => _isLoadingMore = true);

    try {
      final snapshot = await service.getDiscoveryPostsSnapshot(limit: _batchSize, startAfter: _lastDocument);
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        final newPosts = snapshot.docs.map((doc) => PartnerPost.fromFirestore(doc)).toList();
        if (mounted) {
          setState(() {
            _posts.addAll(newPosts);
            _hasMore = snapshot.docs.length == _batchSize;
          });
        }
      } else {
        if (mounted) setState(() => _hasMore = false);
      }
    } catch (e) {
      debugPrint('Error loading more posts: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  bool get _isAdmin {
    final email = FirebaseAuth.instance.currentUser?.email;
    return email != null && _adminEmails.contains(email.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final service = Provider.of<PartnerDiscoveryService>(context);
    final isDark = lang.isDarkMode;
    // Standard Dark Background (matches your premium theme)
    final backgroundColor = isDark ? const Color(0xFF020205) : const Color(0xFFF5F5F5);

    return Directionality(
      textDirection: lang.textDirection,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(overscroll: false),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
            // Sliver Header
            SliverAppBar(
              backgroundColor: backgroundColor,
              floating: false,
              pinned: true,
              elevation: 0,
              centerTitle: true,
              title: Text(
                lang.currentLanguage == AppLanguage.arabic ? 'شريك المحاسبة' : 'هاوڕێی بەرپرسیاریەتی',
                style: lang.getTextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black87, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Top Section (My Post Header)
            SliverToBoxAdapter(
              child: FutureBuilder<PartnerPost?>(
                future: service.getMyPost(),
                builder: (context, snapshot) {
                  final myPost = snapshot.data;
                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366f1), Color(0xFFa855f7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0xFF6366f1).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.white, size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                myPost != null 
                                  ? (lang.currentLanguage == AppLanguage.arabic ? 'منشورك نشط' : 'پۆستەکەت چالاکە')
                                  : (lang.currentLanguage == AppLanguage.arabic ? 'ابحث عن شريك' : 'هاوڕێیەک بدۆزەرەوە'),
                                style: lang.getTextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                myPost != null 
                                  ? (lang.currentLanguage == AppLanguage.arabic ? 'يمكنك تعديل منشورك' : 'دەتوانیت دەستکاری ئەکەیت')
                                  : (lang.currentLanguage == AppLanguage.arabic ? 'أنشئ منشوراً للتواصل' : 'پۆستێک بکە بۆ دۆزینەوەی هاوڕێ'),
                                style: lang.getTextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () => _showPostDialog(service, lang, existingPost: myPost),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF6366f1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: Text(
                                myPost != null 
                                  ? (lang.currentLanguage == AppLanguage.arabic ? 'تعديل' : 'دەستکاری')
                                  : (lang.currentLanguage == AppLanguage.arabic ? 'إضافة' : 'زیادکردن'),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (myPost != null) ...[
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  if (await _showDeleteConfirm(lang) == true) {
                                    await service.deleteMyPost();
                                    setState(() {
                                      _loadInitialPosts();
                                    });
                                  }
                                },
                                child: Text(
                                  lang.currentLanguage == AppLanguage.arabic ? 'حذف المنشور' : 'سڕینەوەی پۆست',
                                  style: lang.getTextStyle(color: Colors.white70, fontSize: 11, decoration: TextDecoration.underline),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Posts List
            if (_isLoadingInitial)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Color(0xFF6366f1))),
              )
            else if (_posts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline_rounded, size: 64, color: isDark ? Colors.white10 : Colors.black12),
                      const SizedBox(height: 16),
                      Text(
                        lang.currentLanguage == AppLanguage.arabic ? 'لا توجد منشورات بعد' : 'هیچ پۆستێک نییە',
                        style: lang.getTextStyle(color: isDark ? Colors.white38 : Colors.black38),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildPostCard(_posts[index], lang, isDark, service);
                    },
                    childCount: _posts.length,
                  ),
                ),
              ),

            // Pagination Indicator Footer
            if (_isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF6366f1))),
                ),
              ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildPostCard(PartnerPost post, LanguageService lang, bool isDark, PartnerDiscoveryService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF6366f1).withOpacity(0.1),
                backgroundImage: post.userPhotoUrl != null ? NetworkImage(post.userPhotoUrl!) : null,
                child: post.userPhotoUrl == null 
                  ? Text(post.userName[0], style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold)) 
                  : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      style: lang.getTextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    ),
                    Text(
                      _formatDate(post.updatedAt, lang),
                      style: lang.getTextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (_isAdmin || post.userId == service.currentUserId) 
                IconButton(
                  onPressed: () async {
                    if (await _showDeleteConfirm(lang) == true) {
                      if (post.userId == service.currentUserId) {
                        await service.deleteMyPost();
                      } else {
                        await service.deletePost(post.userId);
                      }
                      _loadInitialPosts();
                    }
                  },
                  icon: Icon(
                    Icons.delete_forever, 
                    color: post.userId == service.currentUserId ? Colors.orangeAccent : Colors.redAccent, 
                    size: 24
                  ),
                ),
              IconButton(
                onPressed: () => _launchContact(post.contactInfo, post.contactType),
                icon: Icon(
                  post.contactType == 'telegram' ? Icons.telegram : Icons.chat_bubble, 
                  color: post.contactType == 'telegram' ? const Color(0xFF6366f1) : Colors.green, 
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.message,
            style: lang.getTextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (post.contactType == 'telegram' ? Colors.blue : Colors.green).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  post.contactType == 'telegram' ? Icons.alternate_email : Icons.phone_android,
                  size: 14,
                  color: post.contactType == 'telegram' ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  post.contactInfo,
                  style: lang.getTextStyle(
                    fontSize: 11, 
                    fontWeight: FontWeight.bold, 
                    color: post.contactType == 'telegram' ? Colors.blue : Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: post.contactInfo));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          lang.currentLanguage == AppLanguage.arabic ? 'تم النسخ!' : 'کۆپی کرا!',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF6366f1),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        width: 100,
                      ),
                    );
                  },
                  child: Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPostDialog(PartnerDiscoveryService service, LanguageService lang, {PartnerPost? existingPost}) {
    if (existingPost != null) {
      _contactController.text = existingPost.contactInfo;
      _messageController.text = existingPost.message;
      _selectedContactType = existingPost.contactType;
    } else {
      _contactController.clear();
      _messageController.clear();
      _selectedContactType = 'telegram';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: lang.textDirection,
          child: AlertDialog(
            backgroundColor: lang.isDarkMode ? const Color(0xFF1a2a4a) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              lang.currentLanguage == AppLanguage.arabic ? 'اكتب منشورك' : 'پۆستەکەت بنووسە',
              style: lang.getTextStyle(fontWeight: FontWeight.bold, color: lang.isDarkMode ? Colors.white : Colors.black87),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Text(
                      lang.currentLanguage == AppLanguage.arabic 
                        ? 'فقط ضع اسم مستخدم التلغرام أو رقم الواتساب أو أي وسيلة تواصل أخرى'
                        : 'تەنها یوزەرنەیمی تلیگرامت یان وەتس ئەپت یان هەر سۆشیال میدیایەکی تر بنوسە',
                      style: lang.getTextStyle(fontSize: 12, color: Colors.orange[800], fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildContactTypeOption('telegram', Icons.telegram, 'Telegram', setDialogState, lang),
                      _buildContactTypeOption('whatsapp', Icons.chat_bubble, 'WhatsApp', setDialogState, lang),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contactController,
                    style: lang.getTextStyle(color: lang.isDarkMode ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: _selectedContactType == 'telegram' 
                        ? (lang.currentLanguage == AppLanguage.arabic ? 'اسم مستخدم التلجرام' : 'یوزەرنەیمی تلیگرام')
                        : (lang.currentLanguage == AppLanguage.arabic ? 'رقم الواتساب' : 'ڕەقەمی وەتسئەپ'),
                      labelStyle: lang.getTextStyle(color: lang.isDarkMode ? Colors.white60 : Colors.black54),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: lang.isDarkMode ? Colors.white24 : Colors.black12)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF667eea))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    style: lang.getTextStyle(color: lang.isDarkMode ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: lang.currentLanguage == AppLanguage.arabic ? 'الرسالة' : 'پەیام',
                      labelStyle: lang.getTextStyle(color: lang.isDarkMode ? Colors.white60 : Colors.black54),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: lang.isDarkMode ? Colors.white24 : Colors.black12)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF667eea))),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.cancel)),
              ElevatedButton(
                onPressed: _isSaving ? null : () async {
                  if (_contactController.text.isNotEmpty && _messageController.text.isNotEmpty) {
                    setDialogState(() => _isSaving = true);
                    try {
                      await service.savePost(
                        contactInfo: _contactController.text,
                        contactType: _selectedContactType,
                        message: _messageController.text,
                      );
                      if (mounted) { 
                        Navigator.pop(context); 
                        _loadInitialPosts();
                      }
                    } catch (e) {
                      debugPrint('Error in post dialog: $e');
                    } finally {
                      if (mounted) setDialogState(() => _isSaving = false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(lang.currentLanguage == AppLanguage.arabic ? 'نشر' : 'بڵاوکردنەوە', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactTypeOption(String type, IconData icon, String label, StateSetter setDialogState, LanguageService lang) {
    final isSelected = _selectedContactType == type;
    return GestureDetector(
      onTap: () => setDialogState(() => _selectedContactType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF667eea) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF667eea) : Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 8),
            Text(label, style: lang.getTextStyle(color: isSelected ? Colors.white : Colors.grey)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date, LanguageService lang) {
    if (DateTime.now().difference(date).inDays == 0) {
      return lang.currentLanguage == AppLanguage.arabic ? 'اليوم' : 'ئەمڕۆ';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _launchContact(String contact, String type) async {
    final cleanContact = contact.trim().replaceAll('@', '');
    final url = type == 'whatsapp' ? Uri.parse('whatsapp://send?phone=$cleanContact') : Uri.parse('https://t.me/$cleanContact');
    try {
      if (await canLaunchUrl(url)) { await launchUrl(url, mode: LaunchMode.externalApplication); }
      else { await launchUrl(type == 'whatsapp' ? Uri.parse('https://wa.me/$cleanContact') : Uri.parse('https://t.me/$cleanContact'), mode: LaunchMode.externalApplication); }
    } catch (e) { debugPrint('$e'); }
  }

  Future<bool?> _showDeleteConfirm(LanguageService lang) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: lang.isDarkMode ? const Color(0xFF1e293b) : Colors.white,
        title: Text(lang.currentLanguage == AppLanguage.arabic ? 'حذف المنشور؟' : 'سڕینەوەی پۆست؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(lang.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(lang.currentLanguage == AppLanguage.arabic ? 'حذف' : 'سڕینەوە', style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
