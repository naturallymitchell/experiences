// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_intl/fidl_async.dart';
import 'package:fuchsia_logger/logger.dart';
import 'package:intl/intl.dart';

// The locale to use if service-based locale resolution fails.
const _defaultLocale =
    Locale.fromSubtags(languageCode: 'en', countryCode: 'US');

/// Extracts the user's preferred locale from the profile.
Locale _fromProfile(Profile profile) {
  final String localeName =
      profile?.locales?.first?.id ?? _defaultLocale.toString();
  return Locale(Intl.canonicalizedLocale(localeName));
}

/// Encapsulates the logic to obtain the locales from the service
/// fuchsia.intl.PropertyProvider.
///
/// For the time being, the first locale only is returned.
class LocaleSource {
  final PropertyProvider _stub;

  const LocaleSource(this._stub);

  Future<Locale> initial() async {
    try {
      return _fromProfile(await _stub.getProfile());
    } on FidlError catch (e, s) {
      log.warning(
          'Could not get locale from fuchsia.intl.ProfileProvider: $e: $s');
      // In case of an error, use the default locale and proceed.
      return _defaultLocale;
    }
  }

  /// Returns the stream of locale changes, after the call to [initial()].
  Stream<Locale> stream() {
    return _stub.onChange.asyncMap((x) => _stub.getProfile()).map(_fromProfile);
  }
}