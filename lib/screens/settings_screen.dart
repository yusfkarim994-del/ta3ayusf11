import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/language_service.dart';
import '../services/quotes_service.dart';
import '../services/upload_service.dart';
import '../services/tips_service.dart';
import '../services/app_lock_service.dart';
import '../services/app_disguise_service.dart';
import 'login_screen.dart';
import 'content_management_screen.dart';
import 'app_lock_screen.dart';
import 'webview_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _nameController = TextEditingController();
  final _quotesService = QuotesService();
  final _imagePicker = ImagePicker();
  final _tipsService = TipsService();
  bool _isLoading = false;
  bool _isUploadingImage = false;
  Uint8List? _profileImage;
  String? _profileImageUrl;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  bool get _isDeveloper => _quotesService.isDeveloper;
  bool get _isAdmin => _tipsService.isAdmin;

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _profileImageUrl = user.photoURL;
      
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          if (doc.data()?['displayName'] != null) _nameController.text = doc.data()!['displayName'];
          if (doc.data()?['photoURL'] != null) _profileImageUrl = doc.data()!['photoURL'];
          if (doc.data()?['userId'] != null) _userId = doc.data()!['userId'];
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
      setState(() {});
    }
  }

  Future<void> _updateDisplayName() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(_nameController.text.trim());
        await _firestore.collection('users').doc(user.uid).set({
          'displayName': _nameController.text.trim(),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        if (mounted) _showSnackBar(_getSuccessMessage(), Colors.green);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', Colors.red);
    }
    setState(() => _isLoading = false);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  String _getSuccessMessage() {
    final lang = Provider.of<LanguageService>(context, listen: false);
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تم تحديث الاسم بنجاح';
      case AppLanguage.kurdish: return 'ناو بە سەرکەوتوویی نوێ کرایەوە';
      case AppLanguage.english: return 'Name updated successfully';
    }
  }

  Future<void> _pickAndUploadImage() async {
    final lang = Provider.of<LanguageService>(context, listen: false);
    
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() => _isUploadingImage = true);
        
        final bytes = await pickedFile.readAsBytes();
        final filename = pickedFile.name;
        
        // Show the image locally first
        setState(() => _profileImage = bytes);
        
        // Upload to API
        final result = await UploadService.uploadProfileImage(bytes, filename);
        
        if (result.success && result.url != null) {
          // Save URL to Firebase
          final user = _auth.currentUser;
          if (user != null) {
            await user.updatePhotoURL(result.url);
            await _firestore.collection('users').doc(user.uid).set({
              'photoURL': result.url,
              'lastUpdated': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            
            _profileImageUrl = result.url;
            if (mounted) _showSnackBar(_getImageUploadedMessage(lang), Colors.green);
          }
        } else {
          if (mounted) _showSnackBar(result.error ?? 'Upload failed', Colors.red);
        }
      }
    } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      if (mounted) _showSnackBar('Error: $e', Colors.red);
    }
    
    setState(() => _isUploadingImage = false);
  }

  String _getImageUploadedMessage(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تم رفع الصورة بنجاح';
      case AppLanguage.kurdish: return 'وێنە بە سەرکەوتوویی ئەپلۆد کرا';
      case AppLanguage.english: return 'Image uploaded successfully';
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  Future<void> _deleteAccount(String? password) async {
    setState(() => _isLoading = true);
    final lang = Provider.of<LanguageService>(context, listen: false);
    final user = _auth.currentUser;
    
    try {
      if (user != null) {
        // If the user is not anonymous and password is provided, re-authenticate first
        if (!user.isAnonymous && password != null && password.isNotEmpty) {
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );
          await user.reauthenticateWithCredential(credential);
        }

        // 1. Delete user data from Firestore first
        try {
          await _firestore.collection('users').doc(user.uid).delete();
          // Also try to delete their challenges/progress if they exist
          await _firestore.collection('challenges').doc(user.uid).delete();
        } catch (e) {
          debugPrint('Error deleting user data from Firestore: $e');
        }

        // 2. Delete the Auth account
        await user.delete();
        
        if (mounted) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Delete account Firebase error: ${e.code}');
      if (e.code == 'requires-recent-login' && user != null && user.isAnonymous) {
        // If guest user cannot delete due to requires-recent-login, sign out instead to clear session
        try {
          await _auth.signOut();
        } catch (_) {}
        if (mounted) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
        }
        return;
      }
      if (mounted) {
        String errorMsg;
        if (e.code == 'requires-recent-login') {
          errorMsg = lang.currentLanguage == AppLanguage.kurdish
              ? 'بۆ سڕینەوەی ئەکاونت، پێویستە جارێکی تر بچیتەوە ژوورەوە (Re-login) پاشان هەوڵبدەیتەوە'
              : lang.currentLanguage == AppLanguage.arabic
                  ? 'لحذف الحساب، يجب تسجيل الخروج والدخول مرة أخرى ثم المحاولة'
                  : 'For security, please log out and log in again before deleting your account.';
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          errorMsg = lang.currentLanguage == AppLanguage.kurdish
              ? 'تێپەڕەوشە (Password) هەڵەیە، تکایە دووبارە هەوڵبدەرەوە'
              : lang.currentLanguage == AppLanguage.arabic
                  ? 'كلمة المرور غير صحيحة، يرجى المحاولة مرة أخرى'
                  : 'Incorrect password, please try again.';
        } else {
          errorMsg = 'Error: ${e.message}';
        }
        _showSnackBar(errorMsg, Colors.red);
      }
    } catch (e) {
      debugPrint('Delete account error: $e');
      if (mounted) {
        _showSnackBar('Error: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDeleteAccountDialog(LanguageService lang) {
    final isDark = lang.isDarkMode;
    final user = _auth.currentUser;
    final isAnonymous = user?.isAnonymous ?? false;
    final deleteController = TextEditingController();
    bool canDelete = false;

    String title;
    String warningText;
    String hintText;
    String deleteBtn;
    String cancelBtn;
    String confirmationWord = 'حذف';

    switch (lang.currentLanguage) {
      case AppLanguage.kurdish:
        title = 'سڕینەوەی ئەکاونت';
        warningText = 'ئایا دڵنیایت دەتەوێت ئەکاونتەکەت بسڕیتەوە؟ ئەم کارە ناگەڕێتەوە.\n\nبۆ دڵنیابوون، بنووسە «حذف» لە خوارەوە:';
        hintText = 'حذف';
        deleteBtn = 'سڕینەوە';
        cancelBtn = 'پاشگەزبوونەوە';
        break;
      case AppLanguage.arabic:
        title = 'حذف الحساب';
        warningText = 'هل أنت متأكد من حذف حسابك؟ هذا الإجراء لا يمكن التراجع عنه.\n\nللتأكيد، اكتب «حذف» أدناه:';
        hintText = 'حذف';
        deleteBtn = 'حذف';
        cancelBtn = 'إلغاء';
        break;
      case AppLanguage.english:
      default:
        title = 'Delete Account';
        warningText = 'Are you sure you want to delete your account? This action cannot be undone.\n\nTo confirm, type «حذف» below:';
        hintText = 'حذف';
        deleteBtn = 'Delete';
        cancelBtn = 'Cancel';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Directionality(
            textDirection: lang.textDirection,
            child: AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1a2a4a) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: lang.getTextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))),
              ]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(warningText, style: lang.getTextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54, height: 1.6)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: deleteController,
                    textAlign: TextAlign.center,
                    obscureText: false, // Never obscure confirmation word entry
                    style: lang.getTextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: lang.getTextStyle(fontSize: 16, color: isDark ? Colors.white24 : Colors.grey[400]!),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        canDelete = value.trim() == 'حذف';
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(cancelBtn, style: lang.getTextStyle(color: isDark ? Colors.white54 : Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: canDelete ? () {
                    Navigator.pop(context);
                    _deleteAccount(null); // No password is required
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(deleteBtn, style: lang.getTextStyle(color: canDelete ? Colors.white : (isDark ? Colors.white24 : Colors.grey), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(LanguageService lang) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: lang.textDirection,
        child: AlertDialog(
          backgroundColor: lang.isDarkMode ? const Color(0xFF1a2a4a) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.logout_rounded, color: Colors.red)),
            const SizedBox(width: 12),
            Text(lang.logout, style: lang.getTextStyle(fontWeight: FontWeight.bold, color: lang.isDarkMode ? Colors.white : Colors.black87)),
          ]),
          content: Text(lang.logoutConfirm, style: lang.getTextStyle(fontSize: 16, color: lang.isDarkMode ? Colors.white70 : Colors.black54)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.cancel, style: lang.getTextStyle(color: lang.isDarkMode ? Colors.white54 : Colors.grey))),
            ElevatedButton(
              onPressed: () { Navigator.pop(context); _signOut(); },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text(lang.yes, style: lang.getTextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final langService = Provider.of<LanguageService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: langService.isDarkMode ? const Color(0xFF1a2a4a) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: langService.isDarkMode ? Colors.white24 : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(langService.language, style: langService.getTextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: langService.isDarkMode ? Colors.white : Colors.black87)),
            const SizedBox(height: 20),
            _buildLanguageOption(AppLanguage.arabic, '🇸🇦', 'العربية'),
            _buildLanguageOption(AppLanguage.kurdish, '🇮🇶', 'کوردی'),
            _buildLanguageOption(AppLanguage.english, '🇬🇧', 'English'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(AppLanguage language, String flag, String name) {
    final langService = Provider.of<LanguageService>(context);
    final isSelected = langService.currentLanguage == language;
    return GestureDetector(
      onTap: () { langService.setLanguage(language); Navigator.pop(context); },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: isSelected ? const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]) : null,
          color: isSelected ? null : (langService.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Text(name, style: langService.getTextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : (langService.isDarkMode ? Colors.white : Colors.black87))),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // App Lock Methods
  void _toggleAppLock(AppLockService lockService, LanguageService lang) async {
    if (lockService.isLockEnabled) {
      // Disable lock - confirm first
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: lang.isDarkMode ? const Color(0xFF1a2a4a) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(_getDisableLockTitle(lang), style: lang.getTextStyle(color: lang.isDarkMode ? Colors.white : Colors.black87)),
          content: Text(_getDisableLockConfirm(lang), style: lang.getTextStyle(color: lang.isDarkMode ? Colors.white70 : Colors.black54)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(_getCancelText(lang))),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(_getConfirmText(lang), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await lockService.disableLock();
      }
    } else {
      // Enable lock - setup PIN
      _setupOrChangePin(lockService, lang, isChange: false);
    }
  }

  void _setupOrChangePin(AppLockService lockService, LanguageService lang, {required bool isChange}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppLockScreen(
          child: const SizedBox.shrink(),
          isSetupMode: true,
        ),
      ),
    );
  }

  // App Lock Localization
  String _getAppLockTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'قفل التطبيق';
      case AppLanguage.kurdish: return 'قفڵی ئەپ';
      default: return 'App Lock';
    }
  }

  String _getAppLockEnabledText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'مفعل - يتطلب PIN للفتح';
      case AppLanguage.kurdish: return 'چالاکە - پێویستی بە PIN هەیە';
      default: return 'Enabled - Requires PIN';
    }
  }

  String _getAppLockDisabledText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'معطل';
      case AppLanguage.kurdish: return 'ناچالاکە';
      default: return 'Disabled';
    }
  }

  String _getBiometricTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'بصمة الأصبع';
      case AppLanguage.kurdish: return 'پەنجەمۆر';
      default: return 'Fingerprint';
    }
  }

  String _getBiometricEnabledText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'استخدم البصمة للفتح';
      case AppLanguage.kurdish: return 'پەنجەمۆر بۆ کردنەوە';
      default: return 'Use fingerprint to unlock';
    }
  }

  String _getBiometricDisabledText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'معطل';
      case AppLanguage.kurdish: return 'ناچالاکە';
      default: return 'Disabled';
    }
  }

  String _getChangePinTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تغيير رمز PIN';
      case AppLanguage.kurdish: return 'گۆڕینی PIN';
      default: return 'Change PIN';
    }
  }

  String _getChangePinSubtitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تعيين رمز جديد';
      case AppLanguage.kurdish: return 'دانانی PIN ی نوێ';
      default: return 'Set a new PIN';
    }
  }

  String _getDisableLockTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تعطيل القفل؟';
      case AppLanguage.kurdish: return 'قفڵ لادەبەیت؟';
      default: return 'Disable Lock?';
    }
  }

  String _getDisableLockConfirm(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'هل تريد تعطيل قفل التطبيق؟';
      case AppLanguage.kurdish: return 'دەتەوێت قفڵی ئەپ ناچالاک بکەیت؟';
      default: return 'Do you want to disable app lock?';
    }
  }

  String _getCancelText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إلغاء';
      case AppLanguage.kurdish: return 'پاشگەزبوونەوە';
      default: return 'Cancel';
    }
  }

  String _getConfirmText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تأكيد';
      case AppLanguage.kurdish: return 'دڵنیایی';
      default: return 'Confirm';
    }
  }

  // Disguise Localization & Methods
  String _getDisguiseTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إخفاء التطبيق';
      case AppLanguage.kurdish: return 'شاردنەوەی ئەپ';
      default: return 'App Disguise';
    }
  }

  String _getDisguiseSubtitle(AppIconType current, LanguageService lang) {
    String name = '';
    switch (current) {
      case AppIconType.original:
        name = lang.currentLanguage == AppLanguage.kurdish ? 'ڕەسەن (لا ٲبرح)' : (lang.currentLanguage == AppLanguage.arabic ? 'الأصلي (لا ٲبرح)' : 'Original');
        break;
      case AppIconType.calculator:
        name = lang.currentLanguage == AppLanguage.kurdish ? 'ژمێرەر' : (lang.currentLanguage == AppLanguage.arabic ? 'حاسبة' : 'Calculator');
        break;
      case AppIconType.notes:
        name = lang.currentLanguage == AppLanguage.kurdish ? 'تێبینی' : (lang.currentLanguage == AppLanguage.arabic ? 'ملاحظات' : 'Notes');
        break;
    }
    return lang.currentLanguage == AppLanguage.english ? 'Current: $name' : (lang.currentLanguage == AppLanguage.arabic ? 'الحالي: $name' : 'ئێستا: $name');
  }

  void _showDisguiseDialog(LanguageService lang, AppDisguiseService service) {
    final isDark = lang.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Directionality(
        textDirection: lang.textDirection,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a2a4a) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text(_getDisguiseTitle(lang), style: lang.getTextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 10),
              Text(
                lang.currentLanguage == AppLanguage.english ? 'Choose an icon and name to disguise the app. The app will briefly close to apply changes.'
                : (lang.currentLanguage == AppLanguage.arabic ? 'اختر أيقونة واسماً لإخفاء التطبيق. سيُغلق التطبيق للحظات لتطبيق التغيير.'
                : 'ئایکۆن و ناوێک هەڵبژێرە بۆ شاردنەوەی سەرشاشە. ئەپەکە بۆ ساتێک دادەخرێت تا گۆڕانکارییەکە جێبەجێ ببێت.'),
                textAlign: TextAlign.center,
                style: lang.getTextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 20),
              _buildDisguiseOption(AppIconType.original, Icons.favorite, 'لا ٲبرح', service, lang),
              _buildDisguiseOption(AppIconType.calculator, Icons.calculate, lang.currentLanguage == AppLanguage.kurdish ? 'ژمێرەر' : (lang.currentLanguage == AppLanguage.arabic ? 'حاسبة' : 'Calculator'), service, lang),
              _buildDisguiseOption(AppIconType.notes, Icons.notes, lang.currentLanguage == AppLanguage.kurdish ? 'تێبینی' : (lang.currentLanguage == AppLanguage.arabic ? 'ملاحظات' : 'Notes'), service, lang),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisguiseOption(AppIconType type, IconData iconData, String name, AppDisguiseService service, LanguageService lang) {
    final isSelected = service.currentIcon == type;
    final isDark = lang.isDarkMode;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        service.changeIcon(type);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF607D8B).withOpacity(isDark ? 0.4 : 0.1) : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: const Color(0xFF607D8B), width: 2) : null,
        ),
        child: Row(
          children: [
            Icon(iconData, color: isSelected ? const Color(0xFF607D8B) : (isDark ? Colors.white70 : Colors.black54), size: 28),
            const SizedBox(width: 16),
            Text(name, style: lang.getTextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF607D8B) : (isDark ? Colors.white : Colors.black87))),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFF607D8B)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final user = _auth.currentUser;
    final isGuest = user?.isAnonymous ?? true;
    final isDark = lang.isDarkMode;

    return Directionality(
      textDirection: lang.textDirection,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(lang.isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(lang.settings, style: lang.getTextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Card (Clickable - Opens Modal)
              GestureDetector(
                onTap: () => _showProfileModal(lang, isDark, isGuest),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF1a2a4a), const Color(0xFF0d1a2d)]
                          : [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? const Color(0xFF4facfe) : const Color(0xFF4facfe)).withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.6), width: 2.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10),
                          ],
                        ),
                        child: ClipOval(
                          child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                              ? Image.network(_profileImageUrl!, fit: BoxFit.cover, width: 64, height: 64, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 32, color: Colors.white))
                              : Icon(isGuest ? Icons.person_outline : Icons.person, size: 32, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name & Email
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? user?.email?.split('@').first ?? lang.guest,
                              style: lang.getTextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? (isGuest ? lang.guestMode : ''),
                              style: lang.getTextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Edit Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section: General
              _buildSectionHeader(_getGeneralText(lang), lang, isDark),
              const SizedBox(height: 12),
              Container(
                decoration: _getCardDecoration(isDark),
                child: Column(
                  children: [
                    _buildSettingsItem(
                      icon: _buildGradientIcon(Icons.translate_rounded, [const Color(0xFF4facfe), const Color(0xFF00f2fe)]),
                      title: lang.language,
                      subtitle: lang.languageName,
                      onTap: _showLanguageDialog,
                      lang: lang,
                    ),
                    _buildDivider(isDark),
                    _buildSettingsItem(
                      icon: _buildGradientIcon(Icons.palette_rounded, [const Color(0xFFff0844), const Color(0xFFffb199)]),
                      title: lang.appearance,
                      subtitle: lang.themeName,
                      onTap: () => lang.toggleTheme(),
                      lang: lang,
                      trailing: Switch(
                        value: isDark,
                        onChanged: (_) => lang.toggleTheme(),
                        activeColor: const Color(0xFFff0844),
                      ),
                    ),
                    _buildDivider(isDark),
                    // Text Size Setting
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                            ),
                            child: _buildGradientIcon(Icons.format_size_rounded, [const Color(0xFF14B8A6), const Color(0xFF0F766E)]),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_getTextSizeTitle(lang), style: lang.getTextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                                const SizedBox(height: 4),
                                Text(lang.textSizeName, style: lang.getTextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
                              ],
                            ),
                          ),
                          // Decrease button
                          GestureDetector(
                            onTap: () => lang.setTextScale(lang.textScale - 0.1),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.remove, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('${(lang.textScale * 100).round()}%', style: lang.getTextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF14B8A6))),
                          ),
                          // Increase button
                          GestureDetector(
                            onTap: () => lang.setTextScale(lang.textScale + 0.1),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.add, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: Security
              _buildSectionHeader(_getSecurityText(lang), lang, isDark),
              const SizedBox(height: 12),
              Consumer<AppLockService>(
                builder: (context, lockService, child) {
                  return Container(
                    decoration: _getCardDecoration(isDark),
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          icon: _buildGradientIcon(Icons.lock_outline_rounded, [const Color(0xFFb1f2ff), const Color(0xFF36d1dc)]),
                          title: _getAppLockTitle(lang),
                          subtitle: lockService.isLockEnabled ? _getAppLockEnabledText(lang) : _getAppLockDisabledText(lang),
                          onTap: () => _toggleAppLock(lockService, lang),
                          lang: lang,
                          trailing: Switch(
                            value: lockService.isLockEnabled,
                            onChanged: (_) => _toggleAppLock(lockService, lang),
                            activeColor: const Color(0xFF36d1dc),
                          ),
                        ),
                        if (lockService.isLockEnabled) ...[
                          _buildDivider(isDark),
                          FutureBuilder<bool>(
                            future: lockService.isBiometricAvailable(),
                            builder: (context, snapshot) {
                              if (snapshot.data != true) return const SizedBox.shrink();
                              return _buildSettingsItem(
                                icon: _buildGradientIcon(Icons.fingerprint_rounded, [const Color(0xFF00c6ff), const Color(0xFF0072ff)]),
                                title: _getBiometricTitle(lang),
                                subtitle: lockService.isBiometricEnabled ? _getBiometricEnabledText(lang) : _getBiometricDisabledText(lang),
                                onTap: () => lockService.setBiometricEnabled(!lockService.isBiometricEnabled),
                                lang: lang,
                                trailing: Switch(
                                  value: lockService.isBiometricEnabled,
                                  onChanged: (value) => lockService.setBiometricEnabled(value),
                                  activeColor: const Color(0xFF0072ff),
                                ),
                              );
                            },
                          ),
                          _buildDivider(isDark),
                          _buildSettingsItem(
                            icon: _buildGradientIcon(Icons.password_rounded, [const Color(0xFFf9d423), const Color(0xFFff4e50)]),
                            title: _getChangePinTitle(lang),
                            subtitle: _getChangePinSubtitle(lang),
                            onTap: () => _setupOrChangePin(lockService, lang, isChange: true),
                            lang: lang,
                          ),
                        ],
                        
                        _buildDivider(isDark),
                        Consumer<AppDisguiseService>(
                          builder: (context, disguiseService, child) {
                            return _buildSettingsItem(
                              icon: _buildGradientIcon(Icons.hide_source_rounded, [const Color(0xFF8ec5fc), const Color(0xFFe0c3fc)]),
                              title: _getDisguiseTitle(lang),
                              subtitle: _getDisguiseSubtitle(disguiseService.currentIcon, lang),
                              onTap: () => _showDisguiseDialog(lang, disguiseService),
                              lang: lang,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Section: Admin (if applicable)
              if (_isAdmin || _isDeveloper) ...[
                _buildSectionHeader(_getAdminText(lang), lang, isDark),
                const SizedBox(height: 12),
                Container(
                  decoration: _getCardDecoration(isDark),
                  child: _buildSettingsItem(
                    icon: _buildGradientIcon(Icons.space_dashboard_rounded, [const Color(0xFF4caf50), const Color(0xFF81c784)]),
                    title: _getContentManagementTitle(lang),
                    subtitle: _getContentManagementSubtitle(lang),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContentManagementScreen())),
                    lang: lang,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Section: About
              _buildAboutSection(lang, isDark),
              const SizedBox(height: 24),

              // Share App Button
              Container(
                decoration: _getCardDecoration(isDark),
                child: _buildSettingsItem(
                  icon: _buildGradientIcon(Icons.share_rounded, [const Color(0xFF00c6fb), const Color(0xFF005bec)]), 
                  title: lang.currentLanguage == AppLanguage.arabic 
                      ? 'شارك التطبيق' 
                      : lang.currentLanguage == AppLanguage.kurdish 
                          ? 'هاوبەشی بکە' 
                          : 'Share App',
                  subtitle: lang.currentLanguage == AppLanguage.arabic 
                      ? 'ساعد الآخرين في التعافي' 
                      : lang.currentLanguage == AppLanguage.kurdish 
                          ? 'یارمەتی کەسانی تر بدە' 
                          : 'Help others recover',
                  onTap: () async {
                    final uri = Uri.parse('https://laabrah.lovable.app');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  lang: lang,
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(color: Colors.red.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: _buildSettingsItem(
                  icon: _buildGradientIcon(Icons.power_settings_new_rounded, [const Color(0xFFff758c), const Color(0xFFff7eb3)]), 
                  title: lang.logout, 
                  subtitle: '', 
                  onTap: () => _showLogoutDialog(lang), 
                  lang: lang, 
                  isDestructive: true,
                ),
              ),
              const SizedBox(height: 16),

              // App Version
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'v4.0.10+55',
                    style: lang.getTextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white24 : Colors.grey[400]!,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // Profile Modal
  void _showProfileModal(LanguageService lang, bool isDark, bool isGuest) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a2a4a) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Directionality(
          textDirection: lang.textDirection,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text(_getEditProfileText(lang), style: lang.getTextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 24),
              
              // Profile Picture
              Stack(
                children: [
                  GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]),
                        boxShadow: [BoxShadow(color: const Color(0xFF4facfe).withOpacity(0.4), blurRadius: 20)],
                      ),
                      child: _isUploadingImage
                          ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : ClipOval(
                              child: _profileImage != null
                                  ? Image.memory(_profileImage!, fit: BoxFit.cover, width: 100, height: 100)
                                  : _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                      ? Image.network(_profileImageUrl!, fit: BoxFit.cover, width: 100, height: 100, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50, color: Colors.white))
                                      : Icon(isGuest ? Icons.person_outline : Icons.person, size: 50, color: Colors.white),
                            ),
                    ),
                  ),
                  if (!_isUploadingImage)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4facfe),
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? const Color(0xFF1a2a4a) : Colors.white, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(_getChangePhotoText(lang), style: lang.getTextStyle(fontSize: 12, color: const Color(0xFF4facfe))),
              const SizedBox(height: 24),
              
              // User ID
              if (_userId != null && !isGuest)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF0D9488)),
                      const SizedBox(width: 8),
                      Text(_getUserIdLabel(lang), style: lang.getTextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)),
                      const SizedBox(width: 8),
                      Text(_userId!, style: lang.getTextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0D9488))),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _userId!));
                          _showSnackBar(_getCopiedMessage(lang), const Color(0xFF0D9488));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.copy, size: 16, color: Color(0xFF0D9488)),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              
              // Name Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _nameController,
                  style: lang.getTextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: lang.fullName,
                    labelStyle: lang.getTextStyle(color: isDark ? Colors.white54 : Colors.black45),
                    prefixIcon: Icon(Icons.person_outline, color: isDark ? Colors.white54 : Colors.black45),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4facfe))),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Save Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () {
                      _updateDisplayName();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4facfe),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: const Color(0xFF4facfe).withOpacity(0.4),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_getSaveText(lang), style: lang.getTextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Section Header
  Widget _buildSectionHeader(String title, LanguageService lang, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: lang.getTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white60 : Colors.grey[600]!,
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Card Decoration
  BoxDecoration _getCardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1),
      ),
      boxShadow: isDark
          ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]
          : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
    );
  }

  // Helper: Divider
  Widget _buildDivider(bool isDark) {
    return Divider(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200], height: 1);
  }

  // Translations
  String _getGeneralText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'عام';
      case AppLanguage.kurdish: return 'گشتی';
      case AppLanguage.english: return 'General';
    }
  }

  String _getSecurityText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'الأمان';
      case AppLanguage.kurdish: return 'پاراستن';
      case AppLanguage.english: return 'Security';
    }
  }

  String _getAdminText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'المسؤول';
      case AppLanguage.kurdish: return 'بەڕێوەبەر';
      case AppLanguage.english: return 'Admin';
    }
  }

  String _getEditProfileText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تعديل الملف الشخصي';
      case AppLanguage.kurdish: return 'دەستکاری پرۆفایل';
      case AppLanguage.english: return 'Edit Profile';
    }
  }

  String _getTextSizeTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حجم الخط';
      case AppLanguage.kurdish: return 'قەبارەی فۆنت';
      case AppLanguage.english: return 'Text Size';
    }
  }

  Widget _buildAboutSection(LanguageService lang, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark 
              ? [const Color(0xFF1a2a4a), const Color(0xFF0d1a2d)]
              : [Colors.white, const Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF0D9488).withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF14B8A6)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 22),
          ),
          title: Text(
            _getAboutTitle(lang),
            style: lang.getTextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
          ),
          subtitle: Text(
            _getAboutSubtitle(lang),
            style: lang.getTextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
          ),
          children: [
            // Bismillah
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                      ? [const Color(0xFF0D9488).withOpacity(0.2), const Color(0xFF14B8A6).withOpacity(0.2)]
                      : [const Color(0xFF0D9488).withOpacity(0.1), const Color(0xFF14B8A6).withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.3)),
              ),
              child: Text(
                'بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ',
                style: lang.getTextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D9488),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // About text
            Text(
              '''الهدف الأساسي من إنشاء هذا التطبيق هو أن نكون سندًا وعونًا حقيقيًا لكل شخص قرر بشجاعة أن يبدأ صفحة جديدة في حياته ويتخلص من قيود الإدمان التي كبلته لفترة طويلة.

شفنا ولامسنا كيف أن كثير من التطبيقات والمصادر التي المفروض تكون داعمة في رحلة التعافي تحولت مع الوقت لخدمات تجارية بحتة تتطلب اشتراكات ومبالغ مالية كبيرة، وهذا الشيء يشكل عائق كبير قدام ناس كثير إمكانياتهم المادية بسيطة أو يمكن يكونون في بداية طريقهم وما عندهم القدرة على دفع هذه التكاليف.

ونحن نؤمن إيمان كامل بأن المساعدة والدعم النفسي والتحفيزي لازم يكون حق للجميع متاح في كل وقت وبدون أي مقابل أو عوائق مادية.

من هذا المنطلق جاءت فكرة إطلاق هذا التطبيق ليكون بمثابة الرفيق والصديق في رحلة التعافي، مساحة آمنة وداعمة ومجانية بشكل كامل %100.

حاولنا نجمع فيه كل الأدوات والمميزات التي ممكن يحتاجها المتعافي من متابعة أيام التعافي وتحديات تحفيزية ومحتوى ملهم يساعده على الثبات والصمود في وجه أي انتكاسة محتملة ويشجعه على الاستمرار في طريقه نحو حياة أفضل وأكثر إشراقًا وطمأنينة.

طموحنا كبير وأمنيتنا أن يصل هذا الجهد المتواضع إلى أكبر عدد ممكن من الناس في كل مكان وأن يكون له أثر إيجابي ملموس في حياتهم وأن يكون سببًا ولو بسيطًا في تغيير مسار حياتهم نحو الأفضل والأجمل.''',
              style: lang.getTextStyle(
                fontSize: 14,
                height: 1.8,
                color: isDark ? Colors.white.withOpacity(0.85) : Colors.black87,
              ),
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 20),
            // Dua at the end
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF4CAF50).withOpacity(0.15) : const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
              ),
              child: Text(
                'نسأل الله العظيم رب العرش العظيم أن يجعل هذا العمل خالصًا لوجهه الكريم وأن يتقبله منا وأن ينفع به كل من حمّله واستخدمه وأن يثبت كل من يسعى في طريق التعافي ويجزيه خير الجزاء.',
                style: lang.getTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.7,
                  color: const Color(0xFF4CAF50),
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAboutTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حول مطور التطبيق';
      case AppLanguage.kurdish: return 'دەربارەی دروستکەری ئەپ';
      case AppLanguage.english: return 'About the Developer';
    }
  }

  String _getAboutSubtitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'رسالتنا وهدفنا';
      case AppLanguage.kurdish: return 'پەیامی ئێمە و ئامانجمان';
      case AppLanguage.english: return 'Our mission and goal';
    }
  }

  String _getChangePhotoText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'اضغط لتغيير الصورة';
      case AppLanguage.kurdish: return 'کلیک بکە بۆ گۆڕینی وێنە';
      case AppLanguage.english: return 'Tap to change photo';
    }
  }

  String _getSaveText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حفظ التغييرات';
      case AppLanguage.kurdish: return 'پاشەکەوتکردن';
      case AppLanguage.english: return 'Save Changes';
    }
  }

  String _getContentManagementTitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إدارة المحتوى';
      case AppLanguage.kurdish: return 'بەڕێوەبردنی ناوەڕۆک';
      case AppLanguage.english: return 'Content Management';
    }
  }

  String _getContentManagementSubtitle(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'إدارة الاقتباسات والنصائح';
      case AppLanguage.kurdish: return 'بەڕێوەبردنی وتە و نەسیحەتەکان';
      case AppLanguage.english: return 'Manage quotes and tips';
    }
  }

  String _getUserIdLabel(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'معرف الحساب:';
      case AppLanguage.kurdish: return 'ئایدی ئەکاونت:';
      case AppLanguage.english: return 'Account ID:';
    }
  }

  String _getCopiedMessage(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'تم نسخ المعرف';
      case AppLanguage.kurdish: return 'ئایدی کۆپی کرا';
      case AppLanguage.english: return 'ID copied';
    }
  }

  Widget _buildGradientIcon(IconData icon, List<Color> colors, {double size = 28}) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(bounds),
      child: Icon(
        icon,
        size: size,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSettingsItem({
    required Widget icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required LanguageService lang,
    bool isDestructive = false,
    Widget? trailing,
  }) {
    final isDark = lang.isDarkMode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red.withOpacity(isDark ? 0.15 : 0.08)
                      : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.06)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: icon,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: lang.getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? Colors.red : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: lang.getTextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ?? Icon(
                lang.isRTL ? Icons.chevron_left : Icons.chevron_right,
                color: isDark ? Colors.white24 : Colors.grey[400],
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }



  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
