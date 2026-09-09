import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/word.dart';
import '../../models/word_origins.dart';
import '../../providers/app_state_provider.dart';
import '../../services/ai_error_message_formatter.dart';
import '../../services/ai_paywall_handler.dart';
import '../../services/api_service.dart';
import '../../services/groq_service.dart';
import '../../utils/sentence_tokens.dart';
import '../../utils/word_family.dart';
import '../theme/nf_tokens.dart';
import 'nf_button.dart';

/// Tapping a word to find out what it means, wherever the words are.
///
/// This lived inside the book reader, because the reader is where it was
/// first needed. It was never about books: the first thing a real user asked
/// for was the same tap in the tutor's chat, and the reader's version was
/// already the whole answer — the tokeniser, the recogniser bookkeeping, the
/// dictionary call, the quota handling, the three-state save button and the
/// hard-won detail that a saved word has to be pushed into [AppStateProvider]
/// or the Words screen goes on denying it exists.
///
/// So it moved here rather than being written a second time. Two copies of
/// this would be two places to fix the next quota message and one of them
/// would be missed.

/// Text where every word is its own tap target.
///
/// Stateful because of the recognizers. [TapGestureRecognizer] holds resources
/// and must be disposed, and a novel is thousands of words: created inline in a
/// `build` they would leak one per word per rebuild, and a reader would watch
/// the page get slower the longer they stayed on it. Owning them here ties each
/// one's life to the text that uses it.
class NfTappableText extends StatefulWidget {
  const NfTappableText({
    super.key,
    required this.text,
    required this.onWordTapped,
    this.saved = const <String>{},
    this.savedColor,
    this.style,
  });

  final String text;
  final void Function(String token) onWordTapped;

  /// Words the learner has saved, lowercased. Marked where they appear.
  final Set<String> saved;
  final Color? savedColor;

  /// How the text is drawn. Defaults to the reader's body style.
  ///
  /// A parameter because the two callers are not the same shape: prose on a
  /// page and a line inside a speech bubble differ in size, colour and leading,
  /// and a bubble in particular has to draw the learner's own words on a filled
  /// primary background where the reader's ink would be unreadable.
  final TextStyle? style;

  @override
  State<NfTappableText> createState() => _NfTappableTextState();
}

class _NfTappableTextState extends State<NfTappableText> {
  List<String> _tokens = const <String>[];
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  @override
  void initState() {
    super.initState();
    _rebuildTokens();
  }

  @override
  void didUpdateWidget(NfTappableText old) {
    super.didUpdateWidget(old);
    // A recycled list row can be handed a different sentence. Rebuilding the
    // recognizers is what keeps a tap on row three from looking up row nine's
    // word.
    if (old.text != widget.text) {
      _rebuildTokens();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final TapGestureRecognizer recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  /// Whether this token is one of the learner's own words.
  ///
  /// A dotted underline rather than a highlight: a page of highlights is a page
  /// nobody reads, and the point is to notice your own vocabulary in the middle
  /// of a story, not to have the story marked up. Inflections count -- someone
  /// who saved "flight" should see it in "the flights were delayed", which is
  /// the sentence that shows the word is theirs.
  bool _isSaved(String token) {
    if (widget.saved.isEmpty) return false;
    final String word = SentenceTokens.word(token);
    if (word.isEmpty) return false;
    for (final String form in WordFamily.baseForms(word)) {
      if (widget.saved.contains(form)) return true;
    }
    return false;
  }

  void _rebuildTokens() {
    _disposeRecognizers();
    _tokens = SentenceTokens.split(widget.text);
    for (final String token in _tokens) {
      if (token.trim().isEmpty) continue;
      _recognizers.add(
        TapGestureRecognizer()..onTap = () => widget.onWordTapped(token),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final NfTokens t = NfTokens.of(context);

    // Built as one RichText rather than a wrap of widgets so the text flows
    // like prose. Whitespace tokens are kept as plain spans: SentenceTokens
    // returns them, and dropping them would run the sentence together.
    final List<InlineSpan> spans = <InlineSpan>[];
    int recognizerIndex = 0;
    for (final String token in _tokens) {
      if (token.trim().isEmpty) {
        spans.add(TextSpan(text: token));
        continue;
      }
      final bool mine = _isSaved(token);
      spans.add(TextSpan(
        text: token,
        recognizer: _recognizers[recognizerIndex++],
        style: mine
            ? TextStyle(
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dotted,
                decorationColor: widget.savedColor ?? t.primary,
                decorationThickness: 2,
              )
            : null,
      ));
    }

    return RichText(
      text: TextSpan(
        style: widget.style ??
            TextStyle(
              color: t.ink,
              fontSize: NfFont.s17,
              fontWeight: NfTokens.bodyWeight,
              height: 1.6,
            ),
        children: spans,
      ),
    );
  }
}

/// What a tapped word shows: its meaning in this sentence, and a way to keep it.
///
/// Public, and its lookup injectable, so a test can drive the save. The bug
/// this guards against is silent: the word reaches the server, the sheet says
/// so, and the deck the learner then opens has never heard of it.
class NfWordSheet extends StatefulWidget {
  const NfWordSheet({
    super.key,
    this.lookUp,
    required this.word,
    required this.sentence,
    required this.sentenceTranslation,
    required this.api,
    required this.onSaved,
    this.alreadySaved = false,
    this.origin = WordOrigins.reader,
  });

  final String word;
  final String sentence;

  /// The book's translation of [sentence], or null when it has none. Always
  /// null outside the reader — nothing translates a line of live conversation.
  final String? sentenceTranslation;

  final ApiService api;

  /// Called with the word the server created, so the rest of the app learns
  /// about it without waiting for a restart.
  final void Function(Word word) onSaved;

  /// How to explain the word in its sentence. Defaults to the app's dictionary.
  final Future<String> Function(String word, String sentence)? lookUp;

  /// Whether this word is in the deck already, so the sheet can say so instead
  /// of offering to add a second copy of it.
  final bool alreadySaved;

  /// Where the learner met this word, recorded rather than assumed.
  ///
  /// Defaults to the reader because that is where this sheet came from and
  /// every existing caller means it. It is a parameter and not a constant
  /// because a word tapped out of a conversation filed as "From books" is a
  /// plain lie to the one person who would ever read the label, and the whole
  /// reason [WordOrigins] exists is that the server used to guess this.
  final String origin;

  @override
  State<NfWordSheet> createState() => NfWordSheetState();
}

class NfWordSheetState extends State<NfWordSheet> {
  String? _definition;
  String? _error;
  bool _loading = true;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _lookUp();
  }

  Future<void> _lookUp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final Future<String> Function(String, String) lookUp =
          widget.lookUp ?? GroqService.explainWordInSentence;
      final String definition = await lookUp(widget.word, widget.sentence);
      if (!mounted) return;
      setState(() {
        _definition = definition;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Reading is the flow that runs out of quota: a learner meets an unknown
      // word every few lines and taps each one. Showing them "could not get the
      // meaning" for a daily limit tells them the app is broken when it is
      // doing exactly what it was told to, and showing it for a plan limit
      // hides the one thing they could do about it.
      final bool upgradeShown =
          await AiPaywallHandler.handleIfUpgradeRequired(context, e);
      if (!mounted) return;
      setState(() {
        _error = upgradeShown || e is! ApiQuotaExceededException
            ? AiErrorMessageFormatter.forError(e)
            : AiErrorMessageFormatter.forQuota(e);
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final String? meaning = _definition;
    if (meaning == null || meaning.trim().isEmpty) return;

    setState(() => _saving = true);
    try {
      final word = await widget.api.createWord(
        english: widget.word,
        turkish: meaning,
        addedDate: DateTime.now(),
        // Where this word came from, said rather than guessed. The server has
        // only ever inferred provenance — daily words if the meaning carries a
        // star, everything else "manual" — so a word tapped out of a novel has
        // been filed identically to one typed into the dictionary box.
        origin: widget.origin,
      );
      // The sentence is the point of learning a word here: a word kept with the
      // line it came from has somewhere to be reviewed. It is attached whether
      // or not the book has a translation for it — five of the six books have
      // none, and a word saved from those would otherwise arrive in the deck
      // with no context at all, which is most of what makes reading worth
      // learning from.
      await widget.api.addSentenceToWord(
        wordId: word.id,
        sentence: widget.sentence,
        translation: widget.sentenceTranslation,
        // Under the first meaning, not the word at large. The server splits a
        // definition on its commas, so "keyif alıyor, hoşuna gidiyor" arrives
        // as two senses, and a sentence attached to neither lands in the word
        // detail's "unassigned" pile: every meaning then says it has no
        // sentence, under a heading asking the learner to file this one. They
        // tapped a word to read it, not to do the deck's bookkeeping. Where
        // the senses are near-synonyms -- which is what a comma-joined gloss
        // usually is -- the first is as right as any, and a learner who
        // disagrees can move it in two taps.
        meaningId: word.meanings.isEmpty ? null : word.meanings.first.id,
      );
      widget.onSaved(word);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        // Named, not stringified. This rendered `e.toString()` in red under the
        // word, so keeping a word from a novel failed with "Exception: Kelime
        // kaydetme başarısız: 500" — Turkish, in front of every learner in
        // every language. The lookup path a few lines above already does this.
        _error = AiErrorMessageFormatter.forError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final NfTokens t = NfTokens.of(context);

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(NfSpace.s20),
        ),
      ),
      // viewInsets is the keyboard; viewPadding is the system navigation bar.
      // Only the first was accounted for, so on a device with on-screen
      // navigation the save button sat underneath it.
      padding: EdgeInsets.fromLTRB(
        NfSpace.s20,
        NfSpace.s16,
        NfSpace.s20,
        NfSpace.s20 +
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              width: 40,
              height: NfSpace.s4,
              decoration: BoxDecoration(
                color: t.border,
                borderRadius: BorderRadius.circular(NfSpace.s4),
              ),
            ),
          ),
          const SizedBox(height: NfSpace.s16),
          Text(
            widget.word,
            style: TextStyle(
              color: t.ink,
              fontSize: NfFont.s22,
              fontWeight: NfTokens.displayWeight,
            ),
          ),
          const SizedBox(height: NfSpace.s12),
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: NfSpace.s16),
              child: Center(child: CircularProgressIndicator(color: t.primary)),
            )
          else if (_error != null)
            Text(
              _error!,
              style: TextStyle(
                color: t.wrong,
                fontSize: NfFont.s14,
                fontWeight: NfTokens.bodyWeight,
              ),
            )
          else
            Text(
              _definition ?? '',
              style: TextStyle(
                color: t.inkMuted,
                fontSize: NfFont.s15,
                fontWeight: NfTokens.bodyWeight,
                height: 1.5,
              ),
            ),
          const SizedBox(height: NfSpace.s20),
          NfPrimaryButton(
            // Three different states, three different sentences. "Added" and
            // "already there" are not the same news: one is the result of the
            // tap, the other is why the tap does nothing.
            label: _saved
                ? context.tr('books.word.saved')
                : widget.alreadySaved
                    ? context.tr('books.word.already')
                    : context.tr('books.word.save'),
            busy: _saving,
            onPressed: (_loading ||
                    _saving ||
                    _saved ||
                    widget.alreadySaved ||
                    _definition == null)
                ? null
                : _save,
          ),
        ],
      ),
    );
  }
}

/// Opens the lookup sheet for [rawToken], read in the context of [sentence].
///
/// The three things every caller has to get right live here rather than at each
/// tap site: punctuation is stripped off the token before anything is asked
/// about it, the deck is checked for the word first so the sheet can say
/// "already there" instead of quietly filing a duplicate, and the saved word is
/// pushed into [AppStateProvider] so the Words screen shows it without a
/// restart. The reader had all three; a second caller writing them again would
/// have been a second chance to miss one.
Future<void> showNfWordLookup(
  BuildContext context, {
  required String rawToken,
  required String sentence,
  required ApiService api,
  String? sentenceTranslation,
  String origin = WordOrigins.reader,
}) async {
  final String word = SentenceTokens.word(rawToken);
  if (word.isEmpty) return;

  final bool alreadySaved = context
      .read<AppStateProvider>()
      .allWords
      .any((Word w) => WordFamily.matches(word, w.englishWord));

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: NfTokens.transparent,
    builder: (BuildContext sheetContext) => NfWordSheet(
      word: word,
      sentence: sentence,
      sentenceTranslation: sentenceTranslation,
      api: api,
      // Prose repeats itself, so meeting a word twice in one book is the
      // normal case rather than the odd one. Nothing on the server refuses a
      // second copy, so without this the deck quietly fills with the same
      // word over and over — and the learner reviews it twice as often for
      // no reason.
      alreadySaved: alreadySaved,
      origin: origin,
      // The server keeps the word either way; this is what puts it in front
      // of the learner. Without it the save succeeds, the sheet says so, and
      // the Words screen goes on showing the list it loaded at startup --
      // which reads, to the person who just saved it, exactly like the save
      // having failed.
      onSaved: (Word saved) =>
          context.read<AppStateProvider>().adoptServerWord(saved),
    ),
  );
}
