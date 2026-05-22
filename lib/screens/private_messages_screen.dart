import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/private_message_service.dart';
import 'private_chat_screen.dart';

class PrivateMessagesScreen extends StatefulWidget {
  const PrivateMessagesScreen({super.key});

  @override
  State<PrivateMessagesScreen> createState() => _PrivateMessagesScreenState();
}

class _PrivateMessagesScreenState extends State<PrivateMessagesScreen> {
  final _messageService = PrivateMessageService();

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = lang.isDarkMode;

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mail_rounded, color: Colors.white, size: 20),
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
        ),
        body: StreamBuilder<List<Conversation>>(
          stream: _messageService.getConversations(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

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

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mail_outline, size: 80, color: isDark ? Colors.white24 : Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      _getNoMessagesText(lang),
                      style: lang.getTextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            final conversations = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conv = conversations[index];
                return _buildConversationTile(conv, lang, isDark);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildConversationTile(Conversation conv, LanguageService lang, bool isDark) {
    return Dismissible(
      key: Key('conv_${conv.odirUserId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: lang.isRTL ? Alignment.centerLeft : Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) => _confirmDelete(conv, lang, isDark),
      child: GestureDetector(
        onTap: () => _openChat(conv),
        onLongPress: () => _showOptions(conv, lang, isDark),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a2a4a) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: conv.isBlocked 
                        ? Colors.red.withOpacity(0.2) 
                        : Colors.purple.withOpacity(0.2),
                    child: Text(
                      conv.otherUserName.isNotEmpty ? conv.otherUserName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: conv.isBlocked ? Colors.red : Colors.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  // Unread badge
                  if (conv.unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          conv.unreadCount > 99 ? '99+' : '${conv.unreadCount}',
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
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conv.otherUserName,
                            style: lang.getTextStyle(
                              fontSize: 16,
                              fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(conv.lastMessageTime, lang),
                          style: TextStyle(
                            fontSize: 12,
                            color: conv.unreadCount > 0 
                                ? Colors.blue 
                                : (isDark ? Colors.white38 : Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (conv.isBlocked) ...[
                          Icon(Icons.block, size: 14, color: Colors.red.withOpacity(0.7)),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            conv.isBlocked ? _getBlockedText(lang) : conv.lastMessage,
                            style: lang.getTextStyle(
                              fontSize: 13,
                              color: conv.isBlocked 
                                  ? Colors.red.withOpacity(0.7)
                                  : (isDark ? Colors.white54 : Colors.grey[600]),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                lang.isRTL ? Icons.chevron_left : Icons.chevron_right,
                color: isDark ? Colors.white24 : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChat(Conversation conv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrivateChatScreen(
          otherUserId: conv.odirUserId,
          otherUserName: conv.otherUserName,
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(Conversation conv, LanguageService lang, bool isDark) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
        title: Text(
          _getDeleteConvTitle(lang),
          style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          _getDeleteConvDesc(lang),
          style: lang.getTextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_getCancelText(lang)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_getDeleteText(lang), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _messageService.deleteConversation(conv.odirUserId);
      return true;
    }
    return false;
  }

  void _showOptions(Conversation conv, LanguageService lang, bool isDark) {
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
              const SizedBox(height: 20),
              
              // Delete conversation
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  _getDeleteConvTitle(lang),
                  style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _confirmDelete(conv, lang, isDark);
                  setState(() {});
                },
              ),
              
              // Block/Unblock user
              ListTile(
                leading: Icon(
                  conv.isBlocked ? Icons.check_circle : Icons.block,
                  color: conv.isBlocked ? Colors.green : Colors.orange,
                ),
                title: Text(
                  conv.isBlocked ? _getUnblockText(lang) : _getBlockText(lang),
                  style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  if (conv.isBlocked) {
                    await _messageService.unblockUser(conv.odirUserId);
                  } else {
                    await _messageService.blockUser(conv.odirUserId);
                  }
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time, LanguageService lang) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return lang.currentLanguage == AppLanguage.arabic ? 'أمس' 
          : lang.currentLanguage == AppLanguage.kurdish ? 'دوێنێ' 
          : 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  // Translations
  String _getTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'الرسائل الخاصة';
      case AppLanguage.kurdish: return 'نامە تایبەتەکان';
      case AppLanguage.english: return 'Private Messages';
    }
  }

  String _getNoMessagesText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'لا توجد رسائل خاصة';
      case AppLanguage.kurdish: return 'هیچ نامەیەکی تایبەت نییە';
      case AppLanguage.english: return 'No private messages';
    }
  }

  String _getBlockedText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تم حظر هذا المستخدم';
      case AppLanguage.kurdish: return 'ئەم بەکارهێنەرە بلۆک کراوە';
      case AppLanguage.english: return 'This user is blocked';
    }
  }

  String _getDeleteConvTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حذف المحادثة';
      case AppLanguage.kurdish: return 'سڕینەوەی گفتوگۆ';
      case AppLanguage.english: return 'Delete Conversation';
    }
  }

  String _getDeleteConvDesc(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'هل تريد حذف هذه المحادثة؟';
      case AppLanguage.kurdish: return 'ئایا دەتەوێت ئەم گفتوگۆیە بسڕیتەوە؟';
      case AppLanguage.english: return 'Do you want to delete this conversation?';
    }
  }

  String _getCancelText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إلغاء';
      case AppLanguage.kurdish: return 'پەشیمانبوونەوە';
      case AppLanguage.english: return 'Cancel';
    }
  }

  String _getDeleteText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حذف';
      case AppLanguage.kurdish: return 'سڕینەوە';
      case AppLanguage.english: return 'Delete';
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
      case AppLanguage.english: return 'Unblock User';
    }
  }
}
