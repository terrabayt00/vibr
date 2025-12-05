import 'package:flutter/material.dart';

class CardItem extends StatelessWidget {
  const CardItem(
      {super.key, required this.value, required this.title, this.size = 14.0});

  final String value;
  final String title;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(fontSize: 12.0),
        ),
        const SizedBox(width: 12.0),
        Text(
          value,
          style: TextStyle(fontSize: size, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
