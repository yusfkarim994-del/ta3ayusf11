import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Available reaction emojis (Islamic-friendly)
const List<String> availableReactions = ['❤️', '👍', '😂', '😮', '😢', '🤲'];

/// Get emoji text style that ensures color emojis are displayed
TextStyle getEmojiStyle(double fontSize) {
  return TextStyle(
    fontSize: fontSize,
    fontFamily: kIsWeb ? null : 'Apple Color Emoji',
    fontFamilyFallback: const [
      'Apple Color Emoji',
      'Segoe UI Emoji',
      'Noto Color Emoji',
      'Android Emoji',
    ],
  );
}

/// Widget to display reactions on a message
class ReactionsDisplay extends StatelessWidget {
  final Map<String, List<String>> reactions;
  final bool isOwnMessage;
  final bool isDark;
  final Function(String emoji, bool hasReacted) onReactionTap;

  const ReactionsDisplay({
    super.key,
    required this.reactions,
    required this.isOwnMessage,
    required this.isDark,
    required this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    // Filter out empty reaction lists
    final activeReactions = reactions.entries
        .where((e) => e.value.isNotEmpty)
        .toList();
    
    if (activeReactions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        alignment: isOwnMessage ? WrapAlignment.end : WrapAlignment.start,
        children: activeReactions.map((entry) {
          final emoji = entry.key;
          final userIds = entry.value;
          final count = userIds.length;
          final hasUserReacted = userIds.contains(currentUserId);
          
          return GestureDetector(
            onTap: () => onReactionTap(emoji, hasUserReacted),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasUserReacted 
                    ? const Color(0xFF667EEA).withOpacity(0.3)
                    : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(12),
                border: hasUserReacted 
                    ? Border.all(color: const Color(0xFF667EEA).withOpacity(0.5))
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: getEmojiStyle(14)),
                  if (count > 1) ...[
                    const SizedBox(width: 4),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Show reaction picker popup
void showReactionPicker({
  required BuildContext context,
  required bool isDark,
  required Function(String emoji) onReactionSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2a4a) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: availableReactions.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onReactionSelected(emoji);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withOpacity(0.1) 
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      emoji,
                      style: getEmojiStyle(28),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ),
  );
}
