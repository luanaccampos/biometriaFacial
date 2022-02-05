import 'dart:io';
import 'dart:math';
import 'dart:developer' as dev;
import 'dart:typed_data';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imglib;

class FaceRecognizer {
  late Interpreter _interpreter;
  FaceDetector faceDetector = GoogleMlKit.vision.faceDetector(
      const FaceDetectorOptions(
          enableContours: false,
          enableClassification: false,
          enableLandmarks: false,
          enableTracking: false,
          mode: FaceDetectorMode.fast,
          minFaceSize: 0.7));

  Future loadModel() async {
    Delegate delegate;
    try {
      if (Platform.isAndroid) {
        delegate = GpuDelegateV2(
            options: GpuDelegateOptionsV2(
                inferencePreference: TfLiteGpuInferenceUsage.fastSingleAnswer,
                inferencePriority1: TfLiteGpuInferencePriority.minLatency));
      } else {
        delegate = GpuDelegate();
      }
      var interpreterOptions = InterpreterOptions()..addDelegate(delegate);

      _interpreter = await Interpreter.fromAsset('mobilefacenet.tflite',
          options: interpreterOptions);
      dev.log('Modelo carregado com sucesso');
    } catch (e) {
      dev.log('FALHA EM CARREGAR O MODELO');
      dev.log(e.toString());
    }
  }

  Future<List> getEmbeddings(String path) async {
    var emb = [];

    final faces =
        await faceDetector.processImage(InputImage.fromFilePath(path));

    imglib.Image im1 = imglib.decodeImage(File(path).readAsBytesSync())!;

    for (Face f in faces) {
      List input = _preProcess(im1, f);
      input = input.reshape([1, 112, 112, 3]);
      List output = List.generate(1, (index) => List.filled(192, 0));
      _interpreter.run(input, output);
      output = output.reshape([192]);
      emb.add(output);
    }

    return emb;
  }

  double compare(List e1, List e2) {
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow((e1[i] - e2[i]), 2);
    }
    sum = sqrt(sum);

    return 100 - sum * 25;
  }

  List _preProcess(imglib.Image image, Face faceDetected) {
    imglib.Image croppedImage = _cropFace(image, faceDetected);
    imglib.Image img = imglib.copyResizeCropSquare(croppedImage, 112);

    Float32List imageAsList = imageToByteListFloat32(img);
    return imageAsList;
  }

  imglib.Image _cropFace(imglib.Image image, Face faceDetected) {
    double x = faceDetected.boundingBox.left - 10.0;
    double y = faceDetected.boundingBox.top - 10.0;
    double w = faceDetected.boundingBox.width + 10.0;
    double h = faceDetected.boundingBox.height + 10.0;
    return imglib.copyCrop(image, x.round(), y.round(), w.round(), h.round());
  }

  Float32List imageToByteListFloat32(imglib.Image image) {
    /// input size = 112
    var convertedBytes = Float32List(1 * 112 * 112 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < 112; i++) {
      for (var j = 0; j < 112; j++) {
        var pixel = image.getPixel(j, i);

        /// mean: 128
        /// std: 128
        buffer[pixelIndex++] = (imglib.getRed(pixel) - 128) / 128;
        buffer[pixelIndex++] = (imglib.getGreen(pixel) - 128) / 128;
        buffer[pixelIndex++] = (imglib.getBlue(pixel) - 128) / 128;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }
}
