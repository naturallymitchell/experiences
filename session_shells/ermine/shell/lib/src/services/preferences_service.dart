// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json;
import 'dart:io';

import 'package:ermine_utils/ermine_utils.dart';
import 'package:fuchsia_logger/logger.dart';
import 'package:mobx/mobx.dart';

/// Defines a service that allows reading and storing application data.
class PreferencesService with Disposable {
  /// The JSON file that stores preferences persistently.
  static const kPreferencesJson = '/data/preferences.json';

  /// The JSON file that provides preferences as part of package install.
  static const kStartupPreferencesJson = '/pkg/data/preferences.json';

  // Use dark mode: true | false.
  final darkMode = true.asObservable();

  // Show screensaver: true | false.
  bool showScreensaver = false;

  final Map<String, dynamic> _data;

  PreferencesService() : _data = _readPreferences() {
    darkMode.value = _data['dark_mode'] ?? true;
    showScreensaver = _data['screensaver'] ?? true;
    reactions.add(reaction<bool>((_) => darkMode.value, _setDarkMode));
  }

  void _setDarkMode(bool value) {
    _data['dark_mode'] = value;
    _writePreferences(_data);
  }

  static Map<String, dynamic> _readPreferences() {
    Map<String, dynamic> parsePreferences(String data) {
      return json.decode(data, reviver: (key, value) {
        // Sanitize input.
        if (key == 'dark_mode') {
          return value is bool && value;
        }

        // Screensaver.
        if (key == 'screensaver') {
          // ignore: avoid_bool_literals_in_conditional_expressions
          return value is bool ? value : true;
        }

        return value;
      });
    }

    final result = <String, dynamic>{};
    // Read preferences from package configuration.
    var file = File(kStartupPreferencesJson);
    if (file.existsSync()) {
      result.addAll(parsePreferences(file.readAsStringSync()));
    }

    // Read preferences from previous session and overwrite intial values.
    file = File(kPreferencesJson);
    if (file.existsSync()) {
      result.addAll(parsePreferences(file.readAsStringSync()));
      log.info('Read settings from previous session');
    } else {
      log.info('Failed to read settings from previous session');
    }

    return result;
  }

  static void _writePreferences(Map<String, dynamic> data) {
    File(kPreferencesJson).writeAsStringSync(json.encode(data), flush: true);
  }
}
