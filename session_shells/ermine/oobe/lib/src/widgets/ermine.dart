// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:fuchsia_scenic_flutter/fuchsia_view.dart';
import 'package:oobe/src/states/oobe_state.dart';

/// Defines a widget that hosts Ermine shell's root view.
class ErmineApp extends StatelessWidget {
  final OobeState oobe;

  const ErmineApp(this.oobe);

  @override
  Widget build(BuildContext context) {
    return FuchsiaView(controller: oobe.ermineViewConnection);
  }
}
