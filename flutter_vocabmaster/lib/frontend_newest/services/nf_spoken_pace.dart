import 'package:flutter/foundation.dart';

import '../../services/chatbot_service.dart';

/// How fast the learner spoke, and where they stopped.
///
/// The tutor corrects *what* was said and has never had anything to say about
/// *how* it was said, which is the gap every speaking-first competitor fills
/// with pronunciation scoring. This is not that, deliberately.
///
/// Whisper offers no per-word confidence — a word object carries `word`,
/// `start` and `end` and nothing else — and the only confidence it does give,
/// `avg_logprob`, is per segment and, as GroqSpeechToTextService already
/// records, "fires on unusual accents". Every learner here has one by that
/// model's standards. Scoring pronunciation from it would mark a Turkish
/// speaker for sounding Turkish, and would have called today's "Amy" heard as
/// "Emi" a mispronunciation when it was the model missing a name.
///
/// Timings carry no such judgement. Pace and hesitation are arithmetic on when
/// words started and stopped: true whatever the accent, and the two things a
/// learner already notices about their own speech. The backend has been
/// fetching and forwarding them since word timestamps were turned on — the
/// comment on the field there says they are for catching hesitation — and the
/// client has been dropping them on the floor.
@immutable
class NfSpokenPace {
  const NfSpokenPace({
    required this.wordsPerMinute,
    required this.longPauses,
    required this.wordCount,
    required this.spokenSeconds,
  });

  /// Words per minute across the spoken span.
  final int wordsPerMinute;

  /// Gaps between consecutive words longer than [_pauseSeconds].
  final int longPauses;

  final int wordCount;

  /// First word's start to the last word's end — not the recording's length,
  /// which includes however long the button was held before and after.
  final double spokenSeconds;

  /// A gap a listener hears as hesitation rather than as rhythm.
  ///
  /// Fluent connected speech leaves well under 0.3s between words. 0.8 is
  /// above anything ordinary and below the length of a pause someone would
  /// apologise for, so it catches searching for a word without flagging
  /// someone taking a breath.
  static const double _pauseSeconds = 0.8;

  /// Below this there is no rate to speak of, only arithmetic.
  ///
  /// "180 words per minute" computed from two words over 0.7 seconds is
  /// technically correct and tells a learner nothing true about how they
  /// speak. Short answers stay unmeasured rather than measured badly.
  static const int _minWords = 8;

  /// Above this the timings are wrong, not the speaker.
  ///
  /// Auctioneers reach about 250 and a learner reading a sentence aloud tops
  /// out near 200, so a number past 300 is a measurement fault rather than a
  /// fast talker, and reporting it would be reporting noise.
  ///
  /// This replaced a three-second floor on the clip, which was the wrong
  /// question. Word count already guarantees the sample; the duration only
  /// mattered as a proxy for whether the answer was believable. On the phone
  /// the floor silently dropped a twelve-word sentence spoken briskly -- a
  /// perfectly good turn, measured and then thrown away -- while letting
  /// nothing through that this does not.
  static const int _maxPlausibleWordsPerMinute = 300;

  /// The pace of [words], or null when there is not enough to measure.
  ///
  /// Null is the ordinary case for a short reply and means "say nothing",
  /// never "zero".
  static NfSpokenPace? from(List<NfWordTiming> words) {
    if (words.length < _minWords) {
      return null;
    }

    final double start = words.first.start;
    final double end = words.last.end;
    final double span = end - start;
    if (!span.isFinite || span <= 0) {
      return null;
    }

    final int wordsPerMinute = (words.length / span * 60).round();
    if (wordsPerMinute > _maxPlausibleWordsPerMinute) {
      return null;
    }

    int pauses = 0;
    for (int i = 1; i < words.length; i++) {
      final double gap = words[i].start - words[i - 1].end;
      // Negative gaps happen: the model overlaps neighbouring words when they
      // run together. That is the opposite of a pause, so it is not one.
      if (gap > _pauseSeconds) {
        pauses++;
      }
    }

    return NfSpokenPace(
      wordsPerMinute: wordsPerMinute,
      longPauses: pauses,
      wordCount: words.length,
      spokenSeconds: span,
    );
  }
}
