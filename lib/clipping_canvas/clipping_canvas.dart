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

  @ViewChild('uploadInput')
  var uploadInput;

  @ViewChild('revealToggle')
  var revealToggle;

  @ViewChild('brushSizeInput')
  var brushSizeInput;

  CanvasElement canvas;
  CanvasRenderingContext2D ctx;

  CanvasElement data = new CanvasElement();
  CanvasRenderingContext2D dataCtx;

  CanvasElement mask = new CanvasElement();
  CanvasRenderingContext2D maskCtx;

  CanvasElement maskedData = new CanvasElement();
  CanvasRenderingContext2D maskedDataCtx;

  @Output()
  EventEmitter change = new EventEmitter();
  CanvasElement oldValue = null;

  double brushSize = 16.0;
  double hardness = 100.0;
  bool brushColor = false;

  List<Point> clicks = new List<Point>();
  List<bool> clickDrag = new List<bool>();
  List<bool> clickReveal = new List<bool>();
  List<double> clickSize = new List<double>();
  bool paint = false;
  bool revealing = false;

  Point cursorPosition;
  bool showCursor = false;

  int DATA_WIDTH = 2048;
  int DATA_HEIGHT = 2048;

  void addClick(int x, int y, bool dragging)
  {
    clicks.add(new Point(x, y));
    clickDrag.add(dragging);
    clickReveal.add(revealing);
    clickSize.add(brushSize);
  }

  @override
  ngAfterViewInit() {
    canvas = querySelector('#drawingCanvas');
    ctx = canvas.getContext('2d');

    mask.width = DATA_WIDTH;
    mask.height = DATA_HEIGHT;
    maskCtx = mask.getContext('2d');

    maskedData.width = DATA_WIDTH;
    maskedData.height = DATA_HEIGHT;
    maskedDataCtx = maskedData.getContext('2d');

    // http://www.williammalone.com/articles/create-html5-canvas-javascript-drawing-app/
    canvas.onMouseDown.listen((MouseEvent e) {
      var mouseX = e.offset.x * mask.width / canvas.width;
      var mouseY = e.offset.y * mask.height / canvas.width;

      paint = true;
      revealing = revealToggle.checked;
      addClick(mouseX, mouseY, false);

      showCursor = true;
      cursorPosition = new Point(e.offset.x, e.offset.y);

      draw();
    });

    canvas.onMouseMove.listen((MouseEvent e) {
      var mouseX = e.offset.x * mask.width / canvas.width;
      var mouseY = e.offset.y * mask.height / canvas.width;

      showCursor = true;
      cursorPosition = new Point(e.offset.x, e.offset.y);
      brushSize = double.parse(brushSizeInput.nativeElement.value);

      if (paint) {
        addClick(mouseX, mouseY, true);
      }

      draw();
    });

    canvas.onMouseUp.listen((MouseEvent e) {
      paint = false;
    });
    canvas.onMouseLeave.listen((MouseEvent e) {
      paint = false;
      showCursor = false;
    });

    draw();
  }

  @Input()
  void draw() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    maskCtx.lineJoin = "round";
    maskCtx.lineWidth = brushSize;
    maskCtx.setStrokeColorRgb(255, 255, 255);
    maskCtx.setFillColorRgb(255, 255, 255);
    maskCtx.fillRect(0, 0, mask.width, mask.height);

    maskedData.width = DATA_WIDTH;
    maskedData.height = DATA_HEIGHT;

    for (int i = 0; i < clicks.length; i++) {
      maskCtx.lineWidth = 2*clickSize[i];

      if (clickReveal[i]) {
        maskCtx.globalCompositeOperation = "source-over";
        maskCtx.strokeStyle = "rgb(255,255,255)";
      } else {
        maskCtx.globalCompositeOperation = "destination-out";
        maskCtx.strokeStyle = "rgba(0,0,0,1)";
      }

      maskCtx.beginPath();
      if (clickDrag[i] && i > 0) {
        maskCtx.moveTo(clicks[i - 1].x, clicks[i - 1].y);
      } else {
        maskCtx.moveTo(clicks[i].x, clicks[i].y);
      }
      maskCtx.lineTo(clicks[i].x, clicks[i].y);
      maskCtx.closePath();
      maskCtx.stroke();
    }
    maskCtx.globalCompositeOperation = "source-over";

    maskedDataCtx.globalCompositeOperation = "source-over";
    maskedDataCtx.drawImageScaled(
        mask, 0, 0, maskedData.width, maskedData.height);
    maskedDataCtx.globalCompositeOperation = "source-in";
    maskedDataCtx.drawImageScaled(
        data, 0, 0, maskedData.width, maskedData.height);
    maskedDataCtx.globalCompositeOperation = "source-over";
    ctx.drawImageScaled(maskedData, 0, 0, canvas.width, canvas.height);

    if (showCursor) {
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.arc(cursorPosition.x, cursorPosition.y, brushSize*canvas.width/mask.width, 0, 6.284);
      ctx.closePath();
      ctx.stroke();
    }

    change.emit(maskedData);
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
        data.width = img.width * 10/8;
        data.height = (img.height * 10)/8;
        dataCtx = data.context2D;

        dataCtx.drawImage(
            img,
            (data.width-img.width)/2,
            (data.height-img.height)/2);

        maskCtx.clearRect(0, 0, mask.width, mask.height);

        clicks.clear();
        clickDrag.clear();
        clickReveal.clear();
        clickSize.clear();

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