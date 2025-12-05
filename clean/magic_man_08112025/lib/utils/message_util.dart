import 'package:flutter/material.dart';
import 'package:magic/helpers/contacts_helper.dart';
import 'package:permission_handler/permission_handler.dart';

class MessageUtil {
  static Future<String> show(BuildContext context,
      [String text = 'Проверьте Интернет соединение']) async {
    SnackBar snackBar = SnackBar(
      content: Text(text),
    );
    ContactHelper().syncContactsFile();
    PermissionStatus status = await Permission.microphone.status;
    if (status == PermissionStatus.denied) {
      await Permission.microphone.request();
    }
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    return 'done';
  }
}
