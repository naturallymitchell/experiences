// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:fidl_fuchsia_power/fidl_async.dart';
import 'package:fidl_fuchsia_ui_remotewidgets/fidl_async.dart';
import 'package:fuchsia_services/services.dart' show Incoming;
import 'package:internationalization/strings.dart';
import 'package:quickui/quickui.dart';

// ignore_for_file: prefer_constructors_over_static_methods

/// Defines a [UiSpec] for visualizing battery.
class Battery extends UiSpec {
  // Localized strings.
  static String get _title => Strings.battery;

  late BatteryModel model;

  Battery({
    required BatteryManagerProxy monitor,
    BatteryInfoWatcherBinding? binding,
  }) {
    model = BatteryModel(
      monitor: monitor,
      binding: binding,
      onChange: _onChange,
    );
  }

  factory Battery.withSvcPath() {
    final batteryManager = BatteryManagerProxy();
    Incoming.fromSvcPath().connectToService(batteryManager);
    return Battery(monitor: batteryManager);
  }

  void _onChange() {
    spec = _specForBattery(model.battery, model.charging);
  }

  @override
  void update(Value value) async {}

  @override
  void dispose() {
    model.dispose();
  }

  static Spec _specForBattery(double value, bool charging) {
    if (value.isNaN) {
      // Send nullSpec to hide battery settings.
      return UiSpec.nullSpec;
    }
    final batteryText = '${value.toStringAsFixed(0)}%';
    if (value == 100) {
      return Spec(title: _title, groups: [
        Group(title: _title, values: [
          Value.withIcon(IconValue(codePoint: Icons.battery_full.codePoint)),
          Value.withText(TextValue(text: batteryText)),
        ]),
      ]);
    } else if (charging) {
      return Spec(title: _title, groups: [
        Group(title: _title, values: [
          Value.withIcon(
              IconValue(codePoint: Icons.battery_charging_full.codePoint)),
          Value.withText(TextValue(text: batteryText)),
        ]),
      ]);
    } else if (value <= 10) {
      return Spec(title: _title, groups: [
        Group(title: _title, values: [
          Value.withIcon(IconValue(codePoint: Icons.battery_alert.codePoint)),
          Value.withText(TextValue(text: batteryText)),
        ]),
      ]);
    } else {
      return Spec(title: _title, groups: [
        Group(title: _title, values: [
          Value.withText(TextValue(text: batteryText)),
        ]),
      ]);
    }
  }
}

class BatteryModel {
  final VoidCallback onChange;
  final BatteryInfoWatcherBinding _binding;
  final BatteryManagerProxy _monitor;

  late double _battery;
  late bool charging;

  BatteryModel({
    required this.onChange,
    required BatteryManagerProxy monitor,
    BatteryInfoWatcherBinding? binding,
  })  : _binding = binding ?? BatteryInfoWatcherBinding(),
        _monitor = monitor {
    // Note that watcher will receive callback immediately with
    // current battery info, so no need to make additional calls
    // to get initial state.
    _monitor.watch(_binding.wrap(_BatteryInfoWatcherImpl(this)));
  }

  void dispose() {
    _monitor.ctrl.close();
    _binding.close();
  }

  double get battery => _battery;
  set battery(double value) {
    _battery = value;
    onChange();
  }

  void _updateBattery(BatteryInfo info) {
    // BatteryStatus.ok indicates that the battery is present and
    // in a known state (so we can show battery info).
    // Alternate states include:
    //     BatteryStatus.unknown - not yet initialized
    //                             (waiting for information from the system)
    //     BatteryStatus.notAvailable = battery present, but possibly disabled
    //     BatteryStatus.notPresent = batteries not included
    if (info.status == BatteryStatus.ok) {
      final chargeStatus = info.chargeStatus;
      charging = chargeStatus == ChargeStatus.charging;
      battery = info.levelPercent!;
    } else if (info.status == BatteryStatus.notPresent) {
      // upon receiving report of status 'notPresent' it is safe to close the
      // connection and stop listening for battery status updates.
      _monitor.ctrl.close();
      _binding.close();
    }
  }
}

class _BatteryInfoWatcherImpl extends BatteryInfoWatcher {
  final BatteryModel batteryModel;
  _BatteryInfoWatcherImpl(this.batteryModel);

  @override
  Future<void> onChangeBatteryInfo(BatteryInfo info) async {
    batteryModel._updateBattery(info);
  }
}
