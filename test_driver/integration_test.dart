// Driver for `integration_test/screenshots_test.dart`.
//
// Receives screenshot bytes from the integration test running on the device
// and writes them to `docs/screenshots/temp/` on the host machine.
//
// Usage (with a Pixel 7 Pro AVD booted):
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshots_test.dart \
//     -d emulator-5554

import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final outputDir = Directory('docs/screenshots/temp');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final file = File('${outputDir.path}/$name.png');
      await file.writeAsBytes(bytes);
      // ignore: avoid_print
      print('  ⤴ saved ${file.path} (${bytes.length} bytes)');
      return true;
    },
  );
}
