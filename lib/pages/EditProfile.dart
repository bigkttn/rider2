import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:blink_delivery_project/pages/setting.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class Editprofile extends StatefulWidget {
  final String uid;

  const Editprofile({super.key, required this.uid});

  @override
  State<Editprofile> createState() => _EditprofileState();
}

class _EditprofileState extends State<Editprofile> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _nameController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  //map
  final latitude = TextEditingController();
  final longitude = TextEditingController();
  final addresses = TextEditingController();
  final mapController = MapController();
  LatLng? selectedLocation;

  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  String? _imageUrl;
  File? _newImageFile;

  String? aid;

  // Future<void> _pickImage() async {
  //   final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery,);
  //   if (pickedFile != null) {
  //     setState(() {
  //       _imageFile = File(pickedFile.path);
  //     });
  //   }
  // }

  // Future<void> _pickImage() async {
  //   final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
  //   if (pickedFile != null) {
  //     log("Picked from camera: ${pickedFile.path}");
  //     setState(() {
  //       _imageFile = File(pickedFile.path);
  //     });
  //   } else {
  //     log("No Image captured from camera");
  //   }
  // }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _newImageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> uploadImage(File imageUrl) async {
    try {
      const cloudName = "dywfdy174";
      const uploadPreset = "flutter_upload";
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      var request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageUrl.path));

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
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _nameController = TextEditingController();
    _passwordController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();

    _fetchUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  //ดึงมาโชว์
  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      QuerySnapshot addressSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('addresses')
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _nameController.text = data['fullname'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _passwordController.text = data['password'] ?? '';
          _imageUrl = data['profile_photo'];

          if (addressSnapshot.docs.isNotEmpty) {
            var addrData =
                addressSnapshot.docs.first.data() as Map<String, dynamic>;
            addresses.text = addrData['address'] ?? '';
            latitude.text = addrData['latitude'].toString();
            longitude.text = addrData['longitude'].toString();
            aid = addressSnapshot.docs.first.id;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Failed to fetch user data: $e");
    }
  }

  Future<void> _updateUserData() async {
    if (_formKey.currentState!.validate()) {
      try {
        String? imageUrl = _imageUrl;
        if (_newImageFile != null) {
          imageUrl = await uploadImage(_newImageFile!);
        }

        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid);

        await userRef.update({
          'email': _emailController.text,
          'fullname': _nameController.text,
          'password': _passwordController.text,
          'phone': _phoneController.text,
          'profile_photo': imageUrl,
        });

        if (aid != null) {
          await userRef.collection('addresses').doc(aid).update({
            'address': addresses.text,
            'latitude': double.tryParse(latitude.text) ?? 0,
            'longitude': double.tryParse(longitude.text) ?? 0,
          });
        } else {
          await userRef.collection('addresses').add({
            'address': addresses.text,
            'latitude': double.tryParse(latitude.text) ?? 0,
            'longitude': double.tryParse(longitude.text) ?? 0,
          });
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ!')));
        Get.back();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการแก้ไข'),
          content: const Text('คุณต้องการบันทึกการเปลี่ยนแปลงใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                //add data

                Get.back();
                _updateUserData();
              },
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffff3b30),
      appBar: AppBar(
        backgroundColor: Color(0xffff3b30),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      body: Stack(
        children: [
          Container(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, bottom: 10),
                  child: Text(
                    'แก้ไขข้อมูลส่วนตัว',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      color: Color(0xffffffff),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : buildForm(),
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

  Widget buildForm() {
    return Form(
      key: _formKey,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
              child: Container(
                child: Column(
                  children: [
                    _buildProfilePicture(),
                    const SizedBox(height: 24),
                    _buildTextField(label: 'ชื่อ', controller: _nameController),
                    _buildTextField(
                      label: 'อีเมล',
                      controller: _emailController,
                    ),
                    _buildTextField(
                      label: 'หมายเลขโทรศัพท์',
                      hint: 'กรอกหมายเลขโทรศัพท์ใหม่',
                      controller: _phoneController,
                    ),
                    _buildTextField(
                      label: 'รหัสผ่านใหม่',
                      hint: 'กรอกรหัสผ่านใหม่',
                      obscureText: true,
                    ),
                    // _buildTextField(
                    //   label: 'พิกัด GPS',
                    //   hint: 'คลิกที่แผนที่เพื่อเลือกพิกัดใหม่',
                    //   controller: addresses,
                    // ),
                    // const SizedBox(height: 8),
                    // SizedBox(
                    //   height: 300,
                    //   child: FlutterMap(
                    //     mapController: mapController,
                    //     options: MapOptions(
                    //       initialCenter:
                    //           selectedLocation ?? LatLng(16.243998, 103.249047),
                    //       initialZoom: 15.2,
                    //       onTap: (tapPosition, point) async {
                    //         setState(() {
                    //           selectedLocation = point;
                    //           latitude.text = point.latitude.toString();
                    //           longitude.text = point.longitude.toString();
                    //         });
                    //         List<Placemark> placemarks =
                    //             await placemarkFromCoordinates(
                    //               point.latitude,
                    //               point.longitude,
                    //             );

                    //         if (placemarks.isNotEmpty) {
                    //           final place = placemarks.first;
                    //           final address =
                    //               "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";

                    //           setState(() {
                    //             addresses.text = address;
                    //           });
                    //         }
                    //         log("เลือกพิกัด: $point");
                    //       },
                    //     ),
                    //     children: [
                    //       TileLayer(
                    //         urlTemplate:
                    //             'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=d7b6821f750e49e2864ef759ef2223ec',
                    //         userAgentPackageName: 'com.example.my_rider',
                    //         maxNativeZoom: 18,
                    //       ),
                    //       if (selectedLocation != null)
                    //         MarkerLayer(
                    //           markers: [
                    //             Marker(
                    //               point: selectedLocation!,
                    //               width: 40,
                    //               height: 40,
                    //               child: const Icon(
                    //                 Icons.location_on,
                    //                 size: 40,
                    //                 color: Colors.red,
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _showConfirmationDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xffff3b30),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'บันทึก',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('เลือกจากคลังภาพ'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('ถ่ายรูปใหม่'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    ImageProvider? imageProvider;

    if (_newImageFile != null) {
      imageProvider = FileImage(_newImageFile!);
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_imageUrl!);
    }
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey,
            border: Border.all(color: Color(0xffff3b30), width: 4),
            image: imageProvider != null
                ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                : null,
          ),
          child: imageProvider == null
              ? Center(
                  child: Icon(Icons.person, color: Color(0xffffffff), size: 80),
                )
              : null,
        ),
        GestureDetector(
          onTap: () => _showImageSourceActionSheet(context),
          child: Container(
            width: 30,
            height: 30,
            child: Center(
              child: Icon(Icons.add, color: Color(0xffffffff), size: 20),
            ),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xffff3b30),
              border: Border.all(color: Color(0xffff3b30), width: 4),
            ),
          ),
        ),
      ],
    );
  }

  // แก้ไข _buildTextField ให้รับ Controller แทน initialValue
  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
    String? hint,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xffff3b30),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller, // <-- ใช้ controller ที่นี่
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: Colors.black54, width: 2.0),
              ),
            ),
            validator: (value) {
              if (label != 'รหัสผ่านใหม่ (ถ้าต้องการเปลี่ยน)' &&
                  (value == null || value.isEmpty)) {
                return 'กรุณากรอก$label';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
