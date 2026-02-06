import 'package:flutter/material.dart';
import 'grammar_data.dart';

/// ADVANCED GRAMMAR - CLAUSES
const advancedClausesTopic = GrammarTopic(
  id: 'clauses',
  title: 'Clauses (Relative/Noun)',
  titleTr: 'Cümlecikler',
  level: 'advanced',
  icon: Icons.link,
  color: Color(0xFFf59e0b),
  subtopics: [
    // 1. RELATIVE CLAUSES
    GrammarSubtopic(
      id: 'relative_clauses',
      title: 'Relative Clauses',
      titleTr: 'Sıfat Cümlecikleri',
      explanation: '''
Bir ismi niteleyen, hakkında ekstra bilgi veren cümleciklerdir. Türkçedeki "-an/-en, -dığı/-diği" eklerine karşılık gelir.

🎯 Temel Zamirler (Relative Pronouns):
• Who: İnsanlar için
• Which: Hayvan ve nesneler için
• That: Her ikisi için (sadece Defining Clause'da)
• Whose: Sahiplik (onun, bunun)
• Where: Yer (orada)
• When: Zaman (o zaman)
''',
      formula: '''
Person + who/that + Verb
Thing + which/that + Verb
Person/Thing + whose + Noun
Place + where + Subject + Verb
''',
      examples: [
        GrammarExample(
          english: 'The man who lives next door is a doctor.',
          turkish: 'Yan tarafta yaşayan adam doktordur.',
          note: 'Adamı niteliyor',
        ),
        GrammarExample(
          english: 'I lost the book which/that I bought yesterday.',
          turkish: 'Dün satın aldığım kitabı kaybettim.',
          note: 'Kitabı niteliyor',
        ),
        GrammarExample(
          english: 'She is the woman whose car was stolen.',
          turkish: 'O, arabası çalınan kadındır.',
          note: 'Sahiplik (whose car)',
        ),
      ],
      keyPoints: [
        '🔑 "Commalı" (Non-defining) cümlelerde ASLA "that" kullanılmaz!',
        '🔑 Eğer relative pronoun (who/which/that) nesne durumundaysa (arkasından özne geliyorsa) atılabilir. "The book (which) I read."',
      ],
      comparison: '''
🆚 Defining vs Non-defining:
• Defining (Virgülsüz): "The students who studied passed." (Sadece çalışanlar geçti - diğerleri kaldı)
• Non-defining (Virgüllü): "My father, who is 60, retired." (Babam emekli oldu - ek bilgi: yaşı 60. Birden fazla babam yok!)
''',
      examTip: '💡 Boşluktan önce virgül varsa, şıklarda "that"i hemen eleyin. Virgül varsa "which" veya "who" gelir.',
    ),

    // 2. NOUN CLAUSES
    GrammarSubtopic(
      id: 'noun_clauses',
      title: 'Noun Clauses',
      titleTr: 'İsim Cümlecikleri',
      explanation: '''
Bir cümlenin öznesi veya nesnesi konumunda olan cümleciklerdir. "Cümle içinde cümle" gibidir.

🎯 Türleri:
• That clauses: Düz cümleleri bağlar (He is rich -> I know THAT he is rich)
• Wh- clauses: Soruları bağlar (Where does he live? -> I know WHERE he lives)
• If/Whether clauses: Evet/Hayır sorularını bağlar (Is he rich? -> I don't know IF he is rich)
''',
      formula: '''
I know + that + Subject + Verb
I wonder + wh-word + Subject + Verb
I ask + if/whether + Subject + Verb
''',
      examples: [
        GrammarExample(
          english: 'I know (that) she is lying.',
          turkish: 'Yalan söylediğini biliyorum.',
          note: ' Nesne görevinde',
        ),
        GrammarExample(
          english: 'What you said is important.',
          turkish: 'Söylediğin şey önemli.',
          note: 'Özne görevinde (What you said)',
        ),
        GrammarExample(
          english: 'I wonder where he lives.',
          turkish: 'Nerede yaşadığını merak ediyorum.',
          note: 'Soru cümlesi (Düz sıraya döner!)',
        ),
      ],
      commonMistakes: [
        '❌ I wonder where does he live. → ✅ I wonder where he lives. (Soru formatı olmaz)',
        '❌ I don\'t know if will he come. → ✅ I don\'t know if he will come.',
      ],
      keyPoints: [
        '🔑 Noun Clause soruları her zaman "DÜZ CÜMLE" (Subject + Verb) sırasındadır. Yardımcı fiil başa gelmez.',
        '🔑 "The fact that" kalıbı, prepositionlardan sonra cümle getirmek için kullanılır.',
      ],
      comparison: '''
🆚 Noun Clause vs Relative Clause:
• "I know the man WHO lives here." (Adamı tanıyorum - Sıfat Cümlesi, "man"i niteliyor)
• "I know WHO lives here." (Kim yaşadığını biliyorum - İsim Cümlesi, "know"un nesnesi)

💡 İpucu: Boşluktan önce FİİL varsa genelde Noun Clause, İSİM varsa Relative Clause'dur.
''',
      examTip: '💡 Preposition (in, on, at, of) arkasından asla "that" gelmez. Ancak "in that" (bakımından) hariç!',
    ),

    // 3. CONJUNCTIONS (Bağlaçlar)
    GrammarSubtopic(
      id: 'conjunctions',
      title: 'Conjunctions',
      titleTr: 'Bağlaçlar',
      explanation: '''
Cümleleri birbirine bağlayan, anlam ilişkisi kuran kelimelerdir.

🎯 Kategoriler:
• Sebep (Reason): Because, As, Since, Due to
• Sonuç (Result): Therefore, So, As a result
• Zıtlık (Contrast): Although, However, But, Despite
• Amaç (Purpose): So that, In order to
• Zaman (Time): When, While, After, Before
''',
      formula: '''
Cümle + Cümle (Because, Although)
Noun Phrase (Due to, Despite)
''',
      examples: [
        GrammarExample(
          english: 'Although it rained, we went out.',
          turkish: 'Yağmur yağmasına rağmen dışarı çıktık.',
          note: 'Zıtlık (Cümle alır)',
        ),
        GrammarExample(
          english: 'Despite the rain, we went out.',
          turkish: 'Yağmura rağmen dışarı çıktık.',
          note: 'Zıtlık (İsim alır)',
        ),
        GrammarExample(
          english: 'He studied hard; therefore, he passed.',
          turkish: 'Sıkı çalıştı; bu yüzden geçti.',
          note: 'Sonuç',
        ),
      ],
      keyPoints: [
        '🔑 Despite / In spite of + NOUN (veya V-ing)',
        '🔑 Although / Even though + CÜMLE (Subject+Verb)',
        '🔑 Due to / Because of + NOUN',
        '🔑 Because / Since / As + CÜMLE',
      ],
      comparison: '''
🆚 However vs Although:
• "Although he is rich, he is sad." (Tek cümle içinde bağlar)
• "He is rich. However, he is sad." (İki ayrı cümleyi bağlar, genellikle noktalama işaretleriyle ayrılır)
''',
      examTip: '💡 YDS\'de boşluktan sonrasına bakın: Tam cümle mi var, isim grubu mu? Cümle ise Although/Because, isim ise Despite/Due to seçin.',
    ),
  ],
);
