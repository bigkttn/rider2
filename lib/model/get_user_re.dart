import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullname;
  final String email;
  final String phone;
  final String imageUrl;

  UserModel({
    required this.uid,
    required this.fullname,
    required this.email,
    required this.phone,
    required this.imageUrl,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      fullname: data['fullname'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      imageUrl: data['profile_photo'] ?? '', // ✅ แก้ไขให้ดึงจาก 'profile_photo'
    );
  }
}
