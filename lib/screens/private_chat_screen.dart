import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/private_message_service.dart';
import '../services/auth_service.dart';
import '../services/call_room_service.dart';
import '../services/cloud_storage_service.dart';
import '../services/web_audio_recorder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/reactions_widget.dart';
import '../widgets/web_audio_player_widget.dart';
import 'zego_call_screen.dart';

class PrivateChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const PrivateChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messageService = PrivateMessageService();
  final _authService = AuthService();
  final _callRoomService = CallRoomService();
  bool _isLoading = false;
  bool _showScrollToBottom = false;
  bool _isBlocked = false;
  String? _otherUserPhotoUrl;
  int _currentLimit = 20;
  bool _isLoadingMore = false;
  List<PrivateMessage> _currentMessages = [];

  // Voice recording
  final _cloudStorage = CloudStorageService();
  final _audioRecorder = WebAudioRecorder();
  bool _isRecording = false;
  bool _isUploadingAudio = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  // Streams
  late Stream<List<CallRoom>> _roomsStream;
  late Stream<List<PrivateMessage>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _roomsStream = _callRoomService.getGroupRooms(_getChatId());
    _messagesStream = _messageService.getMessages(widget.otherUserId, limit: _currentLimit);
    
    _scrollController.addListener(_onScroll);
    _checkBlockStatus();
    _markMessagesAsRead();
    _fetchOtherUserProfile();
  }

  Future<void> _fetchOtherUserProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _otherUserPhotoUrl = doc.data()?['photoURL'] ?? doc.data()?['photoUrl'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      
      // Show scroll to bottom button
      final shouldShow = (maxScroll - currentScroll) > 200;
      if (shouldShow != _showScrollToBottom) {
        setState(() => _showScrollToBottom = shouldShow);
      }

      // Lazy loading: Check if near the end of the list (top)
      if (currentScroll >= maxScroll - 200 && !_isLoadingMore && _currentMessages.length >= _currentLimit) {
        _loadMoreMessages();
      }
    }
  }

  void _loadMoreMessages() {
    if (!mounted) return;
    setState(() {
      _isLoadingMore = true;
      _currentLimit += 20;
      _messagesStream = _messageService.getMessages(widget.otherUserId, limit: _currentLimit);
    });
    
    // Reset loading flag after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _isLoadingMore = false);
    });
  }

  Future<void> _checkBlockStatus() async {
    final blocked = await _messageService.isUserBlocked(widget.otherUserId);
    if (mounted) setState(() => _isBlocked = blocked);
  }

  Future<void> _markMessagesAsRead() async {
    await _messageService.markAllAsRead(widget.otherUserId);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _getChatId() {
    final currentUserId = _authService.currentUser?.uid ?? '';
    final ids = [currentUserId, widget.otherUserId]..sort();
    return ids.join('_');
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isBlocked) return;

    _messageController.clear();
    
    // Fire and forget, no loading state
    _messageService.sendMessage(widget.otherUserId, widget.otherUserName, text).catchError((e) {
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

      final fileName = 'private_voice_${DateTime.now().millisecondsSinceEpoch}.webm';
      final audioUrl = await _cloudStorage.uploadAudioBytes(audioBytes, fileName);
      
      if (audioUrl != null && mounted) {
        await _messageService.sendAudioMessage(
          widget.otherUserId,
          widget.otherUserName,
          audioUrl,
          duration,
        );
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
        if (!_isBlocked)
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
        if (!_isBlocked) const SizedBox(width: 8),

        Expanded(
          child: TextField(
            controller: _messageController,
            textDirection: lang.textDirection,
            enabled: !_isBlocked,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: _isBlocked
                  ? _getBlockedStatusText(lang)
                  : lang.currentLanguage == AppLanguage.arabic 
                      ? 'اكتب رسالة...' 
                      : lang.currentLanguage == AppLanguage.kurdish 
                          ? 'نامەیەک بنووسە...' 
                          : 'Type a message...',
              hintStyle: lang.getTextStyle(
                color: _isBlocked ? Colors.orange : (isDark ? Colors.white38 : Colors.grey),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: _isBlocked 
                  ? Colors.orange.withOpacity(0.1) 
                  : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100]),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
            onSubmitted: (_) => _sendMessage(),
          ),
        ),
        const SizedBox(width: 8),
        
        // Send Button
        GestureDetector(
          onTap: (_isLoading || _isBlocked) ? null : _sendMessage,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: _isBlocked 
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
                    _isBlocked ? Icons.block : Icons.send,
                    color: Colors.white,
                  ),
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
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _isBlocked ? Colors.red.withOpacity(0.2) : Colors.teal.withOpacity(0.2),
                backgroundImage: !_isBlocked && _otherUserPhotoUrl != null && _otherUserPhotoUrl!.isNotEmpty
                    ? NetworkImage(_otherUserPhotoUrl!)
                    : null,
                child: (_isBlocked || _otherUserPhotoUrl == null || _otherUserPhotoUrl!.isEmpty)
                    ? Text(
                        widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: _isBlocked ? Colors.red : Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherUserName,
                      style: lang.getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_isBlocked)
                      Text(
                        _getBlockedStatusText(lang),
                        style: TextStyle(fontSize: 11, color: Colors.red[400]),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Video Call Button
            IconButton(
              onPressed: _isBlocked ? null : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ZegoCallScreen(
                    roomName: 'Chat: ${widget.otherUserName}',
                    displayName: _authService.currentUser?.displayName ?? 'User',
                    odaID: 'private_${_getChatId()}',
                    isVideoCall: true,
                    roomType: 'private',
                    groupId: _getChatId(),
                  ),
                ),
              ),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _isBlocked 
                      ? null 
                      : const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]),
                  color: _isBlocked ? Colors.grey.withOpacity(0.3) : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.videocam,
                  color: _isBlocked ? Colors.grey : Colors.white,
                  size: 18,
                ),
              ),
            ),
            // Voice Call Button
            IconButton(
              onPressed: _isBlocked ? null : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ZegoCallScreen(
                    roomName: 'Chat: ${widget.otherUserName}',
                    displayName: _authService.currentUser?.displayName ?? 'User',
                    odaID: 'private_${_getChatId()}',
                    isVideoCall: false,
                    roomType: 'private',
                    groupId: _getChatId(),
                  ),
                ),
              ),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _isBlocked 
                      ? null 
                      : const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)]),
                  color: _isBlocked ? Colors.grey.withOpacity(0.3) : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.call,
                  color: _isBlocked ? Colors.grey : Colors.white,
                  size: 18,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: isDark ? Colors.white : Colors.black87),
              color: isDark ? const Color(0xFF1a2a4a) : Colors.white,
              onSelected: (value) => _handleMenuAction(value, lang, isDark),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _isBlocked ? 'unblock' : 'block',
                  child: Row(
                    children: [
                      Icon(
                        _isBlocked ? Icons.check_circle : Icons.block,
                        color: _isBlocked ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isBlocked ? _getUnblockText(lang) : _getBlockText(lang),
                        style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _getDeleteConvText(lang),
                        style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Blocked banner
                if (_isBlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      border: Border(bottom: BorderSide(color: Colors.red.withOpacity(0.3))),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.block, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getBlockedBannerText(lang),
                            style: lang.getTextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _messageService.unblockUser(widget.otherUserId);
                            _checkBlockStatus();
                          },
                          child: Text(_getUnblockText(lang), style: const TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),

                // Active Call Rooms Banner
                StreamBuilder<List<CallRoom>>(
                  stream: _roomsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

                    return Container(
                      height: 50,
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final room = snapshot.data![index];
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.only(left: 12, right: 12, top: 6, bottom: 120),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.tealAccent,
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "LIVE",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (room.participants.isNotEmpty)
                                  SizedBox(
                                    height: 24,
                                    width: 40,
                                    child: Stack(
                                      children: List.generate(
                                        room.participants.take(2).length,
                                        (i) => Positioned(
                                          left: i * 15.0,
                                          child: CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.white,
                                            child: Text(
                                              room.participants[i].name.isNotEmpty 
                                                  ? room.participants[i].name[0].toUpperCase() 
                                                  : '?',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => Navigator.push(
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
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.teal,
                                    minimumSize: const Size(50, 24),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    room.isVideoCall ? 'Video' : 'Voice',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                // Messages List
                Expanded(
                  child: StreamBuilder<List<PrivateMessage>>(
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

                      if (snapshot.connectionState == ConnectionState.waiting && _currentMessages.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 60, color: isDark ? Colors.white24 : Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                _getNoMessagesText(lang),
                                style: lang.getTextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }

                      final List<PrivateMessage> messages = snapshot.data!.reversed.toList();
                      _currentMessages = messages;
                      
                      // Mark as read
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _markMessagesAsRead();
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
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
                          final isOwn = message.senderId == currentUserId;
                          return _buildMessageBubble(message, isOwn, lang, isDark);
                        },
                      );
                    },
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

            // Scroll to bottom button
            if (_showScrollToBottom)
              Positioned(
                right: 16,
                bottom: 100,
                child: GestureDetector(
                  onTap: _scrollToBottom,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1a2a4a) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(PrivateMessage message, bool isOwn, LanguageService lang, bool isDark) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(message, isOwn, lang, isDark),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isOwn) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.teal.withOpacity(0.2),
                backgroundImage: _otherUserPhotoUrl != null && _otherUserPhotoUrl!.isNotEmpty
                    ? NetworkImage(_otherUserPhotoUrl!)
                    : null,
                child: (_otherUserPhotoUrl == null || _otherUserPhotoUrl!.isEmpty)
                    ? Text(
                        widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isOwn
                      ? const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)])
                      : null,
                  color: isOwn ? null : (isDark ? const Color(0xFF1a2a4a) : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isOwn ? 20 : 4),
                    bottomRight: Radius.circular(isOwn ? 4 : 20),
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
                  crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (message.isAudio)
                      WebAudioPlayerWidget(
                        audioUrl: message.audioUrl!,
                        durationSeconds: message.audioDuration ?? 0,
                        activeColor: isOwn ? Colors.white : (isDark ? const Color(0xFF4facfe) : const Color(0xFF0D9488)),
                        inactiveColor: isOwn ? Colors.white38 : Colors.grey,
                      )
                    else
                      Text(
                        message.text,
                        style: lang.getTextStyle(
                          fontSize: 14,
                          color: isOwn ? Colors.white : (isDark ? Colors.white : Colors.black87),
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
                            color: isOwn ? Colors.white70 : (isDark ? Colors.white38 : Colors.grey),
                          ),
                        ),
                        if (message.isEdited) ...[
                          const SizedBox(width: 4),
                          Text(
                            _getEditedText(lang),
                            style: TextStyle(
                              fontSize: 9,
                              fontStyle: FontStyle.italic,
                              color: isOwn ? Colors.white60 : (isDark ? Colors.white30 : Colors.grey[400]),
                            ),
                          ),
                        ],
                        if (isOwn) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 14,
                            color: message.isRead ? Colors.lightBlue : Colors.white60,
                          ),
                        ],
                      ],
                    ),
                    // Reactions Display
                    ReactionsDisplay(
                      reactions: message.reactions,
                      isOwnMessage: isOwn,
                      isDark: isDark,
                      onReactionTap: (emoji, hasReacted) {
                        _messageService.toggleReaction(message.id, emoji, hasReacted);
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

  void _showMessageOptions(PrivateMessage message, bool isOwn, LanguageService lang, bool isDark) {
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
                      _messageService.toggleReaction(message.id, emoji, hasReacted);
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
              
              // Copy message
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.teal),
                title: Text(
                  _getCopyText(lang),
                  style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
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
              if (isOwn)
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: Text(
                    _getEditText(lang),
                    style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(message, lang, isDark);
                  },
                ),
              
              // Delete
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  _getDeleteMsgText(lang),
                  style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _messageService.deleteMessage(message.id);
                },
              ),
              
              // Block sender (if not own message)
              if (!isOwn)
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.orange),
                  title: Text(
                    _getBlockText(lang),
                    style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _messageService.blockUser(widget.otherUserId);
                    _checkBlockStatus();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(PrivateMessage message, LanguageService lang, bool isDark) {
    final controller = TextEditingController(text: message.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
        title: Text(
          _getEditText(lang),
          style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
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
          style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getCancelText(lang)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _messageService.editMessage(message.id, controller.text);
            },
            child: Text(_getSaveText(lang)),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, LanguageService lang, bool isDark) async {
    switch (action) {
      case 'block':
        await _messageService.blockUser(widget.otherUserId);
        _checkBlockStatus();
        break;
      case 'unblock':
        await _messageService.unblockUser(widget.otherUserId);
        _checkBlockStatus();
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
            title: Text(
              _getDeleteConvText(lang),
              style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
            content: Text(
              _getDeleteConvDescText(lang),
              style: lang.getTextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(_getCancelText(lang)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(_getDeleteConfirmText(lang), style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await _messageService.deleteConversation(widget.otherUserId);
          if (mounted) Navigator.pop(context);
        }
        break;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Translations
  String _getBlockedStatusText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'محظور';
      case AppLanguage.kurdish: return 'بلۆک کراوە';
      case AppLanguage.english: return 'Blocked';
    }
  }

  String _getBlockedBannerText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'لقد قمت بحظر هذا المستخدم. لا يمكنك إرسال رسائل.';
      case AppLanguage.kurdish: return 'تۆ ئەم بەکارهێنەرەت بلۆک کردووە. ناتوانیت نامە بنێریت.';
      case AppLanguage.english: return 'You blocked this user. You cannot send messages.';
    }
  }

  String _getBlockedHintText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'المستخدم محظور';
      case AppLanguage.kurdish: return 'بەکارهێنەر بلۆک کراوە';
      case AppLanguage.english: return 'User is blocked';
    }
  }

  String _getNoMessagesText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'ابدأ المحادثة';
      case AppLanguage.kurdish: return 'گفتوگۆ دەست پێ بکە';
      case AppLanguage.english: return 'Start a conversation';
    }
  }

  String _getMessageHint(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'اكتب رسالة...';
      case AppLanguage.kurdish: return 'نامەیەک بنووسە...';
      case AppLanguage.english: return 'Type a message...';
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

  String _getDeleteMsgText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حذف الرسالة';
      case AppLanguage.kurdish: return 'سڕینەوەی نامە';
      case AppLanguage.english: return 'Delete Message';
    }
  }

  String _getBlockText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حظر المستخدم';
      case AppLanguage.kurdish: return 'بلۆک کردنی بەکارهێنەر';
      case AppLanguage.english: return 'Block User';
    }
  }

  String _getUnblockText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إلغاء الحظر';
      case AppLanguage.kurdish: return 'لابردنی بلۆک';
      case AppLanguage.english: return 'Unblock';
    }
  }

  String _getDeleteConvText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حذف المحادثة';
      case AppLanguage.kurdish: return 'سڕینەوەی گفتوگۆ';
      case AppLanguage.english: return 'Delete Conversation';
    }
  }

  String _getDeleteConvDescText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'هل تريد حذف جميع الرسائل مع هذا المستخدم؟';
      case AppLanguage.kurdish: return 'ئایا دەتەوێت هەموو نامەکان لەگەڵ ئەم بەکارهێنەرە بسڕیتەوە؟';
      case AppLanguage.english: return 'Delete all messages with this user?';
    }
  }

  String _getCancelText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إلغاء';
      case AppLanguage.kurdish: return 'پەشیمانبوونەوە';
      case AppLanguage.english: return 'Cancel';
    }
  }

  String _getSaveText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حفظ';
      case AppLanguage.kurdish: return 'پاشەکەوت';
      case AppLanguage.english: return 'Save';
    }
  }

  String _getDeleteConfirmText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حذف';
      case AppLanguage.kurdish: return 'سڕینەوە';
      case AppLanguage.english: return 'Delete';
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
}
