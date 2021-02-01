import 'dart:ffi';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:opencv_binding/opencvBinding.dart';
import 'package:opencv_binding_example/opencvNativeLogic.dart';

class OpenCvNative extends StatefulWidget {
  final List<CameraDescription> cameras;

  const OpenCvNative({Key key, this.cameras}) : super(key: key);

  @override
  _OpenCvNativeState createState() => _OpenCvNativeState();
}

class _OpenCvNativeState extends State<OpenCvNative> {
  CameraController controller;
  OpenCvManager openCvManager;

  @override
  void initState() {
    super.initState();
    openCvManager = OpenCvManager();
    controller = new CameraController(
      widget.cameras[0],
      ResolutionPreset.medium,
    );
    controller.initialize().then((value) {
      openCvManager.allocatePointer(controller.value.previewSize.width,
          controller.value.previewSize.height);
      openCvManager.startStreamingComputedOutput(
          controller, openCvManager.outputImage);
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    openCvManager.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double totalWidth = MediaQuery.of(context).size.width;
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
            return StreamBuilder<ProcessFrameResult>(
                stream: openCvManager.computedOutput.stream,
                builder: (context, snapshot) {
                  bool isThereData = snapshot.data != null;
                  if (isThereData) {
                    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                      openCvManager.computing = false;
                    });
                  }
                  return isThereData
                      ? Stack(
                          children: [
                            CameraPreview(controller),
                            Positioned(
                              top: 0,
                              left: 0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "Computation took: ${snapshot.data.computationInMiliseconds} ms"),
                                  Container(
                                    padding: EdgeInsets.only(left: 5),
                                    child: RepaintBoundary(
                                      child: Image.memory(
                                        snapshot.data.image,
                                        gaplessPlayback: true,
                                        width: min(totalWidth / 2,
                                            snapshot.data.width.toDouble()),
                                      ),
                                    ),
                                  ),
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
