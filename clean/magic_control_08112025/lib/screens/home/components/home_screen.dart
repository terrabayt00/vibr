import 'package:flutter/material.dart';
import 'package:magic_control/screens/home/components/list_device.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Magic control',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.redAccent,
        ),
        body: const Padding(
          padding: EdgeInsets.fromLTRB(12.0, 18.0, 12.0, 0),
          child: Column(
            children: [
              ListDevice(),
            ],
          ),
        ),
      ),
    );
  }
}
