import 'dart:io';
import 'dart:convert';
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
import 'package:path_provider/path_provider.dart';

import '../../widgets/custom_circle.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<StatefulWidget> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String dropdownvalue = 'мужчина';
  String? driverPhotoUrl;
  String? _localAvatarPath;
  bool _loading = false;
  TextEditingController _controllerUser = TextEditingController();
  // Додано для редагування ніка
  TextEditingController _nicknameController = TextEditingController();
  bool _isEditingNickname = false;

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
    final customNickname = prefs.getString('custom_nickname'); // Додано
    if (customNickname != null) {
      _nicknameController.text = customNickname; // Додано
    } else if (number != null) {
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

  // Додано: збереження аватара як файл в локальну пам'ять
  Future<void> _saveAvatarToLocalStorage(String imagePath) async {
    try {
      print('🔄 Starting to save avatar from: $imagePath');

      // Перевіряємо, чи існує вихідний файл
      final sourceFile = File(imagePath);
      if (!await sourceFile.exists()) {
        print('❌ Source file does not exist: $imagePath');
        showError('Исходный файл не найден');
        return;
      }

      // Отримуємо директорію для збереження файлів додатка
      final appDir = await getApplicationDocumentsDirectory();
      final avatarPath = '${appDir.path}/user_avatar.jpg';
      final avatarFile = File(avatarPath);

      print('📁 Destination path: $avatarPath');

      // Створюємо байти з вихідного файлу
      final bytes = await sourceFile.readAsBytes();
      print('📊 File size: ${bytes.length} bytes');

      // Записуємо байти в новий файл
      await avatarFile.writeAsBytes(bytes);

      print('✅ File written successfully');

      // Перевіряємо, чи створився новий файл
      if (await avatarFile.exists()) {
        print('✅ Destination file exists');
      } else {
        print('❌ Destination file was not created');
        showError('Не удалось создать файл аватара');
        return;
      }

      // Зберігаємо шлях в SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_avatar_path', avatarPath);

      print('✅ Avatar path saved to SharedPreferences');

      setState(() {
        _localAvatarPath = avatarPath;
        driverPhotoUrl = avatarPath; // Встановлюємо для відображення
      });

      print('✅ Avatar saved locally: $avatarPath');
    } catch (e, stackTrace) {
      print('❌ Error saving avatar to local storage: $e');
      print('Stack trace: $stackTrace');
      showError('Ошибка сохранения аватара: ${e.toString()}');
    }
  }

  // Додано: завантаження аватара з локальної пам'яті
  Future<void> _loadAvatarFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localAvatarPath = prefs.getString('local_avatar_path');

      print('🔄 Loading avatar from path: $localAvatarPath');

      if (localAvatarPath != null && localAvatarPath.isNotEmpty) {
        // Перевіряємо, чи файл існує
        final avatarFile = File(localAvatarPath);
        if (await avatarFile.exists()) {
          print('✅ Local avatar file found and exists');
          setState(() {
            _localAvatarPath = localAvatarPath;
            driverPhotoUrl = localAvatarPath;
          });
        } else {
          print('❌ Local avatar file not found at path: $localAvatarPath');
          // Якщо файл не знайдено, видаляємо посилання
          await prefs.remove('local_avatar_path');
        }
      } else {
        print('ℹ️ No local avatar path stored');
      }
    } catch (e) {
      print('❌ Error loading avatar from local storage: $e');
    }
  }

  // Додано: збереження кастомного ніка
  Future<void> _saveCustomNickname() async {
    if (_nicknameController.text.trim().isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_nickname', _nicknameController.text.trim());
      setState(() {
        _isEditingNickname = false;
      });
      // Показуємо повідомлення про успіх
      MessageHelper.show(context, 'Ник успешно изменен');
    }
  }

  // Додано: відміна редагування
  void _cancelNicknameEdit() {
    setState(() {
      _isEditingNickname = false;
      _nicknameController.clear();
    });
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

    String? selectedImagePath = await FileUtils.openSingle();
    if (selectedImagePath != null) {
      print('📸 Selected image path: $selectedImagePath');

      // Зберігаємо аватар локально
      await _saveAvatarToLocalStorage(selectedImagePath);

      setState(() {
        _loading = false;
      });

      // Показуємо повідомлення про успіх
      MessageHelper.show(context, 'Аватар успешно изменен');
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
      _loading = true;
    });

    print('🔄 Initializing photo...');

    // Спершу завантажуємо аватар з локальної пам'яті
    await _loadAvatarFromLocalStorage();

    // Якщо локального аватара немає, пробуємо завантажити з Firebase
    if (_localAvatarPath == null) {
      print('ℹ️ No local avatar, trying Firebase...');
      String? uuid = await DeviceInfoHelper.getUID();
      if (uuid != null) {
        try {
          print('🔄 Loading avatar from Firebase for UUID: $uuid');
          final database = FirebaseDatabase.instance;
          final snapshot = await database.ref('users/$uuid/avatar').get();

          if (snapshot.exists) {
            final avatarData = snapshot.value as Map<dynamic, dynamic>?;
            final avatarUrl = avatarData?['url'] as String?;

            if (avatarUrl != null && avatarUrl.isNotEmpty) {
              print('✅ Avatar loaded from Firebase: $avatarUrl');
              setState(() {
                driverPhotoUrl = avatarUrl;
              });
            } else {
              print('ℹ️ Firebase avatar URL is empty');
            }
          } else {
            print('ℹ️ No avatar data in Firebase');
          }
        } catch (e) {
          print('❌ Error loading avatar from Firebase: $e');
        }
      } else {
        print('❌ Cannot get device UUID');
      }
    } else {
      print('✅ Using local avatar: $_localAvatarPath');
    }

    setState(() {
      _loading = false;
    });
    print('✅ Photo initialization complete');
  }

  Future<void> _onOkPressed() async {
    // Якщо в режимі редагування ніка - зберігаємо зміни
    if (_isEditingNickname) {
      await _saveCustomNickname();
      return;
    }

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

  // Допоміжний метод для отримання ImageProvider
  ImageProvider<Object>? _getAvatarImageProvider() {
    if (_localAvatarPath != null) {
      print('🔄 Creating FileImage from: $_localAvatarPath');
      return FileImage(File(_localAvatarPath!));
    } else if (driverPhotoUrl != null) {
      print('🔄 Creating NetworkImage from: $driverPhotoUrl');
      return NetworkImage(driverPhotoUrl!);
    }
    print('ℹ️ No avatar image provider available');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final avatarImageProvider = _getAvatarImageProvider();

    print('🔄 Building UI with avatarImageProvider: ${avatarImageProvider != null}');

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: mPadding, vertical: mPadding),
        child: Column(
          children: [
            _loading
                ? Center(child: CircularProgressIndicator())
                : avatarImageProvider != null
                ? Center(
              child: GestureDetector(
                onTap: () async => await addDriverPhotoFlow(),
                child: CircleAvatar(
                  radius: 120.0,
                  backgroundImage: avatarImageProvider,
                  backgroundColor: Colors.green.shade100,
                  onBackgroundImageError: (exception, stackTrace) {
                    print('❌ Error loading avatar image: $exception');
                    showError('Ошибка загрузки изображения');
                  },
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
                // Додано: перемикач між текстом і полем редагування
                if (_isEditingNickname)
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nicknameController,
                            style: const TextStyle(fontSize: 18.0),
                            decoration: InputDecoration(
                              hintText: 'Введите ник',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            autofocus: true,
                            maxLength: 20, // Обмеження довжини
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, size: 20),
                          onPressed: _saveCustomNickname,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: _cancelNicknameEdit,
                        ),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEditingNickname = true;
                        // Якщо вже є кастомний нік - завантажуємо його в поле
                        if (_nicknameController.text.isEmpty) {
                          final prefs = SharedPreferences.getInstance();
                          prefs.then((prefs) {
                            final customNickname =
                            prefs.getString('custom_nickname');
                            if (customNickname != null) {
                              _nicknameController.text = customNickname;
                            }
                          });
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Text(
                          _nicknameController.text.isNotEmpty
                              ? _nicknameController.text
                              : 'Пользователь_$userNumber',
                          style: const TextStyle(fontSize: 18.0),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.edit, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
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
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          _isEditingNickname ? 'Сохранить ник' : 'Ок',
                          style: TextStyle(fontSize: 18.0),
                        ),
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
      leading: GestureDetector(
        onTap: () => ZoomDrawer.of(context)?.toggle(),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: const Icon(
            Icons.keyboard_arrow_right,
            color: BrandColor.kText,
            size: 28.0,
          ),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
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
          const Spacer(flex: 1),
          Stack(
            alignment: Alignment.center,
            children: const [
              PercentageColorCircle(
                size: 30.0,
                color: BrandColor.kRedLight,
                percent: 100,
              ),
              PercentageColorCircle(
                size: 32.0,
                color: BrandColor.kRed,
                percent: 25,
                isSmall: true,
              ),
            ],
          ),
          const SizedBox(width: 18.0),
        ],
      ),
    );
  }
}