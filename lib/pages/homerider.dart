import 'dart:developer';
import 'package:blink_delivery_project/model/get_rider_re.dart';
import 'package:blink_delivery_project/pages/EditRider.dart';
import 'package:blink_delivery_project/pages/RiderTo.dart';
import 'package:blink_delivery_project/pages/riderhistory.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

class HomeriderPage extends StatefulWidget {
  final String uid;
  const HomeriderPage({super.key, required this.uid});

  @override
  State<HomeriderPage> createState() => _HomeriderPageState();
}

class _HomeriderPageState extends State<HomeriderPage> {
  int _currentIndex = 0;
  Rider? _rider;

  @override
  void initState() {
    super.initState();
    _fetchRider();
  }

  Future<void> _fetchRider() async {
    final rider = await _getRider(widget.uid);
    setState(() {
      _rider = rider;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_rider == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    List<Widget> pages = [
      _buildHomePage(_rider!), // ✅ หน้าแรก
      Ridertopage(uid: widget.uid), // ✅ หน้าที่ต้องไปส่ง
      Riderhistory(uid: widget.uid), // 🕓 ประวัติการส่ง
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        height: 76,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, -2),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            BottomNavItem(
              icon: Icons.home,
              label: "รับงาน",

              onTap: () => setState(() => _currentIndex = 0),
            ),
            BottomNavItem(
              icon: Icons.delivery_dining,
              label: "ที่ต้องไปส่ง",
              onTap: () => setState(() => _currentIndex = 1),
            ),
            BottomNavItem(
              icon: Icons.history,
              label: "ประวัติส่ง",
              onTap: () => setState(() => _currentIndex = 2),
            ),
            BottomNavItem(
              icon: Icons.logout,
              label: "ออกจากระบบ",
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('ยืนยันการออกจากระบบ'),
                    content: const Text('คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('ยกเลิก'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                        child: const Text('ตกลง'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ หน้าแรก แสดงโปรไฟล์ + รายการ Order
  Widget _buildHomePage(Rider rider) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 🔴 ส่วนหัวโปรไฟล์
          Container(
            height: 200,
            width: double.infinity,
            color: const Color(0xFFFF3B30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(rider.profilePhoto),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "สวัสดี ${rider.fullname}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditriderpagState(uid: widget.uid),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              "แก้ไขข้อมูลส่วนตัว",
                              style: TextStyle(
                                color: Color(0xFFFF3B30),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 📦 ส่วนแสดงรายการออเดอร์
          Expanded(child: _buildOrderList()),
        ],
      ),
    );
  }

  /// ✅ แสดงรายการออเดอร์ที่รอไรเดอร์รับ
  Widget _buildOrderList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;

        if (orders.isEmpty) {
          return const Center(child: Text("ยังไม่มีออเดอร์ในระบบ"));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final data = orders[index].data() as Map<String, dynamic>;
            final orderId = orders[index].id;

            final hasRider = (data['rider_id'] ?? '').toString().isNotEmpty;
            final status = data['status'] ?? '';

            // แสดงเฉพาะออเดอร์ที่ยังไม่มีไรเดอร์ หรือรอรับสินค้า
            if (hasRider && status != 'รอไรเดอร์รับสินค้า') {
              return const SizedBox.shrink();
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: data['items'] != null && data['items'].isNotEmpty
                    ? Image.network(
                        data['items'][0]['imageUrl'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.inventory),

                // ✅ โหลดชื่อผู้รับแบบ real-time
                title: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(data['receiver_id'])
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text("กำลังโหลดชื่อผู้รับ...");
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Text("ไม่พบชื่อผู้รับ");
                    }
                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>?;
                    final receiverName =
                        userData?['fullname'] ?? 'ไม่พบชื่อผู้รับ';
                    return Text(
                      receiverName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    );
                  },
                ),

                subtitle: Text(
                  data['receiver_address'] ?? 'ไม่มีที่อยู่',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasRider
                        ? Colors.grey
                        : const Color(0xFFFF3B30),
                  ),
                  onPressed: hasRider
                      ? null
                      : () async {
                          try {
                            // ✅ ตรวจสอบงานค้างก่อน
                            final allOrders = await FirebaseFirestore.instance
                                .collection('orders')
                                .where('rider_id', isEqualTo: widget.uid)
                                .get();

                            final activeOrders = allOrders.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return data['status'] != 'ไรเดอร์นำส่งสินค้าแล้ว';
                            }).toList();

                            if (activeOrders.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'คุณมีงานที่ยังไม่จบ กรุณาส่งให้เสร็จก่อน',
                                  ),
                                ),
                              );
                              return;
                            }

                            // ✅ ดึงตำแหน่งปัจจุบันของ Rider
                            bool serviceEnabled =
                                await Geolocator.isLocationServiceEnabled();
                            if (!serviceEnabled) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('กรุณาเปิด GPS ก่อนรับงาน'),
                                ),
                              );
                              return;
                            }

                            LocationPermission permission =
                                await Geolocator.checkPermission();
                            if (permission == LocationPermission.denied) {
                              permission = await Geolocator.requestPermission();
                              if (permission == LocationPermission.denied) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'ไม่ได้รับสิทธิ์เข้าถึงตำแหน่ง',
                                    ),
                                  ),
                                );
                                return;
                              }
                            }

                            // ✅ ดึงตำแหน่ง
                            Position position =
                                await Geolocator.getCurrentPosition(
                                  desiredAccuracy: LocationAccuracy.high,
                                );

                            // ✅ อัปเดต Order พร้อมตำแหน่ง Rider
                            await FirebaseFirestore.instance
                                .collection('orders')
                                .doc(orderId)
                                .update({
                                  'rider_id': widget.uid,
                                  'status':
                                      'ไรเดอร์รับงานแล้ว (กำลังเดินทางไปรับสินค้า)',
                                  'rider_latitude': position.latitude,
                                  'rider_longitude': position.longitude,
                                  'rider_accept_time':
                                      FieldValue.serverTimestamp(),
                                });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('รับงานสำเร็จ ✅')),
                            );

                            // ✅ ไปหน้า “ที่ต้องไปส่ง”
                            setState(() {
                              _currentIndex = 1;
                            });
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                            );
                          }
                        },
                  child: const Text("รับงาน"),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// ✅ ดึงข้อมูล Rider จาก Firestore
  Future<Rider?> _getRider(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('riders')
        .doc(uid)
        .get();
    if (!doc.exists) {
      log('❌ No rider found for uid $uid');
      return null;
    }
    log('✅ Rider data: ${doc.data()}');
    return Rider.fromMap(doc.id, doc.data()!);
  }
}

/// ✅ ปุ่มล่าง Navbar
class BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const BottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.black),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
