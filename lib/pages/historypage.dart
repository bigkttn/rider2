import 'package:blink_delivery_project/pages/sending_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  final String uid;
  const HistoryPage({super.key, required this.uid});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> ordersList = [];
  bool isLoading = true; // ✅ แทน _isLoading เพื่อเลี่ยงจอแดง Lookup failed

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
          'status': (data['status'] ?? '').toString(), // ✅ บังคับเป็น String
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
          'createAt': data['createAt'], // ใช้เรียงลำดับถ้ามี
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
            : ordersList.isEmpty
            ? const Center(child: Text('ไม่มีประวัติการส่งของคุณ'))
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: ordersList.length,
                  itemBuilder: (context, index) {
                    final order = ordersList[index];
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

  /// หน้าการ์ดแต่ละออเดอร์
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
