import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class FullScreenCameraPreview extends StatelessWidget {
  final CameraController controller;
  final int rotation;
  const FullScreenCameraPreview({
    required this.controller,
    required this.rotation,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(child: Text('Camera not initialized'));
    }
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final previewSize = controller.value.previewSize!;
    final cameraAspectRatio = previewSize.height / previewSize.width;
    final xScale = cameraAspectRatio / deviceRatio;
    return Center(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationZ(math.pi / 180),
        child: Transform.scale(scale: xScale, child: CameraPreview(controller)),
      ),
    );
  }
}
