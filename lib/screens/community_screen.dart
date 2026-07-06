import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../services/language_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/private_message_service.dart';
import '../services/cloud_storage_service.dart';
import '../services/web_audio_recorder.dart';
import '../widgets/reactions_widget.dart';
import '../widgets/web_audio_player_widget.dart';
import 'private_messages_screen.dart';
import 'private_chat_screen.dart';
import 'zego_call_screen.dart';
import '../services/call_room_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _messageController = TextEditingController();
  final _itemScrollController = ItemScrollController();
  final _itemPositionsListener = ItemPositionsListener.create();
  final _chatService = ChatService();
  final _privateMessageService = PrivateMessageService();
  final _authService = AuthService();
  final _callRoomService = CallRoomService();
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _showScrollToBottom = false;
  int _currentLimit = 20;
  bool _isLoadingMore = false;
  StreamSubscription? _userSubscription;
  ChatMessage? _replyToMessage; // Message being replied to
  String? _highlightedMessageId; // For reply scroll highlight
  List<ChatMessage> _cachedMessages = []; // Cache messages for tap-to-scroll
  
  // Voice recording
  final _cloudStorage = CloudStorageService();
  final _audioRecorder = WebAudioRecorder();
  bool _isRecording = false;
  bool _isUploadingAudio = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _itemPositionsListener.itemPositions.addListener(_onScroll);
    // Clean up any empty call rooms on startup
    _callRoomService.cleanupEmptyRooms();
  }

  void _onScroll() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      bool isBottomVisible = positions.any((p) => p.index == 0 && p.itemLeadingEdge < 0.1);
      if (!isBottomVisible != _showScrollToBottom) {
        setState(() => _showScrollToBottom = !isBottomVisible);
      }
      
      // Pagination: Check if we are near the top (index messages.length - 1)
      final lastVisibleIndex = positions
          .map((p) => p.index)
          .reduce((max, index) => index > max ? index : max);
          
      if (lastVisibleIndex >= _cachedMessages.length - 5 && !_isLoadingMore && _cachedMessages.length >= _currentLimit) {
        _loadMoreMessages();
      }
    }
  }

  void _loadMoreMessages() {
    if (!mounted) return;
    setState(() {
      _isLoadingMore = true;
      _currentLimit += 20;
    });
    
    // Reset loading flag after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _isLoadingMore = false);
    });
  }

  Future<void> _initializeUser() async {
    await _chatService.initializeUserRole();
    // Clean up old empty call rooms
    await _callRoomService.cleanupEmptyRooms();
    // Listen to user changes
    _userSubscription = _chatService.getCurrentUserStream().listen((user) {
      if (mounted) setState(() {});
    });
    if (mounted) setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _itemPositionsListener.itemPositions.removeListener(_onScroll);
    _userSubscription?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: 0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToMessage(String messageId) {
    final index = _cachedMessages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
    
    // Highlight the message briefly
    setState(() => _highlightedMessageId = messageId);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _highlightedMessageId = null);
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Check if user is muted or blocked
    if (_chatService.isCurrentUserMuted) {
      if (mounted) {
        final lang = Provider.of<LanguageService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getMutedMessage(lang)),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (_chatService.isCurrentUserBlocked) {
      if (mounted) {
        final lang = Provider.of<LanguageService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getBlockedMessage(lang)),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    _messageController.clear();
    final replyTo = _replyToMessage;
    
    setState(() {
      _replyToMessage = null; // Clear reply after sending
    });

    _chatService.sendMessage(text, replyTo: replyTo).then((success) {
      if (!success && mounted) {
        final lang = Provider.of<LanguageService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getBlockedMessage(lang)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    });

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  Future<void> _startRecording() async {
    final errorMsg = await _audioRecorder.startRecording();
    if (errorMsg == null) {
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _recordingSeconds++);
        }
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _stopAndSendRecording() async {
    _recordingTimer?.cancel();
    final duration = _recordingSeconds;
    
    if (duration < 1) {
      _cancelRecording();
      return;
    }
    
    setState(() {
      _isRecording = false;
      _isUploadingAudio = true;
    });

    try {
      final audioBytes = await _audioRecorder.stopRecording();
      if (audioBytes == null || audioBytes.isEmpty) {
        setState(() => _isUploadingAudio = false);
        return;
      }

      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.webm';
      final audioUrl = await _cloudStorage.uploadAudioBytes(audioBytes, fileName);
      
      if (audioUrl != null && mounted) {
        await _chatService.sendAudioMessage(audioUrl, duration, replyTo: _replyToMessage);
        setState(() => _replyToMessage = null);
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    } catch (e) {
      debugPrint('Error sending voice: $e');
    } finally {
      if (mounted) setState(() => _isUploadingAudio = false);
    }
  }

  void _cancelRecording() {
    _recordingTimer?.cancel();
    _audioRecorder.cancelRecording();
    setState(() {
      _isRecording = false;
      _recordingSeconds = 0;
    });
  }

  String _formatRecordingTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = lang.isDarkMode;
    final currentUserId = _authService.currentUser?.uid ?? '';
    final isAdmin = _chatService.isCurrentUserAdmin;
    final isModerator = _chatService.isCurrentUserModerator;
    final isMuted = _chatService.isCurrentUserMuted;

    return Directionality(
      textDirection: lang.textDirection,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0a1628) : const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                lang.isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
            ),
          ),
          title: GestureDetector(
            onLongPress: () => _showDeveloperActivationDialog(lang, isDark),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.forum_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.currentLanguage == AppLanguage.arabic 
                          ? 'المجتمع' 
                          : lang.currentLanguage == AppLanguage.kurdish 
                              ? 'کۆمەڵگا' 
                              : 'Community',
                      style: lang.getTextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    // Show role badge
                    if (isAdmin || isModerator)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isAdmin ? Colors.teal.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAdmin ? _getDeveloperText(lang) : _getModeratorText(lang),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isAdmin ? Colors.teal : Colors.blue,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            // Private Messages Inbox
            StreamBuilder<int>(
              stream: _privateMessageService.getUnreadCount(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PrivateMessagesScreen()),
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0D9488).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.chat_bubble_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 4,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? const Color(0xFF0a1628) : Colors.white, width: 2),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            // Voice Call Button for Community
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ZegoCallScreen(
                    roomName: lang.currentLanguage == AppLanguage.arabic 
                        ? 'المجتمع' 
                        : lang.currentLanguage == AppLanguage.kurdish 
                            ? 'کۆمەڵگا' 
                            : 'Community',
                    displayName: _authService.currentUser?.displayName ?? 'User',
                    odaID: 'community_main',
                    isVideoCall: false,
                    roomType: 'community',
                    groupId: '',
                  ),
                ),
              ),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.call, color: Colors.white, size: 16),
              ),
            ),
            // Video Call Button for Community
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ZegoCallScreen(
                    roomName: lang.currentLanguage == AppLanguage.arabic 
                        ? 'المجتمع' 
                        : lang.currentLanguage == AppLanguage.kurdish 
                            ? 'کۆمەڵگا' 
                            : 'Community',
                    displayName: _authService.currentUser?.displayName ?? 'User',
                    odaID: 'community_main',
                    isVideoCall: true,
                    roomType: 'community',
                    groupId: '',
                  ),
                ),
              ),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.videocam, color: Colors.white, size: 16),
              ),
            ),
            // Admin/Mod panel button
            if (isAdmin || isModerator)
              IconButton(
                icon: Icon(
                  Icons.admin_panel_settings, 
                  color: isAdmin ? Colors.amber : Colors.blue,
                ),
                onPressed: () => _showAdminPanel(lang, isDark, isAdmin),
              ),
          ],
        ),
        body: Column(
          children: [
            // Muted Warning Banner
            if (isMuted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  border: Border(bottom: BorderSide(color: Colors.orange.withOpacity(0.3))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.volume_off, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getMutedBannerText(lang),
                        style: lang.getTextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Active Call Rooms Banner - Compact Design
            StreamBuilder<List<CallRoom>>(
              stream: _callRoomService.getCommunityRooms(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                final activeRooms = snapshot.data!;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF4facfe).withOpacity(0.15), const Color(0xFF00f2fe).withOpacity(0.15)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4facfe).withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.videocam, color: Colors.white, size: 14),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.currentLanguage == AppLanguage.arabic 
                                        ? 'المكالمات النشطة' 
                                        : lang.currentLanguage == AppLanguage.kurdish 
                                            ? 'پەیوەندییە چالاکەکان' 
                                            : 'Active Calls',
                                    style: lang.getTextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '${activeRooms.length} ${lang.currentLanguage == AppLanguage.arabic ? 'مكالمة' : lang.currentLanguage == AppLanguage.kurdish ? 'پەیوەندی' : 'call(s)'}',
                                    style: lang.getTextStyle(
                                      fontSize: 10,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Live indicator - compact
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // List of active rooms
                      ...activeRooms.map((room) => GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ZegoCallScreen(
                              roomName: room.name,
                              displayName: _authService.currentUser?.displayName ?? 'User',
                              odaID: room.id,
                              isVideoCall: room.isVideoCall,
                              roomType: room.roomType,
                              groupId: room.groupId,
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: const Color(0xFF4facfe).withOpacity(0.2))),
                          ),
                          child: Row(
                            children: [
                              // Participants avatars - smaller
                              SizedBox(
                                width: 48,
                                height: 24,
                                child: Stack(
                                  children: [
                                    for (int i = 0; i < room.participants.length.clamp(0, 3); i++)
                                      Positioned(
                                        left: i * 14.0,
                                        child: CircleAvatar(
                                          radius: 12,
                                          backgroundColor: [Colors.blue, Colors.green, Colors.teal][i % 3],
                                          child: Text(
                                            room.participants[i].name.isNotEmpty 
                                                ? room.participants[i].name[0].toUpperCase() 
                                                : '?',
                                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      room.name,
                                      style: lang.getTextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${room.participantCount} ${lang.currentLanguage == AppLanguage.arabic ? 'مشارك' : lang.currentLanguage == AppLanguage.kurdish ? 'بەشداربوو' : 'participants'}',
                                      style: lang.getTextStyle(
                                        fontSize: 9,
                                        color: isDark ? Colors.white54 : Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Join button - compact for mobile
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4facfe).withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(room.isVideoCall ? Icons.videocam : Icons.call, color: Colors.white, size: 12),
                                    const SizedBox(width: 3),
                                    Text(
                                      lang.currentLanguage == AppLanguage.arabic 
                                          ? 'انضم' 
                                          : lang.currentLanguage == AppLanguage.kurdish 
                                              ? 'داخڵبە' 
                                              : 'Join',
                                      style: lang.getTextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ],
                  ),
                );
              },
            ),

            // Pinned Messages Bar
            StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getPinnedMessages(),
              builder: (context, snapshot) {
                // Handle errors silently for pinned messages
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                final pinnedMessages = snapshot.data!;
                return GestureDetector(
                  onTap: () => _showPinnedMessages(pinnedMessages, lang, isDark),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1a2a4a) : Colors.amber.shade50,
                      border: Border(bottom: BorderSide(color: Colors.amber.withOpacity(0.3))),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.push_pin, color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 40),
                            child: SingleChildScrollView(
                              child: Text(
                                pinnedMessages.first.text,
                                style: lang.getTextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                        if (isAdmin || isModerator)
                          GestureDetector(
                            onTap: () async {
                              await _chatService.unpinMessage(pinnedMessages.first.id);
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(Icons.close, color: Colors.red, size: 20),
                            ),
                          ),
                        if (pinnedMessages.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${pinnedMessages.length - 1}',
                              style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        Icon(
                          lang.isRTL ? Icons.chevron_left : Icons.chevron_right,
                          color: Colors.amber,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // Messages List with Scroll to Bottom Button
            Expanded(
              child: Stack(
                children: [
                  StreamBuilder<List<ChatMessage>>(
                    stream: _chatService.getMessages(limit: _currentLimit),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                              const SizedBox(height: 16),
                              Text(
                                'Error: ${snapshot.error}',
                                style: lang.getTextStyle(color: Colors.red, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting && !_isInitialized) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 80, color: isDark ? Colors.white24 : Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                lang.currentLanguage == AppLanguage.arabic 
                                    ? 'لا توجد رسائل بعد' 
                                    : lang.currentLanguage == AppLanguage.kurdish 
                                        ? 'هێشتا هیچ نامەیەک نییە' 
                                        : 'No messages yet',
                                style: lang.getTextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }

                      final List<ChatMessage> messages = snapshot.data!;
                      _cachedMessages = messages; // Cache for tap-to-scroll

                      return ScrollablePositionedList.builder(
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final message = messages[index];
                          final isOwnMessage = message.senderId == currentUserId;
                          
                          // Check if this message is a reply to one of the current user's messages
                          bool isReplyToMe = false;
                          if (message.isReply && message.replyToId != null && !isOwnMessage) {
                            final originalMsg = messages.where((m) => m.id == message.replyToId).toList();
                            if (originalMsg.isNotEmpty && originalMsg.first.senderId == currentUserId) {
                              isReplyToMe = true;
                            }
                          }

                          return _buildMessageBubble(message, isOwnMessage, isAdmin, isModerator, lang, isDark, isReplyToMe: isReplyToMe);
                        },
                      );
                    },
                  ),
                  // Scroll to Bottom Floating Button (like Telegram)
                  if (_showScrollToBottom)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: GestureDetector(
                        onTap: () {
                          _scrollToBottom();
                          setState(() => _showScrollToBottom = false);
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0D9488).withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.keyboard_double_arrow_down_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Input Area with Reply Preview
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reply Preview Bar
                if (_replyToMessage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1a2a4a) : Colors.grey[100],
                      border: Border(
                        left: BorderSide(color: Colors.blue, width: 4),
                        bottom: BorderSide(color: isDark ? Colors.white12 : Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.reply, color: Colors.blue, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _replyToMessage!.senderName,
                                style: lang.getTextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                _replyToMessage!.text,
                                style: lang.getTextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.grey[600]!,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: isDark ? Colors.white54 : Colors.grey),
                          onPressed: () => setState(() => _replyToMessage = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                
                // Main Input Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1a2a4a) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
              child: SafeArea(
                child: _isRecording 
                  // RECORDING MODE
                  ? Row(
                      children: [
                        // Cancel button
                        GestureDetector(
                          onTap: _cancelRecording,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Recording indicator
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 10, height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 6)],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _formatRecordingTime(_recordingSeconds),
                                  style: lang.getTextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  lang.currentLanguage == AppLanguage.kurdish ? 'تۆمارکردن...' :
                                  lang.currentLanguage == AppLanguage.arabic ? 'تسجيل...' : 'Recording...',
                                  style: lang.getTextStyle(fontSize: 12, color: Colors.red.withOpacity(0.7)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Send recording button
                        GestureDetector(
                          onTap: _stopAndSendRecording,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)]),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(Icons.send, color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  // NORMAL TEXT MODE
                  : Row(
                      children: [
                        // Mic button
                        if (!isMuted)
                          GestureDetector(
                            onTap: _isUploadingAudio ? null : _startRecording,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _isUploadingAudio 
                                    ? Colors.grey.withOpacity(0.15)
                                    : const Color(0xFF4facfe).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: _isUploadingAudio
                                  ? const SizedBox(
                                      width: 24, height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4facfe)),
                                    )
                                  : const Icon(Icons.mic, color: Color(0xFF4facfe), size: 24),
                            ),
                          ),
                        if (!isMuted) const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            textDirection: lang.textDirection,
                            enabled: !isMuted,
                            minLines: 2,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: isMuted 
                                  ? _getMutedHintText(lang)
                                  : (lang.currentLanguage == AppLanguage.arabic 
                                      ? 'اكتب رسالة...' 
                                      : lang.currentLanguage == AppLanguage.kurdish 
                                          ? 'نامەیەک بنووسە...' 
                                          : 'Type a message...'),
                              hintStyle: lang.getTextStyle(
                                color: isMuted ? Colors.orange : (isDark ? Colors.white38 : Colors.grey),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isMuted 
                                  ? Colors.orange.withOpacity(0.1) 
                                  : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100]),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: (_isLoading || isMuted) ? null : _sendMessage,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: isMuted 
                                  ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                                  : const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)]),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Icon(
                                    isMuted ? Icons.volume_off : Icons.send,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ],
                ),
              ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isOwnMessage, bool isAdmin, bool isModerator, LanguageService lang, bool isDark, {bool isReplyToMe = false}) {
    final senderIsAdmin = message.senderRole == UserRole.admin;
    final senderIsModerator = message.senderRole == UserRole.moderator;
    final isHighlighted = _highlightedMessageId == message.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reply-to-you indicator (like Telegram @)
        if (isReplyToMe)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 48),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4facfe).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF4facfe).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.reply, size: 12, color: Color(0xFF4facfe)),
                      const SizedBox(width: 4),
                      Text(
                        lang.currentLanguage == AppLanguage.kurdish ? '${message.senderName} ڕیپلەی بۆ تۆی کرد' :
                        lang.currentLanguage == AppLanguage.arabic ? '${message.senderName} رد عليك' :
                        '${message.senderName} replied to you',
                        style: lang.getTextStyle(fontSize: 10, color: const Color(0xFF4facfe), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Dismissible(
      key: Key('swipe_${message.id}'),
      direction: DismissDirection.startToEnd, // Swipe right
      dismissThresholds: const {DismissDirection.startToEnd: 0.15}, // Only 15% swipe needed
      movementDuration: const Duration(milliseconds: 100),
      confirmDismiss: (direction) async {
        // Set reply and return false (don't dismiss)
        setState(() => _replyToMessage = message);
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.reply, color: Colors.blue, size: 20),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(message, isOwnMessage, isAdmin, isModerator, lang, isDark),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isHighlighted ? Colors.blue.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isOwnMessage) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: senderIsAdmin 
                    ? Colors.teal.withOpacity(0.2) 
                    : senderIsModerator 
                        ? Colors.blue.withOpacity(0.2) 
                        : Colors.grey.withOpacity(0.2),
                child: Text(
                  message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: senderIsAdmin ? Colors.teal : senderIsModerator ? Colors.blue : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isOwnMessage
                      ? const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)])
                      : null,
                  color: isOwnMessage ? null : (isDark ? const Color(0xFF1a2a4a) : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isOwnMessage ? 20 : 4),
                    bottomRight: Radius.circular(isOwnMessage ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isOwnMessage)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message.senderName,
                            style: lang.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: senderIsAdmin 
                                  ? Colors.teal 
                                  : senderIsModerator 
                                      ? Colors.blue 
                                      : (isDark ? Colors.white70 : Colors.grey[600]!),
                            ),
                          ),
                          if (senderIsAdmin) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getDeveloperText(lang),
                                style: const TextStyle(color: Colors.teal, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          if (senderIsModerator) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getModeratorText(lang),
                                style: const TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          if (message.isPinned) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.push_pin, size: 12, color: Colors.amber),
                          ],
                        ],
                      ),
                    if (!isOwnMessage) const SizedBox(height: 4),
                    // Message Content
                    if (message.isAudio)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: WebAudioPlayerWidget(
                          audioUrl: message.audioUrl!,
                          durationSeconds: message.audioDuration ?? 0,
                          activeColor: isOwnMessage ? Colors.white : const Color(0xFF4facfe),
                          inactiveColor: isOwnMessage ? Colors.white54 : Colors.grey,
                        ),
                      )
                    else if (message.isReply)
                      GestureDetector(
                        onTap: () {
                          if (message.replyToId != null) {
                            _scrollToMessage(message.replyToId!);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isOwnMessage 
                                ? Colors.white.withOpacity(0.1) 
                                : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(
                                color: isOwnMessage ? Colors.white70 : Colors.blue,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.replyToSenderName ?? '',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isOwnMessage ? Colors.white70 : Colors.blue,
                                ),
                              ),
                              Text(
                                message.replyToText ?? '',
                                style: lang.getTextStyle(
                                  fontSize: 11,
                                  color: isOwnMessage ? Colors.white60 : (isDark ? Colors.white54 : Colors.grey[600]!),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!message.isAudio)
                      Text(
                        message.text,
                        style: lang.getTextStyle(
                          fontSize: 14,
                          color: isOwnMessage ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isOwnMessage ? Colors.white70 : (isDark ? Colors.white38 : Colors.grey),
                          ),
                        ),
                        if (message.isEdited) ...[
                          const SizedBox(width: 4),
                          Text(
                            lang.currentLanguage == AppLanguage.arabic ? '(معدل)' : lang.currentLanguage == AppLanguage.kurdish ? '(دەستکاریکراو)' : '(edited)',
                            style: TextStyle(
                              fontSize: 9,
                              fontStyle: FontStyle.italic,
                              color: isOwnMessage ? Colors.white60 : (isDark ? Colors.white30 : Colors.grey[400]),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Reactions Display
                    ReactionsDisplay(
                      reactions: message.reactions,
                      isOwnMessage: isOwnMessage,
                      isDark: isDark,
                      onReactionTap: (emoji, hasReacted) {
                        _chatService.toggleReaction(message.id, emoji, hasReacted);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';
    
    if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day) {
      return timeStr;
    }
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} $timeStr';
  }

  void _showMessageOptions(ChatMessage message, bool isOwnMessage, bool isAdmin, bool isModerator, LanguageService lang, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a2a4a) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Directionality(
          textDirection: lang.textDirection,
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              
              // Reaction Picker Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: availableReactions.map((emoji) {
                  final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                  final hasReacted = message.reactions[emoji]?.contains(currentUserId) ?? false;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _chatService.toggleReaction(message.id, emoji, hasReacted);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: hasReacted 
                            ? const Color(0xFF0D9488).withOpacity(0.3) 
                            : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(12),
                        border: hasReacted 
                            ? Border.all(color: const Color(0xFF0D9488))
                            : null,
                      ),
                      child: Text(emoji, style: getEmojiStyle(24)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Divider(color: isDark ? Colors.white12 : Colors.grey[300]),
              const SizedBox(height: 8),
              
              // Send Private Message (if not own message)
              if (!isOwnMessage)
                _buildOptionItem(
                  icon: Icons.mail_outline,
                  title: lang.currentLanguage == AppLanguage.arabic 
                      ? 'إرسال رسالة خاصة' 
                      : lang.currentLanguage == AppLanguage.kurdish 
                          ? 'ناردنی نامەی تایبەت' 
                          : 'Send Private Message',
                  color: Colors.blue,
                  isDark: isDark,
                  lang: lang,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrivateChatScreen(
                          otherUserId: message.senderId,
                          otherUserName: message.senderName,
                        ),
                      ),
                    );
                  },
                ),
              
              // Reply option (always available)
              _buildOptionItem(
                icon: Icons.reply,
                title: _getReplyText(lang),
                color: Colors.blue,
                isDark: isDark,
                lang: lang,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _replyToMessage = message);
                },
              ),
              
              // Copy message (always available)
              _buildOptionItem(
                icon: Icons.copy,
                title: _getCopyText(lang),
                color: Colors.teal,
                isDark: isDark,
                lang: lang,
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_getCopiedText(lang)),
                      backgroundColor: Colors.teal,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              
              // Edit (own messages only)
              if (isOwnMessage)
                _buildOptionItem(
                  icon: Icons.edit,
                  title: _getEditText(lang),
                  color: Colors.blue,
                  isDark: isDark,
                  lang: lang,
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(message, lang, isDark);
                  },
                ),
              
              // Delete (own messages or admin)
              if (isOwnMessage || isAdmin)
                _buildOptionItem(
                  icon: Icons.delete,
                  title: _getDeleteText(lang),
                  color: Colors.red,
                  isDark: isDark,
                  lang: lang,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(message, lang, isDark);
                  },
                ),
              
              // Pin/Unpin (admin or moderator)
              if (isAdmin || isModerator)
                _buildOptionItem(
                  icon: message.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  title: message.isPinned ? _getUnpinText(lang) : _getPinText(lang),
                  color: Colors.amber,
                  isDark: isDark,
                  lang: lang,
                  onTap: () async {
                    Navigator.pop(context);
                    if (message.isPinned) {
                      await _chatService.unpinMessage(message.id);
                    } else {
                      await _chatService.pinMessage(message.id);
                    }
                  },
                ),
              
              // Mute user (admin or moderator, not own messages, not admin messages)
              if ((isAdmin || isModerator) && !isOwnMessage && message.senderRole != UserRole.admin)
                _buildOptionItem(
                  icon: Icons.volume_off,
                  title: _getMuteUserText(lang),
                  color: Colors.orange,
                  isDark: isDark,
                  lang: lang,
                  onTap: () async {
                    Navigator.pop(context);
                    await _chatService.muteUser(message.senderId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_getUserMutedText(lang)),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                ),
              
              // Block user (admin only, not own messages, not admin messages)
              if (isAdmin && !isOwnMessage && message.senderRole != UserRole.admin)
                _buildOptionItem(
                  icon: Icons.block,
                  title: _getBlockUserText(lang),
                  color: Colors.red,
                  isDark: isDark,
                  lang: lang,
                  onTap: () async {
                    Navigator.pop(context);
                    await _chatService.blockUser(message.senderId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_getUserBlockedText(lang)),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              
              // Promote to moderator (admin only, regular users only)
              if (isAdmin && !isOwnMessage && message.senderRole == UserRole.user)
                _buildOptionItem(
                  icon: Icons.arrow_upward,
                  title: _getPromoteText(lang),
                  color: Colors.green,
                  isDark: isDark,
                  lang: lang,
                  onTap: () async {
                    Navigator.pop(context);
                    await _chatService.promoteToModerator(message.senderId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_getPromotedText(lang)),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
              
              // Demote from moderator (admin only, moderators only)
              if (isAdmin && !isOwnMessage && message.senderRole == UserRole.moderator)
                _buildOptionItem(
                  icon: Icons.arrow_downward,
                  title: _getDemoteText(lang),
                  color: Colors.orange,
                  isDark: isDark,
                  lang: lang,
                  onTap: () async {
                    Navigator.pop(context);
                    await _chatService.demoteFromModerator(message.senderId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_getDemotedText(lang)),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                ),
              
              const SizedBox(height: 10),
            ],
          ),
          ),
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
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87)),
      onTap: onTap,
    );
  }

  void _showEditDialog(ChatMessage message, LanguageService lang, bool isDark) {
    final controller = TextEditingController(text: message.text);
    
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: lang.textDirection,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            _getEditMessageText(lang),
            style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            textDirection: lang.textDirection,
            maxLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
            ),
            style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.cancel, style: lang.getTextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  await _chatService.editMessage(message.id, controller.text.trim());
                  if (mounted) Navigator.pop(context);
                }
              },
              child: Text(_getSaveText(lang), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(ChatMessage message, LanguageService lang, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: lang.textDirection,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            _getDeleteMessageText(lang),
            style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Text(
            _getAreYouSureText(lang),
            style: lang.getTextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.cancel, style: lang.getTextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await _chatService.deleteMessage(message.id);
                if (mounted) Navigator.pop(context);
              },
              child: Text(_getDeleteText(lang), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinnedMessages(List<ChatMessage> pinnedMessages, LanguageService lang, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a2a4a) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Directionality(
          textDirection: lang.textDirection,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.push_pin, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    _getPinnedMessagesText(lang),
                    style: lang.getTextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: pinnedMessages.map((msg) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                msg.senderName,
                                style: lang.getTextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber),
                              ),
                              const Spacer(),
                              Text(
                                _formatTime(msg.createdAt),
                                style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey),
                              ),
                              if (_chatService.isCurrentUserAdmin || _chatService.isCurrentUserModerator) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await _chatService.unpinMessage(msg.id);
                                  },
                                  child: const Icon(Icons.close, color: Colors.red, size: 18),
                                ),
                              ]
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg.text,
                            style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdminPanel(LanguageService lang, bool isDark, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a2a4a) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Directionality(
            textDirection: lang.textDirection,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isAdmin ? Colors.teal.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.admin_panel_settings, 
                        color: isAdmin ? Colors.teal : Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getAdminPanelText(lang),
                          style: lang.getTextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isAdmin ? Colors.teal.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isAdmin ? _getDeveloperText(lang) : _getModeratorText(lang),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isAdmin ? Colors.teal : Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<List<ChatUser>>(
                    stream: _chatService.getAllUsers(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final users = snapshot.data!;
                      
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return _buildUserTile(user, isAdmin, lang, isDark);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTile(ChatUser user, bool isAdmin, LanguageService lang, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: user.isBlocked 
            ? Border.all(color: Colors.red.withOpacity(0.5)) 
            : user.isMuted 
                ? Border.all(color: Colors.orange.withOpacity(0.5))
                : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: user.role == UserRole.admin 
                ? Colors.teal.withOpacity(0.2) 
                : user.role == UserRole.moderator 
                    ? Colors.blue.withOpacity(0.2) 
                    : Colors.grey.withOpacity(0.2),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: user.role == UserRole.admin ? Colors.teal : user.role == UserRole.moderator ? Colors.blue : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        style: lang.getTextStyle(
                          fontWeight: FontWeight.bold,
                          color: user.isBlocked ? Colors.red : (isDark ? Colors.white : Colors.black87),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (user.role == UserRole.admin)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.teal.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text(_getDeveloperText(lang), style: const TextStyle(color: Colors.teal, fontSize: 9)),
                      ),
                    if (user.role == UserRole.moderator)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text(_getModeratorText(lang), style: const TextStyle(color: Colors.blue, fontSize: 9)),
                      ),
                  ],
                ),
                Row(
                  children: [
                    if (user.isMuted)
                      Container(
                        margin: const EdgeInsets.only(right: 4, top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.volume_off, size: 10, color: Colors.orange),
                            const SizedBox(width: 2),
                            Text(_getMutedText(lang), style: const TextStyle(color: Colors.orange, fontSize: 9)),
                          ],
                        ),
                      ),
                    if (user.isBlocked)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.block, size: 10, color: Colors.red),
                            const SizedBox(width: 2),
                            Text(_getBlockedText(lang), style: const TextStyle(color: Colors.red, fontSize: 9)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Don't show actions for admin users (developers)
          if (user.role != UserRole.admin)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: isDark ? Colors.white54 : Colors.grey),
              onSelected: (value) async {
                switch (value) {
                  case 'promote':
                    await _chatService.promoteToModerator(user.id);
                    break;
                  case 'demote':
                    await _chatService.demoteFromModerator(user.id);
                    break;
                  case 'mute':
                    await _chatService.muteUser(user.id);
                    break;
                  case 'unmute':
                    await _chatService.unmuteUser(user.id);
                    break;
                  case 'block':
                    await _chatService.blockUser(user.id);
                    break;
                  case 'unblock':
                    await _chatService.unblockUser(user.id);
                    break;
                }
              },
              itemBuilder: (context) => [
                // Promote (admin only, regular users)
                if (isAdmin && user.role == UserRole.user)
                  PopupMenuItem(
                    value: 'promote',
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_upward, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(_getPromoteText(lang)),
                      ],
                    ),
                  ),
                // Demote (admin only, moderators)
                if (isAdmin && user.role == UserRole.moderator)
                  PopupMenuItem(
                    value: 'demote',
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_downward, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(_getDemoteText(lang)),
                      ],
                    ),
                  ),
                // Mute/Unmute (admin or moderator)
                if (!user.isMuted)
                  PopupMenuItem(
                    value: 'mute',
                    child: Row(
                      children: [
                        const Icon(Icons.volume_off, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(_getMuteUserText(lang)),
                      ],
                    ),
                  ),
                if (user.isMuted)
                  PopupMenuItem(
                    value: 'unmute',
                    child: Row(
                      children: [
                        const Icon(Icons.volume_up, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(_getUnmuteUserText(lang)),
                      ],
                    ),
                  ),
                // Block/Unblock (admin only)
                if (isAdmin && !user.isBlocked)
                  PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        const Icon(Icons.block, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(_getBlockUserText(lang)),
                      ],
                    ),
                  ),
                if (isAdmin && user.isBlocked)
                  PopupMenuItem(
                    value: 'unblock',
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(_getUnblockUserText(lang)),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // Localization helpers
  String _getDeveloperText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'مطور';
      case AppLanguage.kurdish: return 'گەشەپێدەر';
      case AppLanguage.english: return 'Developer';
    }
  }

  String _getModeratorText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'مشرف';
      case AppLanguage.kurdish: return 'مشرف';
      case AppLanguage.english: return 'Moderator';
    }
  }

  String _getMutedMessage(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تم كتم صوتك، لا يمكنك إرسال رسائل';
      case AppLanguage.kurdish: return 'تۆ میوتکراویت، ناتوانیت نامە بنێریت';
      case AppLanguage.english: return 'You are muted and cannot send messages';
    }
  }

  String _getBlockedMessage(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تم حظرك من المحادثة';
      case AppLanguage.kurdish: return 'تۆ بلۆککراویت لە گفتوگۆ';
      case AppLanguage.english: return 'You are blocked from the chat';
    }
  }

  String _getMutedBannerText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'أنت مكتوم الصوت حالياً';
      case AppLanguage.kurdish: return 'تۆ ئێستا میوتکراویت';
      case AppLanguage.english: return 'You are currently muted';
    }
  }

  String _getMutedHintText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'لا يمكنك إرسال رسائل...';
      case AppLanguage.kurdish: return 'ناتوانیت نامە بنێریت...';
      case AppLanguage.english: return 'You cannot send messages...';
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

  String _getReplyText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'رد';
      case AppLanguage.kurdish: return 'وەڵام';
      case AppLanguage.english: return 'Reply';
    }
  }

  String _getPinText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تثبيت';
      case AppLanguage.kurdish: return 'تەسبیتکردن';
      case AppLanguage.english: return 'Pin';
    }
  }

  String _getUnpinText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إلغاء التثبيت';
      case AppLanguage.kurdish: return 'لابردنی تەسبیت';
      case AppLanguage.english: return 'Unpin';
    }
  }

  String _getMuteUserText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'كتم المستخدم';
      case AppLanguage.kurdish: return 'میوتکردنی بەکارهێنەر';
      case AppLanguage.english: return 'Mute User';
    }
  }

  String _getUnmuteUserText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إلغاء الكتم';
      case AppLanguage.kurdish: return 'لابردنی میوت';
      case AppLanguage.english: return 'Unmute User';
    }
  }

  String _getBlockUserText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حظر المستخدم';
      case AppLanguage.kurdish: return 'بلۆککردنی بەکارهێنەر';
      case AppLanguage.english: return 'Block User';
    }
  }

  String _getUnblockUserText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إلغاء الحظر';
      case AppLanguage.kurdish: return 'لابردنی بلۆک';
      case AppLanguage.english: return 'Unblock User';
    }
  }

  String _getPromoteText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'ترقية لمشرف';
      case AppLanguage.kurdish: return 'مشرفکردن';
      case AppLanguage.english: return 'Promote to Mod';
    }
  }

  String _getDemoteText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إزالة المشرف';
      case AppLanguage.kurdish: return 'لابردنی مشرف';
      case AppLanguage.english: return 'Remove Mod';
    }
  }

  String _getUserMutedText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تم كتم المستخدم';
      case AppLanguage.kurdish: return 'بەکارهێنەر میوتکرا';
      case AppLanguage.english: return 'User muted';
    }
  }

  String _getUserBlockedText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تم حظر المستخدم';
      case AppLanguage.kurdish: return 'بەکارهێنەر بلۆککرا';
      case AppLanguage.english: return 'User blocked';
    }
  }

  String _getPromotedText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تم ترقية المستخدم لمشرف';
      case AppLanguage.kurdish: return 'بەکارهێنەر بوو بە مشرف';
      case AppLanguage.english: return 'User promoted to moderator';
    }
  }

  String _getDemotedText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تم إزالة صلاحيات المشرف';
      case AppLanguage.kurdish: return 'مۆڵەتی مشرف لابرا';
      case AppLanguage.english: return 'Moderator role removed';
    }
  }

  String _getEditMessageText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تعديل الرسالة';
      case AppLanguage.kurdish: return 'دەستکاریکردنی نامە';
      case AppLanguage.english: return 'Edit Message';
    }
  }

  String _getDeleteMessageText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حذف الرسالة';
      case AppLanguage.kurdish: return 'سڕینەوەی نامە';
      case AppLanguage.english: return 'Delete Message';
    }
  }

  String _getSaveText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حفظ';
      case AppLanguage.kurdish: return 'پاشەکەوتکردن';
      case AppLanguage.english: return 'Save';
    }
  }

  String _getAreYouSureText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'هل أنت متأكد؟';
      case AppLanguage.kurdish: return 'دڵنیایت؟';
      case AppLanguage.english: return 'Are you sure?';
    }
  }

  String _getPinnedMessagesText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'الرسائل المثبتة';
      case AppLanguage.kurdish: return 'نامە تەسبیتکراوەکان';
      case AppLanguage.english: return 'Pinned Messages';
    }
  }

  String _getAdminPanelText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'لوحة الإدارة';
      case AppLanguage.kurdish: return 'پانێڵی بەڕێوەبردن';
      case AppLanguage.english: return 'Admin Panel';
    }
  }

  String _getMutedText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'مكتوم';
      case AppLanguage.kurdish: return 'میوت';
      case AppLanguage.english: return 'Muted';
    }
  }

  String _getBlockedText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'محظور';
      case AppLanguage.kurdish: return 'بلۆک';
      case AppLanguage.english: return 'Blocked';
    }
  }

  void _showDeveloperActivationDialog(LanguageService lang, bool isDark) {
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: lang.textDirection,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.developer_mode, color: Colors.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                lang.currentLanguage == AppLanguage.arabic 
                    ? 'تفعيل المطور' 
                    : lang.currentLanguage == AppLanguage.kurdish 
                        ? 'چالاککردنی گەشەپێدەر' 
                        : 'Developer Activation',
                style: lang.getTextStyle(
                  color: isDark ? Colors.white : Colors.black, 
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lang.currentLanguage == AppLanguage.arabic 
                    ? 'أدخل الرمز السري للتفعيل' 
                    : lang.currentLanguage == AppLanguage.kurdish 
                        ? 'کۆدی نهێنی بنووسە بۆ چالاککردن' 
                        : 'Enter secret code to activate',
                style: lang.getTextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: lang.currentLanguage == AppLanguage.arabic 
                      ? 'الرمز السري' 
                      : lang.currentLanguage == AppLanguage.kurdish 
                          ? 'کۆدی نهێنی' 
                          : 'Secret code',
                  hintStyle: lang.getTextStyle(color: isDark ? Colors.white38 : Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
                  prefixIcon: Icon(Icons.lock, color: isDark ? Colors.white54 : Colors.grey),
                ),
                style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.cancel, style: lang.getTextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final code = codeController.text.trim();
                if (code.isNotEmpty) {
                  final success = await _chatService.setAsDeveloper(code);
                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            lang.currentLanguage == AppLanguage.arabic 
                                ? 'تم تفعيلك كمطور! 🎉' 
                                : lang.currentLanguage == AppLanguage.kurdish 
                                    ? 'وەک گەشەپێدەر چالاککرایت! 🎉' 
                                    : 'You are now a developer! 🎉',
                          ),
                          backgroundColor: Colors.teal,
                        ),
                      );
                      setState(() {}); // Refresh UI
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            lang.currentLanguage == AppLanguage.arabic 
                                ? 'الرمز غير صحيح' 
                                : lang.currentLanguage == AppLanguage.kurdish 
                                    ? 'کۆدەکە هەڵەیە' 
                                    : 'Invalid code',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: Text(
                lang.currentLanguage == AppLanguage.arabic 
                    ? 'تفعيل' 
                    : lang.currentLanguage == AppLanguage.kurdish 
                        ? 'چالاککردن' 
                        : 'Activate',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCopyText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'نسخ الرسالة';
      case AppLanguage.kurdish: return 'کۆپیکردنی نامە';
      case AppLanguage.english: return 'Copy Message';
    }
  }

  String _getCopiedText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تم النسخ';
      case AppLanguage.kurdish: return 'کۆپی کرا';
      case AppLanguage.english: return 'Copied';
    }
  }
}

