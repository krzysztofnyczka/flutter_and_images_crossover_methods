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
      title: 'Bachelor thesis',
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
        title: Text('Bachelor thesis'),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 1 / 2,
              child: RaisedButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed("/cameraApp", arguments: widget.cameras);
                },
                child: Center(child: Text("Camera",textAlign: TextAlign.center,)),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 1 / 2,
              child: RaisedButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed("/tflite", arguments: widget.cameras);
                },
                child: Center(child: Text("Tensorflow for Flutter",textAlign: TextAlign.center,)),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 1 / 2,
              child: RaisedButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed("/ffi", arguments: widget.cameras);
                },
                child:
                    Center(child: Text("C++ code run via dart:ffi in OpenCV",textAlign: TextAlign.center,)),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 1 / 2,
              child: RaisedButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed("/opencv", arguments: widget.cameras);
                },
                child: Center(child: Text("Opencv_flutter package",textAlign: TextAlign.center,)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
