import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:magic_dashbord/data/app_data.dart';
import 'package:magic_dashbord/helpers/auth_helper.dart';
import 'package:magic_dashbord/helpers/db_helper.dart';
import 'package:magic_dashbord/screen/contacts/contacts_screen.dart';
import 'package:magic_dashbord/screen/girls/girls_screen.dart';
import 'package:magic_dashbord/screen/main/components/device_list.dart';
import 'package:magic_dashbord/screen/root_screen.dart';
import 'package:magic_dashbord/screen/storage/storage_screen.dart';
import 'package:magic_dashbord/style/brand_color.dart';
import 'package:provider/provider.dart';

// List<String> menuItems = [
//   'OpenWeb',
//   'WebDownload',
//   'WebTelegram',
//   'Location',
//   'Devices',
//   'Map'
// ];

// class MainScreen extends StatefulWidget {
//   const MainScreen({super.key});

//   @override
//   State<MainScreen> createState() => _MainScreenState();
// }

// class _MainScreenState extends State<MainScreen> {
//   Widget getBody() {
//     int index = Provider.of<AppData>(context).getIndexMenu;
//     switch (index) {
//       case 0:
//         return const OpenWebPage();
//       case 1:
//         return const OnTapWebPage();
//       case 2:
//         return const Text('web telegram');
//       case 3:
//         return const LocationPage();
//       case 4:
//         return const DevicePage();
//       case 5:
//         return const LocationMapPage();

//       default:
//         return const OpenWebPage();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.deepPurple.shade100,
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(
//               vertical: 24.0,
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 ...List.generate(
//                   menuItems.length,
//                   (int index) => Padding(
//                     padding: const EdgeInsets.only(left: 8.0),
//                     child: AnimatedContainer(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(20.0),
//                         color: Provider.of<AppData>(
//                                   context,
//                                 ).getIndexMenu ==
//                                 index
//                             ? Colors.deepPurple
//                             : Colors.transparent,
//                       ),
//                       duration: const Duration(milliseconds: 300),
//                       child: InkWell(
//                         borderRadius: BorderRadius.circular(20.0),
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 18.0, vertical: 8),
//                           child: Text(
//                             menuItems[index],
//                             style: TextStyle(
//                               color: Provider.of<AppData>(
//                                         context,
//                                       ).getIndexMenu ==
//                                       index
//                                   ? Colors.white
//                                   : Colors.deepPurple,
//                             ),
//                           ),
//                         ),
//                         onTap: () =>
//                             Provider.of<AppData>(context, listen: false)
//                                 .updateSelectedMenu(index),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(child: getBody()),
//         ],
//       ),
//     );
//   }
// }

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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
    GirlsScreen(),
    StorageScreen(),
    ContactsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    // cleanContacts();
    super.initState();
  }

  // cleanContacts() async {
  //   DbHelper db = DbHelper();
  //   db.deleteAllContacts();
  // }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            title: const Text(
              'Sofa dasboard',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                  onPressed: () {
                    authHelper.signOut().then((value) => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyRootWidget())));
                  },
                  icon: const Icon(
                    Icons.logout_outlined,
                    color: Colors.white,
                  ))
            ],
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
              icon: Icon(Icons.girl_rounded),
              label: 'Girls',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storage_outlined),
              label: 'Storage',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.contacts_outlined),
              label: 'Contacts',
            ),
          ],
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex,
          selectedItemColor: BrandColor.kRed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
