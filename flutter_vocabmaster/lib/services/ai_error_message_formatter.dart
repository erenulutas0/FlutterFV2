import 'dart:ui';

import '../l10n/app_localizations.dart';
import 'api_service.dart';
import 'locale_text_service.dart';
import 'network_failure.dart';

/// What to tell a learner when an AI request fails.
///
/// Reads the same seven-language key table as the rest of the app. It used to
/// call `LocaleTextService.pick(tr, en)` in sixteen places, which meant every
/// screen in the app was translated into seven languages and the one moment
/// something went wrong switched to English — a Spanish learner hitting their
/// quota was told "Your daily AI quota is exhausted" in the middle of an
/// otherwise Spanish app. Failure is exactly when a person is least able to
/// read a second language.
///
/// Static, and without a BuildContext, because it is called from services and
/// from catch blocks that have none. [_t] resolves the locale the same way
/// LocaleTextService does, from the stored app language.
class AiErrorMessageFormatter {
  /// One localised string, in whatever language the app is currently set to.
  static String _t(String key) =>
      AppLocalizations(Locale(LocaleTextService.appLanguageCode)).t(key);

  static String forQuota(ApiQuotaExceededException e) {
    final reason = (e.reason ?? '').trim().toLowerCase();
    final buffer = StringBuffer();

    if (reason == 'abuse-ban' || (e.banLevel ?? 0) > 0) {
      buffer.write(_t('ai.err.abuseBan'));
    } else if (reason == 'daily-token-quota') {
      buffer.write(_t('ai.err.dailyTokens'));
    } else if (reason == 'daily-quota' ||
        reason == 'user-burst' ||
        reason == 'ip-burst') {
      buffer.write(_t('ai.err.requestLimit'));
    } else if (reason == 'non-paid-device-token-quota') {
      // A ceiling shared by every free account on this phone, not the
      // learner's own allowance. The server answers both of these with the
      // Turkish sentence "your daily AI quota is finished", which was printed
      // verbatim by the fall-through below -- wrong in two ways at once: in a
      // language the reader may not have, and about a limit that is not
      // theirs. Someone who has asked for nothing all day would read that they
      // had used everything up.
      buffer.write(_t('ai.err.sharedDeviceQuota'));
    } else if (reason == 'non-paid-ip-token-quota') {
      // The same ceiling, counted per network: a classroom, an office or a
      // household on one connection share it.
      buffer.write(_t('ai.err.sharedNetworkQuota'));
    } else if (reason == 'redis-fail-closed') {
      // Not the learner's allowance at all: the server reports this case with
      // a message claiming the daily quota is finished, and saying so would be
      // blaming somebody for our own outage.
      buffer.write(_t('ai.err.protectionMode'));
    } else {
      buffer.write(
        e.message.isNotEmpty ? e.message : _t('ai.err.quotaGeneric'),
      );
    }

    if (e.retryAfterSeconds != null && e.retryAfterSeconds! > 0) {
      buffer.write(
        '\n${_t('ai.err.retryAfter')}: ${_formatDuration(e.retryAfterSeconds!)}.',
      );
    }

    if (e.banLevel != null && e.banLevel! > 0) {
      buffer.write('\n${_t('ai.err.banLevel')}: ${e.banLevel}.');
    }

    if (e.nextBanSeconds != null && e.nextBanSeconds! > 0) {
      buffer.write(
        '\n${_t('ai.err.nextWait')}: ${_formatDuration(e.nextBanSeconds!)}.',
      );
    }

    if (reason == 'daily-token-quota' &&
        e.tokensUsed != null &&
        e.tokenLimit != null) {
      buffer.write(
        '\n${_t('ai.err.dailyUsage')}: ${e.tokensUsed}/${e.tokenLimit} token.',
      );
    }

    return buffer.toString();
  }

  static String forError(Object e, {String? fallback}) =>
      _specificFor(e) ?? fallback ?? _t('ai.err.generic');

  /// Fills a `{error}`-style template without ever putting a stack trace in it.
  ///
  /// Nine screens built their failure line as `template.replaceAll('{error}',
  /// '$e')`, so the sentence around it was translated and the thing inside it
  /// was a Dart exception: offline, a learner opening the paywall read
  /// "Payment failed: SocketException: Failed host lookup: 'api.klioai.app'
  /// (OS Error: No address associated with hostname, errno = 7)".
  ///
  /// When the failure is one this class can name, the name goes in. When it is
  /// not, the placeholder and whatever separator introduced it are removed
  /// rather than filled with something worse -- "Could not load the quiz"
  /// says everything true that we know.
  static String intoTemplate(
    String template,
    Object e, {
    String placeholder = '{error}',
  }) {
    final String? specific = _specificFor(e);
    if (specific != null && specific.isNotEmpty) {
      return template.replaceAll(placeholder, specific);
    }
    return template
        .replaceAll(
          RegExp('[:\\-\u2013\u2014]?\\s*' + RegExp.escape(placeholder)),
          '',
        )
        .trim();
  }

  /// The message for a failure this class recognises, or null.
  ///
  /// The network cases are here rather than left to the caller because
  /// [intoTemplate] has nothing useful to say without them. Every template
  /// this fills reads "<something>: {error}", so an unrecognised failure
  /// strips down to a bare label -- offline, the paywall's restore button
  /// said exactly "Hata" and nothing else, which is no more use to a learner
  /// than the stack trace it replaced.
  static String? _specificFor(Object e) {
    if (e is ApiQuotaExceededException) return forQuota(e);
    if (e is ApiUpgradeRequiredException) return forUpgrade(e);
    if (e is ApiUnauthorizedException) return forUnauthorized(e);
    if (e is ApiAiServiceException) return _t('ai.err.aiService');
    if (looksOffline(e)) return _t('common.err.offline');
    if (looksTimedOut(e)) return _t('common.err.timeout');
    return null;
  }

  /// What to tell someone whose session is no longer accepted.
  ///
  /// Never [ApiUnauthorizedException.message]. That field carries whatever the
  /// server or the client happened to write: Spring's entry point answers an
  /// expired JWT with `{"error":"Unauthorized"}`, so the app showed a red
  /// snackbar reading the single English word "Unauthorized" and then signed
  /// the learner out — and the client's own missing-token check threw a
  /// Turkish sentence that was shown just as literally. Neither is a sentence
  /// anyone should read, and neither is in the reader's language.
  ///
  /// The 401 that means "pay for this" is told apart by
  /// `AiPaywallHandler.shouldOpenSubscriptionForUnauthorized`, which reads the
  /// reason rather than the prose; everything else is an ended session, and
  /// there is only one useful thing to say about that.
  static String forUnauthorized(ApiUnauthorizedException e) =>
      _t('common.err.sessionExpired');

  /// The line for a 401 that the classifier read as a billing refusal rather
  /// than an ended session, so the same key answers here as for a plain 403.
  static String forSubscriptionRequired() => _t('ai.err.subscriptionRequired');

  static String forUpgrade(ApiUpgradeRequiredException e) {
    final reason = (e.reason ?? '').trim().toLowerCase();
    if (reason == 'ai-access-disabled') {
      return _t('ai.err.trialEnded');
    }
    return e.message.isNotEmpty
        ? e.message
        : _t('ai.err.subscriptionRequired');
  }

  static String _formatDuration(int totalSeconds) {
    final safe = totalSeconds < 1 ? 1 : totalSeconds;
    final minutes = safe ~/ 60;
    final seconds = safe % 60;

    if (minutes == 0) {
      return _t('ai.err.seconds').replaceAll('{n}', '$seconds');
    }
    if (seconds == 0) {
      return _t('ai.err.minutes').replaceAll('{n}', '$minutes');
    }
    return _t('ai.err.minutesSeconds')
        .replaceAll('{m}', '$minutes')
        .replaceAll('{s}', '$seconds');
  }
}
