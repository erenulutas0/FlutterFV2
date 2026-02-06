import 'package:flutter/material.dart';
import 'grammar_data.dart';

/// EXAM GRAMMAR TOPICS
const examTopicsTopic = GrammarTopic(
  id: 'exam_topics',
  title: 'Exam Topics',
  titleTr: 'Sınav Konuları',
  level: 'exam',
  icon: Icons.school,
  color: Color(0xFFef4444), // Red
  subtopics: [
    // 1. REPORTED SPEECH
    GrammarSubtopic(
      id: 'reported_speech',
      title: 'Reported Speech',
      titleTr: 'Dolaylı Anlatım',
      explanation: '''
Birinin sözünü başkasına aktarırken kullanılır. Aktarım sırasında zamanlar genellikle bir derece geçmişe kayar (Backshift).

🎯 Değişimler:
• Present Simple -> Past Simple
• Present Continuous -> Past Continuous
• Past Simple / Present Perfect -> Past Perfect
• Will -> Would
• Can -> Could
• Must -> Had to
• "Yesterday" -> "The day before"
• "Tomorrow" -> "The next day"
• "Here" -> "There"
''',
      formula: '''
Direct: "I am ill," said Tom.
Reported: Tom said (that) he was ill.
''',
      examples: [
        GrammarExample(
          english: 'She said, "I like ice cream."',
          turkish: 'O, "Dondurma severim" dedi.',
          note: 'Direct',
        ),
        GrammarExample(
          english: 'She said (that) she liked ice cream.',
          turkish: 'Dondurma sevdiğini söyledi.',
          note: 'Indirect (Reported)',
        ),
        GrammarExample(
          english: 'He asked where I lived.',
          turkish: 'Nerede yaşadığımı sordu.',
          note: 'Where do you live? -> where I lived',
        ),
      ],
      commonMistakes: [
        '❌ He said me that... → ✅ He told me that... / He said that...',
        '❌ He asked where did I go. → ✅ He asked where I went. (Soru devriklik kalkar)',
      ],
      keyPoints: [
        '🔑 "Say" nesne almaz (said that...), "Tell" nesne alır (told ME that...).',
        '🔑 Eğer giriş cümlesi Present ise (He SAYS), zaman değişmez!',
        '🔑 Bilimsel gerçeklerde zaman değişmez (The teacher said water boils at 100°C).',
      ],
    ),

    // 2. CAUSATIVE
    GrammarSubtopic(
      id: 'causative',
      title: 'Causative Forms',
      titleTr: 'Ettirgen Çatı',
      explanation: '''
Bir işi başkasına yaptırmak anlamındadır.

🎯 3 Temel Yapı:
1. Have something DONE (Bir şeyi yaptırmak - yaptıran önemli, yapan önemsiz)
2. Have someone DO something (Birine bir şey yaptırmak - otorite/rica)
3. Get someone TO DO something (Birini ikna edip yaptırmak)
''',
      formula: '''
Have + Nesne + V3 (I had my car washed)
Have + Kişi + V1 (I had the mechanic repair my car)
Get + Kişi + to V1 (I got the mechanic to repair my car)
Let + Kişi + V1 (İzin vermek)
Make + Kişi + V1 (Zorlamak)
''',
      examples: [
        GrammarExample(
          english: 'I had my hair cut.',
          turkish: 'Saçımı kestirdim.',
          note: 'Have sth V3',
        ),
        GrammarExample(
          english: 'I will get my car fixed.',
          turkish: 'Arabamı tamir ettireceğim.',
          note: 'Get sth V3',
        ),
        GrammarExample(
          english: 'She made me cry.',
          turkish: 'Beni ağlattı.',
          note: 'Make someone V1',
        ),
      ],
      examTip: '💡 Sınavda boşluktan sonra "NESNE" varsa V3, "KİŞİ" varsa fiilin yapısına (have/make -> V1, get -> to V1) bakın.',
    ),

    // 3. INVERSION
    GrammarSubtopic(
      id: 'inversion',
      title: 'Inversion',
      titleTr: 'Devrik Cümle',
      explanation: '''
Vurguyu artırmak için yardımcı fiilin öznenin önüne gelmesi durumudur (Soru sorar gibi ama soru değildir). Genellikle olumsuz zarflar cümlenin başına geldiğinde oluşur.

🎯 Ne zaman yapılır?
• Olumsuz zarflar başta ise (Never, Seldom, Rarely, Hardly...)
• "Only" ile başlayan zaman ifadeleri başta ise (Only when, Only then...)
• Conditional Type 1, 2, 3 (If atılarak devrik yapılır)
''',
      formula: '''
Negative Adverb + Auxiliary Verb + Subject + Main Verb
Ex: Never have I seen...
''',
      examples: [
        GrammarExample(
          english: 'Never have I seen such a thing.',
          turkish: 'Hayatımda böyle bir şey görmedim.',
          note: 'Normal: I have never seen...',
        ),
        GrammarExample(
          english: 'Rarely do we go out.',
          turkish: 'Nadiren dışarı çıkarız.',
          note: 'Normal: We rarely go out.',
        ),
        GrammarExample(
          english: 'Hardly had I entered when the phone rang.',
          turkish: 'Tam içeri girmiştim ki telefon çaldı.',
          note: 'Hardly...when kalıbı',
        ),
        GrammarExample(
          english: 'Should you need help, call me.',
          turkish: 'Yardıma ihtiyacın olursa beni ara.',
          note: 'If you should need... -> Should you need...',
        ),
      ],
      keyPoints: [
        '🔑 Sadece "Yardımcı Fiil" başa gelir, ana fiil gelmez.',
        '🔑 "Not only... but also": Not only DID he steal, but also he lied.',
      ],
      examTip: '💡 Cümle "Never, Rarely, Scarcely, No sooner" ile başlıyorsa hemen devrik yapı (Yardımcı fiil + Özne) arayın.',
    ),

    // 4. COMPARISON
    GrammarSubtopic(
      id: 'comparison',
      title: 'Comparison',
      titleTr: 'Karşılaştırma',
      explanation: '''
Sıfat ve zarfları karşılaştırmak için kullanılır.

🎯 Yapılar:
• Comparative (-er / more): İki şeyi kıyaslar (taller than, more expensive than)
• Superlative (the -est / the most): En üstünlük (the tallest, the most expensive)
• As...as: Eşitlik (as tall as)
• The more... the more...: Ne kadar... o kadar...
''',
      formula: '''
Adj+er / More + Adj + than
The + Adj+est / The most + Adj
''',
      examples: [
        GrammarExample(
          english: 'This car is faster than yours.',
          turkish: 'Bu araba seninkinden daha hızlı.',
          note: 'Comparative',
        ),
        GrammarExample(
          english: 'He is the smartest student in the class.',
          turkish: 'Sınıftaki en zeki öğrenci.',
          note: 'Superlative',
        ),
        GrammarExample(
          english: 'Run as fast as you can.',
          turkish: 'Koşabildiğin kadar hızlı koş.',
          note: 'Eşitlik',
        ),
        GrammarExample(
          english: 'The more you study, the more you learn.',
          turkish: 'Ne kadar çok çalışırsan, o kadar çok öğrenirsin.',
          note: 'Double Comparative',
        ),
      ],
      keyPoints: [
        '🔑 Düzensizler: Good->Better->Best, Bad->Worse->Worst, Far->Farther/Further->Farthest/Furthest.',
        '🔑 "Farther" fiziksel mesafe, "Further" hem mesafe hem soyut (daha fazla, ileri) anlamdadır.',
      ],
      examTip: '💡 "Of the two..." kalıbı varsa COMPARATIVE ve THE kullanılır: "He is THE TALLER of the two boys."',
    ),
  ],
);
