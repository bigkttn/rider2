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
      backgroundColor: Color(0xffff3b30),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(150.0),
        child: AppBar(
          backgroundColor: Color(0xffff3b30),
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
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RiderContact(uid: widget.uid, rid: widget.rid, oid: widget.oid),
              const SizedBox(height: 16),
              MapReceive(uid: widget.uid, rid: widget.rid),
              const SizedBox(height: 16),
              ProductDetail(oid: widget.oid, uid: widget.uid),
            ],
          ),
        ),
      ),
    );
  }
} //main class

///rider-----------------------------------------------------
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

  @override
  void initState() {
    super.initState();
    _fetchReceiveOrders();
  }

  Future<void> _fetchReceiveOrders() async {
    try {
      DocumentSnapshot riderDoc = await FirebaseFirestore.instance
          .collection('riders')
          .doc(widget.rid)
          .get();

      if (riderDoc.exists) {
        setState(() {
          riderName = riderDoc.get('fullname');
          riderProfile = riderDoc.get('profile_photo');
          riderPhone = riderDoc.get('phone');
          riderVehicleNumber = riderDoc.get('vehicle_number');

          _isLoading = false;
        });
      } else {
        print('rider document does not exist');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Error fetching orders: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
                    border: Border.all(
                      color: Colors.red,
                      width: 2,
                    ), // กำหนดสีและความหนาของขอบ
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: riderProfile != null
                        ? NetworkImage(riderProfile!)
                        : null,
                    child: riderProfile == null
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
                          Text('ทะเบียนรถ: ', style: TextStyle(fontSize: 12)),
                          Text(
                            riderVehicleNumber ?? 'ไม่ระบุเลขทะเบียนรถ',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'เบอร์โทรศัพท์: ',
                            style: TextStyle(fontSize: 12),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              riderPhone ?? 'ไม่ระบุเบอร์โทรศัพท์',
                              style: TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 80,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Get.to(() => Riderprofile(rid: widget.rid));
                    },
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

//end rider

//map--------------------------------------------------------------
class MapReceive extends StatefulWidget {
  final String uid, rid;
  const MapReceive({super.key, required this.uid, required this.rid});

  @override
  State<MapReceive> createState() => _MapReceiveState();
}

class _MapReceiveState extends State<MapReceive> {
  Map<String, dynamic>? currentOrder;
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
      if (currentOrder != null) {
        _updateDistance();
      }
    });
  }

  void _updateDistance() {
    if (riderPos != null && receiverPos != null) {
      distanceToRider = Geolocator.distanceBetween(
        riderPos!.latitude,
        riderPos!.longitude,
        receiverPos!.latitude,
        receiverPos!.longitude,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where(
            'status',
            whereIn: [
              'รอไรเดอร์รับสินค้า',
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

        final List<Marker> markers = [];
        Marker? myRiderMarker;

        for (var doc in orders) {
          final data = doc.data() as Map<String, dynamic>;

          if (data['rider_latitude'] == null ||
              data['rider_longitude'] == null) {
            continue;
          }

          final LatLng riderPosition = LatLng(
            double.tryParse(data['rider_latitude'].toString()) ?? 0,
            double.tryParse(data['rider_longitude'].toString()) ?? 0,
          );

          final bool isMyOrder =
              data['receiver_id'] == widget.uid &&
              data['rider_id'] == widget.rid;

          if (isMyOrder &&
              data['receiver_latitude'] != null &&
              data['receiver_longitude'] != null) {
            receiverPos = LatLng(
              double.tryParse(data['receiver_latitude'].toString()) ?? 0,
              double.tryParse(data['receiver_longitude'].toString()) ?? 0,
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

          if (isMyOrder &&
              data['rider_latitude'] != null &&
              data['rider_longitude'] != null) {
            riderPos = LatLng(
              double.tryParse(data['rider_latitude'].toString()) ?? 0,
              double.tryParse(data['rider_longitude'].toString()) ?? 0,
            );
            markers.add(
              myRiderMarker = Marker(
                point: riderPosition,
                width: 30,
                height: 30,
                child: Icon(
                  Icons.directions_bike_sharp,
                  color: isMyOrder ? Colors.red : Colors.grey.shade600,
                  size: 30,
                ),
              ),
            );
          }
          // else{
          //    markers.add(
          //     Marker(
          //       point: riderPosition,
          //       width: 30,
          //       height: 30,
          //       child: Icon(
          //         Icons.directions_bike_sharp,
          //         color:  Colors.grey.shade600,
          //         size: 30,
          //       ),
          //     ),
          //   );

          //  }
        }
        if (myRiderMarker != null) {
          markers.add(myRiderMarker);
        }

        final LatLng initialCenter =
            receiverPos ?? const LatLng(15.870031, 100.992541);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueGrey, width: 2),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
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
                    initialZoom: 13,
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
} //end map

//order product-----------------------------------------------------------------
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDeliveredOrders();
  }

  Future<void> _fetchDeliveredOrders() async {
    try {
      DocumentSnapshot orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.oid)
          .get();

      if (!orderDoc.exists) {
        print("ไม่พบข้อมูลคำสั่งซื้อ");
        setState(() => _isLoading = false);
        return;
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      String? senderId = orderData['sender_id'];

      if (senderId == null || senderId.isEmpty) {
        print("ไม่พบ sender_id ใน order");
        setState(() => _isLoading = false);
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();

      setState(() {
        orderDetail = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
        senderAddress = orderData['sender_address'] ?? 'ไม่ระบุที่อยู่';
        senderName = userDoc.get('fullname') ?? 'ไม่ระบุชื่อผู้ส่ง';
        senderPhone = userDoc.get('phone') ?? 'ไม่ระบุเบอร์โทร';
        status = orderData['status'] ?? 'ว่าง';
        _isLoading = false;
      });
      print('สถานะตอนนี้: "$status"');
    } catch (e) {
      print("fetch error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orderDetail.isEmpty) {
      return const Center(child: Text('ไม่พบข้อมูลสินค้า'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),

      itemCount: orderDetail.length,
      itemBuilder: (context, index) {
        var item = orderDetail[index];

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

              Padding(
                padding: const EdgeInsets.all(3),
                child: Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['detail'] ?? 'ไม่ระบุรายละเอียด',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        senderName!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: Text(
                          senderAddress!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      Text(
                        senderPhone!,
                        style: TextStyle(
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
      },
    );
  }
}
//end product
//-------------------------------------------------------------------------

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
  List<Map<String, dynamic>> statusList = [];
  bool _isLoading = true;
  String? status;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      DocumentSnapshot statueDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.oid)
          .get();
      final data = statueDoc.data() as Map<String, dynamic>;

      setState(() {
        status = data['status'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      print('fetch error:$e');
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
