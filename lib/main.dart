import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler
import 'package:precription/account/loginPage.dart';
import 'package:precription/account/registro.dart';
import 'package:precription/frontend/home.dart';
import 'package:precription/test.dart';
import 'backend/firebase_options.dart'; // Import Firebase options
import 'frontend/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized before Firebase

  // Request storage permission (Android 11+)
  await _requestStoragePermission();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Initialize Firebase
  );

  runApp(const MainApp());
}

Future<void> _requestStoragePermission() async {
  // Check if storage permission is granted
  PermissionStatus status = await Permission.manageExternalStorage.status;

  if (!status.isGranted) {
    // Request the permission
    PermissionStatus newStatus =
        await Permission.manageExternalStorage.request();

    if (newStatus.isGranted) {
      print("Storage permission granted.");
    } else {
      print("Storage permission denied.");
      // Optionally, you can show a dialog or redirect to app settings
      openAppSettings();
    }
  } else {
    print("Storage permission already granted.");
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: Home());
  }
}
