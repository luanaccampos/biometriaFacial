import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image/image.dart' as imglib;

class CameraPage extends StatefulWidget {
  final List<CameraDescription>? cameras;
  const CameraPage({this.cameras, Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController controller;
  XFile? pictureFile;

  @override
  void initState() {
    super.initState();
    controller = CameraController(
      widget.cameras![1],
      ResolutionPreset.max,
    );
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void takePicture() async {
    var photo = await controller.takePicture();
    var d = await decodeImageFromList(File(photo.path).readAsBytesSync());

    int h = d.height;
    int w = d.width;

    //log('${d.height} ${d.width}');

    var img = imglib.decodeImage(File(photo.path).readAsBytesSync())!;
    img = imglib.copyCrop(img, w ~/ 4, h ~/ 4, w ~/ 2, h ~/ 2);
    var b = imglib.encodePng(img);

    File f = await File(photo.path).writeAsBytes(b);

    Navigator.pop(context, f);
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const SizedBox(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Stack(
      alignment: FractionalOffset.center,
      children: [
        Positioned.fill(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
        FractionallySizedBox(
          heightFactor: 1,
          widthFactor: 1,
          child: ColorFiltered(
            colorFilter:
                const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: Align(
                    alignment: Alignment.center,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      heightFactor: 0.5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35), color: Colors.white),
            child: IconButton(
              icon: const Icon(Icons.camera_alt_outlined),
              onPressed: takePicture,
              color: Colors.black,
              iconSize: 40,
            ),
          ),
        ),
      ],
    );
  }
}
