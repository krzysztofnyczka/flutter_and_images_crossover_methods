import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image/image.dart' as img_package;
import 'package:opencv/opencv.dart';

class OpenCvPackage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const OpenCvPackage({Key key, this.cameras}) : super(key: key);

  @override
  _OpenCvPackageState createState() => _OpenCvPackageState();
}

class _OpenCvPackageState extends State<OpenCvPackage> {
  CameraController controller;
  OpenCvPackageManager openCvPackageManager;

  @override
  void initState() {
    super.initState();
    openCvPackageManager = OpenCvPackageManager();
    controller = new CameraController(
      widget.cameras[0],
      ResolutionPreset.medium,
    );
    controller.initialize().then((value) {
      print(
          "PREVIEW SIZE: ${controller.value.previewSize.width.toInt()} and ${controller.value.previewSize.height}");
      openCvPackageManager.startStreamingComputedOutput(controller);
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    openCvPackageManager.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("opencv_flutter package"),
      ),
      body: FutureBuilder<bool>(
        future: openCvPackageManager.isControllerPrepared,
        builder: (context, snapshot) {
          print(snapshot);
          if (!snapshot.hasData) {
            return Center(
              child: Text("Preparing camera!"),
            );
          } else {
            return StreamBuilder<OpenCvPackageResult>(
                stream: openCvPackageManager.computedOutput.stream,
                builder: (context, snapshot) {
                  bool isThereData = snapshot.data != null;
                  if (snapshot.data != null) {
                    SchedulerBinding.instance.scheduleFrameCallback((_) {
                      openCvPackageManager.computing = false;
                    });
                  }
                  return Stack(
                    children: [
                      CameraPreview(controller),
                      isThereData
                          ? Positioned(
                              top: 0,
                              left: 0,
                              child: Column(
                                children: [
                                  Text(
                                      "Computation took: ${snapshot.data.computationInMiliseconds} ms"),
                                  RotatedBox(
                                      quarterTurns: 1,
                                      child: Image.memory(snapshot.data.image)),
                                ],
                              ),
                            )
                          : Container(),
                    ],
                  );
                });
          }
        },
      ),
    );
  }
}

class OpenCvPackageManager {
  StreamController<OpenCvPackageResult> computedOutput = StreamController();
  Future<bool> isControllerPrepared = Future<bool>.value(false);
  bool mounted = true;
  bool computing = false;

  void close() {
    mounted = false;
    computedOutput.close();
  }

  void startStreamingComputedOutput(CameraController controller) {
    Stopwatch stopwatch = Stopwatch()..start();
    isControllerPrepared = Future<bool>.value(true);
    controller.startImageStream((image) async {
      if (!mounted) {
        return;
      }
      if (!computing) {
        computing = true;
        await runComputations(image).then((value) {
          value.computationInMiliseconds = stopwatch.elapsed.inMilliseconds;
          if (mounted) {
            computedOutput.sink.add(value);
          }
          //computing = false;
        });
        stopwatch.reset();
      }
    });
  }

  Future<OpenCvPackageResult> runComputations(CameraImage img) async {
    Uint8List jpg = await convertImagetoUint8List(img);
    // Uint8List dwa =
    //     await ImgProc.threshold(jpg, 80, 255, ImgProc.cvThreshBINARY);
    Uint8List dwa = await ImgProc.laplacian(jpg, 5);
    return OpenCvPackageResult(dwa);
  }

  Uint8List convertYUV420toPngBytes(CameraImage image) {
    const shift = (0xFF << 24);
    try {
      final int width = image.width;
      final int height = image.height;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel;

      // img_package -> Image package from https://pub.dartlang.org/packages/image
      var img = img_package.Image(width, height); // Create Image buffer

      // Fill image buffer with plane[0] from YUV420_888
      for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
          final int uvIndex =
              uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
          final int index = y * width + x;

          final yp = image.planes[0].bytes[index];
          final up = image.planes[1].bytes[uvIndex];
          final vp = image.planes[2].bytes[uvIndex];
          // Calculate pixel color
          int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
          int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
              .round()
              .clamp(0, 255);
          int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
          // color: 0x FF  FF  FF  FF
          //           A   B   G   R
          img.data[index] = shift | (b << 16) | (g << 8) | r;
        }
      }

      img_package.PngEncoder pngEncoder =
          new img_package.PngEncoder(level: 0, filter: 0);
      Uint8List png = pngEncoder.encodeImage(img);
      return png;
    } catch (e) {
      print(">>>>>>>>>>>> ERROR:" + e.toString());
    }
    return null;
  }

  Future<List<int>> convertImagetoUint8List(CameraImage image) async {
    try {
      img_package.Image img;
      if (image.format.group == ImageFormatGroup.yuv420) {
        img = _convertYUV420(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        img = _convertBGRA8888(image);
      }

      // img_package.PngEncoder pngEncoder =
      //     new img_package.PngEncoder(filter: 0, level: 0);

      // Convert to png
      Uint8List outputImg = img_package.encodeJpg(img);
      return outputImg;
    } catch (e) {
      print(">>>>>>>>>>>> ERROR:" + e.toString());
    }
    return null;
  }

// CameraImage BGRA8888 -> PNG
// Color
  img_package.Image _convertBGRA8888(CameraImage image) {
    return img_package.Image.fromBytes(
      image.width,
      image.height,
      image.planes[0].bytes,
      format: img_package.Format.bgra,
    );
  }

// CameraImage YUV420_888 -> PNG -> Image (compresion:0, filter: none)
// Black
  img_package.Image _convertYUV420(CameraImage image) {
    var img =
        img_package.Image(image.width, image.height); // Create Image buffer

    Plane plane = image.planes[0];
    const int shift = (0xFF << 24);

    // Fill image buffer with plane[0] from YUV420_888
    for (int x = 0; x < image.width; x++) {
      for (int planeOffset = 0;
          planeOffset < image.height * image.width;
          planeOffset += image.width) {
        final pixelColor = plane.bytes[planeOffset + x];
        // color: 0x FF  FF  FF  FF
        //           A   B   G   R
        // Calculate pixel color
        var newVal =
            shift | (pixelColor << 16) | (pixelColor << 8) | pixelColor;

        img.data[planeOffset + x] = newVal;
      }
    }

    return img;
  }
}

class OpenCvPackageResult {
  Uint8List image;
  int computationInMiliseconds;

  OpenCvPackageResult(this.image, [this.computationInMiliseconds = 0]);
}
