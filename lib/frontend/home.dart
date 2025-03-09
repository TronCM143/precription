import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔹 Firestore integration
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_core/firebase_core.dart'; // 🔹 Firebase Core
import 'package:firebase_auth/firebase_auth.dart';
import 'package:precription/backend/processor.dart'; // 🔹 Firebase Auth

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  CameraController? controller;
  bool isCameraInitialized = false;
  bool isCapturing = false;
  int cameraRotation = 0;
  String extractedText = "No text extracted yet."; // 🔹 Holds extracted text

  // 🔹 Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Document AI Service
  late final DocumentAIService _documentAI;

  @override
  void initState() {
    super.initState();
    initializeCamera();

    // Initialize Document AI Service
    _documentAI = DocumentAIService(
      projectId: "prescription-451914", // Replace with your project ID
      processorId: "4bd246b055005fa5", // Replace with your processor ID
      location: "us", // Default region
    );
  }

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print("No cameras found.");
        return;
      }

      controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller!.initialize();
      if (!mounted) return;

      setState(() {
        cameraRotation = cameras[0].sensorOrientation;
        isCameraInitialized = true;
      });
    } catch (e) {
      print("Camera initialization error: $e");
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> capturePhoto() async {
    if (isCapturing || controller == null || !controller!.value.isInitialized) {
      print("⚠️ Camera is not ready.");
      return;
    }

    if (_documentAI == null) {
      print("⚠️ DocumentAIService is not initialized.");
      return;
    }

    setState(() => isCapturing = true);

    try {
      await controller!.setFlashMode(FlashMode.off);
      final XFile file = await controller!.takePicture();

      bool? save = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Preview'),
              content: Image.file(File(file.path)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            ),
      );

      if (save == true) {
        final savedFile = await saveImageToAppFolder(file);
        if (savedFile == null) {
          print("⚠️ Failed to save image.");
          return;
        }

        final results = await _documentAI.processImage(savedFile);
        setState(() {
          extractedText = results.join(', '); // Update extracted text
        });
        print("✅ Extracted Text: ${results.join(', ')}");
      } else {
        final fileToDelete = File(file.path);
        if (await fileToDelete.exists()) await fileToDelete.delete();
        print("❌ Photo capture cancelled");
      }
    } catch (e) {
      print("⛔ Capture error: $e");
    } finally {
      setState(() => isCapturing = false);
    }
  }

  Future<File?> saveImageToAppFolder(XFile file) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        print("External storage directory not found.");
        return null;
      }

      final folderPath = '${directory.path}/Pictures/CameraImages';
      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final newFilePath =
          '$folderPath/${DateTime.now().millisecondsSinceEpoch}.jpg';
      File originalFile = File(file.path);

      List<int> imageBytes = await originalFile.readAsBytes();
      img.Image? decodedImage = img.decodeImage(Uint8List.fromList(imageBytes));
      if (decodedImage == null) {
        print("Error: Image could not be decoded!");
        return null;
      }

      Uint8List encodedImage = Uint8List.fromList(
        img.encodeJpg(decodedImage, quality: 90),
      );
      File newFile = File(newFilePath)..writeAsBytesSync(encodedImage);

      print("Photo saved successfully at: $newFilePath");
      return newFile;
    } catch (e) {
      print("Error saving image: $e");
      return null;
    }
  }

  void pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File selectedFile = File(image.path);
      final results = await _documentAI.processImage(selectedFile);
      setState(() {
        extractedText = results.join(', '); // Update extracted text
      });
      print("✅ Extracted Text: ${results.join(', ')}");
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
          isCameraInitialized && controller != null
              ? CameraPreview(controller!)
              : const Center(child: CircularProgressIndicator()),

          // 🔹 Overlay text display
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                extractedText,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),

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
