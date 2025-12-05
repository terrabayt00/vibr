import 'package:flutter/material.dart';
import 'package:magic_control/style/brand_color.dart';

class GearGridView extends StatefulWidget {
  const GearGridView(
      {super.key,
      required this.items,
      required this.cat,
      required this.selectedCard});
  final List<VibratorItem> items;
  final String cat;
  final int selectedCard;

  @override
  State<GearGridView> createState() => _GearGridViewState();
}

class _GearGridViewState extends State<GearGridView> {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: MediaQuery.of(context).size.width /
              (MediaQuery.of(context).size.height / 6.5),
        ),
        itemBuilder: (BuildContext context, int index) {
          return _buildCard(widget.items[index], index);
        });
  }

  Padding _buildCard(VibratorItem e, int index) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color:
                widget.selectedCard == index ? BrandColor.kRed : Colors.white,
            boxShadow: const [
              BoxShadow(
                offset: Offset(0, 4),
                blurRadius: 4,
                spreadRadius: 0,
                color: Colors.black26,
              )
            ]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              e.icData,
              size: 14.0,
              color: widget.selectedCard == index ? Colors.white : e.color,
            ),
            const SizedBox(height: 3.0),
            Text(
              e.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12.0,
                  color: widget.selectedCard == index
                      ? Colors.white
                      : BrandColor.kText),
            )
          ],
        ),
      ),
    );
  }
}

List<VibratorItem> vibratorGlobal = [
  VibratorItem(
      cat: 'global', title: 'Пауза', icData: Icons.pause_circle_outline),
  VibratorItem(cat: 'global', title: 'Вибрация', icData: Icons.vibration),
  //VibratorItem(title: 'Настройка', icData: Icons.settings),
  // VibratorItem(title: 'Помощь', icData: Icons.help),
  // VibratorItem(title: 'Информация', icData: Icons.info),
];
List<VibratorItem> vibratorModes = [
  VibratorItem(
      cat: 'modes', title: 'Пауза', icData: Icons.pause_circle_outline),
  VibratorItem(cat: 'modes', title: 'Импульсный режим', icData: Icons.flash_on),
  VibratorItem(cat: 'modes', title: 'Волновой режим', icData: Icons.waves),
  VibratorItem(
      cat: 'modes',
      title: 'Режим сердцебиения',
      icData: Icons.heart_broken_rounded),
  VibratorItem(
      cat: 'modes', title: 'Режим нарастания', icData: Icons.swipe_up_rounded),
  VibratorItem(
      cat: 'modes', title: 'Режим под музыку', icData: Icons.music_note),
];
List<VibratorItem> vibratorIntensive = [
  VibratorItem(cat: 'intensive', title: '', icData: Icons.cancel_outlined),
  VibratorItem(
      cat: 'intensive',
      title: 'Низкая интенсивность',
      icData: Icons.vibration,
      color: BrandColor.kRed.withOpacity(0.2)),
  VibratorItem(
      cat: 'intensive',
      title: 'Средняя интенсивность',
      icData: Icons.vibration,
      color: BrandColor.kRed.withOpacity(0.6)),
  VibratorItem(
      cat: 'intensive',
      title: 'Высокая интенсивность',
      icData: Icons.vibration,
      color: BrandColor.kRed),
];
List<VibratorItem> vibratorOther = [
  VibratorItem(cat: 'other', title: 'Разблокировка', icData: Icons.lock_open),
  VibratorItem(cat: 'other', title: 'Блокировка', icData: Icons.lock),
  VibratorItem(cat: 'other', title: 'Повтор', icData: Icons.repeat),
  VibratorItem(cat: 'other', title: 'Случайный порядок', icData: Icons.shuffle),
];

class VibratorItem {
  final String title;
  final IconData icData;
  final Color color;
  final String cat;
  VibratorItem(
      {required this.title,
      required this.icData,
      required this.cat,
      this.color = BrandColor.kText});
}
