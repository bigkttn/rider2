import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Riderhistory extends StatefulWidget {
  final String uid;
  const Riderhistory({super.key, required this.uid});

  @override
  State<Riderhistory> createState() => _RiderhistoryState();
}

class _RiderhistoryState extends State<Riderhistory> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 🔹 ไม่มีปุ่มย้อนกลับ
        title: const Text("ประวัติการส่งสินค้า"),
        backgroundColor: const Color(0xFFFF3B30),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ ไม่ใช้ orderBy → ไม่ต้องสร้าง index
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('rider_id', isEqualTo: widget.uid)
            .where('status', isEqualTo: 'ไรเดอร์นำส่งสินค้าแล้ว')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("ยังไม่มีประวัติการส่งสินค้า"));
          }

          final orders = snapshot.data!.docs;

          // 🔹 เรียงข้อมูลเองตาม delivered_at (ถ้ามี)
          orders.sort((a, b) {
            final aTime =
                (a.data() as Map<String, dynamic>).containsKey('delivered_at')
                ? ((a['delivered_at'] as Timestamp?)?.toDate() ?? DateTime(0))
                : DateTime(0);
            final bTime =
                (b.data() as Map<String, dynamic>).containsKey('delivered_at')
                ? ((b['delivered_at'] as Timestamp?)?.toDate() ?? DateTime(0))
                : DateTime(0);
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;

              // ✅ ป้องกัน error field ไม่มี
              final deliveredAt =
                  data.containsKey('delivered_at') &&
                      data['delivered_at'] != null
                  ? (data['delivered_at'] as Timestamp).toDate()
                  : null;
              final createdAt =
                  data.containsKey('createAt') && data['createAt'] != null
                  ? (data['createAt'] as Timestamp).toDate()
                  : null;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 🔹 หัวข้อ: หมายเลขออเดอร์
                      Text(
                        "รหัสออเดอร์: ${data['order_id'] ?? '-'}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),

                      /// 🔹 รูปภาพ pickup และ delivered
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildImageCard(
                            title: "ตอนรับสินค้า",
                            imageUrl: data['image_pickup'],
                            color: Colors.orange,
                          ),
                          _buildImageCard(
                            title: "ตอนส่งสินค้า",
                            imageUrl: data['image_delivered'],
                            color: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      /// 🔹 ข้อมูลที่อยู่ผู้รับ
                      Text(
                        "ที่อยู่ผู้รับ:",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        data['receiver_address'] ?? "ไม่พบที่อยู่ผู้รับ",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 6),

                      /// 🔹 รายละเอียดสินค้า
                      if (data['items'] != null &&
                          data['items'] is List &&
                          (data['items'] as List).isNotEmpty)
                        Text(
                          "สินค้า: ${(data['items'][0]['detail'] ?? '').toString()}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),

                      const SizedBox(height: 8),

                      /// 🔹 วันที่และสถานะ
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (createdAt != null)
                            Text(
                              "สร้างเมื่อ: ${createdAt.day}/${createdAt.month}/${createdAt.year}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          if (deliveredAt != null)
                            Text(
                              "ส่งเมื่อ: ${deliveredAt.day}/${deliveredAt.month}/${deliveredAt.year}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "สถานะ: ${data['status'] ?? '-'}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 🔸 Widget ย่อย: แสดงรูปภาพ Pickup / Delivered
  Widget _buildImageCard({
    required String title,
    required String? imageUrl,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Container(
          width: 120,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 2),
          ),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(imageUrl, fit: BoxFit.cover),
                )
              : const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: 40,
                ),
        ),
      ],
    );
  }
}
