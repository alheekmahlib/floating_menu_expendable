// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:floating_menu_expendable_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Example app renders floating menu', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Floating Menu'), findsOneWidget);
    expect(find.byKey(const Key('floating_menu_panel_handle')), findsOneWidget);

    // Tap the handle to open the panel.
    await tester.tap(find.byKey(const Key('floating_menu_panel_handle')));
    await tester.pumpAndSettle();

    // When open, the handle switches to a close icon by default.
    expect(
      find.descendant(
        of: find.byKey(const Key('floating_menu_panel_handle')),
        matching: find.byIcon(Icons.close_rounded),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Anchored overlay opens and closes on scroll', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    // Go to the Anchored tab.
    await tester.tap(find.text('Anchored'));
    await tester.pumpAndSettle();

    // Tap the first grid item to open.
    await tester.tap(find.byKey(const Key('grid_item_0')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('floating_menu_anchored_overlay_panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('floating_menu_anchored_overlay_barrier')),
      findsOneWidget,
    );

    // Scroll the grid; closeOnScroll should dismiss the overlay.
    // Simulate a scroll gesture; closeOnScroll should dismiss the overlay.
    await tester.drag(
      find.byKey(const Key('floating_menu_anchored_overlay_barrier')),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('floating_menu_anchored_overlay_panel')),
      findsNothing,
    );
  });
}
