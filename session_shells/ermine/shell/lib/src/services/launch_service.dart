// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl_fuchsia_session/fidl_async.dart';
import 'package:fuchsia_services/services.dart';

/// Defines a service to launch applications given their [url] using the
/// [ElementManager.proposeElement] API.
class LaunchService {
  Future<ElementControllerProxy> launch(String title, String url) async {
    final elementController = ElementControllerProxy();
    final proxy = ElementManagerProxy();

    final incoming = Incoming.fromSvcPath()..connectToService(proxy);

    final annotations = Annotations(customAnnotations: [
      Annotation(
        key: 'id',
        value: Value.withText('${DateTime.now().millisecondsSinceEpoch}'),
      ),
      Annotation(
        key: 'url',
        value: Value.withText(url),
      ),
      Annotation(
        key: 'name',
        value: Value.withText(title),
      ),
    ]);

    final spec = ElementSpec(componentUrl: url, annotations: annotations);
    await proxy.proposeElement(spec, elementController.ctrl.request());

    proxy.ctrl.close();
    await incoming.close();

    return elementController;
  }
}
