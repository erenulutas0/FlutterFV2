import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabmaster/models/xp_sources.dart';

/// The XP ledger was storing translated prose.
///
/// Every award wrote a Turkish sentence — 'Telaffuz Pratiği', 'Mükemmel
/// Yazım', 'SRS Tekrar' — into `xp_history.source`, for every user, in seven
/// shipping languages. It has not hurt anyone yet only because the screen that
/// renders that column, `lib/screens/xp_history_page.dart`, hangs off
/// `LegacyMainScreen` and nothing reaches it any more. That is the trap: the
/// day somebody ports it, a Portuguese learner opens their history and reads
/// Turkish, and the rows behind them cannot be fixed. A translation pass can
/// reach code. It cannot reach a row already on a phone.
///
/// So the ledger stores a key and the language is chosen at display time.
/// These tests pin the two halves of that: that the keys are stable, and that
/// the rows written under the old scheme still come back out readable.
void main() {
  group('the keys are keys', () {
    test('every one is lowercase words joined by underscores', () {
      // Not a style preference. These are wire values in a database column: a
      // key that reads like prose is one refactor away from being edited like
      // prose, and every row written under the old spelling is orphaned when
      // that happens.
      final RegExp shape = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');

      for (final String key in XpSources.all) {
        expect(shape.hasMatch(key), isTrue, reason: '"$key" is not a key');
      }
    });

    test('and the set of them is exactly this, forever', () {
      // Renaming any of these silently splits one activity into two names in
      // the ledger: rows written before the rename keep the old value, and
      // nothing maps them back. Adding a key is fine — this list grows.
      // Changing or removing one is a migration, and this test is where you
      // find that out.
      expect(XpSources.all, <String>{
        'pronunciation_practice',
        'pronunciation_perfect',
        'speaking_practice',
        'reading_practice',
        'reading_perfect',
        'writing_practice',
        'writing_perfect',
        'translation_practice',
        'translation_perfect',
        'sentence_added',
        'practice_sentence_added',
        'daily_word',
        'quick_dictionary',
        'srs_review',
      });
    });
  });

  group('nothing writes prose to the ledger any more', () {
    /// Empty, and it has to stay that way.
    ///
    /// It briefly held `nf_tutor_page.dart`, which was being edited elsewhere
    /// while this test was written and still wrote `source: 'Konuşma Pratiği'`.
    /// That line now writes the key, so the exemption is gone. The set is kept
    /// rather than deleted because the next person who cannot edit a file will
    /// reach for exactly this, and an empty set that the test below holds to
    /// zero is a cheaper argument than a comment asking them not to.
    const Set<String> ownedElsewhere = <String>{};

    test('every XP award names its reason with a key, not a sentence', () {
      // A grep, because nothing else can catch this. A prose `source:` compiles,
      // analyses clean, and looks exactly like working code — it only shows up
      // as somebody else's language in somebody else's history, months later,
      // in rows that can no longer be changed.
      //
      // Scanning beats asserting on the constant set here: the constants can be
      // perfect while a new call site goes on passing a literal beside them,
      // which is precisely how this defect got in. Only calls that reach
      // `xp_history` are read — `source:` also names analytics dimensions and
      // word provenance, and those are not ledger rows.
      final RegExp award =
          RegExp(r'\b(addXPForAction|addXpHistory|addCustomXP|addXP)\s*\(');
      final RegExp labelled = RegExp(r"\b(?:source|reason):\s*'([^']*)'");
      final RegExp key = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');

      final List<String> offenders = <String>[];

      for (final FileSystemEntity entity
          in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final String path = entity.path.replaceAll('\\', '/');
        if (ownedElsewhere.contains(path)) continue;

        final String text = entity.readAsStringSync();
        for (final RegExpMatch call in award.allMatches(text)) {
          // The argument list, bounded by the end of the statement so a match
          // cannot wander into the next call.
          final int start = call.end;
          final int stop = text.indexOf(');', start);
          final String args =
              text.substring(start, stop == -1 ? text.length : stop);

          for (final RegExpMatch arg in labelled.allMatches(args)) {
            final String value = arg.group(1)!;
            if (value.isEmpty || key.hasMatch(value)) continue;
            final int line = '\n'.allMatches(text.substring(0, start)).length + 1;
            offenders.add('$path:~$line: ${arg.group(0)}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'These write a human sentence into xp_history, where it is '
            'frozen in one language for every user who earns it. Use an '
            'XpSources constant and translate at display time.\n'
            '${offenders.join('\n')}',
      );
    });

    test('and nothing is exempt from it', () {
      // The scan above skips whatever is listed here, so an entry is a hole in
      // the guard. There are none; adding one is a decision that should have to
      // be made deliberately, in a diff, rather than by appending a path.
      for (final String path in ownedElsewhere) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
      expect(ownedElsewhere, isEmpty);
    });
  });

  group('rows written before this still read', () {
    test('a legacy Turkish value comes back exactly as it was written', () {
      // The whole reason old rows are survivable. Nothing recorded which event
      // produced them, so the sentence is the only thing they carry — mapping
      // it to anything else, or to nothing, would destroy the row's meaning.
      // Passed through untouched, it still reads to the person who earned it.
      for (final String legacy in <String>[
        'Telaffuz Pratiği',
        'Mükemmel Telaffuz',
        'Okuma Pratiği',
        'Mükemmel Okuma Skoru',
        'Çeviri Pratiği',
        'Mükemmel Çeviri',
        'Konuşma Pratiği',
        'Cümle Ekleme',
        'Yazma Pratiği',
        'Mükemmel Yazım',
        'SRS Tekrar',
        'Günün Kelimesi',
        'Hızlı Sözlük',
        'Pratik Cümlesi',
      ]) {
        expect(XpSources.labelFor(legacy), legacy, reason: legacy);
      }
    });

    test('a value from some other build is prose until proven otherwise', () {
      // Anything unrecognised is assumed already readable, which is the safe
      // guess: showing a stranger's sentence is a smaller failure than blanking
      // a row somebody earned.
      expect(XpSources.labelFor('Kelime silindi: rabbit'), 'Kelime silindi: rabbit');
      expect(XpSources.labelFor('custom'), 'custom');
    });

    test('a known key shows nothing rather than showing itself', () {
      // There is no translation for these yet, on purpose — see XpSources. A
      // gap is honest; `pronunciation_practice` rendered as a label is not.
      for (final String key in XpSources.all) {
        expect(XpSources.labelFor(key), isNull, reason: key);
      }
    });

    test('an empty or missing source is not a label', () {
      expect(XpSources.labelFor(null), isNull);
      expect(XpSources.labelFor(''), isNull);
    });
  });
}
