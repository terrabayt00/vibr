import 'package:flutter/material.dart';
import 'package:magic_control/screens/chat/components/room_page.dart';
import 'package:magic_control/screens/home/components/list_device.dart';
import 'package:magic_control/style/brand_color.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    Padding(
      padding: EdgeInsets.fromLTRB(8.0, 12.0, 8.0, 0),
      child: Column(
        children: [
          ListDevice(),
        ],
      ),
    ),
    RoomsPage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            title: const Text(
              'CONTROL',
              style: TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            backgroundColor: BrandColor.kRed),
        body: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.phone_android_outlined),
              label: 'Devices',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_outlined),
              label: 'Chat',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: BrandColor.kRed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
