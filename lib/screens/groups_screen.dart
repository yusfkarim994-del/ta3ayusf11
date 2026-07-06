import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';
import 'group_chat_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> with SingleTickerProviderStateMixin {
  final _groupService = GroupService();
  final _authService = AuthService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Changed to 3 tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.groups_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                _getTitle(lang),
                style: lang.getTextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => _showCreateGroupDialog(lang, isDark),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF0D9488),
            labelColor: isDark ? Colors.white : Colors.black87,
            unselectedLabelColor: isDark ? Colors.white54 : Colors.grey,
            labelStyle: lang.getTextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: [
              Tab(text: _getMyGroupsText(lang)),
              Tab(text: _getPublicGroupsText(lang)),
              Tab(text: _getPrivateGroupsSectionText(lang)), // New Private Groups Tab
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // My Groups Tab
            _buildMyGroupsList(lang, isDark, currentUserId),
            // Public Groups Tab
            _buildPublicGroupsList(lang, isDark, currentUserId),
            // Private Groups Tab (NEW)
            _buildPrivateGroupsList(lang, isDark, currentUserId),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateGroupDialog(lang, isDark),
          backgroundColor: const Color(0xFF0D9488),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            _getCreateGroupText(lang),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildMyGroupsList(LanguageService lang, bool isDark, String currentUserId) {
    return StreamBuilder<List<ChatGroup>>(
      stream: _groupService.getMyGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups_outlined, size: 80, color: isDark ? Colors.white24 : Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  _getNoGroupsText(lang),
                  style: lang.getTextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showCreateGroupDialog(lang, isDark),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    _getCreateGroupText(lang),
                    style: lang.getTextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }

        final allGroups = snapshot.data!;
        final privateGroups = allGroups.where((g) => g.isPrivate).toList();
        final publicGroups = allGroups.where((g) => !g.isPrivate).toList();

        return ListView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
          children: [
            // Private Groups Section
            if (privateGroups.isNotEmpty) ...[
              _buildSectionHeader(
                icon: Icons.lock,
                title: _getPrivateGroupsSectionText(lang),
                color: Colors.orange,
                isDark: isDark,
                lang: lang,
              ),
              const SizedBox(height: 12),
              ...privateGroups.map((group) => 
                _buildGroupCard(group, lang, isDark, currentUserId, isMyGroup: true)),
              const SizedBox(height: 24),
            ],
            
            // Public Groups Section (My Groups that are public)
            if (publicGroups.isNotEmpty) ...[
              _buildSectionHeader(
                icon: Icons.public,
                title: _getPublicGroupsSectionText(lang),
                color: Colors.green,
                isDark: isDark,
                lang: lang,
              ),
              const SizedBox(height: 12),
              ...publicGroups.map((group) => 
                _buildGroupCard(group, lang, isDark, currentUserId, isMyGroup: true)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
    required LanguageService lang,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: lang.getTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicGroupsList(LanguageService lang, bool isDark, String currentUserId) {
    return StreamBuilder<List<ChatGroup>>(
      stream: _groupService.getPublicGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.public_off, size: 80, color: isDark ? Colors.white24 : Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  _getNoPublicGroupsText(lang),
                  style: lang.getTextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final groups = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final isMember = group.isMember(currentUserId);
            return _buildGroupCard(group, lang, isDark, currentUserId, isMyGroup: isMember);
          },
        );
      },
    );
  }

  Widget _buildPrivateGroupsList(LanguageService lang, bool isDark, String currentUserId) {
    return StreamBuilder<List<ChatGroup>>(
      stream: _groupService.getPrivateGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: isDark ? Colors.white24 : Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  _getNoPrivateGroupsText(lang),
                  style: lang.getTextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final groups = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final isMember = group.isMember(currentUserId);
            return _buildGroupCard(group, lang, isDark, currentUserId, isMyGroup: isMember);
          },
        );
      },
    );
  }

  Widget _buildGroupCard(ChatGroup group, LanguageService lang, bool isDark, String currentUserId, {required bool isMyGroup}) {
    final isOwner = group.isOwner(currentUserId);
    final isAdmin = group.isAdmin(currentUserId);
    final hasPending = group.hasPendingRequest(currentUserId);
    final pendingCount = group.pendingRequestIds.length;
    final isAppAdminUser = _groupService.isAppAdmin;

    return GestureDetector(
      onTap: isMyGroup
          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatScreen(groupId: group.id)))
          : null,
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
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Group Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: group.isPrivate
                      ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)]
                      : [const Color(0xFF0D9488), const Color(0xFF0F766E)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: group.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(group.imageUrl!, fit: BoxFit.cover),
                    )
                  : Icon(
                      group.isPrivate ? Icons.lock : Icons.groups,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
            const SizedBox(width: 16),
            // Group Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          style: lang.getTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOwner)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getOwnerText(lang),
                            style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (!isOwner && isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getAdminText(lang),
                            style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        group.isPrivate ? Icons.lock_outline : Icons.public,
                        size: 14,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        group.isPrivate ? _getPrivateText(lang) : _getPublicText(lang),
                        style: lang.getTextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.people_outline, size: 14, color: isDark ? Colors.white54 : Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${group.memberIds.length}',
                        style: lang.getTextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  // Show pending requests count for admins
                  if (isAdmin && pendingCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.pending_actions, size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              '$pendingCount ${_getPendingText(lang)}',
                              style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Action Button
            if (!isMyGroup)
              ElevatedButton(
                onPressed: hasPending
                    ? null
                    : () async {
                        if (group.isPrivate) {
                          // Request to join
                          final success = await _groupService.requestToJoin(group.id);
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_getRequestSentText(lang)),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          // Join directly
                          final success = await _groupService.joinPublicGroup(group.id);
                          if (success && mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatScreen(groupId: group.id)));
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasPending ? Colors.grey : const Color(0xFF0D9488),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  hasPending
                      ? _getPendingRequestText(lang)
                      : group.isPrivate
                          ? _getRequestJoinText(lang)
                          : _getJoinText(lang),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            if (isMyGroup)
              Icon(
                lang.isRTL ? Icons.chevron_left : Icons.chevron_right,
                color: isDark ? Colors.white38 : Colors.grey,
              ),
            // App Admin Delete Button
            if (isAppAdminUser)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: GestureDetector(
                  onTap: () => _showAdminDeleteGroupDialog(group, lang, isDark),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAdminDeleteGroupDialog(ChatGroup group, LanguageService lang, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: lang.textDirection,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getDeleteGroupTitle(lang),
                  style: lang.getTextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            _getDeleteGroupMessage(lang, group.name),
            style: lang.getTextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                _getCancelText(lang),
                style: lang.getTextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _groupService.deleteGroup(group.id);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(_getGroupDeletedText(lang)),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _getDeleteText(lang),
                style: lang.getTextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog(LanguageService lang, bool isDark) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isPrivate = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1a2a4a) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Directionality(
              textDirection: lang.textDirection,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
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
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.group_add, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getCreateGroupText(lang),
                        style: lang.getTextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Group Name
                  TextField(
                    controller: nameController,
                    textDirection: lang.textDirection,
                    decoration: InputDecoration(
                      labelText: _getGroupNameText(lang),
                      labelStyle: lang.getTextStyle(color: isDark ? Colors.white54 : Colors.grey),
                      prefixIcon: Icon(Icons.edit, color: isDark ? Colors.white54 : Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
                    ),
                    style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  // Description
                  TextField(
                    controller: descController,
                    textDirection: lang.textDirection,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: _getDescriptionText(lang),
                      labelStyle: lang.getTextStyle(color: isDark ? Colors.white54 : Colors.grey),
                      prefixIcon: Icon(Icons.description, color: isDark ? Colors.white54 : Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
                    ),
                    style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  // Privacy Toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPrivate ? Icons.lock : Icons.public,
                          color: isPrivate ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPrivate ? _getPrivateGroupText(lang) : _getPublicGroupText(lang),
                                style: lang.getTextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                isPrivate ? _getPrivateDescText(lang) : _getPublicDescText(lang),
                                style: lang.getTextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isPrivate,
                          onChanged: (value) => setModalState(() => isPrivate = value),
                          activeColor: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_getEnterNameText(lang)), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        // Close dialog immediately
                        Navigator.pop(context);
                        
                        // Show "Creating" snackbar
                        final creatingText = lang.currentLanguage == AppLanguage.kurdish ? 'خەریکی دروستکردنی گروپە...' : (lang.currentLanguage == AppLanguage.arabic ? 'جاري إنشاء المجموعة...' : 'Creating group...');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(creatingText), duration: const Duration(seconds: 2)),
                        );

                        // Trigger creation in background
                        _groupService.createGroup(
                          name: name,
                          description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                          isPrivate: isPrivate,
                        ).then((groupId) {
                          if (groupId != null && mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatScreen(groupId: groupId)));
                          }
                        }).catchError((e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _getCreateText(lang),
                        style: lang.getTextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Localization helpers
  String _getTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'المجموعات';
      case AppLanguage.kurdish: return 'گروپەکان';
      case AppLanguage.english: return 'Groups';
    }
  }

  String _getMyGroupsText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'مجموعاتي';
      case AppLanguage.kurdish: return 'گروپەکانم';
      case AppLanguage.english: return 'My Groups';
    }
  }

  String _getPublicGroupsText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'المجموعات العامة';
      case AppLanguage.kurdish: return 'گروپە گشتیەکان';
      case AppLanguage.english: return 'Public Groups';
    }
  }

  String _getCreateGroupText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إنشاء مجموعة';
      case AppLanguage.kurdish: return 'دروستکردنی گروپ';
      case AppLanguage.english: return 'Create Group';
    }
  }

  String _getNoGroupsText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'لا توجد مجموعات بعد';
      case AppLanguage.kurdish: return 'هێشتا هیچ گروپێکت نییە';
      case AppLanguage.english: return 'No groups yet';
    }
  }

  String _getNoPublicGroupsText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'لا توجد مجموعات عامة';
      case AppLanguage.kurdish: return 'هیچ گروپێکی گشتی نییە';
      case AppLanguage.english: return 'No public groups';
    }
  }

  String _getNoPrivateGroupsText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'لا توجد مجموعات خاصة';
      case AppLanguage.kurdish: return 'هیچ گروپێکی تایبەت نییە';
      case AppLanguage.english: return 'No private groups';
    }
  }

  String _getPrivateGroupsSectionText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'المجموعات الخاصة';
      case AppLanguage.kurdish: return 'گروپە تایبەتەکان';
      case AppLanguage.english: return 'Private Groups';
    }
  }

  String _getPublicGroupsSectionText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'المجموعات العامة';
      case AppLanguage.kurdish: return 'گروپە گشتیەکان';
      case AppLanguage.english: return 'Public Groups';
    }
  }

  String _getOwnerText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'مالك';
      case AppLanguage.kurdish: return 'خاوەن';
      case AppLanguage.english: return 'Owner';
    }
  }

  String _getAdminText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'مشرف';
      case AppLanguage.kurdish: return 'ئەدمین';
      case AppLanguage.english: return 'Admin';
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

  String _getPendingText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'طلب انتظار';
      case AppLanguage.kurdish: return 'داواکاری چاوەڕوان';
      case AppLanguage.english: return 'pending requests';
    }
  }

  String _getJoinText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'انضمام';
      case AppLanguage.kurdish: return 'چوونە ناو';
      case AppLanguage.english: return 'Join';
    }
  }

  String _getRequestJoinText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'طلب الانضمام';
      case AppLanguage.kurdish: return 'داواکردن';
      case AppLanguage.english: return 'Request';
    }
  }

  String _getPendingRequestText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'في الانتظار';
      case AppLanguage.kurdish: return 'چاوەڕوانە';
      case AppLanguage.english: return 'Pending';
    }
  }

  String _getRequestSentText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تم إرسال طلب الانضمام';
      case AppLanguage.kurdish: return 'داواکاریەکەت نێردرا';
      case AppLanguage.english: return 'Join request sent';
    }
  }

  String _getGroupNameText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'اسم المجموعة';
      case AppLanguage.kurdish: return 'ناوی گروپ';
      case AppLanguage.english: return 'Group Name';
    }
  }

  String _getDescriptionText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'الوصف (اختياري)';
      case AppLanguage.kurdish: return 'وەسف (ئارەزوومەندانە)';
      case AppLanguage.english: return 'Description (optional)';
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
      case AppLanguage.arabic: return 'يحتاج الانضمام إلى موافقة المشرف';
      case AppLanguage.kurdish: return 'بۆ چوونە ناو پێویستی بە ڕەزامەندی ئەدمینە';
      case AppLanguage.english: return 'Joining requires admin approval';
    }
  }

  String _getPublicDescText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'يمكن للجميع الانضمام مباشرة';
      case AppLanguage.kurdish: return 'هەموان ڕاستەوخۆ دەتوانن بچنە ناوەوە';
      case AppLanguage.english: return 'Anyone can join directly';
    }
  }

  String _getEnterNameText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'أدخل اسم المجموعة';
      case AppLanguage.kurdish: return 'ناوی گروپ بنووسە';
      case AppLanguage.english: return 'Enter group name';
    }
  }

  String _getCreateText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إنشاء';
      case AppLanguage.kurdish: return 'دروستکردن';
      case AppLanguage.english: return 'Create';
    }
  }

  String _getDeleteGroupTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حذف المجموعة';
      case AppLanguage.kurdish: return 'سڕینەوەی گروپ';
      case AppLanguage.english: return 'Delete Group';
    }
  }

  String _getDeleteGroupMessage(LanguageService lang, String groupName) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'هل أنت متأكد من حذف "$groupName"؟ سيتم حذف جميع الرسائل أيضاً. لا يمكن التراجع عن هذا الإجراء.';
      case AppLanguage.kurdish: return 'دڵنیایت لە سڕینەوەی "$groupName"؟ هەموو نامەکانیش دەسڕدرێنەوە. ناتوانرێت ئەم کردارە بگەڕێنیتەوە.';
      case AppLanguage.english: return 'Are you sure you want to delete "$groupName"? All messages will also be deleted. This action cannot be undone.';
    }
  }

  String _getCancelText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إلغاء';
      case AppLanguage.kurdish: return 'پاشگەزبوونەوە';
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

  String _getGroupDeletedText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تم حذف المجموعة بنجاح';
      case AppLanguage.kurdish: return 'گروپەکە بە سەرکەوتوویی سڕایەوە';
      case AppLanguage.english: return 'Group deleted successfully';
    }
  }
}
