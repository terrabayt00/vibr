import 'package:flutter/material.dart';
import 'package:magic_dashbord/style/brand_color.dart';

class CustomLabel extends StatelessWidget {
  const CustomLabel({
    super.key,
    required this.text,
  });
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
          color: BrandColor.kText,
        ),
      ),
    );
  }
}
