import 'dart:async';
import 'dart:math';
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
    Size size = MediaQuery.of(context).size;
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
                    // WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
                    //   SchedulerBinding.instance.scheduleFrameCallback((_) {
                    //     openCvPackageManager.computing = false;
                      // });
                    // });
                    // Future.delayed(const Duration(milliseconds: 60), () {
                    //   openCvPackageManager.computing = false;
                    // });
                  }
                  return Stack(
                    children: [
                      CameraPreview(controller),
                      isThereData
                          ? Positioned(
                              top: 0,
                              left: 0,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                      "Computation took: ${snapshot.data.computationInMiliseconds} ms"),
                                   RepaintBoundary(
                                     child: RotatedBox(
                                          quarterTurns: 1,
                                          child: Image.memory(
                                            snapshot.data.image,
                                            gaplessPlayback: true,
                                            width: min(size.width/2, snapshot.data.width.toDouble()),
                                          )),
                                   ),
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
          computing = false;
        });
        stopwatch.reset();
      }
    });
  }

  Future<OpenCvPackageResult> runComputations(CameraImage img) async {
    Uint8List jpg = await convertImagetoUint8List(img);
    // moving this computation to another thread slows down the application to ~1000ms
    // Uint8List jpg = await compute(convertImagetoUint8List,img);
    Uint8List openCvResult = await ImgProc.laplacian(jpg, 5);
    return OpenCvPackageResult(openCvResult, img.width, img.height);
  }
}

class OpenCvPackageResult {
  Uint8List image;
  int width;
  int height;
  int computationInMiliseconds;

  OpenCvPackageResult(this.image, this.width, this.height, [this.computationInMiliseconds = 0]);
}

// top level function for computing in another thread
Future<Uint8List> convertImagetoUint8List(CameraImage image) async {
  // Android
  img_package.Image _convertYUV420(CameraImage image) {
    var img = img_package.Image(image.width, image.height);

    Plane plane = image.planes[0];
    // difference between counting it once and counting it every loop cycle is around ~400ms
    const shift = (0xFF << 24);

    for (int x = 0; x < image.width; x++) {
      for (int planeOffset = 0;
          planeOffset < image.height * image.width;
          planeOffset += image.width) {
        final pixelColor = plane.bytes[planeOffset + x];
        int newPixel =
            shift | (pixelColor << 16) | (pixelColor << 8) | pixelColor;

        img.data[planeOffset + x] = newPixel;
      }
    }
    return img;
  }

  // CameraImage BGRA8888 -> PNG
  img_package.Image _convertBGRA8888(CameraImage image) {
    return img_package.Image.fromBytes(
      image.width,
      image.height,
      image.planes[0].bytes,
      format: img_package.Format.bgra,
    );
  }

  try {
    img_package.Image img;
    if (image.format.group == ImageFormatGroup.yuv420) {
      img = _convertYUV420(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      img = _convertBGRA8888(image);
    }
    // Convert to readable format
    Uint8List outputImg = img_package.encodeJpg(img);
    return outputImg;
  } catch (e) {
    print("convertImagetoUint8List ERROR:" + e.toString());
  }
  return null;
}
