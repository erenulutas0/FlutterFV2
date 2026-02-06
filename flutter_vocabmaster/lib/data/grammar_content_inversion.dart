import 'package:flutter/material.dart';
import 'grammar_data.dart';

/// INVERSION (Exam Grammar)
const inversionTopic = GrammarTopic(
  id: 'inversion',
  title: 'Inversion',
  titleTr: 'Devrik Cümle',
  level: 'exam',
  icon: Icons.swap_vert,
  color: Color(0xFFef4444),
  subtopics: [
    // 1. NEGATIVE ADVERB INVERSION
    GrammarSubtopic(
      id: 'negative_adverb_inversion',
      title: 'Negative Adverb Inversion',
      titleTr: 'Olumsuz Zarfla Devrik Yapı',
      explanation: '''
Olumsuz veya kısıtlayıcı zarflar cümle başına geldiğinde, vurgu yaratmak için YARDIMCI FİİL ve ÖZNE yer değiştirir. Cümle soru sorar gibi görünür ama soru değildir.

🎯 DEVRİKLİK GEREKTİREN ZARFLAR:

• NEVER: Asla, hiçbir zaman
  "Never have I seen such a thing."

• RARELY / SELDOM: Nadiren
  "Rarely do we see such behavior."

• HARDLY / SCARCELY: Güçlükle, neredeyse hiç
  "Hardly had I arrived when it started raining."

• BARELY: Güçbela
  "Barely had he finished when the bell rang."

• LITTLE: Az (olumsuz anlamda)
  "Little did he know that..."

• NO SOONER...THAN: ...ir ...mez
  "No sooner had I left than it started raining."

• NOT UNTIL: ...e kadar ...değil
  "Not until yesterday did I learn the truth."

⚠️ KRİTİK:
Sadece YARDIMCI FİİL başa gelir, ANA FİİL gelmez!
''',
      formula: '''
Negative Adverb + Auxiliary + Subject + Main Verb

Normal: I have NEVER seen this.
Inverted: NEVER HAVE I seen this.

Normal: I HAD NO SOONER left THAN it rained.
Inverted: NO SOONER HAD I left THAN it rained.
''',
      examples: [
        GrammarExample(
          english: 'Never have I experienced such kindness.',
          turkish: 'Hiçbir zaman böyle bir nezaket görmedim.',
          note: 'Never + have + I',
        ),
        GrammarExample(
          english: 'Rarely does she go to the cinema.',
          turkish: 'Nadiren sinemaya gider.',
          note: 'Rarely + does + she',
        ),
        GrammarExample(
          english: 'Hardly had I entered when the phone rang.',
          turkish: 'Tam içeri girmiştim ki telefon çaldı.',
          note: 'Hardly...when + Past Perfect',
        ),
        GrammarExample(
          english: 'No sooner had he arrived than everyone left.',
          turkish: 'O gelir gelmez herkes gitti.',
          note: 'No sooner...than',
        ),
        GrammarExample(
          english: 'Little did she know about his secret.',
          turkish: 'Onun sırrı hakkında pek az şey biliyordu.',
          note: 'Little + did + she',
        ),
        GrammarExample(
          english: 'Never I have seen such a thing.',
          turkish: 'Hiç böyle bir şey görmedim.',
          isCorrect: false,
          note: '❌ YANLIŞ! Never HAVE I...',
        ),
      ],
      commonMistakes: [
        '❌ Never I have seen... → ✅ Never HAVE I seen...',
        '❌ Rarely she goes... → ✅ Rarely DOES she go...',
        '❌ Hardly I had arrived... → ✅ Hardly HAD I arrived...',
        '❌ No sooner he had left... → ✅ No sooner HAD he left...',
      ],
      keyPoints: [
        '🔑 Olumsuz zarf başta → Yardımcı fiil + Özne + Ana fiil',
        '🔑 "Hardly/Scarcely...when" ve "No sooner...than" → Past Perfect kullanılır',
        '🔑 Ana fiil (main verb) asla başa gelmez, sadece yardımcı fiil gelir',
        '🔑 Simple tense\'lerde "do/does/did" yardımcı fiil olarak eklenir',
      ],
      examTip: '💡 YDS\'de "Never, Rarely, Seldom, Hardly, No sooner" ile başlayan cümlede devrik yapı (Aux + S) olmazsa YANLIŞ!',
    ),

    // 2. ONLY INVERSION
    GrammarSubtopic(
      id: 'only_inversion',
      title: '"Only" Inversions',
      titleTr: '"Only" ile Devrik Yapı',
      explanation: '''
"Only" ile başlayan zaman, yer veya koşul ifadeleri cümle başında olduğunda devriklik gerektirir.

🎯 "ONLY" KALIPLARI:

• ONLY THEN: Ancak o zaman
  "Only then did I realize my mistake."

• ONLY WHEN: Ancak ...dığında
  "Only when I got home did I notice..."

• ONLY AFTER: Ancak ...den sonra
  "Only after the exam did he relax."

• ONLY BY: Ancak ...erek
  "Only by working hard can you succeed."

• ONLY IF: Ancak ...rsa
  "Only if you study will you pass."

• ONLY IN THIS WAY: Ancak bu şekilde
  "Only in this way can we solve the problem."

⚠️ NOT:
• "Only" yalnız başına cümle başında olursa devriklik OLMAZ
  "Only 10 people came." (Sadece 10 kişi geldi - devrik değil)
• "Only + zaman/koşul" olunca devriklik OLUR
  "Only then did I understand." (Devrik)
''',
      formula: '''
Only + Time/Condition + Auxiliary + Subject + Verb

"Only after the war did reconstruction begin."
"Only by chance did I discover the truth."
''',
      examples: [
        GrammarExample(
          english: 'Only when he left did I realize my mistake.',
          turkish: 'Ancak o gidince hatamı fark ettim.',
          note: 'Only when + devrik ana cümle',
        ),
        GrammarExample(
          english: 'Only then did she understand the problem.',
          turkish: 'Ancak o zaman sorunu anladı.',
          note: 'Only then + did + she',
        ),
        GrammarExample(
          english: 'Only by studying hard can you pass.',
          turkish: 'Ancak çok çalışarak geçebilirsin.',
          note: 'Only by + V-ing',
        ),
        GrammarExample(
          english: 'Only if you help me will I finish on time.',
          turkish: 'Ancak bana yardım edersen zamanında bitiririm.',
          note: 'Only if + devrik ana cümle',
        ),
        GrammarExample(
          english: 'Only when she left I realized.',
          turkish: 'Ancak o gidince fark ettim.',
          isCorrect: false,
          note: '❌ YANLIŞ! Only when she left DID I realize.',
        ),
      ],
      commonMistakes: [
        '❌ Only then I understood. → ✅ Only then DID I understand.',
        '❌ Only when he came I knew. → ✅ Only when he came DID I know.',
        '❌ Only by work hard can we... → ✅ Only by WORKING hard can we...',
      ],
      keyPoints: [
        '🔑 "Only" tek başına → devrik YOK ("Only 10 people came.")',
        '🔑 "Only + zaman/koşul ifadesi" → devrik VAR',
        '🔑 Devriklik ANA CÜMLEDE olur, "only" cümleciğinde değil',
        '🔑 "Only by" sonrası genellikle V-ing gelir',
      ],
      examTip: '💡 YDS\'de "Only when/after/then" görürseniz, takip eden cümlede devrik yapı (did/had/would + subject) arayın.',
    ),

    // 3. CONDITIONAL INVERSION
    GrammarSubtopic(
      id: 'conditional_inversion',
      title: 'Conditional Inversion',
      titleTr: 'Koşullu Devrik Cümle',
      explanation: '''
Conditional (If) cümlelerinde "If" atılarak devrik yapı kurulabilir. Bu daha formal ve edebi bir yapıdır.

🎯 DÖNÜŞÜM KURALLARI:

TYPE 1 (If + Present → Should):
"If you need help, call me."
→ "Should you need help, call me."

TYPE 2 (If + Past → Were):
"If I were you, I would accept."
→ "Were I you, I would accept."

TYPE 3 (If + Past Perfect → Had):
"If I had known, I would have come."
→ "Had I known, I would have come."

💡 NOT:
• "If" tamamen atılır
• Yardımcı fiil (Should/Were/Had) başa gelir
• "Was" yerine mutlaka "WERE" kullanılır
''',
      formula: '''
If + S + should → Should + S + V1
If + S + were → Were + S
If + S + had V3 → Had + S + V3

"If he should come..." → "Should he come..."
"If I were rich..." → "Were I rich..."
"If they had left..." → "Had they left..."
''',
      examples: [
        GrammarExample(
          english: 'Should you need any help, please let me know.',
          turkish: 'Yardıma ihtiyacın olursa, bana haber ver.',
          note: 'If you should need → Should you need',
        ),
        GrammarExample(
          english: 'Were I in your position, I would resign.',
          turkish: 'Senin yerinde olsam, istifa ederdim.',
          note: 'If I were → Were I',
        ),
        GrammarExample(
          english: 'Had I known about the problem, I would have helped.',
          turkish: 'Sorunu bilseydim yardım ederdim.',
          note: 'If I had known → Had I known',
        ),
        GrammarExample(
          english: 'Were it not for his help, we would have failed.',
          turkish: 'Onun yardımı olmasaydı başarısız olurduk.',
          note: 'If it were not for → Were it not for',
        ),
        GrammarExample(
          english: 'Was I you, I would leave.',
          turkish: 'Senin yerinde olsam giderdim.',
          isCorrect: false,
          note: '❌ YANLIŞ! Was değil WERE kullanılır',
        ),
      ],
      commonMistakes: [
        '❌ Was I rich, I would... → ✅ WERE I rich, I would...',
        '❌ If would you help me... → ✅ Should you help me... (would olmaz!)',
        '❌ Had I knew... → ✅ Had I KNOWN... (V3 olmalı)',
      ],
      keyPoints: [
        '🔑 Type 1: If should → Should + S',
        '🔑 Type 2: If were → Were + S (was yerine were!)',
        '🔑 Type 3: If had V3 → Had + S + V3',
        '🔑 Bu yapı formal/yazılı dilde daha yaygındır',
      ],
      examTip: '💡 YDS\'de "Should you, Were I, Had he" ile başlayan cümleler koşullu devrik cümlelerdir. "If" yoktur!',
    ),

    // 4. OTHER INVERSIONS
    GrammarSubtopic(
      id: 'other_inversions',
      title: 'Other Inversions',
      titleTr: 'Diğer Devrik Yapılar',
      explanation: '''
Diğer durumlarda da devrik yapı kullanılabilir.

🎯 SO / NEITHER / NOR:
Aynı durumu ifade ederken:
"I am tired." - "So am I." (Ben de.)
"I don't like it." - "Neither/Nor do I." (Ben de sevmiyorum.)

🎯 NOT ONLY...BUT ALSO:
"Not only" cümle başında olduğunda:
"Not only did he apologize, but he also paid for the damage."

🎯 YER ZARFLARI (Edebi dil):
"Here comes the bus." (İşte otobüs geliyor.)
"There goes my chance." (İşte şansım gitti.)
"Up went the balloon." (Balon yukarı çıktı.)

🎯 "SO + ADJ/ADV" BAŞA GELİRSE:
"So beautiful was the view that I took photos."
(Manzara o kadar güzeldi ki fotoğraf çektim.)

🎯 "AS / THOUGH" İLE:
"Try as she might, she couldn't succeed."
(Ne kadar denese de başaramadı.)
''',
      formula: '''
So + Aux + S (katılma)
Neither/Nor + Aux + S (olumsuz katılma)

Not only + did/had/was + S + V...

So + adj + Aux + S + that...
''',
      examples: [
        GrammarExample(
          english: '"I love coffee." - "So do I."',
          turkish: '"Kahve seviyorum." - "Ben de."',
          note: 'So + do + I',
        ),
        GrammarExample(
          english: '"I don\'t smoke." - "Neither do I."',
          turkish: '"Sigara içmiyorum." - "Ben de içmiyorum."',
          note: 'Neither + do + I',
        ),
        GrammarExample(
          english: 'Not only did she win, but she also broke the record.',
          turkish: 'Sadece kazanmakla kalmadı, rekoru da kırdı.',
          note: 'Not only + did + she',
        ),
        GrammarExample(
          english: 'So surprised was I that I couldn\'t speak.',
          turkish: 'O kadar şaşırdım ki konuşamadım.',
          note: 'So + adj + was + I',
        ),
        GrammarExample(
          english: 'Here the bus comes.',
          turkish: 'İşte otobüs geliyor.',
          isCorrect: false,
          note: '❌ YANLIŞ! Here COMES the bus.',
        ),
      ],
      commonMistakes: [
        '❌ So I do. → ✅ So DO I.',
        '❌ Neither I do. → ✅ Neither DO I.',
        '❌ Not only he came... → ✅ Not only DID he come...',
        '❌ Here the train comes. → ✅ Here COMES the train.',
      ],
      keyPoints: [
        '🔑 So/Neither/Nor + Auxiliary + Subject',
        '🔑 "Not only" başta ise devrik, ortada ise devrik yok',
        '🔑 "Here/There" + verb + subject (edebi)',
        '🔑 Zamirle (I, he, she) "Here/There" devriliği yapılmaz: "Here it is." (Devrik değil)',
      ],
      examTip: '💡 YDS\'de "So do I, Neither did she, Not only did he" kalıpları çok çıkar. Auxiliary + Subject sırasına dikkat!',
    ),
  ],
);
