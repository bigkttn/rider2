import 'dart:developer';
import 'dart:io';

import 'package:blink_delivery_project/pages/receiving_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class OrderlistPage extends StatefulWidget {
  final String uid;
  final String rid;
  const OrderlistPage({super.key, required this.uid, required this.rid});

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
      InTransitTab(uid: widget.uid, rid: widget.rid),
      ReceivedTab(uid: widget.uid, rid: widget.rid),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFFFF3B30)),

          // พื้นหลังขาวส่วนล่าง
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedIndex = 0;
                            });
                          },
                          child: Text(
                            'สินค้าที่เคยได้รับ',
                            style: TextStyle(
                              color: _selectedIndex == 0
                                  ? Color(0xffff3b30)
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ButtonStyle(
                            side: WidgetStatePropertyAll(
                              BorderSide(color: Color(0xffff3b30), width: 2),
                            ),
                            foregroundColor:
                                MaterialStateProperty.resolveWith<Color?>(
                                  (states) =>
                                      states.contains(MaterialState.pressed)
                                      ? Colors.white
                                      : Color(0xffff3b30),
                                ),
                            backgroundColor:
                                MaterialStateProperty.resolveWith<Color?>(
                                  (states) =>
                                      states.contains(MaterialState.pressed)
                                      ? Color(0xffff3b30)
                                      : Colors.white,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedIndex = 1;
                            });
                          },
                          child: Text(
                            'สินค้าที่เคยได้รับ',
                            style: TextStyle(
                              color: _selectedIndex == 1
                                  ? Color(0xffff3b30)
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ButtonStyle(
                            side: WidgetStatePropertyAll(
                              BorderSide(color: Color(0xffff3b30), width: 2),
                            ),
                            foregroundColor:
                                MaterialStateProperty.resolveWith<Color?>(
                                  (states) =>
                                      states.contains(MaterialState.pressed)
                                      ? Colors.white
                                      : Color(0xffff3b30),
                                ),
                            backgroundColor:
                                MaterialStateProperty.resolveWith<Color?>(
                                  (states) =>
                                      states.contains(MaterialState.pressed)
                                      ? Color(0xffff3b30)
                                      : Colors.white,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 0), // ขยับขึ้น
                      child: _pages[_selectedIndex],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔹 Header สีแดงด้านบน
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Padding(
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                      border: Border.all(color: Colors.white, width: 3),
                      image: _imageFile != null
                          ? const DecorationImage(
                              image: NetworkImage(''),
                              fit: BoxFit.cover,
                            )
                          : null,
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
}

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
  });

  @override
  Widget build(BuildContext context) {
    // String formattedDate = '';
    // if (createAt is Timestamp) {
    //   formattedDate = createAt.toDate().toString().substring(0, 16);
    // }

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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(senderAddress),
            Text("โทร: $senderPhone"),
            const Divider(),
            Text(
              "ไรเดอร์: $riderName",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text("เบอร์โทร: $riderPhone"),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "สถานะ: $status",
                  style: const TextStyle(color: Colors.green),
                ),

                if (status != 'ไรเดอร์นำส่งสินค้าแล้ว') ...[
                  TextButton(
                    onPressed: () {
                      Get.to(() => ReceivingStatus());
                    },
                    child: Text('รายละเอียด'),
                    style: ButtonStyle(
                      side: WidgetStatePropertyAll(
                        BorderSide(color: Color(0xffff3b30), width: 2),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      foregroundColor:
                          MaterialStateProperty.resolveWith<Color?>(
                            (states) => states.contains(MaterialState.pressed)
                                ? Colors.white
                                : Colors.red,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InTransitTab extends StatefulWidget {
  final String uid;
  final String rid;
  const InTransitTab({super.key, required this.uid, required this.rid});

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
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where(
            'createAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('createAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      List<Map<String, dynamic>> tempOrder = [];

      for (var itemOne in orderSnapshot.docs) {
        final orderData = itemOne.data();

        // if (orderData['status'] == 'ไรเดอร์นำส่งสินค้าแล้ว') continue;

        if (orderData['sender_id'] == widget.uid ||
            orderData['receiver_id'] == widget.uid ||
            orderData['rider_id'] == widget.rid) {
          final senderDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(orderData['sender_id'])
              .get();
          final riderDoc = await FirebaseFirestore.instance
              .collection('riders')
              .doc(orderData['rider_id'])
              .get();

          tempOrder.add({
            'order_id': itemOne.id,
            'item': orderData['items'] ?? [],
            'sender_name': senderDoc.exists ? senderDoc['fullname'] : '',
            'sender_phone': senderDoc.exists ? senderDoc['phone'] : '',
            'sender_address': orderData['sender_address'] ?? '',
            'rider_name': riderDoc.exists ? riderDoc['fullname'] : '',
            'rider_phone': riderDoc.exists ? riderDoc['phone'] : '',
            'status': orderData['status'] ?? '',
            'createAt': orderData['createAt'] ?? '',
          });

          log('All Intransit $tempOrder');
        }
      }

      setState(() {
        productReceivedList = tempOrder;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productReceivedList.isEmpty) {
      return const Center(child: Text('ไม่มีรายการที่อยู่ระหว่างจัดส่ง'));
    }

    return ListView.builder(
      itemCount: productReceivedList.length,
      itemBuilder: (context, index) {
        var order = productReceivedList[index];
        final items = order['item'] as List<dynamic>;
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
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

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

      List<Map<String, dynamic>> tempOrder = [];

      for (var itemOne in snapshot.docs) {
        final orderData = itemOne.data();

        if (orderData['sender_id'] == widget.uid ||
            orderData['receiver_id'] == widget.uid ||
            orderData['rider_id'] == widget.rid) {
          final senderDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(orderData['sender_id'])
              .get();
          final riderDoc = await FirebaseFirestore.instance
              .collection('riders')
              .doc(orderData['rider_id'])
              .get();

          tempOrder.add({
            'order_id': itemOne.id,
            'item': orderData['items'] ?? [],
            'sender_name': senderDoc.exists ? senderDoc['fullname'] : '',
            'sender_phone': senderDoc.exists ? senderDoc['phone'] : '',
            'sender_address': orderData['sender_address'] ?? '',
            'rider_name': riderDoc.exists ? riderDoc['fullname'] : '',
            'rider_phone': riderDoc.exists ? riderDoc['phone'] : '',
            'status': orderData['status'] ?? '',
            'createAt': orderData['createAt'] ?? '',
          });
          log('All received $tempOrder');
        }
      }

      setState(() {
        deliveredList = tempOrder;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching delivered orders: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (deliveredList.isEmpty) {
      return const Center(child: Text('ยังไม่มีรายการที่จัดส่งสำเร็จ'));
    }

    return ListView.builder(
      itemCount: deliveredList.length,
      itemBuilder: (context, index) {
        var order = deliveredList[index];
        final items = order['item'] as List<dynamic>;
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
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
