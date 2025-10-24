import 'package:blink_delivery_project/pages/sending_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// สถานะที่ถือว่ายัง "กำลังวิ่งอยู่"
const List<String> kActiveStatuses = [
  'รอไรเดอร์รับสินค้า',
  'ไรเดอร์รับงานแล้ว (กำลังเดินทางไปรับสินค้า)',
  'ไรเดอร์รับสินค้าแล้ว (กำลังเดินทางไปส่ง)',
];

class HistoryPage extends StatefulWidget {
  final String uid;
  const HistoryPage({super.key, required this.uid});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> ordersList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  /// ดึงคำสั่งซื้อที่เกี่ยวกับผู้ใช้ (sender หรือ receiver)
  Future<void> _fetchOrders() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('orders').get();
      final temp = <Map<String, dynamic>>[];

      for (final doc in snap.docs) {
        final data = doc.data();

        final isMine =
            data['sender_id'] == widget.uid ||
            data['receiver_id'] == widget.uid;
        if (!isMine) continue;

        // ดึงโปรไฟล์ผู้ส่ง/ผู้รับ
        final senderDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc((data['sender_id'] ?? '').toString())
            .get();
        final receiverDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc((data['receiver_id'] ?? '').toString())
            .get();

        final sender = senderDoc.data();
        final receiver = receiverDoc.data();

        temp.add({
          'order_id': doc.id,
          'item': (data['items'] ?? []) as List<dynamic>,
          'status': (data['status'] ?? '').toString(),
          'image_pickup': (data['image_pickup'] ?? '').toString(),
          'image_delivered': (data['image_delivered'] ?? '').toString(),
          'sender_name': senderDoc.exists
              ? (sender?['fullname'] ?? 'ไม่ระบุชื่อผู้ส่ง').toString()
              : 'ไม่ระบุชื่อผู้ส่ง',
          'sender_phone': senderDoc.exists
              ? (sender?['phone'] ?? '-').toString()
              : '-',
          'sender_address': (data['sender_address'] ?? 'ไม่ระบุที่อยู่ผู้ส่ง')
              .toString(),
          'receiver_name': receiverDoc.exists
              ? (receiver?['fullname'] ?? 'ไม่ระบุชื่อผู้รับ').toString()
              : 'ไม่ระบุชื่อผู้รับ',
          'receiver_phone': receiverDoc.exists
              ? (receiver?['phone'] ?? '-').toString()
              : '-',
          'receiver_address':
              (data['receiver_address'] ?? 'ไม่ระบุที่อยู่ผู้รับ').toString(),
          'createAt': data['createAt'],
        });
      }

      // เรียงล่าสุดก่อนถ้ามี Timestamp
      temp.sort((a, b) {
        final ta = a['createAt'];
        final tb = b['createAt'];
        if (ta is Timestamp && tb is Timestamp) {
          return tb.compareTo(ta);
        }
        return 0;
      });

      if (!mounted) return;
      setState(() {
        ordersList = temp;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error fetching orders: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => isLoading = true);
    await _fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffff3b30),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(150),
        child: AppBar(
          backgroundColor: const Color(0xffff3b30),
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: const Padding(
            padding: EdgeInsets.only(top: 100),
            child: Center(
              child: Text(
                'ประวัติรายการส่งสินค้า',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            topLeft: Radius.circular(20),
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  // +1 แถวสำหรับแผนที่บนสุด
                  itemCount: (ordersList.isEmpty ? 1 : (ordersList.length + 1)),
                  itemBuilder: (context, index) {
                    // index 0 = แผนที่ไรเดอร์ทั้งหมดของผู้ส่งนี้
                    if (index == 0) {
                      return _RidersMapSection(senderId: widget.uid);
                    }

                    // ถ้าไม่มีออเดอร์อื่นๆ ให้ขึ้นข้อความ
                    if (ordersList.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('ไม่มีประวัติการส่งของคุณ')),
                      );
                    }

                    final order = ordersList[index - 1];
                    final items = order['item'] as List<dynamic>? ?? [];

                    return Column(
                      children: items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildHistoryItem(
                            imageUrl: (item['imageUrl'] ?? '').toString(),
                            itemDetail:
                                (item['detail'] ?? 'ไม่ระบุรายละเอียดสินค้า')
                                    .toString(),
                            senderName: (order['sender_name'] ?? '').toString(),
                            senderAddress: (order['sender_address'] ?? '')
                                .toString(),
                            senderPhone: (order['sender_phone'] ?? '-')
                                .toString(),
                            receiverName: (order['receiver_name'] ?? '')
                                .toString(),
                            receiverAddress: (order['receiver_address'] ?? '')
                                .toString(),
                            receiverPhone: (order['receiver_phone'] ?? '-')
                                .toString(),
                            status: (order['status'] ?? '').toString(),
                            orderData: order,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
      ),
    );
  }

  /// การ์ดออเดอร์แต่ละรายการ
  Widget _buildHistoryItem({
    required String imageUrl,
    required String itemDetail,
    required String senderName,
    required String senderAddress,
    required String senderPhone,
    required String receiverName,
    required String receiverAddress,
    required String receiverPhone,
    required String status,
    required Map<String, dynamic> orderData,
  }) {
    final statusText = status.isNotEmpty ? status : 'กำลังประมวลผล';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl.isNotEmpty
                        ? imageUrl
                        : 'https://via.placeholder.com/80',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    itemDetail,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'สถานะ: $statusText',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            _buildAddressInfo(
              'ผู้ส่ง:',
              senderName,
              senderAddress,
              senderPhone,
            ),
            const Divider(height: 20),
            _buildAddressInfo(
              'ผู้รับ:',
              receiverName,
              receiverAddress,
              receiverPhone,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SendingStatus(orderData: orderData),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('ดูรายละเอียด'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressInfo(
    String title,
    String name,
    String address,
    String phone,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title $name',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Text(address, style: const TextStyle(fontSize: 14)),
        Text('เบอร์โทร: $phone', style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

/// =======================================================
/// แผนที่ไรเดอร์ทั้งหมดของ "ผู้ส่งคนนี้" (เฉพาะงานที่ยังไม่ส่งแล้ว)
/// - แตะหมุดไรเดอร์: แสดงรายละเอียดออเดอร์ใน BottomSheet
/// - กดหมุดซ้ำ: toggle โหมดติดตาม กล้องจะเลื่อนตามตำแหน่งที่อัพเดต
/// =======================================================
class _RidersMapSection extends StatefulWidget {
  final String senderId;
  const _RidersMapSection({required this.senderId});

  @override
  State<_RidersMapSection> createState() => _RidersMapSectionState();
}

class _RidersMapSectionState extends State<_RidersMapSection> {
  final MapController _mapController = MapController();

  String? _followRiderId; // ถ้าไม่ null = โหมดติดตามไรเดอร์คนนี้

  // เปิดรายละเอียดออเดอร์ของไรเดอร์ (ใช้ข้อมูลจาก doc data ที่มีอยู่แล้ว)
  Future<void> _showOrderDetailsBottomSheet({
    required String orderId,
    required Map<String, dynamic> data,
  }) async {
    final senderId = (data['sender_id'] ?? '').toString();
    final receiverId = (data['receiver_id'] ?? '').toString();
    final riderId = (data['rider_id'] ?? '').toString();

    final senderDoc = senderId.isNotEmpty
        ? await FirebaseFirestore.instance
              .collection('users')
              .doc(senderId)
              .get()
        : null;
    final receiverDoc = receiverId.isNotEmpty
        ? await FirebaseFirestore.instance
              .collection('users')
              .doc(receiverId)
              .get()
        : null;
    final riderDoc = riderId.isNotEmpty
        ? await FirebaseFirestore.instance
              .collection('riders')
              .doc(riderId)
              .get()
        : null;

    final senderName = senderDoc?.data()?['fullname'] ?? '-';
    final senderPhone = senderDoc?.data()?['phone'] ?? '-';
    final senderAddress = data['sender_address'] ?? '-';

    final receiverName = receiverDoc?.data()?['fullname'] ?? '-';
    final receiverPhone = receiverDoc?.data()?['phone'] ?? '-';
    final receiverAddress = data['receiver_address'] ?? '-';

    final riderName = riderDoc?.data()?['fullname'] ?? '-';
    final riderPhone = riderDoc?.data()?['phone'] ?? '-';

    final items = (data['items'] is List) ? (data['items'] as List) : const [];
    final status = (data['status'] ?? '').toString();
    final imgPickup = (data['image_pickup'] ?? '').toString();
    final imgDelivered = (data['image_delivered'] ?? '').toString();

    // เปิดแผ่นล่าง
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (ctx, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.directions_bike, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Order ID: $orderId',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'สถานะ: $status',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),

                  // สินค้า
                  if (items.isNotEmpty)
                    ...items.map(
                      (it) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            (it['imageUrl'] ?? '').toString(),
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
                        title: Text(
                          (it['detail'] ?? 'ไม่ระบุรายละเอียดสินค้า')
                              .toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  const Divider(height: 24),
                  const Text(
                    'ผู้ส่ง',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('ชื่อ: $senderName'),
                  Text('โทร: $senderPhone'),
                  Text('ที่อยู่: $senderAddress'),
                  const SizedBox(height: 12),

                  const Text(
                    'ผู้รับ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('ชื่อ: $receiverName'),
                  Text('โทร: $receiverPhone'),
                  Text('ที่อยู่: $receiverAddress'),
                  const SizedBox(height: 12),

                  const Text(
                    'ไรเดอร์',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('ชื่อ: $riderName'),
                  Text('โทร: $riderPhone'),
                  const SizedBox(height: 12),

                  // หลักฐานจากไรเดอร์
                  if (imgPickup.isNotEmpty || imgDelivered.isNotEmpty) ...[
                    const Divider(height: 24),
                    const Text(
                      'หลักฐานจากไรเดอร์',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (imgPickup.isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imgPickup,
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
                        title: const Text('รูปตอนรับสินค้า (Pickup)'),
                      ),
                    if (imgDelivered.isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imgDelivered,
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
                        title: const Text('รูปตอนส่งสำเร็จ (Delivered)'),
                      ),
                  ],

                  const SizedBox(height: 16),

                  // ปุ่มไปหน้ารายละเอียด
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.info, color: Color(0xffff3b30)),
                      label: const Text('ดูรายละเอียด'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xffff3b30),
                          width: 2,
                        ),
                        foregroundColor: const Color(0xffff3b30),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // ปิด bottom sheet
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SendingStatus(orderData: data),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ไรเดอร์ของคุณ (กำลังจัดส่งอยู่)',
            style: TextStyle(
              color: Color(0xffff3b30),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xffff3b30), width: 2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('sender_id', isEqualTo: widget.senderId)
                    .where('status', whereIn: kActiveStatuses)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('ยังไม่มีไรเดอร์ที่กำลังจัดส่ง'),
                    );
                  }

                  // รวมพิกัดไรเดอร์แบบ unique โดย key = rider_id
                  final Map<
                    String,
                    (LatLng pos, Map<String, dynamic> data, String orderId)
                  >
                  riderMap = {};

                  for (final doc in snap.data!.docs) {
                    final d = doc.data();
                    final rid = (d['rider_id'] ?? '').toString().trim();
                    final lat = _toDouble(d['rider_latitude']);
                    final lng = _toDouble(d['rider_longitude']);
                    if (rid.isEmpty || lat == null || lng == null) continue;

                    // เก็บอันล่าสุดทับของเดิม (กรณีมีหลายออเดอร์กับไรเดอร์เดียวกัน)
                    riderMap[rid] = (LatLng(lat, lng), d, doc.id);
                  }

                  if (riderMap.isEmpty) {
                    return const Center(
                      child: Text('ยังไม่มีพิกัดไรเดอร์ให้แสดง'),
                    );
                  }

                  final markers = <Marker>[];
                  final points = <LatLng>[];

                  for (final entry in riderMap.entries) {
                    final rid = entry.key;
                    final pos = entry.value.$1;
                    final data = entry.value.$2;
                    final orderId = entry.value.$3;

                    points.add(pos);

                    markers.add(
                      Marker(
                        point: pos,
                        width: 42,
                        height: 42,
                        child: GestureDetector(
                          onTap: () async {
                            // toggle ติดตามกล้องตามไรเดอร์
                            setState(() {
                              _followRiderId = (_followRiderId == rid)
                                  ? null
                                  : rid;
                            });
                            // เปิดรายละเอียดออเดอร์
                            await _showOrderDetailsBottomSheet(
                              orderId: orderId,
                              data: data,
                            );
                          },
                          child: Icon(
                            Icons.directions_bike_sharp,
                            color: (_followRiderId == rid)
                                ? Colors
                                      .green // ถ้ากำลังติดตาม แสดงสีเขียว
                                : Colors.red,
                            size: 36,
                          ),
                        ),
                      ),
                    );
                  }

                  // กล้อง: ถ้ากำลัง follow ไรเดอร์ ให้ตามตำแหน่งทุกอัพเดต
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    if (_followRiderId != null &&
                        riderMap.containsKey(_followRiderId)) {
                      final pos = riderMap[_followRiderId]!.$1;
                      _mapController.move(pos, _mapController.camera.zoom);
                    } else {
                      // ไม่ได้ follow: fit ให้เห็นทั้งหมดเฉพาะครั้งแรก หรือเมื่อเปลี่ยนชุดจุดเยอะๆ
                      if (points.length >= 2) {
                        final b = LatLngBounds.fromPoints(points);
                        _mapController.fitCamera(
                          CameraFit.bounds(
                            bounds: b,
                            padding: const EdgeInsets.all(20),
                          ),
                        );
                      } else {
                        _mapController.move(points.first, 15);
                      }
                    }
                  });

                  return FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: points.first,
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.blink.delivery',
                      ),
                      MarkerLayer(markers: markers),
                      const RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution('© OpenStreetMap contributors'),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- helpers ----------
double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}
