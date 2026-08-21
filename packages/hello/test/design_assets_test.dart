// `show`, not a bare import: where DI is injectable, core also exports an
// Environment const named `test`, which shadows flutter_test's `test`.
import 'package:core/core.dart' show AppIcons;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('every AppIcons constant resolves through the real bundle',
      (tester) async {
    for (final asset in <String>[
      AppIcons.check,
      AppIcons.chevronLeft,
      AppIcons.eye,
      AppIcons.eyeOff,
      AppIcons.alertTriangle,
      AppIcons.home,
      AppIcons.settings,
    ]) {
      // Throws if the key is not in the bundle — exactly the failure that
      // otherwise only shows up as a red box on a device.
      await expectLater(rootBundle.load(asset), completes, reason: asset);
    }
  });

  test('every icon path is built from the one asset root', () {
    for (final asset in <String>[
      AppIcons.check,
      AppIcons.chevronLeft,
      AppIcons.eye,
      AppIcons.eyeOff,
      AppIcons.alertTriangle,
      AppIcons.home,
      AppIcons.settings,
    ]) {
      // The `lib/` is not a typo. See kCoreAssetRoot's own doc comment.
      expect(asset, startsWith('packages/core/lib/assets/'));
    }
  });
}
