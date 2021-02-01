import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:opencv_binding_example/opencvPackageLogic.dart';

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
                  return Stack(
                    children: [
                      CameraPreview(controller),
                      isThereData
                          ? Positioned(
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
                                      child: RotatedBox(
                                          quarterTurns: 1,
                                          child: Image.memory(
                                            snapshot.data.image,
                                            gaplessPlayback: true,
                                            width: min(size.width / 2,
                                                snapshot.data.width.toDouble()),
                                          )),
                                    ),
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
