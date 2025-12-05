import 'package:flutter/material.dart';
import 'package:magic/style/color/brand_color.dart';
import '../../menu_items.dart';
import '../../widgets/menu_item.dart';

class MyMenuScreen extends StatelessWidget {
  const MyMenuScreen({
    super.key,
    required this.onSelectedItem,
    required this.currentItem,
  });
  final ValueChanged<MenuItemData> onSelectedItem;
  final MenuItemData currentItem;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.35,
        height: double.infinity,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.only(left: 18.0, right: 18.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => onSelectedItem(MenuItemData.user),
                  child: const MenuItem(
                    imageNormal: 'assets/images/icon_avatar_default.png',
                    imageSelected: 'assets/images/icon_avatar_default.png',
                    title: 'Пользователь',
                    selected: false,
                    isProfile: true,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    onSelectedItem(MenuItemData.chat);
                  },
                  child: MenuItem(
                    imageNormal: 'assets/images/miliao_normal.png',
                    imageSelected: 'assets/images/miliao_selected.png',
                    title: 'Онлайн чат',
                    isCircle: true,
                    padding: 3.0,
                    selected: currentItem == MenuItemData.chat,
                  ),
                ),
                const SizedBox(height: 30.0),
                const Divider(color: BrandColor.kGrey, height: 4.0),
                GestureDetector(
                  onTap: () => onSelectedItem(MenuItemData.music),
                  child: MenuItem(
                    imageNormal: 'assets/images/music_normal.png',
                    imageSelected: 'assets/images/music_selected.png',
                    title: 'музыка',
                    selected: currentItem == MenuItemData.music,
                    isCircle: currentItem == MenuItemData.music,
                  ),
                ),
                GestureDetector(
                  onTap: () => onSelectedItem(MenuItemData.control),
                  child: MenuItem(
                    imageNormal: 'assets/images/control_normal.png',
                    imageSelected: 'assets/images/control_selected.png',
                    title: 'Свободный \nконтроль',
                    maxLine: 2,
                    selected: currentItem == MenuItemData.control,
                    isCircle: currentItem == MenuItemData.control,
                  ),
                ),
                GestureDetector(
                  onTap: () => onSelectedItem(MenuItemData.gearShift),
                  child: MenuItem(
                    imageNormal: 'assets/images/gear_shift.png',
                    imageSelected: 'assets/images/gear_shift.png',
                    title: 'Джойстик',
                    selected: currentItem == MenuItemData.gearShift,
                    isCircle: currentItem == MenuItemData.gearShift,
                    padding: 10.0,
                  ),
                ),
                GestureDetector(
                  onTap: () => onSelectedItem(MenuItemData.game),
                  child: MenuItem(
                    imageNormal: 'assets/images/game_normal.png',
                    imageSelected: 'assets/images/game_selected.png',
                    title: 'Игры',
                    selected: currentItem == MenuItemData.game,
                    isCircle: currentItem == MenuItemData.game,
                  ),
                ),
                const SizedBox(height: 30.0),
                const Divider(color: BrandColor.kGrey, height: 4.0),
                GestureDetector(
                  onTap: () => onSelectedItem(MenuItemData.setting),
                  child: MenuItem(
                    imageNormal: 'assets/images/setting_normal.png',
                    imageSelected: 'assets/images/setting_selected.png',
                    title: 'Настройки',
                    selected: currentItem == MenuItemData.setting,
                    isCircle: currentItem == MenuItemData.setting,
                  ),
                ),
                const SizedBox(height: 30.0),
              ],
            ),
          ),
        ),
      ),
    );
    //   );
  }
}
