// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_driver_sl4f/flutter_driver_sl4f.dart';
import 'package:sl4f/sl4f.dart';
import 'package:test/test.dart';
import 'package:webdriver/sync_io.dart' show WebDriver;

const _chromeDriverPath = 'runtime_deps/chromedriver';

/// Defines a test utility class to drive Ermine during integration test using
/// Flutter Driver. This utility will grow with more convenience methods in the
/// future useful for testing.
class ErmineDriver {
  /// The instance of [Sl4f] used to connect to Ermine flutter app.
  final Sl4f sl4f;

  FlutterDriver _driver;
  final FlutterDriverConnector _connector;
  final _browserDrivers = <FlutterDriver>[];
  final _browserConnectors = <FlutterDriverConnector>[];
  final WebDriverConnector _webDriverConnector;

  /// Constructor.
  ErmineDriver(this.sl4f)
      : _connector = FlutterDriverConnector(sl4f),
        _webDriverConnector = WebDriverConnector(_chromeDriverPath, sl4f);

  /// The instance of [FlutterDriver] that is connected to Ermine flutter app.
  FlutterDriver get driver => _driver;

  /// Set up the test environment for Ermine.
  ///
  /// This restarts the workstation session and connects to the running instance
  /// of Ermine using FlutterDriver.
  Future<void> setUp() async {
    // TODO(http://fxbug.dev/66199): Uncomment once session restart is fixed.
    // Restart the workstation session.
    // final result = await sl4f.ssh.run('session_control restart');
    // if (result.exitCode != 0) {
    //   fail('failed to restart workstation session.');
    // }

    // Initialize Ermine's flutter driver and web driver connectors.
    await _connector.initialize();
    await _webDriverConnector.initialize();

    // Now connect to ermine.
    _driver = await _connector.driverForIsolate('ermine');
    if (_driver == null) {
      fail('unable to connect to ermine.');
    }
  }

  /// Closes [FlutterDriverConnector] and performs cleanup.
  Future<void> tearDown() async {
    await _driver?.close();
    await _connector.tearDown();

    for (final browserDriver in _browserDrivers) {
      await browserDriver?.close();
    }

    for (final browserConnector in _browserConnectors) {
      await browserConnector?.tearDown();
    }

    await _webDriverConnector?.tearDown();
  }

  /// Launch a component given its [componentUrl].
  Future<void> launch(String componentUrl) async {
    final result = await sl4f.ssh.run('session_control add $componentUrl');
    if (result.exitCode != 0) {
      fail('failed to launch component: $componentUrl.');
    }
  }

  /// Got to the Overview screen.
  Future<void> gotoOverview() async {
    await _driver.requestData('overview');
    await _driver.waitFor(find.byValueKey('overview'));
  }

  /// Launches a simple browser and returns a [FlutterDriver] connected to it.
  Future<FlutterDriver> launchAndWaitForSimpleBrowser() async {
    await launch(
        'fuchsia-pkg://fuchsia.com/simple-browser#meta/simple-browser.cmx');

    // Initilize the browser's flutter driver connector.
    final browserConnector = FlutterDriverConnector(sl4f);
    _browserConnectors.add(browserConnector);
    await browserConnector.initialize();

    // Checks if Simple Browser is running.
    // TODO(fxb/66577): Get the last isolate once it's supported by
    // [FlutterDriverConnector] in flutter_driver_sl4f.dart
    final browserIsolate = await browserConnector.isolate('simple-browser');
    if (browserIsolate == null) {
      fail("couldn't find simple browser.");
    }

    // Connect to the browser.
    // TODO(fxb/66577): Get the driver of the last isolate once it's supported by
    // [FlutterDriverConnector] in flutter_driver_sl4f.dart
    final browserDriver =
        await browserConnector.driverForIsolate('simple-browser');
    _browserDrivers.add(browserDriver);
    if (browserDriver == null) {
      fail('unable to connect to simple browser.');
    }

    await browserDriver.waitUntilNoTransientCallbacks();

    return browserDriver;
  }

  /// Returns a web driver connected to a given URL.
  Future<WebDriver> getWebDriverFor(String hostUrl) async {
    return (await _webDriverConnector.webDriversForHost(hostUrl)).single;
  }
}
