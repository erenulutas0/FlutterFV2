import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The rules that keep local reminders working in the only build learners have.
///
/// A device on the shipped bundle threw this on every reminder call:
///
///   FlutterLocalNotificationsPlugin.cancel -> removeNotificationFromCache
///   -> loadScheduledNotifications
///   -> IllegalStateException: TypeToken must be created with a type argument;
///      When using code shrinkers (ProGuard, R8, ...) make sure that generic
///      signatures are preserved.
///
/// The plugin keeps its scheduled notifications as JSON and reads them back
/// with `new TypeToken<ArrayList<NotificationDetails>>() {}`. Gson recovers the
/// element type from that anonymous subclass's generic superclass; R8 merges
/// the subclass away and the type goes with it. Flutter's Gradle plugin turns
/// minification on for `release` and leaves it off everywhere else, so this
/// failed on every build a learner could install and no build anyone develops
/// against.
///
/// What it cost was not only the reminder. Reading the AI entitlement scheduled
/// the trial-expiry reminder in the same try block, ahead of storing what the
/// server had just said about the learner's plan — so a subscriber's Pro state
/// never reached the client, and the app went on showing the stale one it had
/// cached. That is the second half of this file.
///
/// Testing a build file is unusual and this earns it twice over: nothing else
/// in the project reads either of these, both failures are silent, and both are
/// invisible to every other test in this suite because none of them run through
/// R8.
void main() {
  group('the release build keeps what Gson reflects on', () {
    final File rules = File('android/app/proguard-rules.pro');

    test('the rules file is where Flutter looks for it', () {
      // FlutterPlugin.kt adds android/app/proguard-rules.pro to the release
      // build only when the file exists, and says nothing when it does not.
      // Renaming or moving it disables every rule below without a warning.
      expect(rules.existsSync(), isTrue,
          reason: 'android/app/proguard-rules.pro is gone; R8 is running on '
              'release with none of the keeps this project needs');
    });

    test('anonymous TypeToken subclasses survive R8', () {
      // The one rule the crash was actually about. Without it Gson is handed a
      // raw TypeToken and cannot say what the list holds.
      expect(rules.readAsStringSync(),
          contains('-keep class * extends com.google.gson.reflect.TypeToken'));
    });

    test('the notifications plugin is kept whole', () {
      // Its cache, its receivers and the model classes it serialises are all
      // reached reflectively or from the manifest, which R8 cannot see through.
      expect(rules.readAsStringSync(),
          contains('-keep class com.dexterous.** { *; }'));
    });

    test('generic signatures are preserved', () {
      // Already true by way of proguard-android-optimize, and stated here so
      // the rule does not depend on which default file a future AGP picks.
      expect(rules.readAsStringSync(), contains('-keepattributes Signature'));
    });
  });

  group('nothing after the quota read can undo it', () {
    final String source =
        File('lib/providers/app_state_provider.dart').readAsStringSync();

    /// The body of the entitlement merge, from the quota read to its catch.
    String snapshotBody() {
      final int start = source.indexOf('_mergeAiEntitlementSnapshot');
      expect(start, greaterThan(-1),
          reason: 'the entitlement merge was renamed; this test is out of date');
      final int end = source.indexOf('_recordTrialBookkeeping(Map', start);
      expect(end, greaterThan(start),
          reason: 'the bookkeeping helper is gone; if its work moved back into '
              'the merge, that is exactly what this test exists to catch');
      return source.substring(start, end);
    }

    test('the plan is stored before the reminder is scheduled', () {
      // This is the ordering, asserted as text, which is a weaker test than
      // running the method and the honest one available: the reminder service
      // is constructed inline and the analytics calls are static, so there is
      // nothing here to substitute. It cannot prove the merge works. It does
      // stop the one edit that broke it -- moving a side effect back above the
      // line that stores the plan -- which is how this would be lost again,
      // silently, with all 800 other tests still green.
      final String body = snapshotBody();

      final int stored = body.indexOf('_authService.updateUser(merged)');
      final int bookkeeping = body.indexOf('_recordTrialBookkeeping(quota)');

      expect(stored, greaterThan(-1),
          reason: 'the merged entitlement is no longer stored at all');
      expect(bookkeeping, greaterThan(stored),
          reason: 'a reminder or an analytics call runs before the plan is '
              'stored; a throw in either loses the plan, which is what a '
              'subscriber sees as their subscription lapsing');
    });

    test('the bookkeeping swallows its own failures', () {
      // Its two calls are worth making and neither is worth an entitlement.
      final int helper = source.indexOf('_recordTrialBookkeeping(Map');
      final String body = source.substring(helper);

      expect(body.indexOf('try {'), lessThan(body.indexOf('logTrialSnapshot')),
          reason: 'the analytics call is outside the guard');
      expect(
          body.indexOf('scheduleTrialExpiryReminder'),
          lessThan(body.indexOf('} catch (e) {')),
          reason: 'the reminder is outside the guard');
    });
  });
}
