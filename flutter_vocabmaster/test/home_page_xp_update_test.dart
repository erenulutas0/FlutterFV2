import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vocabmaster/providers/app_state_provider.dart';
import 'package:vocabmaster/screens/home_page.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupTestEnv();
  });

  testWidgets('HomePage updates XP progress text when XP changes', (tester) async {
    final appState = AppStateProvider();
    appState.updateUserStats({
      'xp': 0,
      'level': 1,
      'xpToNextLevel': 100,
    });

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: MaterialApp(
          home: HomePage(
            onNavigate: (_) {},
            enableBackgroundTasks: false,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('0 / 100'), findsOneWidget);

    appState.updateUserStats({'xp': 10, 'level': 1});
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('10 / 100'), findsOneWidget);
  });
}
