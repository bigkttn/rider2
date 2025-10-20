import 'dart:convert';
import 'dart:io';
import 'package:blink_delivery_project/model/address_model.dart';
import 'package:blink_delivery_project/model/get_user_re.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class Createpage extends StatefulWidget {
  final String uid;
  const Createpage({super.key, required this.uid});

  @override
  State<Createpage> createState() => _CreatepageState();
}

class _CreatepageState extends State<Createpage> {
  final TextEditingController _searchController = TextEditingController();
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

  /// ✅ เก็บสินค้าในรูปแบบ array
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _loadSender();
  }

  /// ✅ โหลดข้อมูลผู้ส่ง (รองรับหลายที่อยู่)
  Future<void> _loadSender() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid.trim())
          .get();

      if (userDoc.exists) {
        sender = UserModel.fromMap(userDoc.id, userDoc.data()!);
      }

      final addrSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid.trim())
          .collection('addresses')
          .get();

      if (addrSnap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ผู้ส่งยังไม่มีที่อยู่ในระบบ")),
        );
        return;
      }

      // 🔹 ถ้ามีหลายที่อยู่ ให้เลือกจาก Dialog
      if (addrSnap.docs.length > 1) {
        List<AddressModel> addresses = addrSnap.docs
            .map((d) => AddressModel.fromMap(d.id, d.data()))
            .toList();

        AddressModel? selected = await showDialog<AddressModel>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text("เลือกที่อยู่ของผู้ส่ง"),
            children: [
              for (var addr in addresses)
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
          return; // ถ้ากดยกเลิก
        }
      } else {
        senderAddress = AddressModel.fromMap(
          addrSnap.docs.first.id,
          addrSnap.docs.first.data(),
        );
      }

      setState(() {});
    } catch (e) {
      print("❌ โหลดข้อมูลผู้ส่งล้มเหลว: $e");
    }
  }

  /// ✅ ค้นหาผู้รับด้วยเบอร์โทร
  Future<void> _searchReceiverByPhone() async {
    try {
      String phone = phoneSearchCtl.text.trim();
      if (phone.isEmpty) {
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

      if (userSnap.docs.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("ไม่พบผู้ใช้ที่มีเบอร์ $phone")));
        return;
      }

      final userDoc = userSnap.docs.first;
      receiver = UserModel.fromMap(userDoc.id, userDoc.data());

      // 🔹 โหลดทุกที่อยู่ของผู้รับ
      final addrSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .collection('addresses')
          .get();

      if (addrSnap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ผู้รับยังไม่มีที่อยู่ในระบบ")),
        );
        return;
      }

      // 🔹 ถ้ามีหลายที่อยู่ ให้เลือกจาก Dialog
      if (addrSnap.docs.length > 1) {
        List<AddressModel> addresses = addrSnap.docs
            .map((d) => AddressModel.fromMap(d.id, d.data()))
            .toList();

        AddressModel? selected = await showDialog<AddressModel>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text("เลือกที่อยู่ของผู้รับ"),
            children: [
              for (var addr in addresses)
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
          return; // กดยกเลิก
        }
      } else {
        receiverAddress = AddressModel.fromMap(
          addrSnap.docs.first.id,
          addrSnap.docs.first.data(),
        );
      }

      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ โหลดข้อมูลผู้รับสำเร็จ")));
    } catch (e) {
      print("❌ ค้นหาผู้รับล้มเหลว: $e");
    }
  }

  Future<void> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => pickedFile = File(image.path));
  }

  Future<void> pickFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) setState(() => pickedFile = File(image.path));
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      const cloudName = "dywfdy174";
      const uploadPreset = "flutter_upload";
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      var request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(await response.stream.bytesToString());
        return jsonData['secure_url'];
      } else {
        print("❌ Upload failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print('❌ Upload Error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    detailCtl.dispose();
    _searchController.dispose();
    phoneSearchCtl.dispose();
    super.dispose();
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
                    if (isCreate) _buildReceiverSearch(),
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

  /// ✅ แสดงข้อมูลผู้ส่ง
  Widget _buildSenderInfo() {
    return Padding(
      padding: const EdgeInsets.only(left: 30.0, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                          : const AssetImage("assets/avatar.png")
                                as ImageProvider,
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
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _loadSender,
            icon: const Icon(Icons.location_on),
            label: const Text("เปลี่ยนที่อยู่ผู้ส่ง"),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xffff3b30),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ ช่องค้นหาผู้รับ
  Widget _buildReceiverSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: phoneSearchCtl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'ค้นหาผู้รับด้วยเบอร์โทรศัพท์',
              prefixIcon: const Icon(Icons.phone, color: Color(0xffff3b30)),
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
          if (receiver != null)
            Card(
              margin: const EdgeInsets.only(top: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: receiver!.imageUrl.isNotEmpty
                      ? NetworkImage(receiver!.imageUrl)
                      : const AssetImage("assets/avatar.png") as ImageProvider,
                ),
                title: Text(receiver!.fullname),
                subtitle: Text(receiverAddress?.address ?? 'ไม่มีที่อยู่'),
              ),
            ),
        ],
      ),
    );
  }

  /// ✅ แบบฟอร์มสินค้า
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

  /// ✅ บันทึกทั้งหมดลง Firestore
  Future<void> _saveAllToFirestore() async {
    if (sender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ยังโหลดข้อมูลผู้ส่งไม่เสร็จ")),
      );
      return;
    }

    if (receiver == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณาค้นหาผู้รับก่อน")));
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

    var ordersData = {
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

    DocumentReference docRef = await FirebaseFirestore.instance
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
}
