// Copyright (c) 2017, merrillm. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';
import 'package:angular2/core.dart';
import 'package:angular2_components/angular2_components.dart';

import 'package:vulfpic/clipping_canvas/clipping_canvas.dart';
import 'package:vulfpic/output_canvas/output_canvas.dart';
import 'package:vulfpic/hello_dialog/hello_dialog.dart';

@Component(
  selector: 'my-app',
  styleUrls: const ['app_component.css'],
  templateUrl: 'app_component.html',
  directives: const [materialDirectives, HelloDialog, ClippingCanvas, OutputCanvas],
  providers: const [materialProviders],
)
class AppComponent {

  @ViewChild('clippingCanvas')
  var clippingCanvas;

  @ViewChild('outputCanvas')
  var outputCanvas;

  @ViewChild('downloadAnchorElem')
  var downloadAnchorElem;

  AppComponent() {
  }

  void uploadSession() {
    querySelector("#uploadAnchorElem").click();
  }

  void downloadSession() {
    var data = {
      "maskedData": clippingCanvas.maskedData.toDataUrl(),
      "xOffset": outputCanvas.xOffset,
      "yOffset": outputCanvas.yOffset,
      "xDelta": outputCanvas.xDelta,
      "yDelta": outputCanvas.yDelta,
      "scale": outputCanvas.scale,
      "bkgdIdx": outputCanvas.bkgdIdx,
      "rotation": outputCanvas.rotation
    };
    var dataStr = "data:text/json;charset=utf-8," + JSON.encode(data);
    var dlAnchorElem = querySelector('#downloadAnchorElem');
    dlAnchorElem.setAttribute("href", dataStr);
    dlAnchorElem.setAttribute("download", "scene.json");
    dlAnchorElem.click();
  }

  void sessionUploaded(event) {
    var uploadElem = querySelector("#uploadAnchorElem");
    var files = uploadElem.files;
    if (files.length == 1) {
      var file = files[0];
      loadBlobAsMap(file).then((map) {
        ImageElement img = new ImageElement(src: map["maskedData"]);

        clippingCanvas.data = new CanvasElement();
        clippingCanvas.data.width = img.width;
        clippingCanvas.data.height = img.height;
        clippingCanvas.dataCtx = clippingCanvas.data.context2D;

        clippingCanvas.dataCtx.drawImage(img, 0, 0);

        clippingCanvas.maskCtx.clearRect(0, 0,
            clippingCanvas.mask.width,
            clippingCanvas.mask.height);

        clippingCanvas.clicks.clear();
        clippingCanvas.clickDrag.clear();
        clippingCanvas.clickReveal.clear();
        clippingCanvas.clickSize.clear();

        outputCanvas.xOffset = map["xOffset"];
        outputCanvas.yOffset = map["yOffset"];
        outputCanvas.xDelta = map["xDelta"];
        outputCanvas.yDelta = map["yDelta"];
        outputCanvas.scale = map["scale"];
        outputCanvas.bkgdIdx = map["bkgdIdx"];
        outputCanvas.rotation = map["rotation"] != null ? map["rotation"] : 0;

        clippingCanvas.draw(fromScratch: true);
      });
    }
  }

  Future<String> loadBlobAsString(Blob blob) {
    var fileReader = new FileReader();
    var future = fileReader.onLoad.first.then((ProgressEvent event) {
      return fileReader.result;
    });

    fileReader.readAsText(blob);
    return future;
  }

  Future<dynamic> loadBlobAsMap(Blob blob) {
    return loadBlobAsString(blob).then((json) {
      return JSON.decode(json);
    });
  }
}
