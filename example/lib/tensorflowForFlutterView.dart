import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:opencv_binding_example/tensorflowForFlutterLogic.dart';

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
                var outputRecognitions = snapshot.data;
                return Stack(
                  children: [
                    CameraPreview(controller),
                    outputRecognitions != null
                        ? Positioned(
                            top: 0,
                            left: 0,
                            child: Column(
                              children: outputRecognitions
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
