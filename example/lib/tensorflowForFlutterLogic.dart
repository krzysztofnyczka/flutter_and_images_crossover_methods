import 'dart:async';

import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

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
    return outputRecognitions;
  }
}
