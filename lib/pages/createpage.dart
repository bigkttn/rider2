import 'dart:convert';
import 'dart:io';
import 'package:blink_delivery_project/model/address_model.dart';
import 'package:blink_delivery_project/model/get_user_re.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Createpage extends StatefulWidget {
  final String uid;
  const Createpage({super.key, required this.uid});

  @override
  State<Createpage> createState() => _CreatepageState();
}

class _CreatepageState extends State<Createpage> {
  final TextEditingController detailCtl = TextEditingController();
  final TextEditingController phoneSearchCtl = TextEditingController();

  File? pickedFile;
  final ImagePicker _picker = ImagePicker();
  String? _imageUrl;

  bool isCreate = false;

  UserModel? sender;
  AddressModel? senderAddress;

  UserModel? receiver;
  AddressModel? receiverAddress;

  List<Map<String, dynamic>> items = [];

  // for map preview
  final MapController _map = MapController();

  @override
  void initState() {
    super.initState();
    _loadSender();
  }

  @override
  void dispose() {
    detailCtl.dispose();
    phoneSearchCtl.dispose();
    super.dispose();
  }

  /// โหลดข้อมูลผู้ส่ง + ที่อยู่ (ถ้ามีหลายที่ ให้เลือก)
  Future<void> _loadSender() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid.trim())
          .get();

      if (!mounted) return;
      if (userDoc.exists) {
        sender = UserModel.fromMap(userDoc.id, userDoc.data()!);
      }

      final addrSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid.trim())
          .collection('addresses')
          .get();

      if (!mounted) return;

      if (addrSnap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ผู้ส่งยังไม่มีที่อยู่ในระบบ")),
        );
        return;
      }

      if (addrSnap.docs.length > 1) {
        final addresses = addrSnap.docs
            .map((d) => AddressModel.fromMap(d.id, d.data()))
            .toList();

        if (!mounted) return;
        final selected = await showDialog<AddressModel>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text("เลือกที่อยู่ของผู้ส่ง"),
            children: [
              for (final addr in addresses)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, addr),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(addr.address ?? "ไม่ทราบที่อยู่"),
                  ),
                ),
            ],
          ),
        );

        if (selected != null) {
          senderAddress = selected;
        } else {
          return;
        }
      } else {
        senderAddress = AddressModel.fromMap(
          addrSnap.docs.first.id,
          addrSnap.docs.first.data(),
        );
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("❌ โหลดข้อมูลผู้ส่งล้มเหลว: $e");
    }
  }

  /// ค้นหาผู้รับด้วยเบอร์โทร (2.1.2)
  Future<void> _searchReceiverByPhone() async {
    try {
      final phone = phoneSearchCtl.text.trim();
      if (phone.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("กรุณากรอกเบอร์โทรศัพท์")));
        return;
      }

      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (!mounted) return;

      if (userSnap.docs.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("ไม่พบผู้ใช้ที่มีเบอร์ $phone")));
        return;
      }

      final userDoc = userSnap.docs.first;
      receiver = UserModel.fromMap(userDoc.id, userDoc.data());

      final addrSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .collection('addresses')
          .get();

      if (!mounted) return;

      if (addrSnap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ผู้รับยังไม่มีที่อยู่ในระบบ")),
        );
        return;
      }

      if (addrSnap.docs.length > 1) {
        final addresses = addrSnap.docs
            .map((d) => AddressModel.fromMap(d.id, d.data()))
            .toList();

        if (!mounted) return;

        final selected = await showDialog<AddressModel>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text("เลือกที่อยู่ของผู้รับ"),
            children: [
              for (final addr in addresses)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, addr),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(addr.address ?? "ไม่ทราบที่อยู่"),
                  ),
                ),
            ],
          ),
        );

        if (selected != null) {
          receiverAddress = selected;
        } else {
          return;
        }
      } else {
        receiverAddress = AddressModel.fromMap(
          addrSnap.docs.first.id,
          addrSnap.docs.first.data(),
        );
      }

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ โหลดข้อมูลผู้รับสำเร็จ")),
        );
      }
    } catch (e) {
      debugPrint('❌ ค้นหาผู้รับล้มเหลว: $e');
    }
  }

  /// เลือกผู้รับจาก “ลิสต์ผู้ใช้ทั้งหมด” (2.1.1 ต้องมีลิสต์ให้เลือก)
  Future<void> _openReceiverPicker() async {
    final snap = await FirebaseFirestore.instance.collection('users').get();
    if (!mounted) return;

    final allUsers = snap.docs
        .where((d) => d.id != sender?.uid) // ตัดผู้ส่งออก
        .map((d) => UserModel.fromMap(d.id, d.data()))
        .toList();

    final chosen = await showModalBottomSheet<UserModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final qCtl = TextEditingController();
        // ← ใช้ StatefulBuilder เก็บลิสต์ที่กรองแล้ว
        List<UserModel> filtered = List.of(allUsers);

        void doFilter(String q, void Function(void Function()) setModalState) {
          final lower = q.trim().toLowerCase();
          setModalState(() {
            filtered = allUsers.where((u) {
              return u.fullname.toLowerCase().contains(lower) ||
                  u.phone.toLowerCase().contains(lower) ||
                  u.email.toLowerCase().contains(lower);
            }).toList();
          });
        }

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.7,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'เลือกรายชื่อผู้รับ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: TextField(
                          controller: qCtl,
                          onChanged: (q) => doFilter(q, setModalState),
                          decoration: InputDecoration(
                            hintText: 'ค้นหาชื่อ/อีเมล/เบอร์',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xffff3b30),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final u = filtered[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: u.imageUrl.isNotEmpty
                                    ? NetworkImage(u.imageUrl)
                                    : const AssetImage('assets/avatar.png')
                                          as ImageProvider,
                              ),
                              title: Text(u.fullname),
                              subtitle: Text('${u.phone}  |  ${u.email}'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.pop(ctx, u),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (chosen == null) return;

    // โหลดที่อยู่ของผู้รับที่เลือกเหมือนเดิม...
    final addrSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(chosen.uid)
        .collection('addresses')
        .get();

    if (!mounted) return;

    if (addrSnap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ผู้รับรายนี้ยังไม่มีที่อยู่ในระบบ")),
      );
      return;
    }

    AddressModel? chosenAddr;
    if (addrSnap.docs.length > 1) {
      final addresses = addrSnap.docs
          .map((d) => AddressModel.fromMap(d.id, d.data()))
          .toList();

      chosenAddr = await showDialog<AddressModel>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text("เลือกที่อยู่ของผู้รับ"),
          children: [
            for (final addr in addresses)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, addr),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(addr.address ?? "ไม่ทราบที่อยู่"),
                ),
              ),
          ],
        ),
      );
      if (chosenAddr == null) return;
    } else {
      chosenAddr = AddressModel.fromMap(
        addrSnap.docs.first.id,
        addrSnap.docs.first.data(),
      );
    }

    setState(() {
      receiver = chosen;
      receiverAddress = chosenAddr;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ เลือกผู้รับจากลิสต์สำเร็จ")),
    );
  }

  Future<void> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) setState(() => pickedFile = File(image.path));
  }

  Future<void> pickFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null && mounted) setState(() => pickedFile = File(image.path));
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      const cloudName = "dywfdy174";
      const uploadPreset = "flutter_upload";
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(await response.stream.bytesToString());
        return jsonData['secure_url'];
      }
      debugPrint("❌ Upload failed: ${response.statusCode}");
      return null;
    } catch (e) {
      debugPrint('❌ Upload Error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xffff3b30),
        actions: [
          CircleAvatar(
            backgroundImage: sender?.imageUrl.isNotEmpty == true
                ? NetworkImage(sender!.imageUrl)
                : const AssetImage("assets/avatar.png") as ImageProvider,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          Container(color: const Color(0xFFFF3B30)),
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    if (isCreate) _buildSenderInfo(),
                    if (isCreate) _buildReceiverSection(),
                    if (isCreate) _buildProductForm(),
                    if (!isCreate)
                      TextButton.icon(
                        onPressed: () => setState(() => isCreate = true),
                        icon: const Icon(Icons.add_box),
                        label: const Text(
                          "สร้างรายการใหม่",
                          style: TextStyle(fontSize: 20),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xffff3b30),
                        ),
                      ),
                    if (items.isNotEmpty) _buildItemList(),
                  ],
                ),
              ),
            ),
          ),
          _buildHeader(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "สร้างรายการส่งสินค้า",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderInfo() {
    return Padding(
      padding: const EdgeInsets.only(left: 30.0, bottom: 20),
      child: Row(
        children: [
          Container(
            width: 320,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 3),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: sender?.imageUrl.isNotEmpty == true
                      ? NetworkImage(sender!.imageUrl)
                      : const AssetImage("assets/avatar.png") as ImageProvider,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sender?.fullname ?? "ไม่พบชื่อผู้ส่ง",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        senderAddress?.address ?? "ไม่มีที่อยู่",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ส่วนผู้รับ: ค้นจากเบอร์ + เลือกจากลิสต์ + แผนที่ Preview (2.1.1–2.1.4)
  Widget _buildReceiverSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // แถวปุ่ม 2 วิธี: เลือกจากลิสต์ / ค้นจากเบอร์
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openReceiverPicker,
                  icon: const Icon(Icons.list),
                  label: const Text('เลือกรายชื่อ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffff3b30),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: phoneSearchCtl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'ค้นหาด้วยเบอร์',
                    prefixIcon: const Icon(
                      Icons.phone,
                      color: Color(0xffff3b30),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchReceiverByPhone,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // การ์ดรายละเอียดผู้รับ (2.1.3)
          if (receiver != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: receiver!.imageUrl.isNotEmpty
                          ? NetworkImage(receiver!.imageUrl)
                          : const AssetImage("assets/avatar.png")
                                as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receiver!.fullname,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('โทร: ${receiver!.phone}'),
                          Text('อีเมล: ${receiver!.email}'),
                          Text('ที่อยู่: ${receiverAddress?.address ?? "-"}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // แผนที่ Preview (2.1.4)
          if (receiverAddress != null && senderAddress != null)
            _ReceiverMapPreview(
              map: _map,
              sender: LatLng(
                double.tryParse(senderAddress!.latitude ?? '') ?? 0,
                double.tryParse(senderAddress!.longitude ?? '') ?? 0,
              ),
              recv: LatLng(
                double.tryParse(receiverAddress!.latitude ?? '') ?? 0,
                double.tryParse(receiverAddress!.longitude ?? '') ?? 0,
              ),
            ),
        ],
      ),
    );
  }

  /// แบบฟอร์มสินค้า + อัปโหลดรูป (2.1.5)
  Widget _buildProductForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 30),
          child: Text(
            "เพิ่มสินค้า",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 300,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: pickedFile == null
                ? const Icon(Icons.image, size: 50)
                : Image.file(pickedFile!, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: () async {
                await pickFromCamera();
                if (pickedFile != null) {
                  _imageUrl = await uploadImage(pickedFile!);
                  setState(() {});
                }
              },
              child: const Text("ถ่ายรูป"),
            ),
            const SizedBox(width: 20),
            FilledButton(
              onPressed: () async {
                await pickFromGallery();
                if (pickedFile != null) {
                  _imageUrl = await uploadImage(pickedFile!);
                  setState(() {});
                }
              },
              child: const Text("อัพโหลด"),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: detailCtl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: "รายละเอียดสินค้า",
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: () {
                if (detailCtl.text.isNotEmpty && _imageUrl != null) {
                  setState(() {
                    items.add({
                      'detail': detailCtl.text,
                      'imageUrl': _imageUrl,
                    });
                    detailCtl.clear();
                    pickedFile = null;
                    _imageUrl = null;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("กรอกข้อมูลให้ครบก่อนเพิ่ม")),
                  );
                }
              },
              child: const Text("เพิ่มสินค้าในรายการ"),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (items.isNotEmpty)
          Center(
            child: FilledButton(
              onPressed: _saveAllToFirestore,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xffff3b30),
                foregroundColor: Colors.white,
              ),
              child: const Text("บันทึกรายการทั้งหมด ✅"),
            ),
          ),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildItemList() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "รายการที่เพิ่มแล้ว",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        for (int i = 0; i < items.length; i++)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: ListTile(
              leading: items[i]['imageUrl'] != null
                  ? Image.network(items[i]['imageUrl'], width: 60)
                  : const Icon(Icons.image),
              title: Text(items[i]['detail']),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() => items.removeAt(i)),
              ),
            ),
          ),
      ],
    );
  }

  /// บันทึก order ลง Firestore
  Future<void> _saveAllToFirestore() async {
    if (sender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ยังโหลดข้อมูลผู้ส่งไม่เสร็จ")),
      );
      return;
    }
    if (receiver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาค้นหาหรือเลือกรายชื่อผู้รับ")),
      );
      return;
    }
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("ยังไม่มีสินค้าในรายการ")));
      return;
    }
    if (senderAddress?.latitude == null ||
        senderAddress?.longitude == null ||
        receiverAddress?.latitude == null ||
        receiverAddress?.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ไม่พบพิกัดของผู้ส่งหรือผู้รับ")),
      );
      return;
    }

    final ordersData = {
      'sender_id': sender!.uid,
      'receiver_id': receiver!.uid,
      'rider_id': '',
      'sender_address': senderAddress?.address ?? '',
      'receiver_address': receiverAddress?.address ?? '',
      'sender_latitude': senderAddress!.latitude,
      'sender_longitude': senderAddress!.longitude,
      'receiver_latitude': receiverAddress!.latitude,
      'receiver_longitude': receiverAddress!.longitude,
      'createAt': FieldValue.serverTimestamp(),
      'items': items,
      'status': 'รอไรเดอร์รับสินค้า',
      'image_pickup': '',
      'image_delivered': '',
    };

    final docRef = await FirebaseFirestore.instance
        .collection('orders')
        .add(ordersData);
    await docRef.update({'order_id': docRef.id});

    setState(() {
      items.clear();
      isCreate = false;
      receiver = null;
      receiverAddress = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("บันทึกรายการสำเร็จ 🎉")));
  }
}

/// ---------- แผนที่ Preview ผู้ส่ง/ผู้รับ (Thunderforest) ----------
class _ReceiverMapPreview extends StatefulWidget {
  final MapController map;
  final LatLng sender;
  final LatLng recv;
  const _ReceiverMapPreview({
    required this.map,
    required this.sender,
    required this.recv,
    super.key,
  });

  @override
  State<_ReceiverMapPreview> createState() => _ReceiverMapPreviewState();
}

class _ReceiverMapPreviewState extends State<_ReceiverMapPreview> {
  static const String _tfStyle = 'atlas';
  static const String _apiKey = 'd7b6821f750e49e2864ef759ef2223ec';

  static const double _kMinZoom = 15;
  static const double _kInitZoom = 16;
  static const double _kMaxZoom = 22;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bounds = LatLngBounds.fromPoints([widget.sender, widget.recv]);
      widget.map.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(20)),
      );
      if (widget.map.camera.zoom < _kMinZoom) {
        widget.map.move(widget.map.camera.center, _kMinZoom);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      Marker(
        point: widget.sender,
        width: 40,
        height: 40,
        child: const Icon(Icons.store, color: Colors.green, size: 38),
      ),
      Marker(
        point: widget.recv,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Text(
            'แผนที่ผู้ส่ง ↔ ผู้รับ',
            style: TextStyle(
              color: Color(0xffff3b30),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Container(
          height: 240,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xffff3b30), width: 3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FlutterMap(
              mapController: widget.map,
              options: MapOptions(
                initialCenter: widget.sender,
                initialZoom: _kInitZoom,
                minZoom: _kMinZoom,
                maxZoom: _kMaxZoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.thunderforest.com/$_tfStyle/{z}/{x}/{y}.png?apikey=$_apiKey',
                  userAgentPackageName: 'com.blink.delivery',
                  maxNativeZoom: 22,
                  maxZoom: _kMaxZoom,
                ),
                MarkerLayer(markers: markers),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                    TextSourceAttribution('Tiles © Thunderforest'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
