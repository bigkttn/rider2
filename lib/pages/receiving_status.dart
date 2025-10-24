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

/// ---------------------------------------------------------
/// ReceivingStatus — UI สวยขึ้น + แก้ปัญหา UI ซ้อนกัน
/// - Gradient AppBar + ใช้ bottom: PreferredSize วาง StatusTracker (ไม่ทับ)
/// - FlutterMap ตัวเดียว (TileLayer + MarkerLayer) ป้องกันซ้อน/ทับ
/// - เอา const ออกจากจุดที่ไม่ควร const (TileLayer / children)
/// ---------------------------------------------------------
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
      backgroundColor: const Color(0xfffef2f2),
      appBar: AppBar(
        elevation: 0,
        // เปลี่ยนเป็น false ถ้าไม่ต้องการลูกศรย้อนกลับ
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        title: const Text(
          'สถานะการจัดส่ง',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xffff3b30), Color(0xfffb6a5b)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'รหัสคำสั่งซื้อ: ${widget.oid}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
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
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(icon: Icons.person, text: 'ไรเดอร์'),
                    const SizedBox(height: 8),
                    RiderContact(
                      uid: widget.uid,
                      rid: widget.rid,
                      oid: widget.oid,
                    ),
                    const SizedBox(height: 16),
                    const _SectionHeader(
                      icon: Icons.map_outlined,
                      text: 'ตำแหน่งล่าสุด',
                    ),
                    const SizedBox(height: 8),
                    MapReceive(
                      uid: widget.uid,
                      rid: widget.rid,
                      oid: widget.oid,
                    ),
                    const SizedBox(height: 16),
                    const _SectionHeader(
                      icon: Icons.inventory_2_outlined,
                      text: 'รายละเอียดสินค้า',
                    ),
                    const SizedBox(height: 8),
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

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionHeader({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xffffefe9),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: const Color(0xfffb6a5b), size: 18),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// ---------------- Rider (ListTile สวย + กันข้อความชนปุ่ม) ----------------
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
    if (!_hasRider) return const _EmptyHint(text: 'ระบบกำลังหาไรเดอร์ให้คุณ…');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ListTile(
          isThreeLine: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 8,
          ),
          leading: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: (riderProfile ?? '').isNotEmpty
                    ? NetworkImage(riderProfile!)
                    : null,
                backgroundColor: const Color(0xffffefef),
                child: (riderProfile ?? '').isEmpty
                    ? const Icon(Icons.person, size: 32, color: Colors.grey)
                    : null,
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xff22c55e),
                  border: Border.all(color: Colors.white, width: 2),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          title: Text(
            riderName ?? 'ไม่ระบุชื่อ',
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 14),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'ทะเบียน: ${riderVehicleNumber ?? '-'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      riderPhone ?? 'ไม่ระบุเบอร์โทร',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: SizedBox(
            width: 110,
            height: 36,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xffff3b30),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Get.to(() => Riderprofile(rid: widget.rid)),
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text(
                'ข้อมูลไรเดอร์',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xfffff7ed),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffffedd5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xfffb923c)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: Color(0xff9a3412))),
          ),
        ],
      ),
    );
  }
}

/// ---------------- แผนที่ (FlutterMap ตัวเดียว) ----------------
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
          .doc(widget.oid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const _EmptyHint(text: 'ไม่พบคำสั่งซื้อ');
        }

        final data = snap.data!.data()!;

        // รีเซ็ตพิกัด
        riderPos = null;
        receiverPos = null;

        final List<Marker> markers = [];

        // ผู้รับ
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
              width: 34,
              height: 34,
              child: const Icon(
                Icons.location_on,
                color: Colors.blue,
                size: 34,
              ),
            ),
          );
        }

        // ไรเดอร์
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
              width: 34,
              height: 34,
              child: const Icon(
                Icons.directions_bike_sharp,
                color: Colors.red,
                size: 30,
              ),
            ),
          );
        }

        // กล้องเริ่มต้น
        final LatLng initialCenter =
            receiverPos ?? riderPos ?? const LatLng(15.870031, 100.992541);
        final double initialZoom = (receiverPos != null && riderPos != null)
            ? 14
            : 13;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 320,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: initialZoom,
                    // ใช้ interactionOptions (แทน interactiveFlags)
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag
                          .all, // หรือ InteractiveFlag.none ถ้าจะล็อก
                    ),
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

                if (distanceToRider != null)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Chip(
                      avatar: const Icon(Icons.route, size: 18),
                      label: Text(
                        distanceToRider! >= 1000
                            ? '${(distanceToRider! / 1000).toStringAsFixed(2)} กม.'
                            : '${distanceToRider!.toStringAsFixed(0)} ม.',
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: const BorderSide(color: Color(0xffe5e7eb)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ---------------- รายละเอียดสินค้า (Cards + หลักฐานเป็น Tile) ----------------
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
  String? imagePickupUrl; // รูปตอนรับของ
  String? imageDeliveredUrl; // รูปตอนส่งสำเร็จ
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
    return (imagePickupUrl ?? '').isNotEmpty &&
        (status == 'ไรเดอร์รับสินค้าแล้ว (กำลังเดินทางไปส่ง)' ||
            status == 'ไรเดอร์นำส่งสินค้าแล้ว');
  }

  bool get _shouldShowDelivered {
    return (imageDeliveredUrl ?? '').isNotEmpty &&
        status == 'ไรเดอร์นำส่งสินค้าแล้ว';
  }

  Widget _proofTile(String title, String url) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
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
      return const _EmptyHint(text: 'ไม่พบข้อมูลสินค้า');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...orderDetail.map((item) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item['imageUrl'] ?? '',
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (item['detail'] ?? 'ไม่ระบุรายละเอียด').toString(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                senderName ?? '-',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.blueGrey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                senderAddress ?? '-',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.blueGrey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              senderPhone ?? '-',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.blueGrey,
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
          );
        }),
        const SizedBox(height: 10),
        if (_shouldShowPickup || _shouldShowDelivered) ...[
          const Divider(),
          const SizedBox(height: 6),
          const Text(
            'หลักฐานจากไรเดอร์',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (_shouldShowPickup)
            _proofTile('รูปตอนรับสินค้า (Pickup)', imagePickupUrl!),
          if (_shouldShowDelivered)
            _proofTile('รูปตอนส่งสำเร็จ (Delivered)', imageDeliveredUrl!),
        ],
      ],
    );
  }
}

/// ---------------- ตัวติดตามสถานะ (เขียวเหมือนแบบแรก) ----------------
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
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // ลำดับสถานะ
    final steps = <String>[
      'รอไรเดอร์รับสินค้า',
      'ไรเดอร์รับงานแล้ว (กำลังเดินทางไปรับสินค้า)',
      'ไรเดอร์รับสินค้าแล้ว (กำลังเดินทางไปส่ง)',
      'ไรเดอร์นำส่งสินค้าแล้ว',
    ];
    int activeIndex = steps.indexWhere((s) => s == status);
    if (activeIndex == -1) activeIndex = 0;

    // สีตามแบบแรก
    const activeGreen = Color(0xFF22C55E); // เขียวสด
    final inactiveDotBg = Colors.white; // พื้นขาวสำหรับจุดที่ยังไม่ active
    final inactiveIcon = Colors.grey.shade400;
    final connectorActive = activeGreen;
    final connectorInactive = Colors.white.withOpacity(.5);

    final icons = const [
      Icons.access_time_filled,
      Icons.upload,
      Icons.motorcycle,
      Icons.check_circle,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(icons.length * 2 - 1, (i) {
        if (i.isOdd) {
          // เส้นเชื่อม
          final leftStep = i ~/ 2;
          final isActiveConnector = leftStep < activeIndex;
          return Expanded(
            child: Container(
              height: 8, // สูงขึ้นนิดให้ดูชัด
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isActiveConnector ? connectorActive : connectorInactive,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }
        // จุดสถานะ
        final idx = i ~/ 2;
        final isActive = idx <= activeIndex;
        return _buildStatusIcon(
          icons[idx],
          isActive: isActive,
          activeGreen: activeGreen,
          inactiveDotBg: inactiveDotBg,
          inactiveIcon: inactiveIcon,
        );
      }),
    );
  }

  Widget _buildStatusIcon(
    IconData icon, {
    required bool isActive,
    required Color activeGreen,
    required Color inactiveDotBg,
    required Color inactiveIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? activeGreen : inactiveDotBg,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(
        icon,
        color: isActive ? Colors.white : inactiveIcon,
        size: 22,
      ),
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
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xffff3b30)),
            onPressed: () async {
              Get.to(() => ReceivedTab(uid: widget.uid, rid: widget.rid));
            },
            child: const Text(
              'ได้รับแล้ว',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
