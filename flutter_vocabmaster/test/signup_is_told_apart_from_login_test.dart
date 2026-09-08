import 'package:flutter_test/flutter_test.dart';
import 'package:vocabmaster/services/auth_service.dart';

/// Whether a sign-in was somebody's first.
///
/// The server says so — `newAccount`, at the top level of the Google login
/// response. The landing page reads it to log `signup_completed` rather than
/// `login_completed`. Between the two sat a map literal that rebuilt the
/// response keeping only `success` and `user`, so the field never reached the
/// caller and `signup_completed` fired for nobody, for as long as it existed.
///
/// That event is the only thing in the funnel that separates a real new person
/// from a returning device or a store's pre-launch robot: Play counts installs
/// including reinstalls, Firebase counts `first_open` including test harnesses,
/// and neither of those can sign in with Google. Losing it means having no
/// honest answer to "did that post bring anyone" — the only question worth
/// asking while the app has four users and is being advertised.
///
/// The same literal dropped `trialBlockedReason`, the one word the server says
/// about a refused 7-day trial. Two fields, one mistake, three lines apart.
void main() {
  const Map<String, dynamic> user = <String, dynamic>{
    'id': 7,
    'email': 'learner@test.local',
    'displayName': 'Learner',
  };

  Map<String, dynamic> resultFor(Map<String, dynamic> serverSaid) =>
      AuthService.googleLoginResult(serverSaid, user);

  test('a first sign-in is reported as one', () {
    final Map<String, dynamic> result = resultFor(<String, dynamic>{
      'success': true,
      'newAccount': true,
    });

    expect(result['success'], isTrue);
    expect(result['user'], same(user));
    expect(result['newAccount'], isTrue,
        reason: 'without this, signup_completed can never fire');
  });

  test('a returning learner is not counted as a signup', () {
    expect(
      resultFor(<String, dynamic>{'newAccount': false})['newAccount'],
      isFalse,
    );
  });

  test('a server that says nothing stays silent, rather than saying no', () {
    // An older backend, or a response shape that changes again. Absent must not
    // arrive as `false`: that is a claim this build cannot support, and it
    // would be made on every single login.
    final Map<String, dynamic> result = resultFor(<String, dynamic>{});

    expect(result.containsKey('newAccount'), isFalse);
    expect(result.containsKey('trialBlockedReason'), isFalse);
    expect(result['success'], isTrue);
  });

  test('a refused trial travels the same road, and both arrive', () {
    final Map<String, dynamic> result = resultFor(<String, dynamic>{
      'newAccount': true,
      'trialBlockedReason': 'device-limit',
    });

    expect(result['newAccount'], isTrue);
    expect(result['trialBlockedReason'], 'device-limit');
  });

  test('nothing else the server sends is carried by accident', () {
    // The map is deliberately a whitelist. A response field that reaches the
    // app without anyone deciding it should is how a token or an email ends up
    // somewhere it was never meant to go.
    final Map<String, dynamic> result = resultFor(<String, dynamic>{
      'newAccount': true,
      'accessToken': 'secret',
      'refreshToken': 'also-secret',
      'userId': 7,
    });

    expect(result.keys.toSet(), <String>{'success', 'user', 'newAccount'});
  });
}
