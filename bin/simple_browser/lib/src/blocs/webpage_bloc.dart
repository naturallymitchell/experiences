// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fuchsia_logger/logger.dart';
import 'package:fuchsia_scenic_flutter/fuchsia_view.dart'
    show FuchsiaViewConnection;
import '../models/webpage_action.dart';
import '../services/simple_browser_web_service.dart';
import '../utils/sanitize_url.dart';

enum PageType { empty, normal, error }

/// Business logic for the webpage.
/// Sinks:
///   WebPageAction: a browsing action - url request, prev/next page, etc.
/// Value Notifiers:
///   url: the current url.
///   forwardState: bool indicating whether forward action is available.
///   backState: bool indicating whether back action is available.
///   isLoadedState: bool indicating whether main document has fully loaded.
///   pageTitle: the current page title.
///   pageType: the current type of the page; either normal, error, or empty.
class WebPageBloc {
  final SimpleBrowserWebService webService;

  /// Used to present webpage in Flutter FuchsiaView
  FuchsiaViewConnection get fuchsiaViewConnection =>
      webService.fuchsiaViewConnection;

  ChangeNotifier get urlNotifier =>
      webService.navigationEventListener.urlNotifier;
  ChangeNotifier get forwardStateNotifier =>
      webService.navigationEventListener.forwardStateNotifier;
  ChangeNotifier get backStateNotifier =>
      webService.navigationEventListener.backStateNotifier;
  ChangeNotifier get isLoadedStateNotifier =>
      webService.navigationEventListener.isLoadedStateNotifier;
  ChangeNotifier get pageTitleNotifier =>
      webService.navigationEventListener.pageTitleNotifier;
  ChangeNotifier get pageTypeNotifier =>
      webService.navigationEventListener.pageTypeNotifier;

  String get url => webService.navigationEventListener.url;
  bool get forwardState => webService.navigationEventListener.forwardState;
  bool get backState => webService.navigationEventListener.backState;
  bool get isLoadedState => webService.navigationEventListener.isLoadedState;
  String? get pageTitle => webService.navigationEventListener.pageTitle;
  PageType get pageType => webService.navigationEventListener.pageType;
  // Sinks
  final _webPageActionController = StreamController<WebPageAction>();
  Sink<WebPageAction> get request => _webPageActionController.sink;

  // Constructors

  /// Creates a new [WebPageBloc] with a new page from [ContextProxy].
  ///
  /// A basic constructor for creating a brand-new tab.
  /// Can also be used for testing purposes and in this case,
  /// context parameter does not need to be set.
  WebPageBloc({
    required this.webService,
    String? homePage,
  }) {
    if (homePage != null) {
      _onWebPageActionChanged(NavigateToAction(url: homePage));
    }

    /// Begins handling action requests
    _webPageActionController.stream.listen(_onWebPageActionChanged);
  }

  void dispose() {
    webService.dispose();
    _webPageActionController.close();
  }

  Future<void> _onWebPageActionChanged(WebPageAction action) async {
    switch (action.op) {
      case WebPageActionType.navigateTo:
        final navigate = action as NavigateToAction;
        await webService.loadUrl(
          sanitizeUrl(navigate.url),
        );
        break;
      case WebPageActionType.goBack:
        await webService.goBack();
        break;
      case WebPageActionType.goForward:
        await webService.goForward();
        break;
      case WebPageActionType.refresh:
        await webService.refresh();
        break;
      case WebPageActionType.setFocus:
        try {
          await fuchsiaViewConnection.requestFocus();
        } on Exception catch (e) {
          log.warning('Failed to set focus on the current web view: $e');
        }
        break;
    }
  }
}
