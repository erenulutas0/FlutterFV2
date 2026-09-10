import 'package:flutter_test/flutter_test.dart';
import 'package:vocabmaster/models/word.dart';
import 'package:vocabmaster/providers/app_state_provider.dart';

/// The date written beside a streak that was rebuilt from word dates.
///
/// On startup, a streak whose last recorded day is too old is rebuilt from the dates
/// words were learned on. That rebuild wrote the count and never the date, and the
/// streak guard reads the date: with none it cancels itself. A phone whose words all
/// came from the tutor or the reader showed a one-day streak on screen and never once
/// armed the reminder that exists to protect it. The date now comes from the same walk
/// as the count, and these pin which day that is.
void main() {
  final DateTime now = DateTime(2026, 9, 10, 15);

  Word learnedOn(DateTime day, int id) => Word(
        id: id,
        englishWord: 'word$id',
        turkishMeaning: 'kelime',
        learnedDate: day,
        difficulty: 'easy',
      );

  test('a word learned today makes today the last day', () {
    expect(
      AppStateProvider.lastStreakDayFromWords(<Word>[
        learnedOn(DateTime(2026, 9, 9), 1),
        learnedOn(DateTime(2026, 9, 10, 9), 2),
      ], now: now),
      '2026-09-10',
    );
  });

  test('a streak that ended yesterday is still alive, and yesterday is its day', () {
    // The same grace _calculateStreakFromWords gives: nothing yet today is not a
    // broken streak until today is over.
    expect(
      AppStateProvider.lastStreakDayFromWords(<Word>[
        learnedOn(DateTime(2026, 9, 9, 20), 1),
      ], now: now),
      '2026-09-09',
    );
  });

  test('an older last word means there is no streak to date', () {
    expect(
      AppStateProvider.lastStreakDayFromWords(<Word>[
        learnedOn(DateTime(2026, 9, 7), 1),
      ], now: now),
      isNull,
    );
  });

  group('which date startup restores', () {
    String? restore({
      String? recorded,
      int streak = 1,
      bool rebuilt = false,
      String? fromWords = '2026-09-10',
    }) =>
        AppStateProvider.activityDateToRestore(
          recorded: recorded,
          streak: streak,
          rebuiltFromWords: rebuilt,
          lastDayFromWords: fromWords,
        );

    test('a count with no date gets one -- the case the first fix missed', () {
      // current_streak 1, no last_activity_date, found on the phone running 472. The
      // broken-streak check needs a date and the rebuild needs a zero count, so
      // neither ran and the streak guard stayed cancelled.
      expect(restore(recorded: null), '2026-09-10');
      expect(restore(recorded: ''), '2026-09-10');
    });

    test('a rebuilt count replaces the stale date that broke the old one', () {
      expect(restore(recorded: '2026-08-20', rebuilt: true), '2026-09-10');
    });

    test('a real date on a streak that was not rebuilt is left alone', () {
      // It came from actual activity; word dates have no better claim to it.
      expect(restore(recorded: '2026-09-09'), isNull);
    });

    test('nothing is written when there is nothing to date', () {
      expect(restore(recorded: null, streak: 0), isNull);
      expect(restore(recorded: null, fromWords: null), isNull);
      expect(restore(recorded: '2026-09-10', rebuilt: true), isNull,
          reason: 'rewriting the same date re-arms the guard for nothing');
    });
  });

  test('no words, no date', () {
    expect(AppStateProvider.lastStreakDayFromWords(const <Word>[], now: now), isNull);
  });
}
