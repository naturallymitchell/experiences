// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ermine/src/states/app_state.dart';
import 'package:ermine/src/widgets/settings/shortcut_settings.dart';
import 'package:ermine/src/widgets/settings/timezone_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:internationalization/strings.dart';

/// Defines a widget to display status and update system settings.
class QuickSettings extends StatelessWidget {
  final AppState appState;

  const QuickSettings(this.appState);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        height: MediaQuery.of(context).size.height / 2,
        decoration: BoxDecoration(
          border:
              Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Observer(builder: (_) {
          final state = appState.settingsState;
          return ListTileTheme(
            iconColor: Theme.of(context).colorScheme.onSurface,
            selectedColor: Theme.of(context).colorScheme.onPrimary,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _ListSettings(appState),
                if (state.shortcutsPageVisible.value) ShortcutSettings(state),
                if (state.timezonesPageVisible.value)
                  TimezoneSettings(
                      state: state,
                      onChange: (tz) => state.updateTimezone([tz])),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ListSettings extends StatelessWidget {
  final AppState appState;

  const _ListSettings(this.appState);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Restart, Shutdown and DateTime.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Restart button.
                OutlinedButton.icon(
                  onPressed: appState.restart,
                  icon: Icon(Icons.restart_alt),
                  label: Text(Strings.restart.toUpperCase()),
                ),
                SizedBox(width: 8),

                // Power off button.
                OutlinedButton.icon(
                  onPressed: appState.shutdown,
                  icon: Icon(Icons.power_settings_new_rounded),
                  label: Text(Strings.shutdown.toUpperCase()),
                ),

                Spacer(),
                // Date time.
                Observer(builder: (context) {
                  return Text(
                    appState.settingsState.dateTime.value,
                    style: Theme.of(context).textTheme.bodyText1,
                  );
                }),
              ],
            ),
          ),

          SizedBox(height: 24),

          Expanded(
            child: ListView(
              // TODO(fxb/79721): Re-order tiles everytime a disabled feature is
              // implemented.
              children: [
                // Switch Theme
                SwitchListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 24),
                  secondary: Icon(Icons.dark_mode),
                  title: Text(Strings.darkMode),
                  value: appState.hasDarkTheme.value,
                  onChanged: (value) => appState.setTheme([value]),
                ),
                // Keyboard shortcuts
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(Icons.shortcut_outlined),
                  title: Text(Strings.shortcuts),
                  onTap: appState.settingsState.showShortcutSettings,
                ),
                // Timezone
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(Icons.schedule),
                  title: Text(Strings.timezone),
                  trailing: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        appState.settingsState.selectedTimezone.value
                            // Remove '_' from city names.
                            .replaceAll('_', ' ')
                            .replaceAll('/', ' / '),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary),
                      ),
                      Icon(Icons.arrow_right),
                    ],
                  ),
                  onTap: appState.settingsState.showTimezoneSettings,
                ),
                // Brightness
                Observer(builder: (_) {
                  return ListTile(
                    enabled: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 24),
                    leading: Icon(appState.settingsState.brightnessIcon.value),
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(Strings.brightness),
                        Expanded(
                          child: Slider(
                            value:
                                appState.settingsState.brightnessLevel.value ??
                                    1,
                            onChanged: (double value) {
                              appState.settingsState
                                  .setBrightnessLevel([value]);
                            },
                          ),
                        ),
                      ],
                    ),
                    trailing: OutlinedButton(
                      onPressed: appState.settingsState.brightnessAuto.value ==
                              true
                          ? null
                          : () =>
                              appState.settingsState.setBrightnessAuto([true]),
                      child: Text(Strings.auto.toUpperCase()),
                    ),
                  );
                }),
                // Feedback
                ListTile(
                  enabled: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(Icons.feedback_outlined),
                  title: Text(Strings.feedback),
                  trailing: OutlinedButton(
                    onPressed: appState.launchFeedback,
                    child: Text(Strings.open.toUpperCase()),
                  ),
                ),
                // Open Source
                ListTile(
                  enabled: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(Icons.info_outline),
                  title: Text(Strings.openSource),
                  trailing: OutlinedButton(
                    onPressed: appState.launchLicense,
                    child: Text(Strings.open.toUpperCase()),
                  ),
                ),
                // Features not implemented yet.
                // Volume
                ListTile(
                  enabled: false,
                  contentPadding: EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(Icons.volume_up),
                  title: Text(Strings.volume),
                ),
                // Wi-Fi
                ListTile(
                  enabled: false,
                  contentPadding: EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(Icons.wifi),
                  title: Text(Strings.wifi),
                  trailing: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text('not-implemented'),
                      Icon(Icons.arrow_right),
                    ],
                  ),
                ),
                // Bluetooth
                ListTile(
                  enabled: false,
                  contentPadding: EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(Icons.bluetooth_connected),
                  title: Text(Strings.bluetooth),
                ),
                // Channel
                ListTile(
                  enabled: false,
                  contentPadding: EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(Icons.cloud_download),
                  title: Text(Strings.channel),
                ),
                // Keyboard Input
                ListTile(
                  enabled: false,
                  contentPadding: EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(Icons.keyboard_outlined),
                  title: Text(Strings.keyboard),
                ),
                // Language
                ListTile(
                  enabled: false,
                  contentPadding: EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(Icons.language),
                  title: Text(Strings.language),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
