import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Whether the app and the activities it launches live in the same task.
///
/// MainActivity declared `android:taskAffinity=""` from the first commit. An
/// activity's default affinity is the applicationId, so every activity the Play
/// libraries contribute — SignInHubActivity from play-services-auth,
/// ProxyBillingActivity from billing — belonged to "com.VocabMaster" while
/// MainActivity belonged to nothing. Android could restore that other task by
/// itself and rebuild those activities without the Intent extras they were
/// handed, and each dereferences exactly that in onCreate.
///
/// Crashlytics showed both as NullPointerExceptions inside third-party
/// onCreate, on the two screens nobody can avoid: signing in, and paying.
/// Crash-free users went from 100% to 79.75% in two days.
///
/// A test on a manifest is unusual, and this one earns it: nothing else in the
/// project reads that file, the attribute is one word, and putting it back
/// would break sign-in and purchase for everyone while every Dart test stayed
/// green.
void main() {
  final File manifest =
      File('android/app/src/main/AndroidManifest.xml');

  test('the manifest is where the test thinks it is', () {
    expect(manifest.existsSync(), isTrue,
        reason: 'the path moved; this test is now checking nothing');
  });

  /// The manifest with its comments removed.
  ///
  /// The element carries a comment explaining why the attribute is absent, and
  /// that comment names the attribute. A plain substring search finds its own
  /// explanation and fails.
  String declarations() => manifest
      .readAsStringSync()
      .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

  test('MainActivity shares a task with the activities it starts', () {
    expect(
      declarations().contains('android:taskAffinity'),
      isFalse,
      reason: 'MainActivity must keep the default affinity - the applicationId '
          '- so that SignInHubActivity and ProxyBillingActivity are hosted in '
          'the same task instead of one Android can restore without them.',
    );
  });

  test('and is still the launcher entry, singleTop, exported', () {
    // The attributes around the one that was removed, so a future edit to this
    // element has to have meant it.
    final String xml = declarations();

    expect(xml, contains('android:name=".MainActivity"'));
    expect(xml, contains('android:launchMode="singleTop"'));
    expect(xml, contains('android:exported="true"'));
    expect(xml, contains('android.intent.category.LAUNCHER'));
  });
}
