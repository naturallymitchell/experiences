// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../models/app_model.dart';
import 'cluster.dart';

/// Defines a [PageView] to hold a [Cluster] widget per screen.
class Clusters extends StatelessWidget {
  final AppModel model;

  const Clusters({this.model});

  @override
  Widget build(BuildContext context) {
    final clustersModel = model.clustersModel;
    final pageController = PageController();
    clustersModel.currentCluster.addListener(() {
      if (pageController.hasClients) {
        int index =
            clustersModel.clusters.indexOf(clustersModel.currentCluster.value);
        if (index != pageController.page) {
          if (clustersModel.clusters[index].isEmpty &&
              clustersModel.clusters[pageController.page.toInt()].isEmpty) {
            pageController.jumpToPage(index);
          } else {
            pageController.animateToPage(
              index,
              duration: Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        }
      }
    });
    return AnimatedBuilder(
      animation: Listenable.merge([
        model.overviewVisibility,
        clustersModel.fullscreenStoryNotifier,
      ]),
      child: AnimatedBuilder(
        animation: clustersModel,
        builder: (context, child) => Stack(
          children: <Widget>[
            Positioned.fill(
              child: PageView.builder(
                controller: pageController,
                scrollDirection: Axis.horizontal,
                itemCount: clustersModel.clusters.length,
                onPageChanged: (page) {
                  final cluster = clustersModel.clusters[page];
                  clustersModel.currentCluster.value = cluster;
                },
                itemBuilder: (context, index) {
                  final cluster = clustersModel.clusters[index];
                  return Cluster(model: cluster);
                },
              ),
            ),
          ],
        ),
      ),
      builder: (context, child) =>
          model.isFullscreen || model.overviewVisibility.value
              ? Offstage()
              : child,
    );
  }
}
