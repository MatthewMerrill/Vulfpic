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

  int DATA_WIDTH = 1024;
  int DATA_HEIGHT = 1024;

  void addClick(int x, int y, bool dragging)
  {
    Point click = new Point(x, y);

    clicks.add(click);
    clickDrag.add(dragging);
    clickReveal.add(revealing);
    clickSize.add(brushSize);

    int i = clicks.length - 1;
    if (clickDrag[i] && i > 0) {
      drawClick(clicks[i], clickSize[i], clickReveal[i], clicks[i-1]);
    } else {
      drawClick(clicks[i], clickSize[i], clickReveal[i]);
    }
  }

  @override
  void ngAfterViewInit() {
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
      var mouseX = e.offset.x * mask.width / canvas.client.width;
      var mouseY = e.offset.y * mask.height / canvas.client.height;

      paint = true;
      revealing = revealToggle.checked;
      addClick(mouseX, mouseY, false);

      showCursor = true;
      cursorPosition = new Point(
          e.offset.x*canvas.width/canvas.client.width,
          e.offset.y*canvas.width/canvas.client.width);

      draw(fromScratch: false);
    });

    canvas.onMouseMove.listen((MouseEvent e) {
      var mouseX = e.offset.x * mask.width / canvas.client.width;
      var mouseY = e.offset.y * mask.height / canvas.client.height;

      showCursor = true;
      cursorPosition = new Point(
          e.offset.x*canvas.width/canvas.client.width,
          e.offset.y*canvas.width/canvas.client.width);

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


    int undosScheduled = 0;
    document.onKeyDown.listen((KeyboardEvent e) {
      window.console.debug(e.key);
      if (e.ctrlKey) {
        if (e.key == "z") {
          if (clicks.isEmpty)
            return;

          if (undosScheduled++ > 1)
            return;

          while (undosScheduled > 0) {
            bool continueRemoving = true;
            while (clicks.isNotEmpty && continueRemoving) {
              continueRemoving = clickDrag.last;

              clicks.removeLast();
              clickSize.removeLast();
              clickDrag.removeLast();
              clickReveal.removeLast();
            }
            undosScheduled--;
          }

          draw(fromScratch: true);
        }
      }
    });

    draw();
  }

  @Input()
  void draw({bool fromScratch: false}) {
    canvas.width = canvas.client.width;
    canvas.height = canvas.client.height;
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    maskCtx.lineJoin = "round";
    maskCtx.lineWidth = brushSize;
    maskCtx.setStrokeColorRgb(255, 255, 255);
    maskedDataCtx.clearRect(0, 0, maskedData.width, maskedData.height);

    if (fromScratch) {
      maskCtx.globalCompositeOperation = "source-over";
      maskCtx.setFillColorRgb(255, 255, 255);
      maskCtx.fillRect(0, 0, mask.width, mask.height);

      for (int i = 0; i < clicks.length; i++) {
        if (clickDrag[i] && i > 0) {
          drawClick(clicks[i], clickSize[i], clickReveal[i], clicks[i-1]);
        } else {
          drawClick(clicks[i], clickSize[i], clickReveal[i]);
        }
      }
    }

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
      ctx.arc(cursorPosition.x, cursorPosition.y, brushSize*canvas.width~/mask.width, 0, 6.284);
      ctx.closePath();
      ctx.stroke();

      ctx.lineWidth = .5;
    }

    change.emit(maskedData);
  }

  void drawClick(Point click, double size, bool revealing, [Point from]) {
    if (from == null) from = click;

    maskCtx.lineJoin = "round";
    maskCtx.lineWidth = 2 * size;
    maskCtx.setStrokeColorRgb(255, 255, 255);

    if (revealing) {
      maskCtx.globalCompositeOperation = "source-over";
      maskCtx.strokeStyle = "rgb(255,255,255)";
    } else {
      maskCtx.globalCompositeOperation = "destination-out";
//      maskCtx.strokeStyle = "rgb(255,255,255)";
      maskCtx.strokeStyle = "rgba(0,0,0,1)";
    }

    maskCtx.beginPath();
    maskCtx.moveTo(from.x, from.y);
    maskCtx.lineTo(click.x, click.y);
    maskCtx.closePath();
    maskCtx.stroke();

    maskCtx.globalCompositeOperation = "source-over";
    draw();
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
        data.width = max(img.width, img.height) * 10 ~/8;
        data.height = max(img.width, img.height) * 10 ~/8;
        dataCtx = data.context2D;

        CanvasElement grainData = new CanvasElement(
            width:data.width,
            height:data.height);
        CanvasRenderingContext2D grainCtx = grainData.context2D;

        dataCtx.drawImage(img,
            (data.width-img.width)/2,
            (data.height-img.height)/2);

        grainCtx.drawImage(img,
            (data.width-img.width)/2,
            (data.height-img.height)/2);

        initGrain();
        grainCtx.save();
        grainCtx.scale((data.width/333).ceil(), (data.width/333).ceil());
        grainCtx.globalCompositeOperation = "overlay";
        grainCtx.fillStyle = grainCtx.createPattern(patternCanvas, 'repeat');
        grainCtx.fillRect(0, 0, data.width, data.height);
        grainCtx.restore();

        dataCtx.globalCompositeOperation = "source-in";
        dataCtx.drawImage(grainData, 0, 0);

        maskCtx.clearRect(0, 0, mask.width, mask.height);

        clicks.clear();
        clickDrag.clear();
        clickReveal.clear();
        clickSize.clear();

        draw(fromScratch: true);
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

// change these settings
  static var patternSize = 64,
      patternScaleX = 3,
      patternScaleY = 3,
      patternRefreshInterval = 8,
      patternAlpha = 48; // int between 0 and 255,

  var patternPixelDataLength = patternSize * patternSize * 4,
      patternCanvas,
      patternCtx,
      patternData,
      frame = 0;

// create a canvas which will be used as a pattern
  void initGrain() {
    patternCanvas = document.createElement('canvas');
    patternCanvas.width = patternSize;
    patternCanvas.height = patternSize;
    patternCtx = patternCanvas.getContext('2d');
    patternData = patternCtx.createImageData(patternSize, patternSize);

    var value;
    Random rand = new Random.secure();
    for (var i = 0; i < patternPixelDataLength; i += 4) {
      value = (rand.nextDouble() * 255).floor();

      patternData.data[i    ] = value;
      patternData.data[i + 1] = value;
      patternData.data[i + 2] = value;
      patternData.data[i + 3] = patternAlpha;
    }
    patternCtx.putImageData(patternData, 0, 0);
  }

}