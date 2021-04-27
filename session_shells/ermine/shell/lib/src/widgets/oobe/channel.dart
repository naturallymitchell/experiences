// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ermine_ui/ermine_ui.dart';
import 'package:fidl_fuchsia_update_channelcontrol/fidl_async.dart';
import 'package:flutter/material.dart';
import 'package:fuchsia_services/services.dart' show Incoming;
import 'package:internationalization/strings.dart';

import '../../utils/styles.dart';
import 'oobe_buttons.dart';
import 'oobe_header.dart';

/// Channel horizontal margin.
const double kChannelMargin = 12;

/// Channel right padding.
const double kChannelRightPadding = 24;

/// Channel bottom padding.
const double kChannelBottomPadding = 28;

/// Channel name top margin.
const double kChannelNameTopMargin = 11;

/// Channel name bottom margin.
const double kChannelNameBottomMargin = 8;

class Channel extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;
  final ChannelModel model;

  const Channel(
      {@required this.onBack, @required this.onNext, @required this.model});

  factory Channel.withSvcPath(VoidCallback onBack, VoidCallback onNext) {
    final control = ChannelControlProxy();
    Incoming.fromSvcPath().connectToService(control);
    final channelModel = ChannelModel(control: control);
    return Channel(onBack: onBack, onNext: onNext, model: channelModel);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      OobeHeader(Strings.oobeChannelTitle,
          [DescriptionModel(text: Strings.oobeChannelDesc)]),
      // Body.
      Expanded(
        child: Container(
          margin: EdgeInsets.symmetric(
              vertical: ErmineStyle.kOobeBodyVerticalMargins),
          child: FutureBuilder<List<String>>(
            future: model.channels,
            builder:
                (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
              if (snapshot.hasData) {
                List<String> channels = snapshot.data;
                if (!channels.contains(model.channel.value)) {
                  channels.add(model.channel.value);
                }
                return AnimatedBuilder(
                  animation: model.channel,
                  builder: (context, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (final channel in channels) _buildChannel(channel),
                    ],
                  ),
                );
              } else {
                return Text(
                  Strings.oobeLoadChannelError,
                  textAlign: TextAlign.center,
                  style: ErmineTextStyles.headline4,
                );
              }
            },
          ),
        ),
      ),
      OobeButtons([
        OobeButtonModel(Strings.back, onBack),
        OobeButtonModel(Strings.next, onNext),
      ]),
    ]);
  }

  Widget _buildChannel(String channel) => Expanded(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: kChannelMargin),
          padding: EdgeInsets.only(
              right: kChannelRightPadding, bottom: kChannelBottomPadding),
          decoration: BoxDecoration(
            border: Border.all(
              color: ErmineColors.grey100,
              width: 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                alignment: Alignment.topCenter,
                child: ErmineRadio<String>(
                    value: channel,
                    groupValue: model.channel.value,
                    onChanged: (String value) {
                      model.setCurrentChannel(value);
                    }),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Text name
                    Container(
                      padding: EdgeInsets.only(
                          top: kChannelNameTopMargin,
                          bottom: kChannelNameBottomMargin),
                      child: Text(
                        channel.toUpperCase(),
                        style: ErmineTextStyles.headline3,
                      ),
                    ),
                    // Text description
                    Container(
                      child: Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Text(
                            model.getDescription(channel),
                            style: ErmineTextStyles.headline4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class ChannelModel {
  final ChannelControlProxy control;

  ValueNotifier<String> channel = ValueNotifier('');

  Future<List<String>> channels;

  ChannelModel({this.control}) {
    loadCurrentChannel();
    channels = control.getTargetList();
  }

  void dispose() {
    control.ctrl.close();
  }

  Future<void> loadCurrentChannel() {
    return control.getTarget().then((name) {
      channel.value = name;
    });
  }

  Future<void> setCurrentChannel(String name) {
    control.setTarget(name);
    return loadCurrentChannel();
  }

  String getDescription(String channel) {
    String description = '';
    switch (channel) {
      case 'beta':
        description = Strings.oobeBetaChannelDesc;
        break;
      case 'devhost':
        description = Strings.oobeDevhostChannelDesc;
        break;
      case 'dogfood':
        description = Strings.oobeDogfoodChannelDesc;
        break;
      case 'stable':
        description = Strings.oobeStableChannelDesc;
        break;
      case 'test':
        description = Strings.oobeTestChannelDesc;
        break;
    }
    return description;
  }
}
