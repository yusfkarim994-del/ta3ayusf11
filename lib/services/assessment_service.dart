import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Assessment question model
class AssessmentQuestion {
  final String id;
  final String textAr;
  final String textKu;
  final String textEn;
  final List<AssessmentOption> options;
  final String category; // frequency, control, impact, behavior

  const AssessmentQuestion({
    required this.id,
    required this.textAr,
    required this.textKu,
    required this.textEn,
    required this.options,
    this.category = 'general',
  });
}

/// Option for each question
class AssessmentOption {
  final String textAr;
  final String textKu;
  final String textEn;
  final int score; // 0-6 points (corresponds to levels 1-7)

  const AssessmentOption({
    required this.textAr,
    required this.textKu,
    required this.textEn,
    required this.score,
  });
}

/// Assessment result model
class AssessmentResult {
  final DateTime date;
  final int totalScore;
  final int maxScore;
  final int level; // 1-7
  final Map<String, int> answers;

  AssessmentResult({
    required this.date,
    required this.totalScore,
    required this.maxScore,
    required this.level,
    required this.answers,
  });

  double get percentage => (totalScore / maxScore) * 100;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'totalScore': totalScore,
    'maxScore': maxScore,
    'level': level,
    'answers': answers,
  };

  factory AssessmentResult.fromJson(Map<String, dynamic> json) => AssessmentResult(
    date: DateTime.parse(json['date']),
    totalScore: json['totalScore'],
    maxScore: json['maxScore'],
    level: json['level'],
    answers: Map<String, int>.from(json['answers']),
  );
}

/// Addiction Level Model based on واعي app
class AddictionLevel {
  final int level;
  final String nameAr;
  final String nameKu;
  final String nameEn;
  final String descriptionAr;
  final String descriptionKu;
  final String descriptionEn;
  final Color color;
  final IconData icon;

  const AddictionLevel({
    required this.level,
    required this.nameAr,
    required this.nameKu,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionKu,
    required this.descriptionEn,
    required this.color,
    required this.icon,
  });
}

/// Service for managing addiction assessments based on 7 levels
class AssessmentService extends ChangeNotifier {
  List<AssessmentResult> _results = [];
  Map<String, int> _currentAnswers = {};

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<AssessmentResult> get results => _results;
  Map<String, int> get currentAnswers => _currentAnswers;

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Check if user is logged in (not anonymous)
  bool get _isLoggedIn {
    final user = _auth.currentUser;
    return user != null && !user.isAnonymous;
  }

  /// Get Firestore collection for current user
  CollectionReference? get _collection {
    final uid = _userId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('assessment_results');
  }

  /// 7 Addiction Levels based on واعي app
  static const List<AddictionLevel> levels = [
    AddictionLevel(
      level: 1,
      nameAr: 'المستوى الأول - التعرض الأولي',
      nameKu: 'ئاستی یەکەم - تووشبوونی سەرەتایی',
      nameEn: 'Level 1 - Initial Exposure',
      descriptionAr: 'تعرضت للإباحية منذ فترة قصيرة أو تشاهدها مرة أو مرتين في العام. الأفكار والأعمال ليست مركزة على الإباحية.',
      descriptionKu: 'لە ماوەیەکی کەمدا تووشی ئیباحیەت بوویت یان ساڵانە یەک-دوو جار تەماشای دەکەیت. بیرکردنەوە و کارەکان لەسەر ئیباحیەت ناکۆکلبێتەوە.',
      descriptionEn: 'Recently exposed or watch once or twice a year. Thoughts and actions are not focused on pornography.',
      color: Color(0xFF4CAF50),
      icon: Icons.sentiment_very_satisfied,
    ),
    AddictionLevel(
      level: 2,
      nameAr: 'المستوى الثاني - التعرض المتكرر',
      nameKu: 'ئاستی دووەم - تووشبوونی دووبارە',
      nameEn: 'Level 2 - Repeated Exposure',
      descriptionAr: 'تشاهد عدة مرات لا تزيد عن ست مرات في العام. الإباحية لا تسيطر على التفكير اليومي. التخيلات قليلة.',
      descriptionKu: 'ساڵانە تا شەش جار تەماشا دەکەیت. ئیباحیەت کاریگەری لەسەر بیرکردنەوەی ڕۆژانە نییە. خەیاڵکردن کەمە.',
      descriptionEn: 'Watch up to six times a year. Pornography does not control daily thinking. Fantasies are minimal.',
      color: Color(0xFF8BC34A),
      icon: Icons.sentiment_satisfied,
    ),
    AddictionLevel(
      level: 3,
      nameAr: 'المستوى الثالث - على الحدود',
      nameKu: 'ئاستی سێیەم - لەسەر سنوور',
      nameEn: 'Level 3 - On the Edge',
      descriptionAr: 'تشاهد مرة واحدة في الشهر. أنت على الحدود بين مشكلة متفاقمة وسلوك إدماني. التخيل جزء من الصراع. بداية ظهور الأعراض الانسحابية.',
      descriptionKu: 'مانگانە یەک جار تەماشا دەکەیت. لە نێوان کێشەی زیاتربوو و ڕەفتاری ئیدمانیدایت. خەیاڵکردن بەشێکە لە تێکۆشان. نیشانەکانی کشانەوە دەستی پێکردووە.',
      descriptionEn: 'Watch once a month. On the border between a growing problem and addictive behavior. Fantasy is part of the struggle. Withdrawal symptoms begin.',
      color: Color(0xFFFFEB3B),
      icon: Icons.sentiment_neutral,
    ),
    AddictionLevel(
      level: 4,
      nameAr: 'المستوى الرابع - بداية المشكلة',
      nameKu: 'ئاستی چوارەم - دەستپێکی کێشە',
      nameEn: 'Level 4 - Problem Beginning',
      descriptionAr: 'تشاهد بضع مرات كل شهر أو أسبوع. التفكير بدأ يسيطر. تؤثر على العلاقات والتركيز. تشاهد محتوى أكثر انحرافاً. زيادة الأعراض الانسحابية.',
      descriptionKu: 'مانگانە یان هەفتانە چەند جار تەماشا دەکەیت. بیرکردنەوە دەستی بە کۆنتڕۆڵکردن کردووە. کاریگەری لەسەر پەیوەندییەکان و تەرکیز هەیە. ناوەڕۆکی لادانتر تەماشا دەکەیت.',
      descriptionEn: 'Watch several times a month or week. Thinking starts to take control. Affects relationships and focus. Watch more deviant content. Withdrawal symptoms increase.',
      color: Color(0xFFFF9800),
      icon: Icons.sentiment_dissatisfied,
    ),
    AddictionLevel(
      level: 5,
      nameAr: 'المستوى الخامس - بداية الإدمان',
      nameKu: 'ئاستی پێنجەم - دەستپێکی ئیدمان',
      nameEn: 'Level 5 - Addiction Begins',
      descriptionAr: 'تشاهد 3-5 مرات أسبوعياً. الإباحية من أهم 7 أمور تفكر بها يومياً. بداية الشعور بالضياع والعجز. تفقد أي نضال أو رغبة في التوقف.',
      descriptionKu: 'هەفتانە ٣-٥ جار تەماشا دەکەیت. ئیباحیەت لە ٧ شتە گرنگەکانی بیرکردنەوەی ڕۆژانەتە. هەستی لەدەستچوون و ناتوانی دەستی پێکردووە. هەموو تێکۆشانێک بۆ وەستان لەدەست دەدەیت.',
      descriptionEn: 'Watch 3-5 times weekly. Pornography is among the top 7 things you think about daily. Beginning to feel lost and helpless. Losing any struggle or desire to stop.',
      color: Color(0xFF0F766E),
      icon: Icons.sentiment_very_dissatisfied,
    ),
    AddictionLevel(
      level: 6,
      nameAr: 'المستوى السادس - إدمان اضطراري',
      nameKu: 'ئاستی شەشەم - ئیدمانی ناچاری',
      nameEn: 'Level 6 - Compulsive Addiction',
      descriptionAr: 'الأيام التي لا تشاهد فيها نادرة. إدمان اضطراري وفقدان للسيطرة. تكذب لتخفي سلوكك. شعور باليأس. تفقد وظيفتك أو علاقاتك أو إيمانك.',
      descriptionKu: 'ئەو ڕۆژانەی تەماشا ناکەیت کەمن. ئیدمانی ناچاری و لەدەستدانی کۆنتڕۆڵ. درۆ دەکەیت بۆ شاردنەوەی ڕەفتارەکەت. هەستی نائومێدی. کارەکەت یان پەیوەندییەکان یان باوەڕەکەت لەدەست دەدەیت.',
      descriptionEn: 'Days without watching are rare. Compulsive addiction and loss of control. You lie to hide your behavior. Feeling hopeless. Losing your job, relationships, or faith.',
      color: Color(0xFFF44336),
      icon: Icons.mood_bad,
    ),
    AddictionLevel(
      level: 7,
      nameAr: 'المستوى السابع - إدمان كامل',
      nameKu: 'ئاستی حەوتەم - ئیدمانی تەواو',
      nameEn: 'Level 7 - Full Addiction',
      descriptionAr: 'تشاهد يومياً. يومك مليء بالبحث والمشاهدة. لا تقوم بأي عمل سوى التخيل. تضع نفسك في مناطق خطرة. الكذب سلوك دائم. يأس وعجز تام. مستحيل السيطرة على نفسك.',
      descriptionKu: 'ڕۆژانە تەماشا دەکەیت. ڕۆژەکەت پڕە لە گەڕان و تەماشاکردن. هیچ کارێکی تر ناکەیت جگە لە خەیاڵکردن. خۆت دەخەیتە ناوچە مەترسیدارەکان. درۆکردن شێوازی بەردەوامە. نائومێدی و ناتوانی تەواو. کۆنتڕۆڵکردنی خۆت نەمانە.',
      descriptionEn: 'Watch daily. Your day is full of searching and watching. You do nothing but fantasize. You put yourself in dangerous situations. Lying is constant. Complete despair and helplessness. Impossible to control yourself.',
      color: Color(0xFF9C27B0),
      icon: Icons.warning_rounded,
    ),
  ];

  /// Frequency options for viewing questions
  static const List<AssessmentOption> frequencyOptions = [
    AssessmentOption(textAr: 'مرة أو مرتين في السنة', textKu: 'ساڵانە یەک-دوو جار', textEn: 'Once or twice a year', score: 0),
    AssessmentOption(textAr: 'عدة مرات في السنة (1-6)', textKu: 'ساڵانە چەند جار (١-٦)', textEn: 'Several times a year (1-6)', score: 1),
    AssessmentOption(textAr: 'مرة في الشهر', textKu: 'مانگانە یەک جار', textEn: 'Once a month', score: 2),
    AssessmentOption(textAr: 'عدة مرات في الشهر', textKu: 'مانگانە چەند جار', textEn: 'Several times a month', score: 3),
    AssessmentOption(textAr: '3-5 مرات أسبوعياً', textKu: 'هەفتانە ٣-٥ جار', textEn: '3-5 times weekly', score: 4),
    AssessmentOption(textAr: 'تقريباً يومياً', textKu: 'تەقریبەن ڕۆژانە', textEn: 'Almost daily', score: 5),
    AssessmentOption(textAr: 'يومياً أو أكثر', textKu: 'ڕۆژانە یان زیاتر', textEn: 'Daily or more', score: 6),
  ];

  /// Agreement scale options
  static const List<AssessmentOption> agreementOptions = [
    AssessmentOption(textAr: 'لا أوافق تماماً', textKu: 'تەواو ڕازی نیم', textEn: 'Strongly disagree', score: 0),
    AssessmentOption(textAr: 'لا أوافق', textKu: 'ڕازی نیم', textEn: 'Disagree', score: 1),
    AssessmentOption(textAr: 'لا أوافق قليلاً', textKu: 'کەمێک ڕازی نیم', textEn: 'Slightly disagree', score: 2),
    AssessmentOption(textAr: 'محايد', textKu: 'بێلایەن', textEn: 'Neutral', score: 3),
    AssessmentOption(textAr: 'أوافق قليلاً', textKu: 'کەمێک ڕازیم', textEn: 'Slightly agree', score: 4),
    AssessmentOption(textAr: 'أوافق', textKu: 'ڕازیم', textEn: 'Agree', score: 5),
    AssessmentOption(textAr: 'أوافق تماماً', textKu: 'تەواو ڕازیم', textEn: 'Strongly agree', score: 6),
  ];

  /// Yes/No/Sometimes options
  static const List<AssessmentOption> yesNoOptions = [
    AssessmentOption(textAr: 'لا أبداً', textKu: 'هەرگیز نا', textEn: 'Never', score: 0),
    AssessmentOption(textAr: 'نادراً', textKu: 'بە کەم', textEn: 'Rarely', score: 1),
    AssessmentOption(textAr: 'أحياناً', textKu: 'هەندێک جار', textEn: 'Sometimes', score: 3),
    AssessmentOption(textAr: 'غالباً', textKu: 'زۆرجار', textEn: 'Often', score: 5),
    AssessmentOption(textAr: 'دائماً', textKu: 'هەمیشە', textEn: 'Always', score: 6),
  ];

  /// 21 Assessment questions based on 7 levels criteria
  static const List<AssessmentQuestion> questions = [
    // === Frequency Questions (كم مرة - How often) ===
    AssessmentQuestion(
      id: 'q1',
      textAr: 'كم مرة تشاهد المحتوى الإباحي؟',
      textKu: 'چەند جار ناوەڕۆکی ئیباحی تەماشا دەکەیت؟',
      textEn: 'How often do you watch pornographic content?',
      options: frequencyOptions,
      category: 'frequency',
    ),
    AssessmentQuestion(
      id: 'q2',
      textAr: 'كم من الوقت تقضيه في كل جلسة مشاهدة؟',
      textKu: 'لە هەر جلسەیەکدا چەند کات بەسەر دەبەیت؟',
      textEn: 'How much time do you spend in each viewing session?',
      options: [
        AssessmentOption(textAr: 'دقائق قليلة', textKu: 'چەند خولەکێک', textEn: 'A few minutes', score: 0),
        AssessmentOption(textAr: '10-20 دقيقة', textKu: '١٠-٢٠ خولەک', textEn: '10-20 minutes', score: 1),
        AssessmentOption(textAr: '30 دقيقة', textKu: '٣٠ خولەک', textEn: '30 minutes', score: 2),
        AssessmentOption(textAr: 'ساعة', textKu: 'کاتژمێرێک', textEn: 'One hour', score: 3),
        AssessmentOption(textAr: '1-2 ساعة', textKu: '١-٢ کاتژمێر', textEn: '1-2 hours', score: 4),
        AssessmentOption(textAr: 'عدة ساعات', textKu: 'چەند کاتژمێرێک', textEn: 'Several hours', score: 5),
        AssessmentOption(textAr: 'معظم اليوم', textKu: 'زۆرینەی ڕۆژ', textEn: 'Most of the day', score: 6),
      ],
      category: 'frequency',
    ),
    AssessmentQuestion(
      id: 'q3',
      textAr: 'كم مرة تفكر في الإباحية خلال اليوم؟',
      textKu: 'ڕۆژانە چەند جار بیر لە ئیباحیەت دەکەیتەوە؟',
      textEn: 'How often do you think about pornography during the day?',
      options: yesNoOptions,
      category: 'frequency',
    ),

    // === Control Questions (السيطرة - Control) ===
    AssessmentQuestion(
      id: 'q4',
      textAr: 'هل حاولت التوقف عن المشاهدة ولم تستطع؟',
      textKu: 'ئایا هەوڵت داوە وەستان و نەتتوانیوە؟',
      textEn: 'Have you tried to stop watching and couldn\'t?',
      options: yesNoOptions,
      category: 'control',
    ),
    AssessmentQuestion(
      id: 'q5',
      textAr: 'هل تشعر أنك فقدت السيطرة على هذا السلوك؟',
      textKu: 'ئایا هەست دەکەیت کۆنتڕۆڵت لەسەر ئەم ڕەفتارە لەدەستداوە؟',
      textEn: 'Do you feel you have lost control over this behavior?',
      options: agreementOptions,
      category: 'control',
    ),
    AssessmentQuestion(
      id: 'q6',
      textAr: 'هل تحتاج لمحتوى أكثر إثارة أو انحرافاً للحصول على نفس الشعور؟',
      textKu: 'ئایا پێویستیت بە ناوەڕۆکی توندتر هەیە بۆ هەمان هەست؟',
      textEn: 'Do you need more extreme content to get the same feeling?',
      options: agreementOptions,
      category: 'control',
    ),
    AssessmentQuestion(
      id: 'q7',
      textAr: 'هل تشاهد أنواعاً من المحتوى لم تكن تتخيل أنك ستشاهدها؟',
      textKu: 'ئایا جۆری ناوەڕۆک تەماشا دەکەیت کە پێشتر وات نەدەزانی تەماشای دەکەیت؟',
      textEn: 'Do you watch types of content you never thought you would watch?',
      options: yesNoOptions,
      category: 'control',
    ),

    // === Impact on Life (التأثير على الحياة) ===
    AssessmentQuestion(
      id: 'q8',
      textAr: 'هل تؤثر الإباحية على عملك أو دراستك؟',
      textKu: 'ئایا ئیباحیەت کاریگەری لەسەر کار یان خوێندنەکەت هەیە؟',
      textEn: 'Does pornography affect your work or studies?',
      options: agreementOptions,
      category: 'impact',
    ),
    AssessmentQuestion(
      id: 'q9',
      textAr: 'هل أثرت الإباحية على علاقاتك الاجتماعية أو العائلية؟',
      textKu: 'ئایا ئیباحیەت کاریگەری لەسەر پەیوەندییە کۆمەڵایەتی یان خێزانییەکانت هەیە؟',
      textEn: 'Has pornography affected your social or family relationships?',
      options: agreementOptions,
      category: 'impact',
    ),
    AssessmentQuestion(
      id: 'q10',
      textAr: 'هل تفضل المشاهدة على النشاطات الأخرى التي كنت تستمتع بها؟',
      textKu: 'ئایا تەماشاکردن لە چالاکییەکانی تر کە حەزت لێ بوو باشترە بۆت؟',
      textEn: 'Do you prefer watching over other activities you used to enjoy?',
      options: agreementOptions,
      category: 'impact',
    ),
    AssessmentQuestion(
      id: 'q11',
      textAr: 'هل أثرت الإباحية على صحتك الجسدية (نوم، تعب)؟',
      textKu: 'ئایا ئیباحیەت کاریگەری لەسەر تەندروستی جەستەییت هەیە (خەو، ماندوێتی)؟',
      textEn: 'Has pornography affected your physical health (sleep, fatigue)?',
      options: agreementOptions,
      category: 'impact',
    ),
    AssessmentQuestion(
      id: 'q12',
      textAr: 'هل أنفقت أموالاً على المحتوى الإباحي؟',
      textKu: 'ئایا پارەت خەرجکردووە بۆ ناوەڕۆکی ئیباحی؟',
      textEn: 'Have you spent money on pornographic content?',
      options: yesNoOptions,
      category: 'impact',
    ),

    // === Psychological Impact (التأثير النفسي) ===
    AssessmentQuestion(
      id: 'q13',
      textAr: 'هل تشعر بالذنب أو الخجل بعد المشاهدة؟',
      textKu: 'ئایا هەست بە تاوان یان شەرم دەکەیت دوای تەماشاکردن؟',
      textEn: 'Do you feel guilty or ashamed after watching?',
      options: yesNoOptions,
      category: 'psychological',
    ),
    AssessmentQuestion(
      id: 'q14',
      textAr: 'هل تستخدم الإباحية للهروب من المشاكل أو المشاعر السلبية؟',
      textKu: 'ئایا ئیباحیەت بەکاردەهێنیت بۆ هەڵاتن لە کێشەکان یان هەستە نەرێنییەکان؟',
      textEn: 'Do you use pornography to escape problems or negative feelings?',
      options: agreementOptions,
      category: 'psychological',
    ),
    AssessmentQuestion(
      id: 'q15',
      textAr: 'هل تشعر بالضياع والعجز بسبب هذا السلوك؟',
      textKu: 'ئایا هەست بە لەدەستچوون و ناتوانی دەکەیت بەهۆی ئەم ڕەفتارە؟',
      textEn: 'Do you feel lost and helpless because of this behavior?',
      options: agreementOptions,
      category: 'psychological',
    ),
    AssessmentQuestion(
      id: 'q16',
      textAr: 'هل تشعر باليأس من إمكانية التوقف؟',
      textKu: 'ئایا هەست بە نائومێدی دەکەیت لە توانای وەستان؟',
      textEn: 'Do you feel hopeless about being able to stop?',
      options: agreementOptions,
      category: 'psychological',
    ),

    // === Withdrawal Symptoms (أعراض الانسحاب) ===
    AssessmentQuestion(
      id: 'q17',
      textAr: 'هل تشعر بالقلق أو التوتر عندما لا تستطيع المشاهدة؟',
      textKu: 'ئایا هەست بە نیگەرانی یان تەنشن دەکەیت کاتێک ناتوانیت تەماشا بکەیت؟',
      textEn: 'Do you feel anxious or stressed when you can\'t watch?',
      options: agreementOptions,
      category: 'withdrawal',
    ),
    AssessmentQuestion(
      id: 'q18',
      textAr: 'هل تجد صعوبة في التركيز على أي شيء آخر؟',
      textKu: 'ئایا سەختە بۆت تەرکیز بکەیت لەسەر شتی تر؟',
      textEn: 'Do you find it difficult to focus on anything else?',
      options: agreementOptions,
      category: 'withdrawal',
    ),

    // === Hiding Behavior (إخفاء السلوك) ===
    AssessmentQuestion(
      id: 'q19',
      textAr: 'هل تخفي هذه العادة عن الآخرين؟',
      textKu: 'ئایا ئەم ڕەوشتە لە کەسانی تر دەشاریتەوە؟',
      textEn: 'Do you hide this habit from others?',
      options: yesNoOptions,
      category: 'hiding',
    ),
    AssessmentQuestion(
      id: 'q20',
      textAr: 'هل تكذب لتخفي سلوكك أو وقتك المستهلك؟',
      textKu: 'ئایا درۆ دەکەیت بۆ شاردنەوەی ڕەفتارەکەت یان کاتەکەت؟',
      textEn: 'Do you lie to hide your behavior or the time you spend?',
      options: yesNoOptions,
      category: 'hiding',
    ),

    // === Dangerous Behavior (السلوك الخطر) ===
    AssessmentQuestion(
      id: 'q21',
      textAr: 'هل وضعت نفسك في مواقف خطرة بسبب هذا السلوك؟',
      textKu: 'ئایا خۆت خستووەتە ناو دۆخی مەترسیدار بەهۆی ئەم ڕەفتارە؟',
      textEn: 'Have you put yourself in dangerous situations because of this behavior?',
      options: yesNoOptions,
      category: 'danger',
    ),
  ];

  /// Load saved results from local storage, then sync from Firestore
  Future<void> loadResults() async {
    // 1. Load from local storage first (fast)
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = prefs.getStringList('assessment_results_v2') ?? [];
    _results = resultsJson
        .map((json) => AssessmentResult.fromJson(jsonDecode(json)))
        .toList();
    _results.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();

    // 2. Sync from Firestore in background (if logged in)
    if (_isLoggedIn && _collection != null) {
      try {
        final snapshot = await _collection!.get();
        if (snapshot.docs.isNotEmpty) {
          final firestoreResults = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return AssessmentResult.fromJson(data);
          }).toList();

          // If Firestore has more results, use Firestore data
          if (firestoreResults.length > _results.length) {
            _results = firestoreResults;
            _results.sort((a, b) => b.date.compareTo(a.date));
            await _saveLocally(); // Update local cache
            notifyListeners();
          } else if (_results.isNotEmpty && firestoreResults.isEmpty) {
            // Local has data but Firestore doesn't — push local to Firestore
            for (final result in _results) {
              _saveResultToFirestore(result);
            }
          }
        } else if (_results.isNotEmpty) {
          // Firestore empty but local has data — push to Firestore
          for (final result in _results) {
            _saveResultToFirestore(result);
          }
        }
      } catch (e) {
        debugPrint('Error syncing assessment results from Firestore: $e');
      }
    }
  }

  /// Save results to local storage only
  Future<void> _saveLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = _results.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList('assessment_results_v2', resultsJson);
  }

  /// Save results to both local and Firestore
  Future<void> _saveResults() async {
    await _saveLocally();
  }

  /// Save a single result to Firestore
  Future<void> _saveResultToFirestore(AssessmentResult result) async {
    if (!_isLoggedIn || _collection == null) return;
    try {
      final docId = result.date.millisecondsSinceEpoch.toString();
      await _collection!.doc(docId).set(result.toJson());
    } catch (e) {
      debugPrint('Error saving assessment result to Firestore: $e');
    }
  }

  /// Delete a result from Firestore
  Future<void> _deleteFromFirestore(AssessmentResult result) async {
    if (!_isLoggedIn || _collection == null) return;
    try {
      final docId = result.date.millisecondsSinceEpoch.toString();
      await _collection!.doc(docId).delete();
    } catch (e) {
      debugPrint('Error deleting assessment result from Firestore: $e');
    }
  }

  /// Save a single result (public method for screen to use)
  Future<void> saveResult(AssessmentResult result) async {
    _results.insert(0, result);
    await _saveResults();
    _saveResultToFirestore(result);
    notifyListeners();
  }

  /// Delete a result by index
  Future<void> deleteResult(int index) async {
    if (index >= 0 && index < _results.length) {
      final result = _results[index];
      _results.removeAt(index);
      await _saveResults();
      _deleteFromFirestore(result);
      notifyListeners();
    }
  }

  /// Set answer for a question
  void setAnswer(String questionId, int score) {
    _currentAnswers[questionId] = score;
    notifyListeners();
  }

  /// Reset current answers
  void resetCurrentAnswers() {
    _currentAnswers = {};
    notifyListeners();
  }

  /// Calculate addiction level (1-7) from total score
  int _calculateLevel(double percentage) {
    if (percentage <= 14) return 1;  // Minimal exposure
    if (percentage <= 28) return 2;  // Repeated exposure
    if (percentage <= 42) return 3;  // On the edge
    if (percentage <= 56) return 4;  // Problem beginning
    if (percentage <= 70) return 5;  // Addiction begins
    if (percentage <= 85) return 6;  // Compulsive addiction
    return 7;                        // Full addiction
  }

  /// Calculate and save assessment result
  Future<AssessmentResult> submitAssessment() async {
    int totalScore = 0;
    int maxScore = 0;
    
    for (final question in questions) {
      final maxOptionScore = question.options.map((o) => o.score).reduce((a, b) => a > b ? a : b);
      maxScore += maxOptionScore;
      final selectedIndex = _currentAnswers[question.id];
      if (selectedIndex != null && selectedIndex < question.options.length) {
        totalScore += question.options[selectedIndex].score;
      }
    }

    final percentage = (totalScore / maxScore) * 100;
    final level = _calculateLevel(percentage);

    final result = AssessmentResult(
      date: DateTime.now(),
      totalScore: totalScore,
      maxScore: maxScore,
      level: level,
      answers: Map.from(_currentAnswers),
    );

    _results.insert(0, result);
    await _saveResults();
    _saveResultToFirestore(result);
    resetCurrentAnswers();
    notifyListeners();
    
    return result;
  }

  /// Get the latest result
  AssessmentResult? get latestResult => _results.isNotEmpty ? _results.first : null;

  /// Get level info by level number
  AddictionLevel getLevelInfo(int level) {
    return levels.firstWhere((l) => l.level == level, orElse: () => levels.first);
  }

  /// Get level name by language
  String getLevelName(int level, String language) {
    final levelInfo = getLevelInfo(level);
    if (language == 'ar') return levelInfo.nameAr;
    if (language == 'ku') return levelInfo.nameKu;
    return levelInfo.nameEn;
  }

  /// Get level description by language
  String getLevelDescription(int level, String language) {
    final levelInfo = getLevelInfo(level);
    if (language == 'ar') return levelInfo.descriptionAr;
    if (language == 'ku') return levelInfo.descriptionKu;
    return levelInfo.descriptionEn;
  }

  /// Get level color
  Color getLevelColor(int level) {
    return getLevelInfo(level).color;
  }

  /// Get level icon
  IconData getLevelIcon(int level) {
    return getLevelInfo(level).icon;
  }

  /// Get recommendation based on level
  String getRecommendation(int level, String language) {
    if (level <= 2) {
      if (language == 'ar') return 'أنت في مرحلة مبكرة. بادر بالتغيير الآن قبل أن يتفاقم الأمر. استخدم التطبيق بانتظام.';
      if (language == 'ku') return 'تۆ لە قۆناغی سەرەتادایت. ئێستا دەستبکە بە گۆڕانکاری پێش ئەوەی بارەکە خراپتر ببێت. ئەپەکە بە بەردەوامی بەکاربهێنە.';
      return 'You are in an early stage. Start changing now before it gets worse. Use the app regularly.';
    } else if (level <= 4) {
      if (language == 'ar') return 'أنت على حدود الإدمان. تحتاج التزاماً جاداً. ابحث عن شريك محاسبة واستخدم جميع أدوات التطبيق.';
      if (language == 'ku') return 'لەسەر سنووری ئیدمانیت. پێویستیت بە پابەندبوونی جدییە. بەدوای هاوڕێی بەرپرسیاریەتیدا بگەڕێ و هەموو ئامڕازەکانی ئەپەکە بەکاربهێنە.';
      return 'You are on the edge of addiction. You need serious commitment. Find an accountability partner and use all app tools.';
    } else if (level <= 6) {
      if (language == 'ar') return 'أنت في مرحلة إدمان. ننصحك بشدة بالتواصل مع متخصص بالإضافة لاستخدام التطبيق وشريك محاسبة.';
      if (language == 'ku') return 'لە قۆناغی ئیدمانیت. بە توندی ئامۆژگاریت دەکەین پەیوەندی بە پسپۆڕێک بکەیت لەگەڵ بەکارهێنانی ئەپەکە و هاوڕێی بەرپرسیاریەتی.';
      return 'You are in an addiction stage. We strongly recommend contacting a specialist in addition to using the app and an accountability partner.';
    } else {
      if (language == 'ar') return 'حالتك تحتاج تدخلاً متخصصاً عاجلاً. الرجاء التواصل مع معالج أو مستشار فوراً. التعافي ممكن لكن تحتاج مساعدة احترافية.';
      if (language == 'ku') return 'دۆخەکەت پێویستی بە دەستتێوەردانی پسپۆڕانەی پەلە هەیە. تکایە فەوری پەیوەندی بە چارەسەر یان ڕاوێژکارێک بکە. چاکبوونەوە دەکرێت بەڵام پێویستیت بە یارمەتی پیشەییە.';
      return 'Your condition needs urgent specialized intervention. Please contact a therapist or counselor immediately. Recovery is possible but you need professional help.';
    }
  }
}
