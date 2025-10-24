import 'dart:developer';
import 'dart:math' hide log;

import 'package:blink_delivery_project/model/get_rider_re.dart';
import 'package:blink_delivery_project/pages/EditRider.dart';
import 'package:blink_delivery_project/pages/RiderTo.dart';
import 'package:blink_delivery_project/pages/riderhistory.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HomeriderPage extends StatefulWidget {
  final String uid;
  const HomeriderPage({super.key, required this.uid});

  @override
  State<HomeriderPage> createState() => _HomeriderPageState();
}

class _HomeriderPageState extends State<HomeriderPage> {
  static const _thunderKey = 'd7b6821f750e49e2864ef759ef2223ec';

  int _currentIndex = 0;
  Rider? _rider;

  @override
  void initState() {
    super.initState();
    _fetchRider();
  }

  Future<void> _fetchRider() async {
    final rider = await _getRider(widget.uid);
    if (!mounted) return;
    setState(() => _rider = rider);
  }

  @override
  Widget build(BuildContext context) {
    if (_rider == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = <Widget>[
      _buildHomePage(_rider!), // หน้าแรก: รายการงานที่รับได้
      Ridertopage(uid: widget.uid), // หน้าที่ต้องไปส่ง (งานที่รับแล้ว)
      Riderhistory(uid: widget.uid), // ประวัติ
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
                        onPressed: () => Navigator.pop(context),
                        child: const Text('ยกเลิก'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst),
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

  // ---------------- UI: หน้าแรก ----------------
  Widget _buildHomePage(Rider rider) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // header
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
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditriderpagState(uid: widget.uid),
                            ),
                          ),
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

          // orders list
          Expanded(child: _buildOrderList()),
        ],
      ),
    );
  }

  // ---------------- คิวรี: ไม่มี where (คัดกรองในแอป) ----------------
  Widget _buildOrderList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy(
            'createAt',
            descending: true,
          ) // ไม่มี where → ไม่ต้องสร้าง composite index
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // คัดเฉพาะงานว่าง (ยังไม่มี rider หรือสถานะ "รอไรเดอร์รับสินค้า")
        final docs = snapshot.data!.docs.where((d) {
          final m = d.data() as Map<String, dynamic>;
          final hasRider = (m['rider_id'] ?? '').toString().isNotEmpty;
          final status = (m['status'] ?? '').toString();
          return !hasRider || status == 'รอไรเดอร์รับสินค้า';
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text("ยังไม่มีออเดอร์ที่รับได้"));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final orderId = doc.id;

            final img = (data['items'] is List && data['items'].isNotEmpty)
                ? (data['items'][0]['imageUrl'] ?? '')
                : '';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: img.toString().isNotEmpty
                    ? Image.network(
                        img,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.inventory),
                title: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(data['receiver_id'])
                      .get(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Text("กำลังโหลดชื่อผู้รับ...");
                    }
                    if (!snap.hasData || !snap.data!.exists) {
                      return const Text("ไม่พบชื่อผู้รับ");
                    }
                    final u = snap.data!.data() as Map<String, dynamic>?;
                    final name = (u?['fullname'] ?? 'ไม่พบชื่อผู้รับ')
                        .toString();
                    return Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    );
                  },
                ),
                subtitle: Text(
                  (data['receiver_address'] ?? '').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // กดดูแผนที่ก่อน แล้วค่อยกดยืนยันในหน้าพรีวิว
                trailing: OutlinedButton.icon(
                  onPressed: () => _showPreviewMap(context, orderId, data),
                  icon: const Icon(Icons.map),
                  label: const Text('ดูแผนที่'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- Helper: ดึง Rider ----------------
  Future<Rider?> _getRider(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('riders')
        .doc(uid)
        .get();
    if (!doc.exists) {
      log('❌ No rider found for uid $uid');
      return null;
    }
    return Rider.fromMap(doc.id, doc.data()!);
  }

  // ---------------- Preview Map (ก่อนรับงาน) ----------------
  double? _toD(dynamic v) => v == null ? null : double.tryParse(v.toString());

  double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    double dLat = (lat2 - lat1) * (pi / 180.0);
    double dLon = (lon2 - lon1) * (pi / 180.0);
    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  Future<void> _showPreviewMap(
    BuildContext context,
    String orderId,
    Map<String, dynamic> order,
  ) async {
    final sLat = _toD(order['sender_latitude']);
    final sLng = _toD(order['sender_longitude']);
    final rLat = _toD(order['receiver_latitude']);
    final rLng = _toD(order['receiver_longitude']);

    if (sLat == null || sLng == null || rLat == null || rLng == null) {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'แผนที่พรีวิว',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text('ไม่พบพิกัดรับ/ส่งในคำสั่งซื้อ'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ปิด'),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    Position? myPos;
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm != LocationPermission.denied &&
            perm != LocationPermission.deniedForever) {
          myPos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
          );
        }
      }
    } catch (_) {}

    final approxMeters = _haversineMeters(sLat, sLng, rLat, rLng);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final mapController = MapController();
        final points = <LatLng>[
          LatLng(sLat, sLng),
          LatLng(rLat, rLng),
          if (myPos != null) LatLng(myPos!.latitude, myPos!.longitude),
        ];

        final map = SizedBox(
          height: 300,
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(sLat, sLng),
              initialZoom: 14,
              onMapReady: () {
                if (points.length >= 2) {
                  final fit = CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(points),
                    padding: const EdgeInsets.all(40),
                    maxZoom: 17,
                  );
                  mapController.fitCamera(fit);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=$_thunderKey',
                userAgentPackageName: 'com.example.rider_app',
                maxNativeZoom: 18,
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [LatLng(sLat, sLng), LatLng(rLat, rLng)],
                    strokeWidth: 4,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(sLat, sLng),
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.store,
                      color: Colors.green,
                      size: 36,
                    ),
                  ),
                  Marker(
                    point: LatLng(rLat, rLng),
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 36,
                    ),
                  ),
                  if (myPos != null)
                    Marker(
                      point: LatLng(myPos!.latitude, myPos!.longitude),
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.pedal_bike,
                        color: Colors.red,
                        size: 36,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'แผนที่พรีวิว',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                map,
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.store, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text((order['sender_address'] ?? '').toString()),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text((order['receiver_address'] ?? '').toString()),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'ระยะทางโดยประมาณ: ${(approxMeters / 1000).toStringAsFixed(2)} กม.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('ปิด'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _acceptJob(orderId);
                        },
                        child: const Text('ยืนยันรับงาน'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- รับงาน (อัปเดต Firestore + แชร์พิกัดเริ่มต้น) ----------------
  Future<void> _acceptJob(String orderId) async {
    try {
      // ห้ามมีงานค้าง
      final myOrders = await FirebaseFirestore.instance
          .collection('orders')
          .where('rider_id', isEqualTo: widget.uid)
          .get();
      final active = myOrders.docs.where((d) {
        final m = d.data() as Map<String, dynamic>;
        return (m['status'] ?? '') != 'ไรเดอร์นำส่งสินค้าแล้ว';
      }).toList();
      if (active.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('คุณมีงานที่ยังไม่จบ กรุณาส่งให้เสร็จก่อน'),
          ),
        );
        return;
      }

      // ขอตำแหน่ง
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเปิด GPS ก่อนรับงาน')),
        );
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่ได้รับสิทธิ์เข้าถึงตำแหน่ง')),
        );
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // อัปเดตออเดอร์
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
            'rider_id': widget.uid,
            'status': 'ไรเดอร์รับงานแล้ว (กำลังเดินทางไปรับสินค้า)',
            'rider_latitude': pos.latitude,
            'rider_longitude': pos.longitude,
            'rider_accept_time': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('รับงานสำเร็จ ✅')));
      setState(() => _currentIndex = 1); // ไปหน้า "ที่ต้องไปส่ง"
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }
}

// ---------------- Bottom item ----------------
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
