import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_lite_camera/flutter_lite_camera.dart';
import 'dart:ui' as ui;

class CamViewV2 extends StatelessWidget {
  const CamViewV2({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: CameraApp());
  }
}

class CameraApp extends StatefulWidget {
  const CameraApp({super.key});

  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  final FlutterLiteCamera _flutterLiteCameraPlugin = FlutterLiteCamera();
  bool _isCameraOpened = false;
  bool _isCapturing = false;
  final int _width = 640;
  final int _height = 480;
  ui.Image? _latestFrame;
  bool _shouldCapture = false;

  @override
  void initState() {
    super.initState();
    _handleWindowClose();
  }

  Future<void> _startCamera() async {
    try {
      List<String> devices = await _flutterLiteCameraPlugin.getDeviceList();
      if (devices.isNotEmpty) {
        bool opened = await _flutterLiteCameraPlugin.open(0);
        if (opened) {
          setState(() {
            _isCameraOpened = true;
            _shouldCapture = true;
          });

          // Start capturing frames
          _isCapturing = true;
          _captureFrames();
        } else {}
      }
    } catch (e) {
      // print("Error initializing camera: $e");
    }
  }

  Future<void> _captureFrames() async {
    if (!_isCameraOpened || !_shouldCapture) return;

    try {
      Map<String, dynamic> frame =
          await _flutterLiteCameraPlugin.captureFrame();
      if (frame.containsKey('data')) {
        Uint8List rgbBuffer = frame['data'];
        await _convertBufferToImage(rgbBuffer, frame['width'], frame['height']);
      }
    } catch (e) {
      // print("Error capturing frame: $e");
    }

    // Schedule the next frame
    if (_shouldCapture) {
      Future.delayed(const Duration(milliseconds: 30), _captureFrames);
    }
  }

  Future<void> _convertBufferToImage(
    Uint8List rgbBuffer,
    int width,
    int height,
  ) async {
    final pixels = Uint8List(width * height * 4); // RGBA buffer

    for (int i = 0; i < width * height; i++) {
      int r = rgbBuffer[i * 3];
      int g = rgbBuffer[i * 3 + 1];
      int b = rgbBuffer[i * 3 + 2];

      // Populate RGBA buffer
      pixels[i * 4] = b;
      pixels[i * 4 + 1] = g;
      pixels[i * 4 + 2] = r;
      pixels[i * 4 + 3] = 255; // Alpha channel
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );

    final image = await completer.future;
    setState(() {
      _latestFrame = image;
    });
  }

  Future<void> _stopCamera() async {
    setState(() {
      _shouldCapture = false;
    });

    if (_isCameraOpened) {
      await _flutterLiteCameraPlugin.release();
      setState(() {
        _isCameraOpened = false;
        _latestFrame = null;
      });
    }

    _isCapturing = false;
  }

  void _handleWindowClose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChannels.lifecycle.setMessageHandler((message) async {
        if (message == AppLifecycleState.detached.toString()) {
          await _stopCamera();
        }
        return null;
      });
    });
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: Stack(
        children: [
          if (_latestFrame != null)
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;
                final imageAspectRatio = _width / _height;
                final screenAspectRatio = screenWidth / screenHeight;

                double drawWidth, drawHeight;
                if (imageAspectRatio > screenAspectRatio) {
                  drawWidth = screenWidth;
                  drawHeight = screenWidth / imageAspectRatio;
                } else {
                  drawHeight = screenHeight;
                  drawWidth = screenHeight * imageAspectRatio;
                }

                return Center(
                  child: Transform.flip(
                    flipX: true,

                    child: CustomPaint(
                      painter: FramePainter(_latestFrame!),
                      child: SizedBox(width: drawWidth, height: drawHeight),
                    ),
                  ),
                );
              },
            )
          else
            Center(child: Text('Camera not initialized or no frame captured')),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Start Button
                ElevatedButton(
                  onPressed: _isCapturing ? null : () => _startCamera(),
                  child: const Text('Start'),
                ),
                // Stop Button
                ElevatedButton(
                  onPressed: !_isCapturing ? null : () => _stopCamera(),
                  child: const Text('Stop'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FramePainter extends CustomPainter {
  final ui.Image image;

  FramePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
