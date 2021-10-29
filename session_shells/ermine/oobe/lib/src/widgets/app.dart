// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:ermine_utils/ermine_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:internationalization/localizations_delegate.dart'
    as localizations;
import 'package:internationalization/supported_locales.dart'
    as supported_locales;
import 'package:intl/intl.dart';
import 'package:oobe/src/states/oobe_state.dart';
import 'package:oobe/src/widgets/ermine.dart';
// TODO(http://fxb/81598): Uncomment once login  is ready.
// import 'package:oobe/src/widgets/login.dart';
import 'package:oobe/src/widgets/oobe.dart';

class OobeApp extends StatelessWidget {
  final OobeState oobe;

  const OobeApp(this.oobe);

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final locale = oobe.locale;
      if (locale == null) {
        return Offstage();
      }
      Intl.defaultLocale = locale.toString();
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
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
              return WidgetFactory.create(() => oobe.launchOobe
                  ? Oobe(oobe, onFinish: oobe.finish)
                  // TODO(http://fxb/81598): Uncomment once login  is ready.
                  // : Login(oobe));
                  : ErmineApp(oobe));
            }),
          );
        }),
      );
    });
  }
}
