import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:blink_delivery_project/pages/receiving_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
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
  File? _imageFile; // (reserved)
  final ImagePicker _picker = ImagePicker();

  late List<Widget> _pages;

  // THEME
  static const Color kPrimary = Color(0xFFFF3B30);
  static const BorderRadius kRadius = BorderRadius.all(Radius.circular(18));

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      InTransitTab(uid: widget.uid, rid: widget.rid, oid: widget.oid),
      MapReceive(uid: widget.uid, rid: widget.rid),
      ReceivedTab(uid: widget.uid, rid: widget.rid),
      SentTab(uid: widget.uid),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // << ปิดลูกศรย้อนกลับ

        backgroundColor: kPrimary,
        elevation: 0,
        title: const Text(
          'รายการสินค้าของคุณ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(color: kPrimary),
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF6F7F9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _TabsBar(
                    index: _selectedIndex,
                    onChanged: (i) => setState(() => _selectedIndex = i),
                    items: const [
                      _TabItem(
                        'สินค้ากำลังมาส่ง',
                        Icons.local_shipping_outlined,
                      ),
                      _TabItem('ไรเดอร์ทั้งหมด', Icons.map_outlined),
                      _TabItem(
                        'สินค้าที่เคยได้รับ',
                        Icons.inventory_2_outlined,
                      ),
                      // _TabItem('ที่คุณส่ง', Icons.outbox_outlined),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _pages[_selectedIndex],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------- Product List Card ----------------------------
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

  Color get statusColor => status.contains('แล้ว')
      ? Colors.green
      : (status.contains('รอ') ? const Color(0xFFFFA000) : Colors.blueGrey);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.8,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: _OrderlistPageState.kRadius),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.network(
                    imageUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productDetial,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: statusColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'สถานะ: $status',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: statusColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            _InfoRow(
              icon: Icons.store_mall_directory_outlined,
              title: 'ผู้ส่ง',
              lines: [senderName, senderAddress, 'โทร: $senderPhone'],
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.pedal_bike_outlined,
              title: 'ไรเดอร์',
              lines: [
                riderName.isNotEmpty ? riderName : '-',
                'โทร: ${riderPhone.isNotEmpty ? riderPhone : '-'}',
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ReceivingStatus(uid: uid, rid: rid, oid: oid),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.receipt_long,
                  color: _OrderlistPageState.kPrimary,
                ),
                label: const Text('รายละเอียด'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _OrderlistPageState.kPrimary,
                  side: const BorderSide(
                    color: _OrderlistPageState.kPrimary,
                    width: 1.8,
                  ),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> lines;
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              ...lines.map(
                (t) => Text(t, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ---------------------------- Tabs ----------------------------
class _TabItem {
  final String label;
  final IconData icon;
  const _TabItem(this.label, this.icon);
}

class _TabsBar extends StatelessWidget {
  final int index;
  final void Function(int) onChanged;
  final List<_TabItem> items;
  const _TabsBar({
    required this.index,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final selected = i == index;
          return Material(
            color: selected ? _OrderlistPageState.kPrimary : Colors.white,
            elevation: selected ? 2 : 0,
            borderRadius: _OrderlistPageState.kRadius,
            child: InkWell(
              onTap: () => onChanged(i),
              borderRadius: _OrderlistPageState.kRadius,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      items[i].icon,
                      size: 18,
                      color: selected
                          ? Colors.white
                          : _OrderlistPageState.kPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      items[i].label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : _OrderlistPageState.kPrimary,
                      ),
                    ),
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

/// ---------------------------- IN TRANSIT ----------------------------
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: productReceivedList.length,
      itemBuilder: (context, index) {
        final order = productReceivedList[index];
        final items = (order['item'] is List)
            ? order['item'] as List<dynamic>
            : <dynamic>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
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
        );
      },
    );
  }
}

/// ---------------------------- MAP/RECEIVE ----------------------------
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

  Future<DocumentSnapshot?> safeGetDoc(String collection, String? id) async {
    if (id == null || id.isEmpty) return null;
    return FirebaseFirestore.instance.collection(collection).doc(id).get();
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
          initialChildSize: 0.66,
          minChildSize: 0.44,
          maxChildSize: 0.92,
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
                      const Icon(
                        Icons.assignment,
                        color: _OrderlistPageState.kPrimary,
                      ),
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
                            color: _OrderlistPageState.kPrimary,
                          ),
                          label: const Text('รายละเอียด'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _OrderlistPageState.kPrimary,
                            side: const BorderSide(
                              color: _OrderlistPageState.kPrimary,
                              width: 2,
                            ),
                            shape: const StadiumBorder(),
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
                  color: _OrderlistPageState.kPrimary,
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
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: _OrderlistPageState.kRadius,
            ),
            child: ClipRRect(
              borderRadius: _OrderlistPageState.kRadius,
              child: SizedBox(
                height: 320,
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

/// ---------------------------- RECEIVED ----------------------------
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
            'rider_id': data['rider_id'] ?? '',
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
    if (deliveredList.isEmpty)
      return const Center(child: Text('ยังไม่มีรายการที่จัดส่งสำเร็จ'));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: deliveredList.length,
      itemBuilder: (context, index) {
        final order = deliveredList[index];
        final items = (order['item'] is List)
            ? order['item'] as List<dynamic>
            : <dynamic>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
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
              rid: (order['rider_id'] ?? '').toString(),
              oid: (order['order_id'] ?? '').toString(),
            );
          }).toList(),
        );
      },
    );
  }
}

/// ---------------------------- SENT ----------------------------
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
      final snap = await FirebaseFirestore.instance
          .collection('orders')
          .where('sender_id', isEqualTo: widget.uid)
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
    if (_orders.isEmpty)
      return const Center(child: Text('ยังไม่มีสินค้าที่คุณส่ง'));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final items = (order['item'] is List)
            ? order['item'] as List<dynamic>
            : <dynamic>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
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
        );
      },
    );
  }
}

// helper used above
Future<DocumentSnapshot?> safeGetDoc(String collection, String? id) async {
  if (id == null || id.isEmpty) return null;
  return FirebaseFirestore.instance.collection(collection).doc(id).get();
}
