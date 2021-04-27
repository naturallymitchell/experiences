// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is an L10N developer experience study fragment.
// Let's see how it works when you offload all strings to a file.

// The Intl.message texts have been offloaded to a separate file so as to
// minimize the amount of code needed to be exported for localization.
// While the individual static String get messages have been left in their original form,
// the case-ness of the text is part of the presentation so should probably be
// handled in the view code.

import 'package:intl/intl.dart';

/// Provides access to localized strings used in Ermine code.
class Strings {
  static final Strings instance = Strings._internal();
  factory Strings() => instance;
  Strings._internal();

  static String get brightness => Intl.message(
        'Brightness',
        name: 'brightness',
        desc: 'The label for the screen brightness settings widget',
      );

  static String get cancel => Intl.message(
        'Cancel',
        name: 'cancel',
        desc: 'The label for canceling an offered command',
      );

  static String get done => Intl.message(
        'Done',
        name: 'done',
        desc: 'The label for saying we are done with a command',
      );

  static String get sleep => Intl.message(
        'Sleep',
        name: 'sleep',
        desc: 'The label for the sleep settings widget',
      );

  static String get restart => Intl.message(
        'Restart',
        name: 'restart',
        desc: 'The label for the restart button',
      );

  static String get powerOff => Intl.message(
        'Power Off',
        name: 'powerOff',
        desc: 'The label for the restart button',
      );

  static String get settings => Intl.message(
        'Settings',
        name: 'settings',
        desc: 'The label for the settings button',
      );

  static String get volume => Intl.message(
        'Volume',
        name: 'volume',
        desc: 'The label for the settings button',
      );

  static String get min => Intl.message(
        'Min',
        name: 'min',
        desc: 'The short label for "minimal" label for the volume button',
      );

  static String get max => Intl.message(
        'Max',
        name: 'max',
        desc: 'The shortened label for "maximal" label for the volume button',
      );

  static String get music => Intl.message(
        'Music',
        name: 'music',
        desc: 'The label used for the music button',
      );

  static String get back => Intl.message(
        'Back',
        name: 'back',
        desc: 'The label for the "Back" button',
      );

  static String get pause => Intl.message(
        'Pause',
        name: 'pause',
        desc: 'The label for the "Pause" button',
      );

  static String get skip => Intl.message(
        'Skip',
        name: 'skip',
        desc: 'The label for the "Skip" button',
      );

  static String get topProcesses => Intl.message(
        'Top Processes',
        name: 'topProcesses',
        desc: 'The label for the "Top processes" label',
      );

  static String get shutdown => Intl.message(
        'Shutdown',
        name: 'shutdown',
        desc: 'The label for the "System shutdown" label',
      );

  static String get memory => Intl.message(
        'Memory',
        name: 'memory',
        desc: 'The label for the "memory" label',
      );

  static String get cpu => Intl.message(
        'CPU',
        name: 'cpu',
        desc: 'The short name for the "Central Processing Unit" label',
      );

  static String get mem => Intl.message(
        'MEM',
        name: 'mem',
        desc: 'The short name for the "Memory" label',
      );

  static String get ide => Intl.message(
        'IDE',
        name: 'ide',
        desc:
            'The short name for the "Integrated Development Environment" label',
      );

  static String get chrome => Intl.message(
        'Chrome',
        name: 'chrome',
        desc: 'The short name for the "Google Chrome" browser',
      );

  static String get pid => Intl.message(
        'PID',
        name: 'pid',
        desc: 'The short name for the "Process identifier" label',
      );

  static String get tasks => Intl.message(
        'TASKS',
        name: 'tasks',
        desc: 'The short name for the "Tasks" label',
      );

  static String get weather => Intl.message(
        'Weather',
        name: 'weather',
        desc: 'The short name for the "Weather" label',
      );

  static String get unit => Intl.message(
        'Unit',
        name: 'unit',
        desc: 'The short name for the unit of measurement',
      );

  static String get date => Intl.message(
        'Date',
        name: 'date',
        desc: 'The short name for the "date" label',
      );

  static String get dateTime => Intl.message(
        'Date & Time',
        name: 'dateTime',
        desc: 'The short name for the "date & time" label',
      );

  static String get timezone => Intl.message(
        'Timezone',
        name: 'timezone',
        desc: 'The short name for the "timezone" label',
      );

  static String get network => Intl.message(
        'Network',
        name: 'network',
        desc: 'The short name for the "network" label',
      );

  static String get fps => Intl.message(
        'FPS',
        name: 'fps',
        desc: 'The short name for the "Frames per Second" label',
      );

  static String get batt => Intl.message(
        'Batt',
        name: 'batt',
        desc: 'The short name for the "Battery level" label',
      );

  static String get battery => Intl.message(
        'Battery',
        name: 'battery',
        desc: 'The long name for the "Battery level" label',
      );

  static String get wireless => Intl.message(
        'Wireless',
        name: 'wireless',
        desc: 'The short name for the "Wireless network" label',
      );

  static String get signalStrong => Intl.message(
        'Strong Signal',
        name: 'signalStrong',
        desc: 'The short name for the "Strong signal" label',
      );

  static String get sunny => Intl.message(
        'Sunny',
        name: 'sunny',
        desc: 'The short name for the "Weather is sunny" label',
      );

  static String runningTasks(int numTasks) => Intl.plural(
        numTasks,
        zero: '$numTasks RUNNING',
        one: '$numTasks RUNNING',
        other: '$numTasks RUNNING',
        name: 'runningTasks',
        args: [numTasks],
        desc: 'How many tasks are currently running',
        examples: const {'numTasks': 42},
      );

  static String totalTasks(int numTasks) => Intl.plural(
        numTasks,
        zero: '$numTasks',
        one: '$numTasks',
        other: '$numTasks',
        name: 'totalTasks',
        args: [numTasks],
        desc: 'How many tasks are currently running',
        examples: const {'numTasks': 42},
      );

  static String numThreads(int numThreads) => Intl.plural(
        numThreads,
        zero: '$numThreads THR',
        one: '$numThreads THR',
        other: '$numThreads THR',
        name: 'numThreads',
        args: [numThreads],
        desc: 'How many threads are currently there, short label',
        examples: const {'numThreads': 42},
      );

  static String openPackage(String packageName) => Intl.message(
        'open $packageName',
        name: 'openPackage',
        desc: 'Open an application with supplied package name',
        args: [packageName],
        examples: const {'packageName': 'simple_browser'},
      );

  static String get name => Intl.message(
        'Name',
        name: 'name',
        desc: 'A generic label for a name, sentence case.',
      );

  static String get ask => Intl.message(
        'ASK',
        name: 'ask',
        desc: 'A generic short label for "query", sentence case.',
      );

  static String get typeToAsk => Intl.message(
        'TYPE TO ASK',
        name: 'typeToAsk',
        desc: 'Shown in the ask text entry box in Ermine shell',
      );

  static String get overview => Intl.message(
        'Overview',
        name: 'overview',
        desc: 'Shown in top bar on the Ermine shell',
      );

  static String get recents => Intl.message(
        'Recents',
        name: 'recents',
        desc: 'A list of recent apps',
      );

  static String get browser => Intl.message(
        'Browser',
        name: 'browser',
        desc: 'A button to invoke a browser with',
      );

  static String get auto => Intl.message(
        'Auto',
        name: 'auto',
        desc: 'A shorthand for "automatic" setting.',
      );

  static String get mockWirelessNetwork => Intl.message(
        'Wireless_Network',
        name: 'mockWirelessNetwork',
        desc:
            'A mock label for a wireless network name that the device is connected to',
      );

  static String get nameThisStory => Intl.message(
        'Name this story',
        name: 'nameThisStory',
        desc:
            'A hint appearing in a window for naming a story. This text should not include padding, but now it does.',
      );

  static String get bluetooth => Intl.message(
        'Bluetooth',
        name: 'bluetooth',
        desc: 'The label for the bluetooth settings widget',
      );

  static String get logout => Intl.message(
        'Logout',
        name: 'logout',
        desc: 'The label for logout button.',
      );

  static String get disconnect => Intl.message(
        'Disconnect',
        name: 'disconnect',
        desc: 'The label for "disconnect" button.',
      );

  static String get channel => Intl.message(
        'Channel',
        name: 'channel',
        desc: 'The short name for the "channel" label',
      );

  static String get proposeElementErrorTitle => Intl.message(
        'An error occurred while launching',
        name: 'proposeElementErrorTitle',
        desc: 'The title displayed in the propose element error alert dialog',
      );

  static String get proposeElementErrorNotFoundDesc => Intl.message(
        'The component URL could not be resolved.',
        name: 'proposeElementErrorNotFoundDescription',
        desc: 'The description displayed in the alert dialog handling '
            'ProposeElementError.NOT_FOUND',
      );

  static String get proposeElementErrorRejectedDesc => Intl.message(
        'The element spec may have been malformed.',
        name: 'proposeElementErrorRejectedDescription',
        desc: 'The description displayed in the alert dialog handling '
            'ProposeElementError.REJECTED',
      );

  static String get presentViewErrorTitle => Intl.message(
        'An error occurred opening the view.',
        name: 'presentViewErrorTitle',
        desc: 'The title displayed in the present view error alert dialog',
      );

  static String get presentViewErrorDesc => Intl.message(
        'The provided ViewSpec is malformed.',
        name: 'presentViewErrorDescription',
        desc: 'The description displayed in the alert dialog handling '
            'ViewControllerEpitaph.INVALID_VIEW_SPEC',
      );

  static String get fuchsiaWelcome => Intl.message(
        'Welcome to Fuchsia',
        name: 'fuchsiaWelcome',
        desc:
            'A welcome to Fuchsia message shown during the setup of a newly installed system',
      );

  static String get oobeChannelTitle => Intl.message(
        'Select an OTA channel',
        name: 'oobeChannelTitle',
        desc: 'The title displayed for OTA channel selection in the OOBE',
      );

  static String get oobeChannelDesc => Intl.message(
        'Fuchsia will get updates from the channel of your choice. It will not get updated if you skip this step.',
        name: 'oobeChannelDesc',
        desc:
            'The description displayed for selecting an OTA channel in the OOBE',
      );

  static String get oobeBetaChannelDesc => Intl.message(
        'A branch promoted on a weekly basis from dogfood or test as assessed by our manual testers and release management',
        name: 'oobeBetaChannelDesc',
        desc: 'The description displayed for the "Beta" update channel',
      );

  static String get oobeDevhostChannelDesc => Intl.message(
        'Receive updates from your local machine.',
        name: 'oobeDevhostChannelDesc',
        desc: 'The description displayed for the "Devhost" update channel',
      );

  static String get oobeDogfoodChannelDesc => Intl.message(
        'A branch promoted on a daily basis from the most recent test version that passed the entry criteria for dogfood as assessed by our manual testers and release management.',
        name: 'oobeDogfoodChannelDesc',
        desc: 'The description displayed for the "Dogfood" update channel',
      );

  static String get oobeStableChannelDesc => Intl.message(
        'A branch promoted on a six-weekly basis from beta.',
        name: 'oobeStableChannelDesc',
        desc: 'The description displayed for the "Stable" update channel',
      );

  static String get oobeTestChannelDesc => Intl.message(
        'A branch auto-promoted from the latest green build on master and auto-pushed to all test channels 4 times per day, Sunday (to account for non-MTV timezones) through Friday. It is used by the manual testers to validate the state of the tree, and by brave team members who want to test the most raw and cutting-edge builds.',
        name: 'oobeTestChannelDesc',
        desc: 'The description displayed for the "Test" update channel',
      );

  static String get oobeLoadChannelError => Intl.message(
        'ERROR: Could not load channels\nThe OTA channel can be selected later from settings menu.',
        name: 'oobeLoadChannelError',
        desc:
            'The message displayed when the list of update channels cannot be loaded.',
      );

  static String get dataSharingTitle => Intl.message(
        'Send Usage & Diagnostics Data to Google',
        name: 'dataSharingTitle',
        desc:
            'The title displayed for choosing whether to consent to send usage and diagnostics data to Google in the OOBE',
      );

  static String get dataSharingDesc => Intl.message(
        'We will use the information you give to us to help address technical issues and to improve our services, subject to our privacy policy. You can change this set-up at anytime later in Settings.',
        name: 'dataSharingDesc',
        desc:
            'The description of what is being agreed to when choosing to send usage and diagnostics data to Google in the OOBE',
      );

  static String get oobeSshKeysTitle => Intl.message(
        'Add Your SSH Key',
        name: 'oobeSshKeysTitle',
        desc: 'The title displayed for adding an SSH key in the OOBE',
      );

  static String get oobeSshKeysDesc => Intl.message(
        'Register your SSH key either by pulling from your Gitbub account or by adding manually.',
        name: 'oobeSshKeysDesc',
        desc: 'The description displayed of adding an SSH key in the OOBE',
      );

  static String get next => Intl.message(
        'Next',
        name: 'next',
        desc: 'The label for the "next" button.',
      );
}
