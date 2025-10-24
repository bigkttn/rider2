import 'dart:developer';
import 'package:blink_delivery_project/model/get_user_re.dart';
import 'package:blink_delivery_project/pages/createpage.dart';
import 'package:blink_delivery_project/pages/historypage.dart';
import 'package:blink_delivery_project/pages/orderlist.dart';
import 'package:blink_delivery_project/pages/setting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// =======================================================================

class Homepage extends StatefulWidget {
  final String uid, aid, rid, oid;
  const Homepage({
    super.key,
    required this.uid,
    required this.aid,
    required this.rid,
    required this.oid,
  });

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeContent(uid: widget.uid),
      HistoryPage(uid: widget.uid),
      OrderlistPage(uid: widget.uid, rid: widget.rid, oid: widget.oid),
      SettingPage(uid: widget.uid, aid: widget.aid),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xffff3b30),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'ประวัติ'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'รายการ'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'ตั้งค่า'),
        ],
        currentIndex: _currentIndex,
        onTap: (int index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// =========================================================================
// ==                          HOME CONTENT WIDGET                        ==
// =========================================================================

class HomeContent extends StatefulWidget {
  final String uid;
  const HomeContent({super.key, required this.uid});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _user = UserModel.fromMap(doc.id, doc.data()!);
        });
        log(
          "✅ User data loaded: ${_user!.fullname}, Image URL: ${_user!.imageUrl}",
        );
      } else {
        log("❌ User document not found for uid: ${widget.uid}");
      }
    } catch (e) {
      log("❌ Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const double kWhiteTop = 180; // จุดเริ่มพื้นที่สีขาว (เดิม)
    const double kPushIntoWhite = 80; // ระยะดันปุ่มให้ลงไปในโซนสีขาว

    return Scaffold(
      body: Stack(
        children: [
          // พื้นหลังแดง
          Container(color: const Color(0xFFFF3B30)),
          // แผ่นสีขาวโค้งมนด้านบน — กลับไปตำแหน่งเดิม
          const Positioned(
            top: kWhiteTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: _WhiteSheet(),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                // เนื้อหา
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Column(
                      children: [
                        // ดันเนื้อหา (โดยเฉพาะปุ่ม) ลงไปอยู่ในแผ่นสีขาว
                        const SizedBox(height: kPushIntoWhite),
                        _buildMainButton(
                          "ส่งสินค้า",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    Createpage(uid: widget.uid),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "สวัสดี",
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                Text(
                  _user?.fullname ?? 'กำลังโหลด...',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              color: Colors.grey.shade200,
              image: (_user?.imageUrl != null && _user!.imageUrl.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(_user!.imageUrl),
                      fit: BoxFit.cover,
                      onError: (error, stackTrace) {
                        log("Error loading image: $error");
                      },
                    )
                  : const DecorationImage(
                      image: AssetImage('assets/images/avatar.png'),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton(String text, {required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffff3b30),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// แผ่นสีขาวโค้งมน (แยกเป็น Stateless ให้โค้ดสะอาด)
class _WhiteSheet extends StatelessWidget {
  const _WhiteSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
    );
  }
}
