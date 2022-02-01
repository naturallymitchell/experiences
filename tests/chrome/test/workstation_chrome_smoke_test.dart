// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: import_of_legacy_library_into_null_safe
import 'dart:math';

import 'package:ermine_driver/ermine_driver.dart';
import 'package:fidl_fuchsia_input/fidl_async.dart';
import 'package:sl4f/sl4f.dart';
import 'package:test/test.dart';

const chromeUrl = 'fuchsia-pkg://fuchsia.com/chrome#meta/chrome_v1.cmx';

void main() {
  late Sl4f sl4f;
  late ErmineDriver ermine;

  setUpAll(() async {
    sl4f = Sl4f.fromEnvironment();
    await sl4f.startServer();

    ermine = ErmineDriver(sl4f);
    await ermine.setUp();
  });

  tearDownAll(() async {
    await ermine.tearDown();
    print('Tore down Ermine flutter driver');
    await sl4f.stopServer();
    print('Stopped sl4f server');
    sl4f.close();
    print('Closed sl4f');
  });

  test('Should be able to launch Chrome browser.', () async {
    await ermine.launch(chromeUrl);
    await ermine.driver.waitUntilNoTransientCallbacks();
    print('Launched Chrome');

    final snapshot = await ermine.waitForView(chromeUrl);
    expect(snapshot.focused, true);
    expect(snapshot.url, chromeUrl);
    print('A Chrome view is presented');

    // Takes a screenshot and checks the color
    const white = 0xffffffff; // (0xAABBGGRR)
    Map<int, int> histogram;

    await Future.delayed(Duration(seconds: 3));
    final isWhite = await ermine.waitFor(() async {
      print('Take a screenshot...');
      final screenshot = await ermine.screenshot(Rectangle(500, 500, 100, 100));
      histogram = ermine.histogram(screenshot);
      print('Color key: ${histogram.keys.first}');
      print('Color value: ${histogram.values.first}');
      if (histogram.keys.length == 1 && histogram[white] == 10000) {
        return true;
      }
      return false;
    }, timeout: Duration(minutes: 2));

    expect(isWhite, isTrue);

    // Close the Chrome view.
    await ermine.threeKeyShortcut(Key.leftCtrl, Key.leftShift, Key.w);
    await ermine.driver.waitUntilNoTransientCallbacks();
    expect(await ermine.waitForViewAbsent(chromeUrl), true);
    print('Closed Chrome');
  });
}
