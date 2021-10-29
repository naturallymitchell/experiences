// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:fuchsia_scenic_flutter/fuchsia_view.dart';
import 'package:oobe/src/services/channel_service.dart';
import 'package:oobe/src/services/device_service.dart';
import 'package:oobe/src/services/privacy_consent_service.dart';
import 'package:oobe/src/services/shell_service.dart';
import 'package:oobe/src/services/ssh_keys_service.dart';
import 'package:oobe/src/states/oobe_state_impl.dart';

/// The oobe screens the user navigates through.
// TODO(fxbug.dev/73407): Skip data sharing screen until privacy policy is
// finalized.
enum OobeScreen { channel, /* dataSharing, */ sshKeys, password, done }

/// The screens the user navigates through to add SSH keys.
enum SshScreen { add, confirm, error, exit }

/// The ssh key import methods.
enum SshImport { github, manual }

/// Defines the state of an application view.
abstract class OobeState {
  Locale? get locale;
  OobeScreen get screen;
  bool get updateChannelsAvailable;
  String get currentChannel;
  List<String> get channels;
  Map<String, String> get channelDescriptions;
  SshScreen get sshScreen;
  String get sshKeyTitle;
  String get sshKeyDescription;
  SshImport get importMethod;
  List<String> get sshKeys;
  abstract int sshKeyIndex;
  bool get privacyVisible;
  bool get launchOobe;
  bool get loginDone;

  FuchsiaViewConnection get ermineViewConnection;
  String get privacyPolicy;

  void setCurrentChannel(String channel);
  void nextScreen();
  void prevScreen();
  void agree();
  void disagree();
  void showPrivacy();
  void hidePrivacy();
  void sshImportMethod(SshImport? method);
  void sshBackScreen();
  void sshAdd(String userNameOrKey);
  void setPassword(String password);
  void login(String password);
  void skip();
  void finish();
  void shutdown();

  factory OobeState.fromEnv() {
    return OobeStateImpl(
      deviceService: DeviceService(),
      shellService: ShellService(),
      channelService: ChannelService(),
      sshKeysService: SshKeysService(),
      privacyConsentService: PrivacyConsentService(),
    ) as OobeState;
  }

  void dispose();
}
