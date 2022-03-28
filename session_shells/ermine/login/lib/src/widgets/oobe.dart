// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:internationalization/strings.dart';
import 'package:login/src/states/oobe_state.dart';
import 'package:login/src/widgets/password.dart';
import 'package:login/src/widgets/ready.dart';
// TODO(fxbug.dev/73407): Skip data sharing screen until privacy policy is
// finalized.
// import 'package:login/src/widgets/channels.dart';
// import 'package:login/src/widgets/data_sharing.dart';
// import 'package:login/src/widgets/ssh_keys.dart';

/// Defines a widget that handles the OOBE flow.
class Oobe extends StatelessWidget {
  final OobeState oobe;

  const Oobe(this.oobe);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color.fromARGB(0xff, 0x0c, 0x0c, 0x0c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Fuchsia logo and welcome.
          Padding(
            padding: EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Fuchsia logo.
                Image(
                  image: AssetImage('images/Fuchsia-logo-2x.png'),
                  color: Theme.of(context).colorScheme.primary,
                  width: 24,
                  height: 24,
                ),
                SizedBox(width: 16),
                // Welcome text.
                Text(
                  Strings.fuchsiaWelcome,
                  style: Theme.of(context).textTheme.headline6,
                ),
              ],
            ),
          ),

          // Body: Oobe screens.
          Expanded(
            child: Observer(builder: (context) {
              switch (oobe.screen) {
                // TODO(fxbug.dev/73407): Skip data sharing screen until privacy
                // policy is finalized.
                // case OobeScreen.channel:
                //   return Channels(oobe);
                // case OobeScreen.dataSharing:
                //   return DataSharing(oobe);
                // case OobeScreen.sshKeys:
                //   return SshKeys(oobe);
                case OobeScreen.password:
                  return Password(oobe);
                case OobeScreen.done:
                  return Ready(oobe);
              }
            }),
          ),

          // Footer: progress dots.
          SizedBox(
            height: 68,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = OobeScreen.password.index;
                    index <= OobeScreen.done.index;
                    index++)
                  Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Observer(builder: (context) {
                      return Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          color:
                              index == oobe.screen.index ? Colors.white : null,
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
