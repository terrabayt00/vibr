import 'package:flutter/material.dart';
import 'package:magic/style/color/brand_color.dart';

class BrandText {
  static const TextStyle sTitle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w500,
    color: BrandColor.kText,
  );
  static const TextStyle swTitle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
    color: BrandColor.kText,
  );
  static const TextStyle bodyTitle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.normal,
    color: BrandColor.kGrey,
  );
  static const TextStyle sRed = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    color: BrandColor.kRed,
  );
  static const TextStyle textBody =
      TextStyle(fontSize: 16.0, color: BrandColor.kText);
}
