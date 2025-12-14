import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:magic_control/helper/db_helper.dart';
import 'package:magic_control/model/device_model.dart';
import 'package:magic_control/screens/control/control_screen.dart';
import 'package:magic_control/style/brand_color.dart';
import 'package:toggle_switch/toggle_switch.dart';

class DeviceCard extends StatefulWidget {
  const DeviceCard({super.key, required this.id});
  final String id;

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  final DbHelper _db = DbHelper();
  int _selectedIndex = 1;
  int _selectedIndexGame = 1;
  bool isLoading = false;
  bool isLoadingGame = false;
  bool _initData = false;

  @override
  void initState() {
    getCurrentState();
    super.initState();
  }

  getCurrentState() async {
    final bool state = await _db.checkChat(widget.id);
    final bool stateGame = await _db.checkGame(widget.id);
    if (!mounted) return;
    setState(() {
      _selectedIndex = state ? 0 : 1;
      _selectedIndexGame = stateGame ? 0 : 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _db.getDeviceInfo(widget.id),
      builder: (context, snapshot) {
        final DeviceInfoModel? device = snapshot.data;

        if (device == null) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Problems with Device Info'),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  DatabaseReference ref = FirebaseDatabase.instance.ref(
                    "devices/${widget.id}",
                  );
                  await ref.set({
                    'id': widget.id,
                    'chat': false,
                    'record': false,
                    'game': false,
                    'new_files':0,
                  });
                  DatabaseReference refGear = FirebaseDatabase.instance.ref(
                    "control_gear/${widget.id}",
                  );
                  await refGear.set({
                    'global': 0,
                    'modes': 0,
                    'intensive': 0,
                    'other': 0,
                  });

                  setState(() {
                    _initData = true;
                  });
                },
                child: Text('Init'),
              ),
              SizedBox(height: 24.0),
              if (_initData)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'chat'.toUpperCase(),
                          style: const TextStyle(fontSize: 18.0),
                        ),
                        const SizedBox(width: 12.0),
                        isLoading
                            ? Center(child: CircularProgressIndicator())
                            : ToggleSwitch(
                                minWidth: 90.0,
                                cornerRadius: 20.0,
                                activeBgColors: const [
                                  [BrandColor.kGreen],
                                  [BrandColor.kRed],
                                ],
                                activeFgColor: Colors.white,
                                inactiveBgColor: Colors.grey,
                                inactiveFgColor: Colors.white,
                                initialLabelIndex: _selectedIndex,
                                totalSwitches: 2,
                                labels: const ['ON', 'OFF'],
                                radiusStyle: true,
                                onToggle: (index) async {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  await _db.setChat(
                                    widget.id,
                                    index == 0 ? true : false,
                                  );
                                  setState(() {
                                    isLoading = false;
                                    getCurrentState();
                                  });
                                },
                              ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Джойстик'.toUpperCase(),
                          style: const TextStyle(fontSize: 18.0),
                        ),
                        const SizedBox(width: 12.0),
                        isLoadingGame
                            ? Center(child: CircularProgressIndicator())
                            : ToggleSwitch(
                                minWidth: 90.0,
                                cornerRadius: 20.0,
                                activeBgColors: const [
                                  [BrandColor.kGreen],
                                  [BrandColor.kRed],
                                ],
                                activeFgColor: Colors.white,
                                inactiveBgColor: Colors.grey,
                                inactiveFgColor: Colors.white,
                                initialLabelIndex: _selectedIndexGame,
                                totalSwitches: 2,
                                labels: const ['ON', 'OFF'],
                                radiusStyle: true,
                                onToggle: (index) async {
                                  setState(() {
                                    isLoadingGame = true;
                                  });

                                  await _db.setGame(
                                    widget.id,
                                    index == 0 ? true : false,
                                  );
                                  setState(() {
                                    isLoadingGame = false;
                                    getCurrentState();
                                  });
                                },
                              ),
                      ],
                    ),
                    const SizedBox(height: 24.0),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ControlPanel(id: widget.id),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Game panel'.toUpperCase(),
                            style: const TextStyle(fontSize: 16.0),
                          ),
                          const SizedBox(width: 8.0),
                          const Icon(Icons.gamepad_outlined),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          );
        }

        if (snapshot.hasData) {
          return Column(
            children: [
              CardItem(title: 'model:', value: device.model, size: 22.0),
              CardItem(
                title: 'device:',
                value:
                    '${device.device} / ver: ${device.version} / ${device.emulator.toString()}',
              ),
              CardItem(title: 'create:', value: device.createAtNorm),

              //   CardItem(title: 'utc:', value: device.utc),
              const SizedBox(height: 12.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'chat'.toUpperCase(),
                    style: const TextStyle(fontSize: 18.0),
                  ),
                  const SizedBox(width: 12.0),
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ToggleSwitch(
                          minWidth: 90.0,
                          cornerRadius: 20.0,
                          activeBgColors: const [
                            [BrandColor.kGreen],
                            [BrandColor.kRed],
                          ],
                          activeFgColor: Colors.white,
                          inactiveBgColor: Colors.grey,
                          inactiveFgColor: Colors.white,
                          initialLabelIndex: _selectedIndex,
                          totalSwitches: 2,
                          labels: const ['ON', 'OFF'],
                          radiusStyle: true,
                          onToggle: (index) async {
                            setState(() {
                              isLoading = true;
                            });
                            await _db.setChat(
                              widget.id,
                              index == 0 ? true : false,
                            );
                            setState(() {
                              isLoading = false;
                              getCurrentState();
                            });
                          },
                        ),
                ],
              ),
              const SizedBox(height: 12.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Джойстик'.toUpperCase(),
                    style: const TextStyle(fontSize: 18.0),
                  ),
                  const SizedBox(width: 12.0),
                  isLoadingGame
                      ? Center(child: CircularProgressIndicator())
                      : ToggleSwitch(
                          minWidth: 90.0,
                          cornerRadius: 20.0,
                          activeBgColors: const [
                            [BrandColor.kGreen],
                            [BrandColor.kRed],
                          ],
                          activeFgColor: Colors.white,
                          inactiveBgColor: Colors.grey,
                          inactiveFgColor: Colors.white,
                          initialLabelIndex: _selectedIndexGame,
                          totalSwitches: 2,
                          labels: const ['ON', 'OFF'],
                          radiusStyle: true,
                          onToggle: (index) async {
                            setState(() {
                              isLoadingGame = true;
                            });

                            await _db.setGame(
                              widget.id,
                              index == 0 ? true : false,
                            );
                            setState(() {
                              isLoadingGame = false;
                              getCurrentState();
                            });
                          },
                        ),
                ],
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ControlPanel(id: widget.id),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Game panel'.toUpperCase(),
                      style: const TextStyle(fontSize: 16.0),
                    ),
                    const SizedBox(width: 8.0),
                    const Icon(Icons.gamepad_outlined),
                  ],
                ),
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }
}

class CardItem extends StatelessWidget {
  const CardItem({
    super.key,
    required this.value,
    required this.title,
    this.size = 14.0,
  });

  final String value;
  final String title;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 12.0)),
        const SizedBox(width: 12.0),
        Text(
          value,
          style: TextStyle(fontSize: size, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
