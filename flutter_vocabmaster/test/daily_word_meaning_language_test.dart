import 'package:flutter_test/flutter_test.dart';
import 'package:vocabmaster/services/locale_text_service.dart';
import 'dart:ui';

/// Which language the server is asked to write the daily words in.
///
/// The five words were generated once a day against the default profile and
/// served to everyone, so a learner who switched the app to English still read
/// the English word with its Turkish meaning underneath. The request now
/// carries the language the app is being read in, and this pins the mapping
/// from the app's locale codes to the names the backend keys its cache by --
/// a wrong name there is not an error, it is a silent fall back to Turkish.
void main() {
  test('every shipped locale maps to a language the server supports', () {
    // The names are LearningLanguageProfile.SUPPORTED_SOURCE_LANGUAGES.
    const Map<String, String> expected = <String, String>{
      'tr': 'Turkish',
      'en': 'English',
      'de': 'German',
      'fr': 'French',
      'it': 'Italian',
      'pt': 'Portuguese',
      'es': 'Spanish',
    };

    expected.forEach((String code, String name) {
      LocaleTextService.setAppLocale(Locale(code));
      expect(LocaleTextService.nativeLanguageName, name, reason: 'for $code');
    });
  });

  test('an unknown locale asks for English, not the founder\'s language', () {
    // A device set to a language the app does not ship. Turkish here would put
    // Turkish meanings in front of someone who has never seen the language.
    LocaleTextService.setAppLocale(const Locale('ja'));

    expect(LocaleTextService.nativeLanguageName, 'English');
  });

  test('region and case do not change the answer', () {
    LocaleTextService.setAppLocale(const Locale('PT', 'BR'));

    expect(LocaleTextService.nativeLanguageName, 'Portuguese');
  });
}
