import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:opencv_binding/opencvBinding.dart';

class OpenCvManager {
  StreamController<ProcessFrameResult> computedOutput = StreamController();
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
          }
          // computing = false;
        });
        stopwatch.reset();
      }
    });
  }

  Future<ProcessFrameResult> runComputations(
      CameraImage img, Pointer<Uint32> outputImagePointer) async {
    ProcessFrameArguments processFrameArguments = ProcessFrameArguments(
      img.planes[0].bytes,
      img.planes[1].bytes,
      img.planes[2].bytes,
      img.planes[1].bytesPerRow,
      img.planes[1].bytesPerPixel,
      img.width,
      img.height,
      outputImagePointer,
    );

    ProcessFrameResult result =
        await FrameProcessing.processFrame(processFrameArguments);
    return result;
  }
}

class FrameProcessor {
  static Future<void> startFrameProcessorIsolate(
      FrameProcessorInput frameProcessorInput) async {
    var result = await FrameProcessing.processFrame(
        frameProcessorInput.processFrameArguments);
    frameProcessorInput.sendPort.send(result);
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
