import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image/image.dart' as img_package;
import 'package:opencv_binding/opencv_binding.dart';

class OpenCv2 extends StatefulWidget {
  final List<CameraDescription> cameras;

  const OpenCv2({Key key, this.cameras}) : super(key: key);

  @override
  _OpenCvState2 createState() => _OpenCvState2();
}

class _OpenCvState2 extends State<OpenCv2> {
  CameraController controller;
  OpenCvManager openCvManager;
  Pointer<Uint32> outputImage;
  Queue imageQueue = Queue<Image>();

  @override
  void initState() {
    super.initState();
    openCvManager = OpenCvManager();
    controller = new CameraController(
      widget.cameras[0],
      ResolutionPreset.medium,
    );
    controller.initialize().then((value) {
      outputImage = allocate<Uint32>(
          count: controller.value.previewSize.width.toInt() *
              controller.value.previewSize.height.toInt());
      openCvManager.startStreamingComputedOutput(controller, outputImage);
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    openCvManager.close();
    super.dispose();
    free(outputImage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("C++ code run via dart:ffi in OpenCV"),
      ),
      body: FutureBuilder<bool>(
        future: openCvManager.isControllerPrepared,
        builder: (context, snapshot) {
          print(snapshot);
          if (!snapshot.hasData) {
            return Center(
              child: Text("Preparing camera!"),
            );
          } else {
            return StreamBuilder<ProcessFrameFrom3PlanesResult>(
                stream: openCvManager.computedOutput.stream,
                builder: (context, snapshot) {
                  bool isThereData = imageQueue.isNotEmpty;
                  Image img;
                  if (imageQueue.length > 2) {
                    img = imageQueue.removeFirst();
                  }else if (isThereData) {
                    img = imageQueue.first;
                  }
                  if (snapshot.data != null) {
                    Image encodedImage = Image.memory(
                      snapshot.data.image,
                      height: MediaQuery.of(context).size.height * 1 / 4,
                      width: MediaQuery.of(context).size.width * 1 / 4,
                    );
                    imageQueue.add(encodedImage);

                    SchedulerBinding.instance.scheduleFrameCallback((_) {
                      openCvManager.computing = false;
                    });
                  }
                  // return encodedImage != null
                  //     ? Column(
                  //         children: [
                  //           Text(
                  //               "Computation took: ${snapshot.data.computationInMiliseconds} ms"),
                  //           Image.memory(encodedImage),
                  //         ],
                  //       )
                  //     : Container(
                  //         child: Text("No data"),
                  //       );
                  return isThereData
                      ? Stack(
                          children: [
                            CameraPreview(controller),
                            SizedBox(
                              child: img,
                              width: MediaQuery.of(context).size.width * 1 / 4,
                              height:
                                  MediaQuery.of(context).size.height * 1 / 4,
                            ),
                            Positioned(
                              top: 0,
                              left: 0,
                              child: Column(
                                children: [
                                  Text(
                                      "Computation took: ${snapshot.data.computationInMiliseconds} ms"),
                                ],
                              ),
                            )
                          ],
                        )
                      : Center(
                          child: Container(
                            child: Text("No data"),
                          ),
                        );
                });
          }
        },
      ),
    );
  }
}

class OpenCvManager {
  StreamController<ProcessFrameFrom3PlanesResult> computedOutput =
      StreamController();
  Future<bool> isControllerPrepared = Future<bool>.value(false);
  bool mounted = true;
  bool computing = false;

  void close() {
    mounted = false;
    computedOutput.close();
  }

  void startStreamingComputedOutput(
      CameraController controller, outputImagePointer) {
    Stopwatch stopwatch = Stopwatch()..start();
    isControllerPrepared = Future<bool>.value(true);
    controller.startImageStream((image) async {
      if (!mounted) {
        return;
      }
      if (!computing) {
        computing = true;
        // print("COMPUTATION TIME: ${stopwatch.elapsed.inMilliseconds} ms");
        await runComputations(image, outputImagePointer).then((value) {
          value.computationInMiliseconds = stopwatch.elapsed.inMilliseconds;
          if (mounted) {
            computedOutput.sink.add(value);
            computedOutput.sink.add(value);
          }
          //computing = false;
        });
        stopwatch.reset();
      }
    });
  }

  Future<ProcessFrameFrom3PlanesResult> runComputations(
      CameraImage img, Pointer<Uint32> outputImagePointer) async {
    // print("Length of planes[0].bytes ${img.planes[0].bytes.length}");
    // print("Number of planes ${img.planes.length}");
    // print("Plane0: ${img.planes[0].bytes.length}");
    // print("Plane1: ${img.planes[1].bytes.length}");
    // print("Plane2: ${img.planes[2].bytes.length}");
    //
    // print("Img format group ${img.format.group}");

    // Uint8List allBytes =  Uint8List.fromList(img.planes[0].bytes + img.planes[1].bytes + img.planes[2].bytes);
    //
    // ProcessFrameArguments processFrameArguments = ProcessFrameArguments(
    //     allBytes, img.width, img.height);
    // var result = await FrameProcessor().processFrameInIsolate(processFrameArguments);

    ProcessFrameFrom3PlanesArguments processFrameFrom3PlanesArguments =
        ProcessFrameFrom3PlanesArguments(
      img.planes[0].bytes,
      img.planes[1].bytes,
      img.planes[2].bytes,
      img.planes[1].bytesPerRow,
      img.planes[1].bytesPerPixel,
      img.width,
      img.height,
      outputImagePointer,
    );

    ProcessFrameFrom3PlanesResult result =
        await FrameProcessing.processFrameFrom3Planes(
            processFrameFrom3PlanesArguments);

    // ProcessFrameResult result = await FrameProcessing.processFrame(
    //     processFrameArguments);
    return result;
  }
}
