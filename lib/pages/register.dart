import 'dart:developer';
import 'dart:io';
import 'dart:convert';

import 'package:blink_delivery_project/pages/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

/// โครงสร้างที่อยู่หลายรายการ
class _AddrEntry {
  String label;
  String address;
  LatLng latlng;
  _AddrEntry({
    required this.label,
    required this.address,
    required this.latlng,
  });
}

class _RegisterPageState extends State<RegisterPage> {
  String role = "user";
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final emailCtl = TextEditingController();
  final passwordCtl = TextEditingController();
  final phoneCtl = TextEditingController();
  final fullnameCtl = TextEditingController();

  // เฉพาะ Rider
  final vehicleNumberCtl = TextEditingController();
  File? _vehicleImageFile;

  // ที่อยู่ (หลายรายการ)
  final mapController = MapController();
  LatLng? selectedLocation;
  final addressFieldCtl = TextEditingController();
  final addressLabelCtl = TextEditingController(text: "ที่อยู่หลัก");
  final List<_AddrEntry> addressesList = []; // <= เก็บหลายที่

  final db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    emailCtl.dispose();
    passwordCtl.dispose();
    phoneCtl.dispose();
    fullnameCtl.dispose();
    vehicleNumberCtl.dispose();
    addressFieldCtl.dispose();
    addressLabelCtl.dispose();
    super.dispose();
  }

  Future<ImageSource?> _chooseImageSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
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
      ),
    );
  }

  Future<void> _pickImageGeneric({required bool isVehicle}) async {
    final source = await _chooseImageSource();
    if (source == null) return;
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        if (isVehicle) {
          _vehicleImageFile = File(pickedFile.path);
        } else {
          _imageFile = File(pickedFile.path);
        }
      });
    }
  }

  // ============= UI =============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF3B30),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              "สมัครสมาชิก",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRoleButton("ผู้ใช้ระบบ", "user"),
                const SizedBox(width: 10),
                _buildRoleButton("ไรเดอร์", "rider"),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // รูปโปรไฟล์
                  GestureDetector(
                    onTap: () => _pickImageGeneric(isVehicle: false),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                        border: Border.all(color: Colors.red, width: 2),
                        image: _imageFile != null
                            ? DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _imageFile == null
                          ? const Center(
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 30,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _field(
                    "ชื่อ-นามสกุล",
                    "กรุณากรอกชื่อ-นามสกุล",
                    controller: fullnameCtl,
                  ),
                  _field("อีเมล", "กรุณากรอกอีเมล", controller: emailCtl),
                  const SizedBox(height: 15),
                  _field(
                    "รหัสผ่าน",
                    "กรุณากรอกรหัสผ่าน",
                    obscure: true,
                    controller: passwordCtl,
                  ),
                  const SizedBox(height: 15),
                  _field(
                    "หมายเลขโทรศัพท์",
                    "กรุณากรอกหมายเลขโทรศัพท์",
                    controller: phoneCtl,
                  ),
                  const SizedBox(height: 20),

                  if (role == "user")
                    _buildAddressSection(), // << ส่วนหลายที่อยู่

                  if (role == "rider") _buildRiderExtras(),

                  const SizedBox(height: 25),
                  SizedBox(
                    width: 200,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: adddata,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "สมัครสมาชิก",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("หากเป็นสมาชิกแล้ว?"),
                      InkWell(
                        onTap: () => Get.to(() => const LoginPage()),
                        child: const Text(
                          ' เข้าสู่ระบบ',
                          style: TextStyle(
                            color: Color(0xFFFF3B30),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== Widgets ======
  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("ที่อยู่ (เลือกจากแผนที่ แล้วกดเพิ่มได้หลายที่)"),
        const SizedBox(height: 8),
        TextField(
          controller: addressLabelCtl,
          decoration: InputDecoration(
            labelText: "ป้ายชื่อที่อยู่ (เช่น บ้าน/ที่ทำงาน)",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter:
                  selectedLocation ?? const LatLng(15.8700317, 100.99254),
              initialZoom: 15.2,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
              onTap: (tap, point) async {
                setState(() => selectedLocation = point);
                final placemarks = await placemarkFromCoordinates(
                  point.latitude,
                  point.longitude,
                );
                if (placemarks.isNotEmpty) {
                  final p = placemarks.first;
                  addressFieldCtl.text =
                      "${p.street}, ${p.subLocality}, ${p.locality}, ${p.administrativeArea}, ${p.postalCode}, ${p.country}";
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=d7b6821f750e49e2864ef759ef2223ec',
                userAgentPackageName: 'com.example.my_rider',
                maxNativeZoom: 18,
              ),
              if (selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: addressFieldCtl,
          decoration: InputDecoration(
            labelText: "ที่อยู่ที่เลือก",
            hintText: "แตะบนแผนที่เพื่อเลือกที่อยู่",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _addCurrentAddressToList,
            icon: const Icon(Icons.add_location_alt),
            label: const Text("เพิ่มที่อยู่นี้"),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ลิสต์ที่อยู่หลายรายการ
        if (addressesList.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label("ที่อยู่ที่เพิ่มแล้ว (${addressesList.length})"),
              const SizedBox(height: 6),
              ...addressesList.asMap().entries.map((e) {
                final i = e.key;
                final a = e.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.place, color: Colors.red),
                    title: Text(a.label),
                    subtitle: Text(
                      "${a.address}\n(${a.latlng.latitude.toStringAsFixed(6)}, "
                      "${a.latlng.longitude.toStringAsFixed(6)})",
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          setState(() => addressesList.removeAt(i)),
                    ),
                    onTap: () {
                      mapController.move(a.latlng, 16);
                      setState(() {
                        selectedLocation = a.latlng;
                        addressFieldCtl.text = a.address;
                        addressLabelCtl.text = a.label;
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRiderExtras() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("รูปถ่ายพาหนะ"),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () => _pickImageGeneric(isVehicle: true),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[200],
              image: _vehicleImageFile != null
                  ? DecorationImage(
                      image: FileImage(_vehicleImageFile!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _vehicleImageFile == null
                ? const Center(
                    child: Icon(Icons.add_a_photo, color: Colors.red, size: 40),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 15),
        _field("ทะเบียนรถ", "กรุณากรอกทะเบียนรถ", controller: vehicleNumberCtl),
        const SizedBox(height: 10),
      ],
    );
  }

  // ====== Helpers ======
  Widget _buildRoleButton(String text, String value) {
    final isSelected = role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => role = value),
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.red,
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.red : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Color(0xFFFF3B30),
    ),
  );

  Widget _field(
    String label,
    String hint, {
    bool obscure = false,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  void _addCurrentAddressToList() {
    if (selectedLocation == null || addressFieldCtl.text.trim().isEmpty) {
      Get.snackbar(
        'ที่อยู่ไม่ครบ',
        'แตะเลือกพิกัดบนแผนที่และตรวจสอบช่องที่อยู่',
      );
      return;
    }
    final label = addressLabelCtl.text.trim().isEmpty
        ? "ที่อยู่ ${addressesList.length + 1}"
        : addressLabelCtl.text.trim();
    final entry = _AddrEntry(
      label: label,
      address: addressFieldCtl.text.trim(),
      latlng: selectedLocation!,
    );
    setState(() {
      addressesList.add(entry);
      // เตรียมกรอกที่อยู่ถัดไป
      addressLabelCtl.text = "ที่อยู่ ${addressesList.length + 1}";
      addressFieldCtl.clear();
    });
  }

  // ====== Register ======
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<String?> uploadToCloudinary(File file) async {
    try {
      const cloudName = "dywfdy174";
      const uploadPreset = "flutter_upload";
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      final req = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final res = await req.send();
      if (res.statusCode == 200) {
        final data = jsonDecode(await res.stream.bytesToString());
        return data['secure_url'];
      }
      return null;
    } catch (e) {
      log("Upload error: $e");
      return null;
    }
  }

  Future<void> adddata() async {
    try {
      final collectionName = role == "rider" ? "riders" : "users";
      final email = emailCtl.text.trim();
      final phone = phoneCtl.text.trim();
      final fullName = fullnameCtl.text.trim();
      final pass = passwordCtl.text.trim();

      if (email.isEmpty || phone.isEmpty || fullName.isEmpty || pass.isEmpty) {
        Get.snackbar(
          'กรอกไม่ครบ',
          'กรุณากรอก ชื่อ, อีเมล, เบอร์โทร และรหัสผ่าน',
        );
        return;
      }

      // ผู้ใช้ต้องมีอย่างน้อย 1 ที่อยู่ + 1 พิกัด
      if (role == "user" && addressesList.isEmpty) {
        Get.snackbar(
          'ต้องมีที่อยู่อย่างน้อย 1 ที่',
          'กดปุ่ม "เพิ่มที่อยู่นี้" เพื่อบันทึกเข้า list',
        );
        return;
      }
      if (role == "rider" && vehicleNumberCtl.text.trim().isEmpty) {
        Get.snackbar('กรอกไม่ครบ', 'กรุณากรอกทะเบียนรถ');
        return;
      }

      // กันซ้ำเฉพาะคอลเลกชันตัวเอง
      final dupEmail = await db
          .collection(collectionName)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (dupEmail.docs.isNotEmpty) {
        Get.snackbar(
          'อีเมลถูกใช้แล้ว',
          'อีเมลนี้มีอยู่ใน $collectionName แล้ว',
        );
        return;
      }
      final dupPhone = await db
          .collection(collectionName)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (dupPhone.docs.isNotEmpty) {
        Get.snackbar(
          'เบอร์โทรถูกใช้แล้ว',
          'เบอร์นี้มีอยู่ใน $collectionName แล้ว',
        );
        return;
      }

      String? profileUrl;
      if (_imageFile != null) {
        profileUrl = await uploadToCloudinary(_imageFile!);
        if (profileUrl == null) {
          Get.snackbar('ผิดพลาด', 'อัปโหลดรูปโปรไฟล์ไม่สำเร็จ');
          return;
        }
      }

      final userData = <String, dynamic>{
        'role': role,
        'email': email,
        'password': hashPassword(pass),
        'phone': phone,
        'fullname': fullName,
        'profile_photo': profileUrl,
        'created_at': FieldValue.serverTimestamp(),
      };

      if (role == "rider") {
        String? vehicleUrl;
        if (_vehicleImageFile != null) {
          vehicleUrl = await uploadToCloudinary(_vehicleImageFile!);
          if (vehicleUrl == null) {
            Get.snackbar('ผิดพลาด', 'อัปโหลดรูปรถไม่สำเร็จ');
            return;
          }
        }
        userData.addAll({
          'vehicle_number': vehicleNumberCtl.text.trim(),
          'vehicle_photo': vehicleUrl,
          'latitude': null,
          'longitude': null,
          'last_update': null,
        });
      }

      final docRef = await db.collection(collectionName).add(userData);

      // บันทึกหลายที่อยู่ลง subcollection
      if (role == "user" && addressesList.isNotEmpty) {
        final batch = db.batch();
        final addrCol = db
            .collection('users')
            .doc(docRef.id)
            .collection('addresses');
        for (final a in addressesList) {
          batch.set(addrCol.doc(), {
            'label': a.label,
            'address': a.address,
            'latitude': a.latlng.latitude.toString(),
            'longitude': a.latlng.longitude.toString(),
            'created_at': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }

      Get.snackbar('สำเร็จ', 'สมัครสมาชิกเรียบร้อย');
      Get.to(() => const LoginPage());
    } catch (e) {
      log("เกิดข้อผิดพลาด: $e");
      Get.snackbar('ผิดพลาด', e.toString());
    }
  }

  // ====== Location ======
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar("ผิดพลาด", "กรุณาเปิด GPS");
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar("ผิดพลาด", "ไม่ได้รับสิทธิ์การเข้าถึงตำแหน่ง");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Get.snackbar("ผิดพลาด", "ไม่ได้รับสิทธิ์ถาวร");
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() => selectedLocation = LatLng(pos.latitude, pos.longitude));

    final placemarks = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      addressFieldCtl.text =
          "${p.street}, ${p.subLocality}, ${p.locality}, ${p.administrativeArea}, ${p.postalCode}, ${p.country}";
    }

    mapController.move(LatLng(pos.latitude, pos.longitude), 16);
  }
}
