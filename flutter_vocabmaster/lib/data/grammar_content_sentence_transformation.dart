import 'package:flutter/material.dart';
import 'grammar_data.dart';

/// SENTENCE TRANSFORMATION (Exam Grammar)
const sentenceTransformationTopic = GrammarTopic(
  id: 'sentence_transformation',
  title: 'Sentence Transformation',
  titleTr: 'Cümle Dönüştürme',
  level: 'exam',
  icon: Icons.transform,
  color: Color(0xFFef4444),
  subtopics: [
    // 1. ACTIVE ↔ PASSIVE
    GrammarSubtopic(
      id: 'active_passive_transform',
      title: 'Active ↔ Passive',
      titleTr: 'Etken ↔ Edilgen Dönüşümü',
      explanation: '''
Cümlenin özne ve nesne odağını değiştirmek için yapılır.

🎯 AKTİF → PASİF DÖNÜŞÜMÜ:

1. Aktif cümlenin NESNESİ → Pasif cümlenin ÖZNESİ olur
2. "Be" fiili eklenir (zamana göre çekimlenir)
3. Ana fiil V3 (past participle) yapılır
4. Aktif özne "by..." ile eklenebilir (genellikle atılır)

ACTIVE: "The cat ate the mouse."
PASSIVE: "The mouse was eaten (by the cat)."

🎯 MODAL İLE DÖNÜŞÜM:
ACTIVE: "Someone must clean the room."
PASSIVE: "The room must be cleaned."

🎯 PERFECT İLE DÖNÜŞÜM:
ACTIVE: "They have finished the project."
PASSIVE: "The project has been finished."

🎯 CONTINUOUS İLE DÖNÜŞÜM:
ACTIVE: "They are building a bridge."
PASSIVE: "A bridge is being built."
''',
      formula: '''
Active: Subject + Verb + Object
Passive: Object → Subject + BE + V3 + (by Subject)

"Tom wrote the book." → "The book was written by Tom."
''',
      examples: [
        GrammarExample(
          english: 'Active: Shakespeare wrote Hamlet.\nPassive: Hamlet was written by Shakespeare.',
          turkish: 'Shakespeare Hamlet\'i yazdı.\nHamlet Shakespeare tarafından yazıldı.',
          note: 'Past Simple dönüşümü',
        ),
        GrammarExample(
          english: 'Active: They are renovating the hotel.\nPassive: The hotel is being renovated.',
          turkish: 'Oteli yeniliyorlar.\nOtel yenileniyor.',
          note: 'Present Continuous dönüşümü',
        ),
        GrammarExample(
          english: 'Active: You must complete the form.\nPassive: The form must be completed.',
          turkish: 'Formu doldurmalısınız.\nForm doldurulmalıdır.',
          note: 'Modal dönüşümü',
        ),
        GrammarExample(
          english: 'Active: Someone has stolen my bike.\nPassive: My bike has been stolen.',
          turkish: 'Biri bisikletimi çaldı.\nBisikletim çalındı.',
          note: 'Present Perfect dönüşümü',
        ),
      ],
      keyPoints: [
        '🔑 Nesne (Object) → yeni Özne (Subject) olur',
        '🔑 BE fiili zamana göre çekimlenir',
        '🔑 Ana fiil her zaman V3 olur',
        '🔑 "By + agent" genellikle belirsizse atılır',
      ],
      examTip: '💡 YDS\'de "The house built by..." YANLIŞ! "The house WAS built by..." olmalı.',
    ),

    // 2. DIRECT ↔ REPORTED SPEECH
    GrammarSubtopic(
      id: 'direct_reported_transform',
      title: 'Direct ↔ Reported Speech',
      titleTr: 'Doğrudan ↔ Dolaylı Anlatım',
      explanation: '''
Birinin sözlerini olduğu gibi vermek (direct) veya aktarmak (reported) arasındaki dönüşüm.

🎯 DOĞRUDAN → DOLAYLI:

1. Tırnak işaretleri kaldırılır
2. "That" eklenir (opsiyonel)
3. Zamanlar bir derece geriye kayar (backshift)
4. Zamirler değişir (I → he/she)
5. Zaman/yer ifadeleri değişir

DIRECT: He said, "I am tired."
REPORTED: He said (that) he was tired.

🎯 SORU DÖNÜŞÜMÜ:
DIRECT: "Where do you live?" she asked.
REPORTED: She asked where I lived. (Devriklik kalkar!)

🎯 EMİR/RİCA DÖNÜŞÜMÜ:
DIRECT: "Open the door!" he said.
REPORTED: He told me to open the door.
''',
      formula: '''
Direct: Subject + said, "..."
Reported: Subject + said (that) + [backshifted]

"I am happy" → he was happy
"I will come" → he would come
"I have done" → he had done
''',
      examples: [
        GrammarExample(
          english: 'Direct: "I love this city," she said.\nReported: She said (that) she loved that city.',
          turkish: '"Bu şehri seviyorum" dedi.\nO şehri sevdiğini söyledi.',
          note: 'this → that, love → loved',
        ),
        GrammarExample(
          english: 'Direct: "What time is it?" he asked.\nReported: He asked what time it was.',
          turkish: '"Saat kaç?" diye sordu.\nSaatin kaç olduğunu sordu.',
          note: 'Devriklik kalktı',
        ),
        GrammarExample(
          english: 'Direct: "Don\'t be late!" she warned.\nReported: She warned me not to be late.',
          turkish: '"Geç kalma!" diye uyardı.\nGeç kalmamamı söyledi.',
          note: 'Emir → to V1',
        ),
      ],
      keyPoints: [
        '🔑 Zamanlar bir derece geriye kayar',
        '🔑 Dolaylı soru → düz cümle sırası',
        '🔑 Emirler → told/asked + to V1',
        '🔑 "This → that, here → there, now → then" değişimleri',
      ],
      examTip: '💡 Dolaylı soruda "asked where DID he" YANLIŞ! Devriklik kalkar.',
    ),

    // 3. CONDITIONAL TRANSFORMATIONS
    GrammarSubtopic(
      id: 'conditional_transform',
      title: 'Conditional Transformations',
      titleTr: 'Koşul Cümlesi Dönüşümleri',
      explanation: '''
Koşul cümlelerini farklı yapılarla ifade etme.

🎯 IF → UNLESS DÖNÜŞÜMÜ:
• Unless = If + not
"If you don't study, you will fail."
→ "Unless you study, you will fail."

🎯 IF → PROVIDED THAT / AS LONG AS:
"If you help me, I will finish."
→ "Provided (that) you help me, I will finish."
→ "As long as you help me, I will finish."

🎯 IF → BUT FOR / WITHOUT:
"If it hadn't been for your help, I would have failed."
→ "But for your help, I would have failed."
→ "Without your help, I would have failed."

🎯 IF → OTHERWISE / OR ELSE:
"If you don't hurry, you will be late."
→ "Hurry up, otherwise you will be late."
→ "Hurry up, or else you will be late."

🎯 IF ATI → DEVRIK YAPI:
"If I had known..." → "Had I known..."
"If I were you..." → "Were I you..."
"If you should need..." → "Should you need..."
''',
      formula: '''
If + not → Unless
If + condition → Provided that / As long as
If it hadn't been for → But for / Without
If clause → Devrik yapı (Had I, Were I, Should you)
''',
      examples: [
        GrammarExample(
          english: 'If you don\'t call, I won\'t come.\n= Unless you call, I won\'t come.',
          turkish: 'Aramazsan gelmeyeceğim.',
          note: 'If not → Unless',
        ),
        GrammarExample(
          english: 'If it hadn\'t been for his help, we would have lost.\n= But for his help, we would have lost.',
          turkish: 'Onun yardımı olmasaydı kaybederdik.',
          note: 'If it hadn\'t been for → But for',
        ),
        GrammarExample(
          english: 'If I had known, I would have told you.\n= Had I known, I would have told you.',
          turkish: 'Bilseydim sana söylerdim.',
          note: 'If → Devrik (Had I)',
        ),
        GrammarExample(
          english: 'Study hard, otherwise you will fail.\n= If you don\'t study hard, you will fail.',
          turkish: 'Çok çalış, yoksa başarısız olursun.',
          note: 'Otherwise = If not',
        ),
      ],
      keyPoints: [
        '🔑 UNLESS = IF NOT (olumsuz zaten yok!)',
        '🔑 BUT FOR / WITHOUT = If it weren\'t for / If it hadn\'t been for',
        '🔑 OTHERWISE = If not (iki cümle arasında)',
        '🔑 Devrik yapıda IF atılır, yardımcı fiil başa gelir',
      ],
      examTip: '💡 "Unless you don\'t study" YANLIŞ! Unless zaten olumsuzu içerir.',
    ),

    // 4. MEANING-PRESERVING REWRITES
    GrammarSubtopic(
      id: 'meaning_preserving',
      title: 'Meaning-Preserving Rewrites',
      titleTr: 'Anlam Koruyan Dönüşümler',
      explanation: '''
Aynı anlamı farklı yapılarla ifade etme. YDS/YÖKDİL\'de çok sık çıkar.

🎯 TOO...TO / SO...THAT / ENOUGH:
"He is too young to drive."
= "He is so young that he cannot drive."
= "He is not old enough to drive."

🎯 SO...THAT / SUCH...THAT:
"It was so cold that we stayed inside."
= "It was such cold weather that we stayed inside."

🎯 ALTHOUGH / DESPITE / IN SPITE OF:
"Although he is rich, he is unhappy."
= "Despite being rich, he is unhappy."
= "In spite of his wealth, he is unhappy."

🎯 BECAUSE / BECAUSE OF / DUE TO:
"I stayed home because I was sick."
= "I stayed home because of my illness."
= "I stayed home due to being sick."

🎯 PREFER / WOULD RATHER:
"I prefer tea to coffee."
= "I would rather have tea than coffee."

🎯 IT'S TIME / HAD BETTER:
"It's time you went home."
= "You had better go home."
''',
      formula: '''
too + adj + to V = so + adj + that... can't
not + adj + enough to V = too + opposite adj + to V

Although + clause = Despite + noun/V-ing
Because + clause = Because of + noun
''',
      examples: [
        GrammarExample(
          english: 'He is too short to reach the shelf.\n= He is so short that he cannot reach the shelf.\n= He is not tall enough to reach the shelf.',
          turkish: 'Rafa ulaşamayacak kadar kısa.',
          note: 'too / so...that / enough',
        ),
        GrammarExample(
          english: 'Although she studied hard, she failed.\n= Despite studying hard, she failed.\n= In spite of her hard work, she failed.',
          turkish: 'Çok çalışmasına rağmen başarısız oldu.',
          note: 'Although / Despite',
        ),
        GrammarExample(
          english: 'He didn\'t go out because it was raining.\n= He didn\'t go out because of the rain.\n= He didn\'t go out due to the rain.',
          turkish: 'Yağmur yağdığı için dışarı çıkmadı.',
          note: 'Because / Because of',
        ),
        GrammarExample(
          english: 'It\'s time we left.\n= We had better leave.\n= We should leave now.',
          turkish: 'Gitmemizin zamanı geldi.',
          note: 'It\'s time / had better',
        ),
      ],
      keyPoints: [
        '🔑 TOO...TO (çok...ki yapamaz) = SO...THAT...CAN\'T',
        '🔑 Although + CÜMLE = Despite + İSİM/V-ing',
        '🔑 Because + CÜMLE = Because of + İSİM',
        '🔑 It\'s time + Past = Had better + V1',
      ],
      examTip: '💡 YDS\'de cümle tamamlama ve anlam bütünlüğü sorularında bu dönüşümler çok önemlidir!',
    ),
  ],
);
