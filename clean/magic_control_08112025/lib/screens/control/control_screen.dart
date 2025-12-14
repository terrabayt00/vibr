import 'package:flutter/material.dart';
import 'package:magic_control/helper/db_helper.dart';
import 'package:magic_control/model/control_model.dart';
import 'package:magic_control/screens/control/components/button_grid.dart';
import 'package:magic_control/style/brand_color.dart';

class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key, required this.id});
  final String id;

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  final DbHelper _db = DbHelper();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
            title: const Text(
              'Magic control',
              style: TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            backgroundColor: BrandColor.kRed),
        body: StreamBuilder(
            stream: _db.fetchDeviceData(widget.id),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                ControlModel model = snapshot.data;

                return ButtonGrid(model: model, sessionId: widget.id);
              }
              return const Column();
            }),
      ),
    );
  }
}
