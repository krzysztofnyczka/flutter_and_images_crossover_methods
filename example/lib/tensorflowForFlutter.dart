import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

class TensorflowForFlutter extends StatefulWidget {
  final List<CameraDescription> cameras;

  TensorflowForFlutter({@required this.cameras});

  @override
  _TensorflowForFlutterState createState() => _TensorflowForFlutterState();
}

class _TensorflowForFlutterState extends State<TensorflowForFlutter> {
  CameraController controller;
  TfliteManager tfliteManager;

  @override
  void initState() {
    super.initState();
    tfliteManager = TfliteManager();
    controller = new CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
    );
    tfliteManager.getSSDMobileNet();
    controller.initialize().then((value) {
      tfliteManager.startStreamingRecognitions(controller);
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    tfliteManager.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tensorflow for flutter"),
      ),
      body: FutureBuilder<bool>(
        future: tfliteManager.isControllerPrepared,
        builder: (context, snapshot) {
          return StreamBuilder<List<String>>(
              stream: tfliteManager.recognitions.stream,
              builder: (context, snapshot) {
                var outputRecognitions = snapshot;
                // print("outputRecognitions: ${outputRecognitions.data}");
                return Stack(
                  children: [
                    CameraPreview(controller),
                    outputRecognitions.data != null
                        ? Positioned(
                            top: 0,
                            left: 0,
                            child: Column(
                              children: outputRecognitions.data
                                  .map((e) => Container(
                                        padding: EdgeInsets.all(10),
                                        color: Colors.red,
                                        child: Text(
                                          e,
                                          style: TextStyle(
                                            color: Color.fromRGBO(
                                                37, 213, 253, 1.0),
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          )
                        : Container(),
                  ],
                );
              });
        },
      ),
    );
  }
}

class TfliteManager {
  StreamController<List<String>> recognitions = StreamController();
  Future<bool> isControllerPrepared;
  bool mounted = true;

  void close() {
    mounted = false;
    recognitions.close();
  }

  void startStreamingRecognitions(CameraController controller) {
    bool computing = false;
    isControllerPrepared = Future<bool>.value(true);
    controller.startImageStream((image) async {
      if (!mounted) {
        return;
      }
      if (!computing) {
        computing = true;
        await runObjectClassification(image).then((value) {
          if (mounted) {
            recognitions.sink.add(value);
          }
          computing = false;
        });
      }
    });
  }

  Future<String> getSSDMobileNet() async {
    // .mp3 added to the model file, because otherwise it gets compressed in building process
    // http://ponystyle.com/blog/2010/03/26/dealing-with-asset-compression-in-android-apps/
    return await Tflite.loadModel(
        model: "assets/mobilenet_v1_1.0_224.tflite.mp3",
        labels: "assets/mobilenet_v1_1.0_224.txt",
        numThreads: 4,
        isAsset: true,
        useGpuDelegate: false);
  }

  Future<List<String>> runObjectClassification(CameraImage img) async {
    var recognitions = await Tflite.runModelOnFrame(
      bytesList: img.planes.map((plane) {
        return plane.bytes;
      }).toList(),
      imageHeight: img.height,
      imageWidth: img.width,
      numResults: 3,
    );
    List<String> outputRecognitions = recognitions
        .map((e) =>
            e["confidence"].toString().substring(0, 4) + " " + e["label"])
        .toList();
    // print("IN HERE outputRecognitions: $outputRecognitions");
    return outputRecognitions;
  }
}
