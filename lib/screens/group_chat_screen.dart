import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../services/language_service.dart';
import '../services/group_service.dart';
import '../widgets/user_avatar.dart';
import '../services/auth_service.dart';
import '../widgets/reactions_widget.dart';
import '../widgets/web_audio_player_widget.dart';
import '../services/cloud_storage_service.dart';
import '../services/web_audio_recorder.dart';
import 'group_settings_screen.dart';
import 'zego_call_screen.dart';
import '../services/call_room_service.dart';
class GroupChatScreen extends StatefulWidget {
  final String groupId;

  const GroupChatScreen({super.key, required this.groupId});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _messageController = TextEditingController();
  final _itemScrollController = ItemScrollController();
  final _itemPositionsListener = ItemPositionsListener.create();
  final _groupService = GroupService();
  final _authService = AuthService();
  final _callRoomService = CallRoomService();
  bool _isLoading = false;
  int _currentLimit = 20;
  bool _isLoadingMore = false;
  
  // Reply state
  GroupMessage? _replyToMessage;
  
  // Map of message IDs to their GlobalKeys for scrolling
  final Map<String, GlobalKey> _messageKeys = {};
  
  // List of all messages for lookup
  List<GroupMessage> _allMessages = [];

  // Voice recording
  final _cloudStorage = CloudStorageService();
  final _audioRecorder = WebAudioRecorder();
  bool _isRecording = false;
  bool _isUploadingAudio = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  // Streams
  late Stream<ChatGroup?> _groupStream;
  late Stream<List<CallRoom>> _groupRoomsStream;
  late Stream<List<GroupMessage>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _groupStream = _groupService.getGroup(widget.groupId);
    _groupRoomsStream = _callRoomService.getGroupRooms(widget.groupId);
    _messagesStream = _groupService.getGroupMessages(widget.groupId, limit: _currentLimit);
    
    _itemPositionsListener.itemPositions.addListener(_onScroll);
    
    // Listen to messages to update lookup map
    _messagesStream.listen((messages) {
      _allMessages = messages;
      _messageKeys.clear();
      for (var msg in messages) {
        _messageKeys[msg.id] = GlobalKey();
      }
      // Consider adding logic here to auto-scroll to bottom if new message is from current user
      // or if user is already at the bottom.
    });
  }

  void _onScroll() {
    if (_itemPositionsListener.itemPositions.value.isEmpty) return;

    final positions = _itemPositionsListener.itemPositions.value;
    final lastVisibleIndex = positions
        .map((p) => p.index)
        .reduce((max, index) => index > max ? index : max);

    // If we are close to the end of the current list (oldest messages)
    if (lastVisibleIndex >= _allMessages.length - 5 && !_isLoadingMore && _allMessages.length >= _currentLimit) {
      _loadMoreMessages();
    }
  }

  void _loadMoreMessages() {
    if (!mounted) return;
    setState(() {
      _isLoadingMore = true;
      _currentLimit += 20;
      _messagesStream = _groupService.getGroupMessages(widget.groupId, limit: _currentLimit);
    });
    
    // Reset loading flag after a short delay to prevent multiple triggers
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _isLoadingMore = false);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _itemPositionsListener.itemPositions.removeListener(_onScroll);
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

  // Highlighted message ID (for visual feedback)
  String? _highlightedMessageId;

  /// Scroll to a specific message by ID
  void _scrollToMessage(String messageId) {
    // Find message index
    final index = _allMessages.indexWhere((m) => m.id == messageId);
    if (index == -1) {
      debugPrint('Message not found: $messageId');
      return;
    }

    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }

    // Highlight the message briefly for visual feedback
    setState(() => _highlightedMessageId = messageId);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _highlightedMessageId = null);
    });
  }

  /// Set reply to message
  void _setReplyTo(GroupMessage message) {
    setState(() => _replyToMessage = message);
  }

  /// Cancel reply
  void _cancelReply() {
    setState(() => _replyToMessage = null);
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    _groupService.sendMessage(widget.groupId, text, replyTo: _replyToMessage).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    });
    
    _cancelReply(); // Clear reply after sending
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

      final fileName = 'group_voice_${DateTime.now().millisecondsSinceEpoch}.webm';
      final audioUrl = await _cloudStorage.uploadAudioBytes(audioBytes, fileName);
      
      if (audioUrl != null && mounted) {
        await _groupService.sendAudioMessage(
          widget.groupId,
          audioUrl,
          duration,
          replyTo: _replyToMessage,
        );
        _cancelReply();
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    } catch (e) {
      debugPrint('Error sending voice message: $e');
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

Widget _buildRecordingState(LanguageService lang, bool isDark) {
    return Row(
      children: [
        // Cancel Button
        IconButton(
          onPressed: _cancelRecording,
          icon: const Icon(Icons.delete_outline, color: Colors.red),
        ),
        
        // Recording Indicator
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatRecordingTime(_recordingSeconds),
                style: lang.getTextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        
        // Send / Uploading Button
        GestureDetector(
          onTap: _isUploadingAudio ? null : _stopAndSendRecording,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(25),
            ),
            child: _isUploadingAudio
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildInputState(LanguageService lang, bool isDark) {
    return Row(
      children: [
        // Mic Button
        GestureDetector(
          onTap: _startRecording,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4facfe).withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(Icons.mic, color: Color(0xFF4facfe), size: 24),
          ),
        ),
        const SizedBox(width: 8),

        Expanded(
          child: TextField(
            controller: _messageController,
            textDirection: lang.textDirection,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: _getTypeMessageText(lang),
              hintStyle: lang.getTextStyle(color: isDark ? Colors.white38 : Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
            onSubmitted: (_) => _sendMessage(),
          ),
        ),
        const SizedBox(width: 8),
        
        // Send Button
        GestureDetector(
          onTap: _isLoading ? null : _sendMessage,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
              borderRadius: BorderRadius.circular(25),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send, color: Colors.white),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = lang.isDarkMode;
    final currentUserId = _authService.currentUser?.uid ?? '';

    return StreamBuilder<ChatGroup?>(
      stream: _groupStream,
      builder: (context, groupSnapshot) {
        if (groupSnapshot.hasError) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0a1628) : const Color(0xFFF5F5F5),
            body: Center(child: Text('Error: ${groupSnapshot.error}')),
          );
        }

        if (groupSnapshot.connectionState == ConnectionState.waiting && !groupSnapshot.hasData) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0a1628) : const Color(0xFFF5F5F5),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final group = groupSnapshot.data;
        if (group == null) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0a1628) : const Color(0xFFF5F5F5),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
              ),
            ),
            body: Center(
              child: Text(
                _getGroupNotFoundText(lang),
                style: lang.getTextStyle(color: isDark ? Colors.white54 : Colors.grey),
              ),
            ),
          );
        }

        final isAdmin = group.isAdmin(currentUserId);
        final isOwner = group.isOwner(currentUserId);

        return Directionality(
          textDirection: lang.textDirection,
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF0a1628) : const Color(0xFFF5F5F5),
            appBar: AppBar(
              backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
              elevation: 1,
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GroupSettingsScreen(groupId: widget.groupId)),
                ),
                child: Row(
                  children: [
                    // Group Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: group.isPrivate
                              ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)]
                              : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: group.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(group.imageUrl!, fit: BoxFit.cover),
                            )
                          : Icon(
                              group.isPrivate ? Icons.lock : Icons.groups,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: lang.getTextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 12,
                                color: isDark ? Colors.white54 : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${group.memberIds.length} ${_getMembersText(lang)}',
                                style: lang.getTextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.grey,
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
              actions: [
                // Voice Call Button
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ZegoCallScreen(
                        roomName: group.name,
                        displayName: _authService.currentUser?.displayName ?? 'User',
                        odaID: widget.groupId,
                        isVideoCall: false,
                        roomType: 'group',
                        groupId: widget.groupId,
                      ),
                    ),
                  ),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.call, color: Colors.white, size: 18),
                  ),
                ),
                // Video Call Button
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ZegoCallScreen(
                        roomName: group.name,
                        displayName: _authService.currentUser?.displayName ?? 'User',
                        odaID: widget.groupId,
                        isVideoCall: true,
                        roomType: 'group',
                        groupId: widget.groupId,
                      ),
                    ),
                  ),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.videocam, color: Colors.white, size: 18),
                  ),
                ),
                // Settings Button
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => GroupSettingsScreen(groupId: widget.groupId)),
                  ),
                  icon: Icon(
                    Icons.settings,
                    color: isDark ? Colors.white70 : Colors.grey,
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                // Pending Requests Banner (for admins)
                if (isAdmin && group.pendingRequestIds.isNotEmpty)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GroupSettingsScreen(groupId: widget.groupId)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        border: Border(
                          bottom: BorderSide(color: Colors.orange.withOpacity(0.3)),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.pending_actions, color: Colors.orange, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${group.pendingRequestIds.length} ${_getPendingRequestsText(lang)}',
                              style: lang.getTextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            lang.isRTL ? Icons.chevron_left : Icons.chevron_right,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Active Call Rooms Banner for this Group
                StreamBuilder<List<CallRoom>>(
                  stream: _groupRoomsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final activeRooms = snapshot.data!;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF4facfe).withOpacity(0.2), const Color(0xFF00f2fe).withOpacity(0.2)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF4facfe).withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.videocam, color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 12),
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
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        '${activeRooms.length} ${lang.currentLanguage == AppLanguage.arabic ? 'مكالمة' : lang.currentLanguage == AppLanguage.kurdish ? 'پەیوەندی' : 'call(s)'}',
                                        style: lang.getTextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white60 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Live indicator
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: const Color(0xFF4facfe).withOpacity(0.3))),
                              ),
                              child: Row(
                                children: [
                                  // Participants avatars
                                  SizedBox(
                                    width: 60,
                                    height: 30,
                                    child: Stack(
                                      children: [
                                        for (int i = 0; i < room.participants.length.clamp(0, 3); i++)
                                          Positioned(
                                            left: i * 18.0,
                                            child: CircleAvatar(
                                              radius: 15,
                                              backgroundColor: [Colors.blue, Colors.green, Colors.purple][i % 3],
                                              child: Text(
                                                room.participants[i].name.isNotEmpty 
                                                    ? room.participants[i].name[0].toUpperCase() 
                                                    : '?',
                                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          room.name,
                                          style: lang.getTextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${room.participantCount} ${lang.currentLanguage == AppLanguage.arabic ? 'مشارك' : lang.currentLanguage == AppLanguage.kurdish ? 'بەشداربوو' : 'participants'}',
                                          style: lang.getTextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.white54 : Colors.black45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Join button
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(room.isVideoCall ? Icons.videocam : Icons.call, color: Colors.white, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          lang.currentLanguage == AppLanguage.arabic 
                                              ? 'انضم' 
                                              : lang.currentLanguage == AppLanguage.kurdish 
                                                  ? 'داخڵبە' 
                                                  : 'Join',
                                          style: lang.getTextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
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

                // Messages List
                Expanded(
                  child: StreamBuilder<List<GroupMessage>>(
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 80,
                                color: isDark ? Colors.white24 : Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _getNoMessagesText(lang),
                                style: lang.getTextStyle(
                                  color: isDark ? Colors.white38 : Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getStartConversationText(lang),
                                style: lang.getTextStyle(
                                  color: isDark ? Colors.white24 : Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final List<GroupMessage> messages = snapshot.data!;
                      _allMessages = messages; // Store for lookup
                      
                      // Create keys for each message
                      for (final msg in messages) {
                        _messageKeys.putIfAbsent(msg.id, () => GlobalKey());
                      }

                      // Find pinned message (if any)
                      final pinnedMessage = messages.where((m) => m.isPinned).toList();

                      return Column(
                        children: [
                          // Pinned message banner (clickable to scroll)
                          if (pinnedMessage.isNotEmpty)
                            GestureDetector(
                              onTap: () => _scrollToMessage(pinnedMessage.first.id),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4facfe).withOpacity(0.15),
                                  border: Border(
                                    bottom: BorderSide(color: const Color(0xFF4facfe).withOpacity(0.3)),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.push_pin, color: Color(0xFF4facfe), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pinnedMessage.first.senderName,
                                            style: lang.getTextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF4facfe),
                                            ),
                                          ),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(maxHeight: 40),
                                            child: SingleChildScrollView(
                                              child: Text(
                                                pinnedMessage.first.text,
                                                style: lang.getTextStyle(
                                                  fontSize: 13,
                                                  color: isDark ? Colors.white70 : Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isAdmin || isOwner)
                                      GestureDetector(
                                        onTap: () => _groupService.unpinMessage(widget.groupId, pinnedMessage.first.id),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Icon(Icons.close, color: Colors.red, size: 20),
                                        ),
                                      ),
                                    Icon(Icons.keyboard_arrow_up, color: isDark ? Colors.white54 : Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          Expanded(
                            child: ScrollablePositionedList.builder(
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
                                final senderRole = group.getUserRole(message.senderId);
                                final isHighlighted = _highlightedMessageId == message.id;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  key: _messageKeys[message.id],
                                  decoration: BoxDecoration(
                                    color: isHighlighted 
                                        ? Colors.yellow.withOpacity(0.3) 
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: _buildMessageBubble(
                                    message,
                                    isOwnMessage,
                                    senderRole,
                                    isAdmin || isOwner,
                                    lang,
                                    isDark,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Reply Preview Bar
                if (_replyToMessage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1a2a4a) : Colors.grey[100],
                      border: Border(
                        top: BorderSide(color: const Color(0xFF4facfe).withOpacity(0.5)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4facfe),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                  color: const Color(0xFF4facfe),
                                ),
                              ),
                              Text(
                                _replyToMessage!.text,
                                style: lang.getTextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _cancelReply,
                          icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.grey, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                // Input Area
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
                    child: _isRecording || _isUploadingAudio
                        ? _buildRecordingState(lang, isDark)
                        : _buildInputState(lang, isDark),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(
    GroupMessage message,
    bool isOwnMessage,
    GroupMemberRole? senderRole,
    bool canDelete,
    LanguageService lang,
    bool isDark,
  ) {
    final isOwner = senderRole == GroupMemberRole.owner;
    final isAdmin = senderRole == GroupMemberRole.admin;

    return GestureDetector(
      onLongPress: () => _showMessageOptions(message, isOwnMessage, canDelete, lang, isDark),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isOwnMessage) ...[
              UserAvatar(
                userId: message.senderId,
                userName: message.senderName,
                storedPhotoUrl: message.senderPhotoUrl,
                radius: 16,
                fontSize: 12,
                backgroundColor: isOwner ? Colors.amber : isAdmin ? Colors.blue : Colors.grey,
                textColor: isOwner ? Colors.amber : isAdmin ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isOwnMessage
                      ? const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)])
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
                              color: isOwner
                                  ? Colors.amber
                                  : isAdmin
                                      ? Colors.blue
                                      : (isDark ? Colors.white70 : Colors.grey[600]!),
                            ),
                          ),
                          if (isOwner) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getOwnerBadgeText(lang),
                                style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          if (isAdmin && !isOwner) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getAdminBadgeText(lang),
                                style: const TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    if (!isOwnMessage) const SizedBox(height: 4),
                    // Reply indicator (clickable to scroll to original message)
                    if (message.replyToId != null)
                      GestureDetector(
                        onTap: () => _scrollToMessage(message.replyToId!),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isOwnMessage 
                                ? Colors.white.withOpacity(0.15)
                                : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.15)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(
                                color: const Color(0xFF4facfe),
                                width: 3,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.replyToSenderName ?? '',
                                style: lang.getTextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4facfe),
                                ),
                              ),
                              Text(
                                message.replyToText ?? '',
                                style: lang.getTextStyle(
                                  fontSize: 12,
                                  color: isOwnMessage ? Colors.white70 : (isDark ? Colors.white60 : Colors.black54),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (message.isAudio)
                      WebAudioPlayerWidget(
                        audioUrl: message.audioUrl!,
                        durationSeconds: message.audioDuration ?? 0,
                        activeColor: isOwnMessage ? Colors.white : (isDark ? const Color(0xFF4facfe) : const Color(0xFF667EEA)),
                        inactiveColor: isOwnMessage ? Colors.white38 : Colors.grey,
                      )
                    else
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
                            _getEditedText(lang),
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
                        _groupService.toggleReaction(widget.groupId, message.id, emoji, hasReacted);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(GroupMessage message, bool isOwnMessage, bool canDelete, LanguageService lang, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a2a4a) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Directionality(
          textDirection: lang.textDirection,
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
                  final currentUserId = _authService.currentUser?.uid ?? '';
                  final hasReacted = message.reactions[emoji]?.contains(currentUserId) ?? false;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _groupService.toggleReaction(widget.groupId, message.id, emoji, hasReacted);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: hasReacted 
                            ? const Color(0xFF667EEA).withOpacity(0.3) 
                            : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(12),
                        border: hasReacted 
                            ? Border.all(color: const Color(0xFF667EEA))
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

              // Copy message
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

              // Reply to message
              _buildOptionItem(
                icon: Icons.reply,
                title: _getReplyText(lang),
                color: const Color(0xFF4facfe),
                isDark: isDark,
                lang: lang,
                onTap: () {
                  Navigator.pop(context);
                  _setReplyTo(message);
                },
              ),

              // Pin/Unpin message (admins only)
              if (canDelete)
                _buildOptionItem(
                  icon: message.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  title: message.isPinned ? _getUnpinText(lang) : _getPinText(lang),
                  color: Colors.orange,
                  isDark: isDark,
                  lang: lang,
                  onTap: () {
                    Navigator.pop(context);
                    if (message.isPinned) {
                      _groupService.unpinMessage(widget.groupId, message.id);
                    } else {
                      _groupService.pinMessage(widget.groupId, message.id);
                    }
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

              // Delete
              if (isOwnMessage || canDelete)
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

              const SizedBox(height: 10),
            ],
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

  void _showEditDialog(GroupMessage message, LanguageService lang, bool isDark) {
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA)),
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  await _groupService.editMessage(widget.groupId, message.id, controller.text.trim());
                  if (mounted) Navigator.pop(context);
                }
              },
              child: Text(
                _getSaveText(lang),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(GroupMessage message, LanguageService lang, bool isDark) {
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
                await _groupService.deleteMessage(widget.groupId, message.id);
                if (mounted) Navigator.pop(context);
              },
              child: Text(
                _getDeleteText(lang),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
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

  // Localization helpers
  String _getGroupNotFoundText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'المجموعة غير موجودة';
      case AppLanguage.kurdish: return 'گروپەکە نەدۆزرایەوە';
      case AppLanguage.english: return 'Group not found';
    }
  }

  String _getMembersText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'أعضاء';
      case AppLanguage.kurdish: return 'ئەندام';
      case AppLanguage.english: return 'members';
    }
  }

  String _getPendingRequestsText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'طلبات انضمام';
      case AppLanguage.kurdish: return 'داواکاری چوونە ناو';
      case AppLanguage.english: return 'join requests';
    }
  }

  String _getNoMessagesText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'لا توجد رسائل بعد';
      case AppLanguage.kurdish: return 'هێشتا هیچ نامەیەک نییە';
      case AppLanguage.english: return 'No messages yet';
    }
  }

  String _getStartConversationText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'ابدأ المحادثة!';
      case AppLanguage.kurdish: return 'دەست بە گفتوگۆ بکە!';
      case AppLanguage.english: return 'Start the conversation!';
    }
  }

  String _getTypeMessageText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'اكتب رسالة...';
      case AppLanguage.kurdish: return 'نامەیەک بنووسە...';
      case AppLanguage.english: return 'Type a message...';
    }
  }

  String _getOwnerBadgeText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'مالك';
      case AppLanguage.kurdish: return 'خاوەن';
      case AppLanguage.english: return 'Owner';
    }
  }

  String _getAdminBadgeText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'مشرف';
      case AppLanguage.kurdish: return 'ئەدمین';
      case AppLanguage.english: return 'Admin';
    }
  }

  String _getEditedText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return '(معدل)';
      case AppLanguage.kurdish: return '(دەستکاریکراو)';
      case AppLanguage.english: return '(edited)';
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

  String _getEditMessageText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تعديل الرسالة';
      case AppLanguage.kurdish: return 'دەستکاریکردنی نامە';
      case AppLanguage.english: return 'Edit Message';
    }
  }

  String _getSaveText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حفظ';
      case AppLanguage.kurdish: return 'پاشەکەوتکردن';
      case AppLanguage.english: return 'Save';
    }
  }

  String _getDeleteMessageText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حذف الرسالة';
      case AppLanguage.kurdish: return 'سڕینەوەی نامە';
      case AppLanguage.english: return 'Delete Message';
    }
  }

  String _getAreYouSureText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'هل أنت متأكد؟';
      case AppLanguage.kurdish: return 'دڵنیایت؟';
      case AppLanguage.english: return 'Are you sure?';
    }
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
      case AppLanguage.kurdish: return 'سنجاق';
      case AppLanguage.english: return 'Pin';
    }
  }

  String _getUnpinText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إلغاء التثبيت';
      case AppLanguage.kurdish: return 'لابردنی سنجاق';
      case AppLanguage.english: return 'Unpin';
    }
  }
}
