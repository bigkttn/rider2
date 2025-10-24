import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:blink_delivery_project/pages/receiving_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

class OrderlistPage extends StatefulWidget {
  final String uid;
  final String rid;
  final String oid;
  const OrderlistPage({
    super.key,
    required this.uid,
    required this.rid,
    required this.oid,
  });

  @override
  State<OrderlistPage> createState() => _OrderlistPageState();
}

class _OrderlistPageState extends State<OrderlistPage> {
  int _selectedIndex = 0;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      InTransitTab(uid: widget.uid, rid: widget.rid, oid: widget.oid),
      MapReceive(uid: widget.uid, rid: widget.rid),
      ReceivedTab(uid: widget.uid, rid: widget.rid),
      SentTab(uid: widget.uid), // ✅ แท็บใหม่: สินค้าที่ส่ง
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFFFF3B30)),
          Positioned(
            top: 150,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          _tabButton('สินค้ากำลังมาส่ง', 0),
                          _tabButton('ไรเดอร์ทั้งหมด', 1),
                          _tabButton('สินค้าที่เคยได้รับ', 2),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 0),
                      child: _pages[_selectedIndex],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Padding(
                  padding: EdgeInsets.only(top: 70, left: 80),
                  child: Text(
                    "รายการสินค้าของคุณ",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int idx) {
    final selected = _selectedIndex == idx;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextButton(
        onPressed: () => setState(() => _selectedIndex = idx),
        style: ButtonStyle(
          side: const WidgetStatePropertyAll(
            BorderSide(color: Color(0xffff3b30), width: 2),
          ),
          foregroundColor: MaterialStateProperty.resolveWith<Color?>(
            (states) => selected ? const Color(0xffff3b30) : Colors.grey,
          ),
          backgroundColor: MaterialStateProperty.resolveWith<Color?>(
            (states) => Colors.white,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xffff3b30) : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

//-----------------------------------------------------------
class ProductHistoryCard extends StatelessWidget {
  final String imageUrl;
  final String productDetial;
  final String senderName;
  final String senderAddress;
  final String senderPhone;
  final String riderName;
  final String riderPhone;
  final String status;
  final dynamic createAt;
  final String uid;
  final String rid;
  final String oid;

  const ProductHistoryCard({
    super.key,
    required this.imageUrl,
    required this.productDetial,
    required this.senderName,
    required this.senderAddress,
    required this.senderPhone,
    required this.riderName,
    required this.riderPhone,
    required this.status,
    required this.createAt,
    required this.uid,
    required this.rid,
    required this.oid,
  });

  @override
  Widget build(BuildContext context) {
    final isDelivered = status == 'ไรเดอร์นำส่งสินค้าแล้ว';
    final buttonLabel = isDelivered ? 'รายละเอียด' : 'รายละเอียด';

    return Card(
      elevation: 0.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Text(
                    productDetial,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            const Divider(),
            Text(
              "ผู้ส่ง: $senderName",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(senderAddress),
            Text("เบอร์โทร: $senderPhone"),
            const Divider(),
            Text(
              "ไรเดอร์: ${riderName.isNotEmpty ? riderName : '-'}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("เบอร์โทร: ${riderPhone.isNotEmpty ? riderPhone : '-'}"),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 200,
                  child: Text(
                    "สถานะ: $status",
                    style: const TextStyle(color: Colors.green),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // ปุ่มรายละเอียด (เปิดได้เสมอ) — ถ้าเป็นส่งสำเร็จ จะเปลี่ยนข้อความเป็น "ดูรายละเอียดออเดอร์"
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ReceivingStatus(uid: uid, rid: rid, oid: oid),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Color(0xffff3b30), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(buttonLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<DocumentSnapshot?> safeGetDoc(String collection, String? id) async {
  if (id == null || id.isEmpty) return null;
  return FirebaseFirestore.instance.collection(collection).doc(id).get();
}

//-----------------------------------------------------
// หน้าสินค้ากำลังมาส่ง: แสดงเฉพาะ 3 สถานะตามที่กำหนด
class InTransitTab extends StatefulWidget {
  final String uid;
  final String rid;
  final String oid;
  const InTransitTab({
    super.key,
    required this.uid,
    required this.rid,
    required this.oid,
  });

  @override
  State<InTransitTab> createState() => _InTransitTabState();
}

class _InTransitTabState extends State<InTransitTab> {
  List<Map<String, dynamic>> productReceivedList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReceiveOrders();
  }

  Future<void> _fetchReceiveOrders() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where(
            'status',
            whereIn: [
              'ไรเดอร์รับงานแล้ว (กำลังเดินทางไปรับสินค้า)',
              'รอไรเดอร์รับสินค้า',
              'ไรเดอร์รับสินค้าแล้ว (กำลังเดินทางไปส่ง)',
            ],
          )
          .get();

      final List<Map<String, dynamic>> tempOrder = [];

      for (var orderData in snapshot.docs) {
        final data = orderData.data();
        final status = (data['status'] ?? '').toString();

        final isMine =
            data['receiver_id'] == widget.uid || data['rider_id'] == widget.rid;
        if (!isMine) continue;

        final senderDoc = await safeGetDoc('users', data['sender_id']);
        final riderId = (data['rider_id'] ?? '').toString();
        DocumentSnapshot? riderDoc;
        if (riderId.isNotEmpty) {
          riderDoc = await safeGetDoc('riders', riderId);
        }

        tempOrder.add({
          'order_id': orderData.id,
          'item': data['items'] ?? [],
          'sender_name': senderDoc != null && senderDoc.exists
              ? (senderDoc['fullname'] ?? '').toString()
              : '',
          'sender_phone': senderDoc != null && senderDoc.exists
              ? (senderDoc['phone'] ?? '').toString()
              : '',
          'sender_address': (data['sender_address'] ?? '').toString(),
          'rider_id': riderId,
          'rider_name': riderDoc != null && riderDoc.exists
              ? (riderDoc['fullname'] ?? '').toString()
              : '',
          'rider_phone': riderDoc != null && riderDoc.exists
              ? (riderDoc['phone'] ?? '').toString()
              : '',
          'status': status,
          'createAt': data['createAt'],
        });
      }

      setState(() {
        productReceivedList = tempOrder;
        _isLoading = false;
      });
    } catch (e) {
      log('Error fetching orders: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (productReceivedList.isEmpty) {
      return const Center(child: Text('ไม่มีรายการที่อยู่ระหว่างจัดส่ง'));
    }

    return ListView.builder(
      itemCount: productReceivedList.length,
      itemBuilder: (context, index) {
        final order = productReceivedList[index];
        final items = (order['item'] is List)
            ? order['item'] as List<dynamic>
            : <dynamic>[];

        if (items.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: items.map<Widget>((item) {
              return ProductHistoryCard(
                imageUrl: (item['imageUrl'] ?? '').toString(),
                productDetial: (item['detail'] ?? 'ไม่ระบุรายละเอียดสินค้า')
                    .toString(),
                senderName: (order['sender_name'] ?? 'ไม่ระบุชื่อ').toString(),
                senderAddress: (order['sender_address'] ?? 'ไม่ระบุที่อยู่')
                    .toString(),
                senderPhone: (order['sender_phone'] ?? 'ไม่ระบุเบอร์โทรศัพท์')
                    .toString(),
                riderName: (order['rider_name'] ?? 'ไม่ระบุชื่อ').toString(),
                riderPhone: (order['rider_phone'] ?? 'ไม่ระบุเบอร์โทรศัพท์')
                    .toString(),
                status: (order['status'] ?? '').toString(),
                createAt: order['createAt'] ?? '',
                uid: widget.uid,
                rid: (order['rider_id'] ?? '').toString(),
                oid: (order['order_id'] ?? '').toString(),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

//-----------------------------------------------------
// หน้าไรเดอร์ทั้งหมด (แผนที่): เฉพาะสถานะที่กำหนด และแตะหมุดเพื่อดูรายละเอียด
class MapReceive extends StatefulWidget {
  final String uid, rid;
  const MapReceive({super.key, required this.uid, required this.rid});

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

  Future<void> _showOrderDetails({
    required String orderId,
    required Map<String, dynamic> data,
  }) async {
    final senderDoc = await safeGetDoc('users', data['sender_id']);
    final riderDoc = await safeGetDoc('riders', data['rider_id']);

    final senderName = (senderDoc != null && senderDoc.exists)
        ? senderDoc['fullname']
        : '';
    final senderPhone = (senderDoc != null && senderDoc.exists)
        ? senderDoc['phone']
        : '';
    final senderAddress = data['sender_address'] ?? '';

    final riderName = (riderDoc != null && riderDoc.exists)
        ? riderDoc['fullname']
        : '';
    final riderPhone = (riderDoc != null && riderDoc.exists)
        ? riderDoc['phone']
        : '';

    final items = (data['items'] is List) ? data['items'] as List : <dynamic>[];

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
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (ctx, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'รายละเอียดออเดอร์',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.assignment, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('Order ID: $orderId'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (items.isNotEmpty)
                    ...items.map((it) {
                      final img = it['imageUrl'] ?? '';
                      final detail = it['detail'] ?? 'ไม่ระบุรายละเอียดสินค้า';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            img,
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
                          detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('สถานะ: ${data['status'] ?? '-'}'),
                      );
                    }),
                  const Divider(),
                  Text(
                    'ผู้ส่ง',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('ชื่อ: $senderName'),
                  Text('โทร: $senderPhone'),
                  Text('ที่อยู่: $senderAddress'),
                  const SizedBox(height: 8),
                  const Divider(),
                  Text(
                    'ไรเดอร์',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('ชื่อ: ${riderName.isNotEmpty ? riderName : '-'}'),
                  Text('โทร: ${riderPhone.isNotEmpty ? riderPhone : '-'}'),
                  const SizedBox(height: 16),
                  if (distanceToRider != null)
                    Text(
                      'ระยะทางไรเดอร์ → ผู้รับ: ${(distanceToRider! / 1000).toStringAsFixed(2)} กม.',
                      style: const TextStyle(color: Colors.green),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.info,
                            color: Color(0xffff3b30),
                          ),
                          label: const Text('รายละเอียด'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xffff3b30),
                            side: const BorderSide(
                              color: Color(0xffff3b30),
                              width: 2,
                            ),
                          ),
                          onPressed:
                              (data['rider_id'] ?? '').toString().isNotEmpty
                              ? () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ReceivingStatus(
                                        uid: data['receiver_id'],
                                        rid: data['rider_id'],
                                        oid: orderId,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                        ),
                      ),
                    ],
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
    return StreamBuilder<QuerySnapshot>(
      // หน้าไรเดอร์ทั้งหมด: 4 สถานะ
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where(
            'status',
            whereIn: const [
              'รอไรเดอร์รับสินค้า',
              'คุณส่ง',
              'ไรเดอร์รับงานแล้ว (กำลังเดินทางไปรับสินค้า)',
              'ไรเดอร์รับสินค้าแล้ว (กำลังเดินทางไปส่ง)',
            ],
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('ไม่มีคำสั่งซื้อที่กำลังจัดส่ง'));
        }

        final orders = snapshot.data!.docs;

        // เก็บตำแหน่งล่าสุดของ rider ต่อ rider_id (กันหมุดซ้ำ)
        final Map<String, LatLng> riderPositions = {};
        final Map<String, Map<String, dynamic>> riderOrderData = {};
        final Map<String, String> riderOrderId = {};

        receiverPos = null;
        riderPos = null;
        LatLng initialCenter = const LatLng(15.870031, 100.992541);

        for (var doc in orders) {
          final data = doc.data() as Map<String, dynamic>;
          final riderId = (data['rider_id'] ?? '').toString().trim();

          final rLat = double.tryParse('${data['rider_latitude']}');
          final rLng = double.tryParse('${data['rider_longitude']}');
          if (riderId.isNotEmpty && rLat != null && rLng != null) {
            riderPositions[riderId] = LatLng(rLat, rLng);
            riderOrderData[riderId] = data;
            riderOrderId[riderId] = doc.id;
            riderPos = LatLng(rLat, rLng);
          }

          // โฟกัสผู้รับของเรา ถ้ามีพิกัด
          final bool isMyOrder = data['receiver_id'] == widget.uid;
          if (isMyOrder &&
              receiverPos == null &&
              data['receiver_latitude'] != null &&
              data['receiver_longitude'] != null) {
            final recLat = double.tryParse('${data['receiver_latitude']}');
            final recLng = double.tryParse('${data['receiver_longitude']}');
            if (recLat != null && recLng != null) {
              receiverPos = LatLng(recLat, recLng);
              initialCenter = receiverPos!;
            }
          }
        }

        final List<Marker> markers = [];

        if (receiverPos != null) {
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

        for (final entry in riderPositions.entries) {
          final riderId = entry.key;
          final pos = entry.value;
          final orderData = riderOrderData[riderId]!;
          final orderId = riderOrderId[riderId]!;

          markers.add(
            Marker(
              point: pos,
              width: 36,
              height: 36,
              child: GestureDetector(
                onTap: () =>
                    _showOrderDetails(orderId: orderId, data: orderData),
                child: const Icon(
                  Icons.directions_bike_sharp,
                  color: Colors.red,
                  size: 36,
                ),
              ),
            ),
          );
        }

        if (riderPos != null && receiverPos != null) {
          distanceToRider = Geolocator.distanceBetween(
            riderPos!.latitude,
            receiverPos!.latitude,
            riderPos!.longitude,
            receiverPos!.longitude,
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final points = [
            if (receiverPos != null) receiverPos!,
            ...riderPositions.values,
          ];
          if (points.length >= 2) {
            final b = LatLngBounds.fromPoints(points);
            _mapController.fitCamera(
              CameraFit.bounds(bounds: b, padding: const EdgeInsets.all(20)),
            );
          } else if (points.isNotEmpty) {
            _mapController.move(points.first, 15);
          } else {
            _mapController.move(initialCenter, 15);
          }
        });

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueGrey, width: 2),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 3,
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
                    initialZoom: 16,
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
          ),
        );
      },
    );
  }
}

//-------------------------------------------------------
// หน้าสินค้าที่เคยได้รับ: แสดงเฉพาะ "ไรเดอร์นำส่งสินค้าแล้ว"
class ReceivedTab extends StatefulWidget {
  final String uid;
  final String rid;
  const ReceivedTab({super.key, required this.uid, required this.rid});

  @override
  State<ReceivedTab> createState() => _ReceivedTabState();
}

class _ReceivedTabState extends State<ReceivedTab> {
  List<Map<String, dynamic>> deliveredList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDeliveredOrders();
  }

  Future<void> _fetchDeliveredOrders() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'ไรเดอร์นำส่งสินค้าแล้ว')
          .get();

      final tempOrder = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['receiver_id'] == widget.uid ||
            data['rider_id'] == widget.rid) {
          final senderDoc = await safeGetDoc('users', data['sender_id']);
          final riderDoc = await safeGetDoc('riders', data['rider_id']);

          tempOrder.add({
            'order_id': doc.id,
            'item': data['items'] ?? [],
            'sender_name': senderDoc != null && senderDoc.exists
                ? senderDoc['fullname']
                : '',
            'sender_phone': senderDoc != null && senderDoc.exists
                ? senderDoc['phone']
                : '',
            'sender_address': data['sender_address'] ?? '',
            'rider_id': data['rider_id'] ?? '', // ✅ เก็บ rider_id
            'rider_name': riderDoc != null && riderDoc.exists
                ? riderDoc['fullname']
                : '',
            'rider_phone': riderDoc != null && riderDoc.exists
                ? riderDoc['phone']
                : '',
            'status': data['status'] ?? '',
            'createAt': data['createAt'] ?? '',
          });
        }
      }

      setState(() {
        deliveredList = tempOrder;
        _isLoading = false;
      });
    } catch (e) {
      log('Error fetching delivered orders: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (deliveredList.isEmpty) {
      return const Center(child: Text('ยังไม่มีรายการที่จัดส่งสำเร็จ'));
    }

    return ListView.builder(
      itemCount: deliveredList.length,
      itemBuilder: (context, index) {
        final order = deliveredList[index];
        final items = (order['item'] is List)
            ? order['item'] as List<dynamic>
            : <dynamic>[];

        if (items.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: items.map<Widget>((item) {
              return ProductHistoryCard(
                imageUrl: item['imageUrl'] ?? '',
                productDetial: item['detail'] ?? 'ไม่ระบุรายละเอียดสินค้า',
                senderName: order['sender_name'] ?? 'ไม่ระบุชื่อ',
                senderAddress: order['sender_address'] ?? 'ไม่ระบุที่อยู่',
                senderPhone: order['sender_phone'] ?? 'ไม่ระบุเบอร์โทรศัพท์',
                riderName: order['rider_name'] ?? 'ไม่ระบุชื่อ',
                riderPhone: order['rider_phone'] ?? 'ไม่ระบุเบอร์โทรศัพท์',
                status: order['status'] ?? '',
                createAt: order['createAt'] ?? '',
                uid: widget.uid,
                rid: (order['rider_id'] ?? '')
                    .toString(), // ✅ ส่ง rider_id ที่ถูกต้อง
                oid: (order['order_id'] ?? '')
                    .toString(), // ✅ ส่ง order_id ที่ถูกต้อง
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

//-------------------------------------------------------
// ✅ หน้าสินค้าที่ส่ง: แสดงออเดอร์ที่คุณเป็น "ผู้ส่ง" (แม้ไรเดอร์ยังไม่รับงาน)
class SentTab extends StatefulWidget {
  final String uid;
  const SentTab({super.key, required this.uid});

  @override
  State<SentTab> createState() => _SentTabState();
}

class _SentTabState extends State<SentTab> {
  bool _loading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchSentOrders();
  }

  Future<void> _fetchSentOrders() async {
    try {
      // NOTE: ถ้าต้องการ "ของที่เราส่ง" จริง ๆ ควร where ด้วย sender_id ไม่ใช่ receiver
      final snap = await FirebaseFirestore.instance
          .collection('orders')
          .where('sender_id', isEqualTo: widget.uid) // ✅ แก้ key ให้ถูก
          .get();

      final temp = <Map<String, dynamic>>[];

      for (final doc in snap.docs) {
        final data = doc.data();

        final senderDoc = await safeGetDoc('users', data['sender_id']);
        final riderId = (data['rider_id'] ?? '').toString();
        DocumentSnapshot? riderDoc;
        if (riderId.isNotEmpty) {
          riderDoc = await safeGetDoc('riders', riderId);
        }

        temp.add({
          'order_id': doc.id,
          'item': data['items'] ?? [],
          'sender_name': senderDoc != null && senderDoc.exists
              ? (senderDoc['fullname'] ?? '').toString()
              : '',
          'sender_phone': senderDoc != null && senderDoc.exists
              ? (senderDoc['phone'] ?? '').toString()
              : '',
          'sender_address': (data['sender_address'] ?? '').toString(),
          'rider_id': riderId,
          'rider_name': riderDoc != null && riderDoc.exists
              ? (riderDoc['fullname'] ?? '').toString()
              : '',
          'rider_phone': riderDoc != null && riderDoc.exists
              ? (riderDoc['phone'] ?? '').toString()
              : '',
          'status': (data['status'] ?? '').toString(),
          'createAt': data['createAt'],
        });
      }

      setState(() {
        _orders = temp;
        _loading = false;
      });
    } catch (e) {
      log('Error fetch sent orders: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_orders.isEmpty) {
      return const Center(child: Text('ยังไม่มีสินค้าที่คุณส่ง'));
    }

    return ListView.builder(
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final items = (order['item'] is List)
            ? order['item'] as List<dynamic>
            : <dynamic>[];

        if (items.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: items.map<Widget>((it) {
              return ProductHistoryCard(
                imageUrl: (it['imageUrl'] ?? '').toString(),
                productDetial: (it['detail'] ?? 'ไม่ระบุรายละเอียดสินค้า')
                    .toString(),
                senderName: (order['sender_name'] ?? '').toString(),
                senderAddress: (order['sender_address'] ?? '').toString(),
                senderPhone: (order['sender_phone'] ?? '-').toString(),
                riderName: (order['rider_name'] ?? '').toString(),
                riderPhone: (order['rider_phone'] ?? '-').toString(),
                status: (order['status'] ?? '').toString(),
                createAt: order['createAt'],
                uid: widget.uid,
                rid: (order['rider_id'] ?? '').toString(),
                oid: (order['order_id'] ?? '').toString(),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
