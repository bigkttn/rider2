import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:image_picker/image_picker.dart';
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

  final ImagePicker _picker = ImagePicker();

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
        _fullnameCtl.text = (data['fullname'] ?? '').toString();
        _phoneCtl.text = (data['phone'] ?? '').toString();
        _vehicleNumberCtl.text = (data['vehicle_number'] ?? '').toString();
        profilePhotoUrl = (data['profile_photo'] ?? '').toString();
        vehiclePhotoUrl = (data['vehicle_photo'] ?? '').toString();
      });
    }
  }

  // ---------- เลือกแหล่งรูป (กล้อง/แกลเลอรี) ----------
  Future<ImageSource?> _chooseImageSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('ถ่ายจากกล้อง'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('เลือกจากแกลเลอรี'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ---------- เลือกรูป (รองรับทั้งโปรไฟล์/พาหนะ + กล้อง/แกลเลอรี) ----------
  Future<void> _pickImage(bool isProfile) async {
    final source = await _chooseImageSource();
    if (source == null) return;

    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      if (isProfile) {
        _profileImage = File(picked.path);
      } else {
        _vehicleImage = File(picked.path);
      }
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    // ยืนยันก่อนบันทึก
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการบันทึก'),
        content: const Text('คุณต้องการบันทึกการเปลี่ยนแปลงหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);

    // อัปโหลดรูปโปรไฟล์ถ้าเลือกรูปใหม่
    if (_profileImage != null) {
      final uploaded = await uploadToCloudinary(_profileImage!);
      if (uploaded != null) profilePhotoUrl = uploaded;
    }

    // อัปโหลดรูปรถถ้าเลือกรูปใหม่
    if (_vehicleImage != null) {
      final uploaded = await uploadToCloudinary(_vehicleImage!);
      if (uploaded != null) vehiclePhotoUrl = uploaded;
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

    // แจ้งผลและกลับหน้า Homerider
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('สำเร็จ'),
        content: const Text('บันทึกการเปลี่ยนแปลงเรียบร้อย'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Get.to(() => HomeriderPage(uid: widget.uid));
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  ImageProvider? _profileProvider() {
    if (_profileImage != null) return FileImage(_profileImage!);
    if ((profilePhotoUrl ?? '').isNotEmpty)
      return NetworkImage(profilePhotoUrl!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูล Rider'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
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
                        backgroundImage: _profileProvider(),
                        child: _profileProvider() == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ชื่อ-นามสกุล
                    TextFormField(
                      controller: _fullnameCtl,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อ-นามสกุล',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'กรุณากรอกชื่อ-นามสกุล'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // เบอร์โทร
                    TextFormField(
                      controller: _phoneCtl,
                      decoration: const InputDecoration(
                        labelText: 'เบอร์โทร',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'กรุณากรอกเบอร์โทร'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // เลขทะเบียน
                    TextFormField(
                      controller: _vehicleNumberCtl,
                      decoration: const InputDecoration(
                        labelText: 'เลขทะเบียนพาหนะ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // รูปรถ
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            height: 140,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _vehicleImage != null
                                ? Image.file(_vehicleImage!, fit: BoxFit.cover)
                                : (vehiclePhotoUrl != null &&
                                      vehiclePhotoUrl!.isNotEmpty)
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
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        child: const Text('บันทึกการเปลี่ยนแปลง'),
                      ),
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

      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = jsonDecode(responseData);
        return jsonData['secure_url']; // URL ของรูป
      } else {
        debugPrint("Upload failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }
}
