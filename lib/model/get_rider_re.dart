import 'package:cloud_firestore/cloud_firestore.dart';

class Rider {
  final String uid;
  final String fullname;
  final String email;
  final String phone;
  final String role;
  final String password;
  final String profilePhoto;
  final String vehicleNumber;
  final String vehiclePhoto;
  final DateTime createdAt;

  Rider({
    required this.uid,
    required this.fullname,
    required this.email,
    required this.phone,
    required this.role,
    required this.password,
    required this.profilePhoto,
    required this.vehicleNumber,
    required this.vehiclePhoto,
    required this.createdAt,
  });

  // สร้างจาก Firestore document
  factory Rider.fromMap(String uid, Map<String, dynamic> data) {
    return Rider(
      uid: uid,
      fullname: data['fullname'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? '',
      password: data['password'] ?? '',
      profilePhoto: data['profile_photo'] ?? '',
      vehicleNumber: data['vehicle_number'] ?? '',
      vehiclePhoto: data['vehicle_photo'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }
}
