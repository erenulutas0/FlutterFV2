import 'package:flutter/material.dart';
import 'grammar_data.dart';

/// PREPOSITIONS (Exam Grammar)
const prepositionsTopic = GrammarTopic(
  id: 'prepositions',
  title: 'Prepositions',
  titleTr: 'Edatlar',
  level: 'exam',
  icon: Icons.place,
  color: Color(0xFFef4444),
  subtopics: [
    // 1. PREPOSITIONS OF TIME
    GrammarSubtopic(
      id: 'prepositions_time',
      title: 'Prepositions of Time',
      titleTr: 'Zaman Edatları',
      explanation: '''
Zaman ifadelerinde kullanılan edatlardır. AT, ON, IN üçlüsü en önemlisidir.

🎯 AT (Dar - Nokta):
• Saatler: at 5 PM, at noon, at midnight
• Anlar: at the moment, at present
• Özel günler: at Christmas, at Easter
• İstisna: at night, at the weekend (British)

🎯 ON (Orta - Çizgi):
• Günler: on Monday, on Friday night
• Tarihler: on May 1st, on 25th December
• Özel günler: on my birthday, on New Year's Day
• Gün + Part: on Monday morning

🎯 IN (Geniş - Alan):
• Aylar: in July, in December
• Mevsimler: in summer, in winter
• Yıllar: in 2024, in 1990
• Yüzyıllar: in the 21st century
• Günün bölümleri: in the morning, in the afternoon

💡 HAFIZA İPUCU:
AT < ON < IN (Dar → Geniş)
Saat (nokta) < Gün (çizgi) < Ay/Yıl (alan)
''',
      formula: '''
AT + saat, an, gece
ON + gün, tarih
IN + ay, mevsim, yıl, yüzyıl, günün bölümü

⚠️ AT night (tek istisna!)
⚠️ ON Monday morning (gün + part)
''',
      examples: [
        GrammarExample(
          english: 'The meeting is at 3 PM.',
          turkish: 'Toplantı saat 3\'te.',
          note: 'at + saat',
        ),
        GrammarExample(
          english: 'I was born on July 15th.',
          turkish: '15 Temmuz\'da doğdum.',
          note: 'on + tarih',
        ),
        GrammarExample(
          english: 'It snows a lot in winter.',
          turkish: 'Kışın çok kar yağar.',
          note: 'in + mevsim',
        ),
        GrammarExample(
          english: 'I\'ll call you on Monday morning.',
          turkish: 'Pazartesi sabahı seni ararım.',
          note: 'on + gün + part',
        ),
        GrammarExample(
          english: 'I study in the night.',
          turkish: 'Gece çalışırım.',
          isCorrect: false,
          note: '❌ YANLIŞ! AT night',
        ),
      ],
      commonMistakes: [
        '❌ in Monday → ✅ ON Monday',
        '❌ at the morning → ✅ IN the morning',
        '❌ in 5 PM → ✅ AT 5 PM',
        '❌ on 2024 → ✅ IN 2024',
      ],
      keyPoints: [
        '🔑 AT night (istisna - in the night DEĞİL)',
        '🔑 ON Monday morning (gün + part birleşince ON)',
        '🔑 AT the weekend (British) / ON the weekend (American)',
        '🔑 IN time (zamanında) vs ON time (tam zamanında)',
      ],
      examTip: '💡 YDS\'de "in Monday" veya "at the summer" görürseniz YANLIŞ!',
    ),

    // 2. PREPOSITIONS OF PLACE
    GrammarSubtopic(
      id: 'prepositions_place',
      title: 'Prepositions of Place',
      titleTr: 'Yer Edatları',
      explanation: '''
Konum ve yer ifadelerinde kullanılan edatlardır.

🎯 AT (Nokta Konum):
• Belirli noktalar: at the door, at the bus stop
• Etkinlikler: at a party, at a concert
• Yerler (genel): at home, at work, at school

🎯 ON (Yüzey):
• Üzerinde: on the table, on the wall, on the floor
• Ulaşım (büyük): on the bus, on the plane, on the train
• Cadde: on Fifth Avenue

🎯 IN (İçinde):
• Kapalı alan: in the box, in the room, in the car
• Şehir/Ülke: in Tokyo, in Turkey
• Bölge: in Asia, in the Middle East

💡 TAŞITLAR İÇİN:
• ON: Ayakta durabilenlere → on the bus, on the train, on the plane
• IN: Bükülüp girilen → in the car, in a taxi
''',
      formula: '''
AT + nokta, adres numarası, etkinlik
ON + yüzey, büyük taşıt, cadde ismi
IN + kapalı alan, şehir, ülke, küçük taşıt
''',
      examples: [
        GrammarExample(
          english: 'She is waiting at the bus stop.',
          turkish: 'Otobüs durağında bekliyor.',
          note: 'at + nokta konum',
        ),
        GrammarExample(
          english: 'The book is on the table.',
          turkish: 'Kitap masanın üzerinde.',
          note: 'on + yüzey',
        ),
        GrammarExample(
          english: 'I left my phone in the car.',
          turkish: 'Telefonumu arabada unuttum.',
          note: 'in + kapalı alan (araba)',
        ),
        GrammarExample(
          english: 'We traveled on the train.',
          turkish: 'Trenle seyahat ettik.',
          note: 'on + büyük taşıt',
        ),
        GrammarExample(
          english: 'He is on the car.',
          turkish: 'Arabada.',
          isCorrect: false,
          note: '❌ YANLIŞ! IN the car (araba küçük)',
        ),
      ],
      commonMistakes: [
        '❌ on the car → ✅ IN the car',
        '❌ in the bus → ✅ ON the bus',
        '❌ at Tokyo → ✅ IN Tokyo (şehir)',
        '❌ in the door → ✅ AT the door',
      ],
      keyPoints: [
        '🔑 Büyük taşıtlar (ayakta durabilir) → ON',
        '🔑 Küçük taşıtlar (bükülüp girilir) → IN',
        '🔑 Şehir, ülke → IN',
        '🔑 Adres numarası → AT (at 25 Oxford Street)',
      ],
      examTip: '💡 YDS\'de "in the plane" veya "on the car" görürseniz dikkat edin!',
    ),

    // 3. VERB + PREPOSITION
    GrammarSubtopic(
      id: 'verb_prepositions',
      title: 'Verb + Preposition',
      titleTr: 'Fiil + Edat',
      explanation: '''
Bazı fiiller belirli edatlarla birlikte kullanılır. Bu kalıplar ezber gerektirir.

🎯 YAYGIIN FİİL + EDAT KALIPLARI:

• AGREE with (someone): ile aynı fikirde olmak
• AGREE on/about (something): konusunda anlaşmak
• APOLOGIZE for: için özür dilemek
• APPLY for: için başvurmak
• ARRIVE at (place): bir yere varmak
• ARRIVE in (city/country): şehre/ülkeye varmak
• BELIEVE in: inanmak
• BELONG to: ait olmak
• CONSIST of: oluşmak
• DEPEND on: bağlı olmak
• INSIST on: ısrar etmek
• LISTEN to: dinlemek
• LOOK at: bakmak
• LOOK for: aramak
• LOOK after: bakmak (ilgilenmek)
• RELY on: güvenmek
• SUFFER from: çekmek (acı, hastalık)
• WAIT for: beklemek
• WORRY about: endişelenmek
''',
      formula: '''
Verb + Preposition + Object

"I agree WITH you."
"She apologized FOR being late."
"They arrived AT the airport."
''',
      examples: [
        GrammarExample(
          english: 'I completely agree with you.',
          turkish: 'Seninle tamamen aynı fikirdeyim.',
          note: 'agree with + person',
        ),
        GrammarExample(
          english: 'She apologized for her mistake.',
          turkish: 'Hatası için özür diledi.',
          note: 'apologize for + noun/V-ing',
        ),
        GrammarExample(
          english: 'We arrived in Paris at 8 PM.',
          turkish: 'Paris\'e akşam 8\'de vardık.',
          note: 'arrive in + city',
        ),
        GrammarExample(
          english: 'I\'m looking for my keys.',
          turkish: 'Anahtarlarımı arıyorum.',
          note: 'look for = aramak',
        ),
        GrammarExample(
          english: 'I agree to you.',
          turkish: 'Seninle aynı fikirdeyim.',
          isCorrect: false,
          note: '❌ YANLIŞ! Agree WITH you',
        ),
      ],
      commonMistakes: [
        '❌ agree to you → ✅ agree WITH you',
        '❌ listen him → ✅ listen TO him',
        '❌ wait you → ✅ wait FOR you',
        '❌ arrived to Paris → ✅ arrived IN Paris',
      ],
      keyPoints: [
        '🔑 ARRIVE in (city/country), AT (place)',
        '🔑 LISTEN TO, LOOK AT, WAIT FOR → edat atılmaz!',
        '🔑 AGREE with (person), AGREE on (topic)',
        '🔑 Türkçe\'de edat gerektirmeyen fiiller İngilizce\'de gerektirebilir',
      ],
      examTip: '💡 "Listen him" veya "wait you" her zaman YANLIŞTIR. Edatı unutmayın!',
    ),

    // 4. ADJECTIVE + PREPOSITION
    GrammarSubtopic(
      id: 'adjective_prepositions',
      title: 'Adjective + Preposition',
      titleTr: 'Sıfat + Edat',
      explanation: '''
Bazı sıfatlar belirli edatlarla birlikte kullanılır.

🎯 YAYIN SIFAT + EDAT KALIPLARI:

• AFRAID of: korkmak
• ANGRY with (person): kızgın olmak
• ANGRY about (thing): kızgın olmak
• AWARE of: farkında olmak
• BAD at: kötü olmak
• CAPABLE of: muktedir olmak
• DIFFERENT from: farklı olmak
• DISAPPOINTED with/in: hayal kırıklığına uğramak
• EXCITED about: heyecanlı olmak
• FAMOUS for: meşhur olmak
• FOND of: düşkün olmak
• GOOD at: iyi olmak
• INTERESTED in: ilgili olmak
• JEALOUS of: kıskanmak
• KEEN on: düşkün olmak
• MARRIED to: evli olmak
• PROUD of: gurur duymak
• RESPONSIBLE for: sorumlu olmak
• SATISFIED with: memnun olmak
• SIMILAR to: benzer olmak
• SORRY for/about: üzgün olmak
• TIRED of: bıkmak
''',
      formula: '''
Be + Adjective + Preposition + Object

"I am afraid OF spiders."
"She is good AT math."
"He is interested IN art."
''',
      examples: [
        GrammarExample(
          english: 'She is very good at languages.',
          turkish: 'Dillerde çok iyidir.',
          note: 'good at',
        ),
        GrammarExample(
          english: 'I\'m not interested in politics.',
          turkish: 'Politikayla ilgili değilim.',
          note: 'interested in',
        ),
        GrammarExample(
          english: 'He is married to a famous actress.',
          turkish: 'Meşhur bir aktris ile evli.',
          note: 'married to (with değil!)',
        ),
        GrammarExample(
          english: 'We are proud of your achievements.',
          turkish: 'Başarılarınla gurur duyuyoruz.',
          note: 'proud of',
        ),
        GrammarExample(
          english: 'She is married with a doctor.',
          turkish: 'Bir doktorla evli.',
          isCorrect: false,
          note: '❌ YANLIŞ! Married TO',
        ),
      ],
      commonMistakes: [
        '❌ married with → ✅ married TO',
        '❌ interested at → ✅ interested IN',
        '❌ good in sports → ✅ good AT sports',
        '❌ afraid from → ✅ afraid OF',
      ],
      keyPoints: [
        '🔑 MARRIED TO (with değil!)',
        '🔑 GOOD/BAD AT',
        '🔑 INTERESTED IN',
        '🔑 AFRAID/PROUD/FOND OF',
      ],
      comparison: '''
🆚 Sık karıştırılan edatlar:
• ANGRY with (person) / about (thing)
• SORRY for (person) / about (thing)
• WORRY about ≠ be worried about

🆚 Made:
• Made OF (malzeme belli): "Made of wood"
• Made FROM (malzeme değişmiş): "Made from grapes"
''',
      examTip: '💡 YDS\'de "married WITH" en sık çıkan hatadır! Doğrusu "married TO".',
    ),
  ],
);
