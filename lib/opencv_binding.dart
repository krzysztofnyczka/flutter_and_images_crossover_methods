import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

import 'dart:typed_data';

import 'package:image/image.dart' as img_package;

import 'package:flutter/material.dart';

// C function signatures
typedef _frame_processing_function = Uint8 Function(
    Pointer<Uint8>, Uint32 width, Uint32 height, Pointer<Uint8>);

// Dart function signatures
typedef _FrameProcessingFunction = int Function(
    Pointer<Uint8>, int width, int height, Pointer<Uint8>);

typedef convert_func = Int32 Function(
    Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, Int32, Int32, Int32, Int32,Pointer<Uint32>);
typedef Convert = int Function(
    Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, int, int, int, int,Pointer<Uint32>);


class ProcessFrameArguments {
  final Uint8List bytes;
  final int width;
  final int height;

  // final Uint8List output;

  ProcessFrameArguments(this.bytes, this.width, this.height);
}

class ProcessFrameFrom3PlanesArguments {
  final Uint8List p0;
  final Uint8List p1;
  final Uint8List p2;
  final int bytesPerRow;
  final int bytesPerPixel;
  final int width;
  final int height;
  final Pointer<Uint32> output;

  ProcessFrameFrom3PlanesArguments(this.p0, this.p1, this.p2, this.bytesPerRow,
      this.bytesPerPixel, this.width, this.height, this.output);
}

class ProcessFrameFrom3PlanesResult {
  Uint8List image;
  int computationInMiliseconds;

  ProcessFrameFrom3PlanesResult(this.image, [this.computationInMiliseconds = 0]);
}

class ProcessFrameResult {
  Uint8List image;

  ProcessFrameResult(this.image);
}

class FrameProcessing {
  static Future<ProcessFrameResult> processFrame(
      ProcessFrameArguments args) async {
    Uint8List bytes = args.bytes;
    int width = args.width;
    int height = args.height;
    DynamicLibrary dynamicLibrary = _getDynamicLibrary();

    final processFrame = dynamicLibrary
        .lookup<NativeFunction<_frame_processing_function>>("process_frame")
        .asFunction<_FrameProcessingFunction>();

    Pointer<Uint8> src = Uint8ArrayUtils.toPointer(bytes);

    Pointer<Uint8> dst = allocate(count: width * height);
    print(" width * height : ${width * height}");

    var result = processFrame(src, width, height, dst);
    print(result);
    var resultBytes = Uint8ArrayUtils.fromPointer(dst, bytes.length);
    free(src);
    free(dst);
    return ProcessFrameResult(resultBytes);
  }

  static Future<ProcessFrameFrom3PlanesResult> processFrameFrom3Planes(
      ProcessFrameFrom3PlanesArguments args) async {
    Uint8List p0b = args.p0;
    Uint8List p1b = args.p1;
    Uint8List p2b = args.p2;
    int bytesPerRow = args.bytesPerRow;
    int bytesPerPixel = args.bytesPerPixel;
    int width = args.width;
    int height = args.height;
    Pointer<Uint32> outputImagePointer = args.output;
    DynamicLibrary dynamicLibrary = _getDynamicLibrary();

    final processFrameFrom3Planes = dynamicLibrary
        .lookup<NativeFunction<convert_func>>("convert_image")
        .asFunction<Convert>();

    Pointer<Uint8> p0 = Uint8ArrayUtils.toPointer(p0b);
    Pointer<Uint8> p1 = Uint8ArrayUtils.toPointer(p1b);
    Pointer<Uint8> p2 = Uint8ArrayUtils.toPointer(p2b);

    processFrameFrom3Planes(
        p0, p1, p2, bytesPerRow, bytesPerPixel, width, height, outputImagePointer);

    Uint32List frameAfterConversion = outputImagePointer.asTypedList((width*height));
    Uint8List resultImage = img_package.encodeJpg(img_package.Image.fromBytes(height, width, frameAfterConversion), quality: 50);

    free(p0);
    free(p1);
    free(p2);
    return ProcessFrameFrom3PlanesResult(resultImage);
  }

  static DynamicLibrary _getDynamicLibrary() {
    final DynamicLibrary dynamicLibrary = Platform.isAndroid
        ? DynamicLibrary.open("libopencv_binding.so")
        : DynamicLibrary.process();
    return dynamicLibrary;
  }
}

class Uint8ArrayUtils {
  static Pointer<Uint8> toPointer(Uint8List bytes) {
    final ptr = allocate<Uint8>(count: bytes.length);
    final byteList = ptr.asTypedList(bytes.length);
    byteList.setAll(0, bytes);
    return ptr.cast();
  }

  static Uint8List fromPointer(Pointer<Uint8> ptr, int length) {
    final view = ptr.asTypedList(length);
    final builder = BytesBuilder(copy: false);
    builder.add(view);
    return builder.takeBytes();
  }
}

class NativeBufferUtils {
  final DynamicLibrary lib;

  NativeBufferUtils({@required this.lib}) {
    _createBuffer = lib
        .lookup<NativeFunction<Pointer<Uint8> Function(Uint64)>>(
            'ffi_create_buffer')
        .asFunction();

    _freeBuffer = lib
        .lookup<NativeFunction<Void Function(Pointer<Uint8>, Uint64)>>(
            'ffi_free_buffer')
        .asFunction();
  }

  Pointer<Uint8> Function(int) _createBuffer;

  Pointer<Uint8> createBuffer(int size) => _createBuffer(size);

  void Function(Pointer<Uint8>, int) _freeBuffer;

  void freeBuffer(Pointer<Uint8> buffer, int size) => _freeBuffer(buffer, size);
}
