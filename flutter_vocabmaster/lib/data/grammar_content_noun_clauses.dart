import 'package:flutter/material.dart';
import 'grammar_data.dart';

/// NOUN CLAUSES (Advanced Grammar)
const nounClausesTopic = GrammarTopic(
  id: 'noun_clauses',
  title: 'Noun Clauses',
  titleTr: 'İsim Cümlecikleri',
  level: 'advanced',
  icon: Icons.code,
  color: Color(0xFFf59e0b),
  subtopics: [
    // 1. THAT CLAUSES
    GrammarSubtopic(
      id: 'that_clauses',
      title: 'That-Clauses',
      titleTr: 'That ile Kurulan İsim Cümleleri',
      explanation: '''
"That" bağlacı ile kurulan isim cümleleri, düz cümleleri ana cümleye bağlar. Cümlenin öznesi veya nesnesi konumunda olabilir.

🎯 KULLANIM ALANLARI:

1. ÖZNE KONUMUNDA:
"That he is rich is obvious." (Zengin olduğu açık.)
→ Daha doğal: "It is obvious THAT he is rich."

2. NESNE KONUMUNDA (En yaygın):
"I know THAT she is coming."
"I believe THAT he is honest."

3. SIFAT TAMAMLAYICISI:
"I am sure THAT you will succeed."
"It is important THAT you arrive on time."

🎯 "THAT" ATILABİLİR Mİ?
• Nesne konumunda → EVET (I know (that) she is coming)
• Özne konumunda → HAYIR (That he lied is clear)
• Resmi yazıda → Atılmaması tercih edilir
''',
      formula: '''
NESNE: Subject + Verb + (that) + Subject + Verb
  "I think (that) he is right."

ÖZNE: That + S + V + is/was + Adjective/Noun
  "That she won is amazing."
  → It is amazing that she won.
''',
      examples: [
        GrammarExample(
          english: 'I believe (that) she is telling the truth.',
          turkish: 'Doğruyu söylediğine inanıyorum.',
          note: 'Nesne konumu - that atılabilir',
        ),
        GrammarExample(
          english: 'It is obvious that he doesn\'t like his job.',
          turkish: 'İşini sevmediği açık.',
          note: '"It" + that-clause yapısı',
        ),
        GrammarExample(
          english: 'That the earth is round is a fact.',
          turkish: 'Dünyanın yuvarlak olduğu bir gerçektir.',
          note: 'Özne konumu - that atılamaz',
        ),
        GrammarExample(
          english: 'The problem is that we don\'t have enough time.',
          turkish: 'Sorun, yeterli zamanımızın olmaması.',
          note: 'Yüklem tamamlayıcısı',
        ),
        GrammarExample(
          english: 'She afraid that she will fail.',
          turkish: 'Başarısız olacağından korkuyor.',
          isCorrect: false,
          note: '❌ "BE" eksik! "She IS afraid that..."',
        ),
      ],
      commonMistakes: [
        '❌ I think that is he wrong. → ✅ I think that HE IS wrong.',
        '❌ That is he late is a problem. → ✅ That HE IS late is a problem.',
        '❌ I believe he is honest. (resmi yazıda) → ✅ I believe THAT he is honest.',
      ],
      keyPoints: [
        '🔑 "That" sonrası DÜZ CÜMLE (S+V) gelir, soru yapısı gelmez',
        '🔑 "I hope, I think, I believe, I know, I assume, I suppose" gibi fiiller that-clause alır',
        '🔑 "The fact that..." kalıbı prepositionlardan sonra cümle getirmek için kullanılır',
        '🔑 "It is + adj + that..." kalıbı çok yaygındır',
      ],
      examTip: '💡 YDS\'de "The fact that..." veya "It is... that..." kalıpları sık çıkar. Bunlar her zaman tam cümle ister.',
    ),

    // 2. WH-CLAUSES (INDIRECT QUESTIONS)
    GrammarSubtopic(
      id: 'wh_clauses',
      title: 'Wh-Clauses (Embedded Questions)',
      titleTr: 'Wh- ile Kurulan İsim Cümleleri',
      explanation: '''
Wh- soruları (what, where, when, who, why, how) cümle içinde kullanıldığında Noun Clause olur. Bu yapıya "Embedded Question" veya "Indirect Question" da denir.

🎯 KRİTİK KURAL:
Direkt soru → Soru yapısı → "Where DOES she live?"
Indirect soru → DÜZ cümle → "I wonder where she LIVES."

⚠️ ÇOK ÖNEMLİ:
Noun clause içinde soru yapısı (do/does/did + Özne) KULLANILMAZ!
Düz cümle sırası (Özne + Fiil) kullanılır.

🎯 BAŞLATAN FİİLLER:
• I wonder... (merak ediyorum)
• I don't know... (bilmiyorum)
• Can you tell me... (söyler misin)
• Do you know... (biliyor musun)
• I have no idea... (hiç fikrim yok)
''',
      formula: '''
Direct: Wh- + Auxiliary + Subject + Verb?
  "Where DOES he live?"

Indirect: Subject + Verb + Wh- + Subject + Verb
  "I wonder where he LIVES."
  "Can you tell me where he LIVES?"

⚠️ DEVRİKLİK KALKAR!
''',
      examples: [
        GrammarExample(
          english: 'I don\'t know where she lives.',
          turkish: 'Nerede yaşadığını bilmiyorum.',
          note: '✅ where she lives (düz cümle)',
        ),
        GrammarExample(
          english: 'I don\'t know where does she live.',
          turkish: 'Nerede yaşadığını bilmiyorum.',
          isCorrect: false,
          note: '❌ YANLIŞ! Soru yapısı olmaz',
        ),
        GrammarExample(
          english: 'Can you tell me what time the train leaves?',
          turkish: 'Tren kaçta kalkıyor söyler misin?',
          note: '✅ what time the train leaves',
        ),
        GrammarExample(
          english: 'I wonder why he didn\'t come.',
          turkish: 'Neden gelmediğini merak ediyorum.',
          note: 'Past tense - düz sıra',
        ),
        GrammarExample(
          english: 'What she said was interesting.',
          turkish: 'Söylediği şey ilginçti.',
          note: 'Özne konumunda (What she said)',
        ),
      ],
      commonMistakes: [
        '❌ I wonder where IS the bank. → ✅ I wonder where the bank IS.',
        '❌ Tell me what DID he say. → ✅ Tell me what he SAID.',
        '❌ I don\'t know why IS he angry. → ✅ I don\'t know why he IS angry.',
        '❌ Do you know what time IS it? → ✅ Do you know what time IT IS?',
      ],
      keyPoints: [
        '🔑 Noun Clause = DÜZ CÜMLE (Subject + Verb) sırası',
        '🔑 "Do/Does/Did" yardımcı fiilleri Noun Clause\'da KULLANILMAZ',
        '🔑 Zamanı değiştirirken ana fiil çekimlenir, yardımcı fiil başa gelmez',
        '🔑 "How old, how far, how long, what time" gibi ifadeler tek birim olarak kalır',
      ],
      comparison: '''
🆚 Direct vs Indirect Question:
• Direct: "Where does he work?" (Nerede çalışıyor?)
• Indirect: "I wonder where he works." (Nerede çalıştığını merak ediyorum.)

• Direct: "What time is it?" (Saat kaç?)
• Indirect: "Can you tell me what time it is?" (Saat kaç söyler misin?)

💡 Indirect soru sonuna soru işareti konmaz (cümle soru değilse).
"I wonder where he is." → Nokta
"Can you tell me where he is?" → Soru işareti (çünkü "can you" soru)
''',
      examTip: '💡 YDS\'nin EN SEVDİĞİ konulardan biridir. Boşluktan sonra wh-word ve ardından "does/did" görürseniz YANLIŞ! Düz sıra olmalı.',
    ),

    // 3. IF/WHETHER CLAUSES
    GrammarSubtopic(
      id: 'if_whether_clauses',
      title: 'If / Whether Clauses',
      titleTr: 'Evet/Hayır Soruları (If / Whether)',
      explanation: '''
Evet/Hayır cevabı bekleyen sorular cümle içinde kullanılırken "if" veya "whether" ile bağlanır.

🎯 KULLANIM:
Direct: "Is she coming?" (Geliyor mu?)
Indirect: "I wonder IF/WHETHER she is coming." (Gelip gelmediğini merak ediyorum.)

🎯 IF vs WHETHER FARKİ:

WHETHER tercih edilir:
• "Or not" ifadesi varsa: "...whether or not..."
• Preposition'dan sonra: "about whether..."
• İnfinitive önünde: "...whether to go..."
• Daha resmi yazılarda

IF kullanılabilir:
• Günlük konuşmada
• "Or not" ayrı yazılırsa: "...if he comes or not"
• "Don't know if..." gibi yapılarda
''',
      formula: '''
Direct Yes/No Q: Auxiliary + Subject + Verb?
  "Is he coming?"

Indirect: Subject + Verb + if/whether + Subject + Verb
  "I wonder IF he is coming."
  "I don't know WHETHER she will accept."
''',
      examples: [
        GrammarExample(
          english: 'I don\'t know if she is married.',
          turkish: 'Evli olup olmadığını bilmiyorum.',
          note: 'if + düz cümle',
        ),
        GrammarExample(
          english: 'I wonder whether he will come or not.',
          turkish: 'Gelip gelmeyeceğini merak ediyorum.',
          note: 'whether... or not',
        ),
        GrammarExample(
          english: 'The question is whether we can afford it.',
          turkish: 'Soru, bunu karşılayıp karşılayamayacağımız.',
          note: 'Yüklem tamamlayıcısı',
        ),
        GrammarExample(
          english: 'I\'m thinking about whether to accept the offer.',
          turkish: 'Teklifi kabul edip etmemeyi düşünüyorum.',
          note: 'Preposition + whether + to V1',
        ),
        GrammarExample(
          english: 'I don\'t know if does he have a car.',
          turkish: 'Arabası var mı bilmiyorum.',
          isCorrect: false,
          note: '❌ YANLIŞ! Düz sıra olmalı',
        ),
      ],
      commonMistakes: [
        '❌ I wonder if IS he coming. → ✅ I wonder if he IS coming.',
        '❌ I don\'t know if or not he came. → ✅ I don\'t know WHETHER OR NOT he came.',
        '❌ I\'m thinking about if to go. → ✅ I\'m thinking about WHETHER to go.',
      ],
      keyPoints: [
        '🔑 "If/Whether" sonrası DÜZ CÜMLE gelir',
        '🔑 "Or not" için WHETHER tercih edilir ("whether or not" bitişik yazılabilir)',
        '🔑 Preposition + whether (if olmaz!)',
        '🔑 "Whether to V1" yapısı var, "if to V1" yok!',
      ],
      examTip: '💡 "About/of" gibi prepositionlardan sonra "if" değil "whether" gelir. Bu seçeneklerde if varsa eleyin.',
    ),

    // 4. SUBJUNCTIVE (THAT + SHOULD/V1)
    GrammarSubtopic(
      id: 'subjunctive_noun_clause',
      title: 'Subjunctive in Noun Clauses',
      titleTr: 'Dilek Kipi (Subjunctive)',
      explanation: '''
Bazı fiil ve sıfatlardan sonra gelen that-clause içinde "subjunctive" (dilek kipi) kullanılır. Bu yapıda fiil her zaman YALIN (V1) kalır veya "should + V1" kullanılır.

🎯 SUBJUNCTIVE GEREKTİREN FİİLLER:
• suggest, recommend, propose (önermek)
• demand, insist, request (talep etmek)
• require, order, command (emretmek)
• urge, advise (tavsiye etmek)

🎯 SUBJUNCTIVE GEREKTİREN SIFATLAR:
• It is essential/important/vital/necessary that...
• It is recommended/suggested that...
• It is crucial/imperative that...

⚠️ KRİTİK:
• "He goes" değil "He GO" (3. tekil şahıs -s almaz!)
• "She doesn't go" değil "She NOT GO"
• veya "She SHOULD GO"
''',
      formula: '''
Subject + Verb + that + Subject + (should) + V1

"I suggest that he GO." (Gitmesini öneriyorum.)
"It is essential that she BE here." (Burada olması şart.)
''',
      examples: [
        GrammarExample(
          english: 'The doctor recommended that she take a rest.',
          turkish: 'Doktor dinlenmesini tavsiye etti.',
          note: 'take (not takes!) - Subjunctive',
        ),
        GrammarExample(
          english: 'It is essential that everyone be on time.',
          turkish: 'Herkesin zamanında olması şart.',
          note: 'be (not is!) - Subjunctive',
        ),
        GrammarExample(
          english: 'I insist that he should apologize.',
          turkish: 'Özür dilemesinde ısrar ediyorum.',
          note: 'should + V1 alternatifi',
        ),
        GrammarExample(
          english: 'They demanded that the manager resign immediately.',
          turkish: 'Müdürün derhal istifa etmesini talep ettiler.',
          note: 'resign (not resigns!) - Subjunctive',
        ),
        GrammarExample(
          english: 'I suggest that he goes home.',
          turkish: 'Eve gitmesini öneriyorum.',
          isCorrect: false,
          note: '❌ Subjunctive\'de -s olmaz! "he GO"',
        ),
      ],
      commonMistakes: [
        '❌ I suggest that he GOES. → ✅ I suggest that he GO.',
        '❌ It is vital that she DOESN\'T leave. → ✅ It is vital that she NOT leave.',
        '❌ I recommend that he IS careful. → ✅ I recommend that he BE careful.',
      ],
      keyPoints: [
        '🔑 Subjunctive fiili her zaman YALIN (V1) kalır, şahıs eki almaz',
        '🔑 Olumsuzda "don\'t/doesn\'t" değil "NOT + V1" kullanılır',
        '🔑 "Be" fiili için "am/is/are" değil sadece "BE" kullanılır',
        '🔑 British English\'te "should + V1" daha yaygındır',
      ],
      examTip: '💡 YDS\'de "suggest, recommend, demand, insist" fiillerinden sonra gelen boşlukta şahıs ekli fiil (-s) şıkkını eleyin! Yalın fiil (V1) veya should + V1 doğrudur.',
    ),
  ],
);
