import 'package:flutter/material.dart';
import 'package:magic_dashbord/style/brand_color.dart';

class LoginTextField extends StatelessWidget {
  const LoginTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    required this.lable,
  });
  final TextEditingController controller;

  final String hintText;
  final bool obscureText;
  final String lable;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lable,
          style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: BrandColor.kRed),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              child: TextField(
                obscureText: obscureText,
                obscuringCharacter: '*',
                controller: controller,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    constraints: const BoxConstraints(maxWidth: 400.0),
                    contentPadding: const EdgeInsets.only(left: 18.0),
                    filled: true,
                    fillColor: BrandColor.kRed.withOpacity(0.2),
                    hintText: hintText,
                    hintStyle:
                        TextStyle(color: BrandColor.kRed.withOpacity(0.4)),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        width: 1.0,
                        color: BrandColor.kRed,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(50.0)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(width: 3, color: Colors.white),
                      borderRadius: BorderRadius.all(Radius.circular(50.0)),
                    )),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
      ],
    );
  }
}
