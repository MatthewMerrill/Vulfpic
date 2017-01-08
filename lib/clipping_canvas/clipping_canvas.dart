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

  @ViewChild('revealToggle')
  var revealToggle;

  CanvasElement data = new CanvasElement();
  CanvasRenderingContext2D dataCtx;

  CanvasElement mask = new CanvasElement();
  CanvasRenderingContext2D maskCtx;

  @Output()
  EventEmitter change = new EventEmitter();
  CanvasElement oldValue = null;

  int WIDTH = 500;
  int HEIGHT = 500;

  double brushSize = 16.0;
  double hardness = 100.0;
  bool brushColor;

  List<Point> clicks = new List<Point>();
  List<bool> clickDrag = new List<bool>();
  List<bool> clickReveal = new List<bool>();
  List<int> clickSize = new List<int>();
  bool paint = false;
  bool revealing = false;

  void addClick(int x, int y, bool dragging)
  {
    clicks.add(new Point(x, y));
    clickDrag.add(dragging);
    clickReveal.add(revealing);
  }

  @override
  ngAfterViewInit() {
    canvas = querySelector('#drawingCanvas');
    ctx = canvas.getContext('2d');

    maskCtx = mask.getContext('2d');

    // http://www.williammalone.com/articles/create-html5-canvas-javascript-drawing-app/
    canvas.onMouseDown.listen((MouseEvent e) {
      var mouseX = e.offset.x;
      var mouseY = e.offset.y;

      paint = true;
      revealing = revealToggle.checked;
      addClick(mouseX, mouseY, false);
      draw();
    });

    canvas.onMouseMove.listen((MouseEvent e) {
      var mouseX = e.offset.x;
      var mouseY = e.offset.y;

      if (paint) {
        addClick(mouseX, mouseY, true);
        draw();
      }
    });

    canvas.onMouseUp.listen((MouseEvent e) {
      paint = false;
    });
    canvas.onMouseLeave.listen((MouseEvent e) {
      paint = false;
    });

    draw();
  }

  @Input()
  void draw() {
    canvas.width = WIDTH;
    canvas.height = HEIGHT;
    ctx.clearRect(0, 0, WIDTH, HEIGHT);

    maskCtx.lineJoin = "round";
    maskCtx.lineWidth = 5;
    maskCtx.setStrokeColorRgb(255,255,255);
    maskCtx.setFillColorRgb(255, 255, 255);
    maskCtx.fillRect(0, 0, WIDTH, HEIGHT);

    window.console.debug(clicks);

    for (int i = 0; i < clicks.length; i++) {
      if (clickReveal[i]) {
        maskCtx.globalCompositeOperation = "source-over";
        maskCtx.strokeStyle = "rgb(255,255,255)";
      } else {
        maskCtx.globalCompositeOperation = "destination-out";
        maskCtx.strokeStyle = "rgba(0,0,0,1)";
      }
      maskCtx.beginPath();
      if (clickDrag[i] && i > 0) {
        maskCtx.moveTo(clicks[i-1].x, clicks[i-1].y);
      } else {
        maskCtx.moveTo(clicks[i].x, clicks[i].y);
      }
      maskCtx.lineTo(clicks[i].x, clicks[i].y);
      maskCtx.closePath();
      maskCtx.stroke();
    }
    maskCtx.globalCompositeOperation = "source-over";

    ctx.globalCompositeOperation = "source-over";
    ctx.drawImageScaled(mask, 0, 0, WIDTH, HEIGHT);
    ctx.globalCompositeOperation = "source-in";
    ctx.drawImageScaled(data, 0, 0, WIDTH, HEIGHT);
    ctx.globalCompositeOperation = "source-over";

    change.emit(canvas);
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