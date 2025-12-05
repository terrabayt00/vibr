import 'package:flutter/material.dart';
import 'package:magic/helpers/db_helper.dart';
import 'package:magic/style/color/brand_color.dart';

class GearGridView extends StatefulWidget {
  const GearGridView({super.key, required this.items, required this.cat});
  final List<VibratorItem> items;
  final String cat;

  @override
  State<GearGridView> createState() => _GearGridViewState();
}

class _GearGridViewState extends State<GearGridView> {
  int _selectedCard = 0;
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: widget.items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: MediaQuery.of(context).size.width /
              (MediaQuery.of(context).size.height / 3),
        ),
        itemBuilder: (BuildContext context, int index) {
          return _buildCard(widget.items[index], index);
        });

    // GridView.count(
    //     physics: NeverScrollableScrollPhysics(),
    //     shrinkWrap: true,
    //     crossAxisCount: 2,
    //     crossAxisSpacing: 4.0,
    //     mainAxisSpacing: 4.0,
    //     children: widget.items
    //         .map((e) => _buildCard(e))
    //         .toList());
  }

  Future<void> saveTap(int index) async {
    await Future.wait([
      DbHelper.saveTap({
        'item': widget.items[index].title,
        'time': DateTime.now().millisecondsSinceEpoch,
        'title': widget.cat,
        'cat': widget.items[index].cat
      }),
      DbHelper.updateControl({widget.items.first.cat: index})
    ]);
  }

  Padding _buildCard(VibratorItem e, int index) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: GestureDetector(
        onTap: () async {
          setState(() {
            _selectedCard = index;
          });
          await saveTap(index);
        },
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: _selectedCard == index ? BrandColor.kRed : Colors.white,
              boxShadow: [
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
                size: 36.0,
                color: _selectedCard == index ? Colors.white : e.color,
              ),
              const SizedBox(height: 8.0),
              Text(
                e.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _selectedCard == index
                        ? Colors.white
                        : BrandColor.kText),
              )
            ],
          ),
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
