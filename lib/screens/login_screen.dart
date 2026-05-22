import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
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
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
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
      await _authService.signInAsGuest();
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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(langService.language, style: langService.getTextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
          gradient: isSelected ? const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]) : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Text(name, style: langService.getTextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.black87)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: Colors.white),
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
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text('استعادة كلمة السر', style: lang.getTextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'أدخل بريدك الإلكتروني وسنرسل لك رابط لإعادة تعيين كلمة السر',
                  style: lang.getTextStyle(color: Colors.grey[600], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    labelStyle: lang.getTextStyle(color: Colors.grey[600]),
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF667eea)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSuccess ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSuccess ? Colors.green[200]! : Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                          color: isSuccess ? Colors.green[700] : Colors.red[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(message!, style: lang.getTextStyle(color: isSuccess ? Colors.green[700] : Colors.red[700], fontSize: 13))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء', style: lang.getTextStyle(color: Colors.grey)),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
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
                      // Close dialog after success
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('إرسال', style: lang.getTextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
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
        body: Stack(
          children: [
            // Nature background image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/nature_bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Gradient overlay for better text visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF667eea).withOpacity(0.7),
                    const Color(0xFF764ba2).withOpacity(0.8),
                  ],
                ),
              ),
            ),
            // Floating icons
            Positioned(top: 120, right: 40, child: _buildFloatingIcon(Icons.favorite, 0)),
            Positioned(top: 180, left: 30, child: _buildFloatingIcon(Icons.psychology, 1)),
            Positioned(bottom: 200, right: 50, child: _buildFloatingIcon(Icons.self_improvement, 2)),
            Positioned(bottom: 280, left: 40, child: _buildFloatingIcon(Icons.healing, 3)),
            
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Language selector
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: lang.isRTL ? Alignment.centerLeft : Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _showLanguageDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(lang.languageName, style: lang.getTextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Logo
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 40, spreadRadius: 10)],
                                  ),
                                  child: const Icon(Icons.favorite_rounded, size: 70, color: Colors.white),
                                ),
                                const SizedBox(height: 28),
                                
                                // App Title
                                Text(lang.appName, style: lang.getTextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 15)]), textAlign: TextAlign.center),
                                const SizedBox(height: 8),
                                Text(lang.appSlogan, style: lang.getTextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)), textAlign: TextAlign.center),
                                const SizedBox(height: 40),
                                
                                // Login Form Card
                                Container(
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 15))],
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: const Icon(Icons.login_rounded, color: Colors.white, size: 22),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(lang.login, style: lang.getTextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF2d3436))),
                                          ],
                                        ),
                                        const SizedBox(height: 28),
                                        
                                        // Email Field
                                        TextFormField(
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          textDirection: TextDirection.ltr,
                                          style: const TextStyle(fontSize: 16),
                                          decoration: InputDecoration(
                                            labelText: lang.email,
                                            labelStyle: lang.getTextStyle(color: Colors.grey[600]),
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(8),
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(colors: [const Color(0xFF667eea).withOpacity(0.2), const Color(0xFF764ba2).withOpacity(0.1)]),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(Icons.email_outlined, color: Color(0xFF667eea), size: 20),
                                            ),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                            filled: true,
                                            fillColor: Colors.grey[100],
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) return lang.enterEmail;
                                            if (!value.contains('@')) return lang.invalidEmail;
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Password Field
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          textDirection: TextDirection.ltr,
                                          style: const TextStyle(fontSize: 16),
                                          decoration: InputDecoration(
                                            labelText: lang.password,
                                            labelStyle: lang.getTextStyle(color: Colors.grey[600]),
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(8),
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(colors: [const Color(0xFF764ba2).withOpacity(0.2), const Color(0xFFf093fb).withOpacity(0.1)]),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(Icons.lock_outlined, color: Color(0xFF764ba2), size: 20),
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey[500]),
                                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                            ),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                            filled: true,
                                            fillColor: Colors.grey[100],
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) return lang.enterPassword;
                                            if (value.length < 6) return lang.passwordTooShort;
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        
                                        // Forgot Password Link
                                        Align(
                                          alignment: lang.isRTL ? Alignment.centerRight : Alignment.centerLeft,
                                          child: TextButton(
                                            onPressed: () => _showForgotPasswordDialog(lang),
                                            child: Text(
                                              'نسيت كلمة السر؟',
                                              style: lang.getTextStyle(
                                                color: const Color(0xFF667eea),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        
                                        if (_errorMessage != null)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: Colors.red[200]!),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.error_outline_rounded, color: Colors.red[700]),
                                                const SizedBox(width: 10),
                                                Expanded(child: Text(_errorMessage!, style: lang.getTextStyle(color: Colors.red[700]))),
                                              ],
                                            ),
                                          ),
                                        const SizedBox(height: 24),
                                        
                                        // Login Button
                                        SizedBox(
                                          width: double.infinity,
                                          height: 56,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [BoxShadow(color: const Color(0xFF667eea).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
                                            ),
                                            child: ElevatedButton(
                                              onPressed: _isLoading ? null : _signIn,
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                              child: _isLoading
                                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                                  : Text(lang.login, style: lang.getTextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Create Account Link
                                        TextButton(
                                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                                          child: RichText(
                                            text: TextSpan(
                                              children: [
                                                TextSpan(text: '${lang.noAccount} ', style: lang.getTextStyle(color: Colors.grey[600])),
                                                TextSpan(text: lang.createAccount, style: lang.getTextStyle(color: const Color(0xFF667eea), fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                
                                // Or divider
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.white.withOpacity(0.5))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
                                        child: Text(lang.or, style: lang.getTextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Colors.white.withOpacity(0.5))),
                                  ],
                                ),
                                const SizedBox(height: 28),
                                
                                // Guest Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading ? null : _signInAsGuest,
                                    icon: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 22),
                                    label: Text(lang.guestLogin, style: lang.getTextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.white, width: 2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      backgroundColor: Colors.white.withOpacity(0.15),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 1500 + (index * 200)),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Opacity(opacity: value.clamp(0.0, 1.0), child: child),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white.withOpacity(0.7), size: 24),
      ),
    );
  }

  String _getPasswordResetSuccessMessage(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic:
        return 'تم إرسال الرابط بنجاح! ✅\n\nتفقد مجلد الرسائل غير المرغوب فيها (Spam) إذا لم تجد الرسالة في صندوق الوارد.';
      case AppLanguage.kurdish:
        return 'لینکەکە بە سەرکەوتوویی نێردرا! ✅\n\nئەگەر نامەکەت نەدۆزییەوە، بەرەو بەشی Spam یان نامەی نەویستراو بڕۆ.';
      case AppLanguage.english:
        return 'Link sent successfully! ✅\n\nCheck your spam or junk folder if you don\'t see the email in your inbox.';
    }
  }
}
