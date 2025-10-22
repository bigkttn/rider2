import 'dart:developer';
import 'package:blink_delivery_project/model/get_user_re.dart';
import 'package:blink_delivery_project/pages/createpage.dart';
import 'package:blink_delivery_project/pages/historypage.dart';
import 'package:blink_delivery_project/pages/login.dart';
import 'package:blink_delivery_project/pages/orderlist.dart';
import 'package:blink_delivery_project/pages/receiving_status.dart';
import 'package:blink_delivery_project/pages/sending_status.dart';
import 'package:blink_delivery_project/pages/setting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// =======================================================================

class Homepage extends StatefulWidget {
  final String uid, aid, rid;
  const Homepage({
    super.key,
    required this.uid,
    required this.aid,
    required this.rid,
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
      OrderlistPage(uid: widget.uid, rid: widget.rid),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'ออกจากระบบ',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (int index) {
          if (index == 4) {
            FirebaseAuth.instance.signOut();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
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
    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFFFF3B30)),
          Positioned(
            top: 180,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildMainButton(
                          "ส่งสินค้า",
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Createpage(uid: widget.uid),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Row(
                        //   children: [
                        //     Expanded(
                        //       child: _buildSubButton(
                        //         "กำลังจัดส่ง",
                        //         onPressed: () => Navigator.push(
                        //           context,
                        //           MaterialPageRoute(
                        //             builder: (context) => const SendingStatus(),
                        //           ),
                        //         ),
                        //       ),
                        //     ),
                        //     const SizedBox(width: 16),
                        //     Expanded(
                        //       child: _buildSubButton(
                        //         "รอการตอบรับ",
                        //         onPressed: () => Navigator.push(
                        //           context,
                        //           MaterialPageRoute(
                        //             builder: (context) =>
                        //                 const ReceivingStatus(),
                        //           ),
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
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

  Widget _buildSubButton(String text, {required VoidCallback onPressed}) {
    return SizedBox(
      height: 100,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffff3b30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
