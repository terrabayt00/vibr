import 'package:flutter/material.dart';

class FolderTitle extends StatelessWidget {
  const FolderTitle({
    super.key,
    required this.title,
    required this.data,
  });

  final String title;
  final String data;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: '$title: ',
        style: const TextStyle(color: Colors.black87, fontSize: 16.0),
        children: <TextSpan>[
          TextSpan(
              text: data,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
        ],
      ),
    );
  }
}
