import 'package:flutter/material.dart';
import 'package:magic_dashbord/style/brand_color.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.perm_contact_cal_outlined,
          color: BrandColor.kRed,
          size: 60.0,
        ),
        SizedBox(width: 8.0),
        Text(
          '#Sofa room',
          style: TextStyle(
            color: BrandColor.kRed,
            fontSize: 36.0,
            fontWeight: FontWeight.w500,
          ),
        )
      ],
    );
  }
}
