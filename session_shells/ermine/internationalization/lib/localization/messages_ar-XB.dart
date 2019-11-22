// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ar_XB locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';
import 'dart:convert';
import 'messages_all.dart' show evaluateJsonTemplate;

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'ar_XB';

  String evaluateMessage(translation, List<dynamic> args) {
    return evaluateJsonTemplate(translation, args);
  }
  var _messages;
  get messages => _messages ??=
      const JsonDecoder().convert(messageText) as Map<String, dynamic>;
  static final messageText = r'''
{"ask":"‏‮ASK‬‏","auto":"‏‮Auto‬‏","back":"‏‮Back‬‏","batt":"‏‮Batt‬‏","battery":"‏‮Battery‬‏","bluetooth":"‏‮Bluetooth‬‏","brightness":"‏‮Brightness‬‏","browser":"‏‮Browser‬‏","cancel":"‏‮Cancel‬‏","chrome":"‏‮Chrome‬‏","cpu":"‏‮CPU‬‏","date":"‏‮Date‬‏","dateTime":"‏‮Date‬‏ & ‏‮Time‬‏","disconnect":"‏‮DISCONNECT‬‏","done":"‏‮Done‬‏","fps":"‏‮FPS‬‏","ide":"‏‮IDE‬‏","logout":"‏‮Logout‬‏","max":"‏‮Max‬‏","mem":"‏‮MEM‬‏","memory":"‏‮Memory‬‏","min":"‏‮Min‬‏","mockWirelessNetwork":"‏‮Wireless‬‏_‏‮Network‬‏","music":"‏‮Music‬‏","name":"‏‮Name‬‏","nameThisStory":"‏‮Name‬‏ ‏‮this‬‏ ‏‮story‬‏","network":"‏‮Network‬‏","numThreads":["Intl.plural",0,[0," ‏‮THR‬‏"],[0," ‏‮THR‬‏"],[0," ‏‮THR‬‏"],[0," ‏‮THR‬‏"],[0," ‏‮THR‬‏"],[0," ‏‮THR‬‏"]],"openPackage":["‏‮open‬‏ ",0],"overview":"‏‮Overview‬‏","pause":"‏‮Pause‬‏","pid":"‏‮PID‬‏","powerOff":"‏‮Power‬‏ ‏‮Off‬‏","recents":"‏‮Recents‬‏","restart":"‏‮Restart‬‏","runningTasks":["Intl.plural",0,[0," ‏‮RUNNING‬‏"],[0," ‏‮RUNNING‬‏"],[0," ‏‮RUNNING‬‏"],[0," ‏‮RUNNING‬‏"],[0," ‏‮RUNNING‬‏"],[0," ‏‮RUNNING‬‏"]],"settings":"‏‮Settings‬‏","shutdown":"‏‮Shutdown‬‏","signalStrong":"‏‮Strong‬‏ ‏‮Signal‬‏","skip":"‏‮Skip‬‏","sleep":"‏‮Sleep‬‏","sunny":"‏‮Sunny‬‏","tasks":"‏‮TASKS‬‏","timezone":"‏‮Timezone‬‏","topProcesses":"‏‮Top‬‏ ‏‮Processes‬‏","totalTasks":["Intl.plural",0,0,0,0,0,0,0],"typeToAsk":"‏‮TYPE‬‏ ‏‮TO‬‏ ‏‮ASK‬‏","unit":"‏‮Unit‬‏","volume":"‏‮Volume‬‏","weather":"‏‮Weather‬‏","wireless":"‏‮Wireless‬‏"}''';
}