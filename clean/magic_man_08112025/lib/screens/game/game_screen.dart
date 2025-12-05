import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

import '../../style/color/brand_color.dart';
import '../../widgets/custom_circle.dart';

List<GameCat> listData = [
  GameCat(image: 'assets/images/icon_shake_game_3.png', title: 'Барабан'),
  GameCat(
      image: 'assets/images/icon_sensor_game_1.png', title: 'Датчик давления'),
  GameCat(image: 'assets/images/icon_bubble_game_2.png', title: 'Пенная ванна'),
  GameCat(image: 'assets/images/icon_guitar_game_1.png', title: 'Гитара'),
];

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Center(
        child: SizedBox(
          height: 420,
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Center(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                children: listData
                    .map((e) => GameItem(
                          image: e.image,
                          title: e.title,
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
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
                'Игры',
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

class GameItem extends StatelessWidget {
  const GameItem({
    super.key,
    required this.image,
    required this.title,
  });

  final String image;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 100.0,
          width: 100.0,
          decoration: const BoxDecoration(
              color: Color(0xfff7f7f7), shape: BoxShape.circle),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.asset(image),
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18.0),
        )
      ],
    );
  }
}

class GameCat {
  final String image;
  final String title;
  GameCat({
    required this.image,
    required this.title,
  });
}
