import 'dart:async';
import 'dart:isolate';

import 'package:opencv_binding/opencv_binding.dart';

class FrameProcessor {
  static Future<void> startFrameProcessorIsolate(
      FrameProcessorInput frameProcessorInput) async {
    var result = await FrameProcessing.processFrame(
        frameProcessorInput.processFrameArguments);
    frameProcessorInput.sendPort.send(result);
  }


  static Future<void> startFrameProcessorFrom3PlanesIsolate(
      FrameProcessorFrom3PlanesInput frameProcessorFrom3PlanesInput) async {
    var result = await FrameProcessing.processFrameFrom3Planes(
        frameProcessorFrom3PlanesInput.processFrameFrom3PlanesArguments);
    frameProcessorFrom3PlanesInput.sendPort.send(result);
  }

  Future<ProcessFrameResult> processFrameFrom3PlanesInIsolate(
      ProcessFrameFrom3PlanesArguments processFrameFrom3PlanesArguments) async {
    final port = ReceivePort();

    _spawnIsolate<FrameProcessorInput>(
        startFrameProcessorFrom3PlanesIsolate,
        FrameProcessorFrom3PlanesInput(
          processFrameFrom3PlanesArguments: processFrameFrom3PlanesArguments,
            sendPort: port.sendPort),
        port);
    return await _subscribeToPort<ProcessFrameResult>(port);
  }

  Future<ProcessFrameResult> processFrameInIsolate(
      ProcessFrameArguments processFrameArguments) async {
    final port = ReceivePort();

    _spawnIsolate<FrameProcessorInput>(
        startFrameProcessorIsolate,
        FrameProcessorInput(
            processFrameArguments: processFrameArguments,
            sendPort: port.sendPort),
        port);
    return await _subscribeToPort<ProcessFrameResult>(port);
  }

  void _spawnIsolate<T>(Function function, dynamic input, ReceivePort port) {
    Isolate.spawn<T>(function, input,
        onError: port.sendPort, onExit: port.sendPort);
  }

  Future<T> _subscribeToPort<T>(ReceivePort port) async {
    StreamSubscription portStreamSubscription;

    var completer = new Completer<T>();

    portStreamSubscription = port.listen((result) async {
      await portStreamSubscription?.cancel();
      completer.complete(await result);
    });

    return completer.future;
  }
}

class FrameProcessorInput {
  FrameProcessorInput({this.processFrameArguments, this.sendPort});

  ProcessFrameArguments processFrameArguments;
  SendPort sendPort;
}


class FrameProcessorFrom3PlanesInput {
  FrameProcessorFrom3PlanesInput({this.processFrameFrom3PlanesArguments, this.sendPort});

  ProcessFrameFrom3PlanesArguments processFrameFrom3PlanesArguments;
  SendPort sendPort;
}
