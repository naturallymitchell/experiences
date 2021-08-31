// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:internationalization/strings.dart';
import 'package:oobe/src/states/oobe_state.dart';

/// Defines a widget to configure software update channels.
class Channels extends StatelessWidget {
  final OobeState oobe;

  const Channels(this.oobe);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title.
          Text(
            Strings.oobeChannelTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headline3,
          ),

          // Description.
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(24),
            child: SizedBox(
              width: 600,
              child: Text(
                Strings.oobeChannelDesc,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1!
                    .copyWith(height: 1.55),
              ),
            ),
          ),

          // Channel list.
          Expanded(
            child: Observer(builder: (context) {
              final channels = oobe.channels;
              return oobe.updateChannelsAvailable
                  ? ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        SizedBox(width: 200),
                        ...[
                          for (int index = 0; index < channels.length; index++)
                            Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 76,
                              ),
                              width: 380,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                              ),
                              child: ListTile(
                                minVerticalPadding: 24,
                                leading: Radio<String>(
                                  value: oobe.currentChannel,
                                  groupValue: channels.elementAt(index),
                                  onChanged: (_) {},
                                ),
                                title: Text(
                                  channels.elementAt(index).toUpperCase(),
                                  style: Theme.of(context).textTheme.headline5,
                                ),
                                subtitle: Text(
                                  oobe.channelDescriptions[
                                          channels.elementAt(index)] ??
                                      channels.elementAt(index),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyText1!
                                      .copyWith(height: 1.55),
                                ),
                                selected: oobe.currentChannel ==
                                    channels.elementAt(index),
                                onTap: () => oobe.setCurrentChannel(
                                    channels.elementAt(index)),
                              ),
                            ),
                        ],
                        SizedBox(width: 200),
                      ],
                    )
                  : Center(child: CircularProgressIndicator());
            }),
          ),

          // Next button.
          FocusScope(
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(24),
              child: OutlinedButton(
                autofocus: true,
                onPressed: oobe.nextScreen,
                child: Text(Strings.next.toUpperCase()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
