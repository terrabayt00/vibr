import 'package:flutter/material.dart';
import 'package:magic_dashbord/model/location_model.dart';
import 'package:magic_dashbord/screen/maps.dart';

class LocationDevice extends StatelessWidget {
  const LocationDevice({super.key, required this.loc});
  final LocationModel loc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: SizedBox(
          height: MediaQuery.of(context).size.width * 0.1,
          width: MediaQuery.of(context).size.width * 0.2,
          child: MyMap(
            latitude: loc.lat,
            longitude: loc.lng,
          ),
        ),
      ),
    );
  }
}
