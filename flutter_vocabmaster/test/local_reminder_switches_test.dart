import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocabmaster/services/local_reminder_service.dart';

/// The settings screen has always shown separate switches for streak and subscription
/// reminders, and sent them to the backend for push — but every local scheduler read the
/// single daily-reminder flag. Turning off streak reminders changed nothing about the
/// streak reminder arriving on the phone, which is the difference between a reminder and
/// being pestered.
///
/// These tests pin the property that makes the switches mean something: each reminder
/// answers to its own key, and no key answers for another.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = LocalReminderService();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Turning a switch off cancels whatever is already queued in the OS, which needs the
    // plugin channel; there is no implementation in a test binding.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (call) async => null,
    );
  });

  test('every reminder defaults to on', () async {
    // Opt-out, matching the daily reminder: the real gate is the OS permission prompt.
    expect(await service.isDailyReminderEnabled(), isTrue);
    expect(await service.isStreakGuardEnabled(), isTrue);
    expect(await service.isSubscriptionAlertEnabled(), isTrue);
    expect(await service.isWordRecallEnabled(), isTrue);
  });

  test('turning off the streak guard leaves the others alone', () async {
    await service.setReminderEnabled(LocalReminderService.streakGuardKey, false);

    expect(await service.isStreakGuardEnabled(), isFalse);
    expect(await service.isDailyReminderEnabled(), isTrue,
        reason: 'the daily practice nudge is a separate choice');
    expect(await service.isSubscriptionAlertEnabled(), isTrue);
    expect(await service.isWordRecallEnabled(), isTrue);
  });

  test('turning off word recall leaves the others alone', () async {
    await service.setReminderEnabled(LocalReminderService.wordRecallKey, false);

    expect(await service.isWordRecallEnabled(), isFalse);
    expect(await service.isStreakGuardEnabled(), isTrue);
    expect(await service.isSubscriptionAlertEnabled(), isTrue);
  });

  test('turning off subscription alerts leaves the others alone', () async {
    await service.setReminderEnabled(
        LocalReminderService.subscriptionAlertKey, false);

    expect(await service.isSubscriptionAlertEnabled(), isFalse);
    expect(await service.isStreakGuardEnabled(), isTrue);
    expect(await service.isWordRecallEnabled(), isTrue);
  });

  test('a switch turned off and on again ends up on', () async {
    await service.setReminderEnabled(LocalReminderService.wordRecallKey, false);
    expect(await service.isWordRecallEnabled(), isFalse);

    await service.setReminderEnabled(LocalReminderService.wordRecallKey, true);
    expect(await service.isWordRecallEnabled(), isTrue);
  });

  group('a reminder switched on is armed, not only stored', () {
    // The plugin calls, recorded, so these assert what reaches the OS rather than
    // what was written to preferences -- which is where the old behaviour looked fine.
    late List<String> calls;

    setUp(() {
      calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
    });

    String today() => DateTime.now().toIso8601String().split('T')[0];

    /// Arming runs after the switch is saved, not inside it -- so wait for the call
    /// to reach the plugin rather than expecting it the moment the save returns.
    Future<void> untilCalled(String method) async {
      for (int i = 0; i < 40 && !calls.contains(method); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    }

    test('turning the streak guard on schedules it', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'current_streak': 3,
        'last_activity_date': today(),
      });

      await service.setReminderEnabled(LocalReminderService.streakGuardKey, true);
      await untilCalled('zonedSchedule');

      expect(calls, contains('zonedSchedule'),
          reason: 'the switch said on and nothing was queued');
    });

    test('the streak guard does not answer to the daily switch', () async {
      // Behind the daily `if`, turning the evening reminder off silently took the
      // streak guard with it, despite the guard having -- and showing -- its own row.
      SharedPreferences.setMockInitialValues(<String, Object>{
        LocalReminderService.dailyReminderKey: false,
        'current_streak': 3,
        'last_activity_date': today(),
      });

      await service.refreshScheduledReminders();

      expect(calls, contains('zonedSchedule'),
          reason: 'the streak guard was not armed while the daily reminder was off');
    });
  });

  test('an explicit off survives, it is not re-defaulted to on', () async {
    // The defaults are opt-out, so the stored false has to win over the default true or
    // the user cannot actually turn anything off.
    SharedPreferences.setMockInitialValues({
      LocalReminderService.streakGuardKey: false,
      LocalReminderService.wordRecallKey: false,
    });

    expect(await service.isStreakGuardEnabled(), isFalse);
    expect(await service.isWordRecallEnabled(), isFalse);
  });
}
