import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class DocumentAIService {
  final String projectId;
  final String processorId;
  final String location;

  DocumentAIService({
    required this.projectId,
    required this.processorId,
    this.location = "us", // Default region
  });

  Future<List<String>> processImage(File imageFile) async {
    // Get Firebase ID token
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) await FirebaseAuth.instance.signInAnonymously();
    final token = await user!.getIdToken();

    // Prepare API request
    final url =
        "https://$location-documentai.googleapis.com/v1/projects/$projectId/locations/$location/processors/$processorId:process";

    // Read image file as base64
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    // Prepare JSON request payload
    final requestBody = {
      "rawDocument": {
        "content": base64Image,
        "mimeType": "image/jpeg", // Change if needed
      },
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final extractedText = responseData["document"]["text"] ?? "";

        // ✅ Filter and return only relevant drug names & dosage instructions
        return _filterRelevantWords(extractedText);
      } else {
        throw Exception("Failed to process image: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error processing image: $e");
    }
  }

  List<String> _filterRelevantWords(String text) {
    final words = text.split(RegExp(r"\s+")); // Split by spaces
    final filteredWords = <String>[];

    for (final word in words) {
      for (final drug in drugList) {
        if (word.toLowerCase().contains(drug.toLowerCase())) {
          filteredWords.add(drug);
        }
      }
    }

    return filteredWords.toSet().toList(); // Remove duplicates
  }

  // ✅ Predefined list of recognized drug names & medical instructions
  final List<String> drugList = [
    "Lipitor",
    "Ibuprofen",
    "Aspirin",
    "Amoxicillin",
    "Metformin",
    "Losartan",
    "Omeprazole",
    "Atorvastatin",
    "Simvastatin",
    "Hydrochlorothiazide",
    "Paracetamol",
    "Allergy",
    "AstraZeneca",
    "Cancer",
    "1 tab a day",
    "Take 1 tablet daily",
    "Twice a day",
    "Every 8 hours",
    "Before meals",
    "After meals",
    "With water",
  ];
}
