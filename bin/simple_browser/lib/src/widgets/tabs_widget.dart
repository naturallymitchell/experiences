// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../blocs/tabs_bloc.dart';
import '../blocs/webpage_bloc.dart';
import '../models/tabs_action.dart';

const double _kTabBarHeight = 24.0;

class TabsWidget extends StatelessWidget {
  final TabsBloc<WebPageBloc> bloc;
  const TabsWidget({@required this.bloc});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([bloc.tabsNotifier, bloc.currentTabNotifier]),
      builder: (_, __) => bloc.tabs.length > 1
          ? Container(
              height: _kTabBarHeight,
              color: Theme.of(context).accentColor,
              padding: EdgeInsets.symmetric(vertical: 1.0),
              child: Row(
                children: _buildPageTabs(context: context).toList(),
              ),
            )
          : Offstage(),
    );
  }

  Iterable<Widget> _buildPageTabs({BuildContext context}) => bloc.tabs
      .map(
        (tab) => _buildTab(
          context: context,
          tab: tab,
        ),
      )
      // add a 1pip separator before every tab,
      // divide the rest of the space between tabs
      .expand((item) => [
            SizedBox(width: 1),
            Expanded(child: item, flex: 1),
          ])
      // skip the first separator
      .skip(1);

  Widget _buildTab({
    BuildContext context,
    WebPageBloc tab,
  }) {
    final selected = tab == bloc.currentTab;
    return AnimatedBuilder(
      animation: tab.pageTitleNotifier,
      builder: (_, __) => GestureDetector(
        onTap: () {
          bloc.request.add(FocusTabAction(tab: tab));
        },
        child: Container(
          color: selected
              ? Theme.of(context).accentColor
              : Theme.of(context).primaryColor,
          child: Stack(
            children: <Widget>[
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    tab.pageTitle ?? 'NEW TAB',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).accentColor,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0.0,
                right: 0.0,
                bottom: 0.0,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: GestureDetector(
                    onTap: () {
                      bloc.request.add(RemoveTabAction(tab: tab));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: Center(
                        child: Text(
                          '×',
                          style: TextStyle(
                            color: selected
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).accentColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
