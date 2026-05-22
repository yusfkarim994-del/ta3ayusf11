import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await _authService.createAccountWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
    } catch (e) {
      setState(() { _errorMessage = e.toString(); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
    required LanguageService lang,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? toggleObscure,
    TextInputType keyboardType = TextInputType.text,
    TextDirection textDirection = TextDirection.rtl,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textDirection: textDirection,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: lang.getTextStyle(color: Colors.grey[600]),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [gradientColors[0].withOpacity(0.2), gradientColors[1].withOpacity(0.1)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: gradientColors[0], size: 20),
        ),
        suffixIcon: isPassword
            ? IconButton(icon: Icon(obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey[500]), onPressed: toggleObscure)
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      validator: validator,
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
            // Nature background
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(image: AssetImage('assets/images/nature_bg.png'), fit: BoxFit.cover),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF11998e).withOpacity(0.75), const Color(0xFF38ef7d).withOpacity(0.85)],
                ),
              ),
            ),
            // Floating icons
            Positioned(top: 100, right: 30, child: _buildFloatingIcon(Icons.person_add, 0)),
            Positioned(top: 160, left: 40, child: _buildFloatingIcon(Icons.verified_user, 1)),
            Positioned(bottom: 150, right: 40, child: _buildFloatingIcon(Icons.security, 2)),
            
            // Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Back Button
                        Align(
                          alignment: lang.isRTL ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(12)),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(lang.isRTL ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_rounded, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 30)]),
                          child: const Icon(Icons.person_add_alt_1_rounded, size: 55, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        
                        // Title
                        Text(lang.createAccount, style: lang.getTextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text(lang.joinUs, style: lang.getTextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)), textAlign: TextAlign.center),
                        const SizedBox(height: 32),
                        
                        // Form Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 15))]),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildInputField(
                                  controller: _nameController,
                                  label: lang.fullName,
                                  icon: Icons.person_outlined,
                                  gradientColors: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
                                  lang: lang,
                                  validator: (value) => value == null || value.isEmpty ? lang.enterName : null,
                                ),
                                const SizedBox(height: 14),
                                _buildInputField(
                                  controller: _emailController,
                                  label: lang.email,
                                  icon: Icons.email_outlined,
                                  gradientColors: [const Color(0xFF38ef7d), const Color(0xFF11998e)],
                                  lang: lang,
                                  keyboardType: TextInputType.emailAddress,
                                  textDirection: TextDirection.ltr,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return lang.enterEmail;
                                    if (!value.contains('@')) return lang.invalidEmail;
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                _buildInputField(
                                  controller: _passwordController,
                                  label: lang.password,
                                  icon: Icons.lock_outlined,
                                  gradientColors: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
                                  lang: lang,
                                  isPassword: true,
                                  obscureText: _obscurePassword,
                                  textDirection: TextDirection.ltr,
                                  toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return lang.enterPassword;
                                    if (value.length < 6) return lang.passwordTooShort;
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                _buildInputField(
                                  controller: _confirmPasswordController,
                                  label: lang.confirmPassword,
                                  icon: Icons.lock_outlined,
                                  gradientColors: [const Color(0xFF38ef7d), const Color(0xFF11998e)],
                                  lang: lang,
                                  isPassword: true,
                                  obscureText: _obscureConfirmPassword,
                                  textDirection: TextDirection.ltr,
                                  toggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return lang.confirmPasswordRequired;
                                    if (value != _passwordController.text) return lang.passwordMismatch;
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                
                                if (_errorMessage != null)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red[200]!)),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.red[700]),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(_errorMessage!, style: lang.getTextStyle(color: Colors.red[700]))),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                
                                // Register Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFF11998e), Color(0xFF38ef7d)]),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [BoxShadow(color: const Color(0xFF11998e).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _register,
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                      child: _isLoading
                                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                          : Text(lang.createAccount, style: lang.getTextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(text: '${lang.haveAccount} ', style: lang.getTextStyle(color: Colors.grey[600])),
                                        TextSpan(text: lang.loginNow, style: lang.getTextStyle(color: const Color(0xFF11998e), fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 1200 + (index * 150)),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Opacity(opacity: value.clamp(0.0, 1.0), child: child),
      child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: Colors.white.withOpacity(0.7), size: 22)),
    );
  }
}
