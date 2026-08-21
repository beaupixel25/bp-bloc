import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every `*_page.dart` under `lib/`, wherever it lives.
List<File> _pageSources() {
  final root = Directory('lib');
  if (!root.existsSync()) return [];

  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('_page.dart'))
      .toList();
}

void main() {
  group('pages own layout, components own styling', () {
    // A page that names a colour stops surviving the next design-system
    // bundle: the bundle restyles components, and a literal in a page is
    // unreachable from it. These read the sources off disk rather than
    // asserting on a widget tree, because the rule is about what is written.
    late List<File> pages;

    setUpAll(() {
      pages = _pageSources();
    });

    test('there are pages to check', () {
      // Guards the glob itself. If this ever finds nothing, every assertion
      // below passes vacuously and the contract stops being enforced.
      expect(pages, isNotEmpty, reason: 'no *_page.dart found under lib/');
    });

    test('no page contains a literal colour', () {
      for (final page in pages) {
        final source = page.readAsStringSync();
        expect(
          source,
          isNot(contains('Color(0x')),
          reason: '${page.path} names a literal colour',
        );
      }
    });

    test('no page reaches for the Material palette', () {
      for (final page in pages) {
        final source = page.readAsStringSync();
        // Colors.transparent is the one exception: it is not a design token,
        // it is the absence of paint.
        expect(
          source,
          isNot(matches(RegExp(r'Colors\.(?!transparent)'))),
          reason: '${page.path} uses Colors.*',
        );
      }
    });

    test('no page names a custom colour role', () {
      for (final page in pages) {
        final source = page.readAsStringSync();
        expect(
          source,
          isNot(contains('ColorExtension')),
          reason: '${page.path} reads ColorExtension',
        );
      }
    });
  });
}
