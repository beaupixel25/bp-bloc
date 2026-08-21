import 'package:core_demo/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders demo home page', (tester) async {
    await tester.pumpWidget(const DemoApp());
    expect(find.text('Core Demo'), findsWidgets);
  });

  for (final brightness in Brightness.values) {
    testWidgets('every section renders in ${brightness.name}', (tester) async {
      // Drive the platform brightness rather than wrapping in a MediaQuery:
      // MaterialApp builds its own from the view, so an outer one is ignored.
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      // Tall enough that scrolling is a few steps rather than dozens.
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DemoApp());
      // NOT pumpAndSettle: the busy-button demo shows a
      // CircularProgressIndicator, which animates forever, so the tree never
      // settles and pumpAndSettle times out. One pump past the entry
      // animations is all this needs.
      await tester.pump(const Duration(milliseconds: 400));

      expect(componentSections, isNotEmpty);
      for (final section in componentSections) {
        await tester.scrollUntilVisible(
          find.text(section.title),
          240,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          find.text(section.title),
          findsOneWidget,
          reason: '${section.title} did not render in ${brightness.name}',
        );
      }
    });
  }
}
