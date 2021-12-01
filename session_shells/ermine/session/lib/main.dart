// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_component/fidl_async.dart';
import 'package:fidl_fuchsia_component_decl/fidl_async.dart';
import 'package:fidl_fuchsia_identity_account/fidl_async.dart';
import 'package:fidl_fuchsia_io/fidl_async.dart';
import 'package:fidl_fuchsia_session_scene/fidl_async.dart';
import 'package:fidl_fuchsia_ui_app/fidl_async.dart';
import 'package:fidl_fuchsia_ui_focus/fidl_async.dart';
import 'package:fidl_fuchsia_ui_keyboard_focus/fidl_async.dart';
import 'package:fidl_fuchsia_ui_shortcut/fidl_async.dart' as shortcut;
import 'package:fidl_fuchsia_ui_views/fidl_async.dart';
import 'package:fuchsia_logger/logger.dart';
import 'package:fuchsia_services/services.dart';
import 'package:fuchsia_vfs/vfs.dart';
import 'package:zircon/zircon.dart';

const kLoginShellName = 'login_shell';
const kAccountName = 'created_by_session';
const kAccountPassword = '';
const kAccountDirectory = 'account_data';

void main(List args) async {
  setupLogger(name: 'workstation_session');
  log.info('Setting up workstation session');

  try {
    // Connect to the Realm.
    final realm = RealmProxy();
    Incoming.fromSvcPath().connectToService(realm);

    // Get the login shell's exposed /svc directory.
    final exposedDir = DirectoryProxy();
    await realm.openExposedDir(
        ChildRef(name: kLoginShellName), exposedDir.ctrl.request());

    // Get the login shell's view provider.
    final viewProvider = ViewProviderProxy();
    Incoming.withDirectory(exposedDir).connectToService(viewProvider);

    // Set the login shell's view as the root view.
    final sceneManager = ManagerProxy();
    Incoming.fromSvcPath().connectToService(sceneManager);
    final viewRef = await sceneManager.setRootView(viewProvider.ctrl.unbind());

    // Wait for the view to be attached to the scene.
    final viewRefInstalled = ViewRefInstalledProxy();
    Incoming.fromSvcPath().connectToService(viewRefInstalled);
    await viewRefInstalled.watch(viewRef.duplicate());

    // Set focus on the root view.
    await sceneManager.requestFocus(viewRef.duplicate());

    // Hook up focus chain to IME and shortcut manager.
    final focusChainRegistry = FocusChainListenerRegistryProxy();
    Incoming.fromSvcPath().connectToService(focusChainRegistry);
    await focusChainRegistry
        .register(FocusChainListenerBinding().wrap(_FocusChainListener()));

    // Connect to AccountManager.
    final accountManager = AccountManagerProxy();
    Incoming.fromSvcPath().connectToService(accountManager);

    // Get all account ids.
    final accountIds = await accountManager.getAccountIds();
    if (accountIds.length > 1) {
      log.shout(
          'Multiple (${accountIds.length}) accounts found, cannot get data directory');
      return;
    } else {
      final metadata = AccountMetadata(name: kAccountName);
      final account = AccountProxy();

      // If no accounts exist, create a new one.
      if (accountIds.isEmpty) {
        log.info('Creating a new account through AccountManager');

        await accountManager.deprecatedProvisionNewAccount(
          kAccountPassword,
          metadata,
          account.ctrl.request(),
        );
      } else {
        log.info('Getting existing account with ID ${accountIds.first}');

        // Get the account for the first id.
        await accountManager.deprecatedGetAccount(
          accountIds.first,
          kAccountPassword,
          account.ctrl.request(),
        );
      }

      // Get the data directory for the account.
      log.info('Getting data directory for account: ${accountIds.first}');
      final directory = ChannelPair();
      await account.getDataDirectory(InterfaceRequest(directory.second));

      // Add account directory to outgoing /svc and serve it.
      ComponentContext.create().outgoing
        ..addPublicDirectory(
            kAccountDirectory, InterfaceRequest(directory.first))
        ..serveFromStartupInfo();
    }
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    log.severe('Caught exception during workstation session setup: $e');
  }
}

/// Listens to focus chain updates and forwards them to [shortcut.Manager] and
/// IME [Controller].
class _FocusChainListener extends FocusChainListener {
  final _ime = ControllerProxy();
  final _shortcutManager = shortcut.ManagerProxy();

  _FocusChainListener() {
    Incoming.fromSvcPath().connectToService(_ime);
    Incoming.fromSvcPath().connectToService(_shortcutManager);
  }

  @override
  Future<void> onFocusChange(FocusChain focusChain) async {
    final chain = focusChain.focusChain;
    if (chain == null || chain.isEmpty) {
      return;
    }

    try {
      final viewRef = chain.last.duplicate();
      await _ime.notify(viewRef);
      await _shortcutManager.handleFocusChange(focusChain);
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      log.severe('Caught exception updating focus chain: $e');
    }
  }
}

extension _ViewRefDuplicator on ViewRef {
  ViewRef duplicate() =>
      ViewRef(reference: reference.duplicate(ZX.RIGHT_SAME_RIGHTS));
}

extension _ServeDirectory on Outgoing {
  int addPublicDirectory(String name, InterfaceRequest<Node> request) {
    return publicDir().addNode(name, PseudoDir()..serve(request));
  }
}
