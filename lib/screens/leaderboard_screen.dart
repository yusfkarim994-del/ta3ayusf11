import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/badges_service.dart';
import '../services/tips_service.dart';
import '../services/xp_service.dart';

/// Leaderboard filter period
enum LeaderboardFilter { weekly, monthly, quarterly, allTime }

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  
  // New: Tab controller and filter
  late TabController _tabController;
  final _scrollController = ScrollController();
  LeaderboardFilter _currentFilter = LeaderboardFilter.allTime;
  
  // Pagination state
  DocumentSnapshot? _lastFetchedDocument;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const int _usersBatchSize = 15;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 3); // Start on All-time
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _loadLeaderboard(reset: true);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      
      if (currentScroll >= maxScroll - 300 && !_isLoadingMore && _hasMore && !_isSearching) {
        _loadMoreUsers();
      }
    }
  }

  void _loadMoreUsers() {
    _loadLeaderboard(reset: false);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      switch (_tabController.index) {
        case 0:
          _currentFilter = LeaderboardFilter.weekly;
          break;
        case 1:
          _currentFilter = LeaderboardFilter.monthly;
          break;
        case 2:
          _currentFilter = LeaderboardFilter.quarterly;
          break;
        case 3:
        default:
          _currentFilter = LeaderboardFilter.allTime;
      }
    });
    _loadLeaderboard();
  }

  // Normalize string for consistent searching (handles Arabic/Kurdish char variations)
  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ی')
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('‌', '') // Remove zero-width non-joiner
        .trim();
  }

  // Get filtered leaderboard based on search query
  List<Map<String, dynamic>> get _filteredLeaderboard {
    if (_searchQuery.isEmpty) return _leaderboard;
    
    final query = _normalize(_searchQuery);
    if (query.isEmpty) return _leaderboard; // Handle case where query is just spaces/special chars
    
    final filtered = _leaderboard.where((user) {
      final name = _normalize(user['displayName']?.toString() ?? '');
      // final email = _normalize(user['email']?.toString() ?? ''); // Commented out email search as per user feedback
      return name.contains(query);
    }).toList();
    
    // Debug print
    // print('Searching for "$query": found ${filtered.length} users');
    return filtered;
  }

  Future<void> _loadLeaderboard({bool reset = true}) async {
    if (!mounted) return;
    
    if (reset) {
      setState(() {
        _isLoading = true;
        _leaderboard = [];
        _lastFetchedDocument = null;
        _hasMore = true;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }
    
    try {
      // For allTime, we can use server-side limit and pagination.
      // For filtered periods, we still need to calculate based on recoveryStartDate.
      // But we can still limit the query.
      
      Query query = _firestore.collection('users');

      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));
      final quarterAgo = now.subtract(const Duration(days: 90));
      
      if (_currentFilter == LeaderboardFilter.weekly) {
        query = query.where('recoveryStartDate', isGreaterThanOrEqualTo: weekAgo);
      } else if (_currentFilter == LeaderboardFilter.monthly) {
        query = query.where('recoveryStartDate', isGreaterThanOrEqualTo: monthAgo);
      } else if (_currentFilter == LeaderboardFilter.quarterly) {
        query = query.where('recoveryStartDate', isGreaterThanOrEqualTo: quarterAgo);
      }

      // Order by total days descending = recoveryStartDate ascending
      query = query.orderBy('recoveryStartDate', descending: false).limit(_usersBatchSize);

      if (_lastFetchedDocument != null && !reset) {
        query = query.startAfterDocument(_lastFetchedDocument!);
      }

      // Use cache settings if possible
      final snapshot = await query.get(const GetOptions(source: Source.serverAndCache));
      
      if (snapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _hasMore = false;
        });
        return;
      }

      _lastFetchedDocument = snapshot.docs.last;
      
      List<Map<String, dynamic>> newUsers = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final email = data['email']?.toString() ?? '';
        if (email.isNotEmpty && email.toLowerCase() != 'yusfkarim2001@gmail.com') {
          DateTime? startDate;
          
          if (data['recoveryStartDate'] != null) {
            if (data['recoveryStartDate'] is Timestamp) {
              startDate = (data['recoveryStartDate'] as Timestamp).toDate();
            }
          }

          // Calculate total days
          int totalDays = 0;
          if (startDate != null) {
            totalDays = now.difference(startDate).inDays;
            if (totalDays < 0) totalDays = 0;
          }

          // Get bonus days from previous streaks (halved on relapse)
          int bonusDays = data['bonusDays'] ?? 0;
          int effectiveDays = totalDays + bonusDays;

          // Calculate XP and Level from EFFECTIVE DAYS (current streak + bonus)
          // 100 XP per day, 10 days per level, max Level 100
          int totalXP = XPService.calculateXPFromDays(effectiveDays);
          int level = XPService.calculateLevelFromDays(effectiveDays);
          
          // For period filtering - filter users based on when they started
          bool includeUser = true;
          
          if (_currentFilter == LeaderboardFilter.weekly) {
            // ONLY show users who started recovery in the last 7 days
            includeUser = startDate != null && startDate.isAfter(weekAgo);
          } else if (_currentFilter == LeaderboardFilter.monthly) {
            // ONLY show users who started recovery in the last 30 days
            includeUser = startDate != null && startDate.isAfter(monthAgo);
          } else if (_currentFilter == LeaderboardFilter.quarterly) {
            // ONLY show users who started recovery in the last 90 days (3 months)
            includeUser = startDate != null && startDate.isAfter(quarterAgo);
          }
          // allTime: show everyone

          if (includeUser) {
            newUsers.add({
              'userId': doc.id,
              'email': email,
              'displayName': data['displayName'] ?? data['email']?.toString().split('@').first ?? 'User',
              'photoURL': data['photoURL'],
              'totalDays': totalDays,
              'effectiveDays': effectiveDays,
              'bonusDays': bonusDays,
              'startDate': startDate,
              'totalXP': totalXP,
              'level': level,
            });
          }
        }
      }

      // Sort new users batch to match totalDays descending logic (though query does it)
      newUsers.sort((a, b) => (b['totalDays'] as int).compareTo(a['totalDays'] as int));

      setState(() {
        if (reset) {
          _leaderboard = newUsers;
        } else {
          _leaderboard.addAll(newUsers);
        }
        _isLoading = false;
        _isLoadingMore = false;
        _hasMore = snapshot.docs.length >= _usersBatchSize;
      });
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  String _getTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'لوحة الصدارة';
      case AppLanguage.kurdish: return 'پلەی پێشەوان';
      case AppLanguage.english: return 'Leaderboard';
    }
  }

  String _getDaysLabel(int days, LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return '$days يوم';
      case AppLanguage.kurdish: return '$days ڕۆژ';
      case AppLanguage.english: return '$days days';
    }
  }

  String _getWeeklyText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'أسبوعي';
      case AppLanguage.kurdish: return 'هەفتانە';
      case AppLanguage.english: return 'Weekly';
    }
  }

  String _getMonthlyText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'شهري';
      case AppLanguage.kurdish: return 'مانگانە';
      case AppLanguage.english: return 'Monthly';
    }
  }

  String _getQuarterlyText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return '٣ أشهر';
      case AppLanguage.kurdish: return '٣ مانگ';
      case AppLanguage.english: return '3 Months';
    }
  }

  String _getAllTimeText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'الكل';
      case AppLanguage.kurdish: return 'هەمیشەیی';
      case AppLanguage.english: return 'All Time';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1: return const Color(0xFFFFD700); // Gold
      case 2: return const Color(0xFFC0C0C0); // Silver
      case 3: return const Color(0xFFCD7F32); // Bronze
      default: return const Color(0xFF4facfe);
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1: return Icons.emoji_events;
      case 2: return Icons.workspace_premium;
      case 3: return Icons.military_tech;
      default: return Icons.star_outline;
    }
  }

  bool get _isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final email = user.email?.toLowerCase();
    return email != null && TipsService.adminEmails.any((e) => e.toLowerCase() == email);
  }

  bool get _isGuest {
    final user = FirebaseAuth.instance.currentUser;
    return user == null || user.isAnonymous;
  }

  int? get _currentUserRank {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return null;
    
    for (int i = 0; i < _leaderboard.length; i++) {
      if (_leaderboard[i]['userId'] == user.uid) {
        return i + 1; // 1-indexed rank
      }
    }
    return null;
  }

  Map<String, dynamic>? get _currentUserData {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return null;
    
    for (var userData in _leaderboard) {
      if (userData['userId'] == user.uid) {
        return userData;
      }
    }
    return null;
  }

  void _showEditDaysDialog(Map<String, dynamic> user, LanguageService lang) {
    final isDark = lang.isDarkMode;
    final currentDays = user['totalDays'] as int;
    final controller = TextEditingController(text: currentDays.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.edit, color: const Color(0xFF4facfe)),
            const SizedBox(width: 8),
            Text(
              lang.currentLanguage == AppLanguage.kurdish ? 'دەستکاری ڕۆژەکان' :
              lang.currentLanguage == AppLanguage.arabic ? 'تعديل الأيام' : 'Edit Days',
              style: lang.getTextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user['displayName'] ?? 'User',
              style: lang.getTextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: lang.getTextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: lang.currentLanguage == AppLanguage.kurdish ? 'ژمارەی ڕۆژەکان' :
                           lang.currentLanguage == AppLanguage.arabic ? 'عدد الأيام' : 'Number of Days',
                labelStyle: lang.getTextStyle(color: isDark ? Colors.white54 : Colors.black45),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4facfe), width: 2),
                ),
                prefixIcon: Icon(Icons.calendar_today, color: const Color(0xFF4facfe)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              lang.currentLanguage == AppLanguage.kurdish ? 'پاشگەزبوونەوە' :
              lang.currentLanguage == AppLanguage.arabic ? 'إلغاء' : 'Cancel',
              style: lang.getTextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newDays = int.tryParse(controller.text);
              if (newDays != null && newDays >= 0) {
                await _updateUserDays(user['userId'], newDays);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4facfe),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              lang.currentLanguage == AppLanguage.kurdish ? 'پاشەکەوتکردن' :
              lang.currentLanguage == AppLanguage.arabic ? 'حفظ' : 'Save',
              style: lang.getTextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserDays(String userId, int newDays) async {
    try {
      // Calculate the new start date based on desired days
      final newStartDate = DateTime.now().subtract(Duration(days: newDays));
      
      await _firestore.collection('users').doc(userId).update({
        'recoveryStartDate': Timestamp.fromDate(newStartDate),
      });
      
      // Reload leaderboard
      await _loadLeaderboard();
    } catch (e) {
      debugPrint('Error updating user days: $e');
    }
  }

  void _showUserProfileDialog(Map<String, dynamic> user, LanguageService lang) {
    final isDark = lang.isDarkMode;
    final totalDays = user['totalDays'] as int;
    final earnedBadges = BadgesService.getEarnedBadges(totalDays);
    final highestBadge = BadgesService.getHighestBadge(totalDays);
    final nextBadge = BadgesService.getNextBadge(totalDays);
    final daysUntilNext = BadgesService.daysUntilNextBadge(totalDays);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0a1628) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
              ),
              // Header with user info
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Avatar with badge
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [highestBadge?.color ?? const Color(0xFF4facfe), const Color(0xFF00f2fe)]),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
                            backgroundImage: user['photoURL'] != null && user['photoURL'].toString().isNotEmpty
                                ? NetworkImage(user['photoURL'])
                                : null,
                            child: user['photoURL'] == null || user['photoURL'].toString().isEmpty
                                ? Icon(Icons.person, size: 50, color: highestBadge?.color ?? const Color(0xFF4facfe))
                                : null,
                          ),
                        ),
                        if (highestBadge != null)
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? const Color(0xFF0a1628) : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Image.asset(
                                'assets/images/badge_level_${highestBadge.level}.png',
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        // Admin-only photo edit button
                        if (_isAdmin)
                          Positioned(
                            top: 0, left: 0,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                _showEditPhotoDialog(user, lang);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4facfe),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isDark ? const Color(0xFF0a1628) : Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(user['displayName'] ?? 'User', style: lang.getTextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]), borderRadius: BorderRadius.circular(20)),
                      child: Text(_getDaysLabel(totalDays, lang), style: lang.getTextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    if (nextBadge != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        lang.currentLanguage == AppLanguage.kurdish ? '$daysUntilNext ڕۆژ تا ${nextBadge.nameKu}' :
                        lang.currentLanguage == AppLanguage.arabic ? '$daysUntilNext يوم حتى ${nextBadge.nameAr}' :
                        '$daysUntilNext days until ${nextBadge.nameEn}',
                        style: lang.getTextStyle(fontSize: 13, color: nextBadge.color),
                      ),
                    ],
                  ],
                ),
              ),
              // Badges Section Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: const Color(0xFFFFD700), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      lang.currentLanguage == AppLanguage.kurdish ? 'ئۆسمەکان (${earnedBadges.length})' :
                      lang.currentLanguage == AppLanguage.arabic ? 'الأوسمة (${earnedBadges.length})' :
                      'Badges (${earnedBadges.length})',
                      style: lang.getTextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Badges Grid
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 120),
                  children: [
                    Wrap(
                      spacing: 12, runSpacing: 12,
                      children: earnedBadges.map((badge) => _buildBadgeItem(badge, lang, isDark)).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Certificate Section
                    if (earnedBadges.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [highestBadge!.color.withOpacity(0.15), highestBadge.color.withOpacity(0.05)]),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: highestBadge.color.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.card_membership, size: 50, color: highestBadge.color),
                            const SizedBox(height: 12),
                            Text(
                              lang.currentLanguage == AppLanguage.kurdish ? 'بڕوانامەی سەرکەوتن' :
                              lang.currentLanguage == AppLanguage.arabic ? 'شهادة الإنجاز' :
                              'Achievement Certificate',
                              style: lang.getTextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              lang.currentLanguage == AppLanguage.kurdish ? highestBadge.nameKu :
                              lang.currentLanguage == AppLanguage.arabic ? highestBadge.nameAr :
                              highestBadge.nameEn,
                              style: lang.getTextStyle(fontSize: 16, color: highestBadge.color, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(user['displayName'] ?? 'User', style: lang.getTextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeItem(AchievementBadge badge, LanguageService lang, bool isDark) {
    final name = lang.currentLanguage == AppLanguage.kurdish ? badge.nameKu :
                 lang.currentLanguage == AppLanguage.arabic ? badge.nameAr : badge.nameEn;
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: badge.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badge.color.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/badge_level_${badge.level}.png',
            width: 44,
            height: 44,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          Text(name, style: lang.getTextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  void _showEditPhotoDialog(Map<String, dynamic> user, LanguageService lang) {
    final isDark = lang.isDarkMode;
    final currentUrl = user['photoURL']?.toString() ?? '';
    final controller = TextEditingController(text: currentUrl);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.camera_alt, color: Color(0xFF4facfe)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                lang.currentLanguage == AppLanguage.kurdish ? 'گۆڕینی وێنەی پڕۆفایل' :
                lang.currentLanguage == AppLanguage.arabic ? 'تغيير صورة الملف الشخصي' : 'Change Profile Photo',
                style: lang.getTextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user['displayName'] ?? 'User',
              style: lang.getTextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: lang.getTextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'URL',
                labelStyle: lang.getTextStyle(color: isDark ? Colors.white54 : Colors.black45),
                hintText: 'https://...',
                hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4facfe), width: 2),
                ),
                prefixIcon: const Icon(Icons.link, color: Color(0xFF4facfe)),
              ),
            ),
          ],
        ),
        actions: [
          // Delete photo button
          TextButton(
            onPressed: () async {
              await _firestore.collection('users').doc(user['userId']).update({
                'photoURL': FieldValue.delete(),
              });
              Navigator.pop(context);
              _loadLeaderboard();
            },
            child: Text(
              lang.currentLanguage == AppLanguage.kurdish ? 'سڕینەوە' :
              lang.currentLanguage == AppLanguage.arabic ? 'حذف' : 'Delete',
              style: lang.getTextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              lang.currentLanguage == AppLanguage.kurdish ? 'پاشگەزبوونەوە' :
              lang.currentLanguage == AppLanguage.arabic ? 'إلغاء' : 'Cancel',
              style: lang.getTextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                await _firestore.collection('users').doc(user['userId']).update({
                  'photoURL': url,
                });
                Navigator.pop(context);
                _loadLeaderboard();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4facfe),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              lang.currentLanguage == AppLanguage.kurdish ? 'پاشەکەوتکردن' :
              lang.currentLanguage == AppLanguage.arabic ? 'حفظ' : 'Save',
              style: lang.getTextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = lang.isDarkMode;

    return Directionality(
      textDirection: lang.textDirection,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0a1628) : const Color(0xFFf5f5f5),
        bottomNavigationBar: _buildBottomRankBar(lang, isDark),
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Beautiful Header
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(lang.isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios, color: Colors.white, size: 18),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                // Search button for admin only
                if (_isAdmin)
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white, size: 20),
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchQuery = '';
                          _searchController.clear();
                        }
                      });
                    },
                  ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -50,
                        left: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      // Title and Trophy
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.emoji_events, color: Colors.white, size: 45),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _getTitle(lang),
                              style: lang.getTextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Statistics Section - Total Users & Users with Started Counter (Admin only)
            if (!_isLoading && _isAdmin)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Total Users Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF667eea).withOpacity(isDark ? 0.3 : 0.15),
                                const Color(0xFF764ba2).withOpacity(isDark ? 0.2 : 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF667eea).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF667eea).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.people, color: Color(0xFF667eea), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_leaderboard.length}',
                                      style: lang.getTextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      lang.currentLanguage == AppLanguage.kurdish ? 'کۆی بەکارهێنەران' :
                                      lang.currentLanguage == AppLanguage.arabic ? 'إجمالي المستخدمين' : 'Total Users',
                                      style: lang.getTextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Users with Started Counter Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF00b894).withOpacity(isDark ? 0.3 : 0.15),
                                const Color(0xFF00cec9).withOpacity(isDark ? 0.2 : 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF00b894).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00b894).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.play_circle_filled, color: Color(0xFF00b894), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_leaderboard.where((u) => (u['totalDays'] as int) > 0).length}',
                                      style: lang.getTextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      lang.currentLanguage == AppLanguage.kurdish ? 'بدء عداد کردوون' :
                                      lang.currentLanguage == AppLanguage.arabic ? 'بدء العداد' : 'Started Counter',
                                      style: lang.getTextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Tab Bar for filtering (Weekly, Monthly, All-time)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? Colors.white60 : Colors.grey,
                  labelStyle: lang.getTextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: lang.getTextStyle(fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: _getWeeklyText(lang)),
                    Tab(text: _getMonthlyText(lang)),
                    Tab(text: _getQuarterlyText(lang)),
                    Tab(text: _getAllTimeText(lang)),
                  ],
                ),
              ),
            ),
            
            // Search field for admin (when searching)
            if (_isAdmin && _isSearching)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    textDirection: lang.textDirection,
                    decoration: InputDecoration(
                      hintText: lang.currentLanguage == AppLanguage.kurdish ? 'گەڕان بەدوای بەکارهێنەر...' :
                                lang.currentLanguage == AppLanguage.arabic ? 'البحث عن مستخدم...' : 'Search user...',
                      hintStyle: lang.getTextStyle(color: isDark ? Colors.white38 : Colors.grey),
                      prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: isDark ? Colors.white54 : Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
              ),

            // Loading or Content
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Color(0xFF4facfe))),
              )
            else if (_leaderboard.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 80, color: isDark ? Colors.white24 : Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        lang.currentLanguage == AppLanguage.kurdish ? 'هیچ بەکارهێنەرێک نەدۆزرایەوە' :
                        lang.currentLanguage == AppLanguage.arabic ? 'لم يتم العثور على مستخدمين' : 'No users found',
                        style: lang.getTextStyle(fontSize: 18, color: isDark ? Colors.white38 : Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else ...[

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final users = _filteredLeaderboard;
                      
                      // Loader at the bottom
                      if (index == users.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final user = users[index];
                      final rank = _leaderboard.indexOf(user) + 1; // Use original rank
                      final rankColor = _getRankColor(rank);
                      final isTopThree = rank <= 3;
                      final totalDays = user['totalDays'] as int;
                      final highestBadge = BadgesService.getHighestBadge(totalDays);
                      final earnedBadges = BadgesService.getEarnedBadges(totalDays);

                      return GestureDetector(
                        onTap: () => _showUserProfileDialog(user, lang),
                        child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: isTopThree
                              ? LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    rankColor.withOpacity(0.2),
                                    rankColor.withOpacity(0.08),
                                    isDark ? const Color(0xFF1a2a4a) : Colors.white,
                                  ],
                                  stops: const [0.0, 0.3, 1.0],
                                )
                              : null,
                          color: isTopThree ? null : (isDark ? const Color(0xFF1a2a4a) : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isTopThree ? rankColor.withOpacity(0.6) : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.15)),
                            width: isTopThree ? 2.5 : 1,
                          ),
                          boxShadow: [
                            if (isTopThree)
                              BoxShadow(color: rankColor.withOpacity(0.35), blurRadius: 20, spreadRadius: 0, offset: const Offset(0, 6))
                            else
                              BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 15, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Rank Number - Left Side (Big & Beautiful)
                            Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isTopThree
                                      ? [rankColor.withOpacity(0.9), rankColor]
                                      : [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: (isTopThree ? rankColor : const Color(0xFF4facfe)).withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Center(
                                child: isTopThree
                                    ? Icon(_getRankIcon(rank), color: Colors.white, size: 28)
                                    : Text(
                                        '$rank',
                                        style: lang.getTextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Avatar
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [rankColor, const Color(0xFF4facfe)]),
                                boxShadow: [BoxShadow(color: rankColor.withOpacity(0.3), blurRadius: 8)],
                              ),
                              child: CircleAvatar(
                                radius: 26,
                                backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
                                backgroundImage: user['photoURL'] != null && user['photoURL'].toString().isNotEmpty
                                    ? NetworkImage(user['photoURL'])
                                    : null,
                                child: user['photoURL'] == null || user['photoURL'].toString().isEmpty
                                    ? Icon(Icons.person, color: rankColor, size: 28)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Name & Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['displayName'] ?? 'User',
                                    style: lang.getTextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.local_fire_department_rounded, size: 14, color: rankColor),
                                          const SizedBox(width: 2),
                                          Text(
                                            _getDaysLabel(user['totalDays'], lang),
                                            style: lang.getTextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: rankColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // XP and Level display
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF00BCD4).withOpacity(0.25),
                                              const Color(0xFF26A69A).withOpacity(0.25),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFF00BCD4).withOpacity(0.4),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          '${XPService.getLevelEmoji(user['level'] ?? 1)} Lv.${user['level'] ?? 1}',
                                          style: lang.getTextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? const Color(0xFF4DD0E1) : const Color(0xFF00838F),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Badges Display
                            if (highestBadge != null)
                              Column(
                                children: [
                                  Image.asset(
                                    'assets/images/badge_level_${highestBadge.level}.png',
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${earnedBadges.length}', style: lang.getTextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: highestBadge.color)),
                                ],
                              ),
                            // Admin Edit Button
                            if (_isAdmin)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: GestureDetector(
                                  onTap: () => _showEditDaysDialog(user, lang),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.orange.withOpacity(0.4)),
                                    ),
                                    child: const Icon(Icons.edit, color: Colors.orange, size: 18),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        ),
                      );
                    },
                    childCount: _filteredLeaderboard.length + (_isLoadingMore ? 1 : 0),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildBottomRankBar(LanguageService lang, bool isDark) {
    if (_isLoading) return null;

    // Guest user - show account creation prompt
    if (_isGuest) {
      return Container(
        padding: const EdgeInsets.all(16),
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
        child: SafeArea(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.info_outline, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGuestPromptTitle(lang),
                      style: lang.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      _getGuestPromptSubtitle(lang),
                      style: lang.getTextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getCreateAccountText(lang),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Logged in user - show their rank
    final rank = _currentUserRank;
    final userData = _currentUserData;
    
    if (rank == null || userData == null) return null;

    final rankColor = _getRankColor(rank);
    final totalDays = userData['totalDays'] as int;
    final totalUsers = _leaderboard.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            rankColor.withOpacity(isDark ? 0.3 : 0.15),
            isDark ? const Color(0xFF1a2a4a) : Colors.white,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Rank Number
            Container(
              constraints: const BoxConstraints(minWidth: 50),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [rankColor, rankColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: rankColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: rank > 999 ? 14 : 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // User Info + Top X from Y
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getRankIcon(rank), color: rankColor, size: 18),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          userData['displayName'] ?? 'You',
                          style: lang.getTextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lang.currentLanguage == AppLanguage.kurdish
                        ? 'تۆپ $rank'
                        : lang.currentLanguage == AppLanguage.arabic
                            ? 'المركز $rank'
                            : 'Top $rank',
                    style: lang.getTextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            // Days
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: rankColor.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department, color: rankColor, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    _getDaysLabel(totalDays, lang),
                    style: lang.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: rankColor,
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

  String _getYourRankText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'ترتيبك';
      case AppLanguage.kurdish: return 'پلەی تۆ';
      case AppLanguage.english: return 'Your Rank';
    }
  }

  String _getGuestPromptTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'سجل دخولك لتظهر هنا!';
      case AppLanguage.kurdish: return 'چوونەژوورەوە بکە بۆ دەرکەوتن!';
      case AppLanguage.english: return 'Sign in to appear here!';
    }
  }

  String _getGuestPromptSubtitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'أنشئ حساب لتظهر في لوحة الصدارة';
      case AppLanguage.kurdish: return 'ئەکاونت دروستبکە بۆ دەرکەوتن لە لوحە الصدارە';
      case AppLanguage.english: return 'Create an account to appear on the leaderboard';
    }
  }

  String _getCreateAccountText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إنشاء حساب';
      case AppLanguage.kurdish: return 'ئەکاونت دروستبکە';
      case AppLanguage.english: return 'Sign Up';
    }
  }
}
