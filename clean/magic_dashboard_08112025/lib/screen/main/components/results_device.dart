import 'package:flutter/material.dart';
import 'package:magic_dashbord/model/device_model.dart';
import 'package:magic_dashbord/model/location_model.dart';
import 'package:magic_dashbord/screen/main/components/contacts_info.dart';
import 'package:magic_dashbord/screen/main/components/file_info_widget.dart';
import 'package:magic_dashbord/style/brand_color.dart';

class ResultDevice extends StatelessWidget {
  const ResultDevice(
      {super.key, required this.model, this.location, required this.recCount});
  final DeviceModel model;
  final LocationModel? location;
  final int recCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'r e s u l t'.toUpperCase(),
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: BrandColor.kGrey),
        ),
        const SizedBox(height: 12.0),
        FileInfoWidget(id: model.id),
        const SizedBox(height: 8.0),
        ContactsInfoWidget(id: model.id),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.gps_fixed_outlined),
            const SizedBox(width: 4.0),
            const Text('Location:'),
            const SizedBox(width: 4.0),
            if (location != null)
              Text(
                '${location!.lat}, ${location!.lng}',
                style: const TextStyle(
                    fontSize: 20.0, fontWeight: FontWeight.bold),
              )
          ],
        ),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.record_voice_over_outlined),
            const SizedBox(width: 4.0),
            const Text('Records:'),
            const SizedBox(width: 4.0),
            Text(
              recCount.toString(),
              style:
                  const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
