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

/// ------------------------------------------------------------
///  Createpage — UI Polished Version
///  - Cleaner AppBar (no avatar), rounded header
///  - Consistent spacing/typography
///  - Reusable SectionCard
///  - Buttons: FilledButton primary, tonal secondary
///  - Address text ellipsis + icons
///  - Receiver section tidy controls
///  - Map inside card with labeled header
/// ------------------------------------------------------------
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

  static const Color kPrimary = Color(0xFFFF3B30);
  static const BorderRadius kRadius = BorderRadius.all(Radius.circular(18));

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

  /// ---------- Firestore loaders ----------
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
          const SnackBar(content: Text('ผู้ส่งยังไม่มีที่อยู่ในระบบ')),
        );
        return;
      }

      if (addrSnap.docs.length > 1) {
        final addresses = addrSnap.docs
            .map((d) => AddressModel.fromMap(d.id, d.data()))
            .toList();

        final selected = await showDialog<AddressModel>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('เลือกที่อยู่ของผู้ส่ง'),
            children: [
              for (final addr in addresses)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, addr),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(addr.address ?? 'ไม่ทราบที่อยู่'),
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
      debugPrint('❌ โหลดข้อมูลผู้ส่งล้มเหลว: $e');
    }
  }

  Future<void> _pickSenderAddressAgain() async {
    if (sender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่ได้โหลดข้อมูลผู้ส่ง')),
      );
      return;
    }
    try {
      final addrSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(sender!.uid)
          .collection('addresses')
          .get();
      if (!mounted) return;
      if (addrSnap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ผู้ส่งยังไม่มีที่อยู่ในระบบ')),
        );
        return;
      }
      final addresses = addrSnap.docs
          .map((d) => AddressModel.fromMap(d.id, d.data()))
          .toList();
      final selected = await showDialog<AddressModel>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('เลือกที่อยู่ของผู้ส่ง (เปลี่ยน)'),
          children: [
            for (final addr in addresses)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, addr),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(addr.address ?? 'ไม่ทราบที่อยู่'),
                ),
              ),
          ],
        ),
      );
      if (selected != null) {
        setState(() => senderAddress = selected);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตที่อยู่ผู้ส่งแล้ว ✅')),
        );
      }
    } catch (e) {
      debugPrint('❌ เปลี่ยนที่อยู่ผู้ส่งล้มเหลว: $e');
    }
  }

  Future<void> _searchReceiverByPhone() async {
    try {
      final phone = phoneSearchCtl.text.trim();
      if (phone.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('กรุณากรอกเบอร์โทรศัพท์')));
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
        ).showSnackBar(SnackBar(content: Text('ไม่พบผู้ใช้ที่มีเบอร์ $phone')));
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
          const SnackBar(content: Text('ผู้รับยังไม่มีที่อยู่ในระบบ')),
        );
        return;
      }

      if (addrSnap.docs.length > 1) {
        final addresses = addrSnap.docs
            .map((d) => AddressModel.fromMap(d.id, d.data()))
            .toList();
        final selected = await showDialog<AddressModel>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('เลือกที่อยู่ของผู้รับ'),
            children: [
              for (final addr in addresses)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, addr),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(addr.address ?? 'ไม่ทราบที่อยู่'),
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
          const SnackBar(content: Text('✅ โหลดข้อมูลผู้รับสำเร็จ')),
        );
      }
    } catch (e) {
      debugPrint('❌ ค้นหาผู้รับล้มเหลว: $e');
    }
  }

  Future<void> _openReceiverPicker() async {
    final snap = await FirebaseFirestore.instance.collection('users').get();
    if (!mounted) return;

    final allUsers = snap.docs
        .where((d) => d.id != sender?.uid)
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
                              color: kPrimary,
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

    final addrSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(chosen.uid)
        .collection('addresses')
        .get();

    if (!mounted) return;
    if (addrSnap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ผู้รับรายนี้ยังไม่มีที่อยู่ในระบบ')),
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
          title: const Text('เลือกที่อยู่ของผู้รับ'),
          children: [
            for (final addr in addresses)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, addr),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(addr.address ?? 'ไม่ทราบที่อยู่'),
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
      const SnackBar(content: Text('✅ เลือกผู้รับจากลิสต์สำเร็จ')),
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
      const cloudName = 'dywfdy174';
      const uploadPreset = 'flutter_upload';
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(await response.stream.bytesToString());
        return jsonData['secure_url'];
      }
      debugPrint('❌ Upload failed: ${response.statusCode}');
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
        backgroundColor: kPrimary,
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          'ส่งสินค้า',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: const [],
      ),
      body: Stack(
        children: [
          Container(color: kPrimary),
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 36),
                    if (isCreate) _buildSenderInfo(),
                    if (isCreate) _buildReceiverSection(),
                    if (isCreate) _buildProductForm(),
                    if (!isCreate)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => setState(() => isCreate = true),
                            icon: const Icon(Icons.add_box_outlined),
                            label: const Text('สร้างรายการใหม่'),
                            style: FilledButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ),
                      ),
                    if (items.isNotEmpty) _buildItemList(),
                    const SizedBox(height: 24),
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
              'สร้างรายการส่งสินค้า',
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: sender?.imageUrl.isNotEmpty == true
                      ? NetworkImage(sender!.imageUrl)
                      : const AssetImage('assets/avatar.png') as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sender?.fullname ?? 'ไม่พบชื่อผู้ส่ง',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.place,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              senderAddress?.address ?? 'ไม่มีที่อยู่',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _pickSenderAddressAgain,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('เปลี่ยนที่อยู่ผู้ส่ง'),
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiverSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: 'ผู้รับสินค้า'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _openReceiverPicker,
                    icon: const Icon(Icons.list_alt),
                    label: const Text('เลือกรายชื่อ'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                      prefixIcon: const Icon(Icons.phone, color: kPrimary),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _searchReceiverByPhone,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (receiver != null)
              Card(
                elevation: 0,
                color: Colors.grey[50],
                shape: RoundedRectangleBorder(borderRadius: kRadius),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: receiver!.imageUrl.isNotEmpty
                            ? NetworkImage(receiver!.imageUrl)
                            : const AssetImage('assets/avatar.png')
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('โทร: ${receiver!.phone}'),
                            Text('อีเมล: ${receiver!.email}'),
                            Text(
                              'ที่อยู่: ${receiverAddress?.address ?? '-'}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (receiverAddress != null && senderAddress != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SectionCard(
                  dense: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(title: 'แผนที่ผู้ส่ง ↔ ผู้รับ'),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: kRadius,
                        child: SizedBox(
                          height: 220,
                          child: _ReceiverMapPreview(
                            map: _map,
                            sender: LatLng(
                              double.tryParse(senderAddress!.latitude ?? '') ??
                                  0,
                              double.tryParse(senderAddress!.longitude ?? '') ??
                                  0,
                            ),
                            recv: LatLng(
                              double.tryParse(
                                    receiverAddress!.latitude ?? '',
                                  ) ??
                                  0,
                              double.tryParse(
                                    receiverAddress!.longitude ?? '',
                                  ) ??
                                  0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: 'เพิ่มสินค้า'),
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 300,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: kRadius,
                ),
                child: pickedFile == null
                    ? const Icon(Icons.image, size: 56)
                    : ClipRRect(
                        borderRadius: kRadius,
                        child: Image.file(pickedFile!, fit: BoxFit.cover),
                      ),
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
                  child: const Text('ถ่ายรูป'),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: () async {
                    await pickFromGallery();
                    if (pickedFile != null) {
                      _imageUrl = await uploadImage(pickedFile!);
                      setState(() {});
                    }
                  },
                  child: const Text('อัปโหลดจากเครื่อง'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: detailCtl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'รายละเอียดสินค้า',
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
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
                      const SnackBar(
                        content: Text('กรอกข้อมูลให้ครบก่อนเพิ่ม'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('เพิ่มสินค้าในรายการ'),
                style: FilledButton.styleFrom(shape: const StadiumBorder()),
              ),
            ),
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: FilledButton(
                    onPressed: _saveAllToFirestore,
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('บันทึกรายการทั้งหมด ✅'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: 'รายการที่เพิ่มแล้ว'),
            const SizedBox(height: 8),
            for (int i = 0; i < items.length; i++)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: kRadius),
                child: ListTile(
                  leading: items[i]['imageUrl'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            items[i]['imageUrl'],
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.image),
                  title: Text(items[i]['detail']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => setState(() => items.removeAt(i)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAllToFirestore() async {
    if (sender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังโหลดข้อมูลผู้ส่งไม่เสร็จ')),
      );
      return;
    }
    if (receiver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาค้นหาหรือเลือกรายชื่อผู้รับ')),
      );
      return;
    }
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ยังไม่มีสินค้าในรายการ')));
      return;
    }
    if (senderAddress?.latitude == null ||
        senderAddress?.longitude == null ||
        receiverAddress?.latitude == null ||
        receiverAddress?.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบพิกัดของผู้ส่งหรือผู้รับ')),
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
    ).showSnackBar(const SnackBar(content: Text('บันทึกรายการสำเร็จ 🎉')));
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

    return FlutterMap(
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
    );
  }
}

/// ---------- UI Helpers ----------
class SectionCard extends StatelessWidget {
  final Widget child;
  final bool dense;
  const SectionCard({super.key, required this.child, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: _CreatepageState.kRadius),
      child: Padding(padding: EdgeInsets.all(dense ? 10 : 14), child: child),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 18,
          decoration: BoxDecoration(
            color: _CreatepageState.kPrimary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
