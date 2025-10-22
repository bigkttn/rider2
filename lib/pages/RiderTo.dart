import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class Ridertopage extends StatefulWidget {
  final String uid;
  const Ridertopage({super.key, required this.uid});

  @override
  State<Ridertopage> createState() => _RidertopageState();
}

class _RidertopageState extends State<Ridertopage> {
  // Images
  File? pickupImage;
  File? deliveredImage;

  // Distances
  double? distanceToPickup;
  double? distanceToReceiver;

  // Positions
  LatLng? riderPos;
  LatLng? pickupPos;
  LatLng? receiverPos;

  // Order & flags
  Map<String, dynamic>? currentOrder;
  bool _isFinished = false;

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _posSub;

  // ---------- Safe scheduling ----------
  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle) {
      setState(fn);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(fn);
      });
    }
  }

  void _afterBuild(VoidCallback fn) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      fn();
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

  // ---------- Location stream ----------
  Future<void> _ensureLocationPermissionAndStream() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
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
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && riderPos != null)
                  _mapController.move(riderPos!, 16);
              });

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

  // ---------- Cloudinary ----------
  Future<String?> _uploadToCloudinary(File image) async {
    try {
      const cloudName = "dywfdy174";
      const uploadPreset = "flutter_upload";
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ รับสินค้าเรียบร้อย กำลังเดินทางไปส่ง'),
          ),
        );
      }
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ ส่งสินค้าเรียบร้อยแล้ว 🎉')),
        );
      }
    }
  }

  // ---------- Fetch addresses ----------
  Future<void> _fetchAddresses(Map<String, dynamic> order) async {
    try {
      final senderSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(order['sender_id'])
          .collection('addresses')
          .limit(1)
          .get();

      if (senderSnapshot.docs.isNotEmpty) {
        final sender = senderSnapshot.docs.first.data();
        pickupPos = LatLng(
          double.tryParse(sender['latitude'].toString()) ?? 0,
          double.tryParse(sender['longitude'].toString()) ?? 0,
        );
      } else {
        pickupPos = null;
      }

      final receiverSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(order['receiver_id'])
          .collection('addresses')
          .limit(1)
          .get();

      if (receiverSnapshot.docs.isNotEmpty) {
        final receiver = receiverSnapshot.docs.first.data();
        receiverPos = LatLng(
          double.tryParse(receiver['latitude'].toString()) ?? 0,
          double.tryParse(receiver['longitude'].toString()) ?? 0,
        );
      } else {
        receiverPos = null;
      }

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
      log("📍 sender: $pickupPos | receiver: $receiverPos");
    } catch (e) {
      log('❌ Error fetching addresses: $e');
    }
  }

  // ---------- Order state transitions ----------
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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && riderPos != null) _mapController.move(riderPos!, 16);
      });
    } catch (e) {
      log('getCurrentPosition error: $e');
    }

    safeSetState(() {}); // draw rider marker instantly
  }

  void _onNoOrder() {
    if (currentOrder == null &&
        pickupPos == null &&
        receiverPos == null &&
        distanceToPickup == null &&
        distanceToReceiver == null) {
      return;
    }

    currentOrder = null;
    pickupPos = null;
    receiverPos = null;
    distanceToPickup = null;
    distanceToReceiver = null;
    // keep last riderPos for next job
    safeSetState(() {});
  }

  // ---------- Bottom Sheet ----------
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
        return DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            final status = (currentOrder?['status'] ?? '').toString();
            final canPickup = (distanceToPickup ?? double.infinity) <= 20;
            final canDeliver = (distanceToReceiver ?? double.infinity) <= 20;

            return SingleChildScrollView(
              controller: scrollController,
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('สถานะ: $status'),
                  if (distanceToPickup != null)
                    Text(
                      "ระยะจากจุดรับสินค้า: ${distanceToPickup!.toStringAsFixed(1)} ม.",
                      style: TextStyle(
                        color: (distanceToPickup ?? 999) <= 20
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  if (distanceToReceiver != null)
                    Text(
                      "ระยะจากจุดส่งสินค้า: ${distanceToReceiver!.toStringAsFixed(1)} ม.",
                      style: TextStyle(
                        color: (distanceToReceiver ?? 999) <= 20
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Pickup photo
                  ElevatedButton.icon(
                    onPressed: status.contains('ไปรับสินค้า') && canPickup
                        ? () async {
                            Navigator.of(
                              context,
                            ).pop(); // ปิด sheet ระหว่างเปิดกล้อง
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
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Image.file(
                        pickupImage!,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Delivered photo
                  ElevatedButton.icon(
                    onPressed: status.contains('ไปส่ง') && canDeliver
                        ? () async {
                            Navigator.of(context).pop();
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
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Image.file(
                        deliveredImage!,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Cancel button
                  ElevatedButton.icon(
                    onPressed: () async {
                      final confirmCancel = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
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

                      if (confirmCancel == true && currentOrder != null) {
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
                                'rider_last_update':
                                    FieldValue.serverTimestamp(),
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

                          Navigator.of(context).pop(); // ปิด sheet
                          _afterBuild(_onNoOrder);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '🚫 ยกเลิกการส่งสำเร็จ — งานกลับไปรอรับใหม่',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          log('❌ Error cancel delivery: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('เกิดข้อผิดพลาดในการยกเลิก'),
                              ),
                            );
                          }
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
            );
          },
        );
      },
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("จัดการการส่งสินค้า"),
        backgroundColor: const Color(0xFFFF3B30),
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

            // ไม่มีงาน → แผนที่ใหญ่เฉย ๆ + FAB แจ้งเตือน
            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter:
                                riderPos ?? const LatLng(15.870031, 100.992541),
                            initialZoom: 14,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.rider_app',
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
                    ),
                  ],
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: FloatingActionButton.extended(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ยังไม่มีงานที่ต้องจัดส่ง'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.info_outline),
                        label: const Text('รายละเอียดงาน'),
                        backgroundColor: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;

          if (currentOrder == null ||
              currentOrder!['order_id'] != data['order_id'] ||
              currentOrder!['status'] != data['status']) {
            _afterBuild(() => _onNewActiveOrder(data));
          }

          final status = (currentOrder?['status'] ?? data['status'] ?? '')
              .toString();

          // ----------- BIG MAP + FAB -----------
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red, width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
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
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.rider_app',
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
                              if (riderPos != null &&
                                  currentOrder != null &&
                                  !_isFinished)
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
                  ),
                ],
              ),
              // FAB เปิดแผงคำสั่ง
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FloatingActionButton.extended(
                      onPressed: _openJobSheet,
                      icon: const Icon(Icons.tune),
                      label: Text(status.isEmpty ? 'รายละเอียดงาน' : status),
                      backgroundColor: const Color(0xFFFF3B30),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
