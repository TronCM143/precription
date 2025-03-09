import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class UploadToCloud extends StatefulWidget {
  final File imageFile; // Receive image as a parameter

  const UploadToCloud({super.key, required this.imageFile});

  @override
  State<UploadToCloud> createState() => _UploadToCloudState();
}

class _UploadToCloudState extends State<UploadToCloud> {
  String? imageUrl; // Stores the uploaded image URL

  @override
  void initState() {
    super.initState();
    _uploadImage(); // Upload image on widget creation
  }

  Future<void> _uploadImage() async {
    String cloudName = "your_cloud_name";
    String apiKey = "your_api_key";
    String uploadPreset = "your_upload_preset";

    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(widget.imageFile.path),
      "upload_preset": uploadPreset, // Cloudinary preset
      "api_key": apiKey,
    });

    try {
      var response = await Dio().post(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
        data: formData,
      );

      setState(() {
        imageUrl = response.data["secure_url"]; // Store uploaded image URL
      });

      print("Image Uploaded: $imageUrl");
    } catch (e) {
      print("Upload Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload to Cloudinary")),
      body: Center(
        child:
            imageUrl == null
                ? const CircularProgressIndicator()
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(imageUrl!), // Show uploaded image
                    const SizedBox(height: 10),
                    SelectableText(imageUrl!), // Copyable image URL
                  ],
                ),
      ),
    );
  }
}
