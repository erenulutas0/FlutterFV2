import 'package:flutter/material.dart';
import 'grammar_data.dart';

/// CONDITIONALS (Advanced Grammar)
const conditionalsTopic = GrammarTopic(
  id: 'conditionals',
  title: 'Conditionals',
  titleTr: 'Koşul Cümleleri (If)',
  level: 'advanced',
  icon: Icons.call_split, // Yolları ayıran bir ikon
  color: Color(0xFFf59e0b),
  subtopics: [
    // 1. ZERO CONDITIONAL
    GrammarSubtopic(
      id: 'zero_conditional',
      title: 'Zero Conditional',
      titleTr: 'Tip 0: Genel Doğrular',
      explanation: '''
Bilimsel gerçekler, genel doğrular ve her zaman olan sonuçlar için kullanılır. "Eğer A olursa, B olur."

🎯 Ne zaman kullanılır?
• Doğa kanunları (Su 100 derecede kaynar)
• Genel alışkanlıklar (Yorulursam uyurum)
• Talimatlar (Kırmızı ışık yanarsa dur)
''',
      formula: '''
If + Present Simple, Present Simple
''',
      examples: [
        GrammarExample(
          english: 'If you heat water to 100°C, it boils.',
          turkish: 'Suyu 100 dereceye ısıtırsan kaynar.',
          note: 'Bilimsel gerçek',
        ),
        GrammarExample(
          english: 'If I drink coffee at night, I can\'t sleep.',
          turkish: 'Gece kahve içersem uyuyamam.',
          note: 'Genel alışkanlık',
        ),
        GrammarExample(
          english: 'If the light turns red, stop.',
          turkish: 'Işık kırmızı yanarsa dur.',
          note: 'Talimat (Imperative)',
        ),
      ],
      keyPoints: [
        '🔑 Her iki tarafta da Present Simple kullanılır.',
        '🔑 "If" yerine "When" kullanılabilir, anlam değişmez. (When you heat water...)',
      ],
    ),

    // 2. FIRST CONDITIONAL
    GrammarSubtopic(
      id: 'first_conditional',
      title: 'First Conditional',
      titleTr: 'Tip 1: Gerçekleşmesi Muhtemel',
      explanation: '''
Gelecekte olması muhtemel olaylar için kullanılır.

🎯 Ne zaman kullanılır?
• Gelecek planları
• Uyarılar ve tehditler
• Vaatler
• Olasılıklar
''',
      formula: '''
If + Present Simple, Will + V1
(Can/May/Should/Imperative de gelebilir)
''',
      examples: [
        GrammarExample(
          english: 'If it rains tomorrow, we will stay at home.',
          turkish: 'Yarın yağmur yağarsa evde kalacağız.',
          note: 'Muhtemel gelecek durumu',
        ),
        GrammarExample(
          english: 'If you study hard, you can pass the exam.',
          turkish: 'Sıkı çalışırsan sınavı geçebilirsin.',
          note: 'Yetenek/Olasılık (can)',
        ),
        GrammarExample(
          english: 'If you see him, tell him to call me.',
          turkish: 'Onu görürsen beni aramasını söyle.',
          note: 'Emir cümlesi',
        ),
      ],
      commonMistakes: [
        '❌ If it will rain... → ✅ If it rains...',
        '❌ If you will go... → ✅ If you go... (If cümlesinde will olmaz!)',
      ],
      keyPoints: [
        '🔑 If kısmında asla "will" kullanılmaz! (Gelecek anlamı taşısa bile Present Simple kullanılır)',
        '🔑 Unless = If not (Yapmazsan... = Unless you do...)',
      ],
    ),

    // 3. SECOND CONDITIONAL
    GrammarSubtopic(
      id: 'second_conditional',
      title: 'Second Conditional',
      titleTr: 'Tip 2: Hayali Durumlar (Şu an)',
      explanation: '''
Şu an veya yakın gelecek için hayali, gerçekleşmesi zor veya imkansız durumları anlatır.

🎯 Ne zaman kullanılır?
• "Yerinde olsam..." (If I were you)
• Piyango çıksa... (İhtimal düşük)
• Hayaller ve varsayımlar
''',
      formula: '''
If + Past Simple, Would + V1
(Could/Might da gelebilir)
''',
      examples: [
        GrammarExample(
          english: 'If I had a million dollars, I would buy a house.',
          turkish: 'Bir milyon dolarım olsa (şu an yok), ev alırdım.',
          note: 'Hayali durum',
        ),
        GrammarExample(
          english: 'If I were you, I would accept the offer.',
          turkish: 'Senin yerinde olsam, teklifi kabul ederdim.',
          note: 'Tavsiye',
        ),
        GrammarExample(
          english: 'If she knew the answer, she would tell us.',
          turkish: 'Cevabı bilseydi (bilmiyor), bize söylerdi.',
          note: 'Gerçek dışı',
        ),
      ],
      commonMistakes: [
        '❌ If I was you... → ✅ If I were you... (Resmi/Gramatikal olarak were tercih edilir)',
        '❌ If I would go... → ✅ If I went... (If kısmında would olmaz!)',
      ],
      keyPoints: [
        '🔑 Past Simple kullanılır ama anlam GEÇMİŞ DEĞİL, ŞU ANDIR!',
        '🔑 "Be" fiili tüm şahıslar için "were" olur (I were, she were).',
        '🔑 If kısmında "would" kullanılmaz.',
      ],
    ),

    // 4. THIRD CONDITIONAL
    GrammarSubtopic(
      id: 'third_conditional',
      title: 'Third Conditional',
      titleTr: 'Tip 3: Geçmişteki Pişmanlıklar',
      explanation: '''
Geçmişte olmuş bitmiş olayları "keşke şöyle olsaydı" diye tersini hayal ederken kullanılır. Artık değiştirmek imkansızdır.

🎯 Ne zaman kullanılır?
• Pişmanlıklar (Keşke çalışsaydım)
• Eleştiriler (Daha dikkatli olmalıydın)
• Geçmişe dair varsayımlar
''',
      formula: '''
If + Past Perfect (had V3), Would have + V3
(Could have V3 / Might have V3)
''',
      examples: [
        GrammarExample(
          english: 'If I had studied harder, I would have passed the exam.',
          turkish: 'Daha sıkı çalışsaydım (çalışmadım), sınavı geçerdim (geçemedim).',
          note: 'Geçmiş pişmanlık',
        ),
        GrammarExample(
          english: 'If hadn\'t rained, we would have gone to the park.',
          turkish: 'Yağmur yağmasaydı, parka giderdik.',
          note: 'Geçmiş varsayım',
        ),
      ],
      commonMistakes: [
        '❌ If I would have studied... → ✅ If I had studied...',
        '❌ ...I would passed. → ✅ ...I would HAVE passed.',
      ],
      keyPoints: [
        '🔑 Tamamen geçmişi anlatır, geri dönüşü yoktur.',
        '🔑 If kısmında "Past Perfect", ana cümlede "Modal Perfect" kullanılır.',
      ],
      comparison: '''
🆚 2nd vs 3rd Conditional:
• Type 2 (Şu an): "If I had a car, I would drive." (Arabam yok, olsa sürerim - hayal)
• Type 3 (Geçmiş): "If I had had a car, I would have driven." (Arabam yoktu, olsa sürerdim - geçmiş)
''',
    ),

    // 5. MIXED CONDITIONALS
    GrammarSubtopic(
      id: 'mixed_conditional',
      title: 'Mixed Conditionals',
      titleTr: 'Karışık Koşullar',
      explanation: '''
Bazen koşul geçmişte, sonuç şu anda olabilir; veya koşul genel bir durum iken sonuç geçmişte kalmış olabilir.

🎯 En yaygın tip (Past Agent -> Present Result):
"Geçmişte şunu yapmasaydım (Type 3), şu an bu durumda olmazdım (Type 2)."
''',
      formula: '''
If + Past Perfect (Type 3), Would + V1 (Type 2)
''',
      examples: [
        GrammarExample(
          english: 'If I had eaten breakfast (past), I wouldn\'t be hungry now (present).',
          turkish: 'Kahvaltı yapsaydım (yapmadım), şu an aç olmazdım.',
          note: 'Geçmiş sebep, şimdiki sonuç',
        ),
        GrammarExample(
          english: 'If he were a better player (general), he would have scored yesterday (past).',
          turkish: 'Daha iyi bir oyuncu olsaydı (genel), dün golü atardı (geçmiş).',
          note: 'Genel özellik, geçmiş sonuç',
        ),
      ],
      keyPoints: [
        '🔑 Cümlenin hangi kısmının hangi zamana ait olduğunu anlamak için zaman zarflarına (now, yesterday) bakın.',
      ],
      examTip: '💡 YDS\'de "now, today" gibi ipuçları varsa Mixed Conditional düşünün.',
    ),
  ],
);
