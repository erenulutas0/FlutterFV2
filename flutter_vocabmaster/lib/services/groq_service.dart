import '../models/writing_practice_models.dart';
import 'groq_api_client.dart';
import '../models/exam_models.dart';
import '../constants/exam_word_lists.dart';

/// Direkt Groq API ile iletişim kuran servis 
/// Sözlük kelime araması için kullanılır
/// BYOK (Bring Your Own Key) destekli - GroqApiClient kullanır
class GroqService {

  /// Kelime anlamlarını, bağlamlarını ve örnek cümleleri getirir
  static Future<Map<String, dynamic>?> lookupWord(String word) async {
    try {
      final result = await GroqApiClient.getJsonResponse(
        messages: [
          {
            'role': 'system',
            'content': '''You are a comprehensive English-Turkish dictionary. When given an English word, provide a refined list of its different meanings in Turkish (up to 5). For EACH meaning, strictly provide:
1. The Turkish translation ('translation')
2. The context/nuance ('context') (e.g. literal, metaphorical, legal)
3. An English example sentence using that specific meaning ('example')

You must respond with valid JSON only. Do not include markdown formatting.
Format: { "word": "input_word", "type": "noun/verb/adj", "meanings": [ { "translation": "Turkish Meaning 1", "context": "Context 1", "example": "Example sentence 1" }, ... ] }'''
          },
          {'role': 'user', 'content': word}
        ],
        temperature: 0.3,
        maxTokens: 700,
        timeout: const Duration(seconds: 20),
      );
      
      return result;
    } catch (e) {
      print('Groq lookup error: $e');
      rethrow;
    }
  }

  /// Kelime anlamlarını DETAYLI olarak getirir - türler (n/v/adj/adv) ile birlikte
  static Future<Map<String, dynamic>> lookupWordDetailed(String word) async {
    final prompt = '''
Look up the English word/phrase "$word" and provide ALL its different meanings with word types.

For EACH meaning, provide:
1. "type" - Word type (n = noun, v = verb, adj = adjective, adv = adverb, phr = phrasal verb, idiom = idiom)
2. "turkishMeaning" - Turkish translation for this specific meaning
3. "englishDefinition" - Brief English definition
4. "example" - An example sentence using the word in this specific meaning
5. "exampleTranslation" - Turkish translation of the example sentence

Return ONLY valid JSON in this exact format:
{
  "word": "$word",
  "phonetic": "/phonetic transcription/",
  "meanings": [
    {
      "type": "v",
      "turkishMeaning": "neden olmak, yol açmak",
      "englishDefinition": "to cause something to happen",
      "example": "The new policy will bring about significant changes.",
      "exampleTranslation": "Yeni politika önemli değişikliklere yol açacak."
    }
  ]
}

Be comprehensive - include ALL common meanings and word types for "$word".
''';

    try {
      return await GroqApiClient.getJsonResponse(
        messages: [
          {'role': 'system', 'content': 'You are a comprehensive English-Turkish dictionary. Always return valid JSON. Be thorough and include all word types and meanings.'},
          {'role': 'user', 'content': prompt}
        ],
        temperature: 0.3,
        timeout: const Duration(seconds: 25),
      );
    } catch (e) {
      print('Groq lookupDetailed error: $e');
      rethrow;
    }
  }

  /// Belirli bir anlam için yeni örnek cümle üretir
  static Future<String> generateSpecificSentence({
    required String word,
    required String translation,
    required String context,
  }) async {
    final prompt = "Generate a new, simple English sentence using the word '$word' specifically in the sense of '$translation' ($context). Return valid JSON: { \"sentence\": \"...\" }";

    try {
      final result = await GroqApiClient.getJsonResponse(
        messages: [
          {'role': 'system', 'content': 'You are a helper generating specific example sentences. Return valid JSON only.'},
          {'role': 'user', 'content': prompt}
        ],
        temperature: 0.7,
        timeout: const Duration(seconds: 15),
      );
      
      return result['sentence'] ?? 'Cümle oluşturulamadı.';
    } catch (e) {
      return 'Cümle oluşturulamadı.';
    }
  }

  /// Cümle içinde kelimenin anlamını açıklar
  static Future<String> explainWordInSentence(String word, String sentence) async {
    final prompt = "Explain the meaning of the word '$word' inside this specific sentence: '$sentence'. Provide the definition in Turkish, keeping it very short/concise (max 15 words). Return ONLY valid JSON. Format: { \"definition\": \"...\" }";

    try {
      final result = await GroqApiClient.getJsonResponse(
        messages: [
          {'role': 'system', 'content': 'You are a dictionary helper. Return valid JSON.'},
          {'role': 'user', 'content': prompt}
        ],
        temperature: 0.3,
        timeout: const Duration(seconds: 15),
      );
      
      return result['definition'] ?? 'Anlam bulunamadı.';
    } catch (e) {
      return 'Anlam bulunamadı.';
    }
  }

  /// Okuma parçası üretir (IELTS/TOEFL tarzı)
  static Future<Map<String, dynamic>> generateReadingPassage(String level) async {
    // Seviyeye göre parametre ayarları
    final Map<String, Map<String, dynamic>> levelConfig = {
      'Beginner': {
        'wordCount': '80-120',
        'sentences': 'very short and simple sentences (5-8 words)',
        'vocabulary': 'basic everyday words, no idioms',
        'topics': 'daily life (family, food, hobbies)',
        'grammar': 'present simple tense only',
        'questionDifficulty': 'direct, answer explicitly in text',
      },
      'Elementary': {
        'wordCount': '120-160',
        'sentences': 'short sentences with basic conjunctions (and, but, because)',
        'vocabulary': 'common words, simple phrasal verbs',
        'topics': 'travel, school, jobs, weather',
        'grammar': 'present and past simple tenses',
        'questionDifficulty': 'mostly direct, one inference question',
      },
      'Intermediate': {
        'wordCount': '160-220',
        'sentences': 'mix of simple and compound sentences',
        'vocabulary': 'wider range, some topic-specific terms',
        'topics': 'technology, health, environment, culture',
        'grammar': 'various tenses, passive voice',
        'questionDifficulty': 'mix of direct and inference questions',
      },
      'Upper-Intermediate': {
        'wordCount': '220-280',
        'sentences': 'complex sentences with subordinate clauses',
        'vocabulary': 'academic vocabulary, idioms, collocations',
        'topics': 'science, economics, social issues',
        'grammar': 'conditionals, relative clauses, modal verbs',
        'questionDifficulty': 'inference and analysis required',
      },
      'Advanced': {
        'wordCount': '280-350',
        'sentences': 'sophisticated sentence structures, varied length',
        'vocabulary': 'advanced academic and specialized terms',
        'topics': 'philosophy, politics, scientific research',
        'grammar': 'all tenses, subjunctive, inversions',
        'questionDifficulty': 'critical thinking and synthesis required',
      },
    };

    // Default: Intermediate ayarlarını kullan
    final config = levelConfig[level] ?? levelConfig['Intermediate']!;

    final prompt = '''
  Generate a reading passage for English learners. Strictly follow these constraints:

  LEVEL: $level
  WORD COUNT: ${config['wordCount']} words (strictly within this range)
  SENTENCE STYLE: ${config['sentences']}
  VOCABULARY: ${config['vocabulary']}
  TOPIC CATEGORY: ${config['topics']}
  GRAMMAR FOCUS: ${config['grammar']}
  QUESTION STYLE: ${config['questionDifficulty']}

  Topic: Choose a specific, interesting topic from the category above.
  Include 3 multiple choice questions (with 4 options and 1 correct answer).
  Return ONLY valid JSON. No markdown formatting, no extra text.
  
  Format:
  {
    "title": "Passage Title",
    "text": "Full passage text here...",
    "wordCount": <actual word count as integer>,
    "questions": [
      {
        "question": "Question 1?",
        "options": ["A", "B", "C", "D"],
        "correctAnswer": "A",
        "explanation": "Brief explanation of why A is correct.",
        "correctAnswerQuote": "Exact sentence or phrase from the text that proves the answer."
      }
    ]
  }
  ''';

    try {
      return await GroqApiClient.getJsonResponse(
        messages: [
          {'role': 'system', 'content': 'You are a professional English exam preparation assistant. Generate content that EXACTLY matches the specified level constraints. Return strictly valid JSON with no markdown formatting.'},
          {'role': 'user', 'content': prompt}
        ],
        temperature: 0.7,
        timeout: const Duration(seconds: 45),
      );
    } catch (e) {
      print('Error generating passage: $e');
      rethrow;
    }
  }

  /// Günün kelimelerini getir (5 adet)
  static Future<List<Map<String, dynamic>>> getDailyWords() async {
    final prompt = '''
    Generate 5 "Word of the Day" vocabulary words for an intermediate English learner.
    
    Return a JSON object with a "words" key containing an array of 5 objects.
    Each object must have exactly these fields:
    - id (number 1-5)
    - word (String)
    - pronunciation (String, e.g. /.../ )
    - translation (String - Turkish)
    - partOfSpeech (String - e.g. Noun, Verb)
    - definition (String - English)
    - exampleSentence (String - English)
    - exampleTranslation (String - Turkish)
    - synonyms (Array of Strings - max 3)
    - difficulty (String - Easy, Medium, or Hard)

    Ensure words are interesting and useful.
    Response format:
    {
      "words": [
        {
          "id": 1,
          "word": "Serendipity",
          "pronunciation": "/ˌser-ən-ˈdi-pə-tē/",
          "translation": "Şans eseri güzel rastlantı",
          "partOfSpeech": "Noun",
          "definition": "The occurrence of events by chance in a happy or beneficial way.",
          "exampleSentence": "It was pure serendipity that I met my best friend at the airport.",
          "exampleTranslation": "En iyi arkadaşımla havaalanında tanışmam tamamen şans eseri güzel bir rastlantıydı.",
          "synonyms": ["luck", "fortune", "chance"],
          "difficulty": "Hard"
        }
      ]
    }
    ''';

    try {
      final result = await GroqApiClient.getJsonResponse(
        messages: [
          {'role': 'system', 'content': 'You are a helpful language learning assistant. Return only valid JSON.'},
          {'role': 'user', 'content': prompt}
        ],
        temperature: 0.8,
        timeout: const Duration(seconds: 30),
      );
      
      if (result['words'] != null) {
        return List<Map<String, dynamic>>.from(result['words']);
      }
      return [];
    } catch (e) {
      print('Error getting daily words: $e');
      return [];
    }
  }

  /// Yazma konusu üretir
  static Future<TopicData> generateWritingTopic(String level, String wordCount) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final prompt = '''Generate a UNIQUE and creative writing topic for $level level 
English learners. The topic should be engaging and appropriate for 
someone who needs to write $wordCount words. 
IMPORTANT: Avoid generic topics like "My Daily Routine" unless explicitly asked. 
Try to be diverse (culture, science, abstract, storytelling, opinion, etc.).
seed: $timestamp

Return JSON with: 
topic, description, level, wordCount.''';
    
    try {
      final result = await GroqApiClient.getJsonResponse(
        messages: [
          {'role': 'user', 'content': prompt}
        ],
        temperature: 0.9,
        timeout: const Duration(seconds: 30),
      );
      
      return TopicData.fromJson(result);
    } catch (e) {
      print('Error generating writing topic: $e');
      rethrow;
    }
  }
  
  /// Yazıyı değerlendirir
  static Future<EvaluationData> evaluateWriting(String text, String level, TopicData topic) async {
    final prompt = '''Evaluate this $level level English writing based on the following topic:
    
TOPIC: ${topic.topic}
DESCRIPTION: ${topic.description}

USER WRITING:
"$text"

Provide detailed feedback in JSON format.
CRITICAL: You MUST check if the user wrote about the assigned topic. 
If the writing is completely off-topic (e.g., user wrote about football when topic was space travel), 
give a low score and mention it in "contextRelevance".

JSON Format:
{
  "score": number (0-100),
  "strengths": string[],
  "improvements": string[],
  "grammar": string,
  "vocabulary": string,
  "coherence": string,
  "overall": string,
  "contextRelevance": string (Assess if the writing matches the topic and description)
}''';
    
    try {
      final result = await GroqApiClient.getJsonResponse(
        messages: [
          {'role': 'user', 'content': prompt}
        ],
        temperature: 0.5,
        timeout: const Duration(seconds: 45),
      );
      
      return EvaluationData.fromJson(result);
    } catch (e) {
      print('Error evaluating writing: $e');
      rethrow;
    }
  }

  /// YDS/YÖKDİL sınavı üretir - BASİTLEŞTİRİLMİŞ VERSİYON
  static Future<ExamBundle> generateExamBundle({
    required String examType, // YDS or YOKDIL (Artık sadece başlık olarak)
    required String mode, // Geriye uyumluluk için, artık hep 'category' gibi davranır
    String? category, // Hangi konudan olacağı (Zorunlu)
    int questionCount = 10,
    String? track, // Geriye uyumluluk için (Kullanılmıyor)
    String userLevel = "B2",
    String targetScore = "60-80",
  }) async {
    
    // Rastgelelik ve Çeşitlilik İçin Gizli Konu İlhamı
    final seed = DateTime.now().millisecondsSinceEpoch;
    
    // Geniş Akademik Konu Havuzu (İlham verici konular)
    final allTopics = [
      'Artificial Intelligence', 'Climate Change', 'Ancient History', 'Quantum Physics', 
      'Neuroscience', 'Art History', 'Global Economics', 'Marine Biology', 
      'Space Exploration', 'Psychology', 'Modern Architecture', 'Cybersecurity', 
      'Nanotechnology', 'Sociology', 'International Law', 'Nutritional Science',
      'Astronomy', 'Education Systems', 'Digital Marketing', 'Sustainable Agriculture',
      'Geology', 'Linguistics', 'Urban Planning', 'Philosophy', 'World Literature', 
      'Renewable Energy', 'Genetics', 'Alternative Medicine', 'Anthropology', 'Archaeology'
    ];
    
    // Listeyi karıştır ve 2-3 tane seç (İlham için)
    final shuffledTopics = List<String>.from(allTopics)..shuffle();
    final inspirationTopics = shuffledTopics.take(3).join(', ');

    // KELİME HAVUZU SEÇİMİ VE ENTEGRASYON STRATEJİSİ
    String targetVocabPrompt = "";
    
    // Rastgele kelime seçimi
    final phrasals = (List<String>.from(ExamWordLists.phrasalVerbs)..shuffle()).take(12).join(', ');
    final words = (List<String>.from(ExamWordLists.academicWords)..shuffle()).take(15).join(', ');

    // STRATEJİ 1: Şıkların bizzat kelime olduğu türler (Vocabulary, Cloze Test)
    if (category == 'vocabulary' || category == 'cloze_test') {
      targetVocabPrompt = '''
*** ZORUNLU KELİME KULLANIMI (ŞIKLARDA) ***
Aşağıdaki kelimeleri soruların DOĞRU CEVABI veya ÇELDİRİCİSİ olarak kullan:
- PHRASAL VERBS: $phrasals
- ACADEMIC WORDS: $words
''';
    } 
    // STRATEJİ 2: Şıkların CÜMLE olduğu türler (Paragraf/Cümle Tamamlama, Reading)
    // Burada kelimeler şık değil, metnin veya cümlenin PARÇASI olmalı.
    else if (category == 'sentence_completion' || 
             category == 'paragraph_completion' || 
             category == 'reading') {
      targetVocabPrompt = '''
*** ZORUNLU KELİME KULLANIMI (BAĞLAM İÇİNDE) ***
Aşağıdaki kelimeleri oluşturduğun metinlerin, paragrafların veya cümlelerin İÇİNDE geçir.
(NOT: Şıklar yine de tam cümle olmalı, sadece bu kelimeleri içersin):
- KELİME HAVUZU: $phrasals, $words
''';
    }

    // Category display names for prompt
    final categoryNames = {
      'grammar': 'Grammar (Tense/Voice, Bağlaçlar)',
      'vocabulary': 'Vocabulary (Phrasal Verbs, Academic Words)',
      'sentence_completion': 'Sentence Completion (Cümle Tamamlama)',
      'translation': 'Translation (Çeviri - İng↔Tr)',
      'paragraph_completion': 'Paragraph Completion (Paragraf Tamamlama)',
      'irrelevant_sentence': 'Irrelevant Sentence (Anlam Bozanı Bul)',
      'reading': 'Reading Comprehension (Okuma Parçası)',
      'cloze_test': 'Cloze Test (Paragraf Boşluk Doldurma)',
    };

    final catName = categoryNames[category] ?? category ?? 'Genel';
    
    final categoryPrompt = '''
SADECE "$catName" kategorisinden $questionCount adet YENİ ve ÖZGÜN soru üret.
KONU: Genel Akademik (Herhangi bir kısıtlama yok, ancak çeşitlilik için şu konulardan İLHAM alabilirsin: $inspirationTopics).

$targetVocabPrompt

ÖNEMLİ: Daha önce sorulmamış, özgün sorular üret. Sorular birbirini tekrar etmesin.

KATEGORİ DETAYLARI:
${_getCategoryDetails(category ?? 'grammar')}
''';

    final systemContent = """Sen profesyonel bir YDS/YÖKDİL sınav uzmanısın.
Görevin, belirtilen formatta tamamen ÖZGÜN, YENİ ve AKADEMİK sorular üretmektir.

KURALLAR:
1. **DİL: Sorular, metinler ve şıklar TAMAMEN İNGİLİZCE olmalı.** (Sadece 'Translation' kategorisi hariç).
2. ASLA Prompt içindeki örnek soruları çıktı olarak verme. Her seferinde sıfırdan düşün.
3. Her soru 5 şık (A, B, C, D, E) içermeli.
4. SADECE BİR doğru cevap olmalı.
5. Çeldiriciler güçlü olmalı.
6. Çıktı SADECE geçerli JSON olmalı.

Seviye: C1 (Advanced)
""";

    final userContent = """YDS/YÖKDİL Sınav Simülasyonu ($questionCount Soru).
Random Seed: $seed (Her seferinde farklı sorular üret)

$categoryPrompt

Kullanıcı Profili:
- Seviye: $userLevel
- Hedef Puan: $targetScore

JSON ÇIKTI FORMATI:
{
  "meta": {
    "exam": "$examType",
    "mode": "category",
    "category": "$category",
    "track": "general",
    "user_level_cefr": "$userLevel",
    "target_score_band": "$targetScore",
    "time_limit_minutes": ${questionCount * 2},
    "total_questions": $questionCount
  },
  "sections": [
    {
      "name": "Generated Test",
      "items": [
        {
          "id": "q_${seed}_1",
          "type": "${category ?? 'mixed'}",
          "difficulty": "hard",
          "skill_tags": [],
          "stem": "Question text (ENGLISH)...",
          "passage": null, 
          "options": {"A":"Answer A (ENGLISH)...","B":"...","C":"...","D":"...","E":"..."},
          "correct": "A",
          "explanation_tr": "Türkçe Açıklama",
          "explanation_en": "English Explanation"
        }
      ]
    }
  ]
}
""";

    try {
      final result = await GroqApiClient.getJsonResponse(
        messages: [
          {'role': 'system', 'content': systemContent},
          {'role': 'user', 'content': userContent}
        ],
        temperature: 0.85, 
        maxTokens: 4000, 
        timeout: Duration(seconds: 60 + (questionCount * 3)), 
      );
      
      return ExamBundle.fromJson(result);
    } catch (e) {
      print('Error generating exam: $e');
      rethrow;
    }
  }

  /// Kategori detaylarını döndürür
  static String _getCategoryDetails(String category) {
    switch (category) {
      case 'grammar':
        return '''
Grammar Soruları FORMATI:
- DİL: TAMAMEN İNGİLİZCE.
- Soru Tipi: Tense, Modal, Passive Voice, IF Clauses, Noun Clauses.
- Yapı: MUTLAKA İKİ BOŞLUKLU (---- ... ----) uzun akademik cümleler.
- Şıklar: "fiil1 / fiil2" formatında.

(REFERANS ÖRNEK - AYNISINI YAZMA):
"It ---- that life on Earth ---- about 4 billion years ago." (Cevap: is believed / started)
''';

      case 'vocabulary':
        return '''
Vocabulary Soruları FORMATI:
- DİL: TAMAMEN İNGİLİZCE.
- Soru Tipi: Phrasal Verbs veya Akademik Kelimeler.
- Yapı: Cümle içinde TEK BOŞLUK (----).
- ASLA "What is the meaning of..." diye sorma. Boşluk doldurma sor.

(REFERANS ÖRNEK - AYNISINI YAZMA):
"The moon maps are incomplete but it is hoped that the 2008 lunar orbiter will ---- the gaps for us." (Cevap: fill in)
''';

      case 'sentence_completion':
        return '''
Sentence Completion FORMATI:
- DİL: TAMAMEN İNGİLİZCE (TÜRKÇE ASLA KULLANMA).
- **BOŞLUK KONUMU:** ÇEŞİTLİLİK ZORUNLUDUR.
    - Soruların yarısında boşluk **SONDA** olsun ("Although X happens, ----.").
    - Soruların yarısında boşluk **BAŞTA** olsun ("----, because the weather was bad.").
    - Bazen de **ORTADA** bir kısmı boş bırakabilirsin.
- **YAPI:** Akademik, bağlaçlı (conjunction) uzun cümleler.
- **ŞIKLAR:** Boşluğu tamamlayan TAM ve ANLAMLI cümlecikler olmalı.

(REFERANS - BAŞTA BOŞLUK):
"----, even though the evidence was not entirely conclusive." (Cevap: The jury decided to convict the defendant)

(REFERANS - SONDA BOŞLUK):
"Unless the government takes immediate action, ----." (Cevap: the economic crisis will deepen further.)
''';

      case 'translation':
        return '''
Translation FORMATI:
- Yarısı İngilizce -> Türkçe, Yarısı Türkçe -> İngilizce.
- Cümleler uzun ve akademik olmalı.
- Şıklar birbirine çok yakın (zaman, özne farkı) olmalı.
''';

      case 'paragraph_completion':
        return '''
Paragraph Completion FORMATI:
- DİL: TAMAMEN İNGİLİZCE (TÜRKÇE ASLA KULLANMA).
- **BOŞLUK KONUMU:** ÇEŞİTLİLİK ZORUNLUDUR. Soruların:
    - %33'ünde boşluk EN BAŞTA (Giriş cümlesi),
    - %33'ünde boşluk ORTADA (Gelişme/Geçiş cümlesi),
    - %33'ünde boşluk SONDA (Sonuç cümlesi) olmalı.
- **YAPI:** 4-6 cümlelik yoğun akademik bir paragraf.
- **MANTIK:** Boş bırakılan cümle, kendisinden önceki veya sonraki cümlelerle anlamsal bağ (reference words, conjunctions) içermeli.

(REFERANS - ORTADA BOŞLUK):
"Otto Lehmann observed that liquid crystals are remarkably sensitive. ---- Further, they can register minute fluctuations in temperature." (Cevap: They respond to heat, light, sound, and electromagnetic fields)

(REFERANS - BAŞTA BOŞLUK):
"---- However, this is not the case for all species. Some have evolved to survive in extreme conditions." (Cevap: Most animals require moderate temperatures to thrive.)
''';

      case 'irrelevant_sentence':
        return '''
Irrelevant Sentence FORMATI:
- DİL: TAMAMEN İNGİLİZCE.
- Romen rakamlarıyla (I), (II), (III), (IV), (V) işaretlenmiş 5 cümle.
- Bir cümle konu akışını bozmalı.
''';

      case 'reading':
        return '''
Reading Comprehension FORMATI:
- DİL: TAMAMEN İNGİLİZCE.
- 150-200 kelimelik yoğun akademik paragraf.
- 3 veya 4 adet soru.
- Sorular yorum, çıkarım ve detay içermeli.
''';

      case 'cloze_test':
        return '''
Cloze Test FORMATI (YDS/YÖKDİL Standardı):
1.  **YAPI:** Her 5 soru için BİR adet yoğun akademik paragraf (150-200 kelime) oluştur. (Örneğin 10 soru isteniyorsa 2 farklı paragraf).
2.  **BOŞLUKLAR:** Paragraf içinde **(1), (2), (3), (4), (5)** şeklinde numaralanmış boşluklar bırak.
3.  **İÇERİK DAĞILIMI (Her 5 soru seti için):**
    -   Boşluk (1): Kelime Sorusu (User's Vocabulary List)
    -   Boşluk (2): Gramer (Tense / Modals / Passive)
    -   Boşluk (3): Bağlaç (Conjunctions / Transitions)
    -   Boşluk (4): Preposition (in, on, at, with...) veya Phrasal Verb
    -   Boşluk (5): Relative Clause veya Participle
4.  **JSON ÇIKTISI:** Ürettiğin her sorunun (item) `passage` alanına bu paragrafın TAMAMINI olduğu gibi kopyala.
5.  **SORU KÖKÜ:** Her sorunun `stem` alanına sadece "Choose the correct option to complete blank (X)." yaz.

(Amaç: Görseldeki gibi tek bir paragraf üzerinden farklı dilbilgisi kurallarını test etmek).
''';

      default:
        return 'Akademik formatta, C1 seviyesinde sorular üret.';
    }
  }
}
