import 'dart:io';
import 'package:blink_delivery_project/pages/EditProfile.dart';
import 'package:blink_delivery_project/pages/addresses_list_page.dart';
import 'package:blink_delivery_project/pages/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class SettingPage extends StatefulWidget {
  final String uid;
  final String aid;
  const SettingPage({super.key, required this.uid, required this.aid});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String? _userName;
  String? _userEmail;
  String? _profileImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc.get('fullname');
          _userEmail = userDoc.get('email');
          _profileImageUrl = userDoc.get('profile_photo');

          _isLoading = false;
        });
      } else {
        print("User document does not exist");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Failed to fetch user data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffff3b30),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : buildProfileContent(),
    );
  }

  Widget buildProfileContent() {
    return Stack(
      children: [
        Container(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 90.0, bottom: 0),
                child: Text(
                  'การตั้งค่า',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    height: double.infinity,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 30),
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : null,
                            child: _profileImageUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  )
                                : null,
                          ),
                          SizedBox(height: 12),
                          Text(
                            _userName ?? 'ไม่พบชื่อผู้ใช้',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _userEmail ?? 'ไม่พบอีเมล',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 30),

                          // --- ส่วนเมนู (ทำงานเหมือนเดิม) ---
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.08),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildMenuOption(
                                    icon: Icons.person_outline,
                                    title: 'แก้ไขข้อมูลส่วนตัว',
                                    onTap: () {
                                      Get.to(Editprofile(uid: widget.uid));
                                      print('Go to Edit Profile Page');
                                    },
                                  ),
                                  const Divider(
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16,
                                  ),
                                  _buildMenuOption(
                                    icon: Icons.location_on_outlined,
                                    title: 'เพิ่มที่อยู่',
                                    onTap: () {
                                      Get.to(
                                        AddressesListPage(uid: widget.uid),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.08),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: _buildMenuOption(
                                icon: Icons.logout,
                                title: 'ออกจากระบบ',
                                textColor: Colors.red,
                                onTap: () {
                                  _showLogoutDialog(context);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  //แจ้งเตือน
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        title: const Center(
          child: Text(
            'ออกจากระบบ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            onPressed: () => Get.back(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              print('Logged out!');

              Get.offAll(LoginPage());
            },
          ),
        ],
      ),
    );
  }

  //widget
  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = Colors.black,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
      trailing: textColor == Colors.red
          ? null
          : const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onTap(); // เรียกหลัง frame ปัจจุบัน เพื่อหลีกเลี่ยง context error
        });
      },
    );
  }
}
  

// 