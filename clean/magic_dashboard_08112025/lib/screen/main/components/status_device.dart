import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:magic_dashbord/model/device_model.dart';
import 'package:magic_dashbord/screen/main/components/card_item.dart';
import 'package:magic_dashbord/screen/main/components/device_card.dart';

class StateDevice extends StatelessWidget {
  const StateDevice({super.key, required this.model});
  final DeviceModel model;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CardItem(
            title: 'online',
            value: model.lastOnline.isEmpty
                ? ''
                : normalizeTime(model.lastOnline)),
        Text(
          'S t a t u s:'.toUpperCase(),
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
        CardItem(title: 'connection:', value: model.connectivityState),
        CardItem(title: 'record:', value: model.recordingStatus),
        const SizedBox(height: 8.0),
        Text(
          'P e r m i s s i o n s:'.toUpperCase(),
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
        CardItem(title: 'contact:', value: model.contactsGranted.toString()),
        CardItem(title: 'file:', value: model.filesGranted.toString()),
        CardItem(title: 'location:', value: model.locationGranted.toString()),
        CardItem(title: 'microphone:', value: model.micGranted.toString()),
      ],
    );
  }
}

String normalizeTime(String dateTimeString) {
  final dateTime = DateTime.parse(dateTimeString);

  final format = DateFormat('d.M.y HH:mm');
  final clockString = format.format(dateTime);
  return clockString;
}
