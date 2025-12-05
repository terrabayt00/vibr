import 'package:flutter/material.dart';

import '../style/color/brand_color.dart';

class MenuItem extends StatelessWidget {
  const MenuItem({
    super.key,
    required this.title,
    required this.imageNormal,
    required this.imageSelected,
    this.maxLine = 1,
    this.isCircle = false,
    this.padding = 0,
    required this.selected,
    this.isProfile = false,
  });

  final String title;
  final String imageNormal;
  final String imageSelected;
  final int maxLine;
  final bool isCircle;
  final bool selected;

  final double padding;
  final bool isProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30.0),
        isCircle
            ? Column(
                children: [
                  Container(
                    height: 52.0,
                    width: 52.0,
                    decoration: BoxDecoration(
                        color: selected ? BrandColor.kRed : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            offset: Offset(0, 1),
                            spreadRadius: 2,
                            color: Colors.black12,
                            blurRadius: 5.0,
                          )
                        ]),
                    child: isProfile
                        ? Image.asset(
                            selected ? imageSelected : imageNormal,
                            height: 48.0,
                            width: 48.0,
                            fit: BoxFit.contain,
                          )
                        : Padding(
                            padding: EdgeInsets.all(padding),
                            child: Image.asset(
                              selected ? imageSelected : imageNormal,
                              height: 46.0,
                              width: 46.0,
                              color: Color(0xff333333),
                              fit: BoxFit.contain,
                            ),
                          ),
                  ),
                  const SizedBox(height: 8.0),
                ],
              )
            : isProfile
                ? Image.asset(
                    selected ? imageSelected : imageNormal,
                    height: 48.0,
                    width: 48.0,
                    fit: BoxFit.contain,
                  )
                : Image.asset(
                    selected ? imageSelected : imageNormal,
                    color: Color(0xff333333),
                    height: 48.0,
                    width: 48.0,
                    fit: BoxFit.contain,
                  ),
        SizedBox(
          width: 88.0,
          child: Text(
            title,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: maxLine,
            style: TextStyle(
                fontSize: 15.0,
                color: selected ? BrandColor.kRed : BrandColor.kText),
          ),
        ),
      ],
    );
  }
}
