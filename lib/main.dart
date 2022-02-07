import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'face_recognizer.dart';
import 'camera_page.dart';
import 'package:camera/camera.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    home: const Home(),
    builder: EasyLoading.init(),
  ));
  configLoading();
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 1000)
    ..userInteractions = false
    ..dismissOnTap = false;
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FaceRecognizer _faceRecognizer = FaceRecognizer();
  late Pessoa p1, p2;
  late bool load1, load2;
  late int t1, t2;
  late double sim;
  Color corAuth = const Color.fromRGBO(121, 68, 204, 1);
  Timer? _timer;
  Stopwatch stopwatch = Stopwatch();

  @override
  void initState() {
    _faceRecognizer.loadModel();
    super.initState();

    load1 = load2 = false;
    Image img = const Image(image: AssetImage('assets/unknown.jpg'));
    p1 = p2 = Pessoa(img, []);
    t1 = t2 = 0;
    sim = 0;

    EasyLoading.addStatusCallback((status) {
      if (status == EasyLoadingStatus.dismiss) {
        _timer?.cancel();
      }
    });
  }

  void abreCameraPage(bool flag) async {
    List<CameraDescription> c = await availableCameras();

    File input = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraPage(
          cameras: c,
        ),
      ),
    );

    processaRostosImagem(input, flag);
  }

  void processaRostosImagem(File? input, bool flag) async {
    if (input != null) {
      await EasyLoading.show();

      stopwatch.reset();
      stopwatch.start();
      var l = await _faceRecognizer.getEmbeddings(input.path);
      int t = stopwatch.elapsed.inMilliseconds;
      stopwatch.stop();

      log('${l.length} detected faces.');
      log('$t ms to process faces.');

      if (l.isNotEmpty) {
        Pessoa p = Pessoa(Image.file(File(input.path)), l);
        if (flag) {
          p1 = p;
          load1 = true;
          t1 = t;
        } else {
          p2 = p;
          load2 = true;
          t2 = t;
        }

        setState(() {});
        EasyLoading.showSuccess('Face detectada com sucesso!');
      } else {
        EasyLoading.showError('Nenhuma face detectada!');
      }
    }
  }

  void compara() {
    bool igual = false;

    for (var e1 in p1.emb) {
      for (var e2 in p2.emb) {
        sim = _faceRecognizer.compare(e1, e2);
        if (sim >= 75) {
          igual = true;
          break;
        }
      }
    }

    if (igual) {
      EasyLoading.showSuccess('Autenticado com sucesso!');
      corAuth = Colors.greenAccent;
    } else {
      EasyLoading.showError('Falha na autenticação!');
      corAuth = Colors.redAccent;
    }

    setState(() {});
  }

  void reset() {
    setState(() {
      corAuth = const Color.fromRGBO(121, 68, 204, 1);
      p1.clear();
      p2.clear();
      t1 = t2 = 0;
      sim = 0;
      load1 = load2 = false;
    });
  }

  bool get imgsLoad => load1 && load2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reconhecimento facial'),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(121, 68, 204, 1),
        actions: [
          IconButton(onPressed: reset, icon: const Icon(Icons.refresh))
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTap: () => abreCameraPage(true),
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: corAuth,
                      child: CircleAvatar(
                        radius: 65,
                        backgroundImage: p1.img.image,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      children: [
                        const Icon(Icons.timer),
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Text('$t1 ms'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        const Icon(Icons.face),
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Text('${p1.emb.length}'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () => abreCameraPage(false),
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: corAuth,
                      child: CircleAvatar(
                        radius: 65,
                        backgroundImage: p2.img.image,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      children: [
                        const Icon(Icons.timer),
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Text('$t2 ms'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      children: [
                        const Icon(Icons.face),
                        Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child: Text('${p2.emb.length}')),
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
          TextButton(
            onPressed: imgsLoad ? () => compara() : null,
            style: TextButton.styleFrom(
              backgroundColor: imgsLoad
                  ? const Color.fromRGBO(121, 68, 204, 1)
                  : const Color.fromRGBO(121, 68, 204, 1).withOpacity(0.2),
              fixedSize: const Size(300, 100),
              primary: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'MATCH',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people),
              Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text('${sim.toStringAsPrecision(3)} %')),
            ],
          )
        ],
      ),
    );
  }
}

class Pessoa {
  Image img;
  List emb = [];

  Pessoa(this.img, this.emb);

  void clear() {
    img = const Image(image: AssetImage('assets/unknown.jpg'));
    emb.clear();
  }
}
