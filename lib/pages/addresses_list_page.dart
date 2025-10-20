import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'add_address_page.dart';

class AddressesListPage extends StatefulWidget {
  final String uid;
  const AddressesListPage({super.key, required this.uid});

  @override
  State<AddressesListPage> createState() => _AddressesListPageState();
}

class _AddressesListPageState extends State<AddressesListPage> {
  List<Map<String, dynamic>> addressesList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('addresses')
        .where('aid')
        .orderBy('created_at', descending: true)
        .get();

    setState(() {
      addressesList = snapshot.docs
          .map((doc) => {'aid': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffff3b30),
      appBar: AppBar(
        backgroundColor: const Color(0xffff3b30),
        iconTheme: IconThemeData(color: Color(0xffffffff)),
      ),
      body: Stack(
        children: [
          Container(
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 10.0),
                    child: Text(
                      'รายการที่อยู่',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xffffffff),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xffffffff),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.0),
                          topRight: Radius.circular(20.0),
                        ),
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : addressesList.isEmpty
                          ? const Center(child: Text('ยังไม่มีที่อยู่'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: addressesList.length,
                              itemBuilder: (context, index) {
                                final addr = addressesList[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    title: Text(
                                      addr['address'] ?? 'ไม่มีข้อมูล',
                                    ),
                                    subtitle: Text(
                                      'Lat: ${addr['latitude']}\nLng: ${addr['longitude']}',
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xffff3b30),
        icon: const Icon(Icons.add_location_alt, color: Color(0xffffffff)),
        label: const Text(
          'เพิ่มที่อยู่',
          style: TextStyle(
            color: Color(0xffffffff),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        onPressed: () async {
          // await Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => AddAddressPage(uid: widget.uid),
          //   ),
          // );

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddAddressPage(uid: widget.uid),
            ),
          );

          if (result == true) {
            _fetchAddresses(); // 🔁 รีโหลดเฉพาะเมื่อเพิ่มข้อมูลสำเร็จ
          }
          // _fetchAddresses();
        },
      ),
    );
  }
}
