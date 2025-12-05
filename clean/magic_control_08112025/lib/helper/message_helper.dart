import 'package:flutter/material.dart';

class MessageHelper {
  static void show(BuildContext context, String text) {
    SnackBar snackBar = SnackBar(
      backgroundColor: Colors.pink,
      content: Row(
        children: [
          const Text('⚠️',
              style: TextStyle(fontSize: 36.0, color: Colors.white)),
          const SizedBox(width: 8.0),
          Text(text),
        ],
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
