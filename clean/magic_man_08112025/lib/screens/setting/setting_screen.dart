import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:magic/screens/setting/swith_item.dart';

import 'package:magic/style/color/brand_color.dart';
import 'package:magic/style/color/brand_text.dart';

import '../../widgets/custom_circle.dart';
import 'item_data.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildRow(
                  context,
                  ItemData(
                      title: 'Регулировка интенсивности', value: 'Средний')),
              const SwithItemButton(),
              ...items.map((item) => _buildRow(context, item)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, ItemData item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              item.title,
              overflow: TextOverflow.ellipsis,
              style: BrandText.sTitle,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                item.value,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: BrandText.sRed,
              ),
              const SizedBox(width: 4.0),
              const Icon(
                Icons.arrow_forward_ios_outlined,
                color: BrandColor.kText,
              )
            ],
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: GestureDetector(
        onTap: () => ZoomDrawer.of(context)!.toggle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 4,
              child: Text(
                'Настройки',
                style: const TextStyle(
                  color: BrandColor.kText,
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(
              flex: 1,
            ),
            Stack(
              alignment: Alignment.center,
              children: const [
                PercentageColorCircle(
                  size: 30.0,
                  color: BrandColor.kRedLight,
                  percent: 100,
                ),
                PercentageColorCircle(
                  size: 32.0,
                  color: BrandColor.kRed,
                  percent: 25,
                  isSmall: true,
                ),
              ],
            ),
            const SizedBox(width: 18.0),
          ],
        ),
      ),
    );
  }
}
