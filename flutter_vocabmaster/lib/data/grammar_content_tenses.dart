import 'package:flutter/material.dart';
import 'grammar_data.dart';

/// TENSES - Zamanlar (Core Grammar)
const tensesTopic = GrammarTopic(
  id: 'tenses',
  title: 'Tenses',
  titleTr: 'Zamanlar',
  level: 'core',
  icon: Icons.schedule,
  color: Color(0xFF22c55e),
  subtopics: [
    // 1. PRESENT SIMPLE
    GrammarSubtopic(
      id: 'present_simple',
      title: 'Present Simple',
      titleTr: 'Geniş Zaman',
      explanation: '''
Present Simple (Geniş Zaman), genel doğruları, alışkanlıkları, rutin aktiviteleri ve değişmeyen durumları ifade etmek için kullanılır. 

🎯 Ne zaman kullanılır?
• Evrensel gerçekler ve bilimsel olgular
• Düzenli tekrarlanan eylemler (alışkanlıklar)
• Programlar ve tarifeler (otobüs, tren, uçak saatleri)
• Sportif yorumlar ve kitap/film özetleri
• Duygular ve zihinsel durumlar (believe, know, love, hate)
''',
      formula: '''
➕ Olumlu: Subject + V1 (he/she/it için +s/es)
➖ Olumsuz: Subject + do/does + not + V1
❓ Soru: Do/Does + Subject + V1?

⚠️ 3. tekil şahıs kuralları:
• Genel: +s → works, plays
• -s, -ss, -sh, -ch, -x, -o: +es → goes, watches
• Sessiz harf + y: y→ies → studies (ama: plays)
''',
      examples: [
        GrammarExample(
          english: 'Water boils at 100 degrees Celsius.',
          turkish: 'Su 100 derecede kaynar.',
          note: 'Bilimsel gerçek',
        ),
        GrammarExample(
          english: 'She works at a hospital.',
          turkish: 'O bir hastanede çalışır.',
          note: 'Genel durum',
        ),
        GrammarExample(
          english: 'The train leaves at 8 AM tomorrow.',
          turkish: 'Tren yarın sabah 8\'de kalkıyor.',
          note: 'Program/tarife',
        ),
        GrammarExample(
          english: 'I don\'t like coffee.',
          turkish: 'Kahve sevmiyorum.',
          note: 'Olumsuz cümle',
        ),
        GrammarExample(
          english: 'She go to school every day.',
          turkish: 'O her gün okula gider.',
          isCorrect: false,
          note: '❌ YANLIŞ! "goes" olmalı',
        ),
      ],
      commonMistakes: [
        '❌ He don\'t like... → ✅ He doesn\'t like...',
        '❌ She studys hard. → ✅ She studies hard.',
        '❌ I am go to work. → ✅ I go to work.',
        '❌ Does she likes? → ✅ Does she like?',
      ],
      keyPoints: [
        '🔑 3. tekil şahıs (he/she/it) için fiile -s/-es eklenir',
        '🔑 Olumsuz ve soruda yardımcı fiil kullanılınca ana fiil yalın kalır',
        '🔑 Stative verbs (know, believe, love) genellikle continuous yapılmaz',
      ],
      comparison: '''
🆚 Present Simple vs Present Continuous:
• "I work at a bank." (Genel olarak bankada çalışırım - mesleğim)
• "I am working at a bank." (Şu an/geçici olarak bankada çalışıyorum)

• "She always complains." (Her zaman şikayet eder - alışkanlık)
• "She is always complaining." (Sürekli şikayet ediyor - rahatsız edici)
''',
      examTip: '💡 YDS/YÖKDİL\'de program/tarife belirten cümlelerde Present Simple kullanılır: "The conference starts at 9 AM."',
    ),

    // 2. PRESENT CONTINUOUS
    GrammarSubtopic(
      id: 'present_continuous',
      title: 'Present Continuous',
      titleTr: 'Şimdiki Zaman',
      explanation: '''
Present Continuous (Şimdiki Zaman), konuşma anında devam eden eylemleri, geçici durumları ve yakın gelecek planlarını ifade eder.

🎯 Ne zaman kullanılır?
• Konuşma anında olan eylemler ("Şu an ne yapıyorsun?")
• Geçici durumlar (permanent değil temporary)
• Kesin planlanmış yakın gelecek
• Değişen/gelişen durumlar (getting better, increasing)
• "Always" ile rahatsız edici alışkanlıklar
''',
      formula: '''
➕ Olumlu: Subject + am/is/are + V-ing
➖ Olumsuz: Subject + am/is/are + not + V-ing
❓ Soru: Am/Is/Are + Subject + V-ing?

⚠️ -ing ekleme kuralları:
• -e ile biten: e düşer → make → making
• Tek heceli + CVC: son harf iki yazılır → run → running
• -ie ile biten: ie→y → lie → lying
• -y ile biten: değişmez → play → playing
''',
      examples: [
        GrammarExample(
          english: 'I am studying English right now.',
          turkish: 'Şu an İngilizce çalışıyorum.',
          note: 'Şu anki eylem',
        ),
        GrammarExample(
          english: 'She is living in London this year.',
          turkish: 'Bu yıl Londra\'da yaşıyor.',
          note: 'Geçici durum',
        ),
        GrammarExample(
          english: 'We are meeting the client tomorrow.',
          turkish: 'Yarın müşteriyle buluşuyoruz.',
          note: 'Planlanmış gelecek',
        ),
        GrammarExample(
          english: 'He is always interrupting me!',
          turkish: 'Sürekli sözümü kesiyor!',
          note: 'Rahatsız edici alışkanlık',
        ),
        GrammarExample(
          english: 'I am knowing the answer.',
          turkish: 'Cevabı biliyorum.',
          isCorrect: false,
          note: '❌ Stative verb! "I know" olmalı',
        ),
      ],
      commonMistakes: [
        '❌ I am understand. → ✅ I understand. (stative verb)',
        '❌ She is go to school. → ✅ She is going to school.',
        '❌ He is studing. → ✅ He is studying.',
        '❌ I am believing you. → ✅ I believe you. (stative verb)',
      ],
      keyPoints: [
        '🔑 Stative verbs (know, believe, love, hate, belong, own) continuous yapılmaz',
        '🔑 "Always" ile kullanıldığında olumsuz/rahatsız edici bir anlam katar',
        '🔑 Gelecek plan için kullanıldığında genellikle zaman zarfı gerekir',
      ],
      comparison: '''
🆚 Stative vs Dynamic Verbs:
• Stative (durum): know, believe, love, hate, belong, own, understand
  → ❌ "I am loving this." (yanlış, çünkü "love" stative)
  → ✅ "I love this."

• Dynamic (eylem): work, run, eat, study, play
  → ✅ "I am working now."

⚠️ Bazı fiiller iki anlam taşır:
• "I think he is wrong." (düşünce - stative)
• "I am thinking about the problem." (düşünme eylemi - dynamic)

• "She has a car." (sahiplik - stative)
• "She is having dinner." (yemek yeme eylemi - dynamic)
''',
      examTip: '💡 YDS\'de "currently, at the moment, nowadays, these days" zarfları Present Continuous işaretidir.',
    ),

    // 3. PRESENT PERFECT
    GrammarSubtopic(
      id: 'present_perfect',
      title: 'Present Perfect',
      titleTr: 'Yakın Geçmiş / Belirsiz Geçmiş',
      explanation: '''
Present Perfect, geçmişte başlayıp etkisi hâlâ devam eden veya sonuçları şu anı etkileyen eylemleri ifade eder. Tam olarak "ne zaman" olduğu önemli değildir.

🎯 Ne zaman kullanılır?
• Hayat deneyimleri (Have you ever...?)
• Geçmişten şu ana kadar devam eden durumlar (for, since)
• Az önce tamamlanan eylemler (just, already, yet)
• Sonucu şu an önemli olan geçmiş eylemler
• Tekrarlanan geçmiş eylemler (several times, twice)
''',
      formula: '''
➕ Olumlu: Subject + have/has + V3 (past participle)
➖ Olumsuz: Subject + have/has + not + V3
❓ Soru: Have/Has + Subject + V3?

📌 V3 düzenli fiillerde: V1 + ed (worked, played)
📌 V3 düzensiz fiillerde: ezber (gone, eaten, written)
''',
      examples: [
        GrammarExample(
          english: 'I have visited Paris three times.',
          turkish: 'Paris\'i üç kez ziyaret ettim.',
          note: 'Hayat deneyimi',
        ),
        GrammarExample(
          english: 'She has lived here since 2010.',
          turkish: '2010\'dan beri burada yaşıyor.',
          note: 'Devam eden durum (since)',
        ),
        GrammarExample(
          english: 'I have just finished my homework.',
          turkish: 'Ödevimi az önce bitirdim.',
          note: 'Az önce tamamlanan eylem',
        ),
        GrammarExample(
          english: 'Have you ever eaten sushi?',
          turkish: 'Hiç suşi yedin mi?',
          note: 'Deneyim sorusu',
        ),
        GrammarExample(
          english: 'I have seen this movie yesterday.',
          turkish: 'Bu filmi dün izledim.',
          isCorrect: false,
          note: '❌ "yesterday" belirli zaman! Past Simple kullan',
        ),
      ],
      commonMistakes: [
        '❌ I have went to school. → ✅ I have gone to school.',
        '❌ She has saw the movie. → ✅ She has seen the movie.',
        '❌ I have been here yesterday. → ✅ I was here yesterday.',
        '❌ He has work here for 5 years. → ✅ He has worked here for 5 years.',
      ],
      keyPoints: [
        '🔑 Belirli zaman zarfları (yesterday, last week, in 2010) kullanılmaz!',
        '🔑 "for" süre, "since" başlangıç noktası bildirir',
        '🔑 "gone" gidip dönmemiş, "been" gidip dönmüş demektir',
        '🔑 "Have you ever...?" kalıbı deneyim sormak için kullanılır',
      ],
      comparison: '''
🆚 Present Perfect vs Past Simple:
• "I have lost my keys." (Anahtarlarım hâlâ kayıp - şu an önemli)
• "I lost my keys yesterday." (Dün kaybettim - belirli zaman)

• "She has worked here for 10 years." (Hâlâ çalışıyor)
• "She worked here for 10 years." (Artık çalışmıyor)

🆚 Gone vs Been:
• "He has gone to Paris." (Paris'e gitti, hâlâ orada)
• "He has been to Paris." (Paris'e gitti ve döndü - deneyim)
''',
      examTip: '💡 YDS\'de "since, for, already, yet, just, ever, never, so far, up to now, recently" Present Perfect işaretleridir.',
    ),

    // 4. PRESENT PERFECT CONTINUOUS
    GrammarSubtopic(
      id: 'present_perfect_continuous',
      title: 'Present Perfect Continuous',
      titleTr: 'Yakın Geçmişte Devam Eden',
      explanation: '''
Present Perfect Continuous, geçmişte başlayıp şu ana kadar devam eden veya az önce biten (sonuçları görünen) eylemlerin SÜRESİNİ vurgular.

🎯 Ne zaman kullanılır?
• Geçmişten şu ana kadar devam eden eylemler (süre vurgusu)
• Az önce bitmiş ama etkisi görünen eylemler
• Tekrar eden eylemler (recently, lately)

🎯 Present Perfect'ten farkı:
Present Perfect → Sonuç odaklı ("Bitirdim")
Present Perfect Continuous → Süreç/süre odaklı ("Yapıyordum")
''',
      formula: '''
➕ Olumlu: Subject + have/has + been + V-ing
➖ Olumsuz: Subject + have/has + not + been + V-ing
❓ Soru: Have/Has + Subject + been + V-ing?
''',
      examples: [
        GrammarExample(
          english: 'I have been studying for 3 hours.',
          turkish: '3 saattir ders çalışıyorum.',
          note: 'Süre vurgusu',
        ),
        GrammarExample(
          english: 'She has been crying. Her eyes are red.',
          turkish: 'Ağlıyordu. Gözleri kırmızı.',
          note: 'Az önce bitmiş, etkisi görünüyor',
        ),
        GrammarExample(
          english: 'They have been arguing a lot lately.',
          turkish: 'Son zamanlarda çok tartışıyorlar.',
          note: 'Tekrar eden eylem',
        ),
        GrammarExample(
          english: 'I have been knowing him for years.',
          turkish: 'Onu yıllardır tanıyorum.',
          isCorrect: false,
          note: '❌ Stative verb! "I have known" olmalı',
        ),
      ],
      commonMistakes: [
        '❌ I have been know him. → ✅ I have known him. (stative verb)',
        '❌ She has been wait for you. → ✅ She has been waiting for you.',
        '❌ They have been lived here. → ✅ They have been living here.',
      ],
      keyPoints: [
        '🔑 Stative verbs bu yapıda kullanılmaz (know, believe, love)',
        '🔑 Süre vurgulamak için "for" veya "since" sık kullanılır',
        '🔑 "All day, all week, lately, recently" zarflarıyla sık görülür',
      ],
      comparison: '''
🆚 Present Perfect vs Present Perfect Continuous:
• "I have read the book." (Kitabı okudum - bitti, tamamlandı)
• "I have been reading the book." (Kitabı okuyorum - hâlâ okuyorum veya süreç önemli)

• "She has written 3 reports." (3 rapor yazdı - sayı/sonuç)
• "She has been writing reports all day." (Bütün gün rapor yazıyor - süre/süreç)

💡 Sayı veya miktar belirtiliyorsa → Present Perfect
💡 Süre veya süreç vurgulanıyorsa → Present Perfect Continuous
''',
      examTip: '💡 YDS\'de "for hours, all day, since morning" gibi süre vurgulayan ifadeler Present Perfect Continuous işaretidir.',
    ),

    // 5. PAST SIMPLE
    GrammarSubtopic(
      id: 'past_simple',
      title: 'Past Simple',
      titleTr: 'Geçmiş Zaman (Di\'li Geçmiş)',
      explanation: '''
Past Simple, geçmişte tamamlanmış, belli bir zamanda gerçekleşmiş eylemleri ifade eder. "Ne zaman?" sorusunun cevabı verilebilir.

🎯 Ne zaman kullanılır?
• Geçmişte belli bir zamandaki olaylar (yesterday, last week, in 2010)
• Ardışık geçmiş eylemler (hikaye anlatımı)
• Geçmişteki alışkanlıklar (used to ile)
• Geçmişte tamamlanmış durumlar
''',
      formula: '''
➕ Olumlu: Subject + V2 (past form)
➖ Olumsuz: Subject + did + not + V1
❓ Soru: Did + Subject + V1?

📌 Düzenli fiiller: V1 + ed (worked, played, studied)
📌 Düzensiz fiiller: ezber (went, ate, saw, took)

⚠️ -ed telaffuzu:
• /t/: worked, walked (sert sessiz harflerden sonra)
• /d/: played, cleaned (yumuşak seslerden sonra)
• /ɪd/: wanted, needed (t veya d ile bitenlerden sonra)
''',
      examples: [
        GrammarExample(
          english: 'I visited my grandmother last weekend.',
          turkish: 'Geçen hafta sonu büyükannemi ziyaret ettim.',
          note: 'Belirli zaman',
        ),
        GrammarExample(
          english: 'She woke up, had breakfast, and left.',
          turkish: 'Uyandı, kahvaltı yaptı ve ayrıldı.',
          note: 'Ardışık eylemler',
        ),
        GrammarExample(
          english: 'They didn\'t come to the party.',
          turkish: 'Partiye gelmediler.',
          note: 'Olumsuz cümle',
        ),
        GrammarExample(
          english: 'I did went to school.',
          turkish: 'Okula gittim.',
          isCorrect: false,
          note: '❌ "did" varken fiil yalın kalır: "I did go" veya "I went"',
        ),
      ],
      commonMistakes: [
        '❌ I didn\'t went. → ✅ I didn\'t go.',
        '❌ Did she came? → ✅ Did she come?',
        '❌ He readed the book. → ✅ He read the book. (düzensiz fiil)',
        '❌ I was go to school. → ✅ I went to school.',
      ],
      keyPoints: [
        '🔑 Belirli zaman zarfları (yesterday, ago, last) Past Simple gerektirir',
        '🔑 "did" kullanıldığında ana fiil her zaman V1 (yalın) olur',
        '🔑 Düzensiz fiillerin V2 formlarını ezberlemek gerekir',
      ],
      comparison: '''
🆚 Past Simple vs Present Perfect:
• "I saw that movie." (Belirli bir zamanda - ne zaman olduğu söylenebilir)
• "I have seen that movie." (Belirsiz zaman - ne zaman olduğu önemli değil)

• "She lived in Paris for 5 years." (Artık orada yaşamıyor)
• "She has lived in Paris for 5 years." (Hâlâ orada yaşıyor)
''',
      examTip: '💡 YDS\'de "yesterday, ago, last, in 2010, when I was a child" Past Simple işaretleridir.',
    ),

    // 6. PAST CONTINUOUS
    GrammarSubtopic(
      id: 'past_continuous',
      title: 'Past Continuous',
      titleTr: 'Geçmişte Devam Eden',
      explanation: '''
Past Continuous, geçmişte belirli bir anda devam etmekte olan eylemleri veya arka plan olaylarını ifade eder.

🎯 Ne zaman kullanılır?
• Geçmişte belirli bir anda devam eden eylem
• İki geçmiş eylemin kesişimi (while, when)
• Hikayede arka plan/atmosfer anlatımı
• Aynı anda gerçekleşen paralel eylemler
''',
      formula: '''
➕ Olumlu: Subject + was/were + V-ing
➖ Olumsuz: Subject + was/were + not + V-ing
❓ Soru: Was/Were + Subject + V-ing?
''',
      examples: [
        GrammarExample(
          english: 'I was sleeping when you called.',
          turkish: 'Sen aradığında uyuyordum.',
          note: 'Kesişen eylemler',
        ),
        GrammarExample(
          english: 'While she was cooking, he was watching TV.',
          turkish: 'O yemek yaparken, o TV izliyordu.',
          note: 'Paralel eylemler',
        ),
        GrammarExample(
          english: 'The sun was shining and birds were singing.',
          turkish: 'Güneş parlıyordu ve kuşlar ötüyordu.',
          note: 'Arka plan/atmosfer',
        ),
        GrammarExample(
          english: 'I was knowing the answer.',
          turkish: 'Cevabı biliyordum.',
          isCorrect: false,
          note: '❌ Stative verb! "I knew" olmalı',
        ),
      ],
      commonMistakes: [
        '❌ I was know the answer. → ✅ I knew the answer.',
        '❌ When I was sleep... → ✅ When I was sleeping...',
        '❌ She were watching TV. → ✅ She was watching TV.',
      ],
      keyPoints: [
        '🔑 "When" kısa eylemle, "while" uzun eylemle kullanılır',
        '🔑 Stative verbs Past Continuous yapılmaz',
        '🔑 İki uzun eylem için "while...while" veya "as...as" kullanılır',
      ],
      comparison: '''
🆚 When vs While:
• "When she arrived, I was cooking." (Arrived: kısa, cooking: uzun)
• "While I was cooking, she arrived." (Aynı anlam, farklı vurgu)
• "While I was cooking, she was reading." (İki uzun eylem paralel)

📌 When + Past Simple (kısa eylem)
📌 While + Past Continuous (uzun eylem)
''',
      examTip: '💡 YDS\'de "while, when, as, at that moment" Past Continuous ipuçlarıdır.',
    ),

    // 7. PAST PERFECT
    GrammarSubtopic(
      id: 'past_perfect',
      title: 'Past Perfect',
      titleTr: 'Miş\'li Geçmiş',
      explanation: '''
Past Perfect, geçmişteki bir olaydan ÖNCE tamamlanmış başka bir olayı ifade eder. "Geçmişin geçmişi" olarak düşünülebilir.

🎯 Ne zaman kullanılır?
• Geçmişteki iki olayın zaman sıralamasını belirtmek
• Reported speech (dolaylı anlatım) içinde
• Third conditional (If + had + V3)
• "By the time, before, after, when" ile
''',
      formula: '''
➕ Olumlu: Subject + had + V3
➖ Olumsuz: Subject + had + not + V3
❓ Soru: Had + Subject + V3?
''',
      examples: [
        GrammarExample(
          english: 'When I arrived, the movie had already started.',
          turkish: 'Ben geldiğimde film çoktan başlamıştı.',
          note: 'Önce başladı, sonra geldim',
        ),
        GrammarExample(
          english: 'She had never seen snow before she moved to Canada.',
          turkish: 'Kanada\'ya taşınmadan önce hiç kar görmemişti.',
          note: 'Önceki deneyim',
        ),
        GrammarExample(
          english: 'I realized I had forgotten my keys.',
          turkish: 'Anahtarlarımı unuttuğumu fark ettim.',
          note: 'Fark etmeden ÖNCE unutmuş',
        ),
        GrammarExample(
          english: 'After he had finished, he left.',
          turkish: 'Bitirdikten sonra ayrıldı.',
          note: 'Önce bitirdi, sonra ayrıldı',
        ),
      ],
      commonMistakes: [
        '❌ I had went home. → ✅ I had gone home.',
        '❌ She had already leave. → ✅ She had already left.',
        '❌ Before I had arrive... → ✅ Before I arrived...',
      ],
      keyPoints: [
        '🔑 İki geçmiş olay varsa, ÖNCE olan Past Perfect, SONRA olan Past Simple',
        '🔑 "By the time" → Past Perfect sık kullanılır',
        '🔑 "After" ile Past Perfect, "before" ile Past Simple sık görülür',
      ],
      comparison: '''
🆚 Past Perfect vs Past Simple:
• "When I arrived, he left." (Aynı anda veya ben geldikten sonra ayrıldı)
• "When I arrived, he had left." (Ben gelmeden ÖNCE ayrılmıştı)

💡 Hangisi önce oldu?
1. He left (önce) → had left
2. I arrived (sonra) → arrived

🆚 Already/Yet/Just:
• Present Perfect: "I have just eaten."
• Past Perfect: "I had just eaten when you called."
''',
      examTip: '💡 YDS\'de "by the time, before, after, until, when" bağlaçları Past Perfect ipucudur.',
    ),

    // 8. PAST PERFECT CONTINUOUS
    GrammarSubtopic(
      id: 'past_perfect_continuous',
      title: 'Past Perfect Continuous',
      titleTr: 'Geçmişte Sürmekte Olan',
      explanation: '''
Past Perfect Continuous, geçmişteki bir olaydan önce başlayıp o ana kadar devam etmiş eylemlerin SÜRESİNİ vurgular.

🎯 Ne zaman kullanılır?
• Geçmişte bir noktaya kadar süren eylemler (süre vurgusu)
• Geçmişteki bir eylemin sebebini açıklamak
• "How long" sorularının cevabında
''',
      formula: '''
➕ Olumlu: Subject + had + been + V-ing
➖ Olumsuz: Subject + had + not + been + V-ing
❓ Soru: Had + Subject + been + V-ing?
''',
      examples: [
        GrammarExample(
          english: 'I had been waiting for 2 hours when she finally arrived.',
          turkish: 'O sonunda geldiğinde 2 saattir bekliyordum.',
          note: 'Süre vurgusu',
        ),
        GrammarExample(
          english: 'The ground was wet because it had been raining.',
          turkish: 'Yağmur yağmış olduğu için zemin ıslaktı.',
          note: 'Sebep açıklama',
        ),
        GrammarExample(
          english: 'She was tired because she had been working all day.',
          turkish: 'Bütün gün çalıştığı için yorgundu.',
          note: 'Sonuç gösterme',
        ),
      ],
      commonMistakes: [
        '❌ I had been wait for hours. → ✅ I had been waiting for hours.',
        '❌ She had been knew him. → ✅ She had known him. (stative verb)',
      ],
      keyPoints: [
        '🔑 Süre veya süreç vurgusu için kullanılır',
        '🔑 Stative verbs bu yapıda kullanılmaz',
        '🔑 "for" (süre) ve "since" (başlangıç) sık kullanılır',
      ],
      comparison: '''
🆚 Past Perfect vs Past Perfect Continuous:
• "I had read the report before the meeting." (Raporu okumuştum - tamamlamıştım)
• "I had been reading the report for an hour when she called." (1 saattir okuyordum - süreç)

💡 Tamamlanan eylem → Past Perfect
💡 Süren/devam eden eylem → Past Perfect Continuous
''',
      examTip: '💡 "How long had you been...?" sorularına Past Perfect Continuous ile cevap verilir.',
    ),

    // 9. FUTURE (WILL)
    GrammarSubtopic(
      id: 'future_will',
      title: 'Future Simple (will)',
      titleTr: 'Gelecek Zaman (will)',
      explanation: '''
Will, anlık kararlar, tahminler, vaatler ve kesinlik bildiren gelecek olayları ifade eder.

🎯 Ne zaman kullanılır?
• Anlık kararlar (konuşma anında verilen karar)
• Tahmin ve öngörüler (I think, probably)
• Vaatler ve teklifler
• Kesin gelecek olaylar (güneş yarın doğacak)
• Şartlı cümlelerin ana cümlesi (If..., ...will)
''',
      formula: '''
➕ Olumlu: Subject + will + V1
➖ Olumsuz: Subject + will + not (won't) + V1
❓ Soru: Will + Subject + V1?
''',
      examples: [
        GrammarExample(
          english: 'I\'ll help you with your bags.',
          turkish: 'Çantalarında sana yardım ederim.',
          note: 'Anlık karar/teklif',
        ),
        GrammarExample(
          english: 'I think it will rain tomorrow.',
          turkish: 'Yarın yağmur yağacak sanırım.',
          note: 'Tahmin',
        ),
        GrammarExample(
          english: 'I will always love you.',
          turkish: 'Seni her zaman seveceğim.',
          note: 'Vaat',
        ),
        GrammarExample(
          english: 'If you study hard, you will pass.',
          turkish: 'Çok çalışırsan geçersin.',
          note: 'First conditional',
        ),
      ],
      commonMistakes: [
        '❌ I will going to help. → ✅ I will help. / I am going to help.',
        '❌ Will you coming? → ✅ Will you come?',
        '❌ She wills help you. → ✅ She will help you.',
      ],
      keyPoints: [
        '🔑 "Will" sonrası fiil her zaman yalın (V1) olur',
        '🔑 Kısa form: will = \'ll, will not = won\'t',
        '🔑 Anlık karar → will, önceden planlanmış → going to',
      ],
      comparison: '''
🆚 Will vs Going to:
• "The phone is ringing. I\'ll answer it." (Anlık karar)
• "I\'m going to answer the phone." (Önceden niyetim var - garip)

• "Look at those clouds! It\'s going to rain." (Görsel kanıt)
• "I think it will rain tomorrow." (Kişisel tahmin)

📌 Anlık karar, vaat, teklif → will
📌 Plan, niyet, kanıta dayalı tahmin → going to
''',
      examTip: '💡 YDS\'de "I think, probably, perhaps, maybe" → will kullanılır.',
    ),

    // 10. FUTURE (GOING TO)
    GrammarSubtopic(
      id: 'future_going_to',
      title: 'Future (be going to)',
      titleTr: 'Gelecek Zaman (be going to)',
      explanation: '''
Be going to, önceden planlanmış niyetleri ve mevcut kanıtlara dayalı tahminleri ifade eder.

🎯 Ne zaman kullanılır?
• Önceden yapılmış planlar ve niyetler
• Mevcut kanıtlara dayalı tahminler
• Yakın gelecekte olacağı belli olan şeyler
''',
      formula: '''
➕ Olumlu: Subject + am/is/are + going to + V1
➖ Olumsuz: Subject + am/is/are + not + going to + V1
❓ Soru: Am/Is/Are + Subject + going to + V1?
''',
      examples: [
        GrammarExample(
          english: 'I\'m going to visit my parents this weekend.',
          turkish: 'Bu hafta sonu ailemi ziyaret edeceğim.',
          note: 'Plan/niyet',
        ),
        GrammarExample(
          english: 'Look at those dark clouds! It\'s going to rain.',
          turkish: 'Şu kara bulutlara bak! Yağmur yağacak.',
          note: 'Kanıta dayalı tahmin',
        ),
        GrammarExample(
          english: 'She\'s going to have a baby. (She\'s pregnant)',
          turkish: 'Bebek sahibi olacak. (Hamile)',
          note: 'Belli olan gelecek',
        ),
      ],
      commonMistakes: [
        '❌ I going to help. → ✅ I am going to help.',
        '❌ She is going to goes. → ✅ She is going to go.',
        '❌ Are you going to coming? → ✅ Are you going to come?',
      ],
      keyPoints: [
        '🔑 "going to" sonrası fiil V1 (yalın) olur',
        '🔑 Konuşma dilinde "gonna" şeklinde söylenir',
        '🔑 Kanıt/işaret varsa going to, yoksa will',
      ],
      examTip: '💡 YDS\'de "intend to, plan to" anlamı için "going to" kullanılır.',
    ),

    // 11. FUTURE PERFECT
    GrammarSubtopic(
      id: 'future_perfect',
      title: 'Future Perfect',
      titleTr: 'Gelecekte Tamamlanmış',
      explanation: '''
Future Perfect, gelecekte belirli bir zamana kadar tamamlanmış olacak eylemleri ifade eder.

🎯 Ne zaman kullanılır?
• Gelecekte bir noktadan önce bitecek eylemler
• "By" (... kadar) ile sık kullanılır
• Deadline veya hedef belirtirken
''',
      formula: '''
➕ Olumlu: Subject + will + have + V3
➖ Olumsuz: Subject + will + not + have + V3
❓ Soru: Will + Subject + have + V3?
''',
      examples: [
        GrammarExample(
          english: 'By next year, I will have graduated.',
          turkish: 'Gelecek yıla kadar mezun olmuş olacağım.',
          note: 'Gelecekteki deadline',
        ),
        GrammarExample(
          english: 'She will have finished the project by Friday.',
          turkish: 'Cuma\'ya kadar projeyi bitirmiş olacak.',
          note: 'Hedef',
        ),
        GrammarExample(
          english: 'By the time you arrive, I will have left.',
          turkish: 'Sen geldiğinde ben gitmiş olacağım.',
          note: 'By the time ile',
        ),
      ],
      keyPoints: [
        '🔑 "By + zaman" ile sık kullanılır',
        '🔑 Tamamlanmış olma durumunu vurgular',
        '🔑 "By the time, by next..." kalıpları Future Perfect işaretidir',
      ],
      examTip: '💡 YDS\'de "by the time, by next month/year, by then" → Future Perfect ipucudur.',
    ),

    // 12. FUTURE CONTINUOUS
    GrammarSubtopic(
      id: 'future_continuous',
      title: 'Future Continuous',
      titleTr: 'Gelecekte Devam Eden',
      explanation: '''
Future Continuous, gelecekte belirli bir anda devam ediyor olacak eylemleri ifade eder.

🎯 Ne zaman kullanılır?
• Gelecekte belirli bir anda devam edecek eylemler
• Nazik soru sormak ("Will you be using...?")
• Rutin olarak gelecekte olacak eylemler
''',
      formula: '''
➕ Olumlu: Subject + will + be + V-ing
➖ Olumsuz: Subject + will + not + be + V-ing
❓ Soru: Will + Subject + be + V-ing?
''',
      examples: [
        GrammarExample(
          english: 'This time tomorrow, I will be flying to Paris.',
          turkish: 'Yarın bu saatte Paris\'e uçuyor olacağım.',
          note: 'Belirli anda devam eden',
        ),
        GrammarExample(
          english: 'Will you be using the car tonight?',
          turkish: 'Bu akşam arabayı kullanacak mısın?',
          note: 'Nazik soru',
        ),
        GrammarExample(
          english: 'Don\'t call at 8 PM. I will be having dinner.',
          turkish: 'Saat 8\'de arama. Yemek yiyor olacağım.',
          note: 'Planlı rutin',
        ),
      ],
      keyPoints: [
        '🔑 "This time tomorrow/next week" sık kullanılır',
        '🔑 Nazik soru sormak için tercih edilir',
        '🔑 Süregelen eylem vurgusu',
      ],
      examTip: '💡 "At this time tomorrow, at 5 PM tomorrow" → Future Continuous ipuçlarıdır.',
    ),
  ],
);
