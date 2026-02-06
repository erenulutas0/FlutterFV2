import 'package:flutter/material.dart';
import 'grammar_data.dart';

/// CONJUNCTIONS & LINKERS (Advanced Grammar)
const conjunctionsTopic = GrammarTopic(
  id: 'conjunctions',
  title: 'Conjunctions & Linkers',
  titleTr: 'Bağlaçlar',
  level: 'advanced',
  icon: Icons.merge_type,
  color: Color(0xFFf59e0b),
  subtopics: [
    // 1. COORDINATING CONJUNCTIONS
    GrammarSubtopic(
      id: 'coordinating_conjunctions',
      title: 'Coordinating Conjunctions',
      titleTr: 'Eşit Bağlaçlar (FANBOYS)',
      explanation: '''
İki eşit dilbilgisel yapıyı (iki cümle, iki isim, iki sıfat) birbirine bağlayan bağlaçlardır.

🎯 FANBOYS (7 Koordine Bağlaç):

• FOR: Çünkü (sebep - literary/resmi)
  "I stayed home, for I was sick."

• AND: Ve (ekleme)
  "I bought bread and milk."

• NOR: Ne de (olumsuz ekleme)
  "I don't like tea, nor do I like coffee."

• BUT: Ama, fakat (zıtlık)
  "He is poor but happy."

• OR: Veya (alternatif)
  "Do you want tea or coffee?"

• YET: Ama, yine de (zıtlık, güçlü)
  "He is rich, yet he is unhappy."

• SO: Bu yüzden (sonuç)
  "It was late, so I went home."

⚠️ NOT:
İki tam cümleyi bağlarken VİRGÜL kullanılır!
"I was tired, so I went to bed."
''',
      formula: '''
S + V, FANBOYS + S + V
  "I was hungry, so I ate."

Noun + FANBOYS + Noun
  "Tea or coffee?"
''',
      examples: [
        GrammarExample(
          english: 'I wanted to go, but I was too tired.',
          turkish: 'Gitmek istedim ama çok yorgundum.',
          note: 'But - zıtlık',
        ),
        GrammarExample(
          english: 'Study hard, or you will fail.',
          turkish: 'Çok çalış, yoksa başarısız olursun.',
          note: 'Or - alternatif/sonuç',
        ),
        GrammarExample(
          english: 'She is young, yet she is very mature.',
          turkish: 'Genç ama çok olgun.',
          note: 'Yet - güçlü zıtlık',
        ),
        GrammarExample(
          english: 'I neither smoke nor drink.',
          turkish: 'Ne sigara içerim ne içki.',
          note: 'Neither...nor',
        ),
      ],
      commonMistakes: [
        '❌ I was tired and so I went to bed. → ✅ I was tired, so I went to bed.',
        '❌ He nor I went. → ✅ Neither he nor I went.',
        '❌ I don\'t like tea, nor I like coffee. → ✅ ...nor DO I like coffee. (devrik)',
      ],
      keyPoints: [
        '🔑 "Nor" ile devrik yapı gerekir: "Nor DO I..."',
        '🔑 İki tam cümle bağlanırken virgül konur',
        '🔑 "For" (sebep) yalnızca cümle başında değil, cümle ortasında kullanılır',
        '🔑 "Yet" = but (daha güçlü, şaşırtıcı zıtlık)',
      ],
      examTip: '💡 YDS\'de "nor" ile başlayan cümlede devrik yapı aranır. "Nor does he..." doğrudur.',
    ),

    // 2. SUBORDINATING CONJUNCTIONS
    GrammarSubtopic(
      id: 'subordinating_conjunctions',
      title: 'Subordinating Conjunctions',
      titleTr: 'Yan Cümle Bağlaçları',
      explanation: '''
Bir ana cümleye bağımlı yan cümle ekleyen bağlaçlardır. Yan cümle tek başına anlam vermez.

🎯 KATEGORİLER:

📅 ZAMAN (Time):
when, while, as, before, after, until, since, as soon as, once, by the time

📌 SEBEP (Reason):
because, since, as, now that, in that

🔀 ZITLIK (Contrast):
although, though, even though, while, whereas, even if

🎯 AMAÇ (Purpose):
so that, in order that

📊 SONUÇ (Result):
so...that, such...that

🔍 KOŞUL (Condition):
if, unless, provided (that), providing (that), as long as, in case

📋 KARŞILAŞTIRMA (Comparison):
as, than, as...as

🎭 MANNER (Tarz):
as, as if, as though, like (informal)
''',
      formula: '''
Subordinate Clause + Main Clause (virgül var)
Main Clause + Subordinate Clause (virgül yok)

"Because I was late, I missed the bus."
"I missed the bus because I was late."
''',
      examples: [
        GrammarExample(
          english: 'I\'ll wait here until you come back.',
          turkish: 'Sen dönene kadar burada bekleyeceğim.',
          note: 'Until - süre',
        ),
        GrammarExample(
          english: 'Although he studied hard, he failed.',
          turkish: 'Çok çalışmasına rağmen başarısız oldu.',
          note: 'Although - zıtlık',
        ),
        GrammarExample(
          english: 'I\'ll lend you money provided that you pay me back.',
          turkish: 'Geri ödemen şartıyla sana borç veririm.',
          note: 'Provided that - koşul',
        ),
        GrammarExample(
          english: 'He acts as if he were the boss.',
          turkish: 'Patron oymuş gibi davranıyor.',
          note: 'As if + past (unreal)',
        ),
      ],
      keyPoints: [
        '🔑 Yan cümle başta ise VİRGÜL, sonda ise virgül yok',
        '🔑 "As if/As though" + Past → Gerçek olmayan durum',
        '🔑 "Provided that" = "If" (daha güçlü koşul)',
        '🔑 "In case" = "...olur diye" (ihtimale karşı)',
      ],
      comparison: '''
🆚 In case vs If:
• IF: "I'll take an umbrella IF it rains." (Yağarsa alırım - o zaman alırım)
• IN CASE: "I'll take an umbrella IN CASE it rains." (Yağabilir diye alırım - önceden hazırlık)

🆚 As if vs Like:
• As if + Clause: "He looks as if he is tired." (Yorgun görünüyor)
• Like + Noun: "He looks like a ghost." (Hayalet gibi görünüyor)
''',
      examTip: '💡 "As long as" = If, "Provided that" = If (güçlü koşul), "Unless" = If not',
    ),

    // 3. CORRELATIVE CONJUNCTIONS
    GrammarSubtopic(
      id: 'correlative_conjunctions',
      title: 'Correlative Conjunctions',
      titleTr: 'İkili Bağlaçlar',
      explanation: '''
Çiftler halinde kullanılan bağlaçlardır. Her iki parça da birlikte kullanılmalıdır.

🎯 İKİLİ BAĞLAÇLAR:

• BOTH...AND: Hem...hem de
  "He is both smart and hardworking."

• EITHER...OR: Ya...ya da
  "You can either stay or leave."

• NEITHER...NOR: Ne...ne de
  "She neither called nor texted."

• NOT ONLY...BUT ALSO: Sadece...değil, aynı zamanda
  "He is not only intelligent but also kind."

• WHETHER...OR: ...olsun veya olmasın
  "Whether you like it or not, you must do it."

• NO SOONER...THAN: ...ir ...mez
  "No sooner had I arrived than it started raining."

• HARDLY/SCARCELY...WHEN: Tam ...mıştım ki
  "Hardly had I entered when the phone rang."

💡 PARALELLIK KURALI:
İkili bağlaçlardan sonra gelen yapılar DİLBİLGİSEL OLARAK AYNI olmalıdır!
''',
      formula: '''
Both + X + and + X
Either + X + or + X
Neither + X + nor + X
Not only + X + but also + X

⚠️ X = aynı yapı (noun-noun, verb-verb, adj-adj)
''',
      examples: [
        GrammarExample(
          english: 'She is both intelligent and beautiful.',
          turkish: 'Hem zeki hem güzel.',
          note: 'Both...and (adj + adj)',
        ),
        GrammarExample(
          english: 'Either you apologize or I will leave.',
          turkish: 'Ya özür dilersin ya da giderim.',
          note: 'Either...or (clause + clause)',
        ),
        GrammarExample(
          english: 'He can neither read nor write.',
          turkish: 'Ne okuyabilir ne yazabilir.',
          note: 'Neither...nor (verb + verb)',
        ),
        GrammarExample(
          english: 'Not only did he arrive late, but he also forgot his notes.',
          turkish: 'Sadece geç kalmakla kalmadı, notlarını da unuttu.',
          note: 'Not only (başta) → devrik + but also',
        ),
        GrammarExample(
          english: 'No sooner had I sat down than the phone rang.',
          turkish: 'Oturur oturmaz telefon çaldı.',
          note: 'No sooner...than → devrik yapı',
        ),
      ],
      commonMistakes: [
        '❌ Both smart and is kind. → ✅ Both smart and kind. (paralel)',
        '❌ Neither I nor she are... → ✅ Neither I nor she IS... (or\'a yakın özne)',
        '❌ Not only he arrived late... → ✅ Not only DID he arrive late... (devrik)',
      ],
      keyPoints: [
        '🔑 "Not only" cümle başında ise DEVRİK yapı gerekir',
        '🔑 "No sooner...than" / "Hardly...when" → Past Perfect + devrik',
        '🔑 Either...or / Neither...nor → fiil, yakın özneye göre çekilir',
        '🔑 Paralellik: Her iki taraf da aynı yapıda olmalı',
      ],
      examTip: '💡 YDS\'de "Not only" cümle başında görürseniz devrik yapı (Did he, Had he, Was he) arayın!',
    ),

    // 4. TRANSITION WORDS
    GrammarSubtopic(
      id: 'transition_words',
      title: 'Transition Words & Phrases',
      titleTr: 'Geçiş Sözcükleri (Linkers)',
      explanation: '''
Cümleler veya paragraflar arasında mantıksal geçiş sağlayan sözcüklerdir. Genellikle yeni cümle başında kullanılır.

🎯 EKLEME (Addition):
• Moreover, Furthermore, In addition, Besides, Also, What\'s more

🎯 ZITLIK (Contrast):
• However, Nevertheless, Nonetheless, On the other hand, In contrast, Yet, Still

🎯 SONUÇ (Result):
• Therefore, Thus, Hence, Consequently, As a result, Accordingly, For this reason

🎯 ÖRNEKLER (Examples):
• For example, For instance, Such as, Namely, In particular

🎯 SIRALLAMA (Sequence):
• First, Secondly, Then, Next, Finally, Lastly

🎯 ÖZET (Summary):
• In conclusion, To sum up, In summary, All in all, Overall

⚠️ NOKTALAMA:
Bu sözcükler genellikle virgül ile ayrılır!
"He is rich. However, he is not happy."
"He studied hard. Therefore, he passed."
''',
      formula: '''
S + V. [Linker], S + V.
  "It rained. However, we went out."

S + V; [linker], S + V.
  "It rained; however, we went out."
''',
      examples: [
        GrammarExample(
          english: 'The project was difficult. Nevertheless, we completed it on time.',
          turkish: 'Proje zordu. Yine de zamanında tamamladık.',
          note: 'Nevertheless - zıtlık',
        ),
        GrammarExample(
          english: 'He is very qualified. Moreover, he has great experience.',
          turkish: 'Çok nitelikli. Dahası, çok deneyimli.',
          note: 'Moreover - ekleme',
        ),
        GrammarExample(
          english: 'I was tired. Therefore, I went to bed early.',
          turkish: 'Yorgundum. Bu yüzden erken yattım.',
          note: 'Therefore - sonuç',
        ),
        GrammarExample(
          english: 'Many fruits are healthy; for example, apples and oranges.',
          turkish: 'Birçok meyve sağlıklı; örneğin elma ve portakal.',
          note: 'For example - örnek',
        ),
      ],
      commonMistakes: [
        '❌ However he is rich, he is not happy. → ✅ Although he is rich... / He is rich. However, he is not happy.',
        '❌ Therefore the rain, we stayed home. → ✅ Because of the rain... / It rained. Therefore, we stayed home.',
        '❌ He is smart, moreover he is kind. → ✅ He is smart. Moreover, he is kind. (yeni cümle)',
      ],
      keyPoints: [
        '🔑 Linker\'lar genellikle yeni cümle başlatır (nokta veya noktalı virgülden sonra)',
        '🔑 Linker\'dan sonra genellikle virgül konur',
        '🔑 "However" ≠ "Although" - farklı yapılar!',
        '🔑 Although = tek cümle içinde, However = iki cümle arasında',
      ],
      comparison: '''
🆚 Aynı anlam, farklı yapı:

ZITLIK:
• Although he is rich, he is not happy. (tek cümle)
• He is rich. However, he is not happy. (iki cümle)
• Despite being rich, he is not happy. (isim yapısı)

SEBEP/SONUÇ:
• Because it rained, we stayed home. (tek cümle)
• It rained. Therefore, we stayed home. (iki cümle)
• Due to the rain, we stayed home. (isim yapısı)
''',
      examTip: '💡 YDS\'de "However" ile "Although" karıştırılır. Virgül konumuna ve cümle yapısına dikkat edin!',
    ),
  ],
);
