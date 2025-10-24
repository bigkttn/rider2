import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

/// ----------------------------- Helpers -----------------------------
double? _toD(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim());
  if (v is GeoPoint) return null;
  return null;
}

LatLng? _latLngFromOrderFlexible(
  Map<String, dynamic> m, {
  required bool isSender,
}) {
  final latKeys = isSender
      ? ['sender_latitude', 'sender_lat', 's_lat', 'from_lat']
      : ['receiver_latitude', 'receiver_lat', 'r_lat', 'to_lat'];
  final lngKeys = isSender
      ? [
          'sender_longitude',
          'sender_lng',
          'sender_longtitude',
          's_lng',
          'from_lng',
          'sender_long',
        ]
      : [
          'receiver_longitude',
          'receiver_lng',
          'r_lng',
          'to_lng',
          'receiver_long',
        ];
  final geoPointKeys = isSender
      ? ['sender_geo', 'sender_geopoint', 'from_geo']
      : ['receiver_geo', 'receiver_geopoint', 'to_geo'];

  for (final k in geoPointKeys) {
    final v = m[k];
    if (v is GeoPoint) return LatLng(v.latitude, v.longitude);
  }

  double? lat, lng;
  for (final k in latKeys) {
    if (m.containsKey(k)) {
      lat = _toD(m[k]);
      if (lat != null) break;
    }
  }
  for (final k in lngKeys) {
    if (m.containsKey(k)) {
      lng = _toD(m[k]);
      if (lng != null) break;
    }
  }

  if (lat != null && (lat.abs() > 90) && lng != null && (lng.abs() <= 90)) {
    final tmp = lat;
    lat = lng;
    lng = tmp;
  }
  if (lng != null && (lng.abs() > 180) && lat != null && (lat.abs() <= 180)) {
    final tmp = lat;
    lat = lng;
    lng = tmp;
  }
  if (lat == null || lng == null) return null;
  return LatLng(lat, lng);
}

double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371000.0;
  final dLat = (lat2 - lat1) * (pi / 180.0);
  final dLon = (lon2 - lon1) * (pi / 180.0);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * (pi / 180.0)) *
          cos(lat2 * (pi / 180.0)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

/// --------------------------- Ridertopage ---------------------------
class Ridertopage extends StatefulWidget {
  final String uid;
  const Ridertopage({super.key, required this.uid});

  @override
  State<Ridertopage> createState() => _RidertopageState();
}

class _RidertopageState extends State<Ridertopage> {
  // Cloudinary
  static const _cloudName = "dywfdy174";
  static const _uploadPreset = "flutter_upload";

  // Thunderforest tiles
  static const _tfUrl =
      'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=d7b6821f750e49e2864ef759ef2223ec';

  // รูป
  File? pickupImage;
  File? deliveredImage;

  // ระยะ
  double? distanceToPickup;
  double? distanceToReceiver;

  // พิกัด
  LatLng? riderPos;
  LatLng? pickupPos; // sender
  LatLng? receiverPos; // receiver

  // งานปัจจุบัน
  Map<String, dynamic>? currentOrder;
  bool _isFinished = false;

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _posSub;

  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle) {
      setState(fn);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(fn);
      });
    }
  }

  void _afterBuild(VoidCallback fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) fn();
    });
  }

  @override
  void initState() {
    super.initState();
    _ensureLocationPermissionAndStream();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  // ---------------------- Fit camera helpers ----------------------
  void _fitToPoints(
    List<LatLng> points, {
    double padding = 36,
    double maxZoom = 18,
    double? fallbackZoom,
  }) {
    if (!mounted || points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, fallbackZoom ?? 16);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: EdgeInsets.all(padding),
        maxZoom: maxZoom,
      ),
    );
  }

  void _refitMapByStatus() {
    final status = (currentOrder?['status'] ?? '').toString();
    if (status.contains('ไปรับสินค้า')) {
      _fitToPoints([
        if (riderPos != null) riderPos!,
        if (pickupPos != null) pickupPos!,
      ], fallbackZoom: 16);
    } else if (status.contains('ไปส่ง') || status.contains('นำส่ง')) {
      _fitToPoints([
        if (riderPos != null) riderPos!,
        if (receiverPos != null) receiverPos!,
      ], fallbackZoom: 16);
    } else if (riderPos != null) {
      _fitToPoints([riderPos!], fallbackZoom: 15);
    } else {
      _mapController.move(const LatLng(15.870031, 100.992541), 14);
    }
  }

  // -------------------------- Location stream --------------------------
  Future<void> _ensureLocationPermissionAndStream() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      await _posSub?.cancel();
      _posSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen((pos) async {
            riderPos = LatLng(pos.latitude, pos.longitude);

            distanceToPickup = (pickupPos == null)
                ? null
                : Geolocator.distanceBetween(
                    pos.latitude,
                    pos.longitude,
                    pickupPos!.latitude,
                    pickupPos!.longitude,
                  );
            distanceToReceiver = (receiverPos == null)
                ? null
                : Geolocator.distanceBetween(
                    pos.latitude,
                    pos.longitude,
                    receiverPos!.latitude,
                    receiverPos!.longitude,
                  );

            if (!_isFinished && currentOrder != null) {
              safeSetState(() {});
              _afterBuild(_refitMapByStatus);

              if ((currentOrder!['status'] ?? '') != 'ไรเดอร์นำส่งสินค้าแล้ว') {
                await _pushRiderLocationToFirestore(
                  pos.latitude,
                  pos.longitude,
                );
              }
            }
          });
    } catch (e) {
      log('Error starting location stream: $e');
    }
  }

  Future<void> _pushRiderLocationToFirestore(double lat, double lng) async {
    try {
      await FirebaseFirestore.instance
          .collection('riders')
          .doc(widget.uid)
          .update({
            'latitude': lat,
            'longitude': lng,
            'last_update': FieldValue.serverTimestamp(),
          });

      if (currentOrder != null && currentOrder!['order_id'] != null) {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(currentOrder!['order_id'])
            .update({
              'rider_latitude': lat,
              'rider_longitude': lng,
              'rider_last_update': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      log('Error updating location: $e');
    }
  }

  // ----------------------------- Upload -----------------------------
  Future<String?> _uploadToCloudinary(File image) async {
    try {
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
      );
      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        final resData = jsonDecode(await response.stream.bytesToString());
        return resData['secure_url'];
      }
      return null;
    } catch (e) {
      log('❌ Upload Error: $e');
      return null;
    }
  }

  Future<void> _captureAndUploadImage(bool isPickup) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    final file = File(image.path);
    final url = await _uploadToCloudinary(file);
    if (url == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ อัปโหลดรูปไม่สำเร็จ')));
      return;
    }
    if (currentOrder == null || currentOrder!['order_id'] == null) return;

    if (isPickup) {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(currentOrder!['order_id'])
          .update({
            'image_pickup': url,
            'status': 'ไรเดอร์รับสินค้าแล้ว (กำลังเดินทางไปส่ง)',
          });
      safeSetState(() {
        pickupImage = file;
        currentOrder?['status'] = 'ไรเดอร์รับสินค้าแล้ว (กำลังเดินทางไปส่ง)';
        currentOrder?['image_pickup'] = url;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ รับสินค้าเรียบร้อย กำลังไปส่ง')),
      );
      _afterBuild(_refitMapByStatus);
    } else {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(currentOrder!['order_id'])
          .update({
            'image_delivered': url,
            'status': 'ไรเดอร์นำส่งสินค้าแล้ว',
            'delivered_at': FieldValue.serverTimestamp(),
          });
      _isFinished = true;

      await FirebaseFirestore.instance
          .collection('riders')
          .doc(widget.uid)
          .update({
            'latitude': FieldValue.delete(),
            'longitude': FieldValue.delete(),
            'last_update': FieldValue.serverTimestamp(),
          });

      safeSetState(() {
        deliveredImage = file;
        currentOrder?['status'] = 'ไรเดอร์นำส่งสินค้าแล้ว';
        currentOrder?['image_delivered'] = url;
        pickupPos = null;
        receiverPos = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ ส่งสินค้าเรียบร้อยแล้ว 🎉')),
      );
      _afterBuild(_refitMapByStatus);
    }
  }

  // ------------------------- Order handling -------------------------
  Future<void> _fetchAddresses(Map<String, dynamic> order) async {
    try {
      pickupPos = _latLngFromOrderFlexible(order, isSender: true);
      receiverPos = _latLngFromOrderFlexible(order, isSender: false);

      if (riderPos != null) {
        distanceToPickup = (pickupPos == null)
            ? null
            : Geolocator.distanceBetween(
                riderPos!.latitude,
                riderPos!.longitude,
                pickupPos!.latitude,
                pickupPos!.longitude,
              );
        distanceToReceiver = (receiverPos == null)
            ? null
            : Geolocator.distanceBetween(
                riderPos!.latitude,
                riderPos!.longitude,
                receiverPos!.latitude,
                receiverPos!.longitude,
              );
      }

      safeSetState(() {});
    } catch (e) {
      log('❌ _fetchAddresses error: $e');
    }
  }

  Future<void> _onNewActiveOrder(Map<String, dynamic> ord) async {
    currentOrder = ord;
    _isFinished = false;

    await _fetchAddresses(ord);

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      riderPos = LatLng(pos.latitude, pos.longitude);

      distanceToPickup = (pickupPos == null)
          ? null
          : Geolocator.distanceBetween(
              pos.latitude,
              pos.longitude,
              pickupPos!.latitude,
              pickupPos!.longitude,
            );
      distanceToReceiver = (receiverPos == null)
          ? null
          : Geolocator.distanceBetween(
              pos.latitude,
              pos.longitude,
              receiverPos!.latitude,
              receiverPos!.longitude,
            );

      await _pushRiderLocationToFirestore(pos.latitude, pos.longitude);
      _afterBuild(_refitMapByStatus);
    } catch (e) {
      log('getCurrentPosition error: $e');
    }

    safeSetState(() {});
  }

  void _onNoOrder() {
    if (currentOrder == null &&
        pickupPos == null &&
        receiverPos == null &&
        distanceToPickup == null &&
        distanceToReceiver == null)
      return;

    currentOrder = null;
    pickupPos = null;
    receiverPos = null;
    distanceToPickup = null;
    distanceToReceiver = null;
    safeSetState(() {});
    _afterBuild(_refitMapByStatus);
  }

  // -------------------------- Bottom Sheet --------------------------
  void _openJobSheet() {
    if (currentOrder == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ยังไม่มีงานที่ต้องจัดส่ง')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final status = (currentOrder?['status'] ?? '').toString();
        final canPickup = (distanceToPickup ?? double.infinity) <= 20;
        final canDeliver = (distanceToReceiver ?? double.infinity) <= 20;

        return DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) => SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Text(
                  'รายละเอียดงาน',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('สถานะ: $status'),
                if (distanceToPickup != null)
                  Text(
                    "ระยะจากจุดรับสินค้า: ${distanceToPickup!.toStringAsFixed(1)} ม.",
                    style: TextStyle(
                      color: canPickup ? Colors.green : Colors.red,
                    ),
                  ),
                if (distanceToReceiver != null)
                  Text(
                    "ระยะจากจุดส่งสินค้า: ${distanceToReceiver!.toStringAsFixed(1)} ม.",
                    style: TextStyle(
                      color: canDeliver ? Colors.green : Colors.red,
                    ),
                  ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: status.contains('ไปรับสินค้า') && canPickup
                      ? () async {
                          Navigator.pop(context);
                          await _captureAndUploadImage(true);
                        }
                      : null,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("ถ่ายรูป รับสินค้า"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: canPickup
                        ? const Color(0xFFFF3B30)
                        : Colors.grey,
                  ),
                ),
                if (pickupImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Image.file(
                      pickupImage!,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: status.contains('ไปส่ง') && canDeliver
                      ? () async {
                          Navigator.pop(context);
                          await _captureAndUploadImage(false);
                        }
                      : null,
                  icon: const Icon(Icons.camera),
                  label: const Text("ถ่ายรูป ส่งสินค้า"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: canDeliver ? Colors.green : Colors.grey,
                  ),
                ),
                if (deliveredImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Image.file(
                      deliveredImage!,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('ยืนยันการยกเลิกการส่ง'),
                        content: const Text(
                          'คุณต้องการยกเลิกการส่งสินค้านี้ใช่หรือไม่?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('ไม่'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('ใช่'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && currentOrder != null) {
                      try {
                        final orderId = currentOrder!['order_id'];
                        await FirebaseFirestore.instance
                            .collection('orders')
                            .doc(orderId)
                            .update({
                              'status': 'รอไรเดอร์รับสินค้า',
                              'rider_id': '',
                              'rider_latitude': FieldValue.delete(),
                              'rider_longitude': FieldValue.delete(),
                              'rider_last_update': FieldValue.serverTimestamp(),
                              'canceled_at': FieldValue.serverTimestamp(),
                              'image_pickup': FieldValue.delete(),
                              'image_delivered': FieldValue.delete(),
                            });
                        await FirebaseFirestore.instance
                            .collection('riders')
                            .doc(widget.uid)
                            .update({
                              'latitude': FieldValue.delete(),
                              'longitude': FieldValue.delete(),
                              'last_update': FieldValue.serverTimestamp(),
                            });
                        safeSetState(() {
                          pickupImage = null;
                          deliveredImage = null;
                        });
                        Navigator.pop(context);
                        _afterBuild(_onNoOrder);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '🚫 ยกเลิกการส่งสำเร็จ — งานกลับไปรอรับใหม่',
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('เกิดข้อผิดพลาดในการยกเลิก'),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text("ยกเลิกการส่งสินค้า"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: const Color.fromARGB(255, 255, 0, 0),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------ UI ------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // ให้แผนที่อยู่ใต้ AppBar -> เต็มจอจริง ๆ
      appBar: AppBar(
        automaticallyImplyLeading: false, // << ปิดลูกศรย้อนกลับ

        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("จัดการการส่งสินค้า"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('rider_id', isEqualTo: widget.uid)
            .where(
              'status',
              whereIn: [
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
            if (currentOrder != null ||
                pickupPos != null ||
                receiverPos != null ||
                distanceToPickup != null ||
                distanceToReceiver != null) {
              _afterBuild(_onNoOrder);
            }

            // ===== แผนที่เต็มจอ (ไม่มีงาน) =====
            return Stack(
              children: [
                Positioned.fill(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter:
                          riderPos ?? const LatLng(15.870031, 100.992541),
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _tfUrl,
                        userAgentPackageName: 'com.example.rider_app',
                        maxNativeZoom: 22,
                      ),
                      if (riderPos != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: riderPos!,
                              width: 60,
                              height: 60,
                              child: const Icon(
                                Icons.pedal_bike,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // ปุ่มลอย
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24 + MediaQuery.of(context).padding.bottom,
                  child: FloatingActionButton.extended(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ยังไม่มีงานที่ต้องจัดส่ง')),
                    ),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('รายละเอียดงาน'),
                    backgroundColor: Colors.grey,
                  ),
                ),
              ],
            );
          }

          // ===== มีงาน =====
          final firstDoc = snapshot.data!.docs.first;
          final data = {
            ...(firstDoc.data() as Map<String, dynamic>),
            'order_id': firstDoc.id,
          };

          if (currentOrder == null ||
              currentOrder!['order_id'] != data['order_id'] ||
              currentOrder!['status'] != data['status']) {
            _afterBuild(() => _onNewActiveOrder(data));
          }

          final status = (currentOrder?['status'] ?? data['status'] ?? '')
              .toString();

          return Stack(
            children: [
              // แผนที่ “เต็มจอ”
              Positioned.fill(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        pickupPos ??
                        riderPos ??
                        const LatLng(15.870031, 100.992541),
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _tfUrl,
                      userAgentPackageName: 'com.example.rider_app',
                      maxNativeZoom: 22,
                    ),
                    MarkerLayer(
                      markers: [
                        if (pickupPos != null)
                          Marker(
                            point: pickupPos!,
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.store,
                              color: Colors.green,
                              size: 40,
                            ),
                          ),
                        if (receiverPos != null)
                          Marker(
                            point: receiverPos!,
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                        if (riderPos != null && !_isFinished)
                          Marker(
                            point: riderPos!,
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.pedal_bike,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Gradient บังด้านบนให้อ่านข้อความบน AppBar ชัด
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: IgnorePointer(
                  child: Container(
                    height: kToolbarHeight + MediaQuery.of(context).padding.top,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black38, Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),

              // ปุ่มลอยด้านล่าง
              Positioned(
                left: 16,
                right: 16,
                bottom: 24 + MediaQuery.of(context).padding.bottom,
                child: FloatingActionButton.extended(
                  onPressed: _openJobSheet,
                  icon: const Icon(Icons.tune),
                  label: Text(status.isEmpty ? 'รายละเอียดงาน' : status),
                  backgroundColor: const Color(0xFFFF3B30),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// พรีวิวก่อนรับงาน (ยังคงใช้ tiles เดียวกัน)
  Future<void> _showPreviewMap(
    BuildContext context,
    String orderId,
    Map<String, dynamic> order,
  ) async {
    final s = _latLngFromOrderFlexible(order, isSender: true);
    final r = _latLngFromOrderFlexible(order, isSender: false);

    if (s == null || r == null) {
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
        if (perm == LocationPermission.denied)
          perm = await Geolocator.requestPermission();
        if (perm != LocationPermission.denied &&
            perm != LocationPermission.deniedForever) {
          myPos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
          );
        }
      }
    } catch (_) {}

    final approxMeters = _haversineMeters(
      s.latitude,
      s.longitude,
      r.latitude,
      r.longitude,
    );

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
          s,
          r,
          if (myPos != null) LatLng(myPos!.latitude, myPos!.longitude),
        ];

        final map = SizedBox(
          height: 320,
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: s,
              initialZoom: 14,
              onMapReady: () {
                if (points.length >= 2) {
                  mapController.fitCamera(
                    CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(points),
                      padding: const EdgeInsets.all(40),
                      maxZoom: 17,
                    ),
                  );
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _tfUrl,
                userAgentPackageName: 'com.example.rider_app',
                maxNativeZoom: 22,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: s,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.store,
                      color: Colors.green,
                      size: 36,
                    ),
                  ),
                  Marker(
                    point: r,
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

  // ------------------------------ Accept ------------------------------
  Future<void> _acceptJob(String orderId) async {
    try {
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
      _afterBuild(_refitMapByStatus);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }
}
