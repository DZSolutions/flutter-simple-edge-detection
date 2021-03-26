import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:simple_edge_detection/edge_detection.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simple_edge_detection_example/cropping_preview.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:cool_alert/cool_alert.dart';

import 'camera_view.dart';
import 'edge_detector.dart';
import 'image_view.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

import 'documentdz.dart';

class Scan extends StatefulWidget {
  @override
  _ScanState createState() => _ScanState();
}

class _ScanState extends State<Scan> {
  CameraController controller;
  List<CameraDescription> cameras;
  String imagePath;
  String croppedImagePath;
  EdgeDetectionResult edgeDetectionResult;
  List<Barcode> _barCode = [];
  var result = "";

  @override
  void initState() {
    super.initState();
    checkForCameras().then((value) {
      _initializeController();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          _getMainWidget(),
          _getBottomBar(),
        ],
      ),
      appBar: new AppBar(
          title: imagePath == null
              ? Text("โปรดถ่ายใบลงทะเบียน")
              : croppedImagePath == null
                  ? Text("ปรับจุดให้ตรงกับกระดาษ")
                  : Text("โปรดตรวจสอบภาพก่อนส่ง")),
    );
  }

  Widget _getMainWidget() {
    if (croppedImagePath != null) {
      return ImageView(imagePath: croppedImagePath);
    }

    if (imagePath == null && edgeDetectionResult == null) {
      return CameraView(controller: controller);
    }

    return ImagePreview(
      imagePath: imagePath,
      edgeDetectionResult: edgeDetectionResult,
    );
  }

  Future<void> checkForCameras() async {
    cameras = await availableCameras();
  }

  void _initializeController() {
    checkForCameras();
    if (cameras.length == 0) {
      log('No cameras detected');
      return;
    }

    controller = CameraController(cameras[0], ResolutionPreset.veryHigh,
        enableAudio: false);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Widget _getButtonRow() {
    if (imagePath != null) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FloatingActionButton(
              heroTag: 'check',
              child: Icon(Icons.check),
              onPressed: () async {
                if (croppedImagePath == null) {
                  return _processImage(imagePath, edgeDetectionResult);
                } else {
                  // FirebaseVisionImage myImage =
                  //     FirebaseVisionImage.fromFilePath(croppedImagePath);
                  // BarcodeDetector barcodeDetector =
                  //     FirebaseVision.instance.barcodeDetector();
                  // _barCode = await barcodeDetector.detectInImage(myImage);
                  // result = "";
                  // for (Barcode barcode in _barCode) {
                  //   result = barcode.displayValue;
                  // }
                  // showDialog(
                  //   context: context,
                  //   builder: (BuildContext context) =>
                  //       _buildPopupDialog(context),
                  // );

                  Navigator.of(context).pushReplacement(new MaterialPageRoute(
                      builder: (BuildContext context) => Result(
                            valueFromHome: result,
                          )));
                }

                setState(() {
                  imagePath = null;
                  edgeDetectionResult = null;
                  croppedImagePath = null;
                });
              },
            ),
            // croppedImagePath == null ? SizedBox() : SizedBox(width: 16),
            // croppedImagePath == null
            //     ? SizedBox()
            //     : FloatingActionButton(
            //         foregroundColor: Colors.white,
            //         child: Icon(Icons.save),
            //         onPressed: () {
            //           GallerySaver.saveImage(croppedImagePath);
            //           print("save!");
            //         },
            //       ),
          ],
        ),
      );
    }

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      FloatingActionButton(
        heroTag: 'camera',
        foregroundColor: Colors.white,
        child: Icon(Icons.camera_alt),
        onPressed: onTakePictureButtonPressed,
      ),
      SizedBox(width: 16),
      FloatingActionButton(
        heroTag: 'gallery',
        foregroundColor: Colors.white,
        child: Icon(Icons.image),
        onPressed: _onGalleryButtonPressed,
      ),
    ]);
  }

  Widget _buildPopupDialog(BuildContext context) {
    return new AlertDialog(
      title: const Text('อ่าน QR Code ผิดพลาด'),
      content: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('กรุณาถ่ายภาพใหม่อีกครั้งให้ครอบคลุมทั้งแบบฟอร์ม'),
        ],
      ),
      actions: <Widget>[
        new TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('โอเค'),
        ),
      ],
    );
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<String> takePicture() async {
    if (!controller.value.isInitialized) {
      log('Error: select a camera first.');
      return null;
    }

    final Directory extDir = await getTemporaryDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (controller.value.isTakingPicture) {
      return null;
    }

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      log(e.toString());
      return null;
    }
    return filePath;
  }

  Future _detectEdges(String filePath) async {
    if (!mounted || filePath == null) {
      return;
    }

    setState(() {
      imagePath = filePath;
    });

    EdgeDetectionResult result = await EdgeDetector().detectEdges(filePath);

    setState(() {
      edgeDetectionResult = result;
    });
  }

  Future _processImage(
      String filePath, EdgeDetectionResult edgeDetectionResult) async {
    if (!mounted || filePath == null) {
      return;
    }

    bool result =
        await EdgeDetector().processImage(filePath, edgeDetectionResult);

    if (result == false) {
      return;
    }

    setState(() {
      imageCache.clearLiveImages();
      imageCache.clear();
      croppedImagePath = imagePath;
    });
  }

  void onTakePictureButtonPressed() async {
    String filePath = await takePicture();

    log('Picture saved to $filePath');

    FirebaseVisionImage myImage = FirebaseVisionImage.fromFilePath(filePath);
    BarcodeDetector barcodeDetector = FirebaseVision.instance.barcodeDetector();
    _barCode = await barcodeDetector.detectInImage(myImage);
    result = "";
    for (Barcode barcode in _barCode) {
      result = barcode.displayValue;
      print("RESULT: " + result);
    }
    if (result.contains('DZCard')) {
      await _detectEdges(filePath);
    } else {
      CoolAlert.show(
        context: context,
        type: CoolAlertType.error,
        title: "อ่าน QR Code ผิดพลาด",
        text: "กรุณาถ่ายภาพใหม่อีกครั้งให้ครอบคลุมทั้งแบบฟอร์ม",
        confirmBtnText: "ตกลง",
      );
    }
  }

  void _onGalleryButtonPressed() async {
    ImagePicker picker = ImagePicker();
    PickedFile pickedFile = await picker.getImage(source: ImageSource.gallery);
    final filePath = pickedFile.path;

    log('Picture saved to $filePath');

    FirebaseVisionImage myImage = FirebaseVisionImage.fromFilePath(filePath);
    BarcodeDetector barcodeDetector = FirebaseVision.instance.barcodeDetector();
    _barCode = await barcodeDetector.detectInImage(myImage);
    result = "";
    for (Barcode barcode in _barCode) {
      result = barcode.displayValue;
    }
    if (result.contains('DZCard')) {
      await _detectEdges(filePath);
    } else {
      // showDialog(
      //   context: context,
      //   builder: (BuildContext context) => _buildPopupDialog(context),
      // );
      CoolAlert.show(
        context: context,
        type: CoolAlertType.error,
        title: "อ่าน QR Code ผิดพลาด",
        text: "กรุณาถ่ายภาพใหม่อีกครั้งให้ครอบคลุมทั้งแบบฟอร์ม",
        confirmBtnText: "ตกลง",
      );
    }
  }

  Padding _getBottomBar() {
    return Padding(
        padding: EdgeInsets.only(bottom: 32),
        child:
            Align(alignment: Alignment.bottomCenter, child: _getButtonRow()));
  }
}

class Result extends StatefulWidget {
  final String valueFromHome;
  Result({Key key, this.valueFromHome}) : super(key: key);

  @override
  _ResultState createState() => new _ResultState();
}

class _ResultState extends State<Result> {
  DocumentDz _dataFromDZ;
  @override
  Widget build(BuildContext context) {
    final List<String> qrData = widget.valueFromHome.split(',');

    _dataFromDZ = DocumentDz(
        branchId: qrData[0],
        memberId: qrData[1],
        docType: qrData[2],
        ownerId: qrData[3]);
    // _dataFromDZ.memberId = 100;
    // _dataFromDZ.docType = 100;
    // _dataFromDZ.ownerId = 100;
    return new Scaffold(
      appBar: new AppBar(title: new Text("ผลลัพธ์")),
      // body: new Text("${widget.valueFromHome}"));
      // body: Center(
      //   child: Text("${widget.valueFromHome}"),
      // ));
      body: ListView(
        children: <Widget>[
          // ListTile(
          //   leading: Icon(Icons.qr_code),
          //   title: Text('QR By'),
          //   subtitle: Text('${widget.valueFromHome}'),
          // ),
          ListTile(
            leading: Icon(Icons.store),
            title: Text('บริษัทออกแบบใบลงทะเบียน'),
            subtitle: Text(_dataFromDZ.branchId),
          ),
          // Divider(),
          // ListTile(
          //   leading: Icon(Icons.store),
          //   title: Text('Branch'),
          //   subtitle: Text('D Z C A R D'),
          // ),
          Divider(),
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('รหัสลูกค้า'),
            subtitle: Text(_dataFromDZ.memberId),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.paste_sharp),
            title: Text('ประเภทของใบสมัคร'),
            subtitle: Text(_dataFromDZ.docType),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.location_city),
            title: Text('เจ้าของบริษัท'),
            subtitle: Text(_dataFromDZ.ownerId),
          ),
          Divider(),
        ],
      ),
    );
  }
}
