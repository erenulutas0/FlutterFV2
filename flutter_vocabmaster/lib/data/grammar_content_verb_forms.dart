import 'package:flutter/material.dart';
import 'grammar_data.dart';

/// VERB FORMS (Core Grammar)
const verbFormsTopic = GrammarTopic(
  id: 'verb_forms',
  title: 'Verb Forms',
  titleTr: 'Fiil Cümlecikleri',
  level: 'core',
  icon: Icons.text_fields,
  color: Color(0xFF22c55e),
  subtopics: [
    // 1. GERUND vs INFINITIVE
    GrammarSubtopic(
      id: 'gerund_vs_infinitive',
      title: 'Gerund vs Infinitive',
      titleTr: 'İsim Fiil vs Mastar',
      explanation: '''
İngilizcede fiilleri isimleştirmek için iki yöntem vardır:
1. Gerund (Fiil + -ing): "Swimming is fun."
2. Infinitive (to + Fiil): "To swim is fun."

Hangi fiilden sonra hangisinin geleceği ezber gerektirir ancak bazı mantıksal kurallar vardır.

🎯 Gerund (-ing) Kullanımı:
• Cümlenin öznesi olarak (Swimming is good.)
• Edatlardan (preposition) sonra (interested in learning)
• Bazı belirli fiillerden sonra (enjoy, finish, mind, avoid)

🎯 Infinitive (to V1) Kullanımı:
• Amaç bildirmek için (I went to the store *to buy* milk.)
• Sıfatlardan sonra (This problem is hard *to solve*.)
• Bazı belirli fiillerden sonra (want, decide, hope, promise)
''',
      formula: '''
Gerund: V-ing
Infinitive: to + V1
''',
      examples: [
        GrammarExample(
          english: 'I enjoy reading books.',
          turkish: 'Kitap okumaktan zevk alırım.',
          note: 'Enjoy + V-ing',
        ),
        GrammarExample(
          english: 'She decided to stay home.',
          turkish: 'Evde kalmaya karar verdi.',
          note: 'Decide + to V1',
        ),
        GrammarExample(
          english: 'He is interested in learning Spanish.',
          turkish: 'İspanyolca öğrenmekle ilgileniyor.',
          note: 'Preposition (in) + V-ing',
        ),
        GrammarExample(
          english: 'It is important to be honest.',
          turkish: 'Dürüst olmak önemlidir.',
          note: 'Sıfat (important) + to V1',
        ),
      ],
      commonMistakes: [
        '❌ I enjoy to read. → ✅ I enjoy reading.',
        '❌ She wants going home. → ✅ She wants to go home.',
        '❌ Thank you for help me. → ✅ Thank you for helping me.',
      ],
      keyPoints: [
        '🔑 Preposition (in, on, at, for, of) varsa kesinlikle V-ing gelir',
        '🔑 "Stop, try, remember, forget" gibi fiiller her ikisini de alır ama anlam değişir',
        '🔑 Amaç bildirmek için her zaman "to V1" kullanılır (for V-ing değil)',
      ],
      comparison: '''
🆚 Anlam Değiştiren Fiiller (Stop / Try / Remember / Forget):

Stop:
• Stop smoking (Sigara içmeyi bırak - alışkanlığı sonlandır)
• Stop to smoke (Sigara içmek için dur - eylemi kesip başka şeye başla)

Remember:
• Remember locking the door (Kapıyı kilitlediğini hatırla - geçmiş anı)
• Remember to lock the door (Kapıyı kilitlemeyi hatırla/unutma - gelecek görev)

Try:
• Try opening the window (Pencereyi açmayı dene - bir yöntem olarak dene)
• Try to open the window (Pencereyi açmaya çalış - çaba sarf et, zorlan)
''',
      examTip: '💡 YDS\'de boşluktan önce preposition varsa (of, in, at, with, about) %99 V-ing gelir. Boşluktan önce sıfat varsa (happy, sad, easy) genellikle to V1 gelir.',
    ),

    // 2. INFINITIVE WITHOUT TO
    GrammarSubtopic(
      id: 'bare_infinitive',
      title: 'Bare Infinitive',
      titleTr: 'Yalın Mastar (to\'suz)',
      explanation: '''
Bazı durumlarda fiil mastar (infinitive) halinde kullanılır ama başına "to" gelmez. Buna "Bare Infinitive" denir.

🎯 Ne zaman kullanılır?
• Modallardan sonra (must, can, should, will...)
• "Let" ve "Make" fiillerinden sonra (nesne ile)
• "Help" fiilinden sonra (hem to'lu hem to'suz olur)
• Duyu fiillerinden sonra (see, hear, feel, watch - olayın tamamı görüldüyse)
• "Had better" ve "Would rather" kalıplarından sonra
''',
      formula: '''
Subject + Modal + V1 (to yok!)
Let + Object + V1
Make + Object + V1
It's time + V1 (değil!) -> It's time to V1
''',
      examples: [
        GrammarExample(
          english: 'She can swim well.',
          turkish: 'O iyi yüzebilir.',
          note: 'Modal sonrası',
        ),
        GrammarExample(
          english: 'My father let me drive his car.',
          turkish: 'Babam arabasını sürmeme izin verdi.',
          note: 'Let + me + drive',
        ),
        GrammarExample(
          english: 'The teacher made us do homework.',
          turkish: 'Öğretmen bize ödev yaptırdı.',
          note: 'Make + us + do',
        ),
        GrammarExample(
          english: 'I saw him cross the street.',
          turkish: 'Caddeden geçtiğini gördüm.',
          note: 'See + him + cross (tamamı)',
        ),
      ],
      commonMistakes: [
        '❌ Let me to go. → ✅ Let me go.',
        '❌ She made me to cry. → ✅ She made me cry.',
        '❌ I can to swim. → ✅ I can swim.',
        '❌ You had better to study. → ✅ You had better study.',
      ],
      keyPoints: [
        '🔑 "Make" pasif yapılırsa "to" alır: "We were made TO do homework."',
        '🔑 "Help" fiili opsiyoneldir: "Help me do" veya "Help me TO do"',
        '🔑 "Why not...?" kalıbı V1 alır: "Why not go to the cinema?"',
      ],
      examTip: '💡 "Let" ve "Make" (aktif) fiillerinden sonra gelen fiil asla "to" almaz.',
    ),

    // 3. VERB + OBJECT + INFINITIVE
    GrammarSubtopic(
      id: 'verb_object_infinitive',
      title: 'Verb + Object + Infinitive',
      titleTr: 'Fiil + Nesne + Mastar',
      explanation: '''
Bazı fiillerden sonra bir nesne (kişi/zamir) gelir ve ardından yapılacak eylem "to V1" ile belirtilir. Bu yapı genellikle birinden bir şey yapmasını istemek, beklemek veya izin vermek anlamı taşır.

🎯 Hangi fiiller?
• want, expect, ask, tell, advise, allow, permit, persuade, order, remind, warn, encourage...
''',
      formula: '''
Subject + Verb + Object + to V1
''',
      examples: [
        GrammarExample(
          english: 'I want you to help me.',
          turkish: 'Bana yardım etmeni istiyorum.',
          note: 'Want + you + to help',
        ),
        GrammarExample(
          english: 'She told him to wait.',
          turkish: 'Ona beklemesini söyledi.',
          note: 'Tell + him + to wait',
        ),
        GrammarExample(
          english: 'They advised us not to go out.',
          turkish: 'Bize dışarı çıkmamamızı tavsiye ettiler.',
          note: 'Advised + us + not to go',
        ),
        GrammarExample(
          english: 'My parents allowed me to stay late.',
          turkish: 'Ailem geç kalmama izin verdi.',
          note: 'Allowed + me + to stay',
        ),
      ],
      commonMistakes: [
        '❌ I want that you help me. → ✅ I want you to help me.',
        '❌ She told to him wait. → ✅ She told him to wait.',
        '❌ Advised to not go. → ✅ Advised not to go.',
      ],
      keyPoints: [
        '🔑 "Say" ve "Suggest" bu gruba girmez! Onlar "that clause" alır.',
        '  ❌ I said him to go.',
        '  ✅ I said that he should go.',
        '  ❌ I suggested him to go.',
        '  ✅ I suggested that he go.',
      ],
      comparison: '''
🆚 Verb Pattern Farkları:
• Want someone TO do something: "I want you to come."
• Make someone DO something: "I made you come."
• Let someone DO something: "I let you come."
• Suggest DOING something: "I suggest coming."
''',
      examTip: '💡 "Advise, allow, permit, recommend" fiilleri: Nesne varsa "to V1", nesne yoksa "V-ing" alırlar. Ex: "They allowed us to park." vs "They allowed parking."',
    ),
  ],
);
