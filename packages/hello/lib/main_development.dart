import 'package:core/core.dart';
import 'package:hello/app/view/app.dart';
import 'package:hello/inject.dart';

Future<void> main() async {
  await bootstrap(
    () => const HelloApp(),
    initializer: () async {
      await configureInjection(Environment.development);
      // Add additional initialization logic here.
    },
  );
}
