import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:opencv_binding_example/main.dart';
import 'package:opencv_binding_example/opencvNativeView.dart';
import 'package:opencv_binding_example/opencvPackageView.dart';
import 'package:opencv_binding_example/tensorflowForFlutter.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    final args = routeSettings.arguments;
    switch (routeSettings.name) {
      case "/":
        return MaterialPageRoute(
            builder: (_) => StartPage(
                  cameras: args,
                ));
      case "/cameraApp":
        print(args);
        if (args is List<CameraDescription>) {
          return MaterialPageRoute(
              builder: (_) => CameraApp(
                    cameras: args,
                  ));
        }
        return errorRoute(msg: "Wrong arguments");
      case "/tflite":
        print(args);
        if (args is List<CameraDescription>) {
          return MaterialPageRoute(
              builder: (_) => TensorflowForFlutter(
                cameras: args,
              ));
        }
        return errorRoute(msg: "Wrong arguments");
      case "/ffi":
        print(args);
        if (args is List<CameraDescription>) {
          return MaterialPageRoute(
              builder: (_) => OpenCvNative(
                cameras: args,
              ));
        }
        return errorRoute(msg: "Wrong arguments");
      case "/opencv":
        print(args);
        if (args is List<CameraDescription>) {
          return MaterialPageRoute(
              builder: (_) => OpenCvPackage(
                cameras: args,
              ));
        }
        return errorRoute(msg: "Wrong arguments");

      default:
        return errorRoute();
    }
  }

  static Route<dynamic> errorRoute({String msg}) {
    return MaterialPageRoute(builder: (context) {
      return Scaffold(
        appBar: AppBar(
          title: msg != null ? Text(msg) : Text("ERROR"),
        ),
        body: Center(child: msg != null ? Text(msg) : Text("ERROR")),
      );
    });
  }
}
