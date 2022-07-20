import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:oncameraposenet/camera_page.dart';
import 'package:oncameraposenet/camera_page2.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  bool isLoading = false;
  final ButtonStyle style =
      ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Text("Live Feed Models"),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.black),
              ),
              onPressed: () async {
                await availableCameras().then((value) => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CameraPage(
                          camerass: value,
                        ),
                      ),
                    ));
              },
              child: const Text('PoseNet'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.black),
              ),
              onPressed: () async {
                await availableCameras().then((value) => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => cameraPage2(
                          cameras: value,
                        ),
                      ),
                    ));
              },
              child: const Text('ObjectDetection'),
            ),
          ],
        ),
      ));
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      body: Center(
          child: SpinKitCubeGrid(
        color: Colors.black,
        size: 140,
        itemBuilder: (context, index) {
          return DecoratedBox(
              decoration: BoxDecoration(
                  color: Colors.amber, shape: BoxShape.rectangle));
        },
      )),
    );
  }
}
