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
  List f1 = [], f2 = [];
  late String p1 = '', p2 = '';
  int t1 = 0, t2 = 0, t3 = 0;
  Color corAuth = const Color.fromRGBO(121, 68, 204, 1);
  XFile? image;
  File? input;
  Timer? _timer;
  double p = 0;

  void abre(bool f) async {
    List<CameraDescription> c = await availableCameras();

    input = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraPage(
          cameras: c,
        ),
      ),
    );

    if (input != null) {
      await EasyLoading.show();
      Stopwatch stopwatch = Stopwatch()..start();
      bool r = await processaFace(f);
      int t = stopwatch.elapsed.inMilliseconds;
      f ? t1 = t : t2 = t;

      log('Processar faces. Tempo de resposta: $t ms');

      if (r) {
        setState(() {
          f ? p1 = input!.path : p2 = input!.path;
          corAuth = const Color.fromRGBO(121, 68, 204, 1);
        });
        EasyLoading.showSuccess('Face detectada com sucesso!');
      } else {
        EasyLoading.showError('Nenhuma face detectada!');
      }
    }
  }

  Future<bool> processaFace(bool f) async {
    var l = await _faceRecognizer.getEmbeddings(input!.path);

    if (l.isNotEmpty) {
      f ? f1 = l : f2 = l;
      return true;
    } else {
      return false;
    }
  }

  void compara() {
    bool r = false;

    p = 0;

    Stopwatch stopwatch = Stopwatch()..start();

    for (var e1 in f1) {
      for (var e2 in f2) {
        p = _faceRecognizer.compare(e1, e2);

        if (p >= 75) {
          r = true;
          break;
        }
      }
    }

    t3 = stopwatch.elapsed.inMilliseconds;
    log('Comparar faces. Tempo de resposta: $t3 ms');

    r
        ? EasyLoading.showSuccess(
            'Autenticado com sucesso! Precisão: ${p.toStringAsPrecision(4)}%')
        : EasyLoading.showError('Autenticação falhou!');

    setState(() {
      r ? corAuth = Colors.greenAccent : corAuth = Colors.red;
    });
  }

  void reset() {
    setState(() {
      p1 = p2 = '';
      t1 = t2 = t3 = 0;
      p = 0.0;

      f1.clear();
      f2.clear();

      corAuth = const Color.fromRGBO(121, 68, 204, 1);
    });
  }

  @override
  void initState() {
    _faceRecognizer.loadModel();
    super.initState();
    EasyLoading.addStatusCallback((status) {
      if (status == EasyLoadingStatus.dismiss) {
        _timer?.cancel();
      }
    });
  }

  bool get imgsLoad => p1 != '' && p2 != '';

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
                    onTap: () => abre(true),
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: corAuth,
                      child: CircleAvatar(
                        radius: 65,
                        backgroundImage: p1 != ''
                            ? Image.file(File(p1)).image
                            : const AssetImage('assets/unknown.jpg'),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 25),
                    child: Text('${f1.length} faces'),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 25),
                    child: Text('$t1 ms'),
                  ),
                ],
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () => abre(false),
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: corAuth,
                      child: CircleAvatar(
                        radius: 65,
                        backgroundImage: p2 != ''
                            ? Image.file(File(p2)).image
                            : const AssetImage('assets/unknown.jpg'),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 25),
                    child: Text('${f2.length} faces'),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 25),
                    child: Text('$t2 ms'),
                  ),
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
          Padding(
            padding: const EdgeInsets.only(top: 25),
            child: Text('Similaridade ${p.toStringAsPrecision(4)}%'),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 25),
            child: Text('$t3 ms'),
          )
        ],
      ),
    );
  }
}
