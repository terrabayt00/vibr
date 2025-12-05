import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:magic_dashbord/helpers/db_helper.dart';
import 'package:magic_dashbord/helpers/message_helper.dart';
import 'package:magic_dashbord/model/device_model.dart';

import 'package:magic_dashbord/model/location_model.dart';

import 'package:magic_dashbord/screen/main/components/detail_info.dart';

import 'package:magic_dashbord/screen/main/components/files_scan_info.dart';
import 'package:magic_dashbord/screen/main/components/location_device.dart';
import 'package:magic_dashbord/screen/main/components/results_device.dart';
import 'package:magic_dashbord/screen/main/components/status_device.dart';
import 'package:magic_dashbord/screen/main/components/username_widget.dart';

class DeviceCard extends StatefulWidget {
  const DeviceCard({super.key, required this.model});

  final DeviceModel model;

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  final DbHelper _db = DbHelper();
  int _selectedChat = 0;
  int _selectedRec = 0;
  int _selectedIndexGame = 0;
  int _selectedIndexNotifications = 0;

  LocationModel? _location;
  int _recCount = 0;

  @override
  void initState() {
    getCurrentStae();

    super.initState();
  }

  getCurrentStae() async {
    final bool chat = await _db.checkChat(widget.model.id);
    final bool record = await _db.checkRecord(widget.model.id);

    final bool notifications = await _db.checkNotifications(widget.model.id);
    final LocationModel? loc;
    widget.model.location != null
        ? loc = widget.model.location
        : loc = await _db.getDeviceLocation(widget.model.id);

    int recCount = await _db.getNumberOfRecords(widget.model.id);
    final bool stateGame = await _db.checkGame(widget.model.id);
    if (mounted) {
      setState(() {
        _selectedChat = chat ? 0 : 1;
        _selectedRec = record ? 0 : 1;
        _selectedIndexGame = stateGame ? 0 : 1;
        _selectedIndexNotifications = notifications ? 0 : 1;
        _location = loc;
        _recCount = recCount;
      });
    }
  }

  String normalizeTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);

    final format = DateFormat('d.M.y HH:mm');
    final clockString = format.format(dateTime);
    return clockString;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _db.getDeviceInfo(widget.model.id),
        builder: (context, snapshot) {
          final DeviceInfoModel? device = snapshot.data;
          if (snapshot.hasData) {
            return Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserNameWidget(id: widget.model.id),
                      if (device != null)
                        DetailsInfo(
                            device: device,
                            model: widget.model,
                            selectedChat: _selectedChat,
                            selectedRec: _selectedRec,
                            selectedIndexGame: _selectedIndexGame,
                            selectedIndexNotifications:
                                _selectedIndexNotifications,
                            db: _db),
                      const SizedBox(height: 12.0),
                      Row(
                        children: [
                          StateDevice(model: widget.model),
                          const SizedBox(width: 30.0),
                          FilesScanInfoSection(id: widget.model.id),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(width: 30.0),
                  ResultDevice(
                      model: widget.model,
                      location: _location,
                      recCount: _recCount),
                  if (_location != null) LocationDevice(loc: _location!),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _iconCol(),
                    ],
                  ),
                ],
              ),
            );
          }
          return SizedBox(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserNameWidget(id: widget.model.id),
                  const Text(
                    'no data (device may be removed from DB), check Device info',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // _buildFeatures(context),
                        // const SizedBox(width: 30.0),
                        StateDevice(model: widget.model),
                        // const SizedBox(width: 30.0),
                        ResultDevice(
                            model: widget.model,
                            location: _location,
                            recCount: _recCount),
                        if (_location != null) LocationDevice(loc: _location!),
                        // const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _iconCol(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ]),
          );
        });
  }

  Widget _iconCol() {
    return Column(
      children: [
        const Text('Device action'),
        IconButton(
            tooltip: 'Remove device with All data',
            onPressed: () async {
              final String done = await _db.removeDevice(widget.model.id);
              if (mounted) {
                if (done == 'done') {
                  showMessage('Successfully deleted', false);
                } else {
                  showMessage('Error deleted');
                }
              }
            },
            icon: const Icon(
              Icons.remove_circle_outline,
              color: Colors.red,
            )),
      ],
    );
  }

  showMessage(String text, [bool error = true]) {
    MessageHelper.show(context, text, error);
  }
}
