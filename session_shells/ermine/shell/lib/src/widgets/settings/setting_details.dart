// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Defines a scaffold widget to displaying details of an individual setting.
class SettingDetails extends StatelessWidget {
  final VoidCallback onBack;
  final String title;
  final Widget? trailing;
  final Widget? child;

  const SettingDetails({
    required this.onBack,
    required this.title,
    this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      child: Column(
        children: [
          AppBar(
            elevation: 0,
            leading: IconButton(
              autofocus: true,
              onPressed: onBack,
              icon: Icon(Icons.arrow_back),
            ),
            title: Text(
              title,
              style: Theme.of(context).textTheme.headline6,
            ),
            actions: trailing == null ? null : [trailing!],
          ),
          Expanded(
            child: Material(
              type: MaterialType.canvas,
              color: Theme.of(context).bottomAppBarColor,
              shape: Border(
                  top: BorderSide(color: Theme.of(context).indicatorColor)),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
