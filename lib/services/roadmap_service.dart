import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A single task within a recovery stage
class StageTask {
  final String id;
  final String titleAr;
  final String titleKu;
  final String titleEn;
  final String descriptionAr;
  final String descriptionKu;
  final String descriptionEn;
  final IconData icon;

  const StageTask({
    required this.id,
    required this.titleAr,
    required this.titleKu,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionKu,
    required this.descriptionEn,
    required this.icon,
  });

  String getTitle(String lang) {
    if (lang == 'ar') return titleAr;
    if (lang == 'ku') return titleKu;
    return titleEn;
  }

  String getDescription(String lang) {
    if (lang == 'ar') return descriptionAr;
    if (lang == 'ku') return descriptionKu;
    return descriptionEn;
  }
}

/// A recovery stage on the roadmap
class RecoveryStage {
  final int stageNumber; // 1-10
  final String nameAr;
  final String nameKu;
  final String nameEn;
  final String descriptionAr;
  final String descriptionKu;
  final String descriptionEn;
  final String adviceAr;
  final String adviceKu;
  final String adviceEn;
  final String emoji;
  final Color color;
  final int requiredDays; // minimum days to unlock this stage
  final List<StageTask> tasks;

  const RecoveryStage({
    required this.stageNumber,
    required this.nameAr,
    required this.nameKu,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionKu,
    required this.descriptionEn,
    required this.adviceAr,
    required this.adviceKu,
    required this.adviceEn,
    required this.emoji,
    required this.color,
    required this.requiredDays,
    required this.tasks,
  });

  String getName(String lang) {
    if (lang == 'ar') return nameAr;
    if (lang == 'ku') return nameKu;
    return nameEn;
  }

  String getDescription(String lang) {
    if (lang == 'ar') return descriptionAr;
    if (lang == 'ku') return descriptionKu;
    return descriptionEn;
  }

  String getAdvice(String lang) {
    if (lang == 'ar') return adviceAr;
    if (lang == 'ku') return adviceKu;
    return adviceEn;
  }
}

class RoadmapService extends ChangeNotifier {
  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State
  Set<String> _completedTaskIds = {};
  int _currentRecoveryDays = 0;
  static const String _storageKey = 'roadmap_progress';

  Set<String> get completedTaskIds => _completedTaskIds;
  int get currentRecoveryDays => _currentRecoveryDays;

  String? get _userId => _auth.currentUser?.uid;
  bool get _isLoggedIn {
    final user = _auth.currentUser;
    return user != null && !user.isAnonymous;
  }

  /// 10 Recovery Stages
  static const List<RecoveryStage> stages = [
    // Stage 1: Awareness (Day 0)
    RecoveryStage(
      stageNumber: 1,
      nameAr: 'مرحلة الوعي',
      nameKu: 'قۆناغی ئاگاداری',
      nameEn: 'Awareness Stage',
      descriptionAr: 'اعترف بالمشكلة وابدأ رحلتك',
      descriptionKu: 'دانپیاننان بە کێشەکە و دەستپێکی ڕێگاکەت',
      descriptionEn: 'Acknowledge the problem and start your journey',
      adviceAr: 'الخطوة الأولى والأهم هي الاعتراف. لا تنكر ولا تبرر. أنت هنا لأنك شجاع وتريد التغيير.',
      adviceKu: 'یەکەم و گرنگترین هەنگاو دانپیاننانە. نکۆڵی لێ مەکە و بیانوو مەهێنە. تۆ لێرەیت چونکە ئازایت و دەتەوێت بگۆڕیت.',
      adviceEn: 'The first and most important step is acknowledgment. Don\'t deny or justify. You are here because you are brave and want change.',
      emoji: '🌱',
      color: Color(0xFF4CAF50),
      requiredDays: 0,
      tasks: [
        StageTask(
          id: 's1_t1',
          titleAr: 'اكتب رسالة لنفسك',
          titleKu: 'نامەیەک بنوسە بۆ خۆت',
          titleEn: 'Write a letter to yourself',
          descriptionAr: 'اكتب لماذا تريد التغيير وما الحياة التي تحلم بها',
          descriptionKu: 'بنوسە بۆچی دەتەوێت بگۆڕیت و چ ژیانێکت دەوێت',
          descriptionEn: 'Write why you want to change and what life you dream of',
          icon: Icons.edit_note,
        ),
        StageTask(
          id: 's1_t2',
          titleAr: 'خذ تقييم الإدمان',
          titleKu: 'تاقیکردنەوەی ئاستی ئالوودەبوون بکە',
          titleEn: 'Take the addiction assessment',
          descriptionAr: 'اعرف مستواك الحالي بصدق',
          descriptionKu: 'ئاستی ئێستات بە ڕاستگۆیی بزانە',
          descriptionEn: 'Know your current level honestly',
          icon: Icons.assessment,
        ),
        StageTask(
          id: 's1_t3',
          titleAr: 'ابدأ تحدي ال 90 يوم',
          titleKu: 'چاڵینجی ٩٠ ڕۆژ دەست پێ بکە',
          titleEn: 'Start the 90-day challenge',
          descriptionAr: 'التزم بالتحدي كخطوة أولى',
          descriptionKu: 'پابەند بە بە چاڵینج وەک یەکەم هەنگاو',
          descriptionEn: 'Commit to the challenge as a first step',
          icon: Icons.flag,
        ),
      ],
    ),

    // Stage 2: Detox (Day 3)
    RecoveryStage(
      stageNumber: 2,
      nameAr: 'مرحلة التخلص من السموم',
      nameKu: 'قۆناغی پاکبوونەوە',
      nameEn: 'Detox Stage',
      descriptionAr: 'الأيام الأولى هي الأصعب. ابقَ قوياً!',
      descriptionKu: 'یەکەم ڕۆژەکان سەختترینن. بەهێز بمێنەوە!',
      descriptionEn: 'The first days are the hardest. Stay strong!',
      adviceAr: 'قد تشعر بأعراض انسحابية: قلق، أرق، تقلب مزاج. هذا طبيعي جداً وعلامة على أن جسمك يتعافى.',
      adviceKu: 'ڕەنگە نیشانەی کشانەوەت هەبێت: نیگەرانی، بێخەوی، گۆڕانی کەیف. ئەمە زۆر ئاساییە و نیشانەی چاکبوونەوەی جەستەتە.',
      adviceEn: 'You may experience withdrawal symptoms: anxiety, insomnia, mood swings. This is very normal and a sign your body is healing.',
      emoji: '🧹',
      color: Color(0xFF66BB6A),
      requiredDays: 3,
      tasks: [
        StageTask(
          id: 's2_t1',
          titleAr: 'احذف كل المحتوى المحفوظ',
          titleKu: 'هەموو ناوەڕۆکی پاشەکەوتکراو بسڕەوە',
          titleEn: 'Delete all saved content',
          descriptionAr: 'نظف هاتفك وحاسوبك من أي محتوى إباحي',
          descriptionKu: 'موبایل و کۆمپیوتەرەکەت لە هەر ناوەڕۆکێکی ئیباحی پاک بکەوە',
          descriptionEn: 'Clean your phone and computer from any pornographic content',
          icon: Icons.delete_forever,
        ),
        StageTask(
          id: 's2_t2',
          titleAr: 'تعلم تمارين التنفس',
          titleKu: 'ڕاهێنانی تەنەفوسکردن فێربە',
          titleEn: 'Learn breathing exercises',
          descriptionAr: 'استخدم تمارين التنفس عند الرغبة الملحة',
          descriptionKu: 'ڕاهێنانی تەنەفوسکردن بەکاربهێنە کاتێک ئورج دێت',
          descriptionEn: 'Use breathing exercises during urges',
          icon: Icons.air,
        ),
        StageTask(
          id: 's2_t3',
          titleAr: 'سجل يومك في المتابعة اليومية',
          titleKu: 'ڕۆژەکەت لە تراکینگ تۆمار بکە',
          titleEn: 'Record your day in daily tracking',
          descriptionAr: 'تتبع يومك لمدة 3 أيام متتالية',
          descriptionKu: 'بۆ ٣ ڕۆژ بەردەوام ڕۆژەکانت تۆمار بکە',
          descriptionEn: 'Track your days for 3 consecutive days',
          icon: Icons.calendar_today,
        ),
      ],
    ),

    // Stage 3: Building Foundations (Day 7)
    RecoveryStage(
      stageNumber: 3,
      nameAr: 'بناء الأساس',
      nameKu: 'دروستکردنی بنەما',
      nameEn: 'Building Foundations',
      descriptionAr: 'أسبوع كامل! ابدأ ببناء عادات جديدة',
      descriptionKu: 'هەفتەیەکی تەواو! دەست بکە بە دروستکردنی ڕاهێنانی نوێ',
      descriptionEn: 'A full week! Start building new habits',
      adviceAr: 'الآن حان وقت استبدال العادات السيئة بعادات صحية. الفراغ هو عدوك الأول.',
      adviceKu: 'ئێستا کاتی ئەوەیە ڕاهێنانە خراپەکان بگۆڕیت بە ڕاهێنانی تەندروست. بەتاڵی یەکەم دوژمنتە.',
      adviceEn: 'Now it\'s time to replace bad habits with healthy ones. Free time is your first enemy.',
      emoji: '🏗️',
      color: Color(0xFF42A5F5),
      requiredDays: 7,
      tasks: [
        StageTask(
          id: 's3_t1',
          titleAr: 'أضف 3 عادات صحية',
          titleKu: '٣ ڕاهێنانی تەندروست زیاد بکە',
          titleEn: 'Add 3 healthy habits',
          descriptionAr: 'اختر عادات مثل الرياضة، القراءة، الذكر',
          descriptionKu: 'ڕاهێنان هەڵبژێرە وەک وەرزش، خوێندنەوە، زیکر',
          descriptionEn: 'Choose habits like exercise, reading, prayer',
          icon: Icons.fitness_center,
        ),
        StageTask(
          id: 's3_t2',
          titleAr: 'اكتب في دفتر اليوميات',
          titleKu: 'لە ڕۆژنامەدا بنوسە',
          titleEn: 'Write in your journal',
          descriptionAr: 'اكتب مشاعرك وتجربتك في أول أسبوع',
          descriptionKu: 'هەستەکانت و ئەزموونەکەت بنوسە لە یەکەم هەفتە',
          descriptionEn: 'Write your feelings and experience in the first week',
          icon: Icons.book,
        ),
        StageTask(
          id: 's3_t3',
          titleAr: 'اقرأ كتاباً من المكتبة',
          titleKu: 'کتێبێک بخوێنەوە لە کتێبخانە',
          titleEn: 'Read a book from the library',
          descriptionAr: 'ابدأ بقراءة كتاب عن التعافي أو تطوير الذات',
          descriptionKu: 'دەست بکە بە خوێندنەوەی کتێبێک دەربارەی چاکبوونەوە یان گەشەی خۆت',
          descriptionEn: 'Start reading a book about recovery or self-improvement',
          icon: Icons.menu_book,
        ),
      ],
    ),

    // Stage 4: Resilience (Day 14)
    RecoveryStage(
      stageNumber: 4,
      nameAr: 'مرحلة الصمود',
      nameKu: 'قۆناغی بەرگری',
      nameEn: 'Resilience Stage',
      descriptionAr: 'أسبوعان! أنت تبني مقاومة حقيقية',
      descriptionKu: 'دوو هەفتە! تۆ بەرگریی ڕاستەقینە دروست دەکەیت',
      descriptionEn: 'Two weeks! You are building real resistance',
      adviceAr: 'الإغراءات ستأتي بقوة. تعلم كيف تتعامل معها بدلاً من الاستسلام.',
      adviceKu: 'ئورجەکان بە هێز دێن. فێربە چۆن مامەڵەیان لەگەڵ بکەیت لەجیاتی مانەوە.',
      adviceEn: 'Temptations will come strong. Learn how to deal with them instead of giving in.',
      emoji: '🛡️',
      color: Color(0xFF5C6BC0),
      requiredDays: 14,
      tasks: [
        StageTask(
          id: 's4_t1',
          titleAr: 'اكتب رسالة الالتزام',
          titleKu: 'نامەی پەیمان بنوسە',
          titleEn: 'Write a commitment letter',
          descriptionAr: 'اكتب التزامك بالتغيير وأعد قراءته عند الضعف',
          descriptionKu: 'پابەندبوونت بە گۆڕانکاری بنوسە و کاتێک لاواز دەبیت بیخوێنەوە',
          descriptionEn: 'Write your commitment to change and re-read it when weak',
          icon: Icons.handshake,
        ),
        StageTask(
          id: 's4_t2',
          titleAr: 'استخدم نصائح الإغراء 5 مرات',
          titleKu: 'ئامۆژگاری ئورج ٥ جار بەکاربهێنە',
          titleEn: 'Use urge tips 5 times',
          descriptionAr: 'عند كل رغبة، اقرأ نصيحة من قسم الإغراء',
          descriptionKu: 'لە هەر ئورجێکدا، ئامۆژگارییەک بخوێنەوە لە بەشی ئورج',
          descriptionEn: 'At every urge, read a tip from the urge section',
          icon: Icons.tips_and_updates,
        ),
        StageTask(
          id: 's4_t3',
          titleAr: 'أكمل 14 يوم متابعة',
          titleKu: '١٤ ڕۆژ تراکینگ تەواو بکە',
          titleEn: 'Complete 14 days of tracking',
          descriptionAr: 'سجل حالتك اليومية لمدة أسبوعين كاملين',
          descriptionKu: 'بۆ دوو هەفتەی تەواو بارودۆخی ڕۆژانەت تۆمار بکە',
          descriptionEn: 'Record your daily status for two full weeks',
          icon: Icons.event_available,
        ),
      ],
    ),

    // Stage 5: Self-Discovery (Day 21)
    RecoveryStage(
      stageNumber: 5,
      nameAr: 'اكتشاف الذات',
      nameKu: 'دۆزینەوەی خۆت',
      nameEn: 'Self-Discovery',
      descriptionAr: '3 أسابيع! حان وقت فهم أعمق لنفسك',
      descriptionKu: '٣ هەفتە! کاتی تێگەیشتنی قووڵتر لە خۆتە',
      descriptionEn: '3 weeks! Time for deeper self-understanding',
      adviceAr: 'ابحث عن الأسباب الجذرية. لماذا لجأت للإباحية؟ ملل؟ وحدة؟ قلق؟ الفهم هو مفتاح التعافي.',
      adviceKu: 'بەدوای هۆکارە سەرەکییەکاندا بگەڕێ. بۆچی پەنات بۆ ئیباحیەت برد؟ بێزاری؟ تەنیایی؟ نیگەرانی؟ تێگەیشتن کلیلی چاکبوونەوەیە.',
      adviceEn: 'Look for root causes. Why did you turn to pornography? Boredom? Loneliness? Anxiety? Understanding is the key to recovery.',
      emoji: '🔍',
      color: Color(0xFF7E57C2),
      requiredDays: 21,
      tasks: [
        StageTask(
          id: 's5_t1',
          titleAr: 'اكتب 5 محفزات لديك',
          titleKu: '٥ هانەری خۆت بنوسە',
          titleEn: 'Write 5 of your triggers',
          descriptionAr: 'حدد المواقف والمشاعر التي تدفعك للمشاهدة',
          descriptionKu: 'بارودۆخ و هەستەکان دیاری بکە کە پاڵت دەنێن بۆ تەماشاکردن',
          descriptionEn: 'Identify situations and feelings that push you to watch',
          icon: Icons.psychology,
        ),
        StageTask(
          id: 's5_t2',
          titleAr: 'أكمل 5 عادات يومية',
          titleKu: '٥ ڕاهێنانی ڕۆژانە تەواو بکە',
          titleEn: 'Complete 5 daily habits',
          descriptionAr: 'اجعل عاداتك الصحية جزءاً من روتينك',
          descriptionKu: 'ڕاهێنانە تەندروستەکانت بکە بەشێک لە ڕووتینەکەت',
          descriptionEn: 'Make your healthy habits part of your routine',
          icon: Icons.check_circle,
        ),
        StageTask(
          id: 's5_t3',
          titleAr: 'اكتب في يومياتك 7 مرات',
          titleKu: '٧ جار لە ڕۆژنامەکەت بنوسە',
          titleEn: 'Write in your journal 7 times',
          descriptionAr: 'عبر عن مشاعرك بانتظام',
          descriptionKu: 'هەستەکانت بە بەردەوامی دەربڕین بکە',
          descriptionEn: 'Express your feelings regularly',
          icon: Icons.edit_calendar,
        ),
      ],
    ),

    // Stage 6: Strength (Day 30)
    RecoveryStage(
      stageNumber: 6,
      nameAr: 'مرحلة القوة',
      nameKu: 'قۆناغی بەهێزبوون',
      nameEn: 'Strength Stage',
      descriptionAr: 'شهر كامل! 🎉 أنت أقوى مما تتخيل',
      descriptionKu: 'مانگێکی تەواو! 🎉 تۆ بەهێزتریت لەوەی بیری لێ دەکەیتەوە',
      descriptionEn: 'A full month! 🎉 You are stronger than you think',
      adviceAr: 'شهر واحد هو إنجاز عظيم! دماغك بدأ يتعافى فعلياً. استمر!',
      adviceKu: 'یەک مانگ دەستکەوتێکی گەورەیە! مێشکت بە ڕاستی دەست بە چاکبوونەوە کردووە. بەردەوام بە!',
      adviceEn: 'One month is a great achievement! Your brain has actually started healing. Keep going!',
      emoji: '💪',
      color: Color(0xFFEC407A),
      requiredDays: 30,
      tasks: [
        StageTask(
          id: 's6_t1',
          titleAr: 'خذ التقييم مرة أخرى',
          titleKu: 'تاقیکردنەوە دووبارە بکەوە',
          titleEn: 'Take the assessment again',
          descriptionAr: 'قارن نتيجتك مع التقييم الأول',
          descriptionKu: 'ئەنجامەکەت بەراورد بکە لەگەڵ تاقیکردنەوەی یەکەم',
          descriptionEn: 'Compare your result with the first assessment',
          icon: Icons.compare_arrows,
        ),
        StageTask(
          id: 's6_t2',
          titleAr: 'اقرأ 3 جرعات إيمانية',
          titleKu: '٣ دۆزی ئیمانی بخوێنەوە',
          titleEn: 'Read 3 faith doses',
          descriptionAr: 'اقرأ وتأمل في القصص الإيمانية',
          descriptionKu: 'چیرۆکە ئیمانییەکان بخوێنەوە و بیربکەوە',
          descriptionEn: 'Read and reflect on the faith stories',
          icon: Icons.auto_stories,
        ),
        StageTask(
          id: 's6_t3',
          titleAr: 'أكمل 30 يوم تتبع',
          titleKu: '٣٠ ڕۆژ تراکینگ تەواو بکە',
          titleEn: 'Complete 30 days of tracking',
          descriptionAr: 'شهر كامل من تسجيل حالتك اليومية',
          descriptionKu: 'مانگێکی تەواو لە تۆمارکردنی بارودۆخی ڕۆژانەت',
          descriptionEn: 'A full month of recording your daily status',
          icon: Icons.calendar_month,
        ),
      ],
    ),

    // Stage 7: Transformation (Day 45)
    RecoveryStage(
      stageNumber: 7,
      nameAr: 'مرحلة التحول',
      nameKu: 'قۆناغی گۆڕانکاری',
      nameEn: 'Transformation Stage',
      descriptionAr: 'شهر ونصف! أنت شخص مختلف الآن',
      descriptionKu: 'مانگ و نیو! تۆ ئێستا کەسێکی جیاوازیت',
      descriptionEn: '45 days! You are a different person now',
      adviceAr: 'لاحظ التغييرات: تركيزك أفضل، علاقاتك أقوى، ثقتك أكبر. هذا أنت الحقيقي!',
      adviceKu: 'سەرنج بدە بە گۆڕانکارییەکان: تەرکیزت باشترە، پەیوەندییەکانت بەهێزترن، متمانەت زیاترە. ئەمە خۆتی ڕاستەقینەیە!',
      adviceEn: 'Notice the changes: better focus, stronger relationships, more confidence. This is the real you!',
      emoji: '🦋',
      color: Color(0xFFFF7043),
      requiredDays: 45,
      tasks: [
        StageTask(
          id: 's7_t1',
          titleAr: 'ساعد شخصاً آخر',
          titleKu: 'یارمەتی کەسێکی تر بدە',
          titleEn: 'Help someone else',
          descriptionAr: 'شارك تجربتك في المجتمع أو ساعد مبتدئاً',
          descriptionKu: 'ئەزموونەکەت لە کۆمەڵگادا هاوبەش بکە یان یارمەتی تازەکارێک بدە',
          descriptionEn: 'Share your experience in the community or help a beginner',
          icon: Icons.people,
        ),
        StageTask(
          id: 's7_t2',
          titleAr: 'أكمل 10 عادات مختلفة',
          titleKu: '١٠ ڕاهێنانی جیاواز تەواو بکە',
          titleEn: 'Complete 10 different habits',
          descriptionAr: 'وسع نطاق عاداتك الصحية',
          descriptionKu: 'بواری ڕاهێنانە تەندروستەکانت فراوان بکە',
          descriptionEn: 'Expand the range of your healthy habits',
          icon: Icons.star,
        ),
      ],
    ),

    // Stage 8: Mastery (Day 60)
    RecoveryStage(
      stageNumber: 8,
      nameAr: 'مرحلة الإتقان',
      nameKu: 'قۆناغی شارەزایی',
      nameEn: 'Mastery Stage',
      descriptionAr: 'شهران! أصبحت خبيراً في التعافي',
      descriptionKu: 'دوو مانگ! شارەزا بوویت لە چاکبوونەوە',
      descriptionEn: 'Two months! You have become an expert in recovery',
      adviceAr: 'لا تتراخ! كثيرون يسقطون بعد 60 يوماً بسبب الثقة الزائدة. ابقَ متيقظاً.',
      adviceKu: 'سوست مەبە! زۆر کەس دوای ٦٠ ڕۆژ دەکەون بەهۆی متمانەی زیادە. ئاگادار بمێنەوە.',
      adviceEn: 'Don\'t slack! Many fall after 60 days due to overconfidence. Stay vigilant.',
      emoji: '🏆',
      color: Color(0xFFFFB300),
      requiredDays: 60,
      tasks: [
        StageTask(
          id: 's8_t1',
          titleAr: 'اكتب قصة نجاحك',
          titleKu: 'چیرۆکی سەرکەوتنەکەت بنوسە',
          titleEn: 'Write your success story',
          descriptionAr: 'شارك رحلتك لإلهام الآخرين',
          descriptionKu: 'ڕێگاکەت هاوبەش بکە بۆ هاندانی کەسانی تر',
          descriptionEn: 'Share your journey to inspire others',
          icon: Icons.emoji_events,
        ),
        StageTask(
          id: 's8_t2',
          titleAr: 'أكمل 60 يوم تتبع',
          titleKu: '٦٠ ڕۆژ تراکینگ تەواو بکە',
          titleEn: 'Complete 60 days of tracking',
          descriptionAr: 'شهران كاملان من المتابعة المنتظمة',
          descriptionKu: 'دوو مانگی تەواو لە چاودێری بەردەوام',
          descriptionEn: 'Two full months of regular tracking',
          icon: Icons.trending_up,
        ),
      ],
    ),

    // Stage 9: Freedom (Day 90)
    RecoveryStage(
      stageNumber: 9,
      nameAr: 'مرحلة الحرية',
      nameKu: 'قۆناغی ئازادی',
      nameEn: 'Freedom Stage',
      descriptionAr: '90 يوماً! 🎉🎉 أنت حر!',
      descriptionKu: '٩٠ ڕۆژ! 🎉🎉 تۆ ئازادیت!',
      descriptionEn: '90 days! 🎉🎉 You are free!',
      adviceAr: 'هذه لحظة تاريخية في حياتك. لكن تذكر: التعافي رحلة مستمرة وليست وجهة.',
      adviceKu: 'ئەمە ساتێکی مێژوویییە لە ژیانتدا. بەڵام بیرت بێتەوە: چاکبوونەوە ڕێگایەکی بەردەوامە نەک مەنزیل.',
      adviceEn: 'This is a historic moment in your life. But remember: recovery is an ongoing journey, not a destination.',
      emoji: '🕊️',
      color: Color(0xFF26A69A),
      requiredDays: 90,
      tasks: [
        StageTask(
          id: 's9_t1',
          titleAr: 'أكمل تحدي ال 90 يوم',
          titleKu: 'چاڵینجی ٩٠ ڕۆژ تەواو بکە',
          titleEn: 'Complete the 90-day challenge',
          descriptionAr: 'وصلت! أنت بطل حقيقي!',
          descriptionKu: 'گەیشتیت! تۆ پاڵەوانێکی ڕاستەقینەیت!',
          descriptionEn: 'You made it! You are a true champion!',
          icon: Icons.military_tech,
        ),
        StageTask(
          id: 's9_t2',
          titleAr: 'أعد التقييم وقارن',
          titleKu: 'تاقیکردنەوە دووبارە بکە و بەراورد بکە',
          titleEn: 'Retake assessment and compare',
          descriptionAr: 'قارن مستواك الآن مع البداية',
          descriptionKu: 'ئاستی ئێستات بەراورد بکە لەگەڵ سەرەتا',
          descriptionEn: 'Compare your current level with the beginning',
          icon: Icons.analytics,
        ),
      ],
    ),

    // Stage 10: New Life (Day 120+)
    RecoveryStage(
      stageNumber: 10,
      nameAr: 'حياة جديدة',
      nameKu: 'ژیانی نوێ',
      nameEn: 'New Life',
      descriptionAr: 'أنت الآن مرشد للآخرين. ساعد غيرك!',
      descriptionKu: 'ئێستا تۆ ڕێنماییت بۆ کەسانی تر. یارمەتی کەسانی تر بدە!',
      descriptionEn: 'You are now a guide for others. Help them!',
      adviceAr: 'تذكر دائماً من أين بدأت. ساعد الآخرين في رحلتهم. هذا أعظم ما يمكنك فعله.',
      adviceKu: 'هەمیشە بیرت بێتەوە لەکوێوە دەستت پێکرد. یارمەتی کەسانی تر بدە لە ڕێگایاندا. ئەمە گەورەترین شتە دەتوانیت بیکەیت.',
      adviceEn: 'Always remember where you started. Help others in their journey. This is the greatest thing you can do.',
      emoji: '🌟',
      color: Color(0xFFFFD700),
      requiredDays: 120,
      tasks: [
        StageTask(
          id: 's10_t1',
          titleAr: 'كن مرشداً لشخص جديد',
          titleKu: 'ببە بەڕێنمایی بۆ کەسێکی تازە',
          titleEn: 'Become a mentor for someone new',
          descriptionAr: 'شارك خبرتك وساعد المبتدئين في المجتمع',
          descriptionKu: 'شارەزاییت هاوبەش بکە و یارمەتی تازەکارەکان بدە لە کۆمەڵگادا',
          descriptionEn: 'Share your expertise and help beginners in the community',
          icon: Icons.school,
        ),
        StageTask(
          id: 's10_t2',
          titleAr: 'حافظ على 120+ يوم',
          titleKu: '١٢٠+ ڕۆژ بپارێزە',
          titleEn: 'Maintain 120+ days',
          descriptionAr: 'استمر في رحلتك بلا توقف',
          descriptionKu: 'بەردەوام بە لە ڕێگاکەت بەبێ وەستان',
          descriptionEn: 'Continue your journey without stopping',
          icon: Icons.all_inclusive,
        ),
      ],
    ),
  ];

  /// Check if a stage is unlocked based on recovery days
  bool isStageUnlocked(int stageNumber) {
    final stage = stages.firstWhere((s) => s.stageNumber == stageNumber);
    return _currentRecoveryDays >= stage.requiredDays;
  }

  /// Check if a task is completed
  bool isTaskCompleted(String taskId) {
    return _completedTaskIds.contains(taskId);
  }

  /// Get completion percentage for a stage
  double getStageProgress(int stageNumber) {
    final stage = stages.firstWhere((s) => s.stageNumber == stageNumber);
    if (stage.tasks.isEmpty) return 0;
    final completed = stage.tasks.where((t) => _completedTaskIds.contains(t.id)).length;
    return completed / stage.tasks.length;
  }

  /// Check if a stage is fully completed
  bool isStageCompleted(int stageNumber) {
    return getStageProgress(stageNumber) >= 1.0;
  }

  /// Get the current active stage (highest unlocked incomplete stage)
  int getCurrentStage() {
    for (int i = stages.length - 1; i >= 0; i--) {
      if (isStageUnlocked(stages[i].stageNumber)) {
        return stages[i].stageNumber;
      }
    }
    return 1;
  }

  /// Get overall progress
  double getOverallProgress() {
    int totalTasks = 0;
    int completedTasks = 0;
    for (final stage in stages) {
      totalTasks += stage.tasks.length;
      completedTasks += stage.tasks.where((t) => _completedTaskIds.contains(t.id)).length;
    }
    if (totalTasks == 0) return 0;
    return completedTasks / totalTasks;
  }

  /// Toggle task completion
  Future<void> toggleTask(String taskId) async {
    if (_completedTaskIds.contains(taskId)) {
      _completedTaskIds.remove(taskId);
    } else {
      _completedTaskIds.add(taskId);
    }
    await _saveData();
    notifyListeners();
  }

  /// Set recovery days from timer service
  void updateRecoveryDays(int days) {
    if (_currentRecoveryDays != days) {
      _currentRecoveryDays = days;
      notifyListeners();
    }
  }

  /// Load progress
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. ALWAYS load from local storage first
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final json = jsonDecode(data);
      _completedTaskIds = Set<String>.from(json['completedTaskIds'] ?? []);
    }
    notifyListeners();

    // 2. Sync from Firebase — only if it has MORE progress
    if (_isLoggedIn) {
      try {
        final doc = await _firestore.collection('users').doc(_userId).get();
        if (doc.exists) {
          final roadmapData = doc.data()?['roadmapData'];
          if (roadmapData != null) {
            final firebaseTasks = Set<String>.from(roadmapData['completedTaskIds'] ?? []);
            // Only use Firebase data if it has more completed tasks
            if (firebaseTasks.length > _completedTaskIds.length) {
              _completedTaskIds = firebaseTasks;
              await _saveLocally();
              notifyListeners();
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading roadmap from Firestore: $e');
      }
    }
  }

  /// Save progress
  Future<void> _saveData() async {
    await _saveLocally();
    _syncToFirebase();
  }

  /// Save locally
  Future<void> _saveLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'completedTaskIds': _completedTaskIds.toList(),
    };
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  /// Sync to Firebase
  Future<void> _syncToFirebase() async {
    if (!_isLoggedIn) return;
    try {
      await _firestore.collection('users').doc(_userId).set({
        'roadmapData': {
          'completedTaskIds': _completedTaskIds.toList(),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncing roadmap to Firestore: $e');
    }
  }

  /// Get number of completed stages
  int getCompletedStagesCount() {
    return stages.where((s) => isStageCompleted(s.stageNumber)).length;
  }

  /// Get total completed tasks count
  int getCompletedTasksCount() => _completedTaskIds.length;

  /// Get total tasks count
  int getTotalTasksCount() => stages.fold(0, (sum, s) => sum + s.tasks.length);

  /// Get unlocked stages count
  int getUnlockedStagesCount() {
    return stages.where((s) => isStageUnlocked(s.stageNumber)).length;
  }

  /// Get days remaining until next locked stage
  int getDaysToNextStage() {
    for (final stage in stages) {
      if (!isStageUnlocked(stage.stageNumber)) {
        return stage.requiredDays - _currentRecoveryDays;
      }
    }
    return 0; // all stages unlocked
  }

  /// Get next locked stage (null if all unlocked)
  RecoveryStage? getNextLockedStage() {
    for (final stage in stages) {
      if (!isStageUnlocked(stage.stageNumber)) {
        return stage;
      }
    }
    return null;
  }

  /// Motivational quotes per stage
  static const List<Map<String, String>> stageQuotes = [
    {'ar': 'كل رحلة ألف ميل تبدأ بخطوة واحدة', 'ku': 'هەر ڕێگایەکی هەزار میل بە تاک هەنگاوێک دەست پێ دەکات', 'en': 'Every journey of a thousand miles begins with a single step'},
    {'ar': 'الألم المؤقت أفضل من الندم الدائم', 'ku': 'ئازاری کاتی باشترە لە پەشیمانی هەمیشەیی', 'en': 'Temporary pain is better than permanent regret'},
    {'ar': 'أنت لست ماضيك، أنت مستقبلك', 'ku': 'تۆ ڕابردووت نیت، تۆ داهاتووتیت', 'en': 'You are not your past, you are your future'},
    {'ar': 'القوة لا تأتي من القدرة، بل من الإرادة', 'ku': 'هێز لە توانایەوە نایەت، بەڵکو لە ئیرادەیەوە دێت', 'en': 'Strength doesn\'t come from ability, but from willpower'},
    {'ar': 'اعرف نفسك، تعرف طريقك', 'ku': 'خۆت بناسە، ڕێگاکەت دەناسیت', 'en': 'Know yourself, know your path'},
    {'ar': 'النجاح عادة يومية وليس حدثاً واحداً', 'ku': 'سەرکەوتن ڕاهێنانێکی ڕۆژانەیە نەک ڕووداوێک', 'en': 'Success is a daily habit, not a single event'},
    {'ar': 'الفراشة لا ترى جمال أجنحتها، لكن الجميع يراها', 'ku': 'پەپوولە جوانی باڵەکانی نابینێت، بەڵام هەمووان دەیبینن', 'en': 'A butterfly can\'t see its own wings, but everyone else can'},
    {'ar': 'لا تخف من البطء، خف من الوقوف', 'ku': 'لە هێواشی مەترسە، لە وەستان بترسە', 'en': 'Don\'t fear slowness, fear standing still'},
    {'ar': 'الحرية ليست مجانية، لكنها تستحق كل ثمن', 'ku': 'ئازادی بەخۆڕایی نییە، بەڵام شایەنی هەموو بەهایەکە', 'en': 'Freedom isn\'t free, but it\'s worth every price'},
    {'ar': 'أنت الآن مصدر إلهام لغيرك', 'ku': 'تۆ ئێستا سەرچاوەی هاندانیت بۆ کەسانی تر', 'en': 'You are now a source of inspiration for others'},
  ];

  /// Get motivational quote for a stage
  String getStageQuote(int stageNumber, String lang) {
    final index = (stageNumber - 1).clamp(0, stageQuotes.length - 1);
    return stageQuotes[index][lang] ?? stageQuotes[index]['en']!;
  }

  /// Badge data per stage
  static const List<Map<String, dynamic>> stageBadges = [
    {'emoji': '🌱', 'ar': 'بذرة التغيير', 'ku': 'تۆوی گۆڕانکاری', 'en': 'Seed of Change'},
    {'emoji': '🧼', 'ar': 'المُطَهِّر', 'ku': 'پاککەرەوە', 'en': 'The Cleanser'},
    {'emoji': '🧱', 'ar': 'بانِي الأساس', 'ku': 'بنەماساز', 'en': 'Foundation Builder'},
    {'emoji': '🛡️', 'ar': 'الصامِد', 'ku': 'بەرگر', 'en': 'The Resilient'},
    {'emoji': '🔍', 'ar': 'مُكتَشِف الذات', 'ku': 'دۆزەری خۆ', 'en': 'Self-Explorer'},
    {'emoji': '💪', 'ar': 'القوي', 'ku': 'بەهێز', 'en': 'The Strong'},
    {'emoji': '🦋', 'ar': 'المُتَحَوِّل', 'ku': 'گۆڕاو', 'en': 'The Transformed'},
    {'emoji': '🏆', 'ar': 'المُتقِن', 'ku': 'شارەزا', 'en': 'The Master'},
    {'emoji': '🕊️', 'ar': 'الحُر', 'ku': 'ئازاد', 'en': 'The Free'},
    {'emoji': '🌟', 'ar': 'المُلهِم', 'ku': 'هاندەر', 'en': 'The Inspirer'},
  ];

  /// Get badge name for a stage
  String getBadgeName(int stageNumber, String lang) {
    final index = (stageNumber - 1).clamp(0, stageBadges.length - 1);
    return stageBadges[index][lang] ?? stageBadges[index]['en']!;
  }

  /// Get badge emoji for a stage
  String getBadgeEmoji(int stageNumber) {
    final index = (stageNumber - 1).clamp(0, stageBadges.length - 1);
    return stageBadges[index]['emoji']!;
  }
}
