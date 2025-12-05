import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:magic_dashbord/helpers/auth_helper.dart';
import 'package:magic_dashbord/screen/home/home_screen.dart';
import 'package:magic_dashbord/screen/main/main_screen.dart';

class MyRootWidget extends StatelessWidget {
  const MyRootWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: authHelper.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasData) {
            return const MainScreen();
          }
          return const HomeScreen();
        });
  }
}
