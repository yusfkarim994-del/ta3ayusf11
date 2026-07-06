import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../services/language_service.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';

class GroupSettingsScreen extends StatefulWidget {
  final String groupId;

  const GroupSettingsScreen({super.key, required this.groupId});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  final _groupService = GroupService();
  final _authService = AuthService();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = lang.isDarkMode;
    final currentUserId = _authService.currentUser?.uid ?? '';

    return StreamBuilder<ChatGroup?>(
      stream: _groupService.getGroup(widget.groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final group = snapshot.data;
        if (group == null) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
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

        final isOwner = group.isOwner(currentUserId);
        final isAdmin = group.isAdmin(currentUserId);

        return Directionality(
          textDirection: lang.textDirection,
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
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
              title: Text(
                _getSettingsText(lang),
                style: lang.getTextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Header Card
                  _buildGroupHeaderCard(group, isOwner, isAdmin, lang, isDark),
                  const SizedBox(height: 24),

                  // Group Info Section (editable by admin)
                  if (isAdmin) ...[
                    _buildSectionTitle(_getGroupInfoText(lang), lang, isDark),
                    const SizedBox(height: 12),
                    _buildEditNameTile(group, lang, isDark),
                    const SizedBox(height: 8),
                    _buildEditDescriptionTile(group, lang, isDark),
                    const SizedBox(height: 8),
                    _buildPrivacyToggleTile(group, lang, isDark),
                    const SizedBox(height: 24),
                  ],

                  // Pending Requests Section (for private groups, admins only)
                  if (isAdmin && group.isPrivate && group.pendingRequestIds.isNotEmpty) ...[
                    _buildSectionTitle(
                      '${_getPendingRequestsText(lang)} (${group.pendingRequestIds.length})',
                      lang,
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    ...group.pendingRequestIds.map((userId) => _buildPendingRequestTile(userId, lang, isDark)),
                    const SizedBox(height: 24),
                  ],

                  // Members Section
                  _buildSectionTitle(
                    '${_getMembersText(lang)} (${group.memberIds.length})',
                    lang,
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  ...group.memberIds.map((userId) {
                    final memberRole = group.getUserRole(userId);
                    return _buildMemberTile(userId, memberRole!, group, isOwner, isAdmin, lang, isDark);
                  }),
                  const SizedBox(height: 24),

                  // Danger Zone
                  _buildSectionTitle(_getDangerZoneText(lang), lang, isDark, color: Colors.red),
                  const SizedBox(height: 12),
                  if (!isOwner)
                    _buildDangerButton(
                      icon: Icons.exit_to_app,
                      title: _getLeaveGroupText(lang),
                      color: Colors.orange,
                      lang: lang,
                      isDark: isDark,
                      onTap: () => _confirmLeaveGroup(lang, isDark),
                    ),
                  if (isOwner)
                    _buildDangerButton(
                      icon: Icons.delete_forever,
                      title: _getDeleteGroupText(lang),
                      color: Colors.red,
                      lang: lang,
                      isDark: isDark,
                      onTap: () => _confirmDeleteGroup(lang, isDark),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupHeaderCard(ChatGroup group, bool isOwner, bool isAdmin, LanguageService lang, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Group Avatar with Edit Button
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: group.isPrivate 
                    ? const Color(0xFFEF4444).withOpacity(isDark ? 0.2 : 0.1)
                    : const Color(0xFF0D9488).withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: group.isPrivate 
                      ? const Color(0xFFEF4444).withOpacity(0.5) 
                      : const Color(0xFF0D9488).withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: _isUploading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : group.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(group.imageUrl!, fit: BoxFit.cover),
                          )
                        : Icon(
                            group.isPrivate ? Icons.lock : Icons.groups,
                            color: Colors.white,
                            size: 48,
                          ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            group.name,
            style: lang.getTextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          if (group.description != null && group.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              group.description!,
              style: lang.getTextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip(
                icon: group.isPrivate ? Icons.lock : Icons.public,
                label: group.isPrivate ? _getPrivateText(lang) : _getPublicText(lang),
                color: group.isPrivate ? Colors.orange : Colors.green,
                lang: lang,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.people,
                label: '${group.memberIds.length} ${_getMembersText(lang)}',
                color: const Color(0xFF0D9488),
                lang: lang,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    required LanguageService lang,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, LanguageService lang, bool isDark, {Color? color}) {
    return Text(
      title,
      style: lang.getTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: color ?? (isDark ? Colors.white70 : Colors.black54),
      ),
    );
  }

  Widget _buildEditNameTile(ChatGroup group, LanguageService lang, bool isDark) {
    return _buildSettingsTile(
      icon: Icons.edit,
      title: _getEditNameText(lang),
      subtitle: group.name,
      color: Colors.blue,
      isDark: isDark,
      lang: lang,
      onTap: () => _showEditNameDialog(group, lang, isDark),
    );
  }

  Widget _buildEditDescriptionTile(ChatGroup group, LanguageService lang, bool isDark) {
    return _buildSettingsTile(
      icon: Icons.description,
      title: _getEditDescriptionText(lang),
      subtitle: group.description ?? _getNoDescriptionText(lang),
      color: Colors.teal,
      isDark: isDark,
      lang: lang,
      onTap: () => _showEditDescriptionDialog(group, lang, isDark),
    );
  }

  Widget _buildPrivacyToggleTile(ChatGroup group, LanguageService lang, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (group.isPrivate ? Colors.orange : Colors.green).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              group.isPrivate ? Icons.lock : Icons.public,
              color: group.isPrivate ? Colors.orange : Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.isPrivate ? _getPrivateGroupText(lang) : _getPublicGroupText(lang),
                  style: lang.getTextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  group.isPrivate ? _getPrivateDescText(lang) : _getPublicDescText(lang),
                  style: lang.getTextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: group.isPrivate,
            onChanged: (value) async {
              await _groupService.updateGroupPrivacy(widget.groupId, value);
            },
            activeColor: Colors.orange,
            inactiveThumbColor: Colors.green,
            inactiveTrackColor: Colors.green.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestTile(String userId, LanguageService lang, bool isDark) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _groupService.getUserInfo(userId),
      builder: (context, snapshot) {
        final userName = snapshot.data?['name'] ?? 'User';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.orange.withOpacity(0.2),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  userName,
                  style: lang.getTextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  await _groupService.approveJoinRequest(widget.groupId, userId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_getApprovedText(lang)),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check, color: Colors.green, size: 20),
                ),
              ),
              IconButton(
                onPressed: () async {
                  await _groupService.rejectJoinRequest(widget.groupId, userId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_getRejectedText(lang)),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, color: Colors.red, size: 20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemberTile(
    String userId,
    GroupMemberRole role,
    ChatGroup group,
    bool isOwner,
    bool isAdmin,
    LanguageService lang,
    bool isDark,
  ) {
    final isCurrentUser = userId == _authService.currentUser?.uid;
    final memberIsOwner = role == GroupMemberRole.owner;
    final memberIsAdmin = role == GroupMemberRole.admin;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _groupService.getUserInfo(userId),
      builder: (context, snapshot) {
        final userName = snapshot.data?['name'] ?? 'User';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: memberIsOwner
                    ? Colors.amber.withOpacity(0.2)
                    : memberIsAdmin
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: memberIsOwner ? Colors.amber : memberIsAdmin ? Colors.blue : Colors.grey,
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
                        Text(
                          userName,
                          style: lang.getTextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getYouText(lang),
                              style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _getRoleText(role, lang),
                      style: lang.getTextStyle(
                        fontSize: 12,
                        color: memberIsOwner
                            ? Colors.amber
                            : memberIsAdmin
                                ? Colors.blue
                                : (isDark ? Colors.white54 : Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              // Actions (only for owner managing admins, or admins managing members)
              if (!isCurrentUser && !memberIsOwner)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: isDark ? Colors.white54 : Colors.grey),
                  onSelected: (value) async {
                    switch (value) {
                      case 'make_admin':
                        await _groupService.addAdmin(widget.groupId, userId);
                        break;
                      case 'remove_admin':
                        await _groupService.removeAdmin(widget.groupId, userId);
                        break;
                      case 'remove':
                        await _groupService.removeMember(widget.groupId, userId);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    // Make admin (owner only, for regular members)
                    if (isOwner && !memberIsAdmin)
                      PopupMenuItem(
                        value: 'make_admin',
                        child: Row(
                          children: [
                            const Icon(Icons.admin_panel_settings, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text(_getMakeAdminText(lang)),
                          ],
                        ),
                      ),
                    // Remove admin (owner only, for admins)
                    if (isOwner && memberIsAdmin)
                      PopupMenuItem(
                        value: 'remove_admin',
                        child: Row(
                          children: [
                            const Icon(Icons.remove_moderator, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Text(_getRemoveAdminText(lang)),
                          ],
                        ),
                      ),
                    // Remove member (admin can remove members, owner can remove anyone except self)
                    if ((isAdmin && !memberIsAdmin) || isOwner)
                      PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            const Icon(Icons.person_remove, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Text(_getRemoveMemberText(lang)),
                          ],
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

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required LanguageService lang,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: lang.getTextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: lang.getTextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              lang.isRTL ? Icons.chevron_left : Icons.chevron_right,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerButton({
    required IconData icon,
    required String title,
    required Color color,
    required LanguageService lang,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: lang.getTextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(ChatGroup group, LanguageService lang, bool isDark) {
    final controller = TextEditingController(text: group.name);
    
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: lang.textDirection,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            _getEditNameText(lang),
            style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            textDirection: lang.textDirection,
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
                  await _groupService.updateGroupName(widget.groupId, controller.text.trim());
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

  void _showEditDescriptionDialog(ChatGroup group, LanguageService lang, bool isDark) {
    final controller = TextEditingController(text: group.description ?? '');
    
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: lang.textDirection,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            _getEditDescriptionText(lang),
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
                await _groupService.updateGroupDescription(
                  widget.groupId,
                  controller.text.trim().isEmpty ? null : controller.text.trim(),
                );
                if (mounted) Navigator.pop(context);
              },
              child: Text(_getSaveText(lang), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLeaveGroup(LanguageService lang, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: lang.textDirection,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            _getLeaveGroupText(lang),
            style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Text(
            _getLeaveConfirmText(lang),
            style: lang.getTextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.cancel, style: lang.getTextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                await _groupService.leaveGroup(widget.groupId);
                if (mounted) {
                  Navigator.pop(context); // Dialog
                  Navigator.pop(context); // Settings
                  Navigator.pop(context); // Chat
                }
              },
              child: Text(_getLeaveText(lang), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteGroup(LanguageService lang, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: lang.textDirection,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            _getDeleteGroupText(lang),
            style: lang.getTextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Text(
            _getDeleteConfirmText(lang),
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
                await _groupService.deleteGroup(widget.groupId);
                if (mounted) {
                  Navigator.pop(context); // Dialog
                  Navigator.pop(context); // Settings
                  Navigator.pop(context); // Chat
                }
              },
              child: Text(_getDeleteText(lang), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Localization helpers
  String _getGroupNotFoundText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'المجموعة غير موجودة';
      case AppLanguage.kurdish: return 'گروپەکە نەدۆزرایەوە';
      case AppLanguage.english: return 'Group not found';
    }
  }

  String _getSettingsText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إعدادات المجموعة';
      case AppLanguage.kurdish: return 'ڕێکخستنەکانی گروپ';
      case AppLanguage.english: return 'Group Settings';
    }
  }

  String _getGroupInfoText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'معلومات المجموعة';
      case AppLanguage.kurdish: return 'زانیاری گروپ';
      case AppLanguage.english: return 'Group Info';
    }
  }

  String _getPendingRequestsText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'طلبات الانضمام';
      case AppLanguage.kurdish: return 'داواکاریەکانی چوونە ناو';
      case AppLanguage.english: return 'Join Requests';
    }
  }

  String _getMembersText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'الأعضاء';
      case AppLanguage.kurdish: return 'ئەندامەکان';
      case AppLanguage.english: return 'Members';
    }
  }

  String _getDangerZoneText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'منطقة الخطر';
      case AppLanguage.kurdish: return 'ناوچەی مەترسیدار';
      case AppLanguage.english: return 'Danger Zone';
    }
  }

  String _getPrivateText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'خاص';
      case AppLanguage.kurdish: return 'تایبەت';
      case AppLanguage.english: return 'Private';
    }
  }

  String _getPublicText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'عام';
      case AppLanguage.kurdish: return 'گشتی';
      case AppLanguage.english: return 'Public';
    }
  }

  String _getEditNameText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تعديل الاسم';
      case AppLanguage.kurdish: return 'گۆڕینی ناو';
      case AppLanguage.english: return 'Edit Name';
    }
  }

  String _getEditDescriptionText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تعديل الوصف';
      case AppLanguage.kurdish: return 'گۆڕینی وەسف';
      case AppLanguage.english: return 'Edit Description';
    }
  }

  String _getNoDescriptionText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'لا يوجد وصف';
      case AppLanguage.kurdish: return 'وەسف نییە';
      case AppLanguage.english: return 'No description';
    }
  }

  String _getPrivateGroupText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'مجموعة خاصة';
      case AppLanguage.kurdish: return 'گروپی تایبەت';
      case AppLanguage.english: return 'Private Group';
    }
  }

  String _getPublicGroupText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'مجموعة عامة';
      case AppLanguage.kurdish: return 'گروپی گشتی';
      case AppLanguage.english: return 'Public Group';
    }
  }

  String _getPrivateDescText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'يحتاج الانضمام إلى موافقة';
      case AppLanguage.kurdish: return 'پێویستی بە ڕەزامەندی هەیە';
      case AppLanguage.english: return 'Joining requires approval';
    }
  }

  String _getPublicDescText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'يمكن للجميع الانضمام';
      case AppLanguage.kurdish: return 'هەموان دەتوانن بچنە ناو';
      case AppLanguage.english: return 'Anyone can join';
    }
  }

  String _getApprovedText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تمت الموافقة';
      case AppLanguage.kurdish: return 'پەسەندکرا';
      case AppLanguage.english: return 'Approved';
    }
  }

  String _getRejectedText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تم الرفض';
      case AppLanguage.kurdish: return 'ڕەتکرایەوە';
      case AppLanguage.english: return 'Rejected';
    }
  }

  String _getYouText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'أنت';
      case AppLanguage.kurdish: return 'تۆ';
      case AppLanguage.english: return 'You';
    }
  }

  String _getRoleText(GroupMemberRole role, LanguageService lang) {
    switch (role) {
      case GroupMemberRole.owner:
        switch (lang.currentLanguage) {
          case AppLanguage.arabic: return 'المالك';
          case AppLanguage.kurdish: return 'خاوەن';
          case AppLanguage.english: return 'Owner';
        }
      case GroupMemberRole.admin:
        switch (lang.currentLanguage) {
          case AppLanguage.arabic: return 'مشرف';
          case AppLanguage.kurdish: return 'ئەدمین';
          case AppLanguage.english: return 'Admin';
        }
      case GroupMemberRole.member:
        switch (lang.currentLanguage) {
          case AppLanguage.arabic: return 'عضو';
          case AppLanguage.kurdish: return 'ئەندام';
          case AppLanguage.english: return 'Member';
        }
    }
  }

  String _getMakeAdminText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'جعله مشرف';
      case AppLanguage.kurdish: return 'ئەدمینی بکە';
      case AppLanguage.english: return 'Make Admin';
    }
  }

  String _getRemoveAdminText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إزالة المشرف';
      case AppLanguage.kurdish: return 'لابردنی ئەدمین';
      case AppLanguage.english: return 'Remove Admin';
    }
  }

  String _getRemoveMemberText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'طرد العضو';
      case AppLanguage.kurdish: return 'دەرکردنی ئەندام';
      case AppLanguage.english: return 'Remove Member';
    }
  }

  String _getLeaveGroupText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'مغادرة المجموعة';
      case AppLanguage.kurdish: return 'دەرچوون لە گروپ';
      case AppLanguage.english: return 'Leave Group';
    }
  }

  String _getDeleteGroupText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حذف المجموعة';
      case AppLanguage.kurdish: return 'سڕینەوەی گروپ';
      case AppLanguage.english: return 'Delete Group';
    }
  }

  String _getSaveText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حفظ';
      case AppLanguage.kurdish: return 'پاشەکەوتکردن';
      case AppLanguage.english: return 'Save';
    }
  }

  String _getLeaveConfirmText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'هل أنت متأكد أنك تريد مغادرة هذه المجموعة؟';
      case AppLanguage.kurdish: return 'دڵنیایت کە دەتەوێت لەم گروپە دەربچیت؟';
      case AppLanguage.english: return 'Are you sure you want to leave this group?';
    }
  }

  String _getLeaveText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'مغادرة';
      case AppLanguage.kurdish: return 'دەرچوون';
      case AppLanguage.english: return 'Leave';
    }
  }

  String _getDeleteConfirmText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'هل أنت متأكد؟ سيتم حذف جميع الرسائل والبيانات نهائياً!';
      case AppLanguage.kurdish: return 'دڵنیایت؟ هەموو نامەکان و داتاکان بۆ هەمیشە دەسڕێنەوە!';
      case AppLanguage.english: return 'Are you sure? All messages and data will be permanently deleted!';
    }
  }

  String _getDeleteText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حذف';
      case AppLanguage.kurdish: return 'سڕینەوە';
      case AppLanguage.english: return 'Delete';
    }
  }
}
