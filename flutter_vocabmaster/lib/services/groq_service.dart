import '../models/writing_practice_models.dart';
import 'groq_api_client.dart';

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
}
