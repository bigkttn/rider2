class AddressModel {
  final String id;
  final String address;
  final String latitude;
  final String longitude;

  AddressModel({
    required this.id,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory AddressModel.fromMap(String id, Map<String, dynamic> data) {
    return AddressModel(
      id: id,
      address: data['address'] ?? '',
      latitude: data['latitude']?.toString() ?? '',
      longitude: data['longitude']?.toString() ?? '',
    );
  }
}
