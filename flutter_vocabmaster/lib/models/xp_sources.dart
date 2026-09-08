/// Why XP was awarded, as stored in the local `xp_history.source` column.
///
/// Mirrors `WordOrigins` next door: a plain string column rather than an enum,
/// so a new kind of practice costs no migration. These are the values this
/// client writes, and the ones it can recognise reading back.
///
/// Every one of these used to be Turkish prose — 'Telaffuz Pratiği',
/// 'Mükemmel Yazım', 'SRS Tekrar' — chosen at award time and written into the
/// database. The app ships in seven languages, and a ledger row is written once
/// and read forever, so a French learner's history was quietly filling up with
/// Turkish that no later translation pass could ever reach: those rows are
/// already on disk, and the sentence is all they carry. Prose belongs at the
/// point of display, where the reader's language is known. The ledger stores a
/// key.
///
/// Display-time translation is the other half of this, and it is deliberately
/// not done here. Nothing in the shipping frontend renders these values — the
/// only screen that ever did, `lib/screens/xp_history_page.dart`, hangs off
/// `LegacyMainScreen`, which `MainScreen` stopped reaching when it became a
/// thin wrapper around `NfShell`. So there is no user-visible string to
/// localise today, and minting l10n keys for a screen nobody has designed yet
/// would pin the wrong ones. Whoever ports that screen adds the keys and
/// returns them from [labelFor]. The write side could not wait for that: a
/// wrong label is a one-line fix forever, a wrong row is permanent.
class XpSources {
  const XpSources._();

  // Speaking and pronunciation.

  /// A pronunciation attempt was scored.
  static const String pronunciationPractice = 'pronunciation_practice';

  /// That attempt scored 90 or better.
  static const String pronunciationPerfect = 'pronunciation_perfect';

  /// A tutor conversation ran long enough to count as practice.
  static const String speakingPractice = 'speaking_practice';

  // Reading.

  /// A reading passage was completed.
  static const String readingPractice = 'reading_practice';

  /// Every question on that passage was right.
  static const String readingPerfect = 'reading_perfect';

  // Writing.

  /// A writing task was submitted and evaluated.
  static const String writingPractice = 'writing_practice';

  /// That submission scored 90 or better.
  static const String writingPerfect = 'writing_perfect';

  // Translation.

  /// A translation set was finished.
  static const String translationPractice = 'translation_practice';

  /// Every sentence in that set was right.
  static const String translationPerfect = 'translation_perfect';

  // Vocabulary and review.

  /// A sentence was attached to a saved word.
  static const String sentenceAdded = 'sentence_added';

  /// A standalone practice sentence was added.
  static const String practiceSentenceAdded = 'practice_sentence_added';

  /// A word was saved from the daily-words set.
  static const String dailyWord = 'daily_word';

  /// A word was saved from the quick dictionary.
  static const String quickDictionary = 'quick_dictionary';

  /// A word was graded in a spaced-repetition review.
  static const String srsReview = 'srs_review';

  /// Every key this build writes.
  ///
  /// [labelFor] uses it to tell a key apart from a legacy row, and the tests
  /// pin it so a rename cannot quietly orphan history already written under the
  /// old value.
  static const Set<String> all = <String>{
    pronunciationPractice,
    pronunciationPerfect,
    speakingPractice,
    readingPractice,
    readingPerfect,
    writingPractice,
    writingPerfect,
    translationPractice,
    translationPerfect,
    sentenceAdded,
    practiceSentenceAdded,
    dailyWord,
    quickDictionary,
    srsReview,
  };

  /// The text to show for a stored [value], or null when there is nothing
  /// readable to say about it.
  ///
  /// Two kinds of value reach this, and they need opposite handling.
  ///
  /// A key from [all] has no translation yet — see the note on this class — so
  /// it returns null. An honest gap beats leaking `pronunciation_practice` into
  /// the UI dressed as a label; the row still reads, because the action name,
  /// amount and date around it carry the meaning.
  ///
  /// Anything else is a row written before this change, or by a build newer
  /// than this one. A pre-change row holds Turkish prose that is already a
  /// finished sentence in somebody's language, and it cannot be translated
  /// retroactively — nothing recorded which event produced it. So it is passed
  /// through exactly as written. That is the only choice here that destroys no
  /// information, and it is why [all] has to stay stable: the moment a key
  /// changes value, every row written under the old one starts coming back out
  /// of this function as if it were prose.
  static String? labelFor(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (all.contains(value)) {
      return null;
    }
    return value;
  }
}
