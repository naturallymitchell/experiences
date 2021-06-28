// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart' hide AppBar;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:internationalization/localizations_delegate.dart'
    as localizations;
import 'package:internationalization/supported_locales.dart'
    as supported_locales;
import 'package:intl/intl.dart';

import 'package:next/src/states/app_state.dart';
import 'package:next/src/utils/fuchsia_keyboard.dart';
import 'package:next/src/utils/widget_factory.dart';
import 'package:next/src/widgets/app_view.dart';
import 'package:next/src/widgets/oobe.dart';
import 'package:next/src/widgets/overlays.dart';

/// Builds the top level application widget that reacts to locale changes.
class App extends StatelessWidget {
  final AppState app;

  const App(this.app);

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final locale = app.localeStream.value;
      if (locale == null) {
        return Offstage();
      }
      Intl.defaultLocale = locale.toString();
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: app.theme.value,
        locale: locale,
        localizationsDelegates: [
          localizations.delegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: supported_locales.locales,
        shortcuts: FuchsiaKeyboard.defaultShortcuts,
        scrollBehavior: MaterialScrollBehavior().copyWith(
          dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
        ),
        home: Builder(builder: (context) {
          FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.alwaysTraditional;
          return Material(
            type: MaterialType.canvas,
            child: Observer(builder: (_) {
              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  // Show fullscreen top view.
                  if (app.views.isNotEmpty)
                    WidgetFactory.create(() => AppView(app)),

                  // Show scrim and overlay layers if an overlay is visible.
                  if (app.overlaysVisible.value)
                    WidgetFactory.create(() => Overlays(app)),

                  // Show OOBE view for first-time configuration.
                  if (app.oobeVisible.value)
                    WidgetFactory.create(() => Oobe(
                          app.oobeState,
                          onFinish: app.oobeFinished,
                        )),
                ],
              );
            }),
          );
        }),
      );
    });
  }
}
