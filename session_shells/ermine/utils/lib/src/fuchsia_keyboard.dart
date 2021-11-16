// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Defines the mapping of Fuchsia keys to application [Intent]s.
///
/// This is needed because currently the key mapping for Fuchsia in Flutter
/// Framework is broken.
class FuchsiaKeyboard {
  // Fuchsia keyboard HID usage values are defined in (page 53):
  // https://www.usb.org/sites/default/files/documents/hut1_12v2.pdf

  static const int kHidUsagePageMask = 0x70000;
  static const int kFuchsiaKeyIdPlane = LogicalKeyboardKey.fuchsiaPlane;

  static const kEnter = LogicalKeyboardKey(40 | kFuchsiaKeyIdPlane);
  static const kBackspace = LogicalKeyboardKey(42 | kFuchsiaKeyIdPlane);
  static const kDelete = LogicalKeyboardKey(76 | kFuchsiaKeyIdPlane);
  static const kEscape = LogicalKeyboardKey(41 | kFuchsiaKeyIdPlane);
  static const kTab = LogicalKeyboardKey(43 | kFuchsiaKeyIdPlane);
  static const kArrowLeft = LogicalKeyboardKey(80 | kFuchsiaKeyIdPlane);
  static const kArrowRight = LogicalKeyboardKey(79 | kFuchsiaKeyIdPlane);
  static const kArrowDown = LogicalKeyboardKey(81 | kFuchsiaKeyIdPlane);
  static const kArrowUp = LogicalKeyboardKey(82 | kFuchsiaKeyIdPlane);
  static const kPageUp = LogicalKeyboardKey(75 | kFuchsiaKeyIdPlane);
  static const kPageDown = LogicalKeyboardKey(78 | kFuchsiaKeyIdPlane);

  static const Map<ShortcutActivator, Intent> defaultShortcuts =
      <ShortcutActivator, Intent>{
    // Activation
    SingleActivator(kEnter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),

    // Dismissal
    SingleActivator(kEscape): DismissIntent(),

    // Keyboard traversal.
    SingleActivator(kTab): NextFocusIntent(),
    SingleActivator(kTab, shift: true): PreviousFocusIntent(),
    SingleActivator(kArrowLeft):
        DirectionalFocusIntent(TraversalDirection.left),
    SingleActivator(kArrowRight):
        DirectionalFocusIntent(TraversalDirection.right),
    SingleActivator(kArrowDown):
        DirectionalFocusIntent(TraversalDirection.down),
    SingleActivator(kArrowUp): DirectionalFocusIntent(TraversalDirection.up),

    // Scrolling
    SingleActivator(kArrowUp, control: true):
        ScrollIntent(direction: AxisDirection.up),
    SingleActivator(kArrowDown, control: true):
        ScrollIntent(direction: AxisDirection.down),
    SingleActivator(kArrowLeft, control: true):
        ScrollIntent(direction: AxisDirection.left),
    SingleActivator(kArrowRight, control: true):
        ScrollIntent(direction: AxisDirection.right),
    SingleActivator(kPageUp): ScrollIntent(
        direction: AxisDirection.up, type: ScrollIncrementType.page),
    SingleActivator(kPageDown): ScrollIntent(
        direction: AxisDirection.down, type: ScrollIncrementType.page),
  };
}
