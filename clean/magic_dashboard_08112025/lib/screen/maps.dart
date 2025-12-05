import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MyMap extends StatefulWidget {
  final double latitude;
  final double longitude;

  const MyMap({super.key, required this.latitude, required this.longitude});

  @override
  State createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  late final LatLng center = LatLng(widget.latitude, widget.longitude);
  late final List<Marker> markers;

  @override
  void initState() {
    super.initState();
    markers = [
      Marker(
        point: center,
        child: const Icon(
          Icons.location_on,
          color: Colors.red,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          tileProvider: NetworkTileProvider(),
        ),
        MarkerLayer(
          markers: markers,
        ),
      ],
    );
  }
}
