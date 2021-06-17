// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';

import 'package:next/src/services/settings/datetime_service.dart';
import 'package:next/src/services/settings/task_service.dart';
import 'package:next/src/services/settings/timezone_service.dart';
import 'package:next/src/services/shortcuts_service.dart';
import 'package:next/src/states/settings_state.dart';
import 'package:next/src/utils/mobx_disposable.dart';
import 'package:next/src/utils/mobx_extensions.dart';

/// Defines the implementation of [SettingsState].
class SettingsStateImpl with Disposable implements SettingsState, TaskService {
  static const kTimezonesFile = '/pkg/data/tz_ids.txt';

  final settingsPage = SettingsPage.none.asObservable();

  @override
  late final shortcutsPageVisible =
      (() => settingsPage.value == SettingsPage.shortcuts).asComputed();

  @override
  late final allSettingsPageVisible =
      (() => settingsPage.value == SettingsPage.none).asComputed();

  @override
  late final timezonesPageVisible =
      (() => settingsPage.value == SettingsPage.timezone).asComputed();

  @override
  final wifiStrength = Observable<WiFiStrength>(WiFiStrength.good);

  @override
  final batteryCharge = Observable<BatteryCharge>(BatteryCharge.charging);

  @override
  final Map<String, Set<String>> shortcutBindings;

  @override
  final Observable<String> selectedTimezone;

  final List<String> _timezones;

  @override
  List<String> get timezones {
    // Move the selected timezone to the top.
    return [selectedTimezone.value]
      ..addAll(_timezones.where((zone) => zone != selectedTimezone.value));
  }

  @override
  late final ObservableValue<String> dateTime = (() =>
      // Ex: Mon, Jun 7 2:25 AM
      DateFormat.MMMEd().add_jm().format(dateTimeNow.value)).asComputed();

  final DateTimeService dateTimeService;
  final TimezoneService timezoneService;

  SettingsStateImpl({
    required ShortcutsService shortcutsService,
    required this.timezoneService,
    required this.dateTimeService,
  })  : shortcutBindings = shortcutsService.keyboardBindings,
        _timezones = _loadTimezones(),
        selectedTimezone = timezoneService.timezone.asObservable() {
    dateTimeService.onChanged = updateDateTime;
    timezoneService.onChanged =
        (timezone) => runInAction(() => selectedTimezone.value = timezone);
  }

  @override
  Future<void> start() async {
    await Future.wait([
      dateTimeService.start(),
      timezoneService.start(),
    ]);
  }

  @override
  Future<void> stop() async {
    showAllSettings();
    await dateTimeService.stop();
    await timezoneService.stop();
    _dateTimeNow = null;
  }

  @override
  void dispose() {
    super.dispose();
    dateTimeService.dispose();
    timezoneService.dispose();
  }

  @override
  late final Action updateTimezone = (timezone) {
    selectedTimezone.value = timezone;
    timezoneService.timezone = timezone;
    settingsPage.value = SettingsPage.none;
  }.asAction();

  @override
  late final Action showAllSettings = () {
    settingsPage.value = SettingsPage.none;
  }.asAction();

  @override
  late final Action showShortcutSettings = () {
    settingsPage.value = SettingsPage.shortcuts;
  }.asAction();

  @override
  late final Action showTimezoneSettings = () {
    settingsPage.value = SettingsPage.timezone;
  }.asAction();

  Observable<DateTime>? _dateTimeNow;
  Observable<DateTime> get dateTimeNow =>
      _dateTimeNow ??= DateTime.now().asObservable();

  late final Action updateDateTime = () {
    dateTimeNow.value = DateTime.now();
  }.asAction();

  static List<String> _loadTimezones() {
    return File(kTimezonesFile).readAsLinesSync();
  }
}