import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Riderprofile extends StatefulWidget {
  final String rid;
  const Riderprofile({super.key, required this.rid});

  @override
  State<Riderprofile> createState() => _RiderprofileState();
}

class _RiderprofileState extends State<Riderprofile> {
  String? riderName;
  String? riderEmail;
  String? riderImageUrl;
  String? vehicle_number;
  String? vehicle_photo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot riderDoc = await FirebaseFirestore.instance
          .collection('riders')
          .doc(widget.rid)
          .get();

      if (riderDoc.exists) {
        setState(() {
          riderName = riderDoc.get('fullname');
          riderEmail = riderDoc.get('email');
          riderImageUrl = riderDoc.get('profile_photo');
          vehicle_number = riderDoc.get('vehicle_number');
          vehicle_photo = riderDoc.get('vehicle_photo');

          _isLoading = false;
          print(riderDoc);
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
      appBar: AppBar(
        backgroundColor: Color(0xffff3b30),
        iconTheme: IconThemeData(color: Color(0xffffffff)),
      ),
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
                  'ข้อมูลไรเดอร์',
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
                            backgroundImage: riderImageUrl != null
                                ? NetworkImage(riderImageUrl!)
                                : null,
                            child: riderImageUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  )
                                : null,
                          ),
                          SizedBox(height: 12),
                          Text(
                            riderName ?? 'ไม่พบชื่อผู้ใช้',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'อีเมล: ',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 30),
                              Text(
                                riderEmail ?? 'ไม่พบอีเมล',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'ทะเบียนรถ:',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4, width: 10),
                              Text(
                                vehicle_number ?? 'ไม่พบทะเบียนรถ',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 30),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 300,
                              height: 150,
                              color:
                                  Colors.grey.shade200, // สีพื้นหลังถ้าไม่มีรูป
                              child:
                                  vehicle_photo != null &&
                                      vehicle_photo!.isNotEmpty
                                  ? Image.network(
                                      vehicle_photo!,
                                      fit: BoxFit.cover,
                                    )
                                  : Icon(
                                      Icons.image_not_supported_sharp,
                                      size: 60,
                                      color: Colors.grey.shade400,
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
}
  

// 