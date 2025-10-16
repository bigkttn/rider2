import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker picker = ImagePicker();
  XFile? _image; // เก็บไฟล์ที่เลือก

  Future<void> pickFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      log("Picked from gallery: ${pickedFile.path}");
      setState(() {
        _image = pickedFile;
      });
    } else {
      log("No Image selected from gallery");
    }
  }

  Future<void> pickFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      log("Picked from camera: ${pickedFile.path}");
      setState(() {
        _image = pickedFile;
      });
    } else {
      log("No Image captured from camera");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Image.file(File(_image!.path), height: 200) // แสดงรูปที่เลือก
                : const Text("No image selected"),

            const SizedBox(height: 20),

            FilledButton(
              onPressed: pickFromGallery,
              child: const Text('Gallery'),
            ),
            FilledButton(
              onPressed: pickFromCamera,
              child: const Text('Camera'),
            ),
          ],
        ),
      ),
    );
  }
}
