import 'dart:async';
import 'dart:developer';

import 'package:blink_delivery_project/pages/orderlist.dart';
import 'package:blink_delivery_project/pages/riderProfile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class ReceivingStatus extends StatefulWidget {
  final String uid, rid, oid;
  const ReceivingStatus({
    super.key,
    required this.uid,
    required this.rid,
    required this.oid,
  });

  @override
  State<ReceivingStatus> createState() => _ReceivingStatusState();
}

class _ReceivingStatusState extends State<ReceivingStatus> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffff3b30),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(150.0),
        child: AppBar(
          backgroundColor: const Color(0xffff3b30),
          elevation: 0,
          flexibleSpace: Padding(
            padding: const EdgeInsets.only(top: 50.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'สถานะการจัดส่ง',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                StatusTracker(
                  oid: widget.oid,
                  uid: widget.uid,
                  rid: widget.rid,
                ),
              ],
            ),
          ),
        ),
      ),

      // ✅ ป้องกัน bottom overflow และทำพื้นหลังสีขาวมุมโค้งบน 20
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomInset + 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20), // ✅ โค้งมุมบน 20
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RiderContact(
                      uid: widget.uid,
                      rid: widget.rid,
                      oid: widget.oid,
                    ),
                    const SizedBox(height: 16),
                    // ✅ subscribe เฉพาะออเดอร์นี้ใบเดียว
                    MapReceive(
                      uid: widget.uid,
                      rid: widget.rid,
                      oid: widget.oid,
                    ),
                    const SizedBox(height: 16),
                    ProductDetail(oid: widget.oid, uid: widget.uid),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ---------------- Rider (ซ่อนไว้ถ้ายังไม่มี rider) ----------------
class RiderContact extends StatefulWidget {
  final String uid;
  final String rid;
  final String oid;
  const RiderContact({
    super.key,
    required this.uid,
    required this.rid,
    required this.oid,
  });

  @override
  State<RiderContact> createState() => _RiderContactState();
}

class _RiderContactState extends State<RiderContact> {
  String? riderName;
  String? riderProfile;
  String? riderPhone;
  String? riderVehicleNumber;
  bool _isLoading = true;
  bool _hasRider = false;

  @override
  void initState() {
    super.initState();
    _fetchRider();
  }

  Future<void> _fetchRider() async {
    try {
      if (widget.rid.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasRider = false;
        });
        return;
      }

      final riderDoc = await FirebaseFirestore.instance
          .collection('riders')
          .doc(widget.rid)
          .get();

      if (riderDoc.exists) {
        setState(() {
          riderName = riderDoc.get('fullname');
          riderProfile = riderDoc.get('profile_photo');
          riderPhone = riderDoc.get('phone');
          riderVehicleNumber = riderDoc.get('vehicle_number');
          _hasRider = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasRider = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Error fetching rider: $e');
      setState(() {
        _hasRider = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (!_hasRider) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 5.0, left: 20),
          child: Text(
            'ไรเดอร์',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: (riderProfile ?? '').isNotEmpty
                        ? NetworkImage(riderProfile!)
                        : null,
                    child: (riderProfile ?? '').isEmpty
                        ? Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey.shade400,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        riderName ?? 'ไม่ระบุชื่อ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          const Text(
                            'ทะเบียนรถ: ',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            riderVehicleNumber ?? 'ไม่ระบุ',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            'เบอร์โทรศัพท์: ',
                            style: TextStyle(fontSize: 12),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              riderPhone ?? 'ไม่ระบุเบอร์โทรศัพท์',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  height: 30,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () =>
                        Get.to(() => Riderprofile(rid: widget.rid)),
                    child: const Text(
                      'ข้อมูลไรเดอร์',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// ---------------- แผนที่ (แสดงเฉพาะออเดอร์เดียวตาม oid) ----------------
class MapReceive extends StatefulWidget {
  final String uid, rid, oid;
  const MapReceive({
    super.key,
    required this.uid,
    required this.rid,
    required this.oid,
  });

  @override
  State<MapReceive> createState() => _MapReceiveState();
}

class _MapReceiveState extends State<MapReceive> {
  LatLng? riderPos;
  LatLng? receiverPos;
  double? distanceToRider;
  Timer? _timer;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _startDistanceUpdater();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startDistanceUpdater() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (riderPos != null && receiverPos != null) {
        setState(() {
          distanceToRider = Geolocator.distanceBetween(
            riderPos!.latitude,
            riderPos!.longitude,
            receiverPos!.latitude,
            receiverPos!.longitude,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.oid) // ✅ ออเดอร์เดียว
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const Center(child: Text('ไม่พบคำสั่งซื้อ'));
        }

        final data = snap.data!.data()!;

        // รีเซ็ตพิกัด
        riderPos = null;
        receiverPos = null;

        final List<Marker> markers = [];

        // ผู้รับของเรา
        if (data['receiver_id'] == widget.uid &&
            data['receiver_latitude'] != null &&
            data['receiver_longitude'] != null) {
          receiverPos = LatLng(
            double.tryParse('${data['receiver_latitude']}') ?? 0,
            double.tryParse('${data['receiver_longitude']}') ?? 0,
          );
          markers.add(
            Marker(
              point: receiverPos!,
              width: 30,
              height: 30,
              child: const Icon(
                Icons.location_on,
                color: Colors.blue,
                size: 30,
              ),
            ),
          );
        }

        // ไรเดอร์ของออเดอร์นี้
        if ((data['rider_id'] ?? '') == widget.rid &&
            data['rider_latitude'] != null &&
            data['rider_longitude'] != null) {
          riderPos = LatLng(
            double.tryParse('${data['rider_latitude']}') ?? 0,
            double.tryParse('${data['rider_longitude']}') ?? 0,
          );
          markers.add(
            Marker(
              point: riderPos!,
              width: 30,
              height: 30,
              child: const Icon(
                Icons.directions_bike_sharp,
                color: Colors.red,
                size: 30,
              ),
            ),
          );
        }

        // กล้องเริ่มต้น
        LatLng initialCenter =
            receiverPos ?? riderPos ?? const LatLng(15.870031, 100.992541);
        double initialZoom = (receiverPos != null && riderPos != null)
            ? 14
            : 13;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blueGrey, width: 2),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 300,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: initialZoom,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.rider_app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ---------------- รายละเอียดสินค้า (เพิ่มรูปตามสถานะถ้ามี) ----------------
class ProductDetail extends StatefulWidget {
  final String oid, uid;
  const ProductDetail({super.key, required this.oid, required this.uid});

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  List<Map<String, dynamic>> orderDetail = [];
  String? senderName;
  String? senderAddress;
  String? senderPhone;
  String? status;
  String? imagePickupUrl; // ✅ รูปตอนรับของ
  String? imageDeliveredUrl; // ✅ รูปตอนส่งสำเร็จ
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDeliveredOrders();
  }

  Future<void> _fetchDeliveredOrders() async {
    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.oid)
          .get();

      if (!orderDoc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final String? senderId = orderData['sender_id'];

      if (senderId == null || senderId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();

      setState(() {
        orderDetail = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
        senderAddress = orderData['sender_address'] ?? 'ไม่ระบุที่อยู่';
        senderName = userDoc.data()?['fullname'] ?? 'ไม่ระบุชื่อผู้ส่ง';
        senderPhone = userDoc.data()?['phone'] ?? 'ไม่ระบุเบอร์โทร';
        status = (orderData['status'] ?? 'ว่าง').toString();

        // ✅ ดึง URL รูปจากออเดอร์
        imagePickupUrl = (orderData['image_pickup'] ?? '').toString();
        imageDeliveredUrl = (orderData['image_delivered'] ?? '').toString();

        _isLoading = false;
      });
    } catch (e) {
      log("fetch error: $e");
      setState(() => _isLoading = false);
    }
  }

  bool get _shouldShowPickup {
    // แสดงรูปตอนรับของเมื่อสถานะถึงขั้นรับของแล้วขึ้นไป
    return (imagePickupUrl ?? '').isNotEmpty &&
        (status == 'ไรเดอร์รับสินค้าแล้ว (กำลังเดินทางไปส่ง)' ||
            status == 'ไรเดอร์นำส่งสินค้าแล้ว');
  }

  bool get _shouldShowDelivered {
    // แสดงรูปส่งสำเร็จเฉพาะตอน "นำส่งแล้ว"
    return (imageDeliveredUrl ?? '').isNotEmpty &&
        status == 'ไรเดอร์นำส่งสินค้าแล้ว';
  }

  Widget _proofTile(String title, String url) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 56,
              height: 56,
              color: Colors.grey[200],
              child: const Icon(Icons.image_not_supported),
            ),
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('สถานะปัจจุบัน: ${status ?? '-'}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (orderDetail.isEmpty) {
      return const Center(child: Text('ไม่พบข้อมูลสินค้า'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // รายการสินค้า
        ...orderDetail.map((item) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 0),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item['imageUrl'] ?? '',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (item['detail'] ?? 'ไม่ระบุรายละเอียด').toString(),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          senderName ?? '-',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                        SizedBox(
                          width: 200,
                          child: Text(
                            senderAddress ?? '-',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        Text(
                          senderPhone ?? '-',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 8),

        // ✅ หลักฐานจากไรเดอร์ (แสดงตามสถานะ)
        if (_shouldShowPickup || _shouldShowDelivered)
          const Padding(
            padding: EdgeInsets.only(left: 4.0, bottom: 6),
            child: Text(
              'หลักฐานจากไรเดอร์',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        if (_shouldShowPickup)
          _proofTile('รูปตอนรับสินค้า (Pickup)', imagePickupUrl!),
        if (_shouldShowDelivered)
          _proofTile('รูปตอนส่งสำเร็จ (Delivered)', imageDeliveredUrl!),
      ],
    );
  }
}

/// ---------------- ตัวติดตามสถานะ ----------------
class StatusTracker extends StatefulWidget {
  final String oid, uid, rid;
  const StatusTracker({
    super.key,
    required this.oid,
    required this.uid,
    required this.rid,
  });

  @override
  State<StatusTracker> createState() => _StatusTrackerState();
}

class _StatusTrackerState extends State<StatusTracker> {
  bool _isLoading = true;
  String? status;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final statueDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.oid)
          .get();
      final data = statueDoc.data() as Map<String, dynamic>;
      setState(() {
        status = data['status'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      log('fetch error:$e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const CircularProgressIndicator();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatusIcon(
          Icons.access_time_filled,
          status == 'รอไรเดอร์รับสินค้า' ||
              status == 'ไรเดอร์รับงานแล้ว (กำลังเดินทางไปรับสินค้า)' ||
              status == 'ไรเดอร์รับสินค้าแล้ว (กำลังเดินทางไปส่ง)' ||
              status == 'ไรเดอร์นำส่งสินค้าแล้ว',
        ),
        _buildConnector(status != 'รอไรเดอร์รับสินค้า'),
        _buildStatusIcon(
          Icons.upload,
          status == 'ไรเดอร์รับงานแล้ว (กำลังเดินทางไปรับสินค้า)' ||
              status == 'ไรเดอร์รับสินค้าแล้ว (กำลังเดินทางไปส่ง)' ||
              status == 'ไรเดอร์นำส่งสินค้าแล้ว',
        ),
        _buildConnector(
          status != 'รอไรเดอร์รับสินค้า' &&
              status != 'ไรเดอร์รับงานแล้ว (กำลังเดินทางไปรับสินค้า)',
        ),
        _buildStatusIcon(
          Icons.motorcycle,
          status == 'ไรเดอร์รับสินค้าแล้ว (กำลังเดินทางไปส่ง)' ||
              status == 'ไรเดอร์นำส่งสินค้าแล้ว',
        ),
        _buildConnector(status == 'ไรเดอร์นำส่งสินค้าแล้ว'),
        _buildStatusIcon(
          Icons.check_circle,
          status == 'ไรเดอร์นำส่งสินค้าแล้ว',
        ),
      ],
    );
  }

  Widget _buildStatusIcon(IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade400 : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(
        icon,
        color: isActive ? Colors.white : Colors.grey.shade400,
        size: 24,
      ),
    );
  }

  Widget _buildConnector(bool isActive) {
    return Container(
      width: 40,
      height: 10,
      color: isActive
          ? Colors.green.shade400
          : Colors.grey[300]?.withOpacity(0.5),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    if (status == 'ไรเดอร์นำส่งสินค้าแล้ว') ;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        title: const Center(
          child: Text(
            'ไรเดอร์นำส่งสินค้าสำเร็จแล้ว',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: const Text('คุณได้รับสินค่าแล้วใช่หรือไม่?'),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'ได้รับแล้ว',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              Get.to(() => ReceivedTab(uid: widget.uid, rid: widget.rid));
            },
          ),
        ],
      ),
    );
  }
}
