// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl/fidl.dart' show InterfaceHandle;
import 'package:fidl_fuchsia_io/fidl_async.dart' as fidl_io;
import 'package:fidl_fuchsia_web/fidl_async.dart' as web;
import 'package:fuchsia_services/services.dart' show Incoming;
import 'package:zircon/zircon.dart';

/// Creates a web context for creating new web frames
web.ContextProxy createWebContext() {
  final context = web.ContextProxy();
  final contextProvider = web.ContextProviderProxy();
  final contextProviderProxyRequest = contextProvider.ctrl.request();
  Incoming.fromSvcPath()
    ..connectToServiceByNameWithChannel(contextProvider.ctrl.$serviceName,
        contextProviderProxyRequest.passChannel())
    ..close();
  final channel = Channel.fromFile('/svc');
  final webFeatures = web.ContextFeatureFlags.network |
      web.ContextFeatureFlags.audio |
      web.ContextFeatureFlags.hardwareVideoDecoder |
      web.ContextFeatureFlags.keyboard |
      web.ContextFeatureFlags.vulkan;
  final web.CreateContextParams params = web.CreateContextParams(
      serviceDirectory: InterfaceHandle<fidl_io.Directory>(channel),
      features: webFeatures);
  contextProvider.create(params, context.ctrl.request());
  contextProvider.ctrl.close();

  return context;
}
