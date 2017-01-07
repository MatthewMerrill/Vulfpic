// Copyright (c) 2017, merrillm. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:angular2/core.dart';
import 'package:angular2_components/angular2_components.dart';

import 'dart:html';
import 'dart:math';
import 'package:vulfpic/ValueChangeEvent.dart';

@Component(
  selector: 'clipping-canvas',
  styleUrls: const ['clipping_canvas.css'],
  templateUrl: 'clipping_canvas.html',
  directives: const [materialDirectives],
  providers: const [materialProviders],
)
class ClippingCanvas implements AfterViewInit {

  CanvasElement canvas;
  CanvasRenderingContext2D ctx;

  @ViewChild('uploadInput')
  var uploadInput;

  CanvasElement data = new CanvasElement();
  CanvasRenderingContext2D dataCtx;

  CanvasElement mask = new CanvasElement();
  CanvasRenderingContext2D maskCtx;

  @Output()
  EventEmitter change = new EventEmitter();
  CanvasElement oldValue = null;

  int WIDTH = 500;
  int HEIGHT = 500;

  @override
  ngAfterViewInit() {
    canvas = querySelector('#drawingCanvas');
    ctx = canvas.getContext('2d');
    draw();
  }

  @Input()
  void draw() {
    canvas.width = WIDTH;
    canvas.height = HEIGHT;
    ctx.clearRect(0, 0, WIDTH, HEIGHT);
    ctx.drawImageScaled(data, 0, 0, WIDTH, HEIGHT);
  }

  void onFileUpload(event) {
    print(uploadInput.runtimeType.toString());
    window.console.debug(uploadInput);
    var files = uploadInput.nativeElement.files;
    if (files.length == 1) {
      var file = files[0];
      loadBlobAsImg(file).then((img) {
        oldValue = data;
        data = new CanvasElement();
        data.width = max(img.width, img.height);
        data.height = max(img.width, img.height);
        dataCtx = data.context2D;
        dataCtx.drawImage(img, 0, 0);

        draw();

        change.emit(data);
      });
    }
  }

  Future<String> loadBlobAsDataUri(Blob blob) {
    var fileReader = new FileReader();
    var future = fileReader.onLoad.first.then((ProgressEvent event) {
      return fileReader.result;
    });

    fileReader.readAsDataUrl(blob);
    return future;
  }

  Future<ImageElement> loadBlobAsImg(Blob blob) {
    ImageElement image = new ImageElement();
    return loadBlobAsDataUri(blob).then((String dataUri) {
      var loaded = image.onLoad.first;
      image.src = dataUri;
      return loaded.then((_) => image);
    });
  }


}