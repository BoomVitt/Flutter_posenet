import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CameraPage extends StatefulWidget {
  final List<CameraDescription>? camerass;
  const CameraPage({this.camerass, Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  bool isLoading = false;
  late CameraController controller;
  bool isBusy = false;
  late CameraImage img;
  List<dynamic>? _recognitions;
  late double _imageHeight;
  late double _imageWidth;
  @override
  void initState() {
    super.initState();
    loadModel();
    controller = CameraController(
      widget.camerass![0],
      ResolutionPreset.max,
    );
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        controller.startImageStream((image) => {
              if (!isBusy) {isBusy = true, img = image, runModelOnFrame()}
            });
      });
    });
  }

  runModelOnFrame() async {
    _imageWidth = 1280;
    _imageHeight = 720;
    _recognitions = await Tflite.runPoseNetOnFrame(
        bytesList: img.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        imageHeight: img.height,
        imageWidth: img.width,
        numResults: 2,
        threshold: 0.7, // defaults to 0.5
        nmsRadius: 10, // defaults to 20
        imageMean: 125.0, // defaults to 125.0
        imageStd: 125.0, // defaults to 125.0
        asynch: true // defaults to true
        );
    print(_recognitions?.length);
    isBusy = false;
    setState(() {
      img;
    });
  }

  @override
  void dispose() {
    controller.stopImageStream();
    Tflite.close();
    super.dispose();
  }

  Future loadModel() async {
    Tflite.close();
    try {
      String res;
      res = (await Tflite.loadModel(
        model: "assets/posenet_mv1_075_float_from_checkpoints.tflite",
        // useGpuDelegate: true,
      ))!;
      print(res);
    } on PlatformException {
      print('Failed to load model.');
    }
  }

  List<Widget> renderKeypoints(Size screen) {
    if (_recognitions == null) return [];
    if (_imageHeight == null || _imageWidth == null) return [];

    double factorX = screen.width;
    double factorY = _imageHeight;

    var lists = <Widget>[];
    _recognitions?.forEach((re) {
      var list = re["keypoints"].values.map<Widget>((k) {
        return Positioned(
          left: k["x"] * factorX - 6,
          top: k["y"] * factorY - 6,
          width: 100,
          height: 20,
          child: Text(
            "● ${k["part"]}",
            style: TextStyle(
              color: Colors.blue,
              fontSize: 10.0,
            ),
          ),
        );
      }).toList();

      lists..addAll(list);
    });

    return lists;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Widget> stackChildren = [];
    if (!controller.value.isInitialized) {
      return const SizedBox(
        child: Center(),
      );
    }
    stackChildren.add(Positioned(
        top: 0.0,
        left: 0.0,
        width: size.width,
        child: Container(
          alignment: Alignment.center,
          color: Colors.black,
          child: (!controller.value.isInitialized)
              ? new Container()
              : AspectRatio(
                  aspectRatio: 1 / 2,
                  child: Container(
                    width: double.infinity,
                    child: CameraPreview(controller),
                  ),
                ),
        )));

    if (img != null) {
      stackChildren.addAll(renderKeypoints(size));
    }

    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: Color.fromARGB(255, 23, 23, 23),
            title: Text("CameraPage"),
            leading: BackButton(
                color: Colors.white,
                onPressed: () {
                  Navigator.pop(context);
                }),
          ),
          backgroundColor: Colors.black,
          body: Container(
              color: Colors.green,
              child: Stack(
                children: stackChildren,
              ))),
    );
  }
}
