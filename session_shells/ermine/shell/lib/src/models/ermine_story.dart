// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fidl_fuchsia_session/fidl_async.dart';
import 'package:fidl_fuchsia_ui_views/fidl_async.dart';
import 'package:flutter/material.dart';
import 'package:fuchsia_logger/logger.dart';
import 'package:fuchsia_scenic_flutter/child_view_connection.dart';
import 'package:fuchsia_services/services.dart';
import 'package:internationalization/strings.dart';
import 'package:uuid/uuid.dart';
import 'package:zircon/zircon.dart';

import '../utils/presenter.dart';
import '../utils/suggestion.dart';

typedef AlertHandler = void Function(String, [String, String]);

/// A function which can be used to launch the suggestion.
typedef LaunchSuggestion = Future<void> Function(
    Suggestion, ElementControllerProxy, AlertHandler);

/// Defines a class to represent a story in ermine.
class ErmineStory {
  final ValueChanged<ErmineStory> onDelete;
  final ValueChanged<ErmineStory> onChange;
  final String id;
  final String url;

  // An optional view controller which allows the story to communicate with the
  // process.
  ViewControllerImpl viewController;

  ViewRef viewRef;

  // An optional element controller which allows the story to communicate with
  // the element. This will only be available if ermine launched this process.
  ElementControllerProxy _elementController;

  /// Creates a launches an ermine story.
  @visibleForTesting
  ErmineStory({
    this.id,
    this.url,
    this.onDelete,
    this.onChange,
    String title,
  })  : nameNotifier = ValueNotifier(title),
        childViewConnectionNotifier = ValueNotifier(null),
        childViewAvailableNotifier = ValueNotifier(false);

  factory ErmineStory.fromSuggestion({
    Suggestion suggestion,
    ValueChanged<ErmineStory> onDelete,
    ValueChanged<ErmineStory> onChange,
    AlertHandler onAlert,
    LaunchSuggestion launchSuggestion,
  }) {
    final elementController = ElementControllerProxy();
    launchSuggestion ??= ErmineStory.launchSuggestion;
    launchSuggestion(suggestion, elementController, onAlert);
    return ErmineStory(
      id: suggestion.id,
      title: suggestion.title,
      url: suggestion.url,
      onDelete: onDelete,
      onChange: onChange,
    ).._elementController = elementController;
  }

  /// Creates an ermine story which was proposed from an external source.
  ///
  /// This method will not attempt to launch a story but will generate
  /// a random suggestion
  factory ErmineStory.fromExternalSource({
    ValueChanged<ErmineStory> onDelete,
    ValueChanged<ErmineStory> onChange,
    String id,
    String url,
    String name,
  }) {
    return ErmineStory(
      id: id ?? Uuid().v4(),
      onDelete: onDelete,
      onChange: onChange,
      title: name ?? url?.split('/')?.last,
      url: url,
    );
  }

  final ValueNotifier<String> nameNotifier;
  String get name => nameNotifier.value ?? id;
  set name(String value) => nameNotifier.value = value;

  ValueNotifier<bool> focusedNotifier = ValueNotifier(false);
  bool get focused => focusedNotifier.value;
  set focused(bool value) => focusedNotifier.value = value;

  final ValueNotifier<ChildViewConnection> childViewConnectionNotifier;
  final ValueNotifier<bool> childViewAvailableNotifier;
  ChildViewConnection get childViewConnection =>
      childViewConnectionNotifier.value;

  ValueNotifier<bool> fullscreenNotifier = ValueNotifier(false);
  bool get fullscreen => fullscreenNotifier.value;
  set fullscreen(bool value) => fullscreenNotifier.value = value;
  bool get isImmersive => fullscreenNotifier.value == true;

  void delete() {
    childViewConnectionNotifier.value?.dispose();
    childViewConnectionNotifier.value = null;
    childViewAvailableNotifier.value = null;
    viewController?.viewConnectionAvailable?.removeListener(onViewAvailable);
    viewController?.close();
    onDelete?.call(this);
    _elementController?.ctrl?.close();
  }

  /// Sets the focus state on this story.
  ///
  /// Also invokes [onChange] callback and request scenic to transfer input
  /// focus to the associated [viewRef].
  ///
  /// Takes an optional [ViewRefInstalledProxy] to allow passing in a mocked
  /// instance during test.
  void focus([ViewRefInstalledProxy viewRefInstalled]) {
    onChange?.call(this..focused = true);
    requestFocus(viewRefInstalled);
  }

  void maximize() => onChange?.call(this..fullscreen = true);

  void restore() => onChange?.call(this..fullscreen = false);

  static Future<void> launchSuggestion(Suggestion suggestion,
      ElementControllerProxy elementController, AlertHandler onAlert) async {
    final proxy = ElementManagerProxy();

    final incoming = Incoming.fromSvcPath()..connectToService(proxy);

    final annotations = Annotations(customAnnotations: [
      Annotation(
        key: ermineSuggestionIdKey,
        value: Value.withText(suggestion.id),
      ),
      Annotation(
        key: 'url',
        value: Value.withText(suggestion.url),
      ),
      if (suggestion.title.isNotEmpty)
        Annotation(
          key: 'name',
          value: Value.withText(suggestion.title),
        ),
    ]);

    final spec =
        ElementSpec(componentUrl: suggestion.url, annotations: annotations);

    await proxy
        .proposeElement(spec, elementController.ctrl.request())
        .catchError((err) {
      log.shout('$err: Failed to propose element <${suggestion.url}>');

      ErmineStory.handleError(err, suggestion.title, onAlert);
    });

    proxy.ctrl.close();
    await incoming.close();
  }

  @visibleForTesting
  static void handleError(
      dynamic error, String elementName, AlertHandler onAlert) {
    final title = Strings.proposeElementErrorTitle;
    final header = elementName;
    String description;
    switch (error) {
      case ProposeElementError.notFound:
        description = 'ElementProposeError.NOT_FOUND:\n'
            '${Strings.proposeElementErrorNotFoundDesc}'; //  'The component URL could not be resolved.'
        break;
      case ProposeElementError.rejected:
        description = 'ElementProposeError.REJECTED:\n'
            '${Strings.proposeElementErrorRejectedDesc}'; // 'The element spec may have been malformed.'
        break;
      default:
        description = error.toString();
        break;
    }
    onAlert?.call(title, header, description);
  }

  void presentView(
      ChildViewConnection connection, ViewRef viewRef, ViewControllerImpl vc) {
    childViewConnectionNotifier.value = connection;
    this.viewRef = viewRef;
    viewController = vc;
    viewController.viewConnectionAvailable.addListener(onViewAvailable);
    viewController?.didPresent();
  }

  void onViewAvailable() {
    childViewAvailableNotifier.value =
        viewController.viewConnectionAvailable.value;
    focus();
  }

  /// Requests focus to be transfered to this view given it's [viewRef].
  Future<void> requestFocus([ViewRefInstalledProxy viewRefInstalled]) async {
    // [requestFocus] is called for 'every' post render of ChildView widget,
    // even when that child view is not focused. Skip focusing those views here.
    if (childViewConnection == null || !focused) {
      return;
    }

    if (!await _isInstalled(viewRefInstalled)) {
      return;
    }

    if (!await _isConnected()) {
      return;
    }

    try {
      if (childViewConnection != null) {
        await childViewConnection.requestFocus();
      }
    } on Exception catch (e) {
      log.shout('Failed to request focus for $url: $e');
    } on Error catch (e) {
      log.shout('Failed to request focus for $url: $e');
    }
  }

  // Uses [ViewRefInstalled] service to check if child view is attached to the
  // scene graph.
  Future<bool> _isInstalled([ViewRefInstalledProxy viewRefInstalled]) async {
    try {
      final viewRefService = viewRefInstalled ?? ViewRefInstalledProxy();
      if (viewRefInstalled == null) {
        Incoming.fromSvcPath().connectToService(viewRefService);
      }
      final eventPair = viewRef.reference.duplicate(ZX.RIGHT_SAME_RIGHTS);
      assert(eventPair.isValid);
      await viewRefService.watch(ViewRef(reference: eventPair));
      return true;
    } on Exception catch (e) {
      log.shout('Failed to check if viewRef for $url is installed: $e');
    }
    return false;
  }

  // Returns true if child view is connected to the scene graph and rendering.
  Future<bool> _isConnected() async {
    final completer = Completer<bool>();
    void onChange() async {
      viewController.stateChanged.removeListener(onChange);
      if (!completer.isCompleted) {
        completer.complete(true);
      }
    }

    viewController.stateChanged.addListener(onChange);

    // Some views (for ex: terminal) may not fire state change. In that case we
    // fallback to timer.
    Timer(Duration(milliseconds: 300), () {
      if (!completer.isCompleted) {
        completer.complete(true);
      }
    });

    return completer.future;
  }
}
