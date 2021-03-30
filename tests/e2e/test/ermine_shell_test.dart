// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:sl4f/sl4f.dart';
import 'package:test/test.dart';

import 'ermine_driver.dart';

void main() {
  Sl4f sl4f;
  ErmineDriver ermine;

  const kTransientWait = Duration(seconds: 2);

  setUpAll(() async {
    sl4f = Sl4f.fromEnvironment();
    await sl4f.startServer();

    ermine = ErmineDriver(sl4f);
    await ermine.setUp();
  });

  tearDownAll(() async {
    // Any of these may end up being null if the test fails in setup.
    await ermine.tearDown();
    await sl4f?.stopServer();
    sl4f?.close();
  });

  test('Launch terminal and show recents', () async {
    // Launch terminal.
    const componentUrl = 'fuchsia-pkg://fuchsia.com/terminal#meta/terminal.cmx';
    await ermine.launch(componentUrl);

    // Terminal should fill the view from left to right edge.
    var viewRect = await ermine.getViewRect(componentUrl);
    expect(viewRect.left, equals(0));

    // Toggle Recents, until it is visible. Terminal view is shifted right.
    expect(
        await ermine.waitFor(() async {
          await ermine.driver.requestData('recents');
          await ermine.driver
              .waitUntilNoTransientCallbacks(timeout: kTransientWait);
          viewRect = await ermine.getViewRect(componentUrl);
          return viewRect.left > 0;
        }),
        isTrue);

    // Close terminal.
    await ermine.driver.requestData('close');
    await ermine.driver.waitUntilNoTransientCallbacks(timeout: kTransientWait);
    await ermine.isStopped(componentUrl);
  });

  test('Switch workspaces', () async {
    // Launch terminal in workspace 0.
    final title = find.descendant(
        of: find.byType('TileChrome'), matching: find.byType('Text'));

    await ermine.launch(terminalUrl);
    expect(
        await ermine.waitFor(() async {
          await ermine.driver
              .waitUntilNoTransientCallbacks(timeout: kTransientWait);
          final viewRect = await ermine.getViewRect(terminalUrl);
          return viewRect.width > 0;
        }),
        isTrue);
    await ermine.driver.waitUntilNoTransientCallbacks(timeout: kTransientWait);
    expect(await ermine.driver.getText(title), 'terminal.cmx');

    print(' Launched terminal');

    // Switch to workspace 1, which should be empty.
    expect(
        await ermine.waitFor(() async {
          await ermine.driver.requestData('nextCluster');
          await ermine.driver
              .waitUntilNoTransientCallbacks(timeout: kTransientWait);
          final viewRect = await ermine.getViewRect(terminalUrl);
          return viewRect.width == 0;
        }),
        isTrue);
    print(' Switched to workspace 1');

    // Launch simple browser in workspace 1.
    await ermine.launch(simpleBrowserUrl);
    expect(
        await ermine.waitFor(() async {
          await ermine.driver
              .waitUntilNoTransientCallbacks(timeout: kTransientWait);
          final viewRect = await ermine.getViewRect(simpleBrowserUrl);
          return viewRect.width > 0;
        }),
        isTrue);
    await ermine.driver.waitUntilNoTransientCallbacks(timeout: kTransientWait);
    expect(await ermine.driver.getText(title), 'simple-browser.cmx');
    expect(await ermine.isRunning(simpleBrowserUrl), isTrue);

    print(' Launched simple_browser');

    // Switch back to workspace 0, which should show terminal and hide browser.
    expect(
        await ermine.waitFor(() async {
          await ermine.driver.requestData('previousCluster');
          await ermine.driver
              .waitUntilNoTransientCallbacks(timeout: kTransientWait);
          final viewRect = await ermine.getViewRect(simpleBrowserUrl);
          return viewRect.width == 0;
        }),
        isTrue);
    expect(
        await ermine.waitFor(() async {
          await ermine.driver
              .waitUntilNoTransientCallbacks(timeout: kTransientWait);
          final viewRect = await ermine.getViewRect(terminalUrl);
          return viewRect.width > 0;
        }),
        isTrue);

    print(' Switched to workspace 0');

    // Close terminal and simple-browser
    await ermine.driver.requestData('closeAll');
    await ermine.isStopped(simpleBrowserUrl);
    await ermine.isStopped(terminalUrl);
  });
}
