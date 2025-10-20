import 'dart:developer';

import 'package:blink_delivery_project/pages/homepage.dart';
import 'package:blink_delivery_project/pages/homerider.dart';
import 'package:blink_delivery_project/pages/register.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isUser = true; // true = ผู้ใช้ระบบ, false = ไรเดอร์
  final emailCtl = TextEditingController();
  final passwordCtl = TextEditingController();
  final db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF3B30),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 412,
            height: 917,
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                // พื้นหลังขาว
                Positioned(
                  top: 177,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 740,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Title เข้าสู่ระบบ
                Positioned(
                  top: 43,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      "เข้าสู่ระบบ",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Toggle ผู้ใช้ระบบ / ไรเดอร์
                Positioned(
                  top: 104,
                  left: 38,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => isUser = true),
                        child: Container(
                          width: 154,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.white
                                : Colors
                                      .transparent, // background สีขาวเมื่อเลือก
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              "ผู้ใช้ระบบ",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isUser
                                    ? const Color(
                                        0xFFFF3B30,
                                      ) // ข้อความสีแดงเมื่อเลือก
                                    : Colors.white, // ข้อความสีขาวเมื่อไม่เลือก
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 29),
                      GestureDetector(
                        onTap: () => setState(() => isUser = false),
                        child: Container(
                          width: 154,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.transparent
                                : Colors.white, // ขาวเมื่อเลือกไรเดอร์
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              "ไรเดอร์",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isUser
                                    ? Colors.white
                                    : const Color(
                                        0xFFFF3B30,
                                      ), // ข้อความสีแดงเมื่อเลือก
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ฟอร์มกรอก
                Positioned(
                  top: 210,
                  left: 36,
                  right: 36,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "อีเมล",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF3B30),
                        ),
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        controller: emailCtl,
                        decoration: InputDecoration(
                          hintText: "กรุณากรอกอีเมล",
                          hintStyle: const TextStyle(
                            color: Color(0xFFD9D9D9),
                            fontWeight: FontWeight.bold,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.black),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.black),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      const Text(
                        "รหัสผ่าน",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF3B30),
                        ),
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        controller: passwordCtl,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "กรุณากรอกรหัสผ่าน",
                          hintStyle: const TextStyle(
                            color: Color(0xFFD9D9D9),
                            fontWeight: FontWeight.bold,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.black),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.black),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ปุ่มเข้าสู่ระบบ
                      Center(
                        child: ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF3B30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 10,
                            ),
                          ),
                          child: const Text(
                            "เข้าสู่ระบบ",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),

                      // หากยังไม่ได้เป็นสมาชิก?
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "หากยังไม่ได้เป็นสมาชิก? ",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFFF3B30),
                            ),
                          ),
                          GestureDetector(
                            onTap: toRe,
                            child: const Text(
                              "สมัครสมาชิก",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF3B30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void toRe() {
    Get.to(() => const RegisterPage());
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void login() async {
    String collectionName = isUser ? 'users' : 'riders';
    String email = emailCtl.text.trim();
    String password = passwordCtl.text.trim();

    try {
      String hashedPassword = hashPassword(password);

      var query = await db
          .collection(collectionName)
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: hashedPassword)
          .get();

      if (query.docs.isNotEmpty) {
        String uid = query.docs.first.id;
        log('✅ Login successful: $uid');

        if (!mounted) return; // ✅ ป้องกัน context เสีย

        // ✅ ใช้ Navigator โดยตรง (ปลอดภัยกว่าใน async)
        if (isUser) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Homepage(uid: uid, aid: '', rid: ''),
            ),
          );
          log('➡️ Login as USER');
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => HomeriderPage(uid: uid)),
          );
          log('➡️ Login as RIDER');
        }
      } else {
        Get.snackbar('ผิดพลาด', 'อีเมลหรือรหัสผ่านไม่ถูกต้อง');
      }
    } catch (e) {
      log('Login error: $e');
      Get.snackbar('ผิดพลาด', 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ');
    }
  }
}
