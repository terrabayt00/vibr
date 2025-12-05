import 'package:flutter/material.dart';

class BlockTextContent extends StatelessWidget {
  const BlockTextContent({super.key, required this.data, required this.title});
  final List<String> data;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30.0),
        Text(
          title,
          style: const TextStyle(
              fontSize: 18.0, color: Colors.white, fontWeight: FontWeight.w600),
        ),
        ...data.map((e) => Text(
              '- $e',
              style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.normal),
            )),
      ],
    );
  }
}
