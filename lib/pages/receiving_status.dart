import 'package:flutter/material.dart';

class ReceivingStatus extends StatefulWidget {
  const ReceivingStatus({super.key});

  @override
  State<ReceivingStatus> createState() => _ReceivingStatusState();
}

final TextEditingController _searchController =
    TextEditingController(); //for search

class _ReceivingStatusState extends State<ReceivingStatus> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(150.0),
        child: AppBar(
          backgroundColor: Colors.red,
          elevation: 0,
          shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
          flexibleSpace: const Padding(
            padding: EdgeInsets.only(top: 50.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'สถานะการจัดส่ง',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                StatusTracker(),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Rider Info Card
              _buildRiderCard(),
              const SizedBox(height: 16),
              // Map Card
              _buildMapCard(),
              const SizedBox(height: 16),
              // Item & Recipient Info Card
              _buildRecipientCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: 0,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'ประวัติการส่ง',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'รายการสินค้า',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'ตั้งค่า'),
        ],
      ),
    );
  }

  Widget _buildRiderCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ไรเดอร์',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?img=1',
                  ), // URL รูปโปรไฟล์ไรเดอร์
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kittichet Tanuwan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'ทะเบียนรถ: กน 3456',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      Text(
                        'เบอร์โทร 0875439909',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ข้อมูลไรเดอร์',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias, // ทำให้รูปภาพโค้งตาม Card
      child: Image.network(
        'https://i.imgur.com/3Z1Zc5x.png', // URL รูปแผนที่
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildRecipientCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                'https://i.imgur.com/uRj0w5R.png', // URL รูปกระเป๋าเดินทาง
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'กระเป๋าเดินทาง ขนาด 14 นิ้ว สีชมพู',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'จอร์จศักดิ์ นานะ',
                    style: TextStyle(color: Colors.grey[800], fontSize: 14),
                  ),
                  Text(
                    '402 หอรัฐฎิพงศ์ แมนชั่น\nตำบลศรีษะจระเข้น้อย อำเภอบางพลีสมุทรลักษณ์ จังหวัดสมุทรปราการ 4560',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'เบอร์โทร 0945364493',
                    style: TextStyle(color: Colors.grey[800], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget สำหรับสร้าง Status Tracker ด้านบน
class StatusTracker extends StatelessWidget {
  const StatusTracker({super.key});

  @override
  Widget build(BuildContext context) {
    // กำหนดสถานะปัจจุบันที่นี่ (เช่น 1 = เวลา, 2 = รับของ, ...)
    const int currentStep = 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatusIcon(Icons.access_time_filled, currentStep >= 1),
        _buildConnector(currentStep > 1),
        _buildStatusIcon(Icons.upload, currentStep >= 2),
        _buildConnector(currentStep > 2),
        _buildStatusIcon(Icons.motorcycle, currentStep >= 3),
        _buildConnector(currentStep > 3),
        _buildStatusIcon(Icons.check_circle, currentStep >= 4),
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
      height: 4,
      color: isActive ? Colors.white : Colors.grey[300]?.withOpacity(0.5),
    );
  }
}
