import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:opencv_binding_example/routeGenerator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  List<CameraDescription> cameras;
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }
  // print("CAMERAS: $cameras");
  runApp(MainApp(cameras: cameras));
}

class MainApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  MainApp({@required this.cameras});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Praca inzynierska',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StartPage(
        cameras: cameras,
      ),
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}

class StartPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  StartPage({Key key, this.cameras}) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Praca inżynierska"),
      ),
      body: Center(
        child: Column(
          children: [
            RaisedButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamed("/cameraApp", arguments: widget.cameras);
              },
              child: Text("Camera"),
            ),
            RaisedButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamed("/tflite", arguments: widget.cameras);
              },
              child: Text("Tensorflow for Flutter"),
            ),
            RaisedButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamed("/ffi", arguments: widget.cameras);
              },
              child: Text("C++ code run via dart:ffi in OpenCV"),
            ),
            RaisedButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamed("/opencv", arguments: widget.cameras);
              },
              child: Text("Opencv_flutter package"),
            )
          ],
        ),
      ),
    );
  }
}

class CameraApp extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraApp({Key key, this.cameras}) : super(key: key);

  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  CameraController controller;

  @override
  void initState() {
    super.initState();
    controller = CameraController(widget.cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("Camera"),
      ),
      body: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: CameraPreview(controller)),
    );
  }
}
