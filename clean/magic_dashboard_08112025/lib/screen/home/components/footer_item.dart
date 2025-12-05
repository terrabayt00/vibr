import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FooterItem extends StatelessWidget {
  const FooterItem({super.key, required this.title, required this.link});
  final String title;
  final String link;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: InkWell(
        onTap: () async {
          await launchUrl(Uri.parse(link));
        },
        child: Text(
          title,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 12.0,
              fontWeight: FontWeight.normal),
        ),
      ),
    );
  }
}
