// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_null_aware_operator
import 'package:ermine/src/states/app_state.dart';
import 'package:ermine/src/widgets/dialogs/dialog.dart';
import 'package:ermine/src/widgets/dialogs/password_prompt.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

/// Displays dialogs sequentially.
class Dialogs extends StatelessWidget {
  final AppState app;

  const Dialogs(this.app);

  @override
  Widget build(BuildContext context) {
    // Display queued up dialogs if none are being displayed currently.
    if (!Navigator.canPop(context)) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        _showAllDialogs(context);
      });
    }
    return Offstage();
  }

  // Shows all dialogs sequentially.
  void _showAllDialogs(BuildContext context, [int index = 0]) async {
    if (index >= app.dialogs.length) {
      runInAction(() {
        app.dialogs.clear();
        // Hiding overlays should restore focus to child views.
        app.hideOverlay();
      });
      return;
    }
    final _formState = GlobalKey<FormState>();
    bool validate() => _formState.currentState?.validate() ?? false;

    final dialog = app.dialogs[index];
    final result = await showDialog<String?>(
        context: context,
        builder: (context) {
          return Form(
            key: _formState,
            child: AlertDialog(
              title: _titleFromDialogInfo(dialog),
              content: _contentFromDialogInfo(dialog),
              actions: [
                for (final label in dialog.actions)
                  if (label == dialog.defaultAction)
                    ElevatedButton(
                      autofocus: dialog is AlertDialogInfo,
                      child: Text(label.toUpperCase()),
                      onPressed: () {
                        if (validate()) {
                          _formState.currentState?.save();
                          Navigator.pop(context, label);
                        }
                      },
                    )
                  else
                    OutlinedButton(
                      child: Text(label.toUpperCase()),
                      onPressed: () => Navigator.pop(context, label),
                    )
              ],
              insetPadding: EdgeInsets.symmetric(horizontal: 240),
              titlePadding: EdgeInsets.fromLTRB(40, 40, 40, 24),
              contentPadding: EdgeInsets.fromLTRB(40, 0, 40, 24),
              actionsPadding: EdgeInsets.only(right: 40, bottom: 24),
              titleTextStyle: Theme.of(context).textTheme.headline5,
            ),
          );
        });
    if (result != null) {
      dialog.onAction?.call(result);
    }
    dialog.onClose?.call();

    _showAllDialogs(context, index + 1);
  }

  Widget? _titleFromDialogInfo(DialogInfo info) {
    switch (info.runtimeType) {
      case AlertDialogInfo:
        return Text(info.title!);
      default:
        return null;
    }
  }

  Widget? _contentFromDialogInfo(DialogInfo info) {
    switch (info.runtimeType) {
      case AlertDialogInfo:
        final dialog = info as AlertDialogInfo;
        return (dialog.body != null) ? Text(dialog.body!) : null;
      case PasswordDialogInfo:
        final dialog = info as PasswordDialogInfo;
        return PasswordPrompt(dialog);
      default:
        return null;
    }
  }
}
