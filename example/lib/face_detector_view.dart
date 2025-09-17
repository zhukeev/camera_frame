import 'package:camera_example/face_detector_painter.dart';
import 'package:camera_frame/camera_frame.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'detector_view.dart';

class FaceDetectorView extends StatefulWidget {
  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(enableContours: true, enableLandmarks: true),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  bool _isFrameBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.front;

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetectorView(
      title: 'Face Detector',
      customPaint: _customPaint,
      text: _text,
      onImage: _processImage,
      onFrame: _processFrameImage,
      initialCameraLensDirection: _cameraLensDirection,
      onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
    );
  }

  List<Face> _frameFaces = <Face>[];
  List<Face> _imageFaces = <Face>[];
  InputImageMetadata? _frameMetadata;
  InputImageMetadata? _imageMetadata;

  Future<void> _processFrameImage(InputImage inputImage) async {
    if (!_canProcess) return;
    // if (_isBusy) return;
    // _isBusy = true;
    setState(() {
      _text = '';
    });
    final faces = await _faceDetector.processImage(inputImage);
    print('_processFrameImage faces: ${faces.length}');
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      _frameFaces = faces;
      _frameMetadata = inputImage.metadata;
      _updateCustomPainter();
    } else {
      String text = 'Faces found: ${faces.length}\n\n';
      for (final face in faces) {
        text += 'face: ${face.boundingBox}\n\n';
      }
      _text = text;
      // TODO: set _customPaint to draw boundingRect on top of image
      _customPaint = null;
    }
    // _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    // if (_isBusy) return;
    // _isBusy = true;
    setState(() {
      _text = '';
    });
    final faces = await _faceDetector.processImage(inputImage);
    print('_processImage faces: ${faces.length}');

    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      _imageFaces = faces;
      _imageMetadata = inputImage.metadata;

      _updateCustomPainter();
    } else {
      String text = 'Faces found: ${faces.length}\n\n';
      for (final face in faces) {
        text += 'face: ${face.boundingBox}\n\n';
      }
      _text = text;
      // TODO: set _customPaint to draw boundingRect on top of image
      _customPaint = null;
    }
    // _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _updateCustomPainter() {
    FaceDetectorPainter? _framePainter;
    FaceDetectorPainter? _imagePainter;

    if (_frameFaces.isNotEmpty && _frameMetadata != null) {
      _framePainter = FaceDetectorPainter(
        _frameFaces,
        _frameMetadata!.size,
        _frameMetadata!.rotation,
        _cameraLensDirection,
        color: Colors.yellow,
      );
    }
    if (_imageFaces.isNotEmpty && _imageMetadata != null) {
      _imagePainter = FaceDetectorPainter(
        [..._imageFaces],
        _imageMetadata!.size,
        _imageMetadata!.rotation,
        _cameraLensDirection,
      );
    }

    _customPaint = CustomPaint(
      painter: _imagePainter,
      foregroundPainter: _framePainter,
    );
  }
}
