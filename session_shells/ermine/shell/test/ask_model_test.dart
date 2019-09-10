// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show RawKeyDownEvent, RawKeyEventDataFuchsia;
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

// ignore_for_file: implementation_imports
import 'package:ermine_library/src/models/ask_model.dart';
import 'package:ermine_library/src/utils/suggestions.dart';

void main() {
  ValueNotifier<bool> visibility;
  MockSuggestionService suggestionService;
  AskModel model;
  Completer suggestionsCompleter;
  Completer selectionCompleter;

  setUp(() {
    visibility = ValueNotifier<bool>(false);
    suggestionService = MockSuggestionService();
    suggestionsCompleter = Completer();
    selectionCompleter = Completer();

    model = AskModel(
      visibility: visibility,
      suggestionService: suggestionService,
      onInsertItem: (_) {},
      onRemoveItem: (_) {},
    );
    model.suggestions.addListener(() => suggestionsCompleter.complete());
    model.selection.addListener(() => selectionCompleter.complete());
  });

  tearDown(() {
    model.dispose();
  });

  test('Create AskModel', () {
    expect(model.visibility.value, false);
    expect(model.selection.value, -1);
    expect(model.suggestions.value.length, 0);
  });

  test('Create suggestions', () async {
    when(suggestionService.getSuggestions('t'))
        .thenAnswer((_) => Future<Iterable<Suggestion>>.value(<Suggestion>[
              Suggestion(id: 'one'),
              Suggestion(id: 'two'),
            ]));

    // Type: 't'.
    model.query('t');

    await suggestionsCompleter.future;
    expect(model.suggestions.value.length, 2);
    await selectionCompleter.future;
    expect(model.selection.value, 0);
  });

  test('Clear suggestions', () async {
    // Clear.
    when(suggestionService.getSuggestions(''))
        .thenAnswer((_) => Future<Iterable<Suggestion>>.value(<Suggestion>[]));
    model.query('');

    await suggestionsCompleter.future;
    expect(model.suggestions.value.length, 0);
  });

  test('Navigate Suggestions', () async {
    // Type: 't'.
    when(suggestionService.getSuggestions('t'))
        .thenAnswer((_) => Future<Iterable<Suggestion>>.value(<Suggestion>[
              Suggestion(id: 'one', displayInfo: DisplayInfo(title: '')),
              Suggestion(id: 'two', displayInfo: DisplayInfo(title: '')),
            ]));
    model.query('t');

    await suggestionsCompleter.future;
    expect(model.suggestions.value.length, 2);
    await selectionCompleter.future;
    expect(model.selection.value, 0);

    // Press arrow down.
    selectionCompleter = Completer();
    model.handleKey(RawKeyDownEvent(
      data: RawKeyEventDataFuchsia(
        hidUsage: AskModel.kDownArrow,
      ),
    ));
    expect(model.selection.value, 1);
  });

  test('Dismiss Ask', () async {
    // Type: 't'.
    when(suggestionService.getSuggestions('t'))
        .thenAnswer((_) => Future<Iterable<Suggestion>>.value(<Suggestion>[
              Suggestion(id: 'one', displayInfo: DisplayInfo(title: '')),
              Suggestion(id: 'two', displayInfo: DisplayInfo(title: '')),
            ]));
    model.query('t');

    await suggestionsCompleter.future;
    expect(model.suggestions.value.length, 2);
    await selectionCompleter.future;
    expect(model.selection.value, 0);

    // Press Esc.
    model.handleKey(RawKeyDownEvent(
      data: RawKeyEventDataFuchsia(
        hidUsage: AskModel.kEsc,
      ),
    ));
    expect(model.visibility.value, false);
  });

  test('Select Suggestion', () {
    model.handleSuggestion(Suggestion(id: 'one'));
    expect(
        verify(suggestionService.invokeSuggestion(captureAny))
            .captured
            .first
            .id,
        'one');
  });
}

// Mock classes.
class MockSuggestionService extends Mock implements SuggestionService {}