import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SendingStatus extends StatelessWidget {
  final Map<String, dynamic> orderData;
  const SendingStatus({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    final orderId = (orderData['order_id'] ?? '').toString().trim();

    if (orderId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('สถานะการจัดส่ง'),
          backgroundColor: const Color(0xffff3b30),
        ),
        body: const Center(child: Text('ไม่พบหมายเลขออเดอร์')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffff3b30),
      appBar: AppBar(
        backgroundColor: const Color(0xffff3b30),
        iconTheme: const IconThemeData(color: Colors.white),
        // title: const Text(
        //   'สถานะการจัดส่ง',
        //   style: TextStyle(color: Colors.white),
        // ),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(
              child: Text(
                'ไม่พบข้อมูลคำสั่งซื้อ',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final data = snap.data!.data()!;

          // สถานะ
          final status = (data['status'] ?? '').toString();
          final imagePickup = (data['image_pickup'] ?? '').toString();
          final imageDelivered = (data['image_delivered'] ?? '').toString();

          // ที่อยู่
          final senderAddress = (data['sender_address'] ?? '').toString();
          final receiverAddress = (data['receiver_address'] ?? '').toString();

          // เวลา (อาจไม่มี)
          final createdAt = data['createAt'];
          final riderAccept = data['rider_accept_time'];
          final deliveredAt = data['delivered_at'];
          final canceledAt = data['canceled_at'];

          // พิกัด (รองรับทั้ง number และ string)
          final riderLat = _toDouble(data['rider_latitude']);
          final riderLng = _toDouble(data['rider_longitude']);
          final senderLat = _toDouble(data['sender_latitude']);
          final senderLng = _toDouble(data['sender_longitude']);
          final recvLat = _toDouble(data['receiver_latitude']);
          final recvLng = _toDouble(data['receiver_longitude']);

          final rider = (riderLat != null && riderLng != null)
              ? LatLng(riderLat, riderLng)
              : null;
          final pickup = (senderLat != null && senderLng != null)
              ? LatLng(senderLat, senderLng)
              : null;
          final recv = (recvLat != null && recvLng != null)
              ? LatLng(recvLat, recvLng)
              : null;

          final step = resolveStepFromStatus(
            status,
            hasPickup: imagePickup.isNotEmpty,
            hasDelivered: imageDelivered.isNotEmpty,
          );
          final displayStatus = status.trim().isNotEmpty
              ? _normalizeTH(status)
              : (stepLabels[step] ?? 'กำลังประมวลผล');

          return Stack(
            children: [
              // พื้นหลัง/หัวข้อด้านบน (แดง)
              Column(
                children: [
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      "ติดตามสถานะ",
                      style: TextStyle(
                        color: Color(0xffffffff),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // พื้นที่เนื้อหาสีขาวโค้งมนด้านบน
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xffffffff),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                        children: [
                          // หัวข้อ "สถานะล่าสุด"
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ออเดอร์: $orderId',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.flag_circle,
                                        color: Color(0xffff3b30),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          displayStatus,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (canceledAt != null)
                                    _chip('ยกเลิกแล้ว', Colors.grey.shade800),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // แผนที่ (สไตล์เดียวกับหน้าเพิ่มที่อยู่) — แสดงตั้งแต่ step 2
                          if (step >= 2)
                            _MapCard(rider: rider, pickup: pickup, recv: recv),

                          const SizedBox(height: 16),

                          // ไทม์ไลน์
                          _StatusTimeline(
                            currentStep: step,
                            createdAt: createdAt,
                            riderAccept: riderAccept,
                            deliveredAt: deliveredAt,
                          ),

                          const SizedBox(height: 16),

                          // รูปภาพหลักฐาน
                          if (imagePickup.isNotEmpty ||
                              imageDelivered.isNotEmpty)
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'รูปภาพ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (imagePickup.isNotEmpty) ...[
                                      const Text('ตอนรับสินค้า'),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imagePickup,
                                          height: 160,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (imageDelivered.isNotEmpty) ...[
                                      const Text('ตอนส่งมอบ'),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imageDelivered,
                                          height: 160,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // ที่อยู่
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ที่อยู่',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _addrRow('ผู้ส่ง', senderAddress),
                                  const Divider(height: 20),
                                  _addrRow('ผู้รับ', receiverAddress),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ---------- แผนที่ Thunderforest (สไตล์เหมือนหน้าเพิ่มที่อยู่) ----------
class _MapCard extends StatefulWidget {
  final LatLng? rider;
  final LatLng? pickup;
  final LatLng? recv;
  const _MapCard({
    required this.rider,
    required this.pickup,
    required this.recv,
  });

  @override
  State<_MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<_MapCard> {
  final MapController mapController = MapController();

  // ปรับซูม/ขอบให้เหมาะ
  static const double _kMinZoom = 15; // ไม่ให้ไกลเกินนี้
  static const double _kInitZoom = 16; // มีจุดเดียว → โฟกัสใกล้ ๆ
  static const double _kMaxZoom = 22;
  static const double _kFitPadding = 20;

  // Thunderforest (เหมือนตัวอย่างคุณ)
  static const String _tfStyle = 'atlas';
  static const String _apiKey = 'd7b6821f750e49e2864ef759ef2223ec';

  @override
  Widget build(BuildContext context) {
    final center =
        widget.rider ??
        widget.recv ??
        widget.pickup ??
        const LatLng(16.243998, 103.249047);

    // markers
    final markers = <Marker>[
      if (widget.pickup != null)
        Marker(
          point: widget.pickup!,
          width: 40,
          height: 40,
          child: const Icon(Icons.store, color: Colors.green, size: 38),
        ),
      if (widget.recv != null)
        Marker(
          point: widget.recv!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
        ),
      if (widget.rider != null)
        Marker(
          point: widget.rider!,
          width: 40,
          height: 40,
          child: const Icon(Icons.pedal_bike, color: Colors.red, size: 40),
        ),
    ];

    // รวมจุดไว้ fit กล้อง
    final points = <LatLng>[
      if (widget.rider != null) widget.rider!,
      if (widget.pickup != null) widget.pickup!,
      if (widget.recv != null) widget.recv!,
    ];

    // จัดกล้องหลัง build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (points.length >= 2) {
        final bounds = LatLngBounds.fromPoints(points);
        mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(_kFitPadding),
          ),
        );
        // ถ้าซูมยังไกลไป ให้ดันเข้าอย่างน้อย _kMinZoom
        final z = mapController.camera.zoom;
        if (z < _kMinZoom) {
          mapController.move(mapController.camera.center, _kMinZoom);
        }
      } else {
        mapController.move(center, _kInitZoom);
      }
    });

    // UI เหมือนหน้าเพิ่มที่อยู่: กรอบโค้งมน + เส้นขอบแดง
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // หัว "ตำแหน่งบนแผนที่"
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            "ตำแหน่งบนแผนที่",
            style: TextStyle(
              color: Color(0xffff3b30),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        Container(
          height: MediaQuery.of(context).size.height * 0.5,
          width: MediaQuery.of(context).size.width * 0.96,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xffff3b30), width: 3),
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: _kInitZoom,
                minZoom: _kMinZoom,
                maxZoom: _kMaxZoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  // อยากปิดหมุนแผนที่ก็ไม่ใส่ InteractiveFlag.rotate
                  // ตัวเลือกอื่น ๆ: doubleTapZoom, pinchMove, flingAnimation ฯลฯ
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.thunderforest.com/$_tfStyle/{z}/{x}/{y}.png?apikey=$_apiKey',
                  userAgentPackageName:
                      'com.blink.delivery', // เปลี่ยนเป็นแพ็กเกจจริงของคุณ
                  maxNativeZoom: 22,
                  maxZoom: _kMaxZoom,
                ),
                if (markers.isNotEmpty) MarkerLayer(markers: markers),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                    TextSourceAttribution('Tiles © Thunderforest'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// ---------- Helpers ----------
double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

/// 4 ข้อความสถานะหลัก
const stepLabels = <int, String>{
  0: 'รอไรเดอร์รับสินค้า',
  1: 'ไรเดอร์รับงานแล้ว (กำลังเดินทางไปรับสินค้า)',
  2: 'ไรเดอร์รับสินค้าแล้ว (กำลังเดินทางไปส่ง)',
  3: 'ไรเดอร์นำส่งสินค้าแล้ว',
};

String _normalizeTH(String s) => s
    .replaceAll('\n', ' ')
    .replaceAll('คุณส่ง', '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

int resolveStepFromStatus(
  String rawStatus, {
  bool hasPickup = false,
  bool hasDelivered = false,
}) {
  final s = _normalizeTH(rawStatus);
  if (hasDelivered ||
      s.startsWith('ไรเดอร์นำส่งสินค้าแล้ว') ||
      s.contains('นำส่งสินค้า'))
    return 3;
  if (s.startsWith('ไรเดอร์รับสินค้าแล้ว') || s.contains('รับสินค้าแล้ว'))
    return 2;
  if (s.startsWith('ไรเดอร์รับงานแล้ว') ||
      s.contains('รับงานแล้ว') ||
      hasPickup)
    return 1;
  if (s.startsWith('รอไรเดอร์รับสินค้า')) return 0;
  return 0;
}

Widget _chip(String text, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: color.withOpacity(.08),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text(
    text,
    style: TextStyle(color: color, fontWeight: FontWeight.w600),
  ),
);

Widget _addrRow(String label, String value) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    SizedBox(
      width: 60,
      child: Text(
        '$label:',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    Expanded(child: Text(value.isNotEmpty ? value : '-')),
  ],
);

/// ---------- Timeline ----------
class _StatusTimeline extends StatelessWidget {
  final int currentStep; // 0..3
  final dynamic createdAt, riderAccept, deliveredAt; // Timestamp/null
  const _StatusTimeline({
    required this.currentStep,
    this.createdAt,
    this.riderAccept,
    this.deliveredAt,
  });

  String _fmt(dynamic ts) {
    if (ts is Timestamp) {
      final dt = ts.toDate();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _TimelineItem(
        title: stepLabels[0]!,
        subtitle: _fmt(createdAt),
        done: currentStep >= 0,
        icon: Icons.receipt_long,
      ),
      _TimelineItem(
        title: stepLabels[1]!,
        subtitle: _fmt(riderAccept),
        done: currentStep >= 1,
        icon: Icons.upload,
      ),
      _TimelineItem(
        title: stepLabels[2]!,
        subtitle: '',
        done: currentStep >= 2,
        icon: Icons.motorcycle,
      ),
      _TimelineItem(
        title: stepLabels[3]!,
        subtitle: _fmt(deliveredAt),
        done: currentStep >= 3,
        icon: Icons.check_circle,
      ),
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items.asMap().entries.map((e) {
            final i = e.key, item = e.value;
            return _TimelineTile(
              item: item,
              showConnectorTop: i != 0,
              showConnectorBottom: i != items.length - 1,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TimelineItem {
  final String title;
  final String subtitle;
  final bool done;
  final IconData icon;
  _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.icon,
  });
}

class _TimelineTile extends StatelessWidget {
  final _TimelineItem item;
  final bool showConnectorTop;
  final bool showConnectorBottom;
  const _TimelineTile({
    required this.item,
    required this.showConnectorTop,
    required this.showConnectorBottom,
  });

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: item.done ? Colors.green : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Icon(
        item.icon,
        size: 16,
        color: item.done ? Colors.white : Colors.grey[700],
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (showConnectorTop)
              Container(width: 2, height: 16, color: Colors.grey[300]),
            dot,
            if (showConnectorBottom)
              Container(width: 2, height: 16, color: Colors.grey[300]),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (item.subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
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
