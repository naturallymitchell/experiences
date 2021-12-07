// Copyright 2021 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:ermine/src/services/settings/task_service.dart';
import 'package:fidl/fidl.dart' show InterfaceHandle, InterfaceRequest;
import 'package:fidl_fuchsia_wlan_common/fidl_async.dart';
import 'package:fidl_fuchsia_wlan_policy/fidl_async.dart' as policy;
import 'package:fuchsia_logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fuchsia_services/services.dart';

/// Defines a [TaskService] for WiFi control.
class WiFiService implements TaskService {
  late final VoidCallback onChanged;

  policy.ClientProviderProxy? _clientProvider;
  policy.ClientControllerProxy? _clientController;
  late ClientStateUpdatesMonitor _monitor;
  StreamSubscription? _scanForNetworksSubscription;
  policy.ScanResultIteratorProxy? _scanResultIteratorProvider;
  StreamSubscription? _connectToWPA2NetworkSubscription;
  StreamSubscription? _savedNetworksSubscription;
  StreamSubscription? _removeNetworkSubscription;

  Timer? _timer;
  int scanIntervalInSeconds = 20;
  final _scannedNetworks = <policy.ScanResult>{};
  NetworkInformation _targetNetwork = NetworkInformation();
  final _savedNetworks = <policy.NetworkConfig>{};

  WiFiService();

  @override
  Future<void> start() async {
    _clientProvider = policy.ClientProviderProxy();
    _clientController = policy.ClientControllerProxy();
    _monitor = ClientStateUpdatesMonitor(onChanged);

    Incoming.fromSvcPath().connectToService(_clientProvider);

    await _clientProvider?.getController(
        InterfaceRequest(_clientController?.ctrl.request().passChannel()),
        _monitor.getInterfaceHandle());

    final requestStatus = await _clientController?.startClientConnections();
    if (requestStatus != RequestStatus.acknowledged) {
      log.warning(
          'Failed to start wlan client connection. Request status: $requestStatus');
    }

    await getSavedNetworks();

    _timer = Timer.periodic(
        Duration(seconds: scanIntervalInSeconds), (_) => scanForNetworks());
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    await _scanForNetworksSubscription?.cancel();
    await _connectToWPA2NetworkSubscription?.cancel();
    await _savedNetworksSubscription?.cancel();
    await _removeNetworkSubscription?.cancel();
    dispose();
  }

  @override
  void dispose() {
    _clientProvider?.ctrl.close();
    _clientProvider = policy.ClientProviderProxy();
    _clientController?.ctrl.close();
    _clientController = policy.ClientControllerProxy();
    _scanResultIteratorProvider?.ctrl.close();
    _scanResultIteratorProvider = policy.ScanResultIteratorProxy();
  }

  NetworkInformation get targetNetwork => _targetNetwork;
  set targetNetwork(NetworkInformation network) {
    _targetNetwork = network;
    onChanged();
  }

  Future<void> scanForNetworks() async {
    _scanForNetworksSubscription = () async {
      _scanResultIteratorProvider = policy.ScanResultIteratorProxy();
      await _clientController?.scanForNetworks(InterfaceRequest(
          _scanResultIteratorProvider?.ctrl.request().passChannel()));

      List<policy.ScanResult>? scanResults;
      try {
        scanResults = await _scanResultIteratorProvider?.getNext();
        _scannedNetworks.clear();
        while (scanResults != null && scanResults.isNotEmpty) {
          _scannedNetworks.addAll(scanResults);
          scanResults = await _scanResultIteratorProvider?.getNext();
        }
      } on Exception catch (e) {
        log.warning('Error encountered during scan: $e');
        return;
      }
      onChanged();
    }()
        .asStream()
        .listen((_) {});
  }

  // TODO(cwhitten): simplify to _scannedNetworks.map(NetworkInformation.fromScanResult).toList();
  // once passing named contructors is supported by dart.
  List<NetworkInformation> get scannedNetworks =>
      networkInformationFromScannedNetworks(_scannedNetworks);

  List<NetworkInformation> networkInformationFromScannedNetworks(
      Set<policy.ScanResult> networks) {
    var networkInformationList = <NetworkInformation>[];
    for (var network in networks) {
      networkInformationList.add(NetworkInformation.fromScanResult(network));
    }
    return networkInformationList;
  }

  String nameFromScannedNetwork(policy.ScanResult network) {
    return utf8.decode(network.id!.ssid.toList());
  }

  Future<void> connectToNetwork(String password) async {
    try {
      _connectToWPA2NetworkSubscription = () async {
        final credential = _targetNetwork.isOpen
            ? policy.Credential.withNone(policy.Empty())
            : policy.Credential.withPassword(
                Uint8List.fromList(password.codeUnits));

        policy.ScanResult? network = _scannedNetworks.firstWhereOrNull(
            (network) =>
                nameFromScannedNetwork(network) == _targetNetwork.name);

        if (network == null) {
          throw Exception(
              '$targetNetwork network not found in scanned networks.');
        }

        final networkConfig =
            policy.NetworkConfig(id: network.id, credential: credential);

        await _clientController?.saveNetwork(networkConfig);

        final requestStatus = await _clientController?.connect(network.id!);
        if (requestStatus != RequestStatus.acknowledged) {
          throw Exception(
              'connecting to $targetNetwork rejected: $requestStatus.');
        }

        // Refresh list of saved networks
        await getSavedNetworks();
      }()
          .asStream()
          .listen((_) {});
    } on Exception catch (e) {
      log.warning('Connecting to $targetNetwork failed: $e');
    }
  }

  String get currentNetwork => _monitor.currentNetwork();

  bool get connectionsEnabled => _monitor.connectionsEnabled();

  bool get incorrectPassword => _monitor.incorrectPassword();

  Future<void> getSavedNetworks() async {
    _savedNetworksSubscription = () async {
      final iterator = policy.NetworkConfigIteratorProxy();
      await _clientController?.getSavedNetworks(
          InterfaceRequest(iterator.ctrl.request().passChannel()));

      _savedNetworks.clear();
      var savedNetworkResults = await iterator.getNext();
      while (savedNetworkResults.isNotEmpty) {
        _savedNetworks.addAll(savedNetworkResults);
        savedNetworkResults = await iterator.getNext();
      }
      onChanged();
    }()
        .asStream()
        .listen((_) {});
  }

  // TODO(fxb/79885): Pass security type to ensure removing correct network
  Future<void> remove(String network) async {
    try {
      _removeNetworkSubscription = () async {
        final ssid = utf8.encode(network);
        final foundNetwork = _savedNetworks.firstWhereOrNull(
            (savedNetwork) => listEquals(savedNetwork.id?.ssid, ssid));

        if (foundNetwork == null) {
          throw Exception('$network not found in saved networks.');
        }

        final networkConfig = policy.NetworkConfig(
            id: foundNetwork.id, credential: foundNetwork.credential);

        await _clientController?.removeNetwork(networkConfig);

        // Refresh list of saved networks
        await getSavedNetworks();
      }()
          .asStream()
          .listen((_) {});
    } on Exception catch (e) {
      log.warning('Removing $network failed: $e');
    }
  }

  // TODO(cwhitten): simplify to _savedNetworks.map(NetworkInformation.fromNetworkConfig).toList();
  // once passing named contructors is supported by dart.
  List<NetworkInformation> get savedNetworks =>
      networkInformationFromSavedNetworks(_savedNetworks);

  List<NetworkInformation> networkInformationFromSavedNetworks(
      Set<policy.NetworkConfig> networks) {
    var networkInformationList = <NetworkInformation>[];
    for (var network in networks) {
      networkInformationList.add(NetworkInformation.fromNetworkConfig(network));
    }
    return networkInformationList;
  }
}

class ClientStateUpdatesMonitor extends policy.ClientStateUpdates {
  final _binding = policy.ClientStateUpdatesBinding();
  policy.ClientStateSummary? _summary;
  late final VoidCallback _onChanged;

  ClientStateUpdatesMonitor(this._onChanged);

  InterfaceHandle<policy.ClientStateUpdates> getInterfaceHandle() =>
      _binding.wrap(this);

  policy.ClientStateSummary? getState() => _summary;

  bool connectionsEnabled() =>
      _summary?.state == policy.WlanClientState.connectionsEnabled;

  // Returns first found connected network.
  // TODO(fxb/79885): expand to return multiple connected networks.
  String currentNetwork() {
    final foundNetwork = _summary?.networks
        ?.firstWhereOrNull(
            (network) => network.state == policy.ConnectionState.connected)
        ?.id!
        .ssid
        .toList();
    return foundNetwork == null ? '' : utf8.decode(foundNetwork);
  }

  // TODO(fxb/79855): ensure that failed password status is for target network
  bool incorrectPassword() {
    return _summary?.networks?.firstWhereOrNull((network) =>
            network.status == policy.DisconnectStatus.credentialsFailed) !=
        null;
  }

  @override
  Future<void> onClientStateUpdate(policy.ClientStateSummary summary) async {
    _summary = summary;
    _onChanged();
  }
}

/// Network information needed for UI
class NetworkInformation {
  // String representation of SSID
  String? _name;
  // If network is able to be connected to
  bool _compatible = false;
  // Security type of network
  policy.SecurityType? _securityType;

  NetworkInformation();

  // Constructor for network config
  NetworkInformation.fromNetworkConfig(policy.NetworkConfig networkConfig) {
    _name = networkConfig.id?.ssid.toList() != null
        ? utf8.decode(networkConfig.id!.ssid.toList())
        : null;
    _compatible = true;
    _securityType = networkConfig.id?.type;
  }

  // Constructor for scan result
  NetworkInformation.fromScanResult(policy.ScanResult scanResult) {
    _name = scanResult.id?.ssid.toList() != null
        ? utf8.decode(scanResult.id!.ssid.toList())
        : null;
    _compatible = scanResult.compatibility == policy.Compatibility.supported;
    _securityType = scanResult.id?.type;
  }

  String get name => _name ?? '';

  bool get compatible => _compatible;

  IconData get icon => _securityType == policy.SecurityType.none
      ? Icons.signal_wifi_4_bar
      : Icons.wifi_lock;

  bool get isOpen => _securityType == policy.SecurityType.none;

  bool get isWEP => _securityType == policy.SecurityType.wep;

  bool get isWPA => _securityType == policy.SecurityType.wpa;

  bool get isWPA2 => _securityType == policy.SecurityType.wpa2;

  bool get isWPA3 => _securityType == policy.SecurityType.wpa3;
}
