import 'package:flutter/material.dart';
import 'package:magic_dashbord/helpers/db_helper.dart';
import 'package:magic_dashbord/model/device_model.dart';
import 'package:magic_dashbord/screen/main/components/card_item.dart';
import 'package:magic_dashbord/screen/main/components/features_device.dart';

class DetailsInfo extends StatelessWidget {
  const DetailsInfo(
      {super.key,
      required this.device,
      required this.model,
      required this.selectedChat,
      required this.selectedRec,
      required this.selectedIndexGame,
      required this.selectedIndexNotifications,
      required this.db});
  final DeviceInfoModel device;
  final DeviceModel model;
  final int selectedChat;
  final int selectedRec;
  final int selectedIndexGame;
  final int selectedIndexNotifications;
  final DbHelper db;

  @override
  Widget build(BuildContext context) {
    print('device: ${model.micGranted}');
    final IfconfigModel? ifconfig = device.ifconfig ?? model.ifconfig;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardItem(title: 'brand:', value: device.brand, size: 18.0),
            CardItem(title: 'model:', value: device.model, size: 16.0),
            CardItem(title: 'id:', value: model.id, size: 12.0),
            CardItem(
                title: 'device:',
                value:
                    '${device.device} / ver: ${device.version} / ${device.emulator.toString()}'),
            CardItem(title: 'create:', value: device.createAtNorm),
            CardItem(title: 'ip:', value: device.ip),
            if (ifconfig != null) ...[
              CardItem(
                  title: 'ip_decimal:', value: ifconfig.ipDecimal.toString()),
              CardItem(title: 'country:', value: ifconfig.country),
              CardItem(title: 'country_iso:', value: ifconfig.countryIso),
              CardItem(
                  title: 'country_eu:', value: ifconfig.countryEu.toString()),
              CardItem(title: 'region_name:', value: ifconfig.regionName),
              CardItem(title: 'region_code:', value: ifconfig.regionCode),
              CardItem(title: 'zip_code:', value: ifconfig.zipCode),
              CardItem(title: 'city:', value: ifconfig.city),
              CardItem(title: 'latitude:', value: ifconfig.latitude.toString()),
              CardItem(
                  title: 'longitude:', value: ifconfig.longitude.toString()),
              CardItem(title: 'time_zone:', value: ifconfig.timeZone),
              CardItem(title: 'asn:', value: ifconfig.asn),
              CardItem(title: 'asn_org:', value: ifconfig.asnOrg),
              CardItem(title: 'hostname:', value: ifconfig.hostname),
              CardItem(
                  title: 'user_agent:', value: ifconfig.userAgent.rawValue),
            ],
          ],
        ),
        //   CardItem(title: 'utc:', value: device.utc),
        const SizedBox(width: 30.0),
        FeaturesDevice(
          model: model,
          selectedChat: selectedChat,
          selectedRec: selectedRec,
          selectedIndexGame: selectedIndexGame,
          selectedIndexNotifications: selectedIndexNotifications,
          db: db,
        ),
      ],
    );
  }
}
