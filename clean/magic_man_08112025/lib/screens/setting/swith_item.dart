import 'package:flutter/cupertino.dart';
import 'package:magic/screens/setting/item_data.dart';
import 'package:magic/style/color/brand_text.dart';

class SwithItemButton extends StatefulWidget {
  const SwithItemButton({super.key});

  @override
  State<SwithItemButton> createState() => _SwithItemButtonState();
}

class _SwithItemButtonState extends State<SwithItemButton> {
  List<bool> switchValues = [true, true, true, false];
  @override
  Widget build(BuildContext context) {
    return Column(
        children: itemsSwitch.asMap().entries.map((e) {
      int index = e.key;
      String title = e.value.title;
      bool value = switchValues[index];

      return Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: BrandText.sTitle,
            ),
            CupertinoSwitch(
              value: value,
              onChanged: (newValue) =>
                  setState(() => switchValues[index] = newValue),
            ),
          ],
        ),
      );
    }).toList());
  }
}
