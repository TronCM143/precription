import 'package:flutter/material.dart';

// class DraggablePrescriptionUI extends StatefulWidget {
//   const DraggablePrescriptionUI({super.key});

//   @override
//   State<DraggablePrescriptionUI> createState() =>
//       _DraggablePrescriptionUIState();
// }

// class _DraggablePrescriptionUIState extends State<DraggablePrescriptionUI> {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Scaffold(
//         body: Container(
//           decoration: BoxDecoration(
//             image: DecorationImage(
//               image: AssetImage("assets/kahoy.jpg"), // Set background image
//               fit: BoxFit.cover,
//             ),
//           ),
//           child: SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 SizedBox(width: 50),
//                 PrescriptionPaper(title: "Login", width: 300, height: 400),
//                 SizedBox(width: 20),
//                 PrescriptionPaper(title: "Register", width: 300, height: 400),
//                 SizedBox(width: 50),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class PrescriptionPaper extends StatelessWidget {
//   final String title;
//   final double width;
//   final double height;

//   const PrescriptionPaper({
//     required this.title,
//     required this.width,
//     required this.height,
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Container(
//         width: width,
//         height: height,
//         padding: EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           // borderRadius: BorderRadius.circular(8),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black26,
//               blurRadius: 6,
//               spreadRadius: 2,
//               offset: Offset(2, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "RX",
//               style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 10),
//             Text(
//               "$title Form",
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             Divider(),
//             TextField(decoration: InputDecoration(labelText: "Patient Name")),
//             TextField(decoration: InputDecoration(labelText: "Address")),
//             SizedBox(height: 20),
//             ElevatedButton(onPressed: () {}, child: Text(title)),
//           ],
//         ),
//       ),
//     );
//   }
// }

// void main() => runApp(MaterialApp(home: DraggablePrescriptionUI()));

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class OCRTest extends StatefulWidget {
  @override
  _OCRTestState createState() => _OCRTestState();
}

class _OCRTestState extends State<OCRTest> {
  String extractedText = "Processing...";
  final String apiKey =
      "AIzaSyBK8IGXd9Cw3J5RopGOjJVr-W68CqTmn6I"; // Replace with your actual API key

  @override
  void initState() {
    super.initState();
    processOCR();
  }

  // Load Image from Assets and Perform OCR
  Future<void> processOCR() async {
    try {
      // Load image bytes from assets
      ByteData data = await rootBundle.load("assets/pres.png");
      Uint8List bytes = data.buffer.asUint8List();
      String base64Image = base64Encode(bytes);

      // Call Cloud Vision API
      final url =
          "https://vision.googleapis.com/v1/images:annotate?key=$apiKey";
      final requestBody = jsonEncode({
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [
              {"type": "TEXT_DETECTION"},
            ],
          },
        ],
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          extractedText =
              result["responses"][0]["fullTextAnnotation"]["text"] ??
              "No text found";
        });
      } else {
        setState(() {
          extractedText = "Error: ${response.reasonPhrase}";
        });
      }
    } catch (e) {
      setState(() {
        extractedText = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("OCR Test")),
      body: Column(
        children: [
          Image.asset("assets/pres.png", height: 250), // Display the test image
          SizedBox(height: 20),
          Text(
            extractedText,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
