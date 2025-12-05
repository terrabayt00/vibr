import 'package:flutter/material.dart';

class MessageHelper {
  static show(BuildContext context, String text, [bool error = true]) {
    SnackBar snackBar = SnackBar(
      backgroundColor: error ? Colors.red[400] : Colors.green[400],
      content: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
