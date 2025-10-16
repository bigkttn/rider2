import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:blink_delivery_project/pages/homepage.dart';
import 'package:blink_delivery_project/pages/sending_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class Detailorder extends StatefulWidget {
  const Detailorder({super.key});
  @override
  State<Detailorder> createState() => _DetailorderState();
}

class _DetailorderState extends State<Detailorder> {
  final TextEditingController _searchController =
      TextEditingController(); //for search

  final TextEditingController detailCtl = TextEditingController();
  File? pickedFile;

  final ImagePicker _picker = ImagePicker();
  String? _imageUrl; //ดึงรูปจาก firebase มาแสดง
  bool _isUploading = false;

  bool isCreate = false; //check create button

  int _currentIndex = 0; //rout page of menu ber

  String? _selectedValue;
  List<String> _options = [
    "123/45 ถ.สุขสบาย เขตบางรัก กรุงเทพฯ",
    "88/99 ถ.ประชาร่วมใจ เขตลาดกระบัง กรุงเทพฯ",
    "55/1 หมู่ 2 ต.บางขุนเทียน จ.สมุทรสาคร",
  ];

  void dispose() {
    detailCtl.dispose();
  }

  Future<void> pickFromGallery(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      log("Picked from gallery: ${image.path}");
      setState(() {
        pickedFile = File(image.path);
      });
    } else {
      log("No Image selected from gallery");
    }
  }

  Future<void> pickFromCamera(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      log("Picked from camera: ${image.path}");
      setState(() {
        pickedFile = File(image.path);
      });
    } else {
      log("No Image captured from camera");
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      const cloudName = "dywfdy174";
      const uploadPreset = "flutter_upload";
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      var request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = jsonDecode(responseData);
        return jsonData['secure_url']; // ได้ URL กลับมา
      } else {
        print("Upload failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print('Upload Error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Color(0xffff3b30),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20.0),
        actions: [
          GestureDetector(
            onTap: () {
              print("โปรไฟล์ผู้ใช้!");
            },
            child: CircleAvatar(
              backgroundImage: AssetImage(""),
              // เหลือปรับแต่งกรอบ
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(color: const Color(0xFFFF3B30)),
          Positioned(
            top: 120,
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
                  children: [
                    Padding(
                      padding: EdgeInsetsGeometry.only(top: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 30,
                              bottom: 30.0,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 400,
                                  width: 350,
                                  padding: EdgeInsets.all(
                                    15,
                                  ), // เผื่อระยะห่างด้านใน
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey,
                                      width: 1.0,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black,
                                        spreadRadius: 1,
                                        blurRadius: 1,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      // product image
                                      Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 50,
                                            ),
                                            child: Container(
                                              width: 200,
                                              height: 200,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  width: 3,
                                                  color: Colors.grey,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color.fromARGB(
                                                      200,
                                                      110,
                                                      107,
                                                      107,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              child: pickedFile == null
                                                  ? Icon(
                                                      Icons.image,
                                                      size: 30,
                                                      color: Color(0xFF121212),
                                                    )
                                                  : Image.file(
                                                      pickedFile!,
                                                      fit: BoxFit.cover,
                                                    ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.fromLTRB(
                                              20,
                                              0,
                                              0,
                                              160,
                                            ),
                                            child: Column(
                                              children: [
                                                IconButton(
                                                  iconSize: 20,
                                                  icon: const Icon(
                                                    Icons.info_outlined,
                                                  ),
                                                  onPressed: () {},
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(width: 15, height: 10),

                                      //รายละเอียด
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildInfoRow(
                                              "รายละเอียด:",
                                              "สินค้า A, จำนวน 2 ชิ้น",
                                            ),
                                            _buildInfoRow(
                                              "ผู้ส่ง:",
                                              "ขจรศักดิ์ มานะ",
                                            ),
                                            _buildInfoRow(
                                              "ที่อยู่ผู้ส่ง:",
                                              "123/45 ถ.สุขสบาย แขวงบางรัก เขตบางรัก กรุงเทพฯ 10500",
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.only(left: 30.0, top: 20),
                            child: Text(
                              'ผู้รับ',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.only(
                              left: 50.0,
                              bottom: 30.0,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 170,
                                  width: 300,
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey,
                                      width: 1.0,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        spreadRadius: 1,
                                        blurRadius: 4,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 🔹 วงกลมโปรไฟล์
                                      const CircleAvatar(
                                        radius: 25,
                                        backgroundImage: AssetImage(
                                          "assets/profile.png",
                                        ), // ใส่รูปจริงได้
                                      ),
                                      const SizedBox(width: 15),

                                      // 🔹 ข้อความ + dropdown
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "อารี ดำรง",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "123/45 ถ.สุขสบาย",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            const SizedBox(height: 10),

                                            // 🔹 Dropdown แบบพอดีกับกล่อง
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  isExpanded:
                                                      true, // ✅ ทำให้กว้างเต็มที่
                                                  value: _selectedValue,
                                                  hint: const Text(
                                                    'กรุณาเลือกที่อยู่ผู้รับ',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  items: _options.map((
                                                    String value,
                                                  ) {
                                                    return DropdownMenuItem<
                                                      String
                                                    >(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                                  onChanged:
                                                      (String? newValue) {
                                                        setState(() {
                                                          _selectedValue =
                                                              newValue;
                                                        });
                                                      },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsGeometry.fromLTRB(
                              10,
                              10,
                              10,
                              50,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FilledButton(
                                  onPressed: () async {
                                    var db = FirebaseFirestore.instance;

                                    var ordersData = {
                                      'detail': detailCtl.text,
                                      'imageUrl': _imageUrl ?? '',
                                      'createAt': DateTime.now(),
                                    };

                                    await db
                                        .collection('orders')
                                        .add(ordersData);

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SendingStatus(),
                                      ),
                                    );
                                  },
                                  style: ButtonStyle(
                                    foregroundColor:
                                        MaterialStateProperty.resolveWith<
                                          Color
                                        >((states) => Colors.white),
                                    backgroundColor:
                                        MaterialStateProperty.resolveWith<
                                          Color
                                        >(
                                          (states) =>
                                              states.contains(
                                                MaterialState.pressed,
                                              )
                                              ? Colors.white
                                              : const Color(0xffff3b30),
                                        ),
                                    side: MaterialStateProperty.all(
                                      const BorderSide(
                                        color: Color(0xffff3b30),
                                        width: 1.5,
                                      ),
                                    ),
                                    shape: MaterialStateProperty.all(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    "เรียกไรเดอร์",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // แถบแดงด้านบน
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
                  child: Text(
                    "สร้างรายการส่งสินค้า",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ค้นหาผู้รับ',

                      prefixIcon: IconButton(
                        icon: Icon(Icons.search, color: Color(0xffff3b30)),
                        onPressed: () {
                          // ใส่ logic ค้นหา
                        },
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 5.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xffff3b30),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'ประวัติการสั่ง',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'รายการสินค้า',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'ตั้งค่า'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
