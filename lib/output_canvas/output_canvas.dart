// Copyright (c) 2017, merrillm. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:angular2/core.dart';
import 'package:angular2_components/angular2_components.dart';
import 'package:js/js.dart' show allowInterop;

import 'dart:html';
import 'dart:math';
import 'package:vulfpic/ValueChangeEvent.dart';

@Component(
  selector: 'output-canvas',
  styleUrls: const ['output_canvas.css'],
  templateUrl: 'output_canvas.html',
  directives: const [materialDirectives],
  providers: const [materialProviders],
)
class OutputCanvas implements AfterViewInit {

  CanvasElement canvas;
  CanvasRenderingContext2D ctx;

  var maskedData;

  ImageData pixels;

  int WIDTH = 1024;
  int HEIGHT = 1024;

  List<List<int>> bkgds = [
    [154, 190, 224],
    [247, 207, 205],
    [234, 238, 224],
    [225, 228, 233],

  ];
  int bkgdIdx = 0;

  @Input()
  int xOffset = 175;

  @Input()
  int yOffset = 275;

  @Input()
  int xDelta = -10;

  @Input()
  int yDelta = -10;

  @Input()
  int scale = 100;

  @override
  ngAfterViewInit() {
    canvas = querySelector('#outputCanvas');
    ctx = canvas.getContext('2d');
    draw();
  }

  void updateData(var event) {
//    allowInterop(() {
//        try {
//          window.console.debug(event);
//          window.console.debug(event.newValue);

          maskedData = event;
          draw();
//
//          window.console.debug(maskedData);
//        } catch (err) {
//          window.console.error(err);
//    }});
  }

  @Input()
  void draw() {
    ctx.clearRect(0, 0, WIDTH, HEIGHT);
    ctx.setFillColorRgb(
        bkgds[bkgdIdx][0],
        bkgds[bkgdIdx][1],
        bkgds[bkgdIdx][2]);
    ctx.fillRect(0, 0, WIDTH, HEIGHT);
//
//    xOffset = (xOffset.length>0) ? xOffset : "150";
//    yOffset = (yOffset.length>0) ? yOffset : "50";
//    xDelta = (xDelta.length>0) ? xDelta : "10";
//    yDelta = (yDelta.length>0) ? yDelta : "-10";
//    scale = (scale.length>0) ? scale : "100";

    if (maskedData == null || !(maskedData is CanvasElement)) {
      window.console.debug("No maskedData :(");
      return;
    }

    ctx.setFillColorRgb(255, 255, 255);
    for (int i = 0; i < 6; i++) {
      ctx.shadowColor = '#333333';
      ctx.shadowBlur = 10;
      ctx.shadowOffsetX = 3;
      ctx.shadowOffsetY = 3;
      ctx.drawImageScaled(
            maskedData,
              0 + (xOffset + ((5-i) * xDelta)) - scale,
            512 - (yOffset + ((5-i) * yDelta)) - scale,
            2*scale, 2*scale);
    }
  }
}