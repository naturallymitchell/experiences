// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json;
import 'dart:io';

import 'package:mobx/mobx.dart';

import 'package:next/src/utils/mobx_disposable.dart';
import 'package:next/src/utils/mobx_extensions.dart';

/// Defines a service that allows reading and storing application data.
class PreferencesService with Disposable {
  static const kPreferencesJson = '/data/preferences.json';

  // Use dark mode: true | false.
  final darkMode = true.asObservable();

  final Map<String, dynamic> _data;

  PreferencesService() : _data = _readPreferences() {
    darkMode.value = _data['dark_mode'] ?? true;
    reactions.add(reaction<bool>((_) => darkMode.value, _setDarkMode));
  }

  void _setDarkMode(bool value) {
    _data['dark_mode'] = value;
    _writePreferences(_data);
  }

  static Map<String, dynamic> _readPreferences() {
    final file = File(kPreferencesJson);
    if (file.existsSync()) {
      return json.decode(file.readAsStringSync(), reviver: (key, value) {
        // Sanitize input.
        if (key == 'dark_mode') {
          return value is bool && value;
        }

        return value;
      });
    }
    return {};
  }

  static void _writePreferences(Map<String, dynamic> data) {
    File(kPreferencesJson).writeAsStringSync(json.encode(data));
  }
}
