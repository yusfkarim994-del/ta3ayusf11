import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_lock_service.dart';
import '../services/language_service.dart';

class AppLockScreen extends StatefulWidget {
  final Widget child;
  final bool isSetupMode;
  
  const AppLockScreen({
    super.key,
    required this.child,
    this.isSetupMode = false,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _enteredPin = '';
  String _confirmPin = '';
  bool _isConfirmStep = false;
  String? _errorMessage;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometric();
    });
  }
  
  Future<void> _tryBiometric() async {
    if (widget.isSetupMode) return;
    
    final lockService = Provider.of<AppLockService>(context, listen: false);
    if (lockService.isBiometricEnabled) {
      await lockService.authenticateWithBiometric();
    }
  }
  
  void _onNumberPressed(String number) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += number;
        _errorMessage = null;
      });
      
      if (_enteredPin.length == 4) {
        _checkPin();
      }
    }
  }
  
  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }
  
  Future<void> _checkPin() async {
    final lockService = Provider.of<AppLockService>(context, listen: false);
    
    if (widget.isSetupMode) {
      if (!_isConfirmStep) {
        // First entry - store and ask for confirmation
        _confirmPin = _enteredPin;
        setState(() {
          _isConfirmStep = true;
          _enteredPin = '';
        });
      } else {
        // Confirm entry
        if (_enteredPin == _confirmPin) {
          setState(() => _isLoading = true);
          final success = await lockService.setupPin(_enteredPin);
          if (success && mounted) {
            Navigator.pop(context, true);
          } else {
            setState(() {
              _errorMessage = _getPinSetupError();
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _errorMessage = _getPinMismatchError();
            _enteredPin = '';
            _confirmPin = '';
            _isConfirmStep = false;
          });
        }
      }
    } else {
      // Unlock mode
      final success = await lockService.unlockWithPin(_enteredPin);
      if (!success) {
        setState(() {
          _errorMessage = _getWrongPinError();
          _enteredPin = '';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AppLockService>(
      builder: (context, lockService, child) {
        if (!widget.isSetupMode && !lockService.isAppLocked) {
          return widget.child;
        }
        
        return _buildLockScreen(lockService);
      },
    );
  }
  
  Widget _buildLockScreen(AppLockService lockService) {
    final lang = Provider.of<LanguageService>(context);
    
    return Directionality(
      textDirection: lang.textDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFF0a1628),
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              
              // Lock Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0D9488).withOpacity(0.3),
                      const Color(0xFF0F766E).withOpacity(0.3),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                _getTitle(lang),
                style: lang.getTextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                _getSubtitle(lang),
                style: lang.getTextStyle(
                  fontSize: 14,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 40),
              
              // PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled 
                          ? const Color(0xFF0D9488) 
                          : Colors.transparent,
                      border: Border.all(
                        color: const Color(0xFF0D9488),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              
              // Error Message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _errorMessage!,
                    style: lang.getTextStyle(
                      fontSize: 14,
                      color: Colors.redAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const Spacer(),
              
              // Number Pad
              _buildNumberPad(lang),
              const SizedBox(height: 20),
              
              // Biometric Button (if available and not setup mode)
              if (!widget.isSetupMode && lockService.isBiometricEnabled)
                TextButton.icon(
                  onPressed: _tryBiometric,
                  icon: const Icon(Icons.fingerprint, color: Color(0xFF0D9488), size: 32),
                  label: Text(
                    _getBiometricText(lang),
                    style: lang.getTextStyle(color: const Color(0xFF0D9488)),
                  ),
                ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNumberPad(LanguageService lang) {
    return Column(
      children: [
        _buildNumberRow(['1', '2', '3']),
        const SizedBox(height: 16),
        _buildNumberRow(['4', '5', '6']),
        const SizedBox(height: 16),
        _buildNumberRow(['7', '8', '9']),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildEmptyButton(),
            _buildNumberButton('0'),
            _buildBackspaceButton(),
          ],
        ),
      ],
    );
  }
  
  Widget _buildNumberRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: numbers.map((n) => _buildNumberButton(n)).toList(),
    );
  }
  
  Widget _buildNumberButton(String number) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
        child: InkWell(
          onTap: () => _onNumberPressed(number),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 70,
            height: 70,
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildBackspaceButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onBackspace,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 70,
            height: 70,
            alignment: Alignment.center,
            child: const Icon(
              Icons.backspace_outlined,
              color: Colors.white60,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyButton() {
    return const SizedBox(width: 102);
  }
  
  // === Localization ===
  String _getTitle(LanguageService lang) {
    if (widget.isSetupMode) {
      if (_isConfirmStep) {
        switch (lang.currentLanguage) {
          case AppLanguage.arabic: return 'تأكيد رمز PIN';
          case AppLanguage.kurdish: return 'دووبارەکردنەوەی PIN';
          default: return 'Confirm PIN';
        }
      }
      switch (lang.currentLanguage) {
        case AppLanguage.arabic: return 'إنشاء رمز PIN';
        case AppLanguage.kurdish: return 'دروستکردنی PIN';
        default: return 'Create PIN';
      }
    }
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'أدخل رمز PIN';
      case AppLanguage.kurdish: return 'PIN بنووسە';
      default: return 'Enter PIN';
    }
  }
  
  String _getSubtitle(LanguageService lang) {
    if (widget.isSetupMode) {
      if (_isConfirmStep) {
        switch (lang.currentLanguage) {
          case AppLanguage.arabic: return 'أعد إدخال الرمز للتأكيد';
          case AppLanguage.kurdish: return 'دووبارە بنووسە بۆ دڵنیابوونەوە';
          default: return 'Re-enter PIN to confirm';
        }
      }
      switch (lang.currentLanguage) {
        case AppLanguage.arabic: return 'أدخل رمز PIN مكون من 4 أرقام';
        case AppLanguage.kurdish: return 'PIN ی 4 ژمارەیی بنووسە';
        default: return 'Enter a 4-digit PIN';
      }
    }
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'أدخل الرمز لفتح التطبيق';
      case AppLanguage.kurdish: return 'PIN بنووسە بۆ کردنەوەی ئەپ';
      default: return 'Enter PIN to unlock';
    }
  }
  
  String _getBiometricText(LanguageService lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'استخدم البصمة';
      case AppLanguage.kurdish: return 'پەنجەمۆر بەکاربێنە';
      default: return 'Use Fingerprint';
    }
  }
  
  String _getWrongPinError() {
    final lang = Provider.of<LanguageService>(context, listen: false);
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'رمز PIN غير صحيح';
      case AppLanguage.kurdish: return 'PIN هەڵەیە';
      default: return 'Wrong PIN';
    }
  }
  
  String _getPinMismatchError() {
    final lang = Provider.of<LanguageService>(context, listen: false);
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'الرمز غير متطابق، حاول مرة أخرى';
      case AppLanguage.kurdish: return 'PIN یەک نین، دووبارە هەوڵ بدەوە';
      default: return 'PINs don\'t match, try again';
    }
  }
  
  String _getPinSetupError() {
    final lang = Provider.of<LanguageService>(context, listen: false);
    switch (lang.currentLanguage) {
      case AppLanguage.arabic: return 'حدث خطأ، حاول مرة أخرى';
      case AppLanguage.kurdish: return 'هەڵەیەک ڕوویدا';
      default: return 'Error occurred, try again';
    }
  }
}
