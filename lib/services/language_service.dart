import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppLanguage { arabic, kurdish, english }
enum AppTheme { light, dark }

class LanguageService extends ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.arabic;
  AppTheme _currentTheme = AppTheme.dark;
  double _textScale = 1.0; // 0.8 to 1.4 range
  
  AppLanguage get currentLanguage => _currentLanguage;
  AppTheme get currentTheme => _currentTheme;
  bool get isDarkMode => _currentTheme == AppTheme.dark;
  double get textScale => _textScale;
  
  bool get isRTL => _currentLanguage != AppLanguage.english;
  
  TextDirection get textDirection => 
      _currentLanguage == AppLanguage.english ? TextDirection.ltr : TextDirection.rtl;

  // Cached base fonts for performance - prevents repeated font loading
  static final TextStyle _cachedArabicFont = GoogleFonts.cairo();
  static final TextStyle _cachedKurdishFont = GoogleFonts.vazirmatn();
  static final TextStyle _cachedEnglishFont = GoogleFonts.poppins();

  TextStyle getTextStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
    List<Shadow>? shadows,
    TextDecoration? decoration,
  }) {
    // Apply text scale to fontSize
    final scaledFontSize = fontSize * _textScale;
    
    // Use cached base font and apply variations with copyWith
    final baseFont = switch (_currentLanguage) {
      AppLanguage.kurdish => _cachedKurdishFont,
      AppLanguage.arabic => _cachedArabicFont,
      AppLanguage.english => _cachedEnglishFont,
    };
    
    return baseFont.copyWith(
      fontSize: scaledFontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      shadows: shadows,
      decoration: decoration,
    );
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langIndex = prefs.getInt('language') ?? 0;
    final themeIndex = prefs.getInt('theme') ?? 1; // Default dark
    final scale = prefs.getDouble('textScale') ?? 1.0;
    _currentLanguage = AppLanguage.values[langIndex];
    _currentTheme = AppTheme.values[themeIndex];
    _textScale = scale.clamp(0.8, 1.4);
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('language', language.index);
    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme', theme.index);
    notifyListeners();
  }

  Future<void> setTextScale(double scale) async {
    _textScale = scale.clamp(0.8, 1.4);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textScale', _textScale);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await setTheme(_currentTheme == AppTheme.dark ? AppTheme.light : AppTheme.dark);
  }

  String get textSizeName {
    if (_textScale <= 0.85) {
      switch (_currentLanguage) {
        case AppLanguage.arabic: return 'صغير';
        case AppLanguage.kurdish: return 'بچوک';
        case AppLanguage.english: return 'Small';
      }
    } else if (_textScale <= 1.05) {
      switch (_currentLanguage) {
        case AppLanguage.arabic: return 'متوسط';
        case AppLanguage.kurdish: return 'ناوەند';
        case AppLanguage.english: return 'Medium';
      }
    } else if (_textScale <= 1.25) {
      switch (_currentLanguage) {
        case AppLanguage.arabic: return 'كبير';
        case AppLanguage.kurdish: return 'گەورە';
        case AppLanguage.english: return 'Large';
      }
    } else {
      switch (_currentLanguage) {
        case AppLanguage.arabic: return 'كبير جداً';
        case AppLanguage.kurdish: return 'زۆر گەورە';
        case AppLanguage.english: return 'Extra Large';
      }
    }
  }

  String get languageName {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'العربية';
      case AppLanguage.kurdish: return 'کوردی';
      case AppLanguage.english: return 'English';
    }
  }

  String get themeName {
    switch (_currentLanguage) {
      case AppLanguage.arabic:
        return isDarkMode ? 'الوضع الداكن' : 'الوضع الفاتح';
      case AppLanguage.kurdish:
        return isDarkMode ? 'دۆخی تاریک' : 'دۆخی ڕوناک';
      case AppLanguage.english:
        return isDarkMode ? 'Dark Mode' : 'Light Mode';
    }
  }

  // App Strings
  String get appName {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'التعافي من الإدمان';
      case AppLanguage.kurdish: return 'چاکبوونەوە لە ئیدمان';
      case AppLanguage.english: return 'Addiction Recovery';
    }
  }

  String get appSlogan {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'رحلتك نحو حياة أفضل تبدأ من هنا';
      case AppLanguage.kurdish: return 'گەشتەکەت بۆ ژیانێکی باشتر لێرەوە دەست پێدەکات';
      case AppLanguage.english: return 'Your journey to a better life starts here';
    }
  }

  String get login {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'تسجيل الدخول';
      case AppLanguage.kurdish: return 'چوونە ژوورەوە';
      case AppLanguage.english: return 'Login';
    }
  }

  String get email {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'البريد الإلكتروني';
      case AppLanguage.kurdish: return 'ئیمەیڵ';
      case AppLanguage.english: return 'Email';
    }
  }

  String get password {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'كلمة المرور';
      case AppLanguage.kurdish: return 'وشەی نهێنی';
      case AppLanguage.english: return 'Password';
    }
  }

  String get confirmPassword {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'تأكيد كلمة المرور';
      case AppLanguage.kurdish: return 'دووبارەکردنەوەی وشەی نهێنی';
      case AppLanguage.english: return 'Confirm Password';
    }
  }

  String get fullName {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'الاسم الكامل';
      case AppLanguage.kurdish: return 'ناوی تەواو';
      case AppLanguage.english: return 'Full Name';
    }
  }

  String get noAccount {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'ليس لديك حساب؟';
      case AppLanguage.kurdish: return 'ئەکاونتت نییە؟';
      case AppLanguage.english: return "Don't have an account?";
    }
  }

  String get createAccount {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'إنشاء حساب جديد';
      case AppLanguage.kurdish: return 'دروستکردنی ئەکاونت';
      case AppLanguage.english: return 'Create Account';
    }
  }

  String get haveAccount {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'لديك حساب بالفعل؟';
      case AppLanguage.kurdish: return 'ئەکاونتت هەیە؟';
      case AppLanguage.english: return 'Already have an account?';
    }
  }

  String get loginNow {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'سجل دخولك';
      case AppLanguage.kurdish: return 'بچۆ ژوورەوە';
      case AppLanguage.english: return 'Login now';
    }
  }

  String get guestLogin {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'الدخول كزائر';
      case AppLanguage.kurdish: return 'چوونە ژوورەوە بە زائر';
      case AppLanguage.english: return 'Continue as Guest';
    }
  }

  String get or {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'أو';
      case AppLanguage.kurdish: return 'یان';
      case AppLanguage.english: return 'or';
    }
  }

  String get logout {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'تسجيل الخروج';
      case AppLanguage.kurdish: return 'چوونە دەرەوە';
      case AppLanguage.english: return 'Logout';
    }
  }

  String get logoutConfirm {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'هل أنت متأكد من تسجيل الخروج؟';
      case AppLanguage.kurdish: return 'ئایا دڵنیایت دەتەوێت بچیتە دەرەوە؟';
      case AppLanguage.english: return 'Are you sure you want to logout?';
    }
  }

  String get cancel {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'إلغاء';
      case AppLanguage.kurdish: return 'پاشگەزبوونەوە';
      case AppLanguage.english: return 'Cancel';
    }
  }

  String get yes {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'نعم';
      case AppLanguage.kurdish: return 'بەڵێ';
      case AppLanguage.english: return 'Yes';
    }
  }

  String welcome(String name) {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'مرحباً، $name!';
      case AppLanguage.kurdish: return 'بەخێربێیت، $name!';
      case AppLanguage.english: return 'Welcome, $name!';
    }
  }

  String get guest {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'زائر';
      case AppLanguage.kurdish: return 'میوان';
      case AppLanguage.english: return 'Guest';
    }
  }

  String get guestMode {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'دخول كزائر';
      case AppLanguage.kurdish: return 'چوونە ژوورەوە بە میوان';
      case AppLanguage.english: return 'Guest Mode';
    }
  }

  String get activeAccount {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'حساب مُفعّل';
      case AppLanguage.kurdish: return 'ئەکاونت چالاکە';
      case AppLanguage.english: return 'Active Account';
    }
  }

  String get motivationalQuote {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return '"تذكر أن التعافي هو اختيارك، اختيارك أنك تعيش بكرامة"';
      case AppLanguage.kurdish: return '"بیرهێنەوە چاکبوونەوە هەڵبژاردنی خۆتە، هەڵبژاردنت ئەوەیە بە ڕێز بژیت"';
      case AppLanguage.english: return '"Remember that recovery is your choice, your choice to live with dignity"';
    }
  }

  // Timer strings
  String get months {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'أشهر';
      case AppLanguage.kurdish: return 'مانگ';
      case AppLanguage.english: return 'Months';
    }
  }

  String get days {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'أيام';
      case AppLanguage.kurdish: return 'ڕۆژ';
      case AppLanguage.english: return 'Days';
    }
  }

  String get hours {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'ساعات';
      case AppLanguage.kurdish: return 'کاتژمێر';
      case AppLanguage.english: return 'Hours';
    }
  }

  String get minutesStr {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'دقائق';
      case AppLanguage.kurdish: return 'خولەک';
      case AppLanguage.english: return 'Minutes';
    }
  }

  String get secondsStr {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'ثانية';
      case AppLanguage.kurdish: return 'چرکە';
      case AppLanguage.english: return 'Seconds';
    }
  }

  String get startRecovery {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'ابدأ رحلة التعافي';
      case AppLanguage.kurdish: return 'گەشتی چاکبوونەوە دەست پێبکە';
      case AppLanguage.english: return 'Start Recovery Journey';
    }
  }

  String get resetTimer {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'إعادة تعيين العداد';
      case AppLanguage.kurdish: return 'ڕیسێتکردنی عداد';
      case AppLanguage.english: return 'Reset Timer';
    }
  }

  String get timerSettings {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'إعدادات العداد';
      case AppLanguage.kurdish: return 'ڕێکخستنەکانی عداد';
      case AppLanguage.english: return 'Timer Settings';
    }
  }

  String get setCustomDate {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'تحديد تاريخ مخصص';
      case AppLanguage.kurdish: return 'دیاریکردنی بەروار بە دەست';
      case AppLanguage.english: return 'Set Custom Date';
    }
  }

  String get resetToNow {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'إلغاء والبدء من الآن';
      case AppLanguage.kurdish: return 'دەستپێکردنەوە لە ئێستاوە';
      case AppLanguage.english: return 'Reset to Now';
    }
  }

  String get resetConfirm {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'هل أنت متأكد؟ سيتم إعادة تعيين العداد.';
      case AppLanguage.kurdish: return 'ئایا دڵنیایت؟ عدادەکە ڕیسێت دەبێتەوە.';
      case AppLanguage.english: return 'Are you sure? The timer will be reset.';
    }
  }

  String get menu {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'القائمة';
      case AppLanguage.kurdish: return 'مینیو';
      case AppLanguage.english: return 'Menu';
    }
  }

  String get home {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'الرئيسية';
      case AppLanguage.kurdish: return 'سەرەکی';
      case AppLanguage.english: return 'Home';
    }
  }

  String get settings {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'الإعدادات';
      case AppLanguage.kurdish: return 'ڕێکخستنەکان';
      case AppLanguage.english: return 'Settings';
    }
  }

  String get yourPath {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'طريقك نحو حياة أفضل';
      case AppLanguage.kurdish: return 'ڕێگاکەت بۆ ژیانێکی باشتر';
      case AppLanguage.english: return 'Your path to a better life';
    }
  }

  String get language {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'اللغة';
      case AppLanguage.kurdish: return 'زمان';
      case AppLanguage.english: return 'Language';
    }
  }

  String get appearance {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'المظهر';
      case AppLanguage.kurdish: return 'ڕوانگە';
      case AppLanguage.english: return 'Appearance';
    }
  }

  String get enterEmail {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'الرجاء إدخال البريد الإلكتروني';
      case AppLanguage.kurdish: return 'تکایە ئیمەیڵەکەت بنوسە';
      case AppLanguage.english: return 'Please enter your email';
    }
  }

  String get invalidEmail {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'البريد الإلكتروني غير صحيح';
      case AppLanguage.kurdish: return 'ئیمەیڵ دروست نییە';
      case AppLanguage.english: return 'Invalid email address';
    }
  }

  String get enterPassword {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'الرجاء إدخال كلمة المرور';
      case AppLanguage.kurdish: return 'تکایە وشەی نهێنی بنوسە';
      case AppLanguage.english: return 'Please enter your password';
    }
  }

  String get passwordTooShort {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
      case AppLanguage.kurdish: return 'وشەی نهێنی دەبێ لانیکەم ٦ پیت بێت';
      case AppLanguage.english: return 'Password must be at least 6 characters';
    }
  }

  String get enterName {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'الرجاء إدخال الاسم';
      case AppLanguage.kurdish: return 'تکایە ناوت بنوسە';
      case AppLanguage.english: return 'Please enter your name';
    }
  }

  String get passwordMismatch {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'كلمة المرور غير متطابقة';
      case AppLanguage.kurdish: return 'وشەی نهێنی یەک ناگرێتەوە';
      case AppLanguage.english: return 'Passwords do not match';
    }
  }

  String get confirmPasswordRequired {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'الرجاء تأكيد كلمة المرور';
      case AppLanguage.kurdish: return 'تکایە وشەی نهێنی دووبارە بکەرەوە';
      case AppLanguage.english: return 'Please confirm your password';
    }
  }

  String get support {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'الدعم';
      case AppLanguage.kurdish: return 'پشتگیری';
      case AppLanguage.english: return 'Support';
    }
  }

  String get withYou {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'نحن معك';
      case AppLanguage.kurdish: return 'لەگەڵتین';
      case AppLanguage.english: return "We're with you";
    }
  }

  String get guidance {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'الإرشاد';
      case AppLanguage.kurdish: return 'ڕێنمایی';
      case AppLanguage.english: return 'Guidance';
    }
  }

  String get stepByStep {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'خطوة بخطوة';
      case AppLanguage.kurdish: return 'هەنگاو بە هەنگاو';
      case AppLanguage.english: return 'Step by step';
    }
  }

  String get progress {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'التقدم';
      case AppLanguage.kurdish: return 'پێشکەوتن';
      case AppLanguage.english: return 'Progress';
    }
  }

  String get trackGoals {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'تتبع أهدافك';
      case AppLanguage.kurdish: return 'ئامانجەکانت بەدواداچوون بکە';
      case AppLanguage.english: return 'Track your goals';
    }
  }

  String get success {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'النجاح';
      case AppLanguage.kurdish: return 'سەرکەوتن';
      case AppLanguage.english: return 'Success';
    }
  }

  String get achieveDreams {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'حقق أحلامك';
      case AppLanguage.kurdish: return 'خەونەکانت بەدیبهێنە';
      case AppLanguage.english: return 'Achieve your dreams';
    }
  }

  String get joinUs {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'انضم إلينا وابدأ رحلة التعافي';
      case AppLanguage.kurdish: return 'پەیوەندیمان پێوە بکە و گەشتی چاکبوونەوە دەستپێبکە';
      case AppLanguage.english: return 'Join us and start your recovery journey';
    }
  }

  String get comingSoon {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'قريباً';
      case AppLanguage.kurdish: return 'بەم زووانە';
      case AppLanguage.english: return 'Coming Soon';
    }
  }

  String get contentManagement {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'إدارة المحتوى';
      case AppLanguage.kurdish: return 'بەڕێوەبردنی ناوەڕۆک';
      case AppLanguage.english: return 'Content Management';
    }
  }

  String get setCustomDateTime {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'تحديد التاريخ والوقت';
      case AppLanguage.kurdish: return 'دیاریکردنی بەروار و کات';
      case AppLanguage.english: return 'Set Date & Time';
    }
  }

  String get selectTime {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'اختر الوقت';
      case AppLanguage.kurdish: return 'کات هەڵبژێرە';
      case AppLanguage.english: return 'Select Time';
    }
  }

  String get developerOnly {
    switch (_currentLanguage) {
      case AppLanguage.arabic: return 'للمطور فقط';
      case AppLanguage.kurdish: return 'تەنها بۆ پەرەپێدەر';
      case AppLanguage.english: return 'Developer Only';
    }
  }
}
