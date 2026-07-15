import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      setState(() { _errorMessage = e.toString(); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _signInAsGuest() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      // Add a timeout and continue even if Firebase fails on web
      try {
        await _authService.signInAsGuest().timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('[v0] Guest signin timeout or error: $e');
        // Continue anyway - guest session set up in AuthService
      }

      if (mounted) {
        // Give a tiny delay for localStorage to update
        await Future.delayed(const Duration(milliseconds: 100));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      setState(() { _errorMessage = e.toString(); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await _authService.signInWithGoogle();
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      setState(() { _errorMessage = e.toString(); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _showLanguageDialog() {
    final langService = Provider.of<LanguageService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppDesign.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppDesign.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(langService.language, style: langService.getTextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppDesign.textPrimary)),
            const SizedBox(height: 16),
            _buildLanguageOption(AppLanguage.arabic, 'العربية'),
            _buildLanguageOption(AppLanguage.kurdish, 'کوردی'),
            _buildLanguageOption(AppLanguage.english, 'English'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(AppLanguage language, String name) {
    final langService = Provider.of<LanguageService>(context);
    final isSelected = langService.currentLanguage == language;
    return GestureDetector(
      onTap: () { langService.setLanguage(language); Navigator.pop(context); },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppDesign.primarySoft : const Color(0xFFF8FAFA),
          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
          border: Border.all(color: isSelected ? AppDesign.primary : AppDesign.border),
        ),
        child: Row(
          children: [
            Icon(Icons.translate_rounded, size: 20, color: isSelected ? AppDesign.primary : AppDesign.textSecondary),
            const SizedBox(width: 12),
            Text(name, style: langService.getTextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isSelected ? AppDesign.primaryDark : AppDesign.textPrimary)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppDesign.primary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(LanguageService lang) {
    final emailController = TextEditingController();
    bool isLoading = false;
    String? message;
    bool isSuccess = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: lang.textDirection,
          child: AlertDialog(
            backgroundColor: AppDesign.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusLg)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppDesign.primarySoft,
                    borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                  ),
                  child: const Icon(Icons.lock_reset_rounded, color: AppDesign.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('استعادة كلمة السر', style: lang.getTextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppDesign.textPrimary))),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'أدخل بريدك الإلكتروني وسنرسل لك رابط لإعادة تعيين كلمة السر',
                  style: lang.getTextStyle(color: AppDesign.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    labelStyle: lang.getTextStyle(color: AppDesign.textSecondary),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppDesign.primary, size: 20),
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSuccess ? AppDesign.primarySoft : Colors.red[50],
                      borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                      border: Border.all(color: isSuccess ? AppDesign.primary : Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                          color: isSuccess ? AppDesign.primaryDark : Colors.red[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(message!, style: lang.getTextStyle(color: isSuccess ? AppDesign.primaryDark : Colors.red[700], fontSize: 13))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء', style: lang.getTextStyle(color: AppDesign.textSecondary)),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  if (emailController.text.trim().isEmpty) {
                    setDialogState(() {
                      message = 'الرجاء إدخال البريد الإلكتروني';
                      isSuccess = false;
                    });
                    return;
                  }

                  setDialogState(() { isLoading = true; message = null; });

                  try {
                    await _authService.sendPasswordResetEmail(emailController.text.trim());
                    setDialogState(() {
                      message = _getPasswordResetSuccessMessage(lang);
                      isSuccess = true;
                      isLoading = false;
                    });
                    await Future.delayed(const Duration(seconds: 4));
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    setDialogState(() {
                      message = e.toString();
                      isSuccess = false;
                      isLoading = false;
                    });
                  }
                },
                child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('إرسال', style: lang.getTextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);

    return Directionality(
      textDirection: lang.textDirection,
      child: Scaffold(
        backgroundColor: AppDesign.background,
        body: SafeArea(
          child: Column(
            children: [
              // Language selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Align(
                  alignment: lang.isRTL ? Alignment.centerLeft : Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _showLanguageDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppDesign.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppDesign.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.language_rounded, color: AppDesign.primary, size: 18),
                          const SizedBox(width: 6),
                          Text(lang.languageName, style: lang.getTextStyle(color: AppDesign.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  gradient: AppDesign.primaryGradient,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppDesign.primary.withOpacity(0.25),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.spa_rounded, size: 44, color: Colors.white),
                              ),
                              const SizedBox(height: 24),

                              // App Title
                              Text(
                                lang.appName,
                                style: lang.getTextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppDesign.textPrimary),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                lang.appSlogan,
                                style: lang.getTextStyle(fontSize: 14, color: AppDesign.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 36),

                              // Login Form Card
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppDesign.surface,
                                  borderRadius: BorderRadius.circular(AppDesign.radiusLg),
                                  border: Border.all(color: AppDesign.border),
                                  boxShadow: AppDesign.cardShadow,
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        lang.login,
                                        style: lang.getTextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppDesign.textPrimary),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),

                                      // Email Field
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        textDirection: TextDirection.ltr,
                                        style: const TextStyle(fontSize: 15),
                                        decoration: InputDecoration(
                                          labelText: lang.email,
                                          labelStyle: lang.getTextStyle(color: AppDesign.textSecondary, fontSize: 14),
                                          prefixIcon: const Icon(Icons.email_outlined, color: AppDesign.primary, size: 20),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) return lang.enterEmail;
                                          if (!value.contains('@')) return lang.invalidEmail;
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 14),

                                      // Password Field
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        textDirection: TextDirection.ltr,
                                        style: const TextStyle(fontSize: 15),
                                        decoration: InputDecoration(
                                          labelText: lang.password,
                                          labelStyle: lang.getTextStyle(color: AppDesign.textSecondary, fontSize: 14),
                                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppDesign.primary, size: 20),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                              color: AppDesign.textSecondary,
                                              size: 20,
                                            ),
                                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) return lang.enterPassword;
                                          if (value.length < 6) return lang.passwordTooShort;
                                          return null;
                                        },
                                      ),

                                      // Forgot Password Link
                                      Align(
                                        alignment: lang.isRTL ? Alignment.centerRight : Alignment.centerLeft,
                                        child: TextButton(
                                          onPressed: () => _showForgotPasswordDialog(lang),
                                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                                          child: Text(
                                            'نسيت كلمة السر؟',
                                            style: lang.getTextStyle(
                                              color: AppDesign.primary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),

                                      if (_errorMessage != null) ...[
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                                            border: Border.all(color: Colors.red[200]!),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.error_outline_rounded, color: Colors.red[700], size: 20),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(_errorMessage!, style: lang.getTextStyle(color: Colors.red[700], fontSize: 13))),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                      const SizedBox(height: 8),

                                      // Login Button
                                      SizedBox(
                                        height: 52,
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : _signIn,
                                          child: _isLoading
                                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                              : Text(lang.login, style: lang.getTextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Create Account Link
                                      TextButton(
                                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(text: '${lang.noAccount} ', style: lang.getTextStyle(color: AppDesign.textSecondary, fontSize: 14)),
                                              TextSpan(text: lang.createAccount, style: lang.getTextStyle(color: AppDesign.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Or divider
                              Row(
                                children: [
                                  const Expanded(child: Divider(color: AppDesign.border)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(lang.or, style: lang.getTextStyle(color: AppDesign.textSecondary, fontSize: 13)),
                                  ),
                                  const Expanded(child: Divider(color: AppDesign.border)),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Google Sign-In Button
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isLoading ? null : _signInWithGoogle,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Google "G" Logo
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                            ),
                                            child: const Center(
                                              child: Text(
                                                'G',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF4285F4),
                                                  fontFamily: 'Google Sans',
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Text(
                                            lang.currentLanguage == AppLanguage.kurdish
                                                ? 'بە جییمێڵ چوونەتەوە'
                                                : lang.currentLanguage == AppLanguage.arabic
                                                    ? 'تسجيل الدخول بحساب Google'
                                                    : 'Sign in with Google',
                                            style: lang.getTextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF3C4043),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Guest Login Button
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isLoading ? null : _signInAsGuest,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [AppDesign.primary, AppDesign.primary.withOpacity(0.7)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.person_outline_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Text(
                                            lang.guestLogin,
                                            style: lang.getTextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF3C4043),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPasswordResetSuccessMessage(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic:
        return 'تم إرسال الرابط بنجاح!\n\nتفقد مجلد الرسائل غير المرغوب فيها (Spam) إذا لم تجد الرسالة في صندوق الوارد.';
      case AppLanguage.kurdish:
        return 'لینکەکە بە سەرکەوتوویی نێردرا!\n\nئەگەر نامەکەت نەدۆزییەوە، بەرەو بەشی Spam یان نامەی نەویستراو بڕۆ.';
      case AppLanguage.english:
        return 'Link sent successfully!\n\nCheck your spam or junk folder if you don\'t see the email in your inbox.';
    }
  }
}
