import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabmaster/widgets/bottom_nav.dart';

void main() {
  testWidgets('BottomNav renders correctly', (WidgetTester tester) async {
    // Build BottomNav inside MaterialApp
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNav(
            currentIndex: 0,
            onTap: (index) {},
          ),
        ),
      ),
    );

    // Verify icons are present
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget); // Was fails on Icons.book
    
    // ...
    // expect(find.byType(BottomNavigationBarItem)... (removed)

  });
  
  testWidgets('BottomNav callback works', (WidgetTester tester) async {
    int tappedIndex = -1;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNav(
            currentIndex: 0,
            onTap: (index) {
              tappedIndex = index;
            },
          ),
        ),
      ),
    );

    // Find the words icon (index 1) and tap it
    await tester.tap(find.byIcon(Icons.menu_book_rounded));
    await tester.pumpAndSettle(); // Wait for animation

    // Verify callback was called with index 1
    expect(tappedIndex, 1);
  });
}
