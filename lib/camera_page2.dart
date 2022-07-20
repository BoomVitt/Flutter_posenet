import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class cameraPage2 extends StatefulWidget {
  final List<CameraDescription>? cameras;
  const cameraPage2({Key? key, this.cameras}) : super(key: key);

  @override
  State<cameraPage2> createState() => _cameraPage2State();
}

class _cameraPage2State extends State<cameraPage2> {
  bool isLoading = false;
  late CameraController controller;
  XFile? pictureFile;
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
      widget.cameras![1],
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

  Future loadModel() async {
    Tflite.close();
    try {
      String res;
      res = (await Tflite.loadModel(
        model: "assets/yolov2_tiny.tflite",
        labels: "assets/yolov2_tiny.txt",
        // useGpuDelegate: true,
      ))!;
      print(res);
    } on PlatformException {
      print('Failed to load model.');
    }
  }

  runModelOnFrame() async {
    _imageWidth = img.width + 0.0;
    _imageHeight = img.height + 0.0;
    _recognitions = await Tflite.detectObjectOnFrame(
        bytesList: img.planes.map((plane) {
          return plane.bytes;
        }).toList(), // required
        model: "YOLO",
        imageHeight: img.height,
        imageWidth: img.width,
        imageMean: 0, // defaults to 127.5
        imageStd: 255.0, // defaults to 127.5
        threshold: 0.1, // defaults to 0.1
        numResultsPerClass: 2, // defaults to 5
        anchors:
          [0.57273,0.677385,1.87446,2.06253,3.33843,5.47434,7.88282,3.52778,9.77052,9.16828],
        blockSize: 32, // defaults to 32
        numBoxesPerBlock: 5, // defaults to 5
        asynch: true // defaults to true
        );
    print(_recognitions?.length);
    isBusy = false;
    setState(() {
      img;
    });
  }

  List<Widget> renderBoxes(Size screen) {
    if (_recognitions == null) return [];
    if (_imageHeight == null || _imageWidth == null) return [];

    double factorX = screen.width;
    double factorY = _imageHeight / _imageWidth * screen.width;
    Color blue = Color.fromRGBO(37, 213, 253, 1.0);
    return _recognitions!.map((re) {
      return Positioned(
        left: re["rect"]["x"] * factorX,
        top: re["rect"]["y"] * factorY,
        width: re["rect"]["w"] * factorX,
        height: re["rect"]["h"] * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            border: Border.all(
              color: blue,
              width: 2,
            ),
          ),
          child: Text(
            "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = blue,
              color: Colors.white,
              fontSize: 12.0,
            ),
          ),
        ),
      );
    }).toList();
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
      stackChildren.addAll(renderBoxes(size));
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
