// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;
import 'dart:io';
import 'dart:ui';

import 'package:ermine/src/utils/view_handle.dart';
import 'package:fidl_fuchsia_buildinfo/fidl_async.dart' as buildinfo;
import 'package:fidl_fuchsia_device_manager/fidl_async.dart';
import 'package:fidl_fuchsia_intl/fidl_async.dart';
import 'package:fidl_fuchsia_ui_activity/fidl_async.dart' as activity;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fuchsia_inspect/inspect.dart';
import 'package:fuchsia_internationalization_flutter/internationalization.dart';
import 'package:fuchsia_logger/logger.dart';
import 'package:fuchsia_scenic/views.dart';
import 'package:fuchsia_services/services.dart';
import 'package:zircon/zircon.dart';

// List of default app entries to use when app_launch_entries.json is not found.
const _kAppDefaultEntries = <Map<String, String>>[
  {
    'title': 'Simple Browser',
    'icon': 'images/SimpleBrowser-icon-2x.png',
    'url': 'fuchsia-pkg://fuchsia.com/simple-browser#meta/simple-browser.cmx',
  },
  {
    'title': 'Terminal',
    'icon': 'images/Terminal-icon-2x.png',
    'url': 'fuchsia-pkg://fuchsia.com/terminal#meta/terminal.cmx',
  },
  {
    'title': 'Settings',
    'icon': 'images/Settings-icon-2x.png',
  },
];

/// Defines a service that manages the applications startup state like
/// [ComponentContext] and view's [ViewHandle].
///
/// It also provides access to:
/// - listening to change in system [Locale].
/// - build version of the system.
/// - restart/shutdown the system.
/// - load MaterialIcons [Font] at startup.
class StartupService extends activity.Listener {
  /// Global flag that enables screen saver to kick in. This is set to false
  /// when flutter driver is enabled. See [test_main.dart].
  static bool allowScreensaver = true;

  /// Returns the shell's [ComponentContext].
  final ComponentContext componentContext;

  /// Returns the shell's [ViewHandle].
  final ViewHandle hostView;

  /// Callback to service [Inspect] requests from the system.
  late final void Function(Node) onInspect;

  /// Callback when the system is idle according to activity service.
  late final void Function({required bool idle}) onIdle;

  final _inspect = Inspect();
  final _intl = PropertyProviderProxy();
  final _deviceManager = AdministratorProxy();
  final _provider = buildinfo.ProviderProxy();
  final _activity = activity.ProviderProxy();
  final _activityBinding = activity.ListenerBinding();
  final _activityTracker = activity.TrackerProxy();
  String _buildVersion = '--';
  late final List<Map<String, String>> appLaunchEntries;

  StartupService()
      : componentContext = ComponentContext.create(),
        hostView = ViewHandle(ScenicContext.hostViewRef()) {
    Incoming.fromSvcPath().connectToService(_intl);
    Incoming.fromSvcPath().connectToService(_deviceManager);
    Incoming.fromSvcPath().connectToService(_provider);
    Incoming.fromSvcPath().connectToService(_activity);
    Incoming.fromSvcPath().connectToService(_activityTracker);

    if (allowScreensaver) {
      _activity.watchState(_activityBinding.wrap(this));
    }

    // TODO(http://fxb/80131): Remove once activity is reported in the input
    // pipeline.
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) {
      RawKeyboard.instance.addListener((_) => onActivity('keyboard'));
    });

    // We cannot load MaterialIcons font file from pubspec.yaml. So load it
    // explicitly.
    File file = File('/pkg/data/MaterialIcons-Regular.otf');
    if (file.existsSync()) {
      FontLoader('MaterialIcons')
        ..addFont(() async {
          return file.readAsBytesSync().buffer.asByteData();
        }())
        ..load();
    }

    // Get app launch entries.
    file = File('/pkg/data/app_launch_entries.json');
    if (file.existsSync()) {
      final data = file.readAsStringSync();
      final entries = json.decode(data, reviver: (key, value) {
        // Sanitize and strongly type json values.
        if (value is Map<String, dynamic>) {
          return Map<String, String>.from(value);
        } else if (value is List<dynamic>) {
          return List<Map<String, String>>.from(value);
        } else {
          return value;
        }
      });
      try {
        // Filter out entries missing 'title', the minimum requirement.
        appLaunchEntries = (entries as List<Map<String, String>>)
            .where((e) => e.containsKey('title'))
            .toList(growable: false);
        // ignore: avoid_catches_without_on_clauses
      } catch (e) {
        log.warning('$e: Failed to parse app_launch_entries.json. \n$data');
        appLaunchEntries = _kAppDefaultEntries;
      }
    } else {
      appLaunchEntries = _kAppDefaultEntries;
    }

    // Get the build info.
    _provider.getBuildInfo().then((buildInfo) {
      _buildVersion = buildInfo.version ?? '--';
    });
  }

  void dispose() {
    _deviceManager.ctrl.close();
    _intl.ctrl.close();
    _provider.ctrl.close();
    _activityBinding.close();
    _activity.ctrl.close();
    _activityTracker.ctrl.close();
  }

  /// Publish outgoing services.
  void serve() {
    _inspect
      ..serve(componentContext.outgoing)
      ..onDemand('ermine', onInspect);
    componentContext.outgoing.serveFromStartupInfo();
  }

  // The time when last activity was reported.
  DateTime? _lastActivityReport;

  /// Report pointer and keyboard interaction to activity tracker service.
  void onActivity(String type) {
    int eventTime = System.clockGetMonotonic();
    // Throttle activity reporting by 5 seconds.
    if (_lastActivityReport == null ||
        DateTime.now()
            .subtract(Duration(seconds: 5))
            .isAfter(_lastActivityReport!)) {
      _lastActivityReport = DateTime.now();
      _activityTracker.reportDiscreteActivity(
        activity.DiscreteActivity.withGeneric(
            activity.GenericActivity(label: type)),
        eventTime,
      );
    }
    // Since we have user activity, cancel the timer that disables startup idle.
    _disableIdleAtStartupTimer?.cancel();
  }

  /// Return the build version.
  String get buildVersion => _buildVersion;

  /// Reboot the device.
  void restartDevice() => _deviceManager.suspend(suspendFlagReboot);

  /// Shutdown the device.
  void shutdownDevice() => _deviceManager.suspend(suspendFlagPoweroff);

  Stream<Locale> get stream => LocaleSource(_intl).stream();

  Timer? _disableIdleAtStartupTimer;

  @override
  Future<void> onStateChanged(activity.State state, int transitionTime) async {
    // TODO(http://fxb/80131): Ignore the idle state at startup.
    if (_disableIdleAtStartupTimer == null && state == activity.State.idle) {
      // Initiate idle state at 15 minutes ourselves.
      _disableIdleAtStartupTimer =
          Timer(Duration(minutes: 15), () => onIdle(idle: true));
      return;
    }
    // Subsequent state changes from activity service don't need startup idle.
    _disableIdleAtStartupTimer?.cancel();

    onIdle(idle: state == activity.State.idle);
  }
}
