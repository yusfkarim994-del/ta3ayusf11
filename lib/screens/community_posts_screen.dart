import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/posts_service.dart';
import '../widgets/user_avatar.dart';

class CommunityPostsScreen extends StatefulWidget {
  const CommunityPostsScreen({super.key});

  @override
  State<CommunityPostsScreen> createState() => _CommunityPostsScreenState();
}

class _CommunityPostsScreenState extends State<CommunityPostsScreen> {
  final _postsService = PostsService();
  final _postController = TextEditingController();
  final _scrollController = ScrollController();
  
  bool _isAdmin = false;
  bool _isBlocked = false;
  bool _isLoading = false;
  int _currentLimit = 10;
  bool _isLoadingMore = false;
  int _totalPostsCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      
      // Load more when reaching near the bottom (200px threshold)
      if (currentScroll >= maxScroll - 200 && !_isLoadingMore && _totalPostsCount >= _currentLimit) {
        _loadMorePosts();
      }
    }
  }

  void _loadMorePosts() {
    if (!mounted) return;
    setState(() {
      _isLoadingMore = true;
      _currentLimit += 10;
    });
    
    // We don't need to manually fetch as the StreamBuilder uses _currentLimit
    // but we need a small delay to prevent multiple triggers
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _isLoadingMore = false);
    });
  }

  Future<void> _initializeUser() async {
    await _postsService.initializeUserStatus();
    if (mounted) {
      setState(() {
        _isAdmin = _postsService.isAdmin;
        _isBlocked = _postsService.isBlocked;
      });
    }
  }

  @override
  void dispose() {
    _postController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _createPost() {
    final content = _postController.text.trim();
    if (content.isEmpty) return;

    _postController.clear();
    
    _postsService.createPost(content).then((success) {
      if (success && mounted) {
        // Scroll to top to see the new post
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = lang.isDarkMode;

    return Directionality(
      textDirection: lang.textDirection,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0a1628) : const Color(0xFFF5F5F5),
        appBar: _buildAppBar(lang, isDark),
        body: Column(
          children: [
            // Blocked banner
            if (_isBlocked) _buildBlockedBanner(lang, isDark),
            
            // Posts list
            Expanded(
              child: StreamBuilder<List<CommunityPost>>(
                stream: _postsService.getPosts(limit: _currentLimit),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState(lang, isDark);
                  }

                  final posts = snapshot.data!;
                  _totalPostsCount = posts.length;

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
                    itemCount: posts.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == posts.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return _buildPostCard(posts[index], lang, isDark);
                    },
                  );
                },
              ),
            ),
            
            // Create post input (if not blocked)
            if (!_isBlocked) _buildCreatePostSection(lang, isDark),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(LanguageService lang, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF14B8A6)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.article_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            _getTitle(lang),
            style: lang.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
      actions: _isAdmin ? [
        // Admin panel button
        GestureDetector(
          onTap: () => _showBlockedUsersPanel(lang, isDark),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF14B8A6)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  lang.currentLanguage == AppLanguage.arabic 
                      ? 'لوحة التحكم'
                      : lang.currentLanguage == AppLanguage.kurdish 
                          ? 'لوحەی کۆنترۆڵ' 
                          : 'Admin',
                  style: lang.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ] : null,
    );
  }

  Widget _buildBlockedBanner(LanguageService lang, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade700, Colors.red.shade500],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.block, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getBlockedMessage(lang),
              style: lang.getTextStyle(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LanguageService lang, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _getEmptyMessage(lang),
            style: lang.getTextStyle(
              fontSize: 16,
              color: isDark ? Colors.white54 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post, LanguageService lang, bool isDark) {
    return GestureDetector(
      onLongPress: _isAdmin ? () => _showPostOptions(post, lang, isDark) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a2a4a) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: post.isPinned 
              ? Border.all(color: const Color(0xFFFFD700), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Author avatar
                  UserAvatar(
                    userId: post.authorId,
                    userName: post.authorName,
                    storedPhotoUrl: post.authorPhotoUrl,
                    radius: 20,
                    useGradient: true,
                  ),
                  const SizedBox(width: 12),
                  // Author name and time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.authorName,
                              style: lang.getTextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (post.isEdited) ...[
                              const SizedBox(width: 6),
                              Text(
                                _getEditedText(lang),
                                style: lang.getTextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white38 : Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _formatTime(post.createdAt),
                          style: lang.getTextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Pin indicator
                  if (post.isPinned)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.push_pin, size: 14, color: Color(0xFFFFD700)),
                          const SizedBox(width: 4),
                          Text(
                            _getPinnedText(lang),
                            style: lang.getTextStyle(fontSize: 11, color: const Color(0xFFFFD700)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.content,
                style: lang.getTextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                ),
              ),
            ),
            // Footer (likes)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _postsService.likePost(post.id).catchError((e) {
                         if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Error liking post: $e')),
                           );
                         }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _postsService.hasUserLiked(post)
                            ? Colors.red.withOpacity(0.2)
                            : (isDark 
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(20),
                        border: _postsService.hasUserLiked(post)
                            ? Border.all(color: Colors.red.withOpacity(0.5))
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _postsService.hasUserLiked(post) 
                                ? Icons.favorite 
                                : Icons.favorite_border,
                            size: 18,
                            color: _postsService.hasUserLiked(post) 
                                ? Colors.red 
                                : (isDark ? Colors.white38 : Colors.grey),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            post.likes.toString(),
                            style: lang.getTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _postsService.hasUserLiked(post) 
                                  ? Colors.red 
                                  : (isDark ? Colors.white70 : Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatePostSection(LanguageService lang, bool isDark) {
    return FutureBuilder<int>(
      future: _postsService.getRemainingPosts(),
      builder: (context, snapshot) {
        final remaining = snapshot.data ?? 5;
        final canPost = remaining > 0;
        
        return Container(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a2a4a) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Remaining posts counter - Beautiful badge
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: canPost 
                      ? LinearGradient(
                          colors: isDark 
                              ? [const Color(0xFF0D9488).withOpacity(0.2), const Color(0xFF14B8A6).withOpacity(0.2)]
                              : [const Color(0xFF0D9488).withOpacity(0.15), const Color(0xFF14B8A6).withOpacity(0.15)],
                        )
                      : LinearGradient(
                          colors: [Colors.red.withOpacity(0.2), Colors.orange.withOpacity(0.2)],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: canPost 
                        ? const Color(0xFF0D9488).withOpacity(0.4)
                        : Colors.red.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      remaining >= 999 ? Icons.all_inclusive : Icons.edit_note,
                      size: 18,
                      color: canPost 
                          ? const Color(0xFF0D9488)
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getRemainingText(lang, remaining),
                      style: lang.getTextStyle(
                        fontSize: 13,
                        color: canPost 
                            ? (isDark ? Colors.white : const Color(0xFF0D9488))
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Input row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _postController,
                      maxLines: null,
                      enabled: canPost,
                      style: lang.getTextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: canPost 
                            ? _getHintText(lang)
                            : _getLimitReachedText(lang),
                        hintStyle: lang.getTextStyle(
                          fontSize: 14,
                          color: canPost 
                              ? (isDark ? Colors.white38 : Colors.grey)
                              : Colors.red.withOpacity(0.7),
                        ),
                        filled: true,
                        fillColor: isDark 
                            ? Colors.white.withOpacity(canPost ? 0.1 : 0.05)
                            : (canPost ? Colors.grey.shade100 : Colors.red.shade50),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: (_isLoading || !canPost) ? null : _createPost,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: canPost 
                            ? const LinearGradient(
                                colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                              )
                            : LinearGradient(
                                colors: [Colors.grey.shade400, Colors.grey.shade500],
                              ),
                        shape: BoxShape.circle,
                        boxShadow: canPost ? [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ] : null,
                      ),
                      child: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              canPost ? Icons.send_rounded : Icons.block,
                              color: Colors.white,
                              size: 22,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPostOptions(CommunityPost post, LanguageService lang, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a2a4a) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionItem(
              icon: Icons.favorite,
              title: _getAddLikesText(lang),
              color: Colors.red,
              isDark: isDark,
              lang: lang,
              onTap: () {
                Navigator.pop(context);
                _showAddLikesDialog(post, lang, isDark);
              },
            ),
            _buildOptionItem(
              icon: post.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              title: post.isPinned ? _getUnpinText(lang) : _getPinText(lang),
              color: const Color(0xFFFFD700),
              isDark: isDark,
              lang: lang,
              onTap: () {
                Navigator.pop(context);
                if (post.isPinned) {
                  _postsService.unpinPost(post.id);
                } else {
                  _postsService.pinPost(post.id);
                }
              },
            ),
            _buildOptionItem(
              icon: Icons.edit,
              title: _getEditText(lang),
              color: Colors.blue,
              isDark: isDark,
              lang: lang,
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(post, lang, isDark);
              },
            ),
            _buildOptionItem(
              icon: Icons.delete,
              title: _getDeleteText(lang),
              color: Colors.red.shade700,
              isDark: isDark,
              lang: lang,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(post, lang, isDark);
              },
            ),
            _buildOptionItem(
              icon: Icons.block,
              title: _getBlockUserText(lang),
              color: Colors.orange,
              isDark: isDark,
              lang: lang,
              onTap: () {
                Navigator.pop(context);
                _postsService.blockUser(post.authorId, post.authorName).then((_) {
                   if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_getUserBlockedMessage(lang))),
                    );
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
    required LanguageService lang,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: lang.getTextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showAddLikesDialog(CommunityPost post, LanguageService lang, bool isDark) {
    final controller = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _getAddLikesText(lang),
          style: lang.getTextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: _getLikesHintText(lang),
            hintStyle: lang.getTextStyle(color: isDark ? Colors.white38 : Colors.grey),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getCancelText(lang), style: lang.getTextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final count = int.tryParse(controller.text) ?? 0;
              if (count > 0) {
                _postsService.addLikes(post.id, count);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(_getAddText(lang), style: lang.getTextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(CommunityPost post, LanguageService lang, bool isDark) {
    final controller = TextEditingController(text: post.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _getEditText(lang),
          style: lang.getTextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getCancelText(lang), style: lang.getTextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty) {
                _postsService.editPost(post.id, newContent);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(_getSaveText(lang), style: lang.getTextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(CommunityPost post, LanguageService lang, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _getDeleteText(lang),
          style: lang.getTextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          _getDeleteConfirmText(lang),
          style: lang.getTextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getCancelText(lang), style: lang.getTextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              _postsService.deletePost(post.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(_getDeleteText(lang), style: lang.getTextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBlockedUsersPanel(LanguageService lang, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0a1628) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.block, color: Colors.orange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getBlockedUsersTitle(lang),
                        style: lang.getTextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    // Delete Unknown posts button
                    GestureDetector(
                      onTap: () async {
                        final count = await _postsService.deleteUnknownPosts();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                lang.currentLanguage == AppLanguage.arabic
                                    ? 'تم حذف $count منشورات'
                                    : lang.currentLanguage == AppLanguage.kurdish
                                        ? '$count پۆست سڕایەوە'
                                        : 'Deleted $count posts',
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.delete_sweep, color: Colors.red, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              lang.currentLanguage == AppLanguage.arabic
                                  ? 'حذف Unknown'
                                  : lang.currentLanguage == AppLanguage.kurdish
                                      ? 'سڕینی Unknown'
                                      : 'Delete Unknown',
                              style: lang.getTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<BlockedPostUser>>(
                  stream: _postsService.getBlockedUsers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 60,
                              color: isDark ? Colors.white24 : Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _getNoBlockedUsersText(lang),
                              style: lang.getTextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white54 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final users = snapshot.data!;
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 120),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: lang.getTextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(user.blockedAt),
                                      style: lang.getTextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white38 : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await _postsService.unblockUser(user.id);
                                },
                                child: Text(
                                  _getUnblockText(lang),
                                  style: lang.getTextStyle(
                                    fontSize: 13,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return '${diff.inMinutes}د';
    if (diff.inHours < 24) return '${diff.inHours}س';
    if (diff.inDays < 7) return '${diff.inDays}ي';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  // Localization helpers
  String _getTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'منشورات المجتمع';
      case AppLanguage.kurdish: return 'بڵاوکراوەکانی کۆمەڵگا';
      case AppLanguage.english: return 'Community Posts';
    }
  }

  String _getBlockedMessage(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تم حظرك من النشر';
      case AppLanguage.kurdish: return 'تۆ بلۆککراویت لە بڵاوکردنەوە';
      case AppLanguage.english: return 'You are blocked from posting';
    }
  }

  String _getEmptyMessage(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'لا توجد منشورات بعد';
      case AppLanguage.kurdish: return 'هیچ بڵاوکراوەیەک نییە';
      case AppLanguage.english: return 'No posts yet';
    }
  }

  String _getHintText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'اكتب منشورك هنا...';
      case AppLanguage.kurdish: return 'بڵاوکراوەکەت لێرە بنووسە...';
      case AppLanguage.english: return 'Write your post here...';
    }
  }

  String _getEditedText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return '(معدّل)';
      case AppLanguage.kurdish: return '(دەستکاریکراو)';
      case AppLanguage.english: return '(edited)';
    }
  }

  String _getPinnedText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'مثبّت';
      case AppLanguage.kurdish: return 'چەسپاو';
      case AppLanguage.english: return 'Pinned';
    }
  }

  String _getAddLikesText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إضافة إعجابات';
      case AppLanguage.kurdish: return 'زیادکردنی لایک';
      case AppLanguage.english: return 'Add Likes';
    }
  }

  String _getPinText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تثبيت';
      case AppLanguage.kurdish: return 'چەسپاندن';
      case AppLanguage.english: return 'Pin';
    }
  }

  String _getUnpinText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إلغاء التثبيت';
      case AppLanguage.kurdish: return 'لابردنی چەسپاندن';
      case AppLanguage.english: return 'Unpin';
    }
  }

  String _getEditText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تعديل';
      case AppLanguage.kurdish: return 'دەستکاری';
      case AppLanguage.english: return 'Edit';
    }
  }

  String _getDeleteText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حذف';
      case AppLanguage.kurdish: return 'سڕینەوە';
      case AppLanguage.english: return 'Delete';
    }
  }

  String _getBlockUserText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حظر المستخدم';
      case AppLanguage.kurdish: return 'بلۆککردنی بەکارهێنەر';
      case AppLanguage.english: return 'Block User';
    }
  }

  String _getUserBlockedMessage(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تم حظر المستخدم بنجاح';
      case AppLanguage.kurdish: return 'بەکارهێنەر سەرکەوتوانە بلۆککرا';
      case AppLanguage.english: return 'User blocked successfully';
    }
  }

  String _getLikesHintText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'عدد الإعجابات';
      case AppLanguage.kurdish: return 'ژمارەی لایکەکان';
      case AppLanguage.english: return 'Number of likes';
    }
  }

  String _getCancelText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إلغاء';
      case AppLanguage.kurdish: return 'پاشگەزبوونەوە';
      case AppLanguage.english: return 'Cancel';
    }
  }

  String _getAddText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إضافة';
      case AppLanguage.kurdish: return 'زیادکردن';
      case AppLanguage.english: return 'Add';
    }
  }

  String _getSaveText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حفظ';
      case AppLanguage.kurdish: return 'پاشەکەوتکردن';
      case AppLanguage.english: return 'Save';
    }
  }

  String _getDeleteConfirmText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'هل أنت متأكد من حذف هذا المنشور؟';
      case AppLanguage.kurdish: return 'دڵنیایت لە سڕینەوەی ئەم بڵاوکراوەیە؟';
      case AppLanguage.english: return 'Are you sure you want to delete this post?';
    }
  }

  String _getBlockedUsersTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'المستخدمون المحظورون';
      case AppLanguage.kurdish: return 'بەکارهێنەرە بلۆککراوەکان';
      case AppLanguage.english: return 'Blocked Users';
    }
  }

  String _getNoBlockedUsersText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'لا يوجد مستخدمون محظورون';
      case AppLanguage.kurdish: return 'هیچ بەکارهێنەرێکی بلۆککراو نییە';
      case AppLanguage.english: return 'No blocked users';
    }
  }

  String _getUnblockText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إلغاء الحظر';
      case AppLanguage.kurdish: return 'لابردنی بلۆک';
      case AppLanguage.english: return 'Unblock';
    }
  }

  String _getRemainingText(LanguageService lang, int remaining) {
    // Admin/developer - unlimited posts, show simple text
    if (remaining >= 999) {
      switch (lang.currentLanguage) {
        case AppLanguage.arabic: return 'المنشورات المتبقية: ∞';
        case AppLanguage.kurdish: return 'پۆستی ماوە: ∞';
        case AppLanguage.english: return 'Posts remaining: ∞';
      }
    }
    
    // Regular users
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: 
        return remaining > 0 
            ? 'المنشورات المتبقية: $remaining'
            : 'لقد وصلت للحد الأقصى';
      case AppLanguage.kurdish: 
        return remaining > 0 
            ? 'پۆستی ماوە: $remaining'
            : 'گەیشتیت بە سنوورەکە';
      case AppLanguage.english: 
        return remaining > 0 
            ? 'Posts remaining: $remaining'
            : 'You have reached the limit';
    }
  }

  String _getLimitReachedText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'انتظر 12 ساعة للنشر مرة أخرى';
      case AppLanguage.kurdish: return 'چاوەڕێ بکە 12 کاتژمێر بۆ دووبارە پۆستکردن';
      case AppLanguage.english: return 'Wait 12 hours to post again';
    }
  }
}
