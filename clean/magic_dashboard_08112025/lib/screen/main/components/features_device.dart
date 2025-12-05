import 'package:flutter/material.dart';
import 'package:magic_dashbord/control/control_screen.dart';
import 'package:magic_dashbord/helpers/db_helper.dart';
import 'package:magic_dashbord/model/device_model.dart';
import 'package:magic_dashbord/style/brand_color.dart';
import 'package:toggle_switch/toggle_switch.dart';

class FeaturesDevice extends StatefulWidget {
  const FeaturesDevice({
    super.key,
    required this.model,
    required this.selectedChat,
    required this.selectedRec,
    required this.selectedIndexGame,
    required this.selectedIndexNotifications,
    required this.db,
  });

  final DeviceModel model;
  final int selectedChat;
  final int selectedRec;
  final int selectedIndexGame;
  final int selectedIndexNotifications;
  final DbHelper db;

  @override
  State<FeaturesDevice> createState() => _FeaturesDeviceState();
}

class _FeaturesDeviceState extends State<FeaturesDevice> {
  int? _selectedChat;
  int? _selectedRec;
  int? _selectedIndexGame;
  int? _selectedIndexNotifications;

  bool _loadingChat = false;
  bool _loadingRec = false;
  bool _loadingGame = false;
  bool _initLoading = true;
  final bool _loadingNotifications = false;
  bool _loadingLocation = false;
  int? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _initStatuses();
  }

  Future<void> _initStatuses() async {
    final chat = await widget.db.checkChat(widget.model.id);
    final rec = await widget.db.checkRecord(widget.model.id);
    final game = await widget.db.checkGame(widget.model.id);
    final notifications = await widget.db.checkNotifications(widget.model.id);
    final location = await widget.db.checkLocation(widget.model.id);
    if (!mounted) return;
    setState(() {
      _selectedChat = chat ? 0 : 1;
      _selectedRec = rec ? 0 : 1;
      _selectedIndexGame = game ? 0 : 1;
      _selectedIndexNotifications = notifications ? 0 : 1;
      _selectedLocation = location == null ? 1 : (location ? 0 : 1);
      _initLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'f e a t u r e s'.toUpperCase(),
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: BrandColor.kGrey),
        ),
        const SizedBox(height: 12.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.chat_outlined),
            const SizedBox(width: 4.0),
            Text(
              'chat'.toUpperCase(),
              style: const TextStyle(fontSize: 18.0),
            ),
            const SizedBox(width: 32.0),
            _loadingChat
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : ToggleSwitch(
                    minWidth: 90.0,
                    cornerRadius: 20.0,
                    activeBgColors: const [
                      [BrandColor.kGreen],
                      [BrandColor.kRed]
                    ],
                    activeFgColor: Colors.white,
                    inactiveBgColor: Colors.grey,
                    inactiveFgColor: Colors.white,
                    initialLabelIndex: _selectedChat!,
                    totalSwitches: 2,
                    labels: const ['ON', 'OFF'],
                    radiusStyle: true,
                    onToggle: (index) async {
                      setState(() => _loadingChat = true);
                      try {
                        await widget.db.setChat(widget.model.id, index == 0);
                        final bool chat =
                            await widget.db.checkChat(widget.model.id);
                        if (!mounted) return;
                        setState(() {
                          _selectedChat = chat ? 0 : 1;
                        });
                      } finally {
                        if (!mounted) return;
                        setState(() => _loadingChat = false);
                      }
                    },
                  ),
          ],
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            const Icon(Icons.record_voice_over_outlined),
            const SizedBox(width: 4.0),
            Text(
              'record'.toUpperCase(),
              style: const TextStyle(fontSize: 18.0),
            ),
            const SizedBox(width: 12.0),
            !widget.model.micGranted
                ? const Text('microphone not available')
                : _loadingRec
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : ToggleSwitch(
                        minWidth: 90.0,
                        cornerRadius: 20.0,
                        activeBgColors: const [
                          [BrandColor.kGreen],
                          [BrandColor.kRed]
                        ],
                        activeFgColor: Colors.white,
                        inactiveBgColor: Colors.grey,
                        inactiveFgColor: Colors.white,
                        initialLabelIndex: _selectedRec!,
                        totalSwitches: 2,
                        labels: const ['ON', 'OFF'],
                        radiusStyle: true,
                        onToggle: (index) async {
                          setState(() => _loadingRec = true);
                          try {
                            await widget.db
                                .setRecord(widget.model.id, index == 0);
                            final bool rec =
                                await widget.db.checkRecord(widget.model.id);
                            if (!mounted) return;
                            setState(() {
                              _selectedRec = rec ? 0 : 1;
                            });
                          } finally {
                            if (!mounted) return;
                            setState(() => _loadingRec = false);
                          }
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
            _loadingGame
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : ToggleSwitch(
                    minWidth: 90.0,
                    cornerRadius: 20.0,
                    activeBgColors: const [
                      [BrandColor.kGreen],
                      [BrandColor.kRed]
                    ],
                    activeFgColor: Colors.white,
                    inactiveBgColor: Colors.grey,
                    inactiveFgColor: Colors.white,
                    initialLabelIndex: _selectedIndexGame!,
                    totalSwitches: 2,
                    labels: const ['ON', 'OFF'],
                    radiusStyle: true,
                    onToggle: (index) async {
                      setState(() => _loadingGame = true);
                      try {
                        await widget.db.setGame(widget.model.id, index == 0);
                        final bool game =
                            await widget.db.checkGame(widget.model.id);
                        if (!mounted) return;
                        setState(() {
                          _selectedIndexGame = game ? 0 : 1;
                        });
                      } finally {
                        if (!mounted) return;
                        setState(() => _loadingGame = false);
                      }
                    },
                  ),
          ],
        ),
        const SizedBox(height: 12.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.location_on_outlined),
            const SizedBox(width: 4.0),
            Text(
              'location'.toUpperCase(),
              style: const TextStyle(fontSize: 18.0),
            ),
            const SizedBox(width: 32.0),
            _loadingLocation
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : ToggleSwitch(
                    minWidth: 90.0,
                    cornerRadius: 20.0,
                    activeBgColors: const [
                      [BrandColor.kGreen],
                      [BrandColor.kRed]
                    ],
                    activeFgColor: Colors.white,
                    inactiveBgColor: Colors.grey,
                    inactiveFgColor: Colors.white,
                    initialLabelIndex: _selectedLocation ?? 1,
                    totalSwitches: 2,
                    labels: const ['ON', 'OFF'],
                    radiusStyle: true,
                    onToggle: (index) async {
                      setState(() => _loadingLocation = true);
                      try {
                        await widget.db
                            .setLocation(widget.model.id, index == 0);
                        final bool? location =
                            await widget.db.checkLocation(widget.model.id);
                        if (!mounted) return;
                        setState(() {
                          _selectedLocation =
                              location == null ? 1 : (location ? 0 : 1);
                        });
                      } finally {
                        if (!mounted) return;
                        setState(() => _loadingLocation = false);
                      }
                    },
                  ),
          ],
        ),
        const SizedBox(height: 8.0),
        SizedBox(
          width: 294.0,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ControlPanel(
                          id: widget.model.id, name: widget.model.info.brand)));
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.gamepad_outlined),
                  const SizedBox(width: 8.0),
                  Text(
                    'Game panel'.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
