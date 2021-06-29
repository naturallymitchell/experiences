// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ermine/src/states/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:fuchsia_scenic_flutter/fuchsia_view.dart';

/// Defines a widget to display an app's view fullscreen.
class AppView extends StatelessWidget {
  final AppState state;

  const AppView(this.state);

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final view = state.topView.value;
      return FuchsiaView(
        controller: view.viewConnection,
        hitTestable: view.hitTestable.value,
        focusable: view.focusable.value,
      );
    });
  }
}
