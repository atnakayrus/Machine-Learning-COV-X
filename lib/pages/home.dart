import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';

import 'package:covx/constants/AppStyle.dart';
import 'package:covx/widgets/card.dart';
import 'package:covx/widgets/emptyCard.dart';

import 'package:image/image.dart' as Img;

import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:tflite_flutter_helper_plus/tflite_flutter_helper_plus.dart'
    as tflh;
// ignore: depend_on_referenced_packages, implementation_imports
import 'package:tflite_flutter_plus/src/bindings/types.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late tfl.Interpreter interpreter;
  late File _image;
  late tflh.TensorBuffer _outputBuffer;
  late tflh.TensorImage _inputImage;
  late List<int> _inputShape;
  late List<int> _outputShape;
  late double output;
  bool imageSelect = false;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future loadModel() async {
    interpreter = await tfl.Interpreter.fromAsset('assets/model.tflite');
    _inputShape = interpreter.getInputTensor(0).shape;
    _outputShape = interpreter.getOutputTensor(0).shape;
    _outputBuffer =
        tflh.TensorBuffer.createFixedSize(_outputShape, TfLiteType.float32);
  }

  Future pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    _image = File(pickedFile!.path);
    Img.Image imageInput = Img.decodeImage(_image.readAsBytesSync())!;
    covidClassification(imageInput);
  }

  tflh.TensorImage _preProcess() {
    int cropSize = min(_inputImage.height, _inputImage.width);
    return tflh.ImageProcessorBuilder()
        .add(tflh.ResizeWithCropOrPadOp(cropSize, cropSize))
        .add(tflh.ResizeOp(
            _inputShape[1], _inputShape[2], tflh.ResizeMethod.nearestneighbour))
        .build()
        .process(_inputImage);
  }

  Future covidClassification(Img.Image image) async {
    _inputImage = tflh.TensorImage(TfLiteType.float32);
    _inputImage.loadImage(image);
    _inputImage = _preProcess();
    interpreter.run(_inputImage.buffer, _outputBuffer.getBuffer());
    setState(() {
      imageSelect = true;
      output = _outputBuffer.getBuffer().asFloat32List()[0];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cov - X"),
        foregroundColor: AppStyle.textCol,
        backgroundColor: AppStyle.accentColor,
        centerTitle: true,
      ),
      backgroundColor: AppStyle.accentOff,
      body: imageSelect
          ? HomeCard(
              image: _image,
              output: output,
            )
          : const EmptyCard(),
      floatingActionButton: FloatingActionButton(
        onPressed: pickImage,
        backgroundColor: AppStyle.accentColor,
        foregroundColor: AppStyle.textCol,
        child: const Icon(Icons.add_photo_alternate_outlined),
      ),
    );
  }
}
