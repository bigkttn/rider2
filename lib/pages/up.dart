import 'dart:convert';
import 'dart:io' show File;

import 'package:http/http.dart' as http;

Future<String?> uploadToCloudinary(File imageFile) async {
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
      var responseData = await response.stream.bytesToString();
      var jsonData = jsonDecode(responseData);
      return jsonData['secure_url']; // ✅ ได้ URL กลับมา
    } else {
      return null;
    }
  } catch (e) {
    print("Upload error: $e");
    return null;
  }
}
