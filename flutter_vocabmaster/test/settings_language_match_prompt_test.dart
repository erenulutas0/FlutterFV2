import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabmaster/l10n/app_localizations.dart';
import 'package:vocabmaster/services/learning_language_service.dart';

/// The question asked when the app's language and the tutor's stop agreeing.
///
/// There are two language settings. Switching the app to English left the AI
/// still explaining in Turkish, because the learning profile was written once
/// and never moved; nothing on screen said the second setting existed, so the
/// app just looked half-translated. Settings now offers to move it.
///
/// What can go wrong is not the dialog but its copy and its trigger: a locale
/// that implies a language the server does not accept would offer a switch
/// that fails, and an unfilled placeholder would ship the literal "{new}" to a
/// learner. Both are checked here, in every language the app ships.
void main() {
  const List<String> codes = <String>['en', 'tr', 'de', 'fr', 'it', 'pt', 'es'];

  test('every app language implies one the tutor can actually be set to', () {
    for (final String code in codes) {
      final String implied =
          LearningLanguageService.normalizeSupported(code, 'English');
      expect(
        LearningLanguageService.supportedSourceLanguages,
        contains(implied),
        reason: 'switching the app to $code would offer "$implied", '
            'which the profile would reject',
      );
    }
  });

  test('the prompt is only worth asking when the two disagree', () {
    // The rule the settings page applies before opening the dialog.
    bool wouldAsk(String appCode, String storedSourceLanguage) =>
        LearningLanguageService.normalizeSupported(appCode, 'English') !=
        storedSourceLanguage;

    // The case that started this: app moved to English, profile left behind.
    expect(wouldAsk('en', 'Turkish'), isTrue);
    expect(wouldAsk('de', 'Turkish'), isTrue);
    expect(wouldAsk('es', 'English'), isTrue);

    // Already agreeing. Asking here would be a dialog with nothing behind it,
    // shown to every learner who ever reopens the language picker.
    for (final String code in codes) {
      final String implied =
          LearningLanguageService.normalizeSupported(code, 'English');
      expect(
        wouldAsk(code, implied),
        isFalse,
        reason: '$code already explains in $implied',
      );
    }
  });

  test('both names are filled in, in every language', () {
    const List<String> keys = <String>[
      'settings.learning.matchPrompt.title',
      'settings.learning.matchPrompt.body',
      'settings.learning.matchPrompt.confirm',
      'settings.learning.matchPrompt.keep',
    ];

    for (final String code in codes) {
      final AppLocalizations l10n = AppLocalizations(Locale(code));
      for (final String key in keys) {
        final String raw = l10n.t(key);
        expect(raw, isNotEmpty, reason: '$key missing for $code');
        // The key itself coming back means the locale has no entry.
        expect(raw, isNot(key), reason: '$key untranslated for $code');

        final String filled = raw
            .replaceAll('{new}', 'English')
            .replaceAll('{current}', 'Turkish');
        expect(
          filled.contains('{'),
          isFalse,
          reason: '$key for $code still has an unfilled placeholder: $raw',
        );
      }
    }
  });

  test('the body names both languages, or it does not explain anything', () {
    for (final String code in codes) {
      final String body =
          AppLocalizations(Locale(code)).t('settings.learning.matchPrompt.body');

      expect(body, contains('{new}'), reason: 'for $code');
      expect(body, contains('{current}'), reason: 'for $code');
    }
  });
}
