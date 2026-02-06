
import 'grammar_data.dart';
// Core Grammar
import 'grammar_content_tenses.dart';
import 'grammar_content_verb_forms.dart';
import 'grammar_content_modals.dart';
import 'grammar_content_passive.dart';
import 'grammar_content_conditionals.dart';
// Advanced Grammar
import 'grammar_content_relative_clauses.dart';
import 'grammar_content_noun_clauses.dart';
import 'grammar_content_adverb_clauses.dart';
import 'grammar_content_conjunctions.dart';
// Exam Grammar
import 'grammar_content_reported_speech.dart';
import 'grammar_content_causative.dart';
import 'grammar_content_inversion.dart';
import 'grammar_content_comparison.dart';
import 'grammar_content_articles.dart';
import 'grammar_content_prepositions.dart';
import 'grammar_content_sentence_transformation.dart';
// Bonus Grammar
import 'grammar_content_bonus.dart';

class GrammarRepository {
  static List<GrammarTopic> getAllTopics() {
    return [
      // ====== CORE GRAMMAR (Temel Gramer) ======
      tensesTopic,
      verbFormsTopic,
      modalsTopic,
      passiveVoiceTopic,
      conditionalsTopic,
      
      // ====== ADVANCED GRAMMAR (İleri Gramer) ======
      relativeClausesTopic,
      nounClausesTopic,
      adverbClausesTopic,
      conjunctionsTopic,
      
      // ====== EXAM GRAMMAR (Sınav Odaklı) ======
      reportedSpeechTopic,
      causativeTopic,
      inversionTopic,
      comparisonTopic,
      articlesTopic,
      prepositionsTopic,
      sentenceTransformationTopic,
      
      // ====== BONUS GRAMMAR (Bonus Konular) ======
      errorCorrectionTopic,
      wordOrderTopic,
      parallelStructuresTopic,
    ];
  }
}
