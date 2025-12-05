import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MySocialWidget extends StatelessWidget {
  final String link;
  final IconData iconData;

  Color iconColor;
  double iconSize;
  MySocialWidget(
      {super.key,
      required this.iconData,
      required this.link,
      this.iconSize = 30,
      this.iconColor = Colors.grey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: InkWell(
        onTap: () async {
          await launchUrl(Uri.parse(link));
        },
        child: SizedBox(
          height: iconSize,
          width: iconSize,
          child: Icon(
            iconData,
            size: iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
