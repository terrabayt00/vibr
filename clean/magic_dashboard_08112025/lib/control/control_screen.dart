import 'package:flutter/material.dart';
import 'package:magic_dashbord/control/components/button_grid.dart';
import 'package:magic_dashbord/helpers/db_helper.dart';
import 'package:magic_dashbord/model/control_model.dart';
import 'package:magic_dashbord/style/brand_color.dart';

class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key, required this.id, required this.name});
  final String id;
  final String name;

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  final DbHelper _db = DbHelper();
  String name = '';
  @override
  void initState() {
    name = widget.name;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
            title: Text(
              'Magic control:$name',
              style: const TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            backgroundColor: BrandColor.kRed),
        body: StreamBuilder(
            stream: _db.fetchDeviceData(widget.id),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                ControlModel model = snapshot.data;

                return ButtonGrid(model: model);
              }
              return const Column();
            }),
      ),
    );
  }
}
