import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'Homerider.dart';

class EditriderpagState extends StatefulWidget {
  final String uid;
  const EditriderpagState({super.key, required this.uid});

  @override
  State<EditriderpagState> createState() => EditriderpagStateState();
}

class EditriderpagStateState extends State<EditriderpagState> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullnameCtl = TextEditingController();
  final TextEditingController _phoneCtl = TextEditingController();
  final TextEditingController _vehicleNumberCtl = TextEditingController();

  String? profilePhotoUrl;
  String? vehiclePhotoUrl;

  File? _profileImage;
  File? _vehicleImage;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadRiderData();
  }

  Future<void> _loadRiderData() async {
    final doc = await FirebaseFirestore.instance
        .collection('riders')
        .doc(widget.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _fullnameCtl.text = data['fullname'] ?? '';
        _phoneCtl.text = data['phone'] ?? '';
        _vehicleNumberCtl.text = data['vehicle_number'] ?? '';
        profilePhotoUrl = data['profile_photo'];
        vehiclePhotoUrl = data['vehicle_photo'];
      });
    }
  }

  Future<void> _pickImage(bool isProfile) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          _profileImage = File(pickedFile.path);
        } else {
          _vehicleImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    // แสดง AlertDialog ยืนยันก่อนบันทึก
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการบันทึก'),
        content: const Text('คุณต้องการบันทึกการเปลี่ยนแปลงหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // ยกเลิก
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // ตกลง
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );

    if (confirm != true) return; // ถ้าไม่ตกลงก็ไม่ทำอะไร

    setState(() => _loading = true);

    // อัปโหลดรูปโปรไฟล์ถ้าเลือกใหม่
    if (_profileImage != null) {
      final uploadedProfileUrl = await uploadToCloudinary(_profileImage!);
      if (uploadedProfileUrl != null) {
        profilePhotoUrl = uploadedProfileUrl;
      }
    }

    // อัปโหลดรูปรถถ้าเลือกใหม่
    if (_vehicleImage != null) {
      final uploadedVehicleUrl = await uploadToCloudinary(_vehicleImage!);
      if (uploadedVehicleUrl != null) {
        vehiclePhotoUrl = uploadedVehicleUrl;
      }
    }

    final dataToUpdate = {
      'fullname': _fullnameCtl.text.trim(),
      'phone': _phoneCtl.text.trim(),
      'vehicle_number': _vehicleNumberCtl.text.trim(),
      'profile_photo': profilePhotoUrl,
      'vehicle_photo': vehiclePhotoUrl,
    };

    await FirebaseFirestore.instance
        .collection('riders')
        .doc(widget.uid)
        .update(dataToUpdate);

    setState(() => _loading = false);

    // แสดง Alert ยืนยันเสร็จแล้ว
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('สำเร็จ'),
        content: const Text('บันทึกการเปลี่ยนแปลงเรียบร้อย'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ปิด dialog
              Get.to(
                () => HomeriderPage(uid: widget.uid),
              ); // กลับหน้า Homerider
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูล Rider'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true); // ส่ง true กลับ
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // รูปโปรไฟล์
                    GestureDetector(
                      onTap: () => _pickImage(true),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : (profilePhotoUrl != null
                                      ? NetworkImage(profilePhotoUrl!)
                                      : null)
                                  as ImageProvider<Object>?,
                        child: _profileImage == null && profilePhotoUrl == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fullnameCtl,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อ-นามสกุล',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'กรุณากรอกชื่อ-นามสกุล' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneCtl,
                      decoration: const InputDecoration(
                        labelText: 'เบอร์โทร',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? 'กรุณากรอกเบอร์โทร' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _vehicleNumberCtl,
                      decoration: const InputDecoration(
                        labelText: 'เลขทะเบียนพาหนะ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // รูปรถ
                    // รูปรถ
                    Column(
                      children: [
                        const Text(
                          'เพิ่มรูปรถของคุณ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _pickImage(false),
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: _vehicleImage != null
                                ? Image.file(_vehicleImage!, fit: BoxFit.cover)
                                : (vehiclePhotoUrl != null
                                      ? Image.network(
                                          vehiclePhotoUrl!,
                                          fit: BoxFit.cover,
                                        )
                                      : const Center(
                                          child: Text(
                                            'แตะเพื่อเพิ่มรูปรถ',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        )),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text('บันทึกการเปลี่ยนแปลง'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ฟังก์ชันอัปโหลดรูปไป Cloudinary
  Future<String?> uploadToCloudinary(File imageFile) async {
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
        return jsonData['secure_url']; // ✅ URL ของรูป
      } else {
        print("Upload failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }
}
