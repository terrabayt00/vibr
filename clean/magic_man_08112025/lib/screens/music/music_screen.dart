import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:magic/utils/message_util.dart';

import '../../style/color/brand_color.dart';
import '../../widgets/custom_circle.dart';

class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => ZoomDrawer.of(context)!.toggle(),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.keyboard_arrow_right,
              color: BrandColor.kText,
              size: 28.0,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'музыка',
              style: TextStyle(
                color: BrandColor.kText,
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 8.0),
            const Icon(
              Icons.arrow_drop_down,
              color: BrandColor.kText,
              size: 28.0,
            ),
            const Spacer(),
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
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage(
                'assets/images/music_bg.jpg',
              ),
              fit: BoxFit.cover),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                      height: 50.0,
                      width: 50.0,
                      child: Image.asset('assets/images/ic_list.png')),
                ],
              ),
              const Spacer(),
              InkWell(
                  onTap: () => MessageUtil.show(context),
                  child: SizedBox(
                      height: 100.0,
                      width: 100.0,
                      child: Image.asset('assets/images/mp_play_normal.png'))),
              const Spacer(flex: 2)
            ],
          ),
        ),
      ),
    );
  }
}