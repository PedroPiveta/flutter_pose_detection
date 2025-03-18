import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PoseDetectionScreen(),
    );
  }
}

class PoseDetectionScreen extends StatefulWidget {
  @override
  _PoseDetectionScreenState createState() => _PoseDetectionScreenState();
}

class _PoseDetectionScreenState extends State<PoseDetectionScreen> {
  File? _image;
  ui.Image? _decodedImage;
  List<Pose>? _poses;
  final ImagePicker _picker = ImagePicker();
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(model: PoseDetectionModel.accurate),
  );

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      final bytes = await imageFile.readAsBytes();
      decodeImageFromList(bytes).then((decodedImage) {
        setState(() {
          _image = imageFile;
          _decodedImage = decodedImage;
        });
      });
      _detectPose(imageFile);
    }
  }

  Future<void> _detectPose(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final poses = await _poseDetector.processImage(inputImage);
    setState(() {
      _poses = poses;
    });
  }

  @override
  void dispose() {
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pose Detection')),
      body: Column(
        children: [
          if (_image != null && _decodedImage != null)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double displayWidth = constraints.maxWidth;
                  double displayHeight =
                      displayWidth *
                      (_decodedImage!.height / _decodedImage!.width);

                  return Center(
                    child: SizedBox(
                      width: displayWidth,
                      height: displayHeight,
                      child: Stack(
                        children: [
                          Image.file(
                            _image!,
                            width: displayWidth,
                            height: displayHeight,
                            fit: BoxFit.cover,
                          ),
                          if (_poses != null)
                            CustomPaint(
                              size: Size(displayWidth, displayHeight),
                              painter: PosePainter(
                                _poses!,
                                Size(
                                  _decodedImage!.width.toDouble(),
                                  _decodedImage!.height.toDouble(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          SizedBox(height: 10),
          ElevatedButton(onPressed: _pickImage, child: Text('Escolher Imagem')),
        ],
      ),
    );
  }
}

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;

  PosePainter(this.poses, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paintPoints =
        Paint()
          ..color = Colors.red
          ..strokeWidth = 5.0
          ..style = PaintingStyle.fill;

    final paintLines =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    for (Pose pose in poses) {
      final landmarks = pose.landmarks;

      // Conectar os pontos com linhas
      _drawLine(
        canvas,
        paintLines,
        landmarks,
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.rightShoulder,
        scaleX,
        scaleY,
      );
      _drawLine(
        canvas,
        paintLines,
        landmarks,
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftElbow,
        scaleX,
        scaleY,
      );
      _drawLine(
        canvas,
        paintLines,
        landmarks,
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.leftWrist,
        scaleX,
        scaleY,
      );
      _drawLine(
        canvas,
        paintLines,
        landmarks,
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightElbow,
        scaleX,
        scaleY,
      );
      _drawLine(
        canvas,
        paintLines,
        landmarks,
        PoseLandmarkType.rightElbow,
        PoseLandmarkType.rightWrist,
        scaleX,
        scaleY,
      );
      _drawLine(
        canvas,
        paintLines,
        landmarks,
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftHip,
        scaleX,
        scaleY,
      );
      _drawLine(
        canvas,
        paintLines,
        landmarks,
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightHip,
        scaleX,
        scaleY,
      );
      _drawLine(
        canvas,
        paintLines,
        landmarks,
        PoseLandmarkType.leftHip,
        PoseLandmarkType.rightHip,
        scaleX,
        scaleY,
      );
      _drawLine(
        canvas,
        paintLines,
        landmarks,
        PoseLandmarkType.leftHip,
        PoseLandmarkType.leftKnee,
        scaleX,
        scaleY,
      );
      _drawLine(
        canvas,
        paintLines,
        landmarks,
        PoseLandmarkType.leftKnee,
        PoseLandmarkType.leftAnkle,
        scaleX,
        scaleY,
      );
      _drawLine(
        canvas,
        paintLines,
        landmarks,
        PoseLandmarkType.rightHip,
        PoseLandmarkType.rightKnee,
        scaleX,
        scaleY,
      );
      _drawLine(
        canvas,
        paintLines,
        landmarks,
        PoseLandmarkType.rightKnee,
        PoseLandmarkType.rightAnkle,
        scaleX,
        scaleY,
      );

      // Desenha os pontos
      for (PoseLandmark landmark in landmarks.values) {
        final x = landmark.x * scaleX;
        final y = landmark.y * scaleY;
        canvas.drawCircle(Offset(x, y), 5, paintPoints);
      }
    }
  }

  void _drawLine(
    Canvas canvas,
    Paint paint,
    Map<PoseLandmarkType, PoseLandmark> landmarks,
    PoseLandmarkType start,
    PoseLandmarkType end,
    double scaleX,
    double scaleY,
  ) {
    if (landmarks.containsKey(start) && landmarks.containsKey(end)) {
      final startPoint = Offset(
        landmarks[start]!.x * scaleX,
        landmarks[start]!.y * scaleY,
      );
      final endPoint = Offset(
        landmarks[end]!.x * scaleX,
        landmarks[end]!.y * scaleY,
      );
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
