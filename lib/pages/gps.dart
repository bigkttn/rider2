import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class GpsPagState extends StatefulWidget {
  const GpsPagState({super.key});

  @override
  State<GpsPagState> createState() => __GpsPagStateState();
}

class __GpsPagStateState extends State<GpsPagState> {
  var mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('GPS and Map')),
      body: Center(
        child: Column(
          children: [
            FilledButton(
              onPressed: () async {
                var position =
                    await _determinePosition(); //ตัวเรียกใช้พิกัด geolocator
                log(
                  "latitude: ${position.latitude}  longitude:${position.longitude}",
                );
                var latlng = LatLng(position.latitude, position.longitude);
                mapController.move(latlng, 15);
              },
              child: Text('Get GPS'),
            ),
            Expanded(
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: LatLng(15.8700317, 100.99254),
                  initialZoom: 15.0,
                  onTap: (TapPosition, point) {
                    log(point.toString());
                  },
                ),
                children: [
                  TileLayer(
                    // Display map tiles from any source
                    urlTemplate:
                        'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=ae32626403be455d96f52f6bcc1a07be', // OSMF's Tile Server
                    userAgentPackageName: 'com.example.blink_delivery_project',
                    maxNativeZoom:
                        19, // Scale tiles when the server doesn't support higher zoom levels
                    // And many more recommended properties!
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(15.8700317, 100.99254),
                        width: 40,
                        height: 40,
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Container(color: Colors.amber),
                        ),
                        alignment: Alignment.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}
