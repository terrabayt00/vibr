import 'package:flutter/material.dart';
import 'package:magic_dashbord/model/control_model.dart';

import 'custom_label.dart';
import 'gear_grid_view.dart';

class ButtonGrid extends StatefulWidget {
  const ButtonGrid({super.key, required this.model});
  final ControlModel model;

  @override
  State<ButtonGrid> createState() => _ButtonGridState();
}

class _ButtonGridState extends State<ButtonGrid> {
  Widget _buildControl() {
    ControlModel model = widget.model;
    return SingleChildScrollView(
      child: Column(
        children: [
          const CustomLabel(text: 'Общие'),
          GearGridView(
            items: vibratorGlobal,
            cat: 'Общие',
            selectedCard: model.global,
          ),
          const CustomLabel(text: 'Режимы вибрации'),
          GearGridView(
            items: vibratorModes,
            cat: 'Режимы вибрации',
            selectedCard: model.modes,
          ),
          const CustomLabel(text: 'Интенсивность вибрации'),
          GearGridView(
            items: vibratorIntensive,
            cat: 'Интенсивность вибрации',
            selectedCard: model.intensive,
          ),
          const CustomLabel(text: 'Другие'),
          GearGridView(
            items: vibratorOther,
            cat: 'Другие',
            selectedCard: model.other,
          ),
          const SizedBox(height: 30.0),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildControl();
  }
}
