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

  int WIDTH = 500;
  int HEIGHT = 500;

  @Input()
  String xOffset = "-50";

  @Input()
  String yOffset = "-50";

  @Input()
  String xDelta = "10";

  @Input()
  String yDelta = "-10";

  @Input()
  String scale = "-10";

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
//
//          window.console.debug(maskedData);
//        } catch (err) {
//          window.console.error(err);
//    }});
  }

  @Input()
  void draw() {
    ctx.clearRect(0, 0, WIDTH, HEIGHT);
    ctx.setFillColorRgb(154, 190, 224);
    ctx.fillRect(0, 0, WIDTH, HEIGHT);

    xOffset = (xOffset.length>0) ? xOffset : "-50";
    yOffset = (yOffset.length>0) ? yOffset : "50";
    xDelta = (xDelta.length>0) ? xDelta : "10";
    yDelta = (yDelta.length>0) ? yDelta : "-10";
    scale = (scale.length>0) ? scale : "100";

    if (maskedData == null || !(maskedData is CanvasElement)) {
      window.console.debug("No maskedData :(");
      return;
    }

    var c = new CanvasElement();

    ctx.setFillColorRgb(255, 255, 255);
    for (int i = 0; i < 6; i++) {
        ctx.drawImageScaled(
            maskedData,
            250 + int.parse(xOffset) + (i * int.parse(xDelta)),
            250 + int.parse(yOffset) + (i * int.parse(yDelta)),
            int.parse(scale), int.parse(scale));
    }
  }
}