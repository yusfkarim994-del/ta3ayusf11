/// Daily Tasks for 90-Day Recovery/Challenge App
/// Each day has 3 unique tasks with progressive difficulty
/// Tasks cover: physical, mental, spiritual, social, discipline

List<Map<String, dynamic>> getDailyTasks(int day) {
  if (day < 1 || day > 90) return [];

  // Stage 1: Days 1-5 (Foundation)
  if (day >= 1 && day <= 5) {
    return _stage1(day);
  }
  // Stage 2: Days 6-10 (Building Habits)
  else if (day >= 6 && day <= 10) {
    return _stage2(day);
  }
  // Stage 3: Days 11-15 (Establishing Routines)
  else if (day >= 11 && day <= 15) {
    return _stage3(day);
  }
  // Stage 4: Days 16-20 (Mental Strength)
  else if (day >= 16 && day <= 20) {
    return _stage4(day);
  }
  // Stage 5: Days 21-25 (Social Connection)
  else if (day >= 21 && day <= 25) {
    return _stage5(day);
  }
  // Stage 6: Days 26-30 (Discipline Building)
  else if (day >= 26 && day <= 30) {
    return _stage6(day);
  }
  // Stage 7: Days 31-35 (Spiritual Deepening)
  else if (day >= 31 && day <= 35) {
    return _stage7(day);
  }
  // Stage 8: Days 36-40 (Physical Challenge)
  else if (day >= 36 && day <= 40) {
    return _stage8(day);
  }
  // Stage 9: Days 41-45 (Mental Resilience)
  else if (day >= 41 && day <= 45) {
    return _stage9(day);
  }
  // Stage 10: Days 46-50 (Social Leadership)
  else if (day >= 46 && day <= 50) {
    return _stage10(day);
  }
  // Stage 11: Days 51-55 (Advanced Discipline)
  else if (day >= 51 && day <= 55) {
    return _stage11(day);
  }
  // Stage 12: Days 56-60 (Spiritual Mastery)
  else if (day >= 56 && day <= 60) {
    return _stage12(day);
  }
  // Stage 13: Days 61-65 (Physical Excellence)
  else if (day >= 61 && day <= 65) {
    return _stage13(day);
  }
  // Stage 14: Days 66-70 (Mental Mastery)
  else if (day >= 66 && day <= 70) {
    return _stage14(day);
  }
  // Stage 15: Days 71-75 (Social Impact)
  else if (day >= 71 && day <= 75) {
    return _stage15(day);
  }
  // Stage 16: Days 76-80 (Discipline Mastery)
  else if (day >= 76 && day <= 80) {
    return _stage16(day);
  }
  // Stage 17: Days 81-85 (Integration)
  else if (day >= 81 && day <= 85) {
    return _stage17(day);
  }
  // Stage 18: Days 86-90 (Mastery & Completion)
  else if (day >= 86 && day <= 90) {
    return _stage18(day);
  }

  return [];
}

String getDailyBonus(int day) {
  final bonuses = [
    'اليوم الأول هو الأصعب، لكنه أيضاً الأهم. ابدأ بخطوة واحدة فقط.',
    'لا تقارن نفسك بالآخرين، قارن نفسك بنفسك من البارحة.',
    'الصبر مفتاح التغيير، لا تتسرع في النتائج.',
    'كل عادة جديدة تحتاج وقتاً لتتثبيت، كن صبوراً مع نفسك.',
    'النجاح ليس هدفاً واحداً، بل سلسلة من الخطوات الصغيرة.',
    'إذا سقطت اليوم، قم وابدأ من جديد. الفشل ليس النهاية.',
    'الصحة الجسدية والذهنية مترابطتان، اعتن بهما معاً.',
    'الشكر على ما لديك يفتح أبواباً جديدة للبركات.',
    'التأمل ليس عن الفراغ، بل عن التوازن الداخلي.',
    'التواصل مع الآخرين يقوّي الروح ويُقوّي الإرادة.',
    'النوم الجيد هو أساس الإنتاجية والصحة.',
    'لا تخف من التحديات، فهي تصنعك وتصنع شخصيتك.',
    'الإرادة مثل العضلة، كلما تدربت عليها ازدادت قوة.',
    'القراءة تُثري العقل وتوسّع الأفق.',
    'التخطيط للغد يمنحك سيطرة على وقتك.',
    'الرياضة ليست فقط للجسم، بل للعقل أيضاً.',
    'الاعتراف بالخطأ شجاعة، وليس ضعف.',
    'التنفس العميق يُهدّئ الأعصاب ويُحسّن التركيز.',
    'الابتسامة即使是 ابتسامة بسيطة يمكن أن تغيّر يومك.',
    'العيش في الحاضر هو أجمل هدية يمكنك tặngها لنفسك.',
    'ال GRATITUDE تحوّل النقد إلى إيجابية.',
    'التعلم المستمر هو سر النجاح في الحياة.',
    'لا تدع الخوف يمنعك من تجربة أشياء جديدة.',
    'ال صدق مع النفس هو الخطوة الأولى للتحوّل.',
    'الوقت الذي تستثمره في نفسك هو أفضل استثمار.',
    'القوة الحقيقية في الهدوء والتأمل.',
    'كل يوم هو فرصة جديدة للبداية.',
    'الثقة بالنفس تأتي من الأفعال، لا من الكلام.',
    'الصبر على النتائج هو سر النجاح.',
    'لا تبحث عن الكمال، ابحث عن التقدم.',
    'ال روتين اليومي هو أساس التحوّل.',
    'الكلمة الطيبة تُبني جسوراً بين الناس.',
    'الussة تأتي من داخلك، لا من الخارج.',
    'لا تدع الأمس يسرق فرحة اليوم.',
    'الإبداع يولد من التجربة والإقدام.',
    'القوة في الاتصال، لا في الانقطاع.',
    'ال تعلم من الماضي، لكن لا تعيش فيه.',
    'النجاح يكمن في الاستمرارية، لا في السرعة.',
    'ال تقبل نفسك كما أنت، ثم اعمل على التحسين.',
    'ال صدق في التعامل يبني الثقة.',
    'ال قوة الإرادة تنمو مع كل تحدٍ تتغلب عليه.',
    'ال حياة بدون هدف هي حياة بدون معنى.',
    'ال تعلم أن تقول لا عندما تحتاج.',
    'ال قبول هو البداية للتغيير.',
    'ال صديق حقيقي هو من يدعمك في الأوقات الصعبة.',
    'ال قوة في التواضع، لا في التكبر.',
    'ال حياة قصيرة جداً للندم.',
    'ال تعلم من أخطائك ولا تكررها.',
    'ال قبول للواقع هو الخطوة الأولى للتغيير.',
    'ال صبر على الغير يُنمّي الحب والمودة.',
    'ال قوة في الاعتراف بالحاجة للمساعدة.',
    'ال تعلم كيف تغفر لنفسك.',
    'ال حياة هي اختبار، والاختبارات تصنعك.',
    'ال قبول لل CHANGE هو بداية النمو.',
    'ال صديق يُعرف في الأوقات الصعبة.',
    'ال قوة في التفاؤل، لا في التشاؤم.',
    'ال حياة بدون تحدٍ هي حياة بدون نمو.',
    'ال تعلم أن تتقبل النقد البنّاء.',
    'ال قبول للذات هو أساس السعادة.',
    'ال صبر على النتائج هو سر النجاح.',
    'ال قوة في الإرادة، لا في القوة الجسدية فقط.',
    'ال حياة بدون معنى هي حياة فارغة.',
    'ال تعلم من الآخرين ولا تenvyهم.',
    'ال قبول للوضع الحالي هو البداية للتغيير.',
    'ال صبر على الآخرين ينمّي الحب.',
    'ال قوة في التواضع والتعلم.',
    'ال حياة هي رحلة، وليس وجهة.',
    'ال تعلم كيف تتعامل مع الضغط.',
    'ال قبول للنتائج هو جزء من النجاح.',
    'ال صبر على التغيير هو مفتاح التطور.',
    'ال قوة في الاتصال بالآخرين.',
    'ال حياة بدون تحدٍ هي حياة رتيبة.',
    'ال تعلم من الأخطاء ولا تخف منها.',
    'ال قبول للذات هو الخطوة الأولى للثقة.',
    'ال صبر على النتائج يجلب النجاح.',
    'ال قوة في التفاؤل وال信任.',
    'ال حياة بدون حب هي حياة ناقصة.',
    'ال تعلم كيف تتعامل مع الفشل.',
    'ال قبول للواقع هو أساس التقدم.',
    'ال صبر على الآخرين ينمّي الصداقة.',
    'ال قوة في الهدوء والحكمة.',
    'ال حياة هي اختبار صبر وإرادة.',
    'ال تعلم كيف تُقدّر ما لديك.',
    'ال قبول لل CHANGE هو بداية النمو.',
    'ال صبر على النتائج هو سر النجاح.',
    'ال قوة في الإرادة والعزيمة.',
    'ال حLife is a journey, not a destination.',
  ];

  if (day < 1 || day > 90) return '';
  return bonuses[day - 1];
}

// Stage 1: Days 1-5 (Foundation)
List<Map<String, dynamic>> _stage1(int day) {
  switch (day) {
    case 1:
      return [
        {
          'id': 'D1T1',
          'titleEn': 'Drink 8 glasses of water today',
          'titleAr': 'اشرب 8 أكواب من الماء اليوم',
          'titleKu': 'Îro 8 piyalên avê bêje',
          'descriptionEn': 'Start your journey with proper hydration. Keep a water bottle with you all day.',
          'descriptionAr': 'ابدأ رحلتك بالشرب الكافي. حافظ على زجاجة ماء معك طوال اليوم.',
          'descriptionKu': 'Destê te bi avê baş dest pêke. Piyalê avê li heq te binivîse.',
          'xpReward': 15,
          'type': 'physical'
        },
        {
          'id': 'D1T2',
          'titleEn': 'Write down 3 things you are grateful for',
          'titleAr': 'اكتب 3 أشياء أنت ممتن لها',
          'titleKu': '3 tişt ku hûn piştgînî û heye binivîse',
          'descriptionEn': 'Take 5 minutes to write 3 specific things you are grateful for today.',
          'descriptionAr': 'خذ 5 دقائق لكتابة 3 أشياء محددة أنت ممتن لها اليوم.',
          'descriptionKu': '5 xulekî bifîre û 3 tişt ku hûn piştgînî û heye binivîse.',
          'xpReward': 15,
          'type': 'spiritual'
        },
        {
          'id': 'D1T3',
          'titleEn': 'Take a 10-minute walk',
          'titleAr': 'take a 10-minute walk',
          'titleKu': '10 xulekî bipeyive',
          'descriptionEn': 'Walk for at least 10 minutes today, even if it is around your home.',
          'descriptionAr': 'امشي لمدة 10 دقائق على الأقل اليوم، حتى لو كان حول منزلك.',
          'descriptionKu': 'Di 10 xulekê de bipeyive, gehîn li derdora malê te be.',
          'xpReward': 15,
          'type': 'physical'
        }
      ];
    case 2:
      return [
        {
          'id': 'D2T1',
          'titleEn': 'Eat one healthy meal',
          'titleAr': 'تناول وجبة صحية واحدة',
          'titleKu': 'Taybetê bendewarê peqij bi xwe bixe',
          'descriptionEn': 'Prepare and eat one nutritious meal today. Focus on vegetables and protein.',
          'descriptionAr': 'حضّر وتناول وجبة غذائية صحية اليوم. ركّز على الخضروات والبروتين.',
          'descriptionKu': 'Taybetê bendewarê peqij bi xwe amadeke û bixwe. Li ser sabzî û protein fokus bike.',
          'xpReward': 20,
          'type': 'physical'
        },
        {
          'id': 'D2T2',
          'titleEn': 'Read for 15 minutes',
          'titleAr': 'اقرأ لمدة 15 دقيقة',
          'titleKu': '15 xulekî bi xwîne',
          'descriptionEn': 'Read a book for at least 15 minutes today. Choose something educational or inspiring.',
          'descriptionAr': 'اقرأ كتاباً لمدة 15 دقيقة على الأقل اليوم. اختر شيئاً تعليمياً أو ملهماً.',
          'descriptionKu': 'Di 15 xulekê de pirtûk bixwe. Tiştî amûrker an jî hilbilîkar hilbijêre.',
          'xpReward': 20,
          'type': 'mental'
        },
        {
          'id': 'D2T3',
          'titleEn': 'Clean one room in your house',
          'titleAr': 'نظّف غرفة واحدة في منزلك',
          'titleKu': 'Odagêkî di malê te de paqij bike',
          'descriptionEn': 'Choose one room and clean it thoroughly. A clean space helps a clear mind.',
          'descriptionAr': 'اختر غرفة ونظّفها جيداً. النظافة تساعد على وضوح الذهن.',
          'descriptionKu': 'Odagêkî hilbijêre û bi sîmîn paqij bike. Dîtinê paqij beşdîdar e.',
          'xpReward': 20,
          'type': 'discipline'
        }
      ];
    case 3:
      return [
        {
          'id': 'D3T1',
          'titleEn': 'Do 20 push-ups',
          'titleAr': 'افعل 20 تمرينة ضغط',
          'titleKu': '20 bendekirinê bike',
          'descriptionEn': 'Complete 20 push-ups. You can do them in sets of 5 if needed.',
          'descriptionAr': 'أكمل 20 تمرين ضغط. يمكنك القيام بها على 4 مجموعات من 5 إذا لزم الأمر.',
          'descriptionKu': '20 bendekirinê bi qencî bike. Hûn dikarin di 4 serbestî de bikin.',
          'xpReward': 25,
          'type': 'physical'
        },
        {
          'id': 'D3T2',
          'titleEn': 'Call a family member',
          'titleAr': 'اتصل بأحد أفراد عائلتك',
          'titleKu': 'Bi kesekî ji malbatê te re telefona bike',
          'descriptionEn': 'Call someone in your family and have a real conversation for at least 5 minutes.',
          'descriptionAr': 'اتصل بأحد أفراد عائلتك وتحدث معه لمدة 5 دقائق على الأقل.',
          'descriptionKu': 'Bi kesekî ji malbatê te re telefona bike û di 5 xulekê de axaftinê bikin.',
          'xpReward': 25,
          'type': 'social'
        },
        {
          'id': 'D3T3',
          'titleEn': 'Practice deep breathing for 5 minutes',
          'titleAr': 'مارس التنفس العميق لمدة 5 دقائق',
          'titleKu': '5 xulekî avêtinê giyan bikin',
          'descriptionEn': 'Sit quietly and take slow, deep breaths for 5 minutes. Focus on your breathing.',
          'descriptionAr': 'اجلس بهدوء وخذ أنفاساً بطيئة وعميقة لمدة 5 دقائق. ركّز على تنفسك.',
          'descriptionKu': 'Bi aramî binihîtin û di 5 xulekê de avêtinê slowly bike. Li avêtinê te fokus bike.',
          'xpReward': 25,
          'type': 'mental'
        }
      ];
    case 4:
      return [
        {
          'id': 'D4T1',
          'titleEn': 'Take a 20-minute walk',
          'titleAr': 'امشي لمدة 20 دقيقة',
          'titleKu': '20 xulekî bipeyive',
          'descriptionEn': 'Walk for 20 minutes today. Try to walk in a park or green area if possible.',
          'descriptionAr': 'امشي لمدة 20 دقيقة اليوم. حاول المشي في حديقة أو منطقة خضراء إذا أمكن.',
          'descriptionKu': 'Di 20 xulekê de bipeyive. Gelekî li park an jî qadêkî kesk bipeyive.',
          'xpReward': 30,
          'type': 'physical'
        },
        {
          'id': 'D4T2',
          'titleEn': 'Write a letter to yourself',
          'titleAr': 'اكتب رسالة لنفسك',
          'titleKu': 'Nivîsekî ji bo xwe bivîse',
          'descriptionEn': 'Write a letter to your future self about your goals and hopes for the next 90 days.',
          'descriptionAr': 'اكتب رسالة لذاتك المستقبلية حول أهدافك وآمالك لـ 90 يوماً القادمة.',
          'descriptionKu': 'Nivîsekî ji bo xwe ya piştî 90 rojên pêş ve bivîse.',
          'xpReward': 30,
          'type': 'mental'
        },
        {
          'id': 'D4T3',
          'titleEn': 'Practice gratitude meditation',
          'titleAr': 'مارس تأمل الشكر',
          'titleKu': 'Ragihandinê şukr bikin',
          'descriptionEn': 'Spend 10 minutes in quiet reflection, thinking about what you are thankful for.',
          'descriptionAr': 'اقضِ 10 دقائق في التأمل الهادئ، والتفكير فيما أنت ممتن له.',
          'descriptionKu': 'Di 10 xulekê de bi aramî bifîre, li ser tiştên ku hûn piştgînî û heye.',
          'xpReward': 30,
          'type': 'spiritual'
        }
      ];
    case 5:
      return [
        {
          'id': 'D5T1',
          'titleEn': 'Do 30 jumping jacks',
          'titleAr': 'افعل 30 قفزات',
          'titleKu': '30 sekêdanê bike',
          'descriptionEn': 'Complete 30 jumping jacks to boost your energy and mood.',
          'descriptionAr': 'أكمل 30 قفزات لتعزيز طاقتك ومزاجك.',
          'descriptionKu': '30 sekêdanê bi qencî bike bo bilindkirina enerjî û haleyê te.',
          'xpReward': 35,
          'type': 'physical'
        },
        {
          'id': 'D5T2',
          'titleEn': 'Cook a healthy meal from scratch',
          'titleAr': 'اطبخ وجبة صحية من الصفر',
          'titleKu': 'Taybetê bendewarê ji sêr ve bixwirine',
          'descriptionEn': 'Prepare a complete healthy meal without using processed or pre-made food.',
          'descriptionAr': 'حضّر وجبة صحية كاملة دون استخدام الأطعمة المعالجة أو المسبقة التحضير.',
          'descriptionKu': 'Taybetê bendewarê tam û bi serî bixwirine bêyî xwarinên pêş-destkirî.',
          'xpReward': 35,
          'type': 'discipline'
        },
        {
          'id': 'D5T3',
          'titleEn': 'Spend 15 minutes in nature',
          'titleAr': 'اقضِ 15 دقيقة في الطبيعة',
          'titleKu': '15 xulekî di nexşeyê de bi xwe bibe',
          'descriptionEn': 'Spend 15 minutes outside in nature, observing the environment around you.',
          'descriptionAr': 'اقضِ 15 دقيقة في الخارج في الطبيعة، مراقباً البيئة من حولك.',
          'descriptionKu': 'Di 15 xulekê de der çavê nexşeyê de bimîne û dîtinê binivîse.',
          'xpReward': 35,
          'type': 'spiritual'
        }
      ];
    default:
      return [];
  }
}

// Stage 2: Days 6-10 (Building Habits)
List<Map<String, dynamic>> _stage2(int day) {
  switch (day) {
    case 6:
      return [
        {
          'id': 'D6T1',
          'titleEn': 'Do 40 squats',
          'titleAr': 'افعل 40 تمرين squats',
          'titleKu': '40 zimanî bike',
          'descriptionEn': 'Complete 40 squats to build lower body strength.',
          'descriptionAr': 'أكمل 40 تمرين squat لبناء قوة الجسم السفلي.',
          'descriptionKu': '40 zimanî bi qencî bike bo binyana hêlê jêrîn.',
          'xpReward': 40,
          'type': 'physical'
        },
        {
          'id': 'D6T2',
          'titleEn': 'Read for 20 minutes',
          'titleAr': 'اقرأ لمدة 20 دقيقة',
          'titleKu': '20 xulekî bi xwîne',
          'descriptionEn': 'Read for 20 minutes. Try to finish a book chapter today.',
          'descriptionAr': 'اقرأ لمدة 20 دقيقة. حاول إنهاء فصل من الكتاب اليوم.',
          'descriptionKu': 'Di 20 xulekê de bixwe. Alîkareyê pirtûkê biqencî bike.',
          'xpReward': 40,
          'type': 'mental'
        },
        {
          'id': 'D6T3',
          'titleEn': 'Help someone with a task',
          'titleAr': 'ساعد شخصاً في مهمة',
          'titleKu': 'Kesekî di karekê de alîkariya bike',
          'descriptionEn': 'Offer to help someone with a task or chore today.',
          'descriptionAr': 'اعرض المساعدة على شخص في مهمة أو عمل منزلي اليوم.',
          'descriptionKu': 'Alîkariya kesekî di karekê an jî karê malê de pêşniyar bike.',
          'xpReward': 40,
          'type': 'social'
        }
      ];
    case 7:
      return [
        {
          'id': 'D7T1',
          'titleEn': 'Walk 30 minutes',
          'titleAr': 'امشي لمدة 30 دقيقة',
          'titleKu': '30 xulekî bipeyive',
          'descriptionEn': 'Walk for 30 minutes today. Try to increase your pace slightly.',
          'descriptionAr': 'امشي لمدة 30 دقيقة اليوم. حاول زيادة سرعتك قليلاً.',
          'descriptionKu': 'Di 30 xulekê de bipeyive. Hevediyariyê te kêm bike.',
          'xpReward': 45,
          'type': 'physical'
        },
        {
          'id': 'D7T2',
          'titleEn': 'Write down your goals for the week',
          'titleAr': 'اكتب أهدافك لأسبوعك',
          'titleKu': 'Armanca te ji bo heftayê te binivîse',
          'descriptionEn': 'Set 3 specific, achievable goals for the coming week.',
          'descriptionAr': 'حدد 3 أهداف محددة وقابلة للتحقيق للأسبوع القادم.',
          'descriptionKu': '3 armanca ku di heftayê pêş de têkildar bin û pêk bne binivîse.',
          'xpReward': 45,
          'type': 'mental'
        },
        {
          'id': 'D7T3',
          'titleEn': 'Practice a 10-minute prayer or meditation',
          'titleAr': 'مارس صلاة أو تأمل لمدة 10 دقائق',
          'titleKu': '10 xulekî namê an jî ragihandinê bikin',
          'descriptionEn': 'Spend 10 minutes in prayer, meditation, or quiet reflection.',
          'descriptionAr': 'اقضِ 10 دقائق في الصلاة أو التأمل أو التأمل الهادئ.',
          'descriptionKu': 'Di 10 xulekê de nam, ragihandin an jî biryarê bi aramî bikin.',
          'xpReward': 45,
          'type': 'spiritual'
        }
      ];
    case 8:
      return [
        {
          'id': 'D8T1',
          'titleEn': 'Do 50 sit-ups',
          'titleAr': 'افعل 50 تمرين جلوس',
          'titleKu': '50 nîv-niştinê bike',
          'descriptionEn': 'Complete 50 sit-ups to strengthen your core.',
          'descriptionAr': 'أكمل 50 تمرين جلوس لتقوية عضلات البطن.',
          'descriptionKu': '50 nîv-niştinê bi qencî bike bo hêla nixanî te.',
          'xpReward': 50,
          'type': 'physical'
        },
        {
          'id': 'D8T2',
          'titleEn': 'Organize your workspace',
          'titleAr': 'نظّف مكان عملك',
          'titleKu': 'Cihê karekê te paqij bike',
          'descriptionEn': 'Clean and organize your desk or workspace completely.',
          'descriptionAr': 'نظّف ورتّب مكتبك أو مكان عملك بالكامل.',
          'descriptionKu': 'Mêse an jî cihê karekê te bi temamî paqij bike.',
          'xpReward': 50,
          'type': 'discipline'
        },
        {
          'id': 'D8T3',
          'titleEn': 'Give a genuine compliment to someone',
          'titleAr': 'امدح شخصاً بصدق',
          'titleKu': 'Kesekî bi rastî bêje',
          'descriptionEn': 'Give a specific, genuine compliment to someone today.',
          'descriptionAr': 'امدح شخصاً بشكل محدد وصادق اليوم.',
          'descriptionKu': 'Kesekî bi taybetî û bi rastî bêje.',
          'xpReward': 50,
          'type': 'social'
        }
      ];
    case 9:
      return [
        {
          'id': 'D9T1',
          'titleEn': 'Run for 15 minutes',
          'titleAr': 'اركض لمدة 15 دقيقة',
          'titleKu': '15 xulekî berbiçîne',
          'descriptionEn': 'Run or jog for 15 minutes. Start slow and increase pace gradually.',
          'descriptionAr': 'اركض أو اهرول لمدة 15 دقيقة. ابدأ ببطء وزِد السرعة تدريجياً.',
          'descriptionKu': 'Di 15 xulekê de berbiçîne. Bi hêdî dest pêke û hevediyariyê bi hêdî bilind bike.',
          'xpReward': 55,
          'type': 'physical'
        },
        {
          'id': 'D9T2',
          'titleEn': 'Learn something new for 20 minutes',
          'titleAr': 'تعلم شيئاً جديداً لمدة 20 دقيقة',
          'titleKu': '20 xulekî tiştî nû bikîrz',
          'descriptionEn': 'Spend 20 minutes learning a new skill or topic that interests you.',
          'descriptionAr': 'اقضِ 20 دقيقة في تعلم مهارة أو موضوع جديد يثير اهتمامك.',
          'descriptionKu': 'Di 20 xulekê de hînarekî nû an jî konsernekî nû bikîre ku hûn li ser wêInterest.',
          'xpReward': 55,
          'type': 'mental'
        },
        {
          'id': 'D9T3',
          'titleEn': 'Volunteer for a small task',
          'titleAr': 'تطوع في مهمة صغيرة',
          'titleKu': 'Di karekêkî piçûk de serbest',
          'descriptionEn': 'Volunteer to help with a small task or errand for someone.',
          'descriptionAr': 'تطوع للمساعدة في مهمة أو مهمة صغيرة لشخص ما.',
          'descriptionKu': 'Di karekêkî piçûk an jî serbestî de alîkariya kesekî bike.',
          'xpReward': 55,
          'type': 'social'
        }
      ];
    case 10:
      return [
        {
          'id': 'D10T1',
          'titleEn': 'Do a 20-minute yoga session',
          'titleAr': 'مارس اليوغا لمدة 20 دقيقة',
          'titleKu': '20 xulekî yoga bikin',
          'descriptionEn': 'Follow a 20-minute yoga routine online or from memory.',
          'descriptionAr': 'اتبع روتين يوغا لمدة 20 دقيقة عبر الإنترنت أو من الذاكرة.',
          'descriptionKu': 'Di 20 xulekê de yoga bikin ji Internet an jî ji bîrkirina xwe.',
          'xpReward': 60,
          'type': 'physical'
        },
        {
          'id': 'D10T2',
          'titleEn': 'Reflect on your progress so far',
          'titleAr': 'تأمل في تقدمك حتى الآن',
          'titleKu': 'Di pêşkeftina te de heta niha rû bike',
          'descriptionEn': 'Write down 3 things you have learned or improved in the last 10 days.',
          'descriptionAr': 'اكتب 3 أشياء تعلمتها أو حسنتها في آخر 10 أيام.',
          'descriptionKu': '3 tişt ku hûn di 10 rojan de fihîrîne an jî serkeftin bikirine binivîse.',
          'xpReward': 60,
          'type': 'mental'
        },
        {
          'id': 'D10T3',
          'titleEn': 'Practice patience in a challenging situation',
          'titleAr': 'مارس الصبر في موقف صعب',
          'titleKu': 'Di rewşêkî dengbêjî de sabir bike',
          'descriptionEn': 'Identify one situation that tests your patience and practice staying calm.',
          'descriptionAr': 'حدد موقفاً واحداً يختبر صبرك ومارس البقاء هادئاً.',
          'descriptionKu': 'Rewşêkî ku sabirê te dihilatîne hilbijêre û bi aramî mêne.',
          'xpReward': 60,
          'type': 'spiritual'
        }
      ];
    default:
      return [];
  }
}

// Stage 3: Days 11-15 (Establishing Routines)
List<Map<String, dynamic>> _stage3(int day) {
  switch (day) {
    case 11:
      return [
        {
          'id': 'D11T1',
          'titleEn': 'Do 60 push-ups (3 sets of 20)',
          'titleAr': 'افعل 60 تمرينة ضغط (3 مجموعات من 20)',
          'titleKu': '60 bendekirinê bike (3 serbestî ji 20)',
          'descriptionEn': 'Complete 60 push-ups in 3 sets. Rest 1 minute between sets.',
          'descriptionAr': 'أكمل 60 تمرين ضغط في 3 مجموعات. استرح لمدة دقيقة بين المجموعات.',
          'descriptionKu': '60 bendekirinê bi qencî bike di 3 serbestî de. Di navbera serbestî de 1 xulekî rû bike.',
          'xpReward': 65,
          'type': 'physical'
        },
        {
          'id': 'D11T2',
          'titleEn': 'Meditate for 15 minutes',
          'titleAr': 'تأمل لمدة 15 دقيقة',
          'titleKu': '15 xulekî ragihandinê bike',
          'descriptionEn': 'Sit quietly and focus on your breath for 15 minutes. Notice your thoughts without judgment.',
          'descriptionAr': 'اجلس بهدوء وركز على تنفك لمدة 15 دقيقة. لاحظ أفكارك دون أحكام.',
          'descriptionKu': 'Bi aramî binihîtin û li avêtinê te fokus bike di 15 xulekê de.',
          'xpReward': 65,
          'type': 'mental'
        },
        {
          'id': 'D11T3',
          'titleEn': 'Prepare meals for the next day',
          'titleAr': 'حضّر وجبات ليوم الغد',
          'titleKu': 'Taybetên bo sibeh amade bike',
          'descriptionEn': 'Prepare your meals for tomorrow in advance. This saves time and ensures healthy eating.',
          'descriptionAr': 'حضّر وجباتك لغداً مسبقاً. هذا يوفر الوقت ويضمن الأكل الصحي.',
          'descriptionKu': 'Taybetên bo sibeh bi pêş amade bike. Ev dem diqetîne û xwarina bendewarê dipejinê.',
          'xpReward': 65,
          'type': 'discipline'
        }
      ];
    case 12:
      return [
        {
          'id': 'D12T1',
          'titleEn': 'Cycle for 30 minutes',
          'titleAr': 'اركب الدراجة لمدة 30 دقيقة',
          'titleKu': '30 xulekî bisikletê bike',
          'descriptionEn': 'Ride a bicycle for 30 minutes at a moderate pace.',
          'descriptionAr': 'اركب الدراجة لمدة 30 دقيقة بسرعة متوسطة.',
          'descriptionKu': 'Di 30 xulekê de bisikletê bi hevediyariyê meyilî bike.',
          'xpReward': 70,
          'type': 'physical'
        },
        {
          'id': 'D12T2',
          'titleEn': 'Journal about your feelings',
          'titleAr': 'اكتب في يومياتك عن مشاعرك',
          'titleKu': 'Di rojnameyê de li ser hestiyên te binivîse',
          'descriptionEn': 'Write for 15 minutes about how you are feeling today and why.',
          'descriptionAr': 'اكتب لمدة 15 دقيقة عن مشاعرك اليوم ولماذا.',
          'descriptionKu': 'Di 15 xulekê de li ser hestiyên te li Îro û çima binivîse.',
          'xpReward': 70,
          'type': 'mental'
        },
        {
          'id': 'D12T3',
          'titleEn': 'Visit a neighbor or friend',
          'titleAr': 'زر جاراً أو صديقاً',
          'titleKu': 'Hemûşe an jî hevalêkê sêwirî bike',
          'descriptionEn': 'Visit someone you know for a short, friendly conversation.',
          'descriptionAr': 'زر شخصاً تعرفه لمحادثة قصيرة وودية.',
          'descriptionKu': 'Kesekî ku te dibîne sêwirî bike bo axaftinekî kêm û hênik.',
          'xpReward': 70,
          'type': 'social'
        }
      ];
    case 13:
      return [
        {
          'id': 'D13T1',
          'titleEn': 'Do 70 squats',
          'titleAr': 'افعل 70 تمرين squat',
          'titleKu': '70 zimanî bike',
          'descriptionEn': 'Complete 70 squats with proper form. Focus on quality over quantity.',
          'descriptionAr': 'أكمل 70 تمرين squat بشكل صحيح. ركّز على الجودة بدلاً من الكمية.',
          'descriptionKu': '70 zimanî bi şêweyê rast bike. Li kalîteyê bisevin, ne li qadî.',
          'xpReward': 75,
          'type': 'physical'
        },
        {
          'id': 'D13T2',
          'titleEn': 'Learn to cook a new healthy recipe',
          'titleAr': 'تعلم طبخ وصفة صحية جديدة',
          'titleKu': 'Hînareyê nû bendewar bikîre',
          'descriptionEn': 'Find and cook a new healthy recipe you have never tried before.',
          'descriptionAr': 'ابحث عن وصفة صحية جديدة ولم تحاولها من قبل.',
          'descriptionKu': 'Hînareyê nû bendewar ê ku hûn qet nakirî pêç bikîre.',
          'xpReward': 75,
          'type': 'discipline'
        },
        {
          'id': 'D13T3',
          'titleEn': 'Practice active listening',
          'titleAr': 'مارس الاستماع النشط',
          'titleKu': 'Guharkirinê çalak bikin',
          'descriptionEn': 'Have a conversation where you focus entirely on listening, not responding.',
          'descriptionAr': 'أجرِ محادثة حيث تركز بالكامل على الاستماع، وليس الرد.',
          'descriptionKu': 'Axaftinekê bike ku hûn li ser guharkirinê fokus bikin, ne li bersivdanê.',
          'xpReward': 75,
          'type': 'social'
        }
      ];
    case 14:
      return [
        {
          'id': 'D14T1',
          'titleEn': 'Swim for 20 minutes',
          'titleAr': 'سبح لمدة 20 دقيقة',
          'titleKu': '20 xulekî bavêje',
          'descriptionEn': 'Swim for 20 minutes at a comfortable pace.',
          'descriptionAr': 'سبح لمدة 20 دقيقة بسرعة مريحة.',
          'descriptionKu': 'Di 20 xulekê de bi hevediyariyê aramî bavêje.',
          'xpReward': 80,
          'type': 'physical'
        },
        {
          'id': 'D14T2',
          'titleEn': 'Write a gratitude list of 10 items',
          'titleAr': 'اكتب قائمة شكر من 10 عناصر',
          'titleKu': 'Dîroka şukrê ji 10 tişt binivîse',
          'descriptionEn': 'Write a list of 10 specific things you are grateful for in your life.',
          'descriptionAr': 'اكتب قائمة من 10 أشياء محددة أنت ممتن لها في حياتك.',
          'descriptionKu': 'Li 10 tişt ku hûn piştgînî û heye di jîyanê te de binivîse.',
          'xpReward': 80,
          'type': 'spiritual'
        },
        {
          'id': 'D14T3',
          'titleEn': 'Create a daily schedule for tomorrow',
          'titleAr': 'أنشئ جدول يومي لغد',
          'titleKu': 'Agahdariyê rojane bo sibeh çê bike',
          'descriptionEn': 'Plan your entire day tomorrow with specific times for each activity.',
          'descriptionAr': 'خطط ليومك الغد بالكامل مع أوقات محددة لكل نشاط.',
          'descriptionKu': 'Roja te ya sibeh bi temamî plan bike bi demên taybetî ji bo her çalakiyê.',
          'xpReward': 80,
          'type': 'discipline'
        }
      ];
    case 15:
      return [
        {
          'id': 'D15T1',
          'titleEn': 'Do 80 push-ups and 40 squats',
          'titleAr': 'افعل 80 ضغط و40 squat',
          'titleKu': '80 bendekirinê û 40 zimanî bike',
          'descriptionEn': 'Complete 80 push-ups and 40 squats as a combined workout.',
          'descriptionAr': 'أكمل 80 تمرين ضغط و40 تمرين squat كتمرين مدمج.',
          'descriptionKu': '80 bendekirinê û 40 zimanî bi qencî bike wek karêkê yekî.',
          'xpReward': 85,
          'type': 'physical'
        },
        {
          'id': 'D15T2',
          'titleEn': 'Practice 20 minutes of focused work',
          'titleAr': 'مارس 20 دقيقة من العمل المركّز',
          'titleKu': '20 xulekî karekî fokus bike',
          'descriptionEn': 'Work on a task for 20 minutes with complete focus, no distractions.',
          'descriptionAr': 'اعمل على مهمة لمدة 20 دقيقة بتركيز كامل، دون أي مشتتات.',
          'descriptionKu': 'Di 20 xulekê de li ser karekê fokus bike, bêyî dikkatê.',
          'xpReward': 85,
          'type': 'mental'
        },
        {
          'id': 'D15T3',
          'titleEn': 'Forgive someone who wronged you',
          'titleAr': 'سامح شخصاً ظلمك',
          'titleKu': 'Kesekî ku te xwarê bike',
          'descriptionEn': 'Write down the name of someone you need to forgive and let go of resentment.',
          'descriptionAr': 'اكتب اسم شخص تحتاج لسمحه والتخلص من الغضب تجاهه.',
          'descriptionKu': 'Navê kesekî ku hûn pêdivîye bifîrînin binivîse û qeza bi ve re bike.',
          'xpReward': 85,
          'type': 'spiritual'
        }
      ];
    default:
      return [];
  }
}

// Stage 4: Days 16-20 (Mental Strength)
List<Map<String, dynamic>> _stage4(int day) {
  switch (day) {
    case 16:
      return [
        {
          'id': 'D16T1',
          'titleEn': 'Run for 25 minutes',
          'titleAr': 'اركض لمدة 25 دقيقة',
          'titleKu': '25 xulekî berbiçîne',
          'descriptionEn': 'Run continuously for 25 minutes at a steady pace.',
          'descriptionAr': 'اركض لمدة 25 دقيقة بشكل متواصل بسرعة ثابتة.',
          'descriptionKu': 'Di 25 xulekê de bi hevediyariyê sabit berbiçîne.',
          'xpReward': 90,
          'type': 'physical'
        },
        {
          'id': 'D16T2',
          'titleEn': 'Practice mindfulness for 10 minutes',
          'titleAr': 'مارس الوعي الذهني لمدة 10 دقائق',
          'titleKu': '10 xulekî hizanên xwe bikin',
          'descriptionEn': 'Focus on being present. Notice sounds, sensations, and thoughts without reacting.',
          'descriptionAr': 'ركز على الحضور. لاحظ الأصوات والأحاسيس والأفكار دون تفاعل.',
          'descriptionKu': 'Li ser hizanên te fokus bike. Deng, his û rûher bikeîr bêyî destpêkirinê.',
          'xpReward': 90,
          'type': 'mental'
        },
        {
          'id': 'D16T3',
          'titleEn': 'Identify and challenge a negative thought',
          'titleAr': 'حدد وتحدى فكرة سلبية',
          'titleKu': 'Rûherêkî negatîv hilbijêre û teqîne bike',
          'descriptionEn': 'Notice a negative thought you have and write down why it may not be true.',
          'descriptionAr': 'لاحظ فكرة سلبية لديك واكتب لماذا قد لا تكون صحيحة.',
          'descriptionKu': 'Rûherêkî negatîv ku te heye hilbijêre û çima dikevê der kevebinivîse.',
          'xpReward': 90,
          'type': 'mental'
        }
      ];
    case 17:
      return [
        {
          'id': 'D17T1',
          'titleEn': 'Do a plank for 2 minutes total',
          'titleAr': 'افعل plank لمدة دقيقتين',
          'titleKu': 'Di 2 xulekê de plank bike',
          'descriptionEn': 'Hold a plank position for a total of 2 minutes, broken into sets if needed.',
          'descriptionAr': 'حافظ على وضعية plank لمدة دقيقتين، مقسمة إلى مجموعات إذا لزم الأمر.',
          'descriptionKu': 'Di 2 xulekê de plank bike, di 2 serbestî de bike.',
          'xpReward': 95,
          'type': 'physical'
        },
        {
          'id': 'D17T2',
          'titleEn': 'Write down your top 5 priorities',
          'titleAr': 'اكتب أولوياتك الخمس الأولى',
          'titleKu': '5 yekem li hemberî te binivîse',
          'descriptionEn': 'List your top 5 priorities in life right now and rank them.',
          'descriptionAr': 'اكتب أولوياتك الخمس الأولى في حياتك الآن ورتبها.',
          'descriptionKu': '5 yekem li hemberî te li jîyanê te niha binivîse û rêz bike.',
          'xpReward': 95,
          'type': 'mental'
        },
        {
          'id': 'D17T3',
          'titleEn': 'Perform a random act of kindness',
          'titleAr': 'افعل عملاً عشوائياً من اللطف',
          'titleKu': 'Karekî şexnezanî bikin',
          'descriptionEn': 'Do something kind for someone without expecting anything in return.',
          'descriptionAr': 'افعل شيئاً لطيفاً لشخص دون انتظار أي شيء في المقابل.',
          'descriptionKu': 'Tiştîkî hênik ji bo kesekî bike bêyî rûmetî.',
          'xpReward': 95,
          'type': 'social'
        }
      ];
    case 18:
      return [
        {
          'id': 'D18T1',
          'titleEn': 'Climb stairs for 15 minutes',
          'titleAr': 'اصعد الدرج لمدة 15 دقيقة',
          'titleKu': '15 xulekî qereqalê bike',
          'descriptionEn': 'Climb stairs continuously for 15 minutes. Use a building or stadium.',
          'descriptionAr': 'اصعد الدرج بشكل متواصل لمدة 15 دقيقة. استخدم مبنى أو ملعباً.',
          'descriptionKu': 'Di 15 xulekê de qereqalê bi temamî bike. Mal an jî stadê bikar bîne.',
          'xpReward': 100,
          'type': 'physical'
        },
        {
          'id': 'D18T2',
          'titleEn': 'Read an article about mental health',
          'titleAr': 'اقرأ مقالاً عن الصحة النفسية',
          'titleKu': 'Qetalekî li ser tendemandiya xwe bikir',
          'descriptionEn': 'Find and read a quality article about mental health or personal development.',
          'descriptionAr': 'ابحث واقرأ مقالاً جيداً عن الصحة النفسية أو التنمية الشخصية.',
          'descriptionKu': 'Qetalekî li ser tendemandiya xwe an jî pêşkeftina personal bikeir.',
          'xpReward': 100,
          'type': 'mental'
        },
        {
          'id': 'D18T3',
          'titleEn': 'Practice self-compassion',
          'titleAr': 'مارس العطف على النفس',
          'titleKu': 'Bi xwe re şefeq bike',
          'descriptionEn': 'Write a kind letter to yourself about your struggles and efforts.',
          'descriptionAr': 'اكتب رسالة لطيفة لنفسك عن معاناتك وجهودك.',
          'descriptionKu': 'Nivîsekî hênik ji bo xwe li ser dîtina te û ezmûnên te bivîse.',
          'xpReward': 100,
          'type': 'spiritual'
        }
      ];
    case 19:
      return [
        {
          'id': 'D19T1',
          'titleEn': 'Do 100 push-ups throughout the day',
          'titleAr': 'افعل 100 ضغط على مدار اليوم',
          'titleKu': '100 bendekirinê di roja de bike',
          'descriptionEn': 'Complete 100 push-ups throughout the day in any number of sets.',
          'descriptionAr': 'أكمل 100 تمرين ضغط على مدار اليوم بأي عدد من المجموعات.',
          'descriptionKu': '100 bendekirinê di roja de di her qadî de bi qencî bike.',
          'xpReward': 105,
          'type': 'physical'
        },
        {
          'id': 'D19T2',
          'titleEn': 'Practice saying "no" to one request',
          'titleAr': 'مارس قول "لا" لطلب واحد',
          'titleKu': 'Ji bo serbestiyêkê "ne" bêje',
          'descriptionEn': 'Politely decline one request that would take away your time or energy.',
          'descriptionAr': 'رفض بأدب طبباً واحداً سيستنزف وقتك أو طاقتك.',
          'descriptionKu': 'Bi dilsozî "ne" bêje ji bo serbestiyêkê ku dem an jî enerjî te diqetîne.',
          'xpReward': 105,
          'type': 'discipline'
        },
        {
          'id': 'D19T3',
          'titleEn': 'Share your story with someone',
          'titleAr': 'شارك قصتك مع شخص',
          'titleKu': 'Çîrokê xwe bi kesekî re parve bike',
          'descriptionEn': 'Open up to someone you trust about your recovery journey.',
          'descriptionAr': 'افتح قلبك لشخص تثق به عن رحلة تعافيك.',
          'descriptionKu': 'Dilê xwe bo kesekî ku hûn bi wê re trust bikin veke li ser seferê şifakirina te.',
          'xpReward': 105,
          'type': 'social'
        }
      ];
    case 20:
      return [
        {
          'id': 'D20T1',
          'titleEn': 'Complete a 30-minute workout',
          'titleAr': 'أكمل تمريناً رياضياً لمدة 30 دقيقة',
          'titleKu': '30 xulekî karê vîrajyana bike',
          'descriptionEn': 'Do a full 30-minute workout including warm-up, exercises, and cool-down.',
          'descriptionAr': 'أكمل تمريناً رياضياً كاملاً لمدة 30 دقيقة يشمل الإحماء والتمارين والتهدئة.',
          'descriptionKu': '30 xulekî karê vîrajyana bike bi tepikirinê, vîrajyan û aramîkirinê.',
          'xpReward': 110,
          'type': 'physical'
        },
        {
          'id': 'D20T2',
          'titleEn': 'Identify 3 limiting beliefs',
          'titleAr': 'حدد 3 معتقدات مقيّدة',
          'titleKu': '3 rûherên sernegahekirinê hilbijêre',
          'descriptionEn': 'Write down 3 beliefs that hold you back and rewrite them positively.',
          'descriptionAr': 'اكتب 3 معتقدات تمنعك وأعد كتابتها بشكل إيجابي.',
          'descriptionKu': '3 rûherên ku te dişkinin binivîse û bi awayê ecêb nû nivîse.',
          'xpReward': 110,
          'type': 'mental'
        },
        {
          'id': 'D20T3',
          'titleEn': 'Fast for one meal',
          'titleAr': 'صم لوجبة واحدة',
          'titleKu': 'Ji bo taybetêkî rûçik bixe',
          'descriptionEn': 'Skip one meal today and use the time for reflection or prayer.',
          'descriptionAr': 'تخطى وجبة واحدة اليوم واستخدم الوقت للتأمل أو الصلاة.',
          'descriptionKu': 'Taybetêkî rojê bixwe û demê ji bo ragihandinê an jî namê bikar bîne.',
          'xpReward': 110,
          'type': 'spiritual'
        }
      ];
    default:
      return [];
  }
}

// Stage 5: Days 21-25 (Social Connection)
List<Map<String, dynamic>> _stage5(int day) {
  switch (day) {
    case 21:
      return [
        {
          'id': 'D21T1',
          'titleEn': 'Walk 45 minutes',
          'titleAr': 'امشي لمدة 45 دقيقة',
          'titleKu': '45 xulekî bipeyive',
          'descriptionEn': 'Walk for 45 minutes at a brisk pace. Focus on your breathing and posture.',
          'descriptionAr': 'امشي لمدة 45 دقيقة بسرعة سريعة. ركّز على تنفسك ووضعية جسمك.',
          'descriptionKu': 'Di 45 xulekê de bi hevediyariyê çalak bipeyive. Li avêtinê û diqetînê te fokus bike.',
          'xpReward': 115,
          'type': 'physical'
        },
        {
          'id': 'D21T2',
          'titleEn': 'Schedule a coffee meeting',
          'titleAr': 'حدد موعداً للقهوة',
          'titleKu': 'Dîmena kahvêkî serbest bike',
          'descriptionEn': 'Arrange to meet someone for coffee or tea in the next few days.',
          'descriptionAr': 'رتّب لقاء مع شخص للقهوة أو الشاي في الأيام القليلة القادمة.',
          'descriptionKu': 'Bo avêtina kesekî li ser kahve an jî çay di 3-4 rojan de serbest bike.',
          'xpReward': 115,
          'type': 'social'
        },
        {
          'id': 'D21T3',
          'titleEn': 'Practice a breathing exercise for 10 minutes',
          'titleAr': 'مارس تمرين تنفسي لمدة 10 دقائق',
          'titleKu': '10 xulekî avêtinê bikin',
          'descriptionEn': 'Try box breathing: inhale 4 counts, hold 4, exhale 4, hold 4. Repeat.',
          'descriptionAr': 'جرّب تنفس المربع: شهيق 4 عدات، حبس 4، زفير 4، حبس 4. كرر.',
          'descriptionKu': 'Avêtina qutî bikin: 4 dîtî, 4 berxê, 4 avêtin, 4 berxê. Du barê bike.',
          'xpReward': 115,
          'type': 'mental'
        }
      ];
    case 22:
      return [
        {
          'id': 'D22T1',
          'titleEn': 'Do 50 lunges (25 each leg)',
          'titleAr': 'افعل 50 lunge (25 لكل ساق)',
          'titleKu': '50 lunge bike (25 ji her pî)',
          'descriptionEn': 'Complete 50 lunges, alternating legs. Focus on balance and form.',
          'descriptionAr': 'أكمل 50 lunge، متناوباً بين الساقين. ركّز على التوازن والشكل.',
          'descriptionKu': '50 lunge bi qencî bike, li her pî re du barê bike. Li balansê û şêweyê fokus bike.',
          'xpReward': 120,
          'type': 'physical'
        },
        {
          'id': 'D22T2',
          'titleEn': 'Apologize to someone you have wronged',
          'titleAr': 'اعتذر لشخص أساءت إليه',
          'titleKu': 'Kesekî ku te xwarê bikirî bûyî bêje',
          'descriptionEn': 'Genuinely apologize to someone for a past mistake or hurt.',
          'descriptionAr': 'اعتذر بصدق لشخص عن خطأ أو ألم في الماضي.',
          'descriptionKu': 'Bi rastî bêje "bûyî" ji bo kesekî ku te di qêrînê de xwarê kirî bûyî.',
          'xpReward': 120,
          'type': 'social'
        },
        {
          'id': 'D22T3',
          'titleEn': 'Create a personal mission statement',
          'titleAr': 'أنشئ بياناً للرسالة الشخصية',
          'titleKu': 'Daxwaznameyê personal bikir',
          'descriptionEn': 'Write a short statement about your purpose and values in life.',
          'descriptionAr': 'اكتب بياناً مختصراً عن غرضك وقيمك في الحياة.',
          'descriptionKu': 'Nivîsekî kêm ji bo mafê xwe û nirxên te di jîyanê de bivîse.',
          'xpReward': 120,
          'type': 'spiritual'
        }
      ];
    case 23:
      return [
        {
          'id': 'D23T1',
          'titleEn': 'Swim for 30 minutes',
          'titleAr': 'سبح لمدة 30 دقيقة',
          'titleKu': '30 xulekî bavêje',
          'descriptionEn': 'Swim for 30 minutes continuously. Focus on stroke technique.',
          'descriptionAr': 'سبح لمدة 30 دقيقة بشكل متواصل. ركّز على تقنية الضربة.',
          'descriptionKu': 'Di 30 xulekê de bi temamî bavêje. Li şêweyê strike fokus bike.',
          'xpReward': 125,
          'type': 'physical'
        },
        {
          'id': 'D23T2',
          'titleEn': 'Write a thank-you note',
          'titleAr': 'اكتب بريداً تهنئياً',
          'titleKu': 'Nivîsekî şukrê bivîse',
          'descriptionEn': 'Write and send a genuine thank-you message to someone who has helped you.',
          'descriptionAr': 'اكتب وأرسل رسالة شكر صادقة لشخص ساعدك.',
          'descriptionKu': 'Nivîsekî şukrê bi rastî bivîse û bo kesekî ku te alîkariya te kirî bavêze.',
          'xpReward': 125,
          'type': 'social'
        },
        {
          'id': 'D23T3',
          'titleEn': 'Practice progressive muscle relaxation',
          'titleAr': 'مارس استرخاء العضلات التدريجي',
          'titleKu': 'Aramburgirina azmê bi hêdî bikin',
          'descriptionEn': 'Tense and release each muscle group for 5 seconds, working from toes to head.',
          'descriptionAr': 'شد وارخِ كل مجموعة عضلات لمدة 5 ثوانٍ، من القدم إلى الرأس.',
          'descriptionKu': 'Di her gurûpa azmê de 5 saniyê bişkêjin û vekir, ji pêy derê serê.',
          'xpReward': 125,
          'type': 'mental'
        }
      ];
    case 24:
      return [
        {
          'id': 'D24T1',
          'titleEn': 'Do a 35-minute HIIT workout',
          'titleAr': 'مارس تمرين HIIT لمدة 35 دقيقة',
          'titleKu': '35 xulekî HIIT bike',
          'descriptionEn': 'Complete a 35-minute high-intensity interval training session.',
          'descriptionAr': 'أكمل جلسة تدريب عالي الكثافة لمدة 35 دقيقة.',
          'descriptionKu': '35 xulekî karê vîrajyana bilind bi qencî bike.',
          'xpReward': 130,
          'type': 'physical'
        },
        {
          'id': 'D24T2',
          'titleEn': 'Resolve a small conflict',
          'titleAr': 'حل نزاعاً صغيراً',
          'titleKu': 'Çenûskiyêkî piçûk çare bike',
          'descriptionEn': 'Address and resolve a small misunderstanding or conflict with someone.',
          'descriptionAr': 'تطرق وحل سوء تفاهم أو نزاع صغير مع شخص.',
          'descriptionKu': 'Çenûskiyêkî piçûk bi kesekî re çare bike.',
          'xpReward': 130,
          'type': 'social'
        },
        {
          'id': 'D24T3',
          'titleEn': 'Create a bedtime routine',
          'titleAr': 'أنشئ روتيناً للنوم',
          'titleKu': 'Rutînekî bo niştêjê çê bike',
          'descriptionEn': 'Design and follow a consistent bedtime routine tonight.',
          'descriptionAr': 'صمم واتبع روتيناً ثابتاً للنوم الليلة.',
          'descriptionKu': 'Niştêjê xwe bi şêweyê nû amade bike û bi qencî bike.',
          'xpReward': 130,
          'type': 'discipline'
        }
      ];
    case 25:
      return [
        {
          'id': 'D25T1',
          'titleEn': 'Run 5 kilometers',
          'titleAr': 'اركض 5 كيلومترات',
          'titleKu': '5 kilometer berbiçîne',
          'descriptionEn': 'Run 5 kilometers at a comfortable pace. Walk if needed.',
          'descriptionAr': 'اركض 5 كيلومترات بسرعة مريحة. المشي إذا لزم الأمر.',
          'descriptionKu': 'Di 5 kilometer de bi hevediyariyê aramî berbiçîne. He pêdivîye bipeyive.',
          'xpReward': 135,
          'type': 'physical'
        },
        {
          'id': 'D25T2',
          'titleEn': 'Practice empathy in a conversation',
          'titleAr': 'مارس التعاطف في محادثة',
          'titleKu': 'Di axaftinê de hênikî bike',
          'descriptionEn': 'Have a conversation where you try to fully understand the other person\'s perspective.',
          'descriptionAr': 'أجرِ محادثة تحاول فيها فهم وجهة نظر الشخص الآخر بالكامل.',
          'descriptionKu': 'Axaftinekê bike ku hûn bixwazin li ser dîtina kesê din bi temamî fihîrin.',
          'xpReward': 135,
          'type': 'social'
        },
        {
          'id': 'D25T3',
          'titleEn': 'Fast for 16 hours (intermittent fasting)',
          'titleAr': 'صم لمدة 16 ساعة (صيام متقطع)',
          'titleKu': '16 saetan rûçik bixe',
          'descriptionEn': 'Try intermittent fasting: eat within an 8-hour window today.',
          'descriptionAr': 'جرّب الصيام المتقطع: تناول الطعام خلال 8 ساعات فقط اليوم.',
          'descriptionKu': 'Rûçika giyan bikin: di 8 saetan de xwarinê bixwe.',
          'xpReward': 135,
          'type': 'discipline'
        }
      ];
    default:
      return [];
  }
}

// Stage 6: Days 26-30 (Discipline Building)
List<Map<String, dynamic>> _stage6(int day) {
  switch (day) {
    case 26:
      return [
        {
          'id': 'D26T1',
          'titleEn': 'Do 120 push-ups throughout the day',
          'titleAr': 'افعل 120 ضغط على مدار اليوم',
          'titleKu': '120 bendekirinê di roja de bike',
          'descriptionEn': 'Complete 120 push-ups throughout the day in any number of sets.',
          'descriptionAr': 'أكمل 120 تمرين ضغط على مدار اليوم بأي عدد من المجموعات.',
          'descriptionKu': '120 bendekirinê di roja de di her qadî de bi qencî bike.',
          'xpReward': 140,
          'type': 'physical'
        },
        {
          'id': 'D26T2',
          'titleEn': 'Declutter one area of your home',
          'titleAr': 'رتّب منطقة واحدة في منزلك',
          'titleKu': 'Qadekî di malê te de paqij bike',
          'descriptionEn': 'Choose one cluttered area and organize it completely.',
          'descriptionAr': 'اختر منطقة فوضوية ونظّفها بالكامل.',
          'descriptionKu': 'Qadekî ku di derdorê de yê nû bike û bi temamî paqij bike.',
          'xpReward': 140,
          'type': 'discipline'
        },
        {
          'id': 'D26T3',
          'titleEn': 'Practice gratitude for 10 minutes',
          'titleAr': 'مارس الشكر لمدة 10 دقائق',
          'titleKu': '10 xulekî şukrê bikin',
          'descriptionEn': 'Spend 10 minutes thinking deeply about what you are grateful for.',
          'descriptionAr': 'اقضِ 10 دقائق في التفكير بعمق فيما أنت ممتن له.',
          'descriptionKu': 'Di 10 xulekê de bi qencî li ser tiştên ku hûn piştgînî û heye bifîre.',
          'xpReward': 140,
          'type': 'spiritual'
        }
      ];
    case 27:
      return [
        {
          'id': 'D27T1',
          'titleEn': 'Walk 60 minutes',
          'titleAr': 'امشي لمدة 60 دقيقة',
          'titleKu': '60 xulekî bipeyive',
          'descriptionEn': 'Walk for 60 minutes. This is your longest walk yet!',
          'descriptionAr': 'امشي لمدة 60 دقيقة. هذه أطول مشية لك حتى الآن!',
          'descriptionKu': 'Di 60 xulekê de bipeyive. Ev gerîteya te ya pêşîn e!',
          'xpReward': 145,
          'type': 'physical'
        },
        {
          'id': 'D27T2',
          'titleEn': 'Read a chapter of a self-help book',
          'titleAr': 'اقرأ فصلاً من كتاب تطوير ذات',
          'titleKu': 'Alîkareyê pirtûkê xwe biqencî bike',
          'descriptionEn': 'Read one chapter of a personal development or recovery book.',
          'descriptionAr': 'اقرأ فصلاً واحداً من كتاب تنمية ذاتية أو تعافٍ.',
          'descriptionKu': 'Alîkareyêkî ji pirtûkê pêşkeftina personal an jî şifakirinê bixwe.',
          'xpReward': 145,
          'type': 'mental'
        },
        {
          'id': 'D27T3',
          'titleEn': 'Call an old friend you have lost touch with',
          'titleAr': 'اتصل بصديق قديم فقدت الاتصال به',
          'titleKu': 'Bi hevalêkî kevneşopî re telefona bike',
          'descriptionEn': 'Reconnect with someone you have not spoken to in a while.',
          'descriptionAr': 'أعد الاتصال بشخص لم تتحدث إليه منذ فترة.',
          'descriptionKu': 'Dîtinê nû bi kesekî re bikin ku hûn bi wê re di demê de nexwe.',
          'xpReward': 145,
          'type': 'social'
        }
      ];
    case 28:
      return [
        {
          'id': 'D28T1',
          'titleEn': 'Do 80 squats and 60 lunges',
          'titleAr': 'افعل 80 squat و60 lunge',
          'titleKu': '80 zimanî û 60 lunge bike',
          'descriptionEn': 'Complete 80 squats and 60 lunges as a leg-focused workout.',
          'descriptionAr': 'أكمل 80 تمرين squat و60 lunge كتمرين يركّز على الساقين.',
          'descriptionKu': '80 zimanî û 60 lunge bi qencî bike wek karê pî.',
          'xpReward': 150,
          'type': 'physical'
        },
        {
          'id': 'D28T2',
          'titleEn': 'Practice 30 minutes of focused work',
          'titleAr': 'مارس 30 دقيقة من العمل المركّز',
          'titleKu': '30 xulekî karekî fokus bike',
          'descriptionEn': 'Work on a single task for 30 minutes with no distractions.',
          'descriptionAr': 'اعمل على مهمة واحدة لمدة 30 دقيقة دون أي مشتتات.',
          'descriptionKu': 'Di 30 xulekê de li ser karekêkî yek bi fokus bike.',
          'xpReward': 150,
          'type': 'mental'
        },
        {
          'id': 'D28T3',
          'titleEn': 'Prepare a meal for someone else',
          'titleAr': 'حضّر وجبة لشخص آخر',
          'titleKu': 'Taybetêkî ji bo kesê din amade bike',
          'descriptionEn': 'Cook a meal for a family member, friend, or neighbor.',
          'descriptionAr': 'اطبخ وجبة لفرد من العائلة أو صديق أو جار.',
          'descriptionKu': 'Taybetêkî ji bo kesekî ji malbatê, heval an jî hemûşe bixwirine.',
          'xpReward': 150,
          'type': 'social'
        }
      ];
    case 29:
      return [
        {
          'id': 'D29T1',
          'titleEn': 'Do a 40-minute workout',
          'titleAr': 'أكمل تمريناً رياضياً لمدة 40 دقيقة',
          'titleKu': '40 xulekî karê vîrajyana bike',
          'descriptionEn': 'Complete a 40-minute workout with variety: cardio, strength, and stretching.',
          'descriptionAr': 'أكمل تمريناً رياضياً لمدة 40 دقيقة مع تنوع:-cardio، قوة، ومرونة.',
          'descriptionKu': '40 xulekî karê vîrajyana bike bi cureyan: cardio, hêl, û stretch.',
          'xpReward': 155,
          'type': 'physical'
        },
        {
          'id': 'D29T2',
          'titleEn': 'Write down your values and principles',
          'titleAr': 'اكتب قيمك ومبادئك',
          'titleKu': 'Nirxên û bingeha xwe binivîse',
          'descriptionEn': 'List the top 5 values that guide your life and decisions.',
          'descriptionAr': 'اكتب 5 قيم رئيسية توجه حياتك وقراراتك.',
          'descriptionKu': '5 nirxên sereke ku jîyan û qerepên te dihilatîne binivîse.',
          'xpReward': 155,
          'type': 'mental'
        },
        {
          'id': 'D29T3',
          'titleEn': 'Meditate for 20 minutes',
          'titleAr': 'تأمل لمدة 20 دقيقة',
          'titleKu': '20 xulekî ragihandinê bike',
          'descriptionEn': 'Sit in silence for 20 minutes, focusing on your breath and letting thoughts pass.',
          'descriptionAr': 'اجلس في صمت لمدة 20 دقيقة، ركّز على تنفك ودع الأفكار تمر.',
          'descriptionKu': 'Di 20 xulekê de bi dengê nedin bi aramî binihîtin, li avêtinê fokus bike.',
          'xpReward': 155,
          'type': 'spiritual'
        }
      ];
    case 30:
      return [
        {
          'id': 'D30T1',
          'titleEn': 'Run 6 kilometers',
          'titleAr': 'اركض 6 كيلومترات',
          'titleKu': '6 kilometer berbiçîne',
          'descriptionEn': 'Run 6 kilometers. You are now in the second month!',
          'descriptionAr': 'اركض 6 كيلومترات. أنت الآن في الشهر الثاني!',
          'descriptionKu': 'Di 6 kilometer de berbiçîne. Hûn niha di mehê duwemî de!',
          'xpReward': 160,
          'type': 'physical'
        },
        {
          'id': 'D30T2',
          'titleEn': 'Review your goals from Day 1',
          'titleAr': 'راجع أهدافك من اليوم الأول',
          'titleKu': 'Armanca te ji roja 1 veşartbike',
          'descriptionEn': 'Read the letter you wrote to yourself on Day 4 and reflect on your growth.',
          'descriptionAr': 'اقرأ الرسالة التي كتبتها لنفسك في اليوم 4 وتأمل في نموك.',
          'descriptionKu': 'Nivîsê ku te ji roja 4 de nivîsand bi xwîne û li ser pêşkeftina te rû bike.',
          'xpReward': 160,
          'type': 'mental'
        },
        {
          'id': 'D30T3',
          'titleEn': 'Perform a meaningful act of service',
          'titleAr': 'افعل عملاً ذا معنى من الخدمة',
          'titleKu': 'Karekî bi manayêî bikin',
          'descriptionEn': 'Volunteer your time or resources to help someone in need.',
          'descriptionAr': 'تطوع بوقتك أو مواردك لمساعدة شخص محتاج.',
          'descriptionKu': 'Dem an jî serkeftiyên xwe bo alîkariya kesekî pêdivî bike.',
          'xpReward': 160,
          'type': 'social'
        }
      ];
    default:
      return [];
  }
}

// Stage 7: Days 31-35 (Spiritual Deepening)
List<Map<String, dynamic>> _stage7(int day) {
  switch (day) {
    case 31:
      return [
        {
          'id': 'D31T1',
          'titleEn': 'Do 100 squats and 80 lunges',
          'titleAr': 'افعل 100 squat و80 lunge',
          'titleKu': '100 zimanî û 80 lunge bike',
          'descriptionEn': 'Complete 100 squats and 80 lunges in sets of 20.',
          'descriptionAr': 'أكمل 100 تمرين squat و80 lunge في مجموعات من 20.',
          'descriptionKu': '100 zimanî û 80 lunge bi qencî bike di serbestiyên 20 de.',
          'xpReward': 165,
          'type': 'physical'
        },
        {
          'id': 'D31T2',
          'titleEn': 'Practice silent reflection for 15 minutes',
          'titleAr': 'مارس التأمل الصامت لمدة 15 دقيقة',
          'titleKu': '15 xulekî biryarê bi aramî bikin',
          'descriptionEn': 'Sit in complete silence for 15 minutes, reflecting on your journey.',
          'descriptionAr': 'اجلس في صمت تام لمدة 15 دقيقة، متأملاً في رحلتك.',
          'descriptionKu': 'Di 15 xulekê de bi dengê nedin binihîtin, li ser seferê te rû bike.',
          'xpReward': 165,
          'type': 'spiritual'
        },
        {
          'id': 'D31T3',
          'titleEn': 'Identify one habit to break',
          'titleAr': 'حدد عادة واحدة للتخلص منها',
          'titleKu': 'Adetêkî ku divê were çalê bikirî hilbijêre',
          'descriptionEn': 'Choose one bad habit you want to eliminate and create a plan to break it.',
          'descriptionAr': 'اختر عادة سيئة تريد التخلص منها وأنشئ خطة لكسرها.',
          'descriptionKu': 'Adetêkî yê nû ku hûn dixwazin veda bikirî hilbijêre û plan çê bike.',
          'xpReward': 165,
          'type': 'discipline'
        }
      ];
    case 32:
      return [
        {
          'id': 'D32T1',
          'titleEn': 'Bike for 45 minutes',
          'titleAr': 'اركب الدراجة لمدة 45 دقيقة',
          'titleKu': '45 xulekî bisikletê bike',
          'descriptionEn': 'Ride a bicycle for 45 minutes at a challenging pace.',
          'descriptionAr': 'اركب الدراجة لمدة 45 دقيقة بسرعة تحدٍ.',
          'descriptionKu': 'Di 45 xulekê de bisikletê bi hevediyariyê teqîneyê bike.',
          'xpReward': 170,
          'type': 'physical'
        },
        {
          'id': 'D32T2',
          'titleEn': 'Practice deep listening with a family member',
          'titleAr': 'مارس الاستماع العميق مع فرد من العائلة',
          'titleKu': 'Bi kesekî ji malbatê re guharkirinê çalak bike',
          'descriptionEn': 'Have a deep conversation with a family member, focusing on understanding.',
          'descriptionAr': 'أجرِ محادثة عميقة مع فرد من العائلة، مع التركيز على الفهم.',
          'descriptionKu': 'Axaftinekî dengbêjî bi kesekî ji malbatê re bike, li ser fihînê fokus bike.',
          'xpReward': 170,
          'type': 'social'
        },
        {
          'id': 'D32T3',
          'titleEn': 'Read a spiritual or philosophical text',
          'titleAr': 'اقرأ نصاً روحانياً أو فلسفياً',
          'titleKu': 'Nivîsekî ruhî an jî felsefî bixwe',
          'descriptionEn': 'Read a meaningful text from a spiritual or philosophical tradition.',
          'descriptionAr': 'اقرأ نصاً ذا معنى من تقليد روحاني أو فلسفي.',
          'descriptionKu': 'Nivîsekî bi manayêî ji awayeke ruhî an jî felsefî bixwe.',
          'xpReward': 170,
          'type': 'spiritual'
        }
      ];
    case 33:
      return [
        {
          'id': 'D33T1',
          'titleEn': 'Do 150 push-ups throughout the day',
          'titleAr': 'افعل 150 ضغط على مدار اليوم',
          'titleKu': '150 bendekirinê di roja de bike',
          'descriptionEn': 'Complete 150 push-ups throughout the day in any number of sets.',
          'descriptionAr': 'أكمل 150 تمرين ضغط على مدار اليوم بأي عدد من المجموعات.',
          'descriptionKu': '150 bendekirinê di roja de di her qadî de bi qencî bike.',
          'xpReward': 175,
          'type': 'physical'
        },
        {
          'id': 'D33T2',
          'titleEn': 'Practice 25 minutes of focused work',
          'titleAr': 'مارس 25 دقيقة من العمل المركّز',
          'titleKu': '25 xulekî karekî fokus bike',
          'descriptionEn': 'Work on a single task for 25 minutes with absolute focus.',
          'descriptionAr': 'اعمل على مهمة واحدة لمدة 25 دقيقة بتركيز مطلق.',
          'descriptionKu': 'Di 25 xulekê de li ser karekêkî yek bi fokus absolut bike.',
          'xpReward': 175,
          'type': 'mental'
        },
        {
          'id': 'D33T3',
          'titleEn': 'Write a forgiveness letter',
          'titleAr': 'اكتب رسالة مغفرة',
          'titleKu': 'Nivîsekî bûyîkirinê bivîse',
          'descriptionEn': 'Write a letter forgiving yourself or someone else for a past hurt.',
          'descriptionAr': 'اكتب رسالة تسامح لنفسك أو لشخص آخر عن ألم في الماضي.',
          'descriptionKu': 'Nivîsekî bûyîkirinê ji bo xwe an jî kesê din ji bo dîtinekê pêşîn bivîse.',
          'xpReward': 175,
          'type': 'spiritual'
        }
      ];
    case 34:
      return [
        {
          'id': 'D34T1',
          'titleEn': 'Swim for 40 minutes',
          'titleAr': 'سبح لمدة 40 دقيقة',
          'titleKu': '40 xulekî bavêje',
          'descriptionEn': 'Swim for 40 minutes continuously with varied strokes.',
          'descriptionAr': 'سبح لمدة 40 دقيقة بشكل متواصل مع تنويع الضربات.',
          'descriptionKu': 'Di 40 xulekê de bi temamî bavêje bi cureyên cur.',
          'xpReward': 180,
          'type': 'physical'
        },
        {
          'id': 'D34T2',
          'titleEn': 'Create a vision board for your goals',
          'titleAr': 'أنشئ لوحة رؤية لأهدافك',
          'titleKu': 'Tabyayê dîtina te çê bike',
          'descriptionEn': 'Collect images and words that represent your goals and create a vision board.',
          'descriptionAr': 'اجمع صوراً وكلمات تمثل أهدافك وأنشئ لوحة رؤية.',
          'descriptionKu': 'Wêne û peyvên ku armanca te dabizîne girtin û tabyayê dîtina te çê bike.',
          'xpReward': 180,
          'type': 'mental'
        },
        {
          'id': 'D34T3',
          'titleEn': 'Spend an hour in nature without devices',
          'titleAr': 'اقضِ ساعة في الطبيعة بدون أجهزة',
          'titleKu': 'Di 1 saetan de di nexşeyê de bimîne bêyî amûr',
          'descriptionEn': 'Spend one hour outside in nature with no phone, tablet, or other devices.',
          'descriptionAr': 'اقضِ ساعة في الخارج في الطبيعة بدون هاتف أو جهاز آخر.',
          'descriptionKu': 'Di 1 saetan de der çavê nexşeyê de bimîne bêyî telefon an jî amûr.',
          'xpReward': 180,
          'type': 'spiritual'
        }
      ];
    case 35:
      return [
        {
          'id': 'D35T1',
          'titleEn': 'Complete a 45-minute workout',
          'titleAr': 'أكمل تمريناً رياضياً لمدة 45 دقيقة',
          'titleKu': '45 xulekî karê vîrajyana bike',
          'descriptionEn': 'Do a full 45-minute workout with cardio, strength, and flexibility.',
          'descriptionAr': 'أكمل تمريناً رياضياً كاملاً لمدة 45 دقيقة مع تمارين القلب والقوة والمرونة.',
          'descriptionKu': '45 xulekî karê vîrajyana bike bi cardio, hêl, û stretch.',
          'xpReward': 185,
          'type': 'physical'
        },
        {
          'id': 'D35T2',
          'titleEn': 'Practice gratitude journaling for 20 minutes',
          'titleAr': 'مارس كتابة يوميات الشكر لمدة 20 دقيقة',
          'titleKu': '20 xulekî rojnameyê şukrê binivîse',
          'descriptionEn': 'Write in detail about 5 things you are grateful for, explaining why each matters.',
          'descriptionAr': 'اكتب بالتفصيل عن 5 أشياء أنت ممتن لها، موضحاً لماذا كل منها مهم.',
          'descriptionKu': 'Li ser 5 tişt ku hûn piştgînî û heye bi qencî binivîse, çima her yekî giring bike.',
          'xpReward': 185,
          'type': 'spiritual'
        },
        {
          'id': 'D35T3',
          'titleEn': 'Organize your financial records',
          'titleAr': 'نظّف سجلاتك المالية',
          'titleKu': 'Agahdariyên dîwana xwe paqij bike',
          'descriptionEn': 'Organize your bills, receipts, and financial documents.',
          'descriptionAr': 'رتّب فواتيرك وإيصالاتك ووثائقك المالية.',
          'descriptionKu': 'Bilêç, qayîm û belêkên dîwana xwe paqij bike.',
          'xpReward': 185,
          'type': 'discipline'
        }
      ];
    default:
      return [];
  }
}

// Stage 8: Days 36-40 (Physical Challenge)
List<Map<String, dynamic>> _stage8(int day) {
  switch (day) {
    case 36:
      return [
        {
          'id': 'D36T1',
          'titleEn': 'Run 7 kilometers',
          'titleAr': 'اركض 7 كيلومترات',
          'titleKu': '7 kilometer berbiçîne',
          'descriptionEn': 'Run 7 kilometers at a steady pace. Focus on endurance.',
          'descriptionAr': 'اركض 7 كيلومترات بسرعة ثابتة. ركّز على التحمل.',
          'descriptionKu': 'Di 7 kilometer de bi hevediyariyê sabit berbiçîne. Li hewilî fokus bike.',
          'xpReward': 190,
          'type': 'physical'
        },
        {
          'id': 'D36T2',
          'titleEn': 'Practice 30 minutes of deep work',
          'titleAr': 'مارس 30 دقيقة من العمل العميق',
          'titleKu': '30 xulekî karê dengbêjî bike',
          'descriptionEn': 'Work on your most important task for 30 minutes with no interruptions.',
          'descriptionAr': 'اعمل على أهم مهمة لديك لمدة 30 دقيقة دون أي مقاطعات.',
          'descriptionKu': 'Di 30 xulekê de li ser karê sereke te li ser fokus absolut bike.',
          'xpReward': 190,
          'type': 'mental'
        },
        {
          'id': 'D36T3',
          'titleEn': 'Practice a new form of prayer or meditation',
          'titleAr': 'مارس شكل جديد من الصلاة أو التأمل',
          'titleKu': 'Awayêkî nû ji namê an jî ragihandinê bike',
          'descriptionEn': 'Try a different form of prayer or meditation than what you are used to.',
          'descriptionAr': 'جرّب شكل مختلف من الصلاة أو التأمل عما تعودت عليه.',
          'descriptionKu': 'Awayêkî cuda ji namê an jî ragihandinê bike wek ku hûn bi wê re nexwazin.',
          'xpReward': 190,
          'type': 'spiritual'
        }
      ];
    case 37:
      return [
        {
          'id': 'D37T1',
          'titleEn': 'Do 200 push-ups throughout the day',
          'titleAr': 'افعل 200 ضغط على مدار اليوم',
          'titleKu': '200 bendekirinê di roja de bike',
          'descriptionEn': 'Complete 200 push-ups throughout the day. You can do it!',
          'descriptionAr': 'أكمل 200 تمرين ضغط على مدار اليوم. تستطيع!',
          'descriptionKu': '200 bendekirinê di roja de bi qencî bike. Hûn dikarin!',
          'xpReward': 195,
          'type': 'physical'
        },
        {
          'id': 'D37T2',
          'titleEn': 'Teach someone a skill you have',
          'titleAr': 'علم شخصاً مهارة لديك',
          'titleKu': 'Hînarekî ku te heye kesekî fêr bike',
          'descriptionEn': 'Share your knowledge by teaching someone something you are good at.',
          'descriptionAr': 'شارك معرفتك بتعليم شخص شيئاً أنت جيد فيه.',
          'descriptionKu': 'Zanînê xwe bi fêrkirina kesekî li ser tiştî ku te baş dike parve bike.',
          'xpReward': 195,
          'type': 'social'
        },
        {
          'id': 'D37T3',
          'titleEn': 'Create a morning routine checklist',
          'titleAr': 'أنشئ قائمة فحص للروتين الصباحي',
          'titleKu': 'Li ser rutîna sibehê lîsteyek çê bike',
          'descriptionEn': 'Design a morning routine checklist and follow it tomorrow.',
          'descriptionAr': 'صمم قائمة فحص للروتين الصباحي واتبعها غداً.',
          'descriptionKu': 'Li ser rutîna sibehê lîsteyek çê bike û sibeh bi qencî bike.',
          'xpReward': 195,
          'type': 'discipline'
        }
      ];
    case 38:
      return [
        {
          'id': 'D38T1',
          'titleEn': 'Do a 50-minute workout',
          'titleAr': 'أكمل تمريناً رياضياً لمدة 50 دقيقة',
          'titleKu': '50 xulekî karê vîrajyana bike',
          'descriptionEn': 'Complete a challenging 50-minute workout session.',
          'descriptionAr': 'أكمل جلسة تمرين صعبة لمدة 50 دقيقة.',
          'descriptionKu': '50 xulekî karê vîrajyana bike bi teqîneyê.',
          'xpReward': 200,
          'type': 'physical'
        },
        {
          'id': 'D38T2',
          'titleEn': 'Write about your biggest fear',
          'titleAr': 'اكتب عن خوفك الأكبر',
          'titleKu': 'Li ser tîrêjê te ya mezin binivîse',
          'descriptionEn': 'Write about your biggest fear and why it affects you.',
          'descriptionAr': 'اكتب عن خوفك الأكبر ولماذا يؤثر عليك.',
          'descriptionKu': 'Li ser tîrêjê te ya mezin binivîse û çima ew li ser te effected bike.',
          'xpReward': 200,
          'type': 'mental'
        },
        {
          'id': 'D38T3',
          'titleEn': 'Practice 20 minutes of mindful eating',
          'titleAr': 'مارس الأكل الواعي لمدة 20 دقيقة',
          'titleKu': '20 xulekî xwarina zana bikin',
          'descriptionEn': 'Eat one meal slowly and mindfully, noticing every taste and texture.',
          'descriptionAr': 'تناول وجبة ببطء وبوعي، لاحظ كل نكهة وملمس.',
          'descriptionKu': 'Taybetêkî bi hêdî û bi zanînê bixwe, her tam û teqeyê hîs bike.',
          'xpReward': 200,
          'type': 'spiritual'
        }
      ];
    case 39:
      return [
        {
          'id': 'D39T1',
          'titleEn': 'Run 8 kilometers',
          'titleAr': 'اركض 8 كيلومترات',
          'titleKu': '8 kilometer berbiçîne',
          'descriptionEn': 'Run 8 kilometers. You are getting stronger every day!',
          'descriptionAr': 'اركض 8 كيلومترات. أنت تزداد قوة كل يوم!',
          'descriptionKu': 'Di 8 kilometer de berbiçîne. Hûn bi her rojê hêdîtir dibin!',
          'xpReward': 205,
          'type': 'physical'
        },
        {
          'id': 'D39T2',
          'titleEn': 'Practice assertive communication',
          'titleAr': 'مارس التواصل الحازم',
          'titleKu': 'Guharkirinê hêz bike',
          'descriptionEn': 'Express your needs clearly and respectfully in one conversation today.',
          'descriptionAr': 'عبّر عن احتياجاتك بوضوح واحترام في محادثة واحدة اليوم.',
          'descriptionKu': 'Di axaftinekê de hûnixazîyên xwe bi rastî û bi hêz bêje.',
          'xpReward': 205,
          'type': 'social'
        },
        {
          'id': 'D39T3',
          'titleEn': 'Fast for 20 hours',
          'titleAr': 'صم لمدة 20 ساعة',
          'titleKu': '20 saetan rûçik bixe',
          'descriptionEn': 'Try a 20-hour fast. Eat one large meal at the end.',
          'descriptionAr': 'جرّب صيام 20 ساعة. تناول وجبة كبيرة في النهاية.',
          'descriptionKu': 'Rûçika 20 saetan bikin. Di dawitê de taybetêkî mezin bixwe.',
          'xpReward': 205,
          'type': 'discipline'
        }
      ];
    case 40:
      return [
        {
          'id': 'D40T1',
          'titleEn': 'Complete a 55-minute workout',
          'titleAr': 'أكمل تمريناً رياضياً لمدة 55 دقيقة',
          'titleKu': '55 xulekî karê vîrajyana bike',
          'descriptionEn': 'Push yourself with a 55-minute high-intensity workout.',
          'descriptionAr': 'تحدى نفسك بتمرين عالي الكثافة لمدة 55 دقيقة.',
          'descriptionKu': '55 xulekî karê vîrajyana bilind bi qencî bike.',
          'xpReward': 210,
          'type': 'physical'
        },
        {
          'id': 'D40T2',
          'titleEn': 'Review and update your life goals',
          'titleAr': 'راجع وحدّث أهداف حياتك',
          'titleKu': 'Armanca jîyanê te lê serek bike',
          'descriptionEn': 'Spend 30 minutes reviewing and updating your long-term goals.',
          'descriptionAr': 'اقضِ 30 دقيقة في مراجعة وتحديث أهدافك طويلة المدى.',
          'descriptionKu': 'Di 30 xulekê de li ser armanca xwe ya dirêj lê serek bike.',
          'xpReward': 210,
          'type': 'mental'
        },
        {
          'id': 'D40T3',
          'titleEn': 'Practice a spiritual ritual for 30 minutes',
          'titleAr': 'مارس طقوساً روحانية لمدة 30 دقيقة',
          'titleKu': '30 xulekî rêkeke ruhî bike',
          'descriptionEn': 'Engage in a meaningful spiritual practice for 30 minutes.',
          'descriptionAr': 'شارك في ممارسة روحانية ذات معنى لمدة 30 دقيقة.',
          'descriptionKu': 'Di 30 xulekê de li ser çalakiyêke ruhî ya bi manayêî bikin.',
          'xpReward': 210,
          'type': 'spiritual'
        }
      ];
    default:
      return [];
  }
}

// Stage 9: Days 41-45 (Mental Resilience)
List<Map<String, dynamic>> _stage9(int day) {
  switch (day) {
    case 41:
      return [
        {
          'id': 'D41T1',
          'titleEn': 'Run 9 kilometers',
          'titleAr': 'اركض 9 كيلومترات',
          'titleKu': '9 kilometer berbiçîne',
          'descriptionEn': 'Run 9 kilometers. Almost at 10K!',
          'descriptionAr': 'اركض 9 كيلومترات. تقترب من 10 كيلومترات!',
          'descriptionKu': 'Di 9 kilometer de berbiçîne. Comekî ji 10K dûr nîn!',
          'xpReward': 215,
          'type': 'physical'
        },
        {
          'id': 'D41T2',
          'titleEn': 'Practice cognitive reframing',
          'titleAr': 'مارس إعادة هيكلة الإدراك',
          'titleKu': 'Rûherkirina dîtînê nû bikin',
          'descriptionEn': 'Take a negative situation and find 3 possible positive interpretations.',
          'descriptionAr': 'خذ موقفاً سلابياً وابحث عن 3 تفسيرات إيجابية ممكنة.',
          'descriptionKu': 'Rewşêkî negatîv bixwe û 3 rûherkirina ecêb pêç bikir.',
          'xpReward': 215,
          'type': 'mental'
        },
        {
          'id': 'D41T3',
          'titleEn': 'Organize your digital files',
          'titleAr': 'نظّف ملفاتك الرقمية',
          'titleKu': 'Pelên dîjîtal paqij bike',
          'descriptionEn': 'Clean up your computer files, photos, and emails.',
          'descriptionAr': 'نظّف ملفاتك وصورك وبريدك الإلكتروني على الكمبيوتر.',
          'descriptionKu': 'Pelên komputer, wêne û e-maîlê xwe paqij bike.',
          'xpReward': 215,
          'type': 'discipline'
        }
      ];
    case 42:
      return [
        {
          'id': 'D42T1',
          'titleEn': 'Do 200 squats throughout the day',
          'titleAr': 'افعل 200 squat على مدار اليوم',
          'titleKu': '200 zimanî di roja de bike',
          'descriptionEn': 'Complete 200 squats throughout the day.',
          'descriptionAr': 'أكمل 200 تمرين squat على مدار اليوم.',
          'descriptionKu': '200 zimanî di roja de bi qencî bike.',
          'xpReward': 220,
          'type': 'physical'
        },
        {
          'id': 'D42T2',
          'titleEn': 'Practice delayed gratification',
          'titleAr': 'مارس المكافأة المتأخرة',
          'titleKu': 'Pirsgiriyê bi hêdî bikin',
          'descriptionEn': 'Delay a pleasure or reward by 2 hours. Notice how it feels.',
          'descriptionAr': 'أجّل متعة أو مكافأة لمدة ساعتين. لاحظ كيف تشعر.',
          'descriptionKu': 'Heziyê an jî xweşiyê ji 2 saetan ve bike. Hest bike çi dide.',
          'xpReward': 220,
          'type': 'mental'
        },
        {
          'id': 'D42T3',
          'titleEn': 'Write a letter of encouragement to someone',
          'titleAr': 'اكتب رسالة تشجيع لشخص',
          'titleKu': 'Nivîsekî hênik ji bo kesekî bivîse',
          'descriptionEn': 'Write and send a letter encouraging someone who is going through a hard time.',
          'descriptionAr': 'اكتب وأرسلا رسالة تشجيعية لشخص يمر بوقت صعب.',
          'descriptionKu': 'Nivîsekî hênik ji bo kesekî ku di demê sêdî de ye bivîse û vêze.',
          'xpReward': 220,
          'type': 'social'
        }
      ];
    case 43:
      return [
        {
          'id': 'D43T1',
          'titleEn': 'Bike for 60 minutes',
          'titleAr': 'اركب الدراجة لمدة 60 دقيقة',
          'titleKu': '60 xulekî bisikletê bike',
          'descriptionEn': 'Ride for 60 minutes at a challenging pace.',
          'descriptionAr': 'اركب لمدة 60 دقيقة بسرعة تحدٍ.',
          'descriptionKu': 'Di 60 xulekê de bisikletê bi hevediyariyê teqîneyê bike.',
          'xpReward': 225,
          'type': 'physical'
        },
        {
          'id': 'D43T2',
          'titleEn': 'Create a problem-solving framework',
          'titleAr': 'أنشئ إطاراً لحل المشكلات',
          'titleKu': 'Çarçoveyêkî çarekirina pirsgiriyê çê bike',
          'descriptionEn': 'Write down a 5-step framework for solving problems in your life.',
          'descriptionAr': 'اكتب إطاراً من 5 خطوات لحل المشكلات في حياتك.',
          'descriptionKu': 'Li ser 5 gavên çarekirina pirsgiriyên te di jîyanê de lê serek bike.',
          'xpReward': 225,
          'type': 'mental'
        },
        {
          'id': 'D43T3',
          'titleEn': 'Perform a act of charity',
          'titleAr': 'افعل عملاً خيرياً',
          'titleKu': 'Karekî xweş bike',
          'descriptionEn': 'Give something valuable (time, money, or effort) to someone in need.',
          'descriptionAr': 'أعطِ شيئاً ذا قيمة (وقت أو مال أو جهد) لشخص محتاج.',
          'descriptionKu': 'Tiştîkî bi nirxê ji bo kesekî pêdivî bike (dem, pere an jî ezmûn).',
          'xpReward': 225,
          'type': 'spiritual'
        }
      ];
    case 44:
      return [
        {
          'id': 'D44T1',
          'titleEn': 'Run 10 kilometers',
          'titleAr': 'اركض 10 كيلومترات',
          'titleKu': '10 kilometer berbiçîne',
          'descriptionEn': 'Run 10 kilometers! This is a major milestone!',
          'descriptionAr': 'اركض 10 كيلومترات! هذه نقطة تحوّل رئيسية!',
          'descriptionKu': 'Di 10 kilometer de berbiçîne! Ev qadêke sereke ye!',
          'xpReward': 230,
          'type': 'physical'
        },
        {
          'id': 'D44T2',
          'titleEn': 'Practice visualization for 15 minutes',
          'titleAr': 'مارس التخيل لمدة 15 دقيقة',
          'titleKu': '15 xulekî xeyal bikein',
          'descriptionEn': 'Close your eyes and visualize yourself achieving your goals in detail.',
          'descriptionAr': 'أغمض عينيك وتخيل نفسك تحقق أهدافك بالتفصيل.',
          'descriptionKu': 'Çavên xwe tike û xeyal bike ku hûn armanca te bi qencî dikin.',
          'xpReward': 230,
          'type': 'mental'
        },
        {
          'id': 'D44T3',
          'titleEn': 'Reconnect with your spiritual practice',
          'titleAr': 'أعد الاتصال بممارستك الروحانية',
          'titleKu': 'Dîtinê nû bi çalakiyê ruhî te bikin',
          'descriptionEn': 'Engage deeply with a spiritual practice that is meaningful to you.',
          'descriptionAr': 'شارك بعمق في ممارسة روحانية ذات معنى لك.',
          'descriptionKu': 'Bi çalakiyêke ruhî ya ku bi manayêî ye li ser te bikin.',
          'xpReward': 230,
          'type': 'spiritual'
        }
      ];
    case 45:
      return [
        {
          'id': 'D45T1',
          'titleEn': 'Do a 60-minute workout',
          'titleAr': 'أكمل تمريناً رياضياً لمدة 60 دقيقة',
          'titleKu': '60 xulekî karê vîrajyana bike',
          'descriptionEn': 'Complete a 60-minute workout. Halfway through the program!',
          'descriptionAr': 'أكمل تمريناً رياضياً لمدة 60 دقيقة. أنت في منتصف البرنامج!',
          'descriptionKu': '60 xulekî karê vîrajyana bike. Hûn di nîvê bermayana programê de!',
          'xpReward': 235,
          'type': 'physical'
        },
        {
          'id': 'D45T2',
          'titleEn': 'Reflect on your progress over 45 days',
          'titleAr': 'تأمل في تقدمك خلال 45 يوماً',
          'titleKu': 'Li ser pêşkeftina te di 45 rojan de rû bike',
          'descriptionEn': 'Write about how you have changed and grown over the past 45 days.',
          'descriptionAr': 'اكتب عن كيف تغيّرت ونموت خلال آخر 45 يوماً.',
          'descriptionKu': 'Li ser çima te di 45 rojan de diguhere û mezin dibin binivîse.',
          'xpReward': 235,
          'type': 'mental'
        },
        {
          'id': 'D45T3',
          'titleEn': 'Plan a social activity for next week',
          'titleAr': 'خطط لنشاط اجتماعي للأسبوع القادم',
          'titleKu': 'Çalakiyêkî sosyal ji bo heftayê pêş plan bike',
          'descriptionEn': 'Plan a meaningful social activity to do with others next week.',
          'descriptionAr': 'خطط لنشاط اجتماعي ذا معنى لفعله مع الآخرين الأسبوع القادم.',
          'descriptionKu': 'Çalakiyêkî sosyal ya bi manayêî ji bo heftayê pêş bi kesên din re plan bike.',
          'xpReward': 235,
          'type': 'social'
        }
      ];
    default:
      return [];
  }
}

// Stage 10: Days 46-50 (Social Leadership)
List<Map<String, dynamic>> _stage10(int day) {
  switch (day) {
    case 46:
      return [
        {
          'id': 'D46T1',
          'titleEn': 'Do 250 push-ups throughout the day',
          'titleAr': 'افعل 250 ضغط على مدار اليوم',
          'titleKu': '250 bendekirinê di roja de bike',
          'descriptionEn': 'Complete 250 push-ups throughout the day.',
          'descriptionAr': 'أكمل 250 تمرين ضغط على مدار اليوم.',
          'descriptionKu': '250 bendekirinê di roja de bi qencî bike.',
          'xpReward': 240,
          'type': 'physical'
        },
        {
          'id': 'D46T2',
          'titleEn': 'Mentor someone younger or less experienced',
          'titleAr': 'كن مرشداً لشخص أصغر أو أقل خبرة',
          'titleKu': 'Kesekî ciwan an jî kêm ezmûnî bûyî',
          'descriptionEn': 'Offer guidance and support to someone who is starting their journey.',
          'descriptionAr': 'اعرض التوجيه والدعم لشخص يبدأ رحلته.',
          'descriptionKu': 'Alîkariya kesekî ku destê seferê xwe dike pêşniyar bike.',
          'xpReward': 240,
          'type': 'social'
        },
        {
          'id': 'D46T3',
          'titleEn': 'Practice patience for a full day',
          'titleAr': 'مارس الصبر ليوم كامل',
          'titleKu': 'Di rojêkê de sabir bike',
          'descriptionEn': 'Consciously practice patience in every interaction today.',
          'descriptionAr': 'مارس الص버 بوعي في كل تفاعل اليوم.',
          'descriptionKu': 'Di her têkiliyê de bi zanînê sabir bike.',
          'xpReward': 240,
          'type': 'spiritual'
        }
      ];
    case 47:
      return [
        {
          'id': 'D47T1',
          'titleEn': 'Run 11 kilometers',
          'titleAr': 'اركض 11 كيلومتر',
          'titleKu': '11 kilometer berbiçîne',
          'descriptionEn': 'Run 11 kilometers. You are becoming a strong runner!',
          'descriptionAr': 'اركض 11 كيلومتر. أنت تصبح عداء قوياً!',
          'descriptionKu': 'Di 11 kilometer de berbiçîne. Hûn bi hêdî dibin bi berbiçînekî hêzdar!',
          'xpReward': 245,
          'type': 'physical'
        },
        {
          'id': 'D47T2',
          'titleEn': 'Organize a group activity',
          'titleAr': 'نظّم نشاطاً جماعياً',
          'titleKu': 'Çalakiyêkî komekê pêşdeng bike',
          'descriptionEn': 'Plan and organize an activity for friends or family.',
          'descriptionAr': 'خطط ونظّم نشاطاً لأصدقائك أو عائلتك.',
          'descriptionKu': 'Çalakiyêkî ji bo heval an jî malbatê plan bike û pêşdeng bike.',
          'xpReward': 245,
          'type': 'social'
        },
        {
          'id': 'D47T3',
          'titleEn': 'Write your personal mission statement',
          'titleAr': 'اكتب بيان رسالتك الشخصية',
          'titleKu': 'Daxwaznameyê personal xwe nivîse',
          'descriptionEn': 'Refine and finalize your personal mission statement.',
          'descriptionAr': 'حسّن وأكمل بيان رسالتك الشخصية.',
          'descriptionKu': 'Daxwaznameyê personal xwe bi qencî bike.',
          'xpReward': 245,
          'type': 'mental'
        }
      ];
    case 48:
      return [
        {
          'id': 'D48T1',
          'titleEn': 'Do 100 burpees',
          'titleAr': 'افعل 100 burpee',
          'titleKu': '100 burpee bike',
          'descriptionEn': 'Complete 100 burpees throughout the day. This is a real challenge!',
          'descriptionAr': 'أكمل 100 burpee على مدار اليوم. هذا تحدٍ حقيقي!',
          'descriptionKu': '100 burpee di roja de bi qencî bike. Ev teqînekî rastî ye!',
          'xpReward': 250,
          'type': 'physical'
        },
        {
          'id': 'D48T2',
          'titleEn': 'Practice empathy with a difficult person',
          'titleAr': 'مارس التعاطف مع شخص صعب',
          'titleKu': 'Bi kesêkî dengbêjî re hênikî bike',
          'descriptionEn': 'Try to understand the perspective of someone you find difficult.',
          'descriptionAr': 'حاول فهم وجهة نظر شخص تجده صعباً.',
          'descriptionKu': 'Dîtina kesêkî ku hûn dibînin dengbêjî ye fihîne.',
          'xpReward': 250,
          'type': 'social'
        },
        {
          'id': 'D48T3',
          'titleEn': 'Fast for 24 hours',
          'titleAr': 'صم لمدة 24 ساعة',
          'titleKu': '24 saetan rûçik bixe',
          'descriptionEn': 'Complete a 24-hour fast. Drink water only.',
          'descriptionAr': 'أكمل صيام 24 ساعة. اشرب الماء فقط.',
          'descriptionKu': 'Rûçika 24 saetan bi qencî bike. Tenê av bixwe.',
          'xpReward': 250,
          'type': 'discipline'
        }
      ];
    case 49:
      return [
        {
          'id': 'D49T1',
          'titleEn': 'Swim for 50 minutes',
          'titleAr': 'سبح لمدة 50 دقيقة',
          'titleKu': '50 xulekî bavêje',
          'descriptionEn': 'Swim for 50 minutes continuously.',
          'descriptionAr': 'سبح لمدة 50 دقيقة بشكل متواصل.',
          'descriptionKu': 'Di 50 xulekê de bi temamî bavêje.',
          'xpReward': 255,
          'type': 'physical'
        },
        {
          'id': 'D49T2',
          'titleEn': 'Give a speech or presentation',
          'titleAr': 'ألقِ خطاباً أو عرضاً',
          'titleKu': 'Vêranêkî an jî pêşkêşî bike',
          'descriptionEn': 'Prepare and deliver a short speech or presentation to others.',
          'descriptionAr': 'حضّر وألقِ خطاباً قصيراً أو عرضاً للآخرين.',
          'descriptionKu': 'Vêranêkî kêm amade bike û bo kesên din pêşkêş bike.',
          'xpReward': 255,
          'type': 'social'
        },
        {
          'id': 'D49T3',
          'titleEn': 'Create a personal development plan',
          'titleAr': 'أنشئ خطة تطوير شخصي',
          'titleKu': 'Planê pêşkeftina personal çê bike',
          'descriptionEn': 'Design a detailed plan for your continued growth over the next 45 days.',
          'descriptionAr': 'صمم خطة مفصلة لنموك المستمر خلال الـ 45 يوماً القادمة.',
          'descriptionKu': 'Planêkî qetayê ji bo pêşkeftina te ya piştî 45 rojan bike.',
          'xpReward': 255,
          'type': 'mental'
        }
      ];
    case 50:
      return [
        {
          'id': 'D50T1',
          'titleEn': 'Do a 65-minute workout',
          'titleAr': 'أكمل تمريناً رياضياً لمدة 65 دقيقة',
          'titleKu': '65 xulekî karê vîrajyana bike',
          'descriptionEn': 'Complete a challenging 65-minute workout session.',
          'descriptionAr': 'أكمل جلسة تمرين صعبة لمدة 65 دقيقة.',
          'descriptionKu': '65 xulekî karê vîrajyana bike bi teqîneyê.',
          'xpReward': 260,
          'type': 'physical'
        },
        {
          'id': 'D50T2',
          'titleEn': 'Host a gathering or dinner',
          'titleAr': 'نظّم تجمعاً أو عشاء',
          'titleKu': 'Komekê an jî şilavê pêşdeng bike',
          'descriptionEn': 'Invite friends or family for a gathering or dinner.',
          'descriptionAr': 'ادعُ أصدقاء أو عائلة لتجمّع أو عشاء.',
          'descriptionKu': 'Heval an jî malbatê ji bo komekê an jî şilavê belav bike.',
          'xpReward': 260,
          'type': 'social'
        },
        {
          'id': 'D50T3',
          'titleEn': 'Practice a 30-minute meditation',
          'titleAr': 'مارس تأملاً لمدة 30 دقيقة',
          'titleKu': '30 xulekî ragihandinê bike',
          'descriptionEn': 'Sit in deep meditation for 30 minutes.',
          'descriptionAr': 'اجلس في تأمل عميق لمدة 30 دقيقة.',
          'descriptionKu': 'Di 30 xulekê de bi dengbêjî binihîtin.',
          'xpReward': 260,
          'type': 'spiritual'
        }
      ];
    default:
      return [];
  }
}

// Stage 11: Days 51-55 (Advanced Discipline)
List<Map<String, dynamic>> _stage11(int day) {
  switch (day) {
    case 51:
      return [
        {
          'id': 'D51T1',
          'titleEn': 'Run 12 kilometers',
          'titleAr': 'اركض 12 كيلومتر',
          'titleKu': '12 kilometer berbiçîne',
          'descriptionEn': 'Run 12 kilometers at a strong pace.',
          'descriptionAr': 'اركض 12 كيلومتر بسرعة قوية.',
          'descriptionKu': 'Di 12 kilometer de bi hevediyariyê hêzdar berbiçîne.',
          'xpReward': 265,
          'type': 'physical'
        },
        {
          'id': 'D51T2',
          'titleEn': 'Practice digital detox for 4 hours',
          'titleAr': 'مارس التخلص الرقمي لمدة 4 ساعات',
          'titleKu': '4 saetan bêyî dîjîtal bimîne',
          'descriptionEn': 'Stay away from all screens and digital devices for 4 hours.',
          'descriptionAr': 'ابقَ بعيداً عن جميع الشاشات والأجهزة الرقمية لمدة 4 ساعات.',
          'descriptionKu': 'Di 4 saetan de ji hemû dîtir û amûrên dîjîtal dûr bimîne.',
          'xpReward': 265,
          'type': 'mental'
        },
        {
          'id': 'D51T3',
          'titleEn': 'Create a budget and financial plan',
          'titleAr': 'أنشئ ميزانية وخطة مالية',
          'titleKu': 'Bûtçe an jî planê dîwana xwe çê bike',
          'descriptionEn': 'Create a detailed budget and financial plan for the next month.',
          'descriptionAr': 'أنشئ ميزانية وخطة مالية مفصلة للشهر القادم.',
          'descriptionKu': 'Bûtçe an jî planê dîwana xwe ya mehê pêş qetayê çê bike.',
          'xpReward': 265,
          'type': 'discipline'
        }
      ];
    case 52:
      return [
        {
          'id': 'D52T1',
          'titleEn': 'Do 300 push-ups throughout the day',
          'titleAr': 'افعل 300 ضغط على مدار اليوم',
          'titleKu': '300 bendekirinê di roja de bike',
          'descriptionEn': 'Complete 300 push-ups throughout the day. This is elite level!',
          'descriptionAr': 'أكمل 300 تمرين ضغط على مدار اليوم. هذا مستوى النخبة!',
          'descriptionKu': '300 bendekirinê di roja de bi qencî bike. Ev asta elîetê ye!',
          'xpReward': 270,
          'type': 'physical'
        },
        {
          'id': 'D52T2',
          'titleEn': 'Lead a group discussion or activity',
          'titleAr': 'قاد نقاشاً أو نشاطاً جماعياً',
          'titleKu': 'Axaftinekî komekê an jî çalakiyêkî destek bike',
          'descriptionEn': 'Take the lead in organizing and facilitating a group activity.',
          'descriptionAr': 'تولَّ قيادة تنظيم وتسهيل نشاط جماعي.',
          'analysis': null,
          'descriptionKu': 'Li ser pêşdengkirina çalakiyêkî komekê destek bike.',
          'xpReward': 270,
          'type': 'social'
        },
        {
          'id': 'D52T3',
          'titleEn': 'Practice deep spiritual reflection',
          'titleAr': 'مارس التأمل الروحي العميق',
          'titleKu': 'Ragihandinê ruhî dengbêjî bike',
          'descriptionEn': 'Spend 30 minutes in deep spiritual reflection and prayer.',
          'descriptionAr': 'اقضِ 30 دقيقة في التأمل الروحي العميق والصلاة.',
          'descriptionKu': 'Di 30 xulekê de ragihandinê ruhî û namê dengbêjî bike.',
          'xpReward': 270,
          'type': 'spiritual'
        }
      ];
    case 53:
      return [
        {
          'id': 'D53T1',
          'titleEn': 'Run 13 kilometers',
          'titleAr': 'اركض 13 كيلومتر',
          'titleKu': '13 kilometer berbiçîne',
          'descriptionEn': 'Run 13 kilometers. You are unstoppable!',
          'descriptionAr': 'اركض 13 كيلومتر. لا يمكن إيقافك!',
          'descriptionKu': 'Di 13 kilometer de berbiçîne. Hûn netekî nabin!',
          'xpReward': 275,
          'type': 'physical'
        },
        {
          'id': 'D53T2',
          'titleEn': 'Write about your core values',
          'titleAr': 'اكتب عن قيمك الأساسية',
          'titleKu': 'Li ser nirxên bingehî binivîse',
          'descriptionEn': 'Write a detailed essay about your core values and how they guide your life.',
          'descriptionAr': 'اكتب مقالاً مفصلاً عن قيمك الأساسية وكيف توجه حياتك.',
          'descriptionKu': 'Li ser nirxên bingehî û çima ew jîyanê te dihilatîne qetayê binivîse.',
          'xpReward': 275,
          'type': 'mental'
        },
        {
          'id': 'D53T3',
          'titleEn': 'Organize a community service project',
          'titleAr': 'نظّم مشروعاً للخدمة المجتمعية',
          'titleKu': 'Proyektekî xizmetê komelexanê pêşdeng bike',
          'descriptionEn': 'Plan and organize a community service project.',
          'descriptionAr': 'خطط ونظّم مشروعاً للخدمة المجتمعية.',
          'descriptionKu': 'Proyektekî xizmetê komelexanê plan bike û pêşdeng bike.',
          'xpReward': 275,
          'type': 'social'
        }
      ];
    case 54:
      return [
        {
          'id': 'D54T1',
          'titleEn': 'Do a 70-minute workout',
          'titleAr': 'أكمل تمريناً رياضياً لمدة 70 دقيقة',
          'titleKu': '70 xulekî karê vîrajyana bike',
          'descriptionEn': 'Complete a 70-minute high-intensity workout.',
          'descriptionAr': 'أكمل تمريناً عالي الكثافة لمدة 70 دقيقة.',
          'descriptionKu': '70 xulekî karê vîrajyana bilind bi qencî bike.',
          'xpReward': 280,
          'type': 'physical'
        },
        {
          'id': 'D54T2',
          'titleEn': 'Practice advanced problem-solving',
          'titleAr': 'مارس حل المشكلات المتقدم',
          'titleKu': 'Çarekirina pirsgiriyên pêşveçûn bikin',
          'descriptionEn': 'Tackle a complex problem in your life using structured thinking.',
          'descriptionAr': 'تغلّب على مشكلة معقدة في حياتك باستخدام التفكير المنظم.',
          'descriptionKu': 'Pirsgiriyêkî dengbêjî di jîyanê de bi rûherkirinê bikarîner bikin.',
          'xpReward': 280,
          'type': 'mental'
        },
        {
          'id': 'D54T3',
          'titleEn': 'Fast for 36 hours',
          'titleAr': 'صم لمدة 36 ساعة',
          'titleKu': '36 saetan rûçik bixe',
          'descriptionEn': 'Try a 36-hour fast. This requires strong willpower.',
          'descriptionAr': 'جرّب صيام 36 ساعة. هذا يتطلب قوة إرادة كبيرة.',
          'descriptionKu': 'Rûçika 36 saetan bikin. Ev hêza xwezayê mezin dipêvîne.',
          'xpReward': 280,
          'type': 'discipline'
        }
      ];
    case 55:
      return [
        {
          'id': 'D55T1',
          'titleEn': 'Run 14 kilometers',
          'titleAr': 'اركض 14 كيلومتر',
          'titleKu': '14 kilometer berbiçîne',
          'descriptionEn': 'Run 14 kilometers. Half marathon distance!',
          'descriptionAr': 'اركض 14 كيلومتر. مسافة نصف ماراثون!',
          'descriptionKu': 'Di 14 kilometer de berbiçîne. Mesafa nîv maratona ye!',
          'xpReward': 285,
          'type': 'physical'
        },
        {
          'id': 'D55T2',
          'titleEn': 'Teach a workshop or class',
          'titleAr': 'قدّم ورشة عمل أو حصة تدريس',
          'titleKu': 'Workshop an jî dersê fêr bike',
          'descriptionEn': 'Prepare and teach a short workshop or class to others.',
          'descriptionAr': 'حضّر وقدّم ورشة عمل قصيرة أو حصة تدريس للآخرين.',
          'descriptionKu': 'Workshop an jî dersêkî kêm amade bike û bo kesên din fêr bike.',
          'xpReward': 285,
          'type': 'social'
        },
        {
          'id': 'D55T3',
          'titleEn': 'Create a gratitude jar',
          'titleAr': 'أنشئ زجاجة شكر',
          'titleKu': 'Dawîyeke şukrê çê bike',
          'descriptionEn': 'Create a gratitude jar and write one thing you are grateful for today.',
          'descriptionAr': 'أنشئ زجاجة شكر واكتب شيئاً واحداً أنت ممتن له اليوم.',
          'descriptionKu': 'Dawîyeke şukrê çê bike û tiştêkî ku hûn piştgînî û heye binivîse.',
          'xpReward': 285,
          'type': 'spiritual'
        }
      ];
    default:
      return [];
  }
}

// Stage 12: Days 56-60 (Spiritual Mastery)
List<Map<String, dynamic>> _stage12(int day) {
  switch (day) {
    case 56:
      return [
        {
          'id': 'D56T1',
          'titleEn': 'Run 15 kilometers',
          'titleAr': 'اركض 15 كيلومتر',
          'titleKu': '15 kilometer berbiçîne',
          'descriptionEn': 'Run 15 kilometers. You are an endurance athlete now!',
          'descriptionAr': 'اركض 15 كيلومتر. أنت رياضي تحمٍ الآن!',
          'descriptionKu': 'Di 15 kilometer de berbiçîne. Hûn niha vîrajyana hewildarîyê dibin!',
          'xpReward': 290,
          'type': 'physical'
        },
        {
          'id': 'D56T2',
          'titleEn': 'Practice 40 minutes of deep work',
          'titleAr': 'مارس 40 دقيقة من العمل العميق',
          'titleKu': '40 xulekî karê dengbêjî bike',
          'descriptionEn': 'Work on your most important project for 40 minutes with total focus.',
          'descriptionAr': 'اعمل على أهم مشروع لديك لمدة 40 دقيقة بتركيز كامل.',
          'descriptionKu': 'Di 40 xulekê de li ser proyekta sereke te li ser fokus absolut bike.',
          'xpReward': 290,
          'type': 'mental'
        },
        {
          'id': 'D56T3',
          'titleEn': 'Spend an hour in silent meditation',
          'titleAr': 'اقضِ ساعة في تأمل صامت',
          'titleKu': 'Di 1 saetan de ragihandinê dengbike bike',
          'descriptionEn': 'Spend one full hour in silent meditation or prayer.',
          'descriptionAr': 'اقضِ ساعة كاملة في تأمل صامت أو صلاة.',
          'descriptionKu': 'Di 1 saetan de ragihandinê dengbike an jî namê bi aramî bike.',
          'xpReward': 290,
          'type': 'spiritual'
        }
      ];
    case 57:
      return [
        {
          'id': 'D57T1',
          'titleEn': 'Do 350 push-ups throughout the day',
          'titleAr': 'افعل 350 ضغط على مدار اليوم',
          'titleKu': '350 bendekirinê di roja de bike',
          'descriptionEn': 'Complete 350 push-ups throughout the day.',
          'descriptionAr': 'أكمل 350 تمرين ضغط على مدار اليوم.',
          'descriptionKu': '350 bendekirinê di roja de bi qencî bike.',
          'xpReward': 295,
          'type': 'physical'
        },
        {
          'id': 'D57T2',
          'titleEn': 'Practice forgiveness meditation',
          'titleAr': 'مارس تأمل المغفرة',
          'titleKu': 'Ragihandinê bûyîkirinê bikin',
          'descriptionEn': 'Meditate for 20 minutes focusing on forgiving yourself and others.',
          'descriptionAr': 'تأمل لمدة 20 دقيقة مع التركيز على مغفرة نفسك والآخرين.',
          'descriptionKu': 'Di 20 xulekê de ragihandinê bûyîkirinê ji bo xwe û kesên din bikin.',
          'xpReward': 295,
          'type': 'spiritual'
        },
        {
          'id': 'D57T3',
          'titleEn': 'Create a legacy statement',
          'titleAr': 'أنشئ بياناً للميراث',
          'titleKu': 'Daxwaznameyê mirathê çê bike',
          'descriptionEn': 'Write about what legacy you want to leave behind.',
          'descriptionAr': 'اكتب عن الميراث الذي تريد تركه.',
          'descriptionKu': 'Li ser mirathê ku hûn dixwazin jê bimîne binivîse.',
          'xpReward': 295,
          'type': 'mental'
        }
      ];
    case 58:
      return [
        {
          'id': 'D58T1',
          'titleEn': 'Complete a 75-minute workout',
          'titleAr': 'أكمل تمريناً رياضياً لمدة 75 دقيقة',
          'titleKu': '75 xulekî karê vîrajyana bike',
          'descriptionEn': 'Push through a 75-minute intense workout.',
          'descriptionAr': 'تحدى نفسك بتمرين مكثف لمدة 75 دقيقة.',
          'descriptionKu': '75 xulekî karê vîrajyana bilind bi qencî bike.',
          'xpReward': 300,
          'type': 'physical'
        },
        {
          'id': 'D58T2',
          'titleEn': 'Write a letter to your future self',
          'titleAr': 'اكتب رسالة لذاتك المستقبلية',
          'titleKu': 'Nivîsekî ji bo xwe ya piştî 30 roj bivîse',
          'descriptionEn': 'Write a letter to yourself to be opened in 30 days.',
          'descriptionAr': 'اكتب رسالة لنفسك لتُفتح بعد 30 يوماً.',
          'descriptionKu': 'Nivîsekî ji bo xwe bivîse ku piştî 30 roj were vekirin.',
          'xpReward': 300,
          'type': 'mental'
        },
        {
          'id': 'D58T3',
          'titleEn': 'Practice charity for a full day',
          'titleAr': 'مارس الإحسان ليوم كامل',
          'titleKu': 'Di rojêkê de xweşî bike',
          'descriptionEn': 'Perform acts of charity and kindness throughout the entire day.',
          'descriptionAr': 'افعل أعمال الخير واللطف على مدار اليوم بالكامل.',
          'descriptionKu': 'Di hemû roja de xweşî û hênikî bike.',
          'xpReward': 300,
          'type': 'spiritual'
        }
      ];
    case 59:
      return [
        {
          'id': 'D59T1',
          'titleEn': 'Run 16 kilometers',
          'titleAr': 'اركض 16 كيلومتر',
          'titleKu': '16 kilometer berbiçîne',
          'descriptionEn': 'Run 16 kilometers. You are incredible!',
          'descriptionAr': 'اركض 16 كيلومتر. أنت مذهل!',
          'descriptionKu': 'Di 16 kilometer de berbiçîne. Hûn bêqetî dibin!',
          'xpReward': 305,
          'type': 'physical'
        },
        {
          'id': 'D59T2',
          'titleEn': 'Mentor 3 people',
          'titleAr': 'كن مرشداً لـ 3 أشخاص',
          'titleKu': '3 kesan bûyî',
          'descriptionEn': 'Offer guidance and support to 3 different people.',
          'descriptionAr': 'اعرض التوجيه والدعم على 3 أشخاص مختلفين.',
          'descriptionKu': 'Alîkariya 3 kesên cuda pêşniyar bike.',
          'xpReward': 305,
          'type': 'social'
        },
        {
          'id': 'D59T3',
          'titleEn': 'Create a spiritual practice routine',
          'titleAr': 'أنشئ روتيناً للممارسة الروحانية',
          'titleKu': 'Rutînekî çalakiyê ruhî çê bike',
          'descriptionEn': 'Design a daily spiritual practice routine for the next 30 days.',
          'descriptionAr': 'صمم روتيناً يومياً للممارسة الروحانية للـ 30 يوماً القادمة.',
          'descriptionKu': 'Rutînekî rojane ji bo çalakiyê ruhî li ser 30 rojan pêş çê bike.',
          'xpReward': 305,
          'type': 'spiritual'
        }
      ];
    case 60:
      return [
        {
          'id': 'D60T1',
          'titleEn': 'Do 400 push-ups throughout the day',
          'titleAr': 'افعل 400 ضغط على مدار اليوم',
          'titleKu': '400 bendekirinê di roja de bike',
          'descriptionEn': 'Complete 400 push-ups throughout the day. Champion level!',
          'descriptionAr': 'أكمل 400 تمرين ضغط على مدار اليوم. مستوى البطل!',
          'descriptionKu': '400 bendekirinê di roja de bi qencî bike. Asta qeybalî ye!',
          'xpReward': 310,
          'type': 'physical'
        },
        {
          'id': 'D60T2',
          'titleEn': 'Write a comprehensive life review',
          'titleAr': 'اكتب مراجعة شاملة للحياة',
          'titleKu': 'Rêveberiya complete a ji bo jîyanê xwe binivîse',
          'descriptionEn': 'Write a detailed review of your life, growth, and achievements so far.',
          'descriptionAr': 'اكتب مراجعة مفصلة لحياتك ونموك وإنجازاتك حتى الآن.',
          'descriptionKu': 'Li ser jîyan, pêşkeftin û serkeftiyên te heta niha bi qetayê binivîse.',
          'xpReward': 310,
          'type': 'mental'
        },
        {
          'id': 'D60T3',
          'titleEn': 'Plan a spiritual retreat',
          'titleAr': 'خطط لإقامة روحانية',
          'titleKu': 'Sêwirîyêkî ruhî plan bike',
          'descriptionEn': 'Plan a spiritual retreat or intensive practice session for yourself.',
          'descriptionAr': 'خطط لإقامة روحانية أو جلسة ممارسة مكثفة لنفسك.',
          'descriptionKu': 'Sêwirîyêkî ruhî an jî çalakiyêkî intensive ji bo xwe plan bike.',
          'xpReward': 310,
          'type': 'spiritual'
        }
      ];
    default:
      return [];
  }
}

// Stage 13: Days 61-65 (Physical Excellence)
List<Map<String, dynamic>> _stage13(int day) {
  switch (day) {
    case 61:
      return [
        {
          'id': 'D61T1',
          'titleEn': 'Run 17 kilometers',
          'titleAr': 'اركض 17 كيلومتر',
          'titleKu': '17 kilometer berbiçîne',
          'descriptionEn': 'Run 17 kilometers. You are in peak physical condition!',
          'descriptionAr': 'اركض 17 كيلومتر. أنت في أفضل حالة جسدية!',
          'descriptionKu': 'Di 17 kilometer de berbiçîne. Hûn di enîme zêdeyê jismenî de dibin!',
          'xpReward': 315,
          'type': 'physical'
        },
        {
          'id': 'D61T2',
          'titleEn': 'Practice 45 minutes of deep work',
          'titleAr': 'مارس 45 دقيقة من العمل العميق',
          'titleKu': '45 xulekî karê dengbêjî bike',
          'descriptionEn': 'Work with complete focus for 45 minutes on your priority task.',
          'descriptionAr': 'اعمل بتركيز كامل لمدة 45 دقيقة على مهمتك ذات الأولوية.',
          'descriptionKu': 'Di 45 xulekê de li ser karê sereke te bi fokus absolut bike.',
          'xpReward': 315,
          'type': 'mental'
        },
        {
          'id': 'D61T3',
          'titleEn': 'Create a charity project',
          'titleAr': 'أنشئ مشروعاً خيرياً',
          'titleKu': 'Proyektekî xweşî çê bike',
          'descriptionEn': 'Design and launch a small charity or service project.',
          'descriptionAr': 'صمم وأطلق مشروعاً خيرياً صغيراً.',
          'descriptionKu': 'Proyektekî xweşî piçûk çê bike û dest pêke.',
          'xpReward': 315,
          'type': 'social'
        }
      ];
    case 62:
      return [
        {
          'id': 'D62T1',
          'titleEn': 'Do 450 push-ups throughout the day',
          'titleAr': 'افعل 450 ضغط على مدار اليوم',
          'titleKu': '450 bendekirinê di roja de bike',
          'descriptionEn': 'Complete 450 push-ups throughout the day.',
          'descriptionAr': 'أكمل 450 تمرين ضغط على مدار اليوم.',
          'descriptionKu': '450 bendekirinê di roja de bi qencî bike.',
          'xpReward': 320,
          'type': 'physical'
        },
        {
          'id': 'D62T2',
          'titleEn': 'Practice advanced mindfulness',
          'titleAr': 'مارس التأمل المتقدم',
          'titleKu': 'Ragihandinê pêşveçûn bikin',
          'descriptionEn': 'Practice 30 minutes of advanced mindfulness techniques.',
          'descriptionAr': 'مارس تقنيات التأمل المتقدمة لمدة 30 دقيقة.',
          'descriptionKu': 'Di 30 xulekê de teknîkên ragihandinê pêşveçûn bikin.',
          'xpReward': 320,
          'type': 'mental'
        },
        {
          'id': 'D62T3',
          'titleEn': 'Organize a community event',
          'titleAr': 'نظّم حدثاً مجتمعياً',
          'titleKu': 'Pêvajoyêkî komelexanê pêşdeng bike',
          'descriptionEn': 'Plan and organize a community event or gathering.',
          'descriptionAr': 'خطط ونظّم حدثاً أو تجمعاً مجتمعياً.',
          'descriptionKu': 'Pêvajoyêkî komelexanê an jî komekê plan bike û pêşdeng bike.',
          'xpReward': 320,
          'type': 'social'
        }
      ];
    case 63:
      return [
        {
          'id': 'D63T1',
          'titleEn': 'Run 18 kilometers',
          'titleAr': 'اركض 18 كيلومتر',
          'titleKu': '18 kilometer berbiçîne',
          'descriptionEn': 'Run 18 kilometers. You are almost at 20K!',
          'descriptionAr': 'اركض 18 كيلومتر. أنت تقترب من 20 كيلومتر!',
          'descriptionKu': 'Di 18 kilometer de berbiçîne. Hûn comekî ji 20K dûr nîn!',
          'xpReward': 325,
          'type': 'physical'
        },
        {
          'id': 'D63T2',
          'titleEn': 'Write a personal philosophy',
          'titleAr': 'اكتب فلسفتك الشخصية',
          'titleKu': 'Felsefeke personal bivîse',
          'descriptionEn': 'Write a detailed personal philosophy that guides your life.',
          'descriptionAr': 'اكتب فلسفتك الشخصية المفصلة التي توجه حياتك.',
          'descriptionKu': 'Felsefeke personal ya ku jîyanê te dihilatîne bi qetayê bivîse.',
          'xpReward': 325,
          'type': 'mental'
        },
        {
          'id': 'D63T3',
          'titleEn': 'Practice gratitude for a stranger',
          'titleAr': 'مارس الشكر لغريب',
          'titleKu': 'Ji bo kesekî nizanim şukrê bike',
          'descriptionEn': 'Express genuine gratitude to someone you do not know personally.',
          'descriptionAr': 'عبّر عن شكر صادق لشخص لا تعرفه شخصياً.',
          'descriptionKu': 'Ji bo kesekî ku hûn bi wê re nizanim bi rastî şukrê bike.',
          'xpReward': 325,
          'type': 'spiritual'
        }
      ];
    case 64:
      return [
        {
          'id': 'D64T1',
          'titleEn': 'Complete an 80-minute workout',
          'titleAr': 'أكمل تمريناً رياضياً لمدة 80 دقيقة',
          'titleKu': '80 xulekî karê vîrajyana bike',
          'descriptionEn': 'Complete an intense 80-minute workout session.',
          'descriptionAr': 'أكمل جلسة تمرين مكثفة لمدة 80 دقيقة.',
          'descriptionKu': '80 xulekî karê vîrajyana bilind bi qencî bike.',
          'xpReward': 330,
          'type': 'physical'
        },
        {
          'id': 'D64T2',
          'titleEn': 'Lead a meditation session',
          'titleAr': 'قدّم جلسة تأمل',
          'titleKu': 'Çalakiyêkî ragihandinê pêşbikeve',
          'descriptionEn': 'Lead a meditation or prayer session for others.',
          'descriptionAr': 'قدّم جلسة تأمل أو صلاة للآخرين.',
          'descriptionKu': 'Çalakiyêkî ragihandinê an jî namê bo kesên din pêşbikeve.',
          'xpReward': 330,
          'type': 'social'
        },
        {
          'id': 'D64T3',
          'titleEn': 'Fast for 48 hours',
          'titleAr': 'صم لمدة 48 ساعة',
          'titleKu': '48 saetan rûçik bixe',
          'descriptionEn': 'Attempt a 48-hour fast. This is a major mental challenge.',
          'descriptionAr': 'حاول صيام 48 ساعة. هذا تحدٍ ذهني كبير.',
          'descriptionKu': 'Rûçika 48 saetan bikein. Ev teqînekî zihînî mezin ye.',
          'xpReward': 330,
          'type': 'discipline'
        }
      ];
    case 65:
      return [
        {
          'id': 'D65T1',
          'titleEn': 'Run 19 kilometers',
          'titleAr': 'اركض 19 كيلومتر',
          'titleKu': '19 kilometer berbiçîne',
          'descriptionEn': 'Run 19 kilometers. One more kilometer to reach 20K!',
          'descriptionAr': 'اركض 19 كيلومتر. كيلومتر واحد للوصول إلى 20 كيلومتر!',
          'descriptionKu': 'Di 19 kilometer de berbiçîne. 1 kilometer din ji bo 20K!',
          'xpReward': 335,
          'type': 'physical'
        },
        {
          'id': 'D65T2',
          'titleEn': 'Write a thank-you letter to your mentor',
          'titleAr': 'اكتب رسالة شكر لمشرفك',
          'titleKu': 'Nivîsekî şukrê ji bo bûyî te bivîse',
          'descriptionEn': 'Write and send a heartfelt thank-you to someone who mentored you.',
          'descriptionAr': 'اكتب وأرسلا رسالة شكر صادقة لشخص قادك أو رشدك.',
          'descriptionKu': 'Nivîsekî şukrê ji bo kesekî ku te bûyî te kirî bivîse û vêze.',
          'xpReward': 335,
          'type': 'social'
        },
        {
          'id': 'D65T3',
          'titleEn': 'Practice a 45-minute spiritual session',
          'titleAr': 'مارس جلسة روحانية لمدة 45 دقيقة',
          'titleKu': '45 xulekî çalakiyê ruhî bikin',
          'descriptionEn': 'Engage in a 45-minute deep spiritual practice.',
          'descriptionAr': 'شارك في ممارسة روحانية عميقة لمدة 45 دقيقة.',
          'descriptionKu': 'Di 45 xulekê de li ser çalakiyê ruhî dengbêjî bikin.',
          'xpReward': 335,
          'type': 'spiritual'
        }
      ];
    default:
      return [];
  }
}

// Stage 14: Days 66-70 (Mental Mastery)
List<Map<String, dynamic>> _stage14(int day) {
  switch (day) {
    case 66:
      return [
        {
          'id': 'D66T1',
          'titleEn': 'Run 20 kilometers',
          'titleAr': 'اركض 20 كيلومتر',
          'titleKu': '20 kilometer berbiçîne',
          'descriptionEn': 'Run 20 kilometers! Half marathon distance achieved!',
          'descriptionAr': 'اركض 20 كيلومتر! لقد حققت مسافة نصف ماراثون!',
          'descriptionKu': 'Di 20 kilometer de berbiçîne! Mesafa nîv maratona serbestî ye!',
          'xpReward': 340,
          'type': 'physical'
        },
        {
          'id': 'D66T2',
          'titleEn': 'Practice 50 minutes of deep work',
          'titleAr': 'مارس 50 دقيقة من العمل العميق',
          'titleKu': '50 xulekî karê dengbêjî bike',
          'descriptionEn': 'Work with absolute focus for 50 minutes.',
          'descriptionAr': 'اعمل بتركيز مطلق لمدة 50 دقيقة.',
          'descriptionKu': 'Di 50 xulekê de li ser karêkê bi fokus absolut bike.',
          'xpReward': 340,
          'type': 'mental'
        },
        {
          'id': 'D66T3',
          'titleEn': 'Create a gratitude journal',
          'titleAr': 'أنشئ يوميات شكر',
          'titleKu': 'Rojnameyêkî şukrê çê bike',
          'descriptionEn': 'Start a gratitude journal and write 10 things you are grateful for.',
          'descriptionAr': 'ابدأ يوميات شكر واكتب 10 أشياء أنت ممتن لها.',
          'descriptionKu': 'Rojnameyêkî şukrê dest pêke û li ser 10 tişt ku hûn piştgînî û heye binivîse.',
          'xpReward': 340,
          'type': 'spiritual'
        }
      ];
    case 67:
      return [
        {
          'id': 'D67T1',
          'titleEn': 'Do 500 push-ups throughout the day',
          'titleAr': 'افعل 500 ضغط على مدار اليوم',
          'titleKu': '500 bendekirinê di roja de bike',
          'descriptionEn': 'Complete 500 push-ups throughout the day!',
          'descriptionAr': 'أكمل 500 تمرين ضغط على مدار اليوم!',
          'descriptionKu': '500 bendekirinê di roja de bi qencî bike!',
          'xpReward': 345,
          'type': 'physical'
        },
        {
          'id': 'D67T2',
          'titleEn': 'Teach a master class',
          'titleAr': 'قدّم حصة تدريس متقدمة',
          'titleKu': 'Dersêkî sereke fêr bike',
          'descriptionEn': 'Prepare and teach an advanced class or workshop.',
          'descriptionAr': 'حضّر وقدّم حصة أو ورشة عمل متقدمة.',
          'descriptionKu': 'Dersêkî an jî workshopêkî pêşveçûn amade bike û fêr bike.',
          'xpReward': 345,
          'type': 'social'
        },
        {
          'id': 'D67T3',
          'titleEn': 'Practice advanced cognitive techniques',
          'titleAr': 'مارس تقنيات إدراكية متقدمة',
          'titleKu': 'Teknîkên pêşveçûnî bikin',
          'descriptionEn': 'Practice advanced techniques for mental clarity and focus.',
          'descriptionAr': 'مارس تقنيات متقدمة لوضوح الذهن والتركيز.',
          'descriptionKu': 'Teknîkên pêşveçûn ji bo zanîna zîhînî bikin.',
          'xpReward': 345,
          'type': 'mental'
        }
      ];
    case 68:
      return [
        {
          'id': 'D68T1',
          'titleEn': 'Run 21 kilometers (half marathon)',
          'titleAr': 'اركض 21 كيلومتر (نصف ماراثون)',
          'titleKu': '21 kilometer berbiçîne (nîv maraton)',
          'descriptionEn': 'Run a half marathon! This is a huge achievement!',
          'descriptionAr': 'اركض نصف ماراثون! هذا إنجاز ضخم!',
          'descriptionKu': 'Nîv maratonê berbiçîne! Ev serkeftinêkî mezin ye!',
          'xpReward': 350,
          'type': 'physical'
        },
        {
          'id': 'D68T2',
          'titleEn': 'Write a book or long article',
          'titleAr': 'اكتب كتاباً أو مقالاً طويلاً',
          'titleKu': 'Pirtûkêkî an jî qetalekî dirêj bivîse',
          'descriptionEn': 'Write a substantial piece of writing about your journey.',
          'descriptionAr': 'اكتب عملاً كتابياً ملحوظاً عن رحلتك.',
          'descriptionKu': 'Nivîsekî mezin li ser seferê te bivîse.',
          'xpReward': 350,
          'type': 'mental'
        },
        {
          'id': 'D68T3',
          'titleEn': 'Organize a charity fundraiser',
          'titleAr': 'نظّم حملة تبرعات خيرية',
          'titleKu': 'Bêjna xweşî pêşdeng bike',
          'descriptionEn': 'Plan and organize a charity fundraiser event.',
          'descriptionAr': 'خطط ونظّم حدثاً لجمع التبرعات الخيرية.',
          'descriptionKu': 'Bêjna xweşî plan bike û pêşdeng bike.',
          'xpReward': 350,
          'type': 'social'
        }
      ];
    case 69:
      return [
        {
          'id': 'D69T1',
          'titleEn': 'Do a 85-minute workout',
          'titleAr': 'أكمل تمريناً رياضياً لمدة 85 دقيقة',
          'titleKu': '85 xulekî karê vîrajyana bike',
          'descriptionEn': 'Complete an intense 85-minute workout.',
          'descriptionAr': 'أكمل تمريناً مكثفاً لمدة 85 دقيقة.',
          'descriptionKu': '85 xulekî karê vîrajyana bilind bi qencî bike.',
          'xpReward': 355,
          'type': 'physical'
        },
        {
          'id': 'D69T2',
          'titleEn': 'Practice advanced emotional regulation',
          'titleAr': 'مارس تنظيم المشاعر المتقدم',
          'titleKu': 'Destekirina hestî pêşveçûn bikin',
          'descriptionEn': 'Practice advanced techniques for managing emotions.',
          'descriptionAr': 'مارس تقنيات متقدمة لإدارة المشاعر.',
          'descriptionKu': 'Teknîkên pêşveçûn ji bo birêveberkirina hestî bikin.',
          'xpReward': 355,
          'type': 'mental'
        },
        {
          'id': 'D69T3',
          'titleEn': 'Create a spiritual practice guide',
          'titleAr': 'أنشئ دليلاً للممارسة الروحانية',
          'titleKu': 'Rêberê çalakiyê ruhî çê bike',
          'descriptionEn': 'Write a guide for spiritual practices that you can share with others.',
          'descriptionAr': 'اكتب دليلاً للممارسات الروحانية يمكنك مشاركته مع الآخرين.',
          'descriptionKu': 'Rêberê çalakiyên ruhî bivîse ku hûn dikarin bi kesên din re parve bike.',
          'xpReward': 355,
          'type': 'spiritual'
        }
      ];
    case 70:
      return [
        {
          'id': 'D70T1',
          'titleEn': 'Run 22 kilometers',
          'titleAr': 'اركض 22 كيلومتر',
          'titleKu': '22 kilometer berbiçîne',
          'descriptionEn': 'Run 22 kilometers. You are in the final stretch!',
          'descriptionAr': 'اركض 22 كيلومتر. أنت في المرحلة الأخيرة!',
          'descriptionKu': 'Di 22 kilometer de berbiçîne. Hûn di derbasê dawî de dibin!',
          'xpReward': 360,
          'type': 'physical'
        },
        {
          'id': 'D70T2',
          'titleEn': 'Create a comprehensive life plan',
          'titleAr': 'أنشئ خطة شاملة للحياة',
          'titleKu': 'Planêkî complete a ji bo jîyanê çê bike',
          'descriptionEn': 'Create a detailed plan for the next year of your life.',
          'descriptionAr': 'أنشئ خطة مفصلة للسنة القادمة من حياتك.',
          'descriptionKu': 'Planêkî qetayê ji bo salê pêşîn ji bo jîyanê te çê bike.',
          'xpReward': 360,
          'type': 'mental'
        },
        {
          'id': 'D70T3',
          'titleEn': 'Host a spiritual gathering',
          'titleAr': 'نظّم تجمعاً روحانياً',
          'titleKu': 'Komekêkî ruhî pêşdeng bike',
          'descriptionEn': 'Organize and lead a spiritual gathering or retreat.',
          'descriptionAr': 'نظّم وقدّم تجمعاً روحانياً أو إقامة.',
          'descriptionKu': 'Komekêkî ruhî an jî sêwirî organize bike û pêşbikeve.',
          'xpReward': 360,
          'type': 'spiritual'
        }
      ];
    default:
      return [];
  }
}

// Stage 15: Days 71-75 (Social Impact)
List<Map<String, dynamic>> _stage15(int day) {
  switch (day) {
    case 71:
      return [
        {
          'id': 'D71T1',
          'titleEn': 'Run 23 kilometers',
          'titleAr': 'اركض 23 كيلومتر',
          'titleKu': '23 kilometer berbiçîne',
          'descriptionEn': 'Run 23 kilometers. Almost at the marathon distance!',
          'descriptionAr': 'اركض 23 كيلومتر. تقترب من مسافة الماراثون!',
          'descriptionKu': 'Di 23 kilometer de berbiçîne. Comekî ji mesafa maratona dûr nîn!',
          'xpReward': 365,
          'type': 'physical'
        },
        {
          'id': 'D71T2',
          'titleEn': 'Mentor 5 people',
          'titleAr': 'كن مرشداً لـ 5 أشخاص',
          'titleKu': '5 kesan bûyî',
          'descriptionEn': 'Offer guidance and support to 5 different people.',
          'descriptionAr': 'اعرض التوجيه والدعم على 5 أشخاص مختلفين.',
          'descriptionKu': 'Alîkariya 5 kesên cuda pêşniyar bike.',
          'xpReward': 365,
          'type': 'social'
        },
        {
          'id': 'D71T3',
          'titleEn': 'Practice a 60-minute meditation',
          'titleAr': 'مارس تأملاً لمدة 60 دقيقة',
          'titleKu': '60 xulekî ragihandinê bike',
          'descriptionEn': 'Sit in deep meditation for 60 minutes.',
          'descriptionAr': 'اجلس في تأمل عميق لمدة 60 دقيقة.',
          'descriptionKu': 'Di 60 xulekê de bi dengbêjî binihîtin.',
          'xpReward': 365,
          'type': 'spiritual'
        }
      ];
    case 72:
      return [
        {
          'id': 'D72T1',
          'titleEn': 'Do 600 push-ups throughout the day',
          'titleAr': 'افعل 600 ضغط على مدار اليوم',
          'titleKu': '600 bendekirinê di roja de bike',
          'descriptionEn': 'Complete 600 push-ups throughout the day!',
          'descriptionAr': 'أكمل 600 تمرين ضغط على مدار اليوم!',
          'descriptionKu': '600 bendekirinê di roja de bi qencî bike!',
          'xpReward': 370,
          'type': 'physical'
        },
        {
          'id': 'D72T2',
          'titleEn': 'Organize a large community event',
          'titleAr': 'نظّم حدثاً مجتمعياً كبيراً',
          'titleKu': 'Pêvajoyêkî komelexanê mezin pêşdeng bike',
          'descriptionEn': 'Plan and organize a large-scale community event.',
          'descriptionAr': 'خطط ونظّم حدثاً مجتمعياً على نطاق واسع.',
          'descriptionKu': 'Pêvajoyêkî komelexanê ya mezin plan bike û pêşdeng bike.',
          'xpReward': 370,
          'type': 'social'
        },
        {
          'id': 'D72T3',
          'titleEn': 'Practice advanced spiritual discipline',
          'titleAr': 'مارس تدبيراً روحانياً متقدماً',
          'titleKu': 'Destekirina ruhî pêşveçûn bikin',
          'descriptionEn': 'Practice an advanced spiritual discipline for 45 minutes.',
          'descriptionAr': 'مارس تدبيراً روحانياً متقدماً لمدة 45 دقيقة.',
          'descriptionKu': 'Di 45 xulekê de destekirina ruhî pêşveçûn bikin.',
          'xpReward': 370,
          'type': 'spiritual'
        }
      ];
    case 73:
      return [
        {
          'id': 'D73T1',
          'titleEn': 'Run 24 kilometers',
          'titleAr': 'اركض 24 كيلومتر',
          'titleKu': '24 kilometer berbiçîne',
          'descriptionEn': 'Run 24 kilometers. Just 2 more to go!',
          'descriptionAr': 'اركض 24 كيلومتر. متبقي 2 كيلومتر فقط!',
          'descriptionKu': 'Di 24 kilometer de berbiçîne. Tenê 2 kilometer jê maye!',
          'xpReward': 375,
          'type': 'physical'
        },
        {
          'id': 'D73T2',
          'titleEn': 'Create a leadership development plan',
          'titleAr': 'أنشئ خطة تطوير قيادي',
          'titleKu': 'Planê pêşkeftina serokbijnayê çê bike',
          'descriptionEn': 'Design a plan to develop your leadership skills.',
          'descriptionAr': 'صمم خطة لتطوير مهاراتك القيادة.',
          'descriptionKu': 'Planêkî ji bo pêşkeftina hînên serokbijnayê te çê bike.',
          'xpReward': 375,
          'type': 'mental'
        },
        {
          'id': 'D73T3',
          'titleEn': 'Teach spiritual practices to others',
          'titleAr': 'علّم الممارسات الروحانية للآخرين',
          'titleKu': 'Çalakiyên ruhî bo kesên din fêr bike',
          'descriptionEn': 'Share your spiritual knowledge by teaching others.',
          'descriptionAr': 'شارك معرفتك الروحانية بتعليم الآخرين.',
          'descriptionKu': 'Zanîna ruhî xwe bi fêrkirina kesên din parve bike.',
          'xpReward': 375,
          'type': 'social'
        }
      ];
    case 74:
      return [
        {
          'id': 'D74T1',
          'titleEn': 'Complete a 90-minute workout',
          'titleAr': 'أكمل تمريناً رياضياً لمدة 90 دقيقة',
          'titleKu': '90 xulekî karê vîrajyana bike',
          'descriptionEn': 'Complete a 90-minute intense workout session.',
          'descriptionAr': 'أكمل جلسة تمرين مكثفة لمدة 90 دقيقة.',
          'descriptionKu': '90 xulekî karê vîrajyana bilind bi qencî bike.',
          'xpReward': 380,
          'type': 'physical'
        },
        {
          'id': 'D74T2',
          'titleEn': 'Write a book chapter or article',
          'titleAr': 'اكتب فصلاً من كتاب أو مقالاً',
          'titleKu': 'Alîkareyê pirtûkê an jî qetalekî bivîse',
          'descriptionEn': 'Write a substantial chapter or article about your recovery journey.',
          'descriptionAr': 'اكتب فصلاً أو مقالاً ملحوظاً عن رحلة تعافيك.',
          'descriptionKu': 'Alîkareyê pirtûkê an jî qetalekî mezin li ser seferê şifakirina te bivîse.',
          'xpReward': 380,
          'type': 'mental'
        },
        {
          'id': 'D74T3',
          'titleEn': 'Establish a charity foundation',
          'titleAr': 'أسّس مؤسسة خيرية',
          'titleKu': 'Vekiriyekekî xweşî dest pêke',
          'descriptionEn': 'Research and plan the establishment of a charity or service organization.',
          'descriptionAr': 'ابحث عن تأسيس منظمة خيرية أو خدمة المجتمع.',
          'descriptionKu': 'Li ser vekirina nêzîkekî xweşî an jî xizmetê komelexanê lêkolîn bike.',
          'xpReward': 380,
          'type': 'social'
        }
      ];
    case 75:
      return [
        {
          'id': 'D75T1',
          'titleEn': 'Run 25 kilometers',
          'titleAr': 'اركض 25 كيلومتر',
          'titleKu': '25 kilometer berbiçîne',
          'descriptionEn': 'Run 25 kilometers! Only 17 more to full marathon!',
          'descriptionAr': 'اركض 25 كيلومتر! متبقي 17 كيلومتر للوصول إلى الماراثون الكامل!',
          'descriptionKu': 'Di 25 kilometer de berbiçîne! Tenê 17 kilometer din ji bo maratonê tam!',
          'xpReward': 385,
          'type': 'physical'
        },
        {
          'id': 'D75T2',
          'titleEn': 'Create a social impact project',
          'titleAr': 'أنشئ مشروعاً للتأثير الاجتماعي',
          'titleKu': 'Proyektekî bandorê sosyal çê bike',
          'descriptionEn': 'Design a project that will positively impact your community.',
          'descriptionAr': 'صمم مشروعاً سيكون له تأثير إيجابي على مجتمعك.',
          'descriptionKu': 'Proyektekî ku bandorê ecêb li ser komelexanê te bike çê bike.',
          'xpReward': 385,
          'type': 'social'
        },
        {
          'id': 'D75T3',
          'titleEn': 'Practice a 75-minute spiritual session',
          'titleAr': 'مارس جلسة روحانية لمدة 75 دقيقة',
          'titleKu': '75 xulekî çalakiyê ruhî bikin',
          'descriptionEn': 'Engage in a 75-minute deep spiritual practice.',
          'descriptionAr': 'شارك في ممارسة روحانية عميقة لمدة 75 دقيقة.',
          'descriptionKu': 'Di 75 xulekê de li ser çalakiyê ruhî dengbêjî bikin.',
          'xpReward': 385,
          'type': 'spiritual'
        }
      ];
    default:
      return [];
  }
}

// Stage 16: Days 76-80 (Discipline Mastery)
List<Map<String, dynamic>> _stage16(int day) {
  switch (day) {
    case 76:
      return [
        {
          'id': 'D76T1',
          'titleEn': 'Run 26 kilometers',
          'titleAr': 'اركض 26 كيلومتر',
          'titleKu': '26 kilometer berbiçîne',
          'descriptionEn': 'Run 26 kilometers. You are a marathon runner!',
          'descriptionAr': 'اركض 26 كيلومتر. أنت عداء ماراثون!',
          'descriptionKu': 'Di 26 kilometer de berbiçîne. Hûn berbiçîna maraton dibin!',
          'xpReward': 390,
          'type': 'physical'
        },
        {
          'id': 'D76T2',
          'titleEn': 'Practice 55 minutes of deep work',
          'titleAr': 'مارس 55 دقيقة من العمل العميق',
          'titleKu': '55 xulekî karê dengbêjî bike',
          'descriptionEn': 'Work with absolute focus for 55 minutes.',
          'descriptionAr': 'اعمل بتركيز مطلق لمدة 55 دقيقة.',
          'descriptionKu': 'Di 55 xulekê de li ser karêkê bi fokus absolut bike.',
          'xpReward': 390,
          'type': 'mental'
        },
        {
          'id': 'D76T3',
          'titleEn': 'Complete a 48-hour digital detox',
          'titleAr': 'أكمل تخلصاً رقمياً لمدة 48 ساعة',
          'titleKu': '48 saetan bêyî dîjîtal bimîne',
          'descriptionEn': 'Stay away from all digital devices for 48 hours.',
          'descriptionAr': 'ابقَ بعيداً عن جميع الأجهزة الرقمية لمدة 48 ساعة.',
          'descriptionKu': 'Di 48 saetan de ji hemû amûrên dîjîtal dûr bimîne.',
          'xpReward': 390,
          'type': 'discipline'
        }
      ];
    case 77:
      return [
        {
          'id': 'D77T1',
          'titleEn': 'Do 700 push-ups throughout the day',
          'titleAr': 'افعل 700 ضغط على مدار اليوم',
          'titleKu': '700 bendekirinê di roja de bike',
          'descriptionEn': 'Complete 700 push-ups throughout the day!',
          'descriptionAr': 'أكمل 700 تمرين ضغط على مدار اليوم!',
          'descriptionKu': '700 bendekirinê di roja de bi qencî bike!',
          'xpReward': 395,
          'type': 'physical'
        },
        {
          'id': 'D77T2',
          'titleEn': 'Write a comprehensive recovery guide',
          'titleAr': 'اكتب دليلاً شاملاً للتعافي',
          'titleKu': 'Rêberê complete a ji bo şifakirinê bivîse',
          'descriptionEn': 'Write a detailed guide about your recovery process and insights.',
          'descriptionAr': 'اكتب دليلاً مفصلاً عن عملية تعافيك ورؤىك.',
          'descriptionKu': 'Rêberê qetayê li ser pêvajoya şifakirina te û dîtina te bivîse.',
          'xpReward': 395,
          'type': 'mental'
        },
        {
          'id': 'D77T3',
          'titleEn': 'Establish a daily spiritual practice',
          'titleAr': 'أرسّخ ممارسة روحانية يومية',
          'titleKu': 'Çalakiyêkî ruhî rojane dest pêke',
          'descriptionEn': 'Commit to a consistent daily spiritual practice.',
          'descriptionAr': 'التزم بممارسة روحانية يومية ثابتة.',
          'challenge': null,
          'descriptionKu': 'Li ser çalakiyêkî ruhî rojane ya sabit bike.',
          'xpReward': 395,
          'type': 'spiritual'
        }
      ];
    case 78:
      return [
        {
          'id': 'D78T1',
          'titleEn': 'Run 27 kilometers',
          'titleAr': 'اركض 27 كيلومتر',
          'titleKu': '27 kilometer berbiçîne',
          'descriptionEn': 'Run 27 kilometers. Just 15 more to the full marathon!',
          'descriptionAr': 'اركض 27 كيلومتر. متبقي 15 كيلومتر فقط للماراثون الكامل!',
          'descriptionKu': 'Di 27 kilometer de berbiçîne. Tenê 15 kilometer din ji bo maratonê tam!',
          'xpReward': 400,
          'type': 'physical'
        },
        {
          'id': 'D78T2',
          'titleEn': 'Lead a team project',
          'titleAr': 'قاد مشروعاً جماعياً',
          'titleKu': 'Proyektekî tîmê destek bike',
          'descriptionEn': 'Take the lead in a team project and guide others.',
          'descriptionAr': 'تولَّ قيادة مشروعاً جماعياً ووجّه الآخرين.',
          'descriptionKu': 'Li ser serokbijnaya proyekta tîmê destek bike û kesên din dihilatîne.',
          'xpReward': 400,
          'type': 'social'
        },
        {
          'id': 'D78T3',
          'titleEn': 'Fast for 72 hours',
          'titleAr': 'صم لمدة 72 ساعة',
          'titleKu': '72 saetan rûçik bixe',
          'descriptionEn': 'Attempt a 72-hour fast. Extreme discipline required.',
          'descriptionAr': 'حاول صيام 72 ساعة. يتطلب تدبيراً شديداً.',
          'descriptionKu': 'Rûçika 72 saetan bikein. Destekirinê teqîneyê dipêvîne.',
          'xpReward': 400,
          'type': 'discipline'
        }
      ];
    case 79:
      return [
        {
          'id': 'D79T1',
          'titleEn': 'Run 28 kilometers',
          'titleAr': 'اركض 28 كيلومتر',
          'titleKu': '28 kilometer berbiçîne',
          'descriptionEn': 'Run 28 kilometers. Getting closer!',
          'descriptionAr': 'اركض 28 كيلومتر. تقترب!',
          'descriptionKu': 'Di 28 kilometer de berbiçîne. Comekî ji ber dûr nîn!',
          'xpReward': 405,
          'type': 'physical'
        },
        {
          'id': 'D79T2',
          'titleEn': 'Write a personal manifesto',
          'titleAr': 'اكتب بياناً شخصياً',
          'titleKu': 'Bifestoyêkî personal bivîse',
          'descriptionEn': 'Write a manifesto that declares your values, goals, and commitments.',
          'descriptionAr': 'اكتب بياناً يعلن عن قيمك وأهدافك والالتزاماتك.',
          'descriptionKu': 'Bifestoyêkî ku nirx, armanca û berfermanên te dibêje bivîse.',
          'xpReward': 405,
          'type': 'mental'
        },
        {
          'id': 'D79T3',
          'titleEn': 'Organize a spiritual retreat for others',
          'titleAr': 'نظّم إقامة روحانية للآخرين',
          'titleKu': 'Sêwirîyêkî ruhî ji bo kesên din pêşdeng bike',
          'descriptionEn': 'Plan and organize a spiritual retreat for others.',
          'descriptionAr': 'خطط ونظّم إقامة روحانية للآخرين.',
          'descriptionKu': 'Sêwirîyêkî ruhî ji bo kesên din plan bike û pêşdeng bike.',
          'xpReward': 405,
          'type': 'spiritual'
        }
      ];
    case 80:
      return [
        {
          'id': 'D80T1',
          'titleEn': 'Run 29 kilometers',
          'titleAr': 'اركض 29 كيلومتر',
          'titleKu': '29 kilometer berbiçîne',
          'descriptionEn': 'Run 29 kilometers. Just one more kilometer to 30K!',
          'descriptionAr': 'اركض 29 كيلومتر. كيلومتر واحد فقط للوصول إلى 30 كيلومتر!',
          'descriptionKu': 'Di 29 kilometer de berbiçîne. Tenê 1 kilometer din ji bo 30K!',
          'xpReward': 410,
          'type': 'physical'
        },
        {
          'id': 'D80T2',
          'titleEn': 'Complete a major project',
          'titleAr': 'أكمل مشروعاً كبيراً',
          'titleKu': 'Proyektekî mezin bi qencî bike',
          'descriptionEn': 'Complete a significant personal or professional project.',
          'descriptionAr': 'أكمل مشروعاً شخصياً أو مهنياً مهماً.',
          'descriptionKu': 'Proyektekî sereke personal an jî pîroz bi qencî bike.',
          'xpReward': 410,
          'type': 'mental'
        },
        {
          'id': 'D80T3',
          'titleEn': 'Practice a 90-minute spiritual session',
          'titleAr': 'مارس جلسة روحانية لمدة 90 دقيقة',
          'titleKu': '90 xulekî çalakiyê ruhî bikin',
          'descriptionEn': 'Engage in a 90-minute deep spiritual practice.',
          'descriptionAr': 'شارك في ممارسة روحانية عميقة لمدة 90 دقيقة.',
          'descriptionKu': 'Di 90 xulekê de li ser çalakiyê ruhî dengbêjî bikin.',
          'xpReward': 410,
          'type': 'spiritual'
        }
      ];
    default:
      return [];
  }
}

// Stage 17: Days 81-85 (Integration)
List<Map<String, dynamic>> _stage17(int day) {
  switch (day) {
    case 81:
      return [
        {
          'id': 'D81T1',
          'titleEn': 'Run 30 kilometers',
          'titleAr': 'اركض 30 كيلومتر',
          'titleKu': '30 kilometer berbiçîne',
          'descriptionEn': 'Run 30 kilometers! You are a true endurance champion!',
          'descriptionAr': 'اركض 30 كيلومتر! أنت بطل التحمٍ الحقيقي!',
          'descriptionKu': 'Di 30 kilometer de berbiçîne! Hûn qeybala hewildarîyê ya rastî dibin!',
          'xpReward': 415,
          'type': 'physical'
        },
        {
          'id': 'D81T2',
          'titleEn': 'Practice 60 minutes of deep work',
          'titleAr': 'مارس 60 دقيقة من العمل العميق',
          'titleKu': '60 xulekî karê dengbêjî bike',
          'descriptionEn': 'Work with complete focus for 60 minutes on your highest priority.',
          'descriptionAr': 'اعمل بتركيز كامل لمدة 60 دقيقة على أولويتك الأعلى.',
          'descriptionKu': 'Di 60 xulekê de li ser sereka sereke te bi fokus absolut bike.',
          'xpReward': 415,
          'type': 'mental'
        },
        {
          'id': 'D81T3',
          'titleEn': 'Create a daily routine checklist',
          'titleAr': 'أنشئ قائمة فحص للروتين اليومي',
          'titleKu': 'Li ser rutîna rojane lîsteyek çê bike',
          'descriptionEn': 'Design a comprehensive daily routine checklist for long-term success.',
          'descriptionAr': 'صمم قائمة فحص شاملة للروتين اليومي للنجاح طويل المدى.',
          'descriptionKu': 'Li ser rutîna rojane ya bi qetayê ji bo serkeftina dirêj lîsteyek çê bike.',
          'xpReward': 415,
          'type': 'discipline'
        }
      ];
    case 82:
      return [
        {
          'id': 'D82T1',
          'titleEn': 'Do 800 push-ups throughout the day',
          'titleAr': 'افعل 800 ضغط على مدار اليوم',
          'titleKu': '800 bendekirinê di roja de bike',
          'descriptionEn': 'Complete 800 push-ups throughout the day!',
          'descriptionAr': 'أكمل 800 تمرين ضغط على مدار اليوم!',
          'descriptionKu': '800 bendekirinê di roja de bi qencî bike!',
          'xpReward': 420,
          'type': 'physical'
        },
        {
          'id': 'D82T2',
          'titleEn': 'Teach a comprehensive workshop',
          'titleAr': 'قدّم ورشة عمل شاملة',
          'titleKu': 'Workshopêkî complete a fêr bike',
          'descriptionEn': 'Design and teach a comprehensive workshop to others.',
          'descriptionAr': 'صمم وقدّم ورشة عمل شاملة للآخرين.',
          'descriptionKu': 'Workshopêkî complete a ji bo kesên din design bike û fêr bike.',
          'xpReward': 420,
          'type': 'social'
        },
        {
          'id': 'D82T3',
          'titleEn': 'Practice a 100-minute spiritual session',
          'titleAr': 'مارس جلسة روحانية لمدة 100 دقيقة',
          'titleKu': '100 xulekî çalakiyê ruhî bikin',
          'descriptionEn': 'Engage in a 100-minute deep spiritual practice.',
          'descriptionAr': 'شارك في ممارسة روحانية عميقة لمدة 100 دقيقة.',
          'descriptionKu': 'Di 100 xulekê de li ser çalakiyê ruhî dengbêjî bikin.',
          'xpReward': 420,
          'type': 'spiritual'
        }
      ];
    case 83:
      return [
        {
          'id': 'D83T1',
          'titleEn': 'Run 31 kilometers',
          'titleAr': 'اركض 31 كيلومتر',
          'titleKu': '31 kilometer berbiçîne',
          'descriptionEn': 'Run 31 kilometers. Beyond the half marathon!',
          'descriptionAr': 'اركض 31 كيلومتر. تجاوزت نصف الماراثون!',
          'descriptionKu': 'Di 31 kilometer de berbiçîne. Ji nîv maratona derbas bû!',
          'xpReward': 425,
          'type': 'physical'
        },
        {
          'id': 'D83T2',
          'titleEn': 'Write a book or guide',
          'titleAr': 'اكتب كتاباً أو دليلاً',
          'titleKu': 'Pirtûkêkî an jî rêberêkî bivîse',
          'descriptionEn': 'Write a book or guide about your recovery and growth.',
          'descriptionAr': 'اكتب كتاباً أو دليلاً عن تعافيك ونموك.',
          'descriptionKu': 'Pirtûkêkî an jî rêberêkî li ser şifakirina te û pêşkeftina te bivîse.',
          'xpReward': 425,
          'type': 'mental'
        },
        {
          'id': 'D83T3',
          'titleEn': 'Establish a charity organization',
          'titleAr': 'أسّس منظمة خيرية',
          'titleKu': 'Nêzîkekî xweşî dest pêke',
          'descriptionEn': 'Take steps to establish a charity or service organization.',
          'descriptionAr': 'اتخذ خطوات لإنشاء منظمة خيرية أو خدمة مجتمعية.',
          'descriptionKu': 'Gavên ji bo vekirina nêzîkekî xweşî an jî xizmetê komelexanê bidest bike.',
          'xpReward': 425,
          'type': 'social'
        }
      ];
    case 84:
      return [
        {
          'id': 'D84T1',
          'titleEn': 'Complete a 95-minute workout',
          'titleAr': 'أكمل تمريناً رياضياً لمدة 95 دقيقة',
          'titleKu': '95 xulekî karê vîrajyana bike',
          'descriptionEn': 'Complete a 95-minute intense workout.',
          'descriptionAr': 'أكمل تمريناً مكثفاً لمدة 95 دقيقة.',
          'descriptionKu': '95 xulekî karê vîrajyana bilind bi qencî bike.',
          'xpReward': 430,
          'type': 'physical'
        },
        {
          'id': 'D84T2',
          'titleEn': 'Practice advanced leadership skills',
          'titleAr': 'مارس مهارات قيادية متقدمة',
          'titleKu': 'Hînên serokbijnayê pêşveçûn bikin',
          'descriptionEn': 'Practice advanced leadership and mentoring skills.',
          'descriptionAr': 'مارس مهارات القيادة والإرشاد المتقدمة.',
          'descriptionKu': 'Hînên serokbijnayê an jî bûyîkirinê pêşveçûn bikin.',
          'xpReward': 430,
          'type': 'mental'
        },
        {
          'id': 'D84T3',
          'titleEn': 'Create a spiritual legacy',
          'titleAr': 'أنشئ ميراثاً روحانياً',
          'titleKu': 'Mirathêkî ruhî çê bike',
          'descriptionEn': 'Document your spiritual journey and create a legacy for others.',
          'descriptionAr': 'وثّق رحلتك الروحانية وأنشئ ميراثاً للآخرين.',
          'descriptionKu': 'Seferê ruhî te nivîse û mirathêkî ji bo kesên din çê bike.',
          'xpReward': 430,
          'type': 'spiritual'
        }
      ];
    case 85:
      return [
        {
          'id': 'D85T1',
          'titleEn': 'Run 32 kilometers',
          'titleAr': 'اركض 32 كيلومتر',
          'titleKu': '32 kilometer berbiçîne',
          'descriptionEn': 'Run 32 kilometers. Getting closer to the marathon!',
          'descriptionAr': 'اركض 32 كيلومتر. تقترب من الماراثون!',
          'descriptionKu': 'Di 32 kilometer de berbiçîne. Comekî ji maratona dûr nîn!',
          'xpReward': 435,
          'type': 'physical'
        },
        {
          'id': 'D85T2',
          'titleEn': 'Complete a major life goal',
          'titleAr': 'أكمل هدفاً كبيراً في الحياة',
          'titleKu': 'Armancekî mezin ji bo jîyanê bi qencî bike',
          'descriptionEn': 'Accomplish a significant life goal you have been working toward.',
          'descriptionAr': 'حقق هدفاً كبيراً في حياتك كنت تعمل عليه.',
          'descriptionKu': 'Armancekî sereke ji bo jîyanê ku te li ser wê kar dikir bi qencî bike.',
          'xpReward': 435,
          'type': 'mental'
        },
        {
          'id': 'D85T3',
          'titleEn': 'Lead a community initiative',
          'titleAr': 'قاد مبادرة مجتمعية',
          'titleKu': 'Destekirinêkî komelexanê destek bike',
          'descriptionEn': 'Take the lead in a community initiative or project.',
          'descriptionAr': 'تولَّ قيادة مبادرة أو مشروع مجتمعي.',
          'descriptionKu': 'Li ser destekirinêkî an jî proyektekî komelexanê serokbijnayê bike.',
          'xpReward': 435,
          'type': 'social'
        }
      ];
    default:
      return [];
  }
}

// Stage 18: Days 86-90 (Mastery & Completion)
List<Map<String, dynamic>> _stage18(int day) {
  switch (day) {
    case 86:
      return [
        {
          'id': 'D86T1',
          'titleEn': 'Run 33 kilometers',
          'titleAr': 'اركض 33 كيلومتر',
          'titleKu': '33 kilometer berbiçîne',
          'descriptionEn': 'Run 33 kilometers. You are a true marathon runner!',
          'descriptionAr': 'اركض 33 كيلومتر. أنت عداء ماراثون حقيقي!',
          'descriptionKu': 'Di 33 kilometer de berbiçîne. Hûn berbiçîna maraton ya rastî dibin!',
          'xpReward': 440,
          'type': 'physical'
        },
        {
          'id': 'D86T2',
          'titleEn': 'Practice 65 minutes of deep work',
          'titleAr': 'مارس 65 دقيقة من العمل العميق',
          'titleKu': '65 xulekî karê dengbêjî bike',
          'descriptionEn': 'Work with absolute focus for 65 minutes.',
          'descriptionAr': 'اعمل بتركيز مطلق لمدة 65 دقيقة.',
          'descriptionKu': 'Di 65 xulekê de li ser karêkê bi fokus absolut bike.',
          'xpReward': 440,
          'type': 'mental'
        },
        {
          'id': 'D86T3',
          'titleEn': 'Create a 90-day review document',
          'titleAr': 'أنشئ وثيقة مراجعة لـ 90 يوماً',
          'titleKu': 'Belêkê rêveberiya 90 rojê çê bike',
          'descriptionEn': 'Write a comprehensive review of your entire 90-day journey.',
          'descriptionAr': 'اكتب مراجعة شاملة لرحلتك الكاملة التي استمرت 90 يوماً.',
          'descriptionKu': 'Rêveberiya complete a ji seferê 90 roja te bivîse.',
          'xpReward': 440,
          'type': 'mental'
        }
      ];
    case 87:
      return [
        {
          'id': 'D87T1',
          'titleEn': 'Do 900 push-ups throughout the day',
          'titleAr': 'افعل 900 ضغط على مدار اليوم',
          'titleKu': '900 bendekirinê di roja de bike',
          'descriptionEn': 'Complete 900 push-ups throughout the day!',
          'descriptionAr': 'أكمل 900 تمرين ضغط على مدار اليوم!',
          'descriptionKu': '900 bendekirinê di roja de bi qencî bike!',
          'xpReward': 445,
          'type': 'physical'
        },
        {
          'id': 'D87T2',
          'titleEn': 'Teach a master class on your expertise',
          'titleAr': 'قدّم حصة تدريس متقدمة في تخصصك',
          'titleKu': 'Dersêkî sereke li ser taybetmendiya te fêr bike',
          'descriptionEn': 'Teach a master class sharing your knowledge and expertise.',
          'descriptionAr': 'قدّم حصة تدريس متقدمة تشارك فيها معرفتك وخبرتك.',
          'descriptionKu': 'Dersêkî sereke ku zanîn û taybetmendiya te parve bike fêr bike.',
          'xpReward': 445,
          'type': 'social'
        },
        {
          'id': 'D87T3',
          'titleEn': 'Practice a 120-minute spiritual session',
          'titleAr': 'مارس جلسة روحانية لمدة 120 دقيقة',
          'titleKu': '120 xulekî çalakiyê ruhî bikin',
          'descriptionEn': 'Engage in a 120-minute deep spiritual practice.',
          'descriptionAr': 'شارك في ممارسة روحانية عميقة لمدة 120 دقيقة.',
          'descriptionKu': 'Di 120 xulekê de li ser çalakiyê ruhî dengbêjî bikin.',
          'xpReward': 445,
          'type': 'spiritual'
        }
      ];
    case 88:
      return [
        {
          'id': 'D88T1',
          'titleEn': 'Run 34 kilometers',
          'titleAr': 'اركض 34 كيلومتر',
          'titleKu': '34 kilometer berbiçîne',
          'descriptionEn': 'Run 34 kilometers. Almost at the marathon distance!',
          'descriptionAr': 'اركض 34 كيلومتر. تقترب من مسافة الماراثون!',
          'descriptionKu': 'Di 34 kilometer de berbiçîne. Comekî ji mesafa maratona dûr nîn!',
          'xpReward': 450,
          'type': 'physical'
        },
        {
          'id': 'D88T2',
          'titleEn': 'Write a letter to someone who inspired you',
          'titleAr': 'اكتب رسالة لشخص ألهمك',
          'titleKu': 'Nivîsekî ji bo kesekî ku te inspire kir bivîse',
          'descriptionEn': 'Write a heartfelt letter to someone who has inspired your journey.',
          'descriptionAr': 'اكتب رسالة صادقة لشخص ألهم رحلتك.',
          'descriptionKu': 'Nivîsekî bi dilê te ji bo kesekî ku te seferê te inspire kir bivîse.',
          'xpReward': 450,
          'type': 'social'
        },
        {
          'id': 'D88T3',
          'titleEn': 'Create a personal philosophy document',
          'titleAr': 'أنشئ وثيقة فلسفتك الشخصية',
          'titleKu': 'Belêkê felsefeyê personal çê bike',
          'descriptionEn': 'Write a comprehensive personal philosophy document.',
          'descriptionAr': 'اكتب وثيقة فلسفتك الشخصية الشاملة.',
          'descriptionKu': 'Belêkê felsefeyê personal ya complete a bivîse.',
          'xpReward': 450,
          'type': 'mental'
        }
      ];
    case 89:
      return [
        {
          'id': 'D89T1',
          'titleEn': 'Run 35 kilometers',
          'titleAr': 'اركض 35 كيلومتر',
          'titleKu': '35 kilometer berbiçîne',
          'descriptionEn': 'Run 35 kilometers. You are ready for the marathon!',
          'descriptionAr': 'اركض 35 كيلومتر. أنت مستعد للماراثون!',
          'descriptionKu': 'Di 35 kilometer de berbiçîne. Hûn ji bo maratona amade dibin!',
          'xpReward': 455,
          'type': 'physical'
        },
        {
          'id': 'D89T2',
          'titleEn': 'Reflect on your complete transformation',
          'titleAr': 'تأمل في تحوّلك الكامل',
          'titleKu': 'Li ser guhertina te ya complete a rû bike',
          'descriptionEn': 'Spend time reflecting on how completely you have transformed.',
          'descriptionAr': 'اقضِ وقتاً في التأمل في كيف تحوّلت تماماً.',
          'descriptionKu': 'Demêkî li ser çima te bi temamî guherî bike.',
          'xpReward': 455,
          'type': 'mental'
        },
        {
          'id': 'D89T3',
          'titleEn': 'Plan your next 90-day challenge',
          'titleAr': 'خطط لتحدٍ الـ 90 يوماً القادم',
          'titleKu': 'Teqîna 90 roja pêş plan bike',
          'descriptionEn': 'Design your next 90-day challenge or growth plan.',
          'descriptionAr': 'صمم تحدٍ الـ 90 يوماً القادم أو خطة النمو.',
          'descriptionKu': 'Teqîna 90 roja pêş an jî planê pêşkeftinê design bike.',
          'xpReward': 455,
          'type': 'discipline'
        }
      ];
    case 90:
      return [
        {
          'id': 'D90T1',
          'titleEn': 'Complete a full marathon (42.2 km)',
          'titleAr': 'أكمل ماراثوناً كاملاً (42.2 كيلومتر)',
          'titleKu': 'Maratonêkî tam bike (42.2 km)',
          'descriptionEn': 'Complete a full marathon. You have earned this!',
          'descriptionAr': 'أكمل ماراثوناً كاملاً. لقد استحققت هذا!',
          'descriptionKu': 'Maratonêkî tam bi qencî bike. Hûn vê serbestîyê hêstîyê!',
          'xpReward': 460,
          'type': 'physical'
        },
        {
          'id': 'D90T2',
          'titleEn': 'Write a legacy letter',
          'titleAr': 'اكتب رسالة ميراث',
          'titleKu': 'Nivîsekî mirathê bivîse',
          'descriptionEn': 'Write a letter to future generations about your journey and lessons learned.',
          'descriptionAr': 'اكتب رسالة للأجيال المستقبلية عن رحلتك والدروس المستفادة.',
          'descriptionKu': 'Nivîsekî ji bo derfiqên pêşîn li ser sefer û şîretên te bivîse.',
          'xpReward': 460,
          'type': 'mental'
        },
        {
          'id': 'D90T3',
          'titleEn': 'Celebrate your achievement',
          'titleAr': 'احتفل بإنجازك',
          'titleKu': 'Serkeftina xwe destfest bike',
          'descriptionEn': 'Take time to celebrate and appreciate your incredible 90-day journey.',
          'descriptionAr': 'خذ وقتاً للاحتفال والتقدير لرحلتك المذهلة التي استمرت 90 يوماً.',
          'descriptionKu': 'Demêkî ji bo destfestkirinê û pirsgiriyê seferê te ya 90 roja xweş bike.',
          'xpReward': 460,
          'type': 'spiritual'
        }
      ];
    default:
      return [];
  }
}
