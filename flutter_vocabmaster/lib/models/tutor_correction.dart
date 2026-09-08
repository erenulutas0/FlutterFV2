/// One thing the learner said, and the way to say it.
///
/// The speaking tab has always had corrections and never shown them. The server
/// tells the model to recast a mistake naturally inside its reply, so the fix is
/// in there somewhere, folded into a sentence about coffee — which is exactly
/// where someone practising a language will not notice it. This is the same
/// correction, pulled out where it can be read, and later counted.
///
/// Absent means the model had nothing worth correcting, which is the ordinary
/// case and must stay distinguishable from an empty one: a chip that says
/// nothing still tells the learner they got something wrong.
class TutorCorrection {
  const TutorCorrection({
    required this.said,
    required this.better,
    this.note,
  });

  /// What the learner actually said, as the transcript heard it.
  final String said;

  /// The same thing, said correctly.
  final String better;

  /// Why the first line was wrong, in the language the learner reads.
  ///
  /// Two lines with one word changed between them tell a learner that they
  /// were wrong and not what they got wrong: "I am boring" against "I'm bored"
  /// is a joke to anyone who already knows the difference and a mystery to
  /// everyone else, which is the entire audience for this screen. The model
  /// writes this sentence in the learner's own language and the server sends
  /// it through already written, so nothing on this side translates it or ever
  /// should.
  ///
  /// Null is the ordinary case: the model is asked for a note and frequently
  /// has nothing short to say, and every correction that predates the field
  /// has none. It stays distinct from an empty string because a blank line
  /// under a correction is indistinguishable, on a phone, from a card that
  /// failed to draw.
  final String? note;

  /// Reads the `correction` object off a chat response, or null.
  ///
  /// Tolerant on purpose. This is model output that has been through a marker,
  /// a server and a JSON body, and the screen it lands on is the app's most
  /// important one: anything malformed becomes no correction, never a broken
  /// turn. A correction that repeats the learner word for word is dropped too —
  /// being told you were wrong and shown the same sentence back teaches nothing.
  static TutorCorrection? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final String said = value['said']?.toString().trim() ?? '';
    final String better = value['better']?.toString().trim() ?? '';
    if (said.isEmpty || better.isEmpty) {
      return null;
    }
    // Compared with punctuation and spacing removed, because the model is
    // asked to reproduce "their exact words" and drifts by a full stop. A
    // lowercase-only comparison passed "I go to school." against "I go to
    // school" and drew a correction chip whose two lines were identical --
    // being told you were wrong and shown your own sentence back teaches
    // nothing and reads as a bug.
    if (_normalise(said) == _normalise(better)) {
      return null;
    }
    // The note is the one part of a correction the model composes freely, in a
    // language nobody on this side of the wire can read, and it goes onto the
    // screen unedited. Length is the only thing that can be checked without
    // understanding it: asked for a clause, a model that decides to teach the
    // present perfect instead pushes the corrected line off the top of a
    // phone, and the corrected line is the reason the card exists. So an
    // oversized note is dropped and the correction is kept. Never the reverse,
    // and never the whole card -- a bad explanation must not cost a learner
    // the fix it was explaining.
    //
    // Read more strictly than the two lines above it for the same reason. A
    // said or better that arrived as the wrong type is worth stringifying,
    // because the alternative is losing the correction; a note is worth
    // nothing stringified, so anything that is not already text is simply not
    // an explanation.
    final Object? rawNote = value['note'];
    final String note = rawNote is String ? rawNote.trim() : '';
    return TutorCorrection(
      said: said,
      better: better,
      note: note.isEmpty || note.length > _maxNoteLength ? null : note,
    );
  }

  /// Roughly two lines under the correction on a phone. The prompt asks for a
  /// short clause, so anything past this is a model that stopped answering the
  /// question it was asked.
  static const int _maxNoteLength = 160;

  /// Whether this correction is about [transcript], the sentence actually
  /// sent to the model.
  ///
  /// Nothing else checks. The prompt asks the model to correct only what the
  /// learner said and never to invent a mistake, and that request was the
  /// entire enforcement: a hallucinated `said` was attached to the last
  /// learner turn and drawn struck through, under "Say it like this". Being
  /// shown words you never spoke, crossed out, is the fastest way to lose
  /// somebody's trust in the one feature that justifies this screen.
  ///
  /// Word overlap rather than string distance, because the two texts come
  /// from different places -- one from Whisper, one echoed back by the model
  /// -- and disagree about punctuation, casing and the odd filler. A quote
  /// shares nearly all of its words with the original; an invention shares
  /// almost none, so anything in between is rare and the threshold is not
  /// delicate.
  bool isAbout(String transcript) {
    final List<String> quoted = _words(said);
    if (quoted.isEmpty) {
      return false;
    }
    final Set<String> heard = _words(transcript).toSet();
    if (heard.isEmpty) {
      return false;
    }
    final int shared = quoted.where(heard.contains).length;
    return shared / quoted.length >= _minWordOverlap;
  }

  /// Six in ten. A model quoting the learner lands at or near one; a model
  /// inventing a sentence lands near zero.
  static const double _minWordOverlap = 0.6;

  static final RegExp _notWord = RegExp(r"[^a-z0-9']+");

  static List<String> _words(String text) => text
      .toLowerCase()
      .split(_notWord)
      .where((String w) => w.isNotEmpty)
      .toList();

  static String _normalise(String text) => _words(text).join(' ');

  @override
  String toString() => 'TutorCorrection($said -> $better)';
}

/// A reply, and whatever came back with it.
class TutorReply {
  const TutorReply({required this.text, this.correction});

  final String text;
  final TutorCorrection? correction;

  bool get isEmpty => text.trim().isEmpty;
}
