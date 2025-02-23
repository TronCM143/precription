import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class Home extends StatefulWidget {
  final List<CameraDescription> cameras;
  const Home(this.cameras, {Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  CameraController? controller;
  bool isCameraInitialized = false;
  int cameraRotation = 0;
  bool isCapturing = false; // Prevent multiple captures

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    if (widget.cameras.isEmpty) return;
    controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await controller!.initialize();
      if (!mounted) return;
      final int rotation = widget.cameras[0].sensorOrientation;
      setState(() {
        cameraRotation = rotation;
        isCameraInitialized = true;
      });
    } catch (e) {
      print("Camera error: $e");
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> capturePhoto() async {
    // Prevent duplicate taps if already capturing
    if (isCapturing) return;
    setState(() {
      isCapturing = true;
    });
    try {
      // Turn off the flash before capturing
      await controller!.setFlashMode(FlashMode.off);
      final XFile file = await controller!.takePicture();

      // Show preview dialog with the captured image
      bool? save = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Preview'),
            content: Image.file(File(file.path)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // Cancel saving
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // Save image
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
      if (save == null || !save) {
        // User cancelled: delete the captured file
        final fileToDelete = File(file.path);
        if (await fileToDelete.exists()) {
          await fileToDelete.delete();
        }
        print("Photo capture cancelled, file deleted.");
      } else {
        print("Photo saved: ${file.path}");
        // Here you could move the file to permanent storage if desired.
      }
    } catch (e) {
      print("Capture error: $e");
    } finally {
      setState(() {
        isCapturing = false;
      });
    }
  }

  void pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      print("Selected image: ${image.path}");
    }
  }

  void openSettings() {
    print("Open camera settings");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          isCameraInitialized
              ? FullScreenCameraPreview(
                controller: controller!,
                rotation: cameraRotation,
              )
              : const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.photo, size: 40, color: Colors.white),
                  onPressed: pickFromGallery,
                ),
                GestureDetector(
                  onTap: isCapturing ? null : capturePhoto,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.settings,
                    size: 40,
                    color: Colors.white,
                  ),
                  onPressed: openSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenCameraPreview extends StatelessWidget {
  final CameraController controller;
  final int rotation;
  const FullScreenCameraPreview({
    required this.controller,
    required this.rotation,
  });

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
