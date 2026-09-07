import 'dart:ui';

class LocaleTextService {
  const LocaleTextService._();

  static String? _appLanguageCode;

  static void setAppLocale(Locale locale) {
    _appLanguageCode = locale.languageCode.toLowerCase();
  }

  /// The language the interface is being read in, lowercased.
  ///
  /// Falls back to the device's, which is what the app itself does before a
  /// choice has been stored.
  static String get appLanguageCode =>
      _appLanguageCode ??
      PlatformDispatcher.instance.locale.languageCode.toLowerCase();

  static bool get isTurkish => appLanguageCode == 'tr';

  static String pick(String tr, String en) => isTurkish ? tr : en;

  /// What the server calls this language.
  ///
  /// The backend keys content it writes for the learner — word meanings, and
  /// the AI's explanations — by a language *name*, not a code. The daily words
  /// were generated once a day against the default profile and served to
  /// everyone, so a learner who switched the app to English still read the
  /// meanings in Turkish. Sending this along says which language the reader is
  /// actually in.
  ///
  /// English is the fallback rather than Turkish: an unknown code means we do
  /// not know who is reading, and the app's own second language is a safer
  /// guess than the founder's first.
  static String get nativeLanguageName => switch (appLanguageCode) {
        'tr' => 'Turkish',
        'de' => 'German',
        'fr' => 'French',
        'it' => 'Italian',
        'pt' => 'Portuguese',
        'es' => 'Spanish',
        'id' => 'Indonesian',
        _ => 'English',
      };
}
