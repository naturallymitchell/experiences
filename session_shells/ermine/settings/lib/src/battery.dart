// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:fidl_fuchsia_power/fidl_async.dart';
import 'package:fidl_fuchsia_ui_remotewidgets/fidl_async.dart';
import 'package:fuchsia_services/services.dart' show StartupContext;
import 'package:quickui/quickui.dart';

/// Defines a [UiSpec] for visualizing battery.
class Battery extends UiSpec {
  static const _title = 'Battery';
  static const _checkBatteryDuration = Duration(seconds: 1);

  BatteryModel model;

  Battery({BatteryManagerProxy monitor, BatteryInfoWatcherBinding binding}) {
    model = BatteryModel(
      monitor: monitor,
      binding: binding,
      onChange: _onChange,
    );
    Timer.periodic(_checkBatteryDuration, (Timer t) => {_onChange()});
  }

  factory Battery.fromStartupContext(StartupContext startupContext) {
    final batteryManager = BatteryManagerProxy();
    startupContext.incoming.connectToService(batteryManager);
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
    final batteryText = '${value.toStringAsFixed(0)}%';
    if (value.isNaN || value == 0) {
      return null;
    }
    if (value == 100) {
      return Spec(groups: [
        Group(title: _title, values: [
          Value.withIcon(IconValue(codePoint: Icons.battery_full.codePoint)),
          Value.withText(TextValue(text: batteryText)),
        ]),
      ]);
    } else if (charging) {
      return Spec(groups: [
        Group(title: _title, values: [
          Value.withIcon(
              IconValue(codePoint: Icons.battery_charging_full.codePoint)),
          Value.withText(TextValue(text: batteryText)),
        ]),
      ]);
    } else if (value <= 10) {
      return Spec(groups: [
        Group(title: _title, values: [
          Value.withIcon(IconValue(codePoint: Icons.battery_alert.codePoint)),
          Value.withText(TextValue(text: batteryText)),
        ]),
      ]);
    } else {
      return Spec(groups: [
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

  double _battery;
  bool charging;

  BatteryModel({
    @required this.onChange,
    BatteryInfoWatcherBinding binding,
    BatteryManagerProxy monitor,
  }) : _binding = binding ?? BatteryInfoWatcherBinding() {
    monitor
      ..watch(_binding.wrap(_BatteryInfoWatcherImpl(this)))
      ..getBatteryInfo().then(updateBattery);
  }

  void dispose() {
    _binding.close();
  }

  double get battery => _battery;
  set battery(double value) {
    _battery = value;
    onChange?.call();
  }

  void updateBattery(BatteryInfo info) {
    final chargeStatus = info.chargeStatus;
    charging = chargeStatus == ChargeStatus.charging;
    battery = info.levelPercent;
  }
}

class _BatteryInfoWatcherImpl extends BatteryInfoWatcher {
  final BatteryModel batteryModel;
  _BatteryInfoWatcherImpl(this.batteryModel);

  @override
  Future<void> onChangeBatteryInfo(BatteryInfo info) async {
    batteryModel.updateBattery(info);
  }
}