import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class OrderlistPage extends StatefulWidget {
  final String uid;

  const OrderlistPage({super.key, required this.uid});

  @override
  State<OrderlistPage> createState() => _OrderlistPageState();
}

class _OrderlistPageState extends State<OrderlistPage> {
  String role = "user"; // ค่าเริ่มต้น: user
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  // Firestore
  var db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFFFF3B30)),
          Positioned(
            top: 150,
            left: 0,
            right: 0,
            bottom: 0,

            // พืื้นหลังสีขาว
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [],
                ),
              ),
            ),
          ),

          // ข้อความสีแดงด้านบน
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 70),
                  child: Text(
                    "รายการสินค้าของคุณ",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                      border: Border.all(color: Colors.white, width: 3),
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
