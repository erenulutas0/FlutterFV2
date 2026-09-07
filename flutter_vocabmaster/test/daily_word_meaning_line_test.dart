import 'package:flutter_test/flutter_test.dart';
import 'package:vocabmaster/frontend_newest/screens/nf_today_page.dart';

/// The one line of type under each daily word.
///
/// Seen on a device: rows reading "festival / festival". The server's
/// `translation` field is a gloss in the reader's own language, and for a
/// reader whose language IS English that gloss can be the word itself, while
/// in Spanish and Portuguese the cognate is spelled the same. Either way the
/// line costs a glance and teaches nothing.
void main() {
  test('a real translation is what the reader gets', () {
    expect(
      dailyWordMeaning(<String, dynamic>{
        'word': 'celebrate',
        'translation': 'kutlamak',
        'definition': 'to mark an occasion',
      }),
      'kutlamak',
    );
  });

  test('a translation that is just the word gives way to the definition', () {
    expect(
      dailyWordMeaning(<String, dynamic>{
        'word': 'festival',
        'translation': 'festival',
        'definition': 'a public celebration',
      }),
      'a public celebration',
    );
  });

  test('case and spacing do not rescue an empty repetition', () {
    expect(
      dailyWordMeaning(<String, dynamic>{
        'word': 'Tradition',
        'translation': '  tradition ',
        'definition': 'a custom passed down',
      }),
      'a custom passed down',
    );
  });

  test('no translation at all falls back to the definition', () {
    // What a non-Turkish reader gets from the canned offline list, where the
    // Turkish gloss is dropped rather than shown.
    expect(
      dailyWordMeaning(<String, dynamic>{
        'word': 'resilient',
        'definition': 'able to recover quickly',
      }),
      'able to recover quickly',
    );
  });

  test('with neither, the row says nothing rather than something wrong', () {
    expect(dailyWordMeaning(<String, dynamic>{'word': 'insight'}), '');
  });

  test('a repeated word with no definition prints no line at all', () {
    // The card hides the line when it is empty, and a blank under the word is
    // quieter than the word restated as its own meaning.
    expect(
      dailyWordMeaning(<String, dynamic>{
        'word': 'festival',
        'translation': 'festival',
      }),
      '',
    );
  });
}
