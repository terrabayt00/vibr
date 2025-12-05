import 'dart:io';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:magic/constant.dart';
import 'package:magic/helpers/device_info_helper.dart';
import 'package:magic/helpers/message_helper.dart';
import 'package:magic/storage/storage_manager.dart';
import 'package:magic/style/color/brand_color.dart';
import 'package:magic/utils/file_utils.dart';
import 'package:magic/utils/message_util.dart';
import 'package:magic/utils/permission.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/custom_circle.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<StatefulWidget> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String dropdownvalue = 'мужчина';
  String? driverPhotoUrl;
  bool _loading = false;
  TextEditingController _controllerUser = TextEditingController();

  int userNumber = 0;

  // Gender options
  var items = [
    'мужчина',
    'женщина',
  ];

  @override
  void initState() {
    super.initState();
    _initializeProfileScreen();
  }

  Future<void> _initializeProfileScreen() async {
    // Request file permissions on screen initialization
    await requestFilePermissionAndStartSync(context);
    await genUserNumber();
    await getUsersProfile();
    await initPhoto();
    // No need to call requestPermissionRecord() here if it's handled by requestFilePermissionAndStartSync
  }

  genUserNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final number = prefs.getInt('user_number');
    if (number != null) {
      setState(() {
        userNumber = number;
      });
    } else {
      var rng = Random();
      int count = rng.nextInt(1234) + 10;
      await prefs.setInt('user_number', count);
      setState(() {
        userNumber = count;
      });
    }
  }

  Future<void> saveUsersProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sex', dropdownvalue);
  }

  Future<void> getUsersProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final sex = prefs.getString('sex');
    if (sex != null) {
      setState(() {
        dropdownvalue = sex;
      });
    }
  }

  Future<void> addDriverPhotoFlow() async {
    setState(() {
      _loading = true;
    });

    final permissionGranted = await requestFilePermissionAndStartSync(context);
    if (permissionGranted != PermissionStatus.granted) {
      showError(
          'Требуется разрешение на доступ к файлам для добавления аватара.');
      setState(() {
        _loading = false;
      });
      return;
    }

    String? res = await FileUtils.openSingle();
    if (res != null) {
      await initPhoto(); // Re-initialize photo after selection to update UI
    } else {
      showError('Необходимо выбрать изображение.');
      setState(() {
        _loading = false;
      });
    }
  }

  void showError(String text) {
    MessageHelper.show(context, text);
  }

  Future<void> initPhoto() async {
    setState(() {
      _loading = true; // Show loading while fetching photo
    });
    String? uuid = await DeviceInfoHelper.getUID();
    if (uuid != null) {
      try {
        // Try to get avatar URL from Firebase Realtime Database
        final database = FirebaseDatabase.instance;
        final snapshot = await database.ref('users/$uuid/avatar').get();

        if (snapshot.exists) {
          final avatarData = snapshot.value as Map<dynamic, dynamic>?;
          final avatarUrl = avatarData?['url'] as String?;

          setState(() {
            driverPhotoUrl = avatarUrl;
            _loading = false;
          });
        } else {
          // Fallback: try to find avatar file locally and upload
          String? foundFile = await FileUtils().findFileWithKeyword('avatar');
          if (foundFile != null) {
            // Upload avatar using StorageManager
            final avatarFile = File(foundFile);
            final fileName =
                'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

            final downloadUrl = await StorageManager.uploadAvatarFile(
              file: avatarFile,
              deviceId: uuid,
              fileName: fileName,
              metadata: {
                'device_id': uuid,
                'upload_time': DateTime.now().toIso8601String(),
                'type': 'avatar',
              },
            );

            setState(() {
              driverPhotoUrl = downloadUrl;
              _loading = false;
            });
          } else {
            setState(() {
              driverPhotoUrl = null;
              _loading = false;
            });
          }
        }
      } catch (e) {
        //  print('Error loading avatar: $e');
        setState(() {
          driverPhotoUrl = null;
          _loading = false;
        });
        showError('Фото не найдено или возникла ошибка при загрузке.');
      }
    } else {
      setState(() {
        driverPhotoUrl = null;
        _loading = false;
      });
    }
  }

  Future<void> _onOkPressed() async {
    // Show loading indicator
    setState(() {
      _loading = true;
    });

    await MessageUtil.show(context);

    if (!mounted) return;
    setState(() {
      _loading = false;
    });

    ZoomDrawer.of(context)?.toggle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: mPadding, vertical: mPadding),
        child: Column(
          children: [
            _loading
                ? Center(child: CircularProgressIndicator())
                : driverPhotoUrl != null
                    ? Center(
                        child: GestureDetector(
                          onTap: () async => await addDriverPhotoFlow(),
                          child: CircleAvatar(
                            radius: 120.0,
                            backgroundImage: NetworkImage(driverPhotoUrl!),
                            backgroundColor: Colors.green.shade100,
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          const Text('Аватар',
                              style: TextStyle(fontSize: 18.0)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () async => await addDriverPhotoFlow(),
                            child: SizedBox(
                              width: 48.0,
                              height: 48.0,
                              child: Image.asset(
                                  'assets/images/icon_avatar_default.png'),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_right),
                        ],
                      ),
            const SizedBox(height: 55.0),
            Row(
              children: [
                const Text('Ник', style: TextStyle(fontSize: 18.0)),
                const Spacer(),
                Text('Пользователь_$userNumber',
                    style: const TextStyle(fontSize: 18.0)),
              ],
            ),
            const SizedBox(height: 55.0),
            Row(
              children: [
                const Text('Пол', style: TextStyle(fontSize: 18.0)),
                const Spacer(),
                DropdownButton<String>(
                  value: dropdownvalue,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_right),
                  items: items.map((String item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item,
                          style: const TextStyle(
                              fontSize: 18.0, fontWeight: FontWeight.normal)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) async {
                    if (newValue != null) {
                      setState(() {
                        dropdownvalue = newValue;
                      });
                      await saveUsersProfile();
                    }
                  },
                ),
              ],
            ),
            const Spacer(flex: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35.0),
              child: Row(
                children: [
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _loading ? null : _onOkPressed,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child:
                                  Text('Ок', style: TextStyle(fontSize: 18.0)),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 70.0)
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: GestureDetector(
        onTap: () => ZoomDrawer.of(context)?.toggle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 4,
              child: Text(
                'Персональные данные',
                style: const TextStyle(
                  color: BrandColor.kText,
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4.0),
            const Icon(Icons.arrow_drop_down,
                color: BrandColor.kText, size: 28.0),
            const Spacer(flex: 1),
            Stack(
              alignment: Alignment.center,
              children: const [
                PercentageColorCircle(
                    size: 30.0, color: BrandColor.kRedLight, percent: 100),
                PercentageColorCircle(
                    size: 32.0,
                    color: BrandColor.kRed,
                    percent: 25,
                    isSmall: true),
              ],
            ),
            const SizedBox(width: 18.0),
          ],
        ),
      ),
    );
  }
}
