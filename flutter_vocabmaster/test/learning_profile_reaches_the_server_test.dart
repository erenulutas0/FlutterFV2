import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocabmaster/frontend_newest/nf_frontend_preference.dart';
import 'package:vocabmaster/frontend_newest/screens/nf_settings_page.dart';
import 'package:vocabmaster/frontend_newest/screens/nf_today_page.dart';
import 'package:vocabmaster/l10n/app_localizations.dart';
import 'package:vocabmaster/models/language_profile.dart';
import 'package:vocabmaster/providers/app_state_provider.dart';
import 'package:vocabmaster/providers/language_provider.dart';
import 'package:vocabmaster/providers/learning_language_provider.dart';
import 'package:vocabmaster/services/api_service.dart';
import 'package:vocabmaster/services/auth_service.dart';
import 'package:vocabmaster/services/learning_language_service.dart';
import 'package:vocabmaster/services/locale_text_service.dart';

/// The level a learner chooses is the level the server is told.
///
/// Onboarding asks for it and stored it on the device and nowhere else:
/// `createLanguageProfile` and `updateLanguageProfile` had been sitting in
/// `api_service.dart` with no callers anywhere in the app. The only row the
/// server ever held was the one registration writes — a hardcoded Turkish →
/// English, B1 (`LanguageProfile.defaultEnglishProfile`).
///
/// The home screen reads its level. So an absolute beginner who picked A1 was
/// greeted, on the first screen after signing in, with "English · B1", while
/// Settings two taps away said A1. One fact, two screens, and the wrong one
/// facing someone who has just arrived from a TikTok video and is deciding
/// whether this app is for them.
///
/// The AI content was never wrong — the level travels in every request body
/// (`LearningLanguageService.currentProfile`) and the server prefers it over
/// the row. This was a lie about the learner, not about the lessons, told in
/// the one place where being told you are further along than you are is
/// discouraging rather than flattering.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String baseUrl = 'http://localhost:8080/api';
  const int profileId = 7;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    // The service keeps its answers in statics, so one test's learner would
    // otherwise still be answering in the next.
    LearningLanguageService.resetAnswers();
    LocaleTextService.setAppLocale(const Locale('en'));
    await AuthService().saveSession('test_token', 'test_refresh', {
      'id': 4,
      'userId': 4,
      'email': 'beginner@test.local',
      'displayName': 'Eren',
      'userTag': '#00004',
      'role': 'USER',
    });
  });

  /// The row registration writes: nobody chose any of this.
  Map<String, dynamic> signupRow({
    String level = 'B1',
    String? goal,
  }) =>
      <String, dynamic>{
        'id': profileId,
        'sourceLanguage': 'Turkish',
        'targetLanguage': 'English',
        'level': level,
        'learningGoal': goal,
        'isActive': true,
        'createdAt': '2026-09-01T10:00:00',
      };

  /// Answers the two calls this is about and records every PUT body.
  ///
  /// [putStatus] of 500 is the flaky network the learner must not notice.
  MockClient serverHolding(
    Map<String, dynamic> row,
    List<Map<String, dynamic>> puts, {
    int putStatus = 200,
  }) {
    return MockClient((http.Request request) async {
      final String path = request.url.path;
      if (request.method == 'GET' && path.endsWith('/language-profiles')) {
        return http.Response(json.encode(<Object>[row]), 200);
      }
      if (request.method == 'PUT' &&
          path.endsWith('/language-profiles/$profileId')) {
        final Map<String, dynamic> body =
            json.decode(request.body) as Map<String, dynamic>;
        puts.add(body);
        if (putStatus != 200) {
          return http.Response('{"error":"nope"}', putStatus);
        }
        return http.Response(
          json.encode(<String, dynamic>{
            ...row,
            if (body['level'] != null) 'level': body['level'],
            if (body['learningGoal'] != null)
              'learningGoal': body['learningGoal'],
          }),
          200,
        );
      }
      return http.Response('{}', 404);
    });
  }

  AppStateProvider appStateTalkingTo(http.Client client) {
    final AppStateProvider appState = AppStateProvider();
    appState.setApiServiceForTesting(
      ApiService(client: client, baseUrl: baseUrl),
    );
    return appState;
  }

  /// What onboarding leaves behind: three answers on the device, and no
  /// account yet to send them to.
  Future<LearningLanguageProvider> learnerWhoAnswered({
    required String level,
    String goal = 'Travel',
    String source = 'Turkish',
  }) async {
    final LearningLanguageProvider provider = LearningLanguageProvider();
    await provider.initialize();
    await provider.selectSourceLanguage(source);
    await provider.selectEnglishLevel(level);
    await provider.selectLearningGoal(goal);
    return provider;
  }

  test('the level chosen in onboarding is the level the server is told',
      () async {
    // Onboarding runs before there is an account, so the push cannot happen
    // there — there is no id to PUT to. This is the first moment it can: the
    // profile list has just arrived, so the row and its id both exist.
    await learnerWhoAnswered(level: 'A1');
    final List<Map<String, dynamic>> puts = <Map<String, dynamic>>[];
    final AppStateProvider appState =
        appStateTalkingTo(serverHolding(signupRow(), puts));

    await appState.loadLanguageProfiles();

    expect(puts, hasLength(1),
        reason: 'nothing ever called updateLanguageProfile before this');
    expect(puts.single['level'], 'A1');
    expect(puts.single['learningGoal'], 'Travel');
    expect(appState.activeProfile?.level, 'A1',
        reason: 'the row the rest of the app reads has to be corrected too');
  });

  test('the corrected row is the one the home screen would read', () async {
    // The whole point of pushing rather than only re-reading: everything that
    // consults the profile — not just the chip — now sees A1.
    await learnerWhoAnswered(level: 'A2');
    final AppStateProvider appState = appStateTalkingTo(
      serverHolding(signupRow(), <Map<String, dynamic>>[]),
    );

    await appState.loadLanguageProfiles();

    expect(appState.activeProfile?.level, 'A2');
    expect(appState.activeProfile?.isActive, isTrue,
        reason: 'an update must not quietly deactivate the profile');
  });

  test("a failed sync leaves the learner's answer alone and does not throw",
      () async {
    // They already answered. Losing that to a flaky network, or hanging the
    // screen on it, is worse than the mismatch this is fixing.
    final LearningLanguageProvider provider =
        await learnerWhoAnswered(level: 'A1');
    final List<Map<String, dynamic>> puts = <Map<String, dynamic>>[];
    final AppStateProvider appState = appStateTalkingTo(
      serverHolding(signupRow(), puts, putStatus: 500),
    );

    await appState.loadLanguageProfiles();

    expect(puts, hasLength(1), reason: 'it did try');
    expect(provider.englishLevel, 'A1');
    expect(LearningLanguageService.englishLevel, 'A1');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('learning_english_level'), 'A1');
    // The list still loaded; a refused push is not a failed load.
    expect(appState.languageProfiles, hasLength(1));
  });

  test('a second load retries what the first one could not send', () async {
    // Fail quietly, keep the local value, let the next sync fix it.
    await learnerWhoAnswered(level: 'A1');
    final List<Map<String, dynamic>> puts = <Map<String, dynamic>>[];
    final AppStateProvider failing = appStateTalkingTo(
      serverHolding(signupRow(), puts, putStatus: 500),
    );
    await failing.loadLanguageProfiles();
    expect(failing.activeProfile?.level, 'B1');

    final AppStateProvider recovered =
        appStateTalkingTo(serverHolding(signupRow(), puts));
    await recovered.loadLanguageProfiles();

    expect(puts, hasLength(2));
    expect(recovered.activeProfile?.level, 'A1');
  });

  test('a row that already agrees is not written to again', () async {
    // This is what keeps the push off the hot path. It fires when an answer
    // changes, not every time the profile list is loaded — and the list is
    // loaded on every launch, on every profile switch and after every
    // re-hydration.
    await learnerWhoAnswered(level: 'B2', goal: 'Exam');
    final List<Map<String, dynamic>> puts = <Map<String, dynamic>>[];
    final AppStateProvider appState = appStateTalkingTo(
      serverHolding(signupRow(level: 'B2', goal: 'Exam'), puts),
    );

    await appState.loadLanguageProfiles();
    await appState.loadLanguageProfiles();

    expect(puts, isEmpty);
  });

  test('a learner who has answered nothing has nothing pushed', () async {
    // The displayed defaults follow the interface language, and writing a guess
    // to the server as if it were a fact is what once turned a Turkish
    // learner's profile Spanish. `currentProfile()` is where that line already
    // lives; the push is behind it.
    final List<Map<String, dynamic>> puts = <Map<String, dynamic>>[];
    final AppStateProvider appState =
        appStateTalkingTo(serverHolding(signupRow(), puts));

    await appState.loadLanguageProfiles();

    expect(puts, isEmpty);
    expect(appState.activeProfile?.level, 'B1');
  });

  testWidgets('changing the level in Settings syncs it', (tester) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Already in agreement, so the load makes no request and every PUT below
    // belongs to the tap.
    final LearningLanguageProvider learning =
        await learnerWhoAnswered(level: 'B1', goal: 'Speaking');
    final List<Map<String, dynamic>> puts = <Map<String, dynamic>>[];
    final AppStateProvider appState = appStateTalkingTo(
      serverHolding(signupRow(goal: 'Speaking'), puts),
    );
    await appState.loadLanguageProfiles();
    expect(puts, isEmpty);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppStateProvider>.value(value: appState),
          ChangeNotifierProvider<LearningLanguageProvider>.value(
              value: learning),
          ChangeNotifierProvider<LanguageProvider>(
              create: (_) => LanguageProvider()),
          ChangeNotifierProvider<NfFrontendPreference>(
              create: (_) => NfFrontendPreference()),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: NfSettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder levelChip = find.textContaining('English level: B1');
    await tester.scrollUntilVisible(levelChip, 200);
    await tester.tap(levelChip);
    await tester.pumpAndSettle();

    await tester.tap(find.text('A1'));
    await tester.pumpAndSettle();

    expect(learning.englishLevel, 'A1');
    expect(puts, hasLength(1),
        reason: 'the level was changed here and only ever stored here');
    expect(puts.single['level'], 'A1');
  });

  testWidgets('the home screen shows the level the learner chose',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // The server row still holds the sign-up B1 — the state between the list
    // arriving and the push landing, and the state a push that keeps failing
    // leaves behind. The learner said A1, and the greeting must not argue.
    await learnerWhoAnswered(level: 'A1');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppStateProvider>.value(
            value: _SignedInAppState(
              const LanguageProfile(
                id: profileId,
                sourceLanguage: 'Turkish',
                targetLanguage: 'English',
                level: 'B1',
                isActive: true,
              ),
            ),
          ),
          ChangeNotifierProvider<NfFrontendPreference>(
              create: (_) => NfFrontendPreference()),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: NfTodayPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('English · A1'), findsOneWidget);
    expect(find.text('English · B1'), findsNothing,
        reason: 'B1 is what registration wrote, not what anyone chose');
  });

  testWidgets('and falls back to the row when nobody has answered',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // The guard has to cut one way only. With no answer stored there is no
    // learner's level to prefer, and the server's row is the better of the two
    // guesses — it is at least the row every other reader is using.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppStateProvider>.value(
            value: _SignedInAppState(
              const LanguageProfile(
                id: profileId,
                sourceLanguage: 'Turkish',
                targetLanguage: 'English',
                level: 'C1',
                isActive: true,
              ),
            ),
          ),
          ChangeNotifierProvider<NfFrontendPreference>(
              create: (_) => NfFrontendPreference()),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: NfTodayPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('English · C1'), findsOneWidget);
  });
}

/// A provider that is already loaded and holds one profile.
///
/// A real [AppStateProvider] reports itself uninitialised until a user is set,
/// and the page then draws its loading skeleton, which has no header chips at
/// all — so the assertions above would pass over an empty screen. Setting a
/// real user instead starts background hydration and leaves timers pending
/// past the end of the test. Overriding what the header reads is the version
/// that renders the state these tests are about; the same trick, and the same
/// reason, as `nf_today_plan_card_test.dart`.
class _SignedInAppState extends AppStateProvider {
  _SignedInAppState(this.profile);

  final LanguageProfile profile;

  @override
  bool get isInitialized => true;

  @override
  bool get isLoadingWords => false;

  @override
  LanguageProfile? get activeProfile => profile;

  @override
  String get userName => 'Eren';
}
