import 'package:flutter/material.dart';
import 'grammar_data.dart';

/// COMPARISON (Exam Grammar)
const comparisonTopic = GrammarTopic(
  id: 'comparison',
  title: 'Comparison Structures',
  titleTr: 'Karşılaştırma',
  level: 'exam',
  icon: Icons.compare_arrows,
  color: Color(0xFFef4444),
  subtopics: [
    // 1. COMPARATIVES & SUPERLATIVES
    GrammarSubtopic(
      id: 'comparatives_superlatives',
      title: 'Comparatives & Superlatives',
      titleTr: 'Üstünlük ve En Üstünlük',
      explanation: '''
Sıfat ve zarfları karşılaştırmak için kullanılan yapılardır.

🎯 COMPARATIVE (Üstünlük Derecesi):
İki şeyi karşılaştırır. "-er" veya "more" kullanılır.

Kısa sıfatlar (1 hece): + er
• tall → taller, big → bigger, nice → nicer

Uzun sıfatlar (2+ hece): more + adj
• beautiful → more beautiful
• expensive → more expensive

🎯 SUPERLATIVE (En Üstünlük Derecesi):
Bir grupta en üstün olanı belirtir. "the + -est" veya "the most" kullanılır.

Kısa sıfatlar: the + adj + est
• tall → the tallest, big → the biggest

Uzun sıfatlar: the most + adj
• the most beautiful, the most expensive

🎯 DÜZENSİZ SIFATLAR:
• good → better → best
• bad → worse → worst
• far → farther/further → farthest/furthest
• little → less → least
• much/many → more → most
''',
      formula: '''
Comparative: adj + er + than / more + adj + than
Superlative: the + adj + est / the most + adj

"She is taller than me."
"He is the most intelligent student."
''',
      examples: [
        GrammarExample(
          english: 'This book is more interesting than that one.',
          turkish: 'Bu kitap ondan daha ilginç.',
          note: 'more + adj + than',
        ),
        GrammarExample(
          english: 'Mount Everest is the highest mountain in the world.',
          turkish: 'Everest dünyanın en yüksek dağıdır.',
          note: 'the + adj + est',
        ),
        GrammarExample(
          english: 'She sings better than anyone else.',
          turkish: 'Herkesten daha iyi şarkı söyler.',
          note: 'Düzensiz: good → better',
        ),
        GrammarExample(
          english: 'This is the best movie I have ever seen.',
          turkish: 'Bu gördüğüm en iyi film.',
          note: 'Düzensiz: good → best',
        ),
        GrammarExample(
          english: 'She is more taller than him.',
          turkish: 'Ondan daha uzun.',
          isCorrect: false,
          note: '❌ YANLIŞ! more + taller olmaz!',
        ),
      ],
      commonMistakes: [
        '❌ more taller → ✅ taller',
        '❌ most biggest → ✅ biggest',
        '❌ gooder → ✅ better',
        '❌ the more intelligent → ✅ the MOST intelligent (superlative)',
      ],
      keyPoints: [
        '🔑 -er/-est ile more/most birlikte KULLANILMAZ',
        '🔑 2 heceli sıfatlardan bazıları (-y, -er, -le, -ow ile bitenler) -er/-est alır: happy → happier',
        '🔑 Superlative\'de "the" unutulmamalı',
        '🔑 "Than" comparative için, "of/in" superlative için',
      ],
      examTip: '💡 YDS\'de "more taller" veya "most best" görürseniz YANLIŞ!',
    ),

    // 2. AS...AS STRUCTURES
    GrammarSubtopic(
      id: 'as_as_structures',
      title: 'As...As Structures',
      titleTr: 'Eşitlik Yapıları',
      explanation: '''
İki şeyin eşit olduğunu veya olmadığını karşılaştırmak için kullanılır.

🎯 EŞİTLİK (Olumlu):
as + adj/adv + as
"She is as tall as her brother."

🎯 EŞİTSİZLİK (Olumsuz):
not as + adj/adv + as
not so + adj/adv + as
"She is not as tall as her brother."

🎯 YARILANMA YAPILARI:
• twice as ... as: iki kat
• three times as ... as: üç kat
• half as ... as: yarısı kadar

🎯 "AS...AS" KALIPLARI:
• as soon as possible (ASAP): mümkün olduğunca çabuk
• as far as I know: bildiğim kadarıyla
• as long as: ...dığı sürece
• as well as: ...in yanı sıra
''',
      formula: '''
Olumlu: as + adj + as
Olumsuz: not as/so + adj + as

"He is as smart as his sister."
"He is not as smart as his sister."
"This is twice as expensive as that."
''',
      examples: [
        GrammarExample(
          english: 'This test is not as difficult as the last one.',
          turkish: 'Bu test sonuncusu kadar zor değil.',
          note: 'not as...as (eşit değil)',
        ),
        GrammarExample(
          english: 'Please come as soon as possible.',
          turkish: 'Lütfen mümkün olduğunca çabuk gel.',
          note: 'as...as possible',
        ),
        GrammarExample(
          english: 'This book is twice as expensive as that one.',
          turkish: 'Bu kitap ondan iki kat pahalı.',
          note: 'twice as...as',
        ),
        GrammarExample(
          english: 'As far as I know, he is still working there.',
          turkish: 'Bildiğim kadarıyla hâlâ orada çalışıyor.',
          note: 'as far as I know',
        ),
        GrammarExample(
          english: 'He is not as taller as me.',
          turkish: 'Benim kadar uzun değil.',
          isCorrect: false,
          note: '❌ YANLIŞ! as + adj (yalın) + as',
        ),
      ],
      commonMistakes: [
        '❌ as taller as → ✅ as tall as (yalın sıfat)',
        '❌ as more expensive as → ✅ as expensive as',
        '❌ two times as big as → ✅ twice as big as',
      ],
      keyPoints: [
        '🔑 "As...as" arasına yalın sıfat gelir (comparative değil!)',
        '🔑 Olumsuzda "so" kullanılabilir: "not so tall as"',
        '🔑 "Twice" = two times, "three times" = üç kat',
        '🔑 "As well as" = and, in addition to',
      ],
      examTip: '💡 YDS\'de "as taller as" veya "as more expensive as" görürseniz YANLIŞ! Yalın sıfat gelir.',
    ),

    // 3. THE MORE...THE MORE
    GrammarSubtopic(
      id: 'double_comparative',
      title: 'The More...The More',
      titleTr: 'Ne Kadar...O Kadar',
      explanation: '''
İki şeyin paralel olarak arttığını veya azaldığını gösterir.

🎯 TEMEL YAPI:
The + comparative..., the + comparative...
"The more you study, the more you learn."
(Ne kadar çok çalışırsan, o kadar çok öğrenirsin.)

🎯 VARYASYONLAR:
• The more...the less: Ne kadar çok...o kadar az
• The sooner...the better: Ne kadar erken...o kadar iyi
• The less...the less: Ne kadar az...o kadar az

🎯 KISA FORMU:
"The more, the better." (Ne kadar çok, o kadar iyi.)
"The sooner, the better." (Ne kadar erken, o kadar iyi.)

💡 NOT:
• İlk "the" koşulu, ikinci "the" sonucu gösterir
• Kısa sıfatlarda -er, uzunlarda more kullanılır
''',
      formula: '''
The + comparative + S + V, the + comparative + S + V

"The harder you work, the more successful you will be."
"The older he gets, the wiser he becomes."
''',
      examples: [
        GrammarExample(
          english: 'The more you practice, the better you get.',
          turkish: 'Ne kadar çok pratik yaparsan, o kadar iyi olursun.',
          note: 'more...better',
        ),
        GrammarExample(
          english: 'The sooner you start, the earlier you will finish.',
          turkish: 'Ne kadar erken başlarsan, o kadar erken bitirirsin.',
          note: 'sooner...earlier',
        ),
        GrammarExample(
          english: 'The less you eat, the more weight you will lose.',
          turkish: 'Ne kadar az yersen, o kadar çok kilo verirsin.',
          note: 'less...more',
        ),
        GrammarExample(
          english: 'The richer he becomes, the meaner he gets.',
          turkish: 'Ne kadar zengin olursa, o kadar cimri oluyor.',
          note: 'richer...meaner',
        ),
        GrammarExample(
          english: 'More you study, more you learn.',
          turkish: 'Ne kadar çok çalışırsan, o kadar çok öğrenirsin.',
          isCorrect: false,
          note: '❌ YANLIŞ! THE more...THE more',
        ),
      ],
      commonMistakes: [
        '❌ More you study... → ✅ THE more you study...',
        '❌ The more faster... → ✅ The faster... (double comparative olmaz)',
        '❌ The more I study, I learn more. → ✅ The more I study, the more I learn.',
      ],
      keyPoints: [
        '🔑 Her iki tarafta da "THE" olmalı',
        '🔑 Comparative (-er/more) HER İKİ tarafta da olmalı',
        '🔑 "The sooner, the better" gibi kısa formlar yaygındır',
        '🔑 İkinci cümlede inverted word order gelebilir (edebi)',
      ],
      examTip: '💡 YDS\'de "The more...the more" yapısında "THE" eksikse YANLIŞ!',
    ),

    // 4. OTHER COMPARISON STRUCTURES
    GrammarSubtopic(
      id: 'other_comparisons',
      title: 'Other Comparison Structures',
      titleTr: 'Diğer Karşılaştırma Yapıları',
      explanation: '''
Karşılaştırma için kullanılan diğer yapılar ve kalıplar.

🎯 PREFER / WOULD RATHER:
• Prefer + noun + to + noun
  "I prefer tea to coffee."

• Prefer + V-ing + to + V-ing
  "I prefer walking to driving."

• Would rather + V1 + than + V1
  "I would rather stay than leave."

🎯 SAME / DIFFERENT / SIMILAR:
• The same as: ...ile aynı
  "Your bag is the same as mine."

• Different from: ...den farklı
  "This is different from that."

• Similar to: ...e benzer
  "This is similar to that."

🎯 LIKE / UNLIKE:
• Like: Gibi (benzerlik)
  "He looks like his father."

• Unlike: Aksine, ...den farklı olarak
  "Unlike his brother, he is quiet."
''',
      formula: '''
prefer + noun/V-ing + to + noun/V-ing
would rather + V1 + than + V1
the same + N + as
different + from
similar + to
''',
      examples: [
        GrammarExample(
          english: 'I prefer reading to watching TV.',
          turkish: 'Okumayı TV izlemeye tercih ederim.',
          note: 'prefer + V-ing + to + V-ing',
        ),
        GrammarExample(
          english: 'I would rather walk than take a taxi.',
          turkish: 'Taksi almaktansa yürümeyi tercih ederim.',
          note: 'would rather + V1 + than + V1',
        ),
        GrammarExample(
          english: 'Your opinion is different from mine.',
          turkish: 'Senin fikrin benimkinden farklı.',
          note: 'different from',
        ),
        GrammarExample(
          english: 'This material is similar to silk.',
          turkish: 'Bu kumaş ipeğe benzer.',
          note: 'similar to',
        ),
        GrammarExample(
          english: 'I prefer to read than to watch TV.',
          turkish: 'Okumayı TV izlemeye tercih ederim.',
          isCorrect: false,
          note: '❌ YANLIŞ! prefer...to (than değil)',
        ),
      ],
      commonMistakes: [
        '❌ prefer...than → ✅ prefer...TO',
        '❌ would rather...to → ✅ would rather...THAN',
        '❌ different than → ✅ different FROM (British)',
        '❌ similar with → ✅ similar TO',
      ],
      keyPoints: [
        '🔑 PREFER → TO kullanır (than değil!)',
        '🔑 WOULD RATHER → THAN kullanır (to değil!)',
        '🔑 Different FROM (British) / Different THAN (American)',
        '🔑 Similar TO, Same AS',
      ],
      comparison: '''
🆚 Prefer vs Would rather:
• PREFER: Genel tercih, her zaman doğru
  "I prefer coffee." (Genel olarak kahveyi tercih ederim)
  
• WOULD RATHER: Belirli durum tercihi
  "I would rather have coffee now." (Şu an kahve istiyorum)

🆚 Like vs As:
• LIKE + Noun: "She looks like a model." (Model gibi görünüyor)
• AS + Noun (görev): "She works as a model." (Model olarak çalışıyor)
''',
      examTip: '💡 YDS\'de "prefer...than" veya "would rather...to" görürseniz YANLIŞ!',
    ),
  ],
);
